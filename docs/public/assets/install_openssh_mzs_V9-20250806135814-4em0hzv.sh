#!/bin/bash
set -euo pipefail

# ------------------------------------------------------
# OpenSSH 完全离线安装脚本 v2.0.0 (函数化重构)
# 作者：omanik
# 修改：luoyuanxiang
# 日期：2025-08-06
# ------------------------------------------------------

# 全局配置
YUM_OFFLINE_OPTS="--disablerepo=* --setopt=module_platform_id=platform:an8 --setopt=modules.disable=1"
OFFLINE_DEPS_TAR="anolis8-dev.tar.gz"
TAR_FILE="SSH_10.0p2-rpm.tar.gz"
LOGFILE="$(pwd)/openssh_install_$(date +%Y%m%d%H%M%S).log"
BACKUP_DIR=""
TIMESTAMP=""
INSTALL_STATUS=0

# 初始化日志
init_logging() {
    exec > >(tee -a "$LOGFILE") 2>&1
}

# 日志记录
log() {
    echo -e "\e[36m[$(date +'%Y-%m-%d %H:%M:%S')] $*\e[0m"
}

# 错误退出
error_exit() {
    echo -e "\e[31m错误：$*\e[0m"
    exit 1
}

# 显示欢迎信息
show_welcome() {
    echo "------------------------------------------------------"
    echo -e "\e[34m🛠  欢迎使用 OpenSSH 完全离线安装脚本（v2.0.0）\e[0m"
    echo "------------------------------------------------------"
    echo -e "\e[36m✔  支持系统：\e[0m"
    echo -e "\e[32m  - CentOS 7.x（内核 3.10.0-）"
    echo -e "  - CentOS 8.x（内核 4.18.0-）"
    echo -e "  - Rocky Linux 9.x（内核 5.14.0-）"
    echo -e "  - Alibaba Cloud Linux 3（内核 5.10.0-）"
    echo -e "  - 其他 RedHat 系发行版请自测兼容性\e[0m"
    echo -e "\e[36m✔  架构要求：\e[0m \e[32mx86_64\e[0m"
    echo -e "\e[36m✔  离线特性：\e[0m \e[32m无网络依赖、本地包安装、使用预提供的离线依赖包\e[0m"
    echo -e "\e[36m✔  依赖包：\e[0m \e[32m$OFFLINE_DEPS_TAR\e[0m"
}

# 系统检查
system_check() {
    log "执行系统环境检查..."
    OS_ID=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    OS_VERSION_ID=$(grep "^VERSION_ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
    CPU_ARCH=$(uname -m)
    KERNEL_VER=$(uname -r)

    [[ "$CPU_ARCH" != "x86_64" ]] && error_exit "当前架构为 $CPU_ARCH，仅支持 x86_64"

    if [[ "$OS_ID" == "centos" && "$OS_VERSION_ID" =~ ^(7|8)$ ]]; then
        log "系统版本符合要求：CentOS $OS_VERSION_ID"
    elif [[ "$OS_ID" == "rocky" && "$OS_VERSION_ID" =~ ^9 ]]; then
        log "系统版本符合要求：Rocky Linux $OS_VERSION_ID"
    else
        echo -e "\e[33m当前系统为 $OS_ID $OS_VERSION_ID，未在支持列表中。\e[0m"
        read -p $'\e[33m是否继续安装？(y/n): \e[0m' choice
        [[ ! "$choice" =~ ^[Yy]$ ]] && error_exit "已取消安装。"
    fi

    if [[ ! "$KERNEL_VER" =~ ^(3\.10\.0|4\.18\.0|5\.14\.0)- ]]; then
        echo -e "\e[33m当前内核版本为 $KERNEL_VER，未在推荐版本中。\e[0m"
        read -p $'\e[33m是否继续安装？(y/n): \e[0m' choice
        [[ ! "$choice" =~ ^[Yy]$ ]] && error_exit "已取消安装。"
    else
        log "内核版本符合要求：$KERNEL_VER"
    fi
}

# 管理 SELinux
manage_selinux() {
    log "检测 SELinux 状态..."
    SELINUX_STATUS=$(getenforce 2>/dev/null || echo "Disabled")

    if [[ "$SELINUX_STATUS" == "Enforcing" || "$SELINUX_STATUS" == "Permissive" ]]; then
        log "当前 SELinux 状态为 $SELINUX_STATUS，将临时设置为 Disabled"
        setenforce 0 || log "⚠️ 无法使用 setenforce 关闭 SELinux，可能未安装或非运行时可修改"

        if grep -q '^SELINUX=' /etc/selinux/config; then
            sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
            log "已修改 /etc/selinux/config，禁用 SELinux（需重启生效）"
        else
            log "⚠️ 未找到 /etc/selinux/config 或配置不规范，请手动确认是否完全禁用 SELinux"
        fi
    else
        log "SELinux 已处于关闭状态：$SELINUX_STATUS"
    fi
}

# 检查重复安装
check_existing_installation() {
    log "检查当前系统已安装的 OpenSSH 版本..."
    CURRENT_VER=$(rpm -q --qf '%{VERSION}-%{RELEASE}\n' openssh-server 2>/dev/null || echo "none")
    TARGET_VER=$(rpm -q --qf '%{VERSION}-%{RELEASE}\n' -p openssh-server-*.rpm | head -n1)

    if [[ "$CURRENT_VER" == "$TARGET_VER" ]]; then
        echo -e "\e[33m当前系统已安装相同版本（$CURRENT_VER），无需重复安装。\e[0m"
        read -p $'\e[33m是否强制安装此版本？(y/n): \e[0m' choice
        [[ ! "$choice" =~ ^[Yy]$ ]] && error_exit "已取消安装。"
    fi
}

# 准备备份目录
prepare_backup() {
    TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    BACKUP_DIR="/opt/openssh_backup_$TIMESTAMP"
    mkdir -p "$BACKUP_DIR"
    log "创建备份目录: $BACKUP_DIR"
}

# 备份配置文件
backup_configs() {
    log "备份关键配置文件..."
    CRITICAL_FILES=(
        /etc/ssh/sshd_config
        /etc/ssh/ssh_config
        /etc/pam.d/sshd
        /etc/sysconfig/sshd
    )

    for file in "${CRITICAL_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            cp -a "$file" "$BACKUP_DIR/"
            log "已备份：$file"
        else
            log "⚠️ 未找到：$file"
        fi
    done
}

# 备份 SSH 目录
backup_ssh_directory() {
    if [[ -d "/etc/ssh" ]]; then
        log "备份整个/etc/ssh目录..."
        cp -a /etc/ssh "$BACKUP_DIR/etc_ssh"

        getfacl -R /etc/ssh > "$BACKUP_DIR/etc_ssh_acls.txt" 2>/dev/null
        find /etc/ssh -exec ls -la {} \; > "$BACKUP_DIR/etc_ssh_filelist.txt" 2>/dev/null
        log "已备份/etc/ssh目录权限和ACL信息"
    fi
}

# 备份服务状态
backup_service_status() {
    log "备份服务状态..."
    if command -v systemctl &>/dev/null; then
        systemctl status sshd > "$BACKUP_DIR/sshd_status_before.txt" 2>&1
    elif command -v service &>/dev/null; then
        service sshd status > "$BACKUP_DIR/sshd_status_before.txt" 2>&1
    fi
}

# 备份服务文件
backup_service_files() {
    log "备份服务相关文件..."
    INIT_SYSTEM=$(cat /proc/1/comm)
    log "检测到系统使用的初始化进程为：$INIT_SYSTEM"

    SERVICE_FILES=(
        /etc/systemd/system/sshd.service
        /usr/lib/systemd/system/sshd.service
        /etc/rc.d/init.d/sshd
        /etc/init.d/sshd
    )

    for service_file in "${SERVICE_FILES[@]}"; do
        if [[ -f "$service_file" ]]; then
            cp -a "$service_file" "$BACKUP_DIR/"
            log "已备份服务文件：$service_file"
        fi
    done
}

# 获取二进制路径
get_binary_path() {
    local name=$1
    local path=$(command -v "$name" 2>/dev/null)
    [[ -n "$path" ]] && { echo "$path"; return 0; }

    local rpm_files=$(rpm -ql openssh-server openssh-clients openssh 2>/dev/null | grep -E "/${name}$")
    [[ -n "$rpm_files" ]] && { echo "$rpm_files" | head -n1; return 0; }

    case "$name" in
        sshd)        echo "/usr/sbin/sshd" ;;
        ssh)         echo "/usr/bin/ssh" ;;
        scp)         echo "/usr/bin/scp" ;;
        sftp)        echo "/usr/bin/sftp" ;;
        ssh-keygen)  echo "/usr/bin/ssh-keygen" ;;
        sftp-server) echo "/usr/libexec/openssh/sftp-server" ;;
        *)           echo ""
    esac
}

# 备份二进制文件
backup_binaries() {
    log "备份二进制文件和库..."
    BINARIES=()
    BINARY_NAMES=(sshd ssh scp sftp ssh-keygen sftp-server)

    for binary_name in "${BINARY_NAMES[@]}"; do
        path=$(get_binary_path "$binary_name")
        if [[ -e "$path" || -L "$path" ]]; then
            BINARIES+=("$path")
            log "定位到二进制文件：$binary_name → $path"
        else
            log "⚠️ 未找到二进制文件：$binary_name"
        fi
    done

    EXTRA_PATHS=(
        /usr/libexec/openssh/ssh-keysign
        /usr/libexec/openssh/ssh-pkcs11-helper
    )
    for path in "${EXTRA_PATHS[@]}"; do
        [[ -e "$path" ]] && BINARIES+=("$path")
    done

    for binary in "${BINARIES[@]}"; do
        if [[ -f "$binary" || -L "$binary" ]]; then
            mkdir -p "$BACKUP_DIR/$(dirname "$binary")"
            cp -a "$binary" "$BACKUP_DIR/$binary"
            log "已备份：$binary"
        fi
    done
}

# 记录 RPM 包信息
record_rpm_info() {
    log "记录已安装的RPM包信息..."
    rpm -qa --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' openssh\* > "$BACKUP_DIR/installed_rpms.txt"
    rpm -qa --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' > "$BACKUP_DIR/all_installed_rpms.txt"
}

# 验证备份完整性
verify_backup() {
    log "验证备份完整性..."
    BACKUP_VERIFICATION_FAILED=0
    [[ ! -f "$BACKUP_DIR/etc_ssh/sshd_config" ]] && { log "⚠️ 关键文件sshd_config备份失败"; BACKUP_VERIFICATION_FAILED=1; }
    [[ ! -f "$BACKUP_DIR/installed_rpms.txt" ]] && { log "⚠️ RPM包信息备份失败"; BACKUP_VERIFICATION_FAILED=1; }

    if [[ $BACKUP_VERIFICATION_FAILED -eq 1 ]]; then
        echo -e "\e[31m备份验证失败！关键文件未成功备份。\e[0m"
        read -p $'\e[31m是否强制继续？(y/n): \e[0m' choice
        [[ ! "$choice" =~ ^[Yy]$ ]] && error_exit "安装中止，备份验证未通过。"
    fi

    log "备份完成，路径：$BACKUP_DIR"
}

# 解压安装包
extract_package() {
    log "解压 SSH 安装包..."
    [[ ! -f "$TAR_FILE" ]] && error_exit "$TAR_FILE 不存在！请确保放在脚本同一目录下。"
    mkdir -p ./openssh_rpms
    tar -xzf "$TAR_FILE" -C ./openssh_rpms
    cd ./openssh_rpms
}

# 安装离线依赖
install_offline_deps() {
    cd ~
    log "准备离线依赖包..."
    [[ ! -f "$OFFLINE_DEPS_TAR" ]] && error_exit "离线依赖包 $OFFLINE_DEPS_TAR 不存在！"
    log "解压离线依赖包..."
    tar xzf "$OFFLINE_DEPS_TAR"
    rpm -Uvh ./rpms/*.rpm
    log "离线依赖包准备完成"
    cd /root/openssh_rpms
}

# 检查依赖
check_deps() {
  # 要检查的软件包列表
  packages=(
      "gcc"
      "make"
      "openssl-devel"
      "zlib-devel"
      "pam-devel"
  )
  # 标记是否有未安装的包
  missing=0

  echo "===== 检查必需的开发工具和库 ====="

  # 循环检查每个包
  for pkg in "${packages[@]}"; do
      # 检查包是否安装（适用于RPM系统）
      if rpm -q "$pkg" >/dev/null 2>&1; then
          # 获取已安装版本
          version=$(rpm -q --qf '%{VERSION}-%{RELEASE}\n' "$pkg")
          echo -e "\e[32m[已安装] $pkg: $version\e[0m"
      else
          echo -e "\e[31m[未安装] $pkg\e[0m"
          missing=1
      fi
  done

  echo "=================================="

  # 输出检查结果
  if [ $missing -eq 0 ]; then
      echo -e "\e[32m所有必需的开发工具和库均已安装\e[0m"
  else
      install_offline_deps
  fi
}

# 安装 OpenSSH
install_openssh() {
    log "开始安装 OpenSSH 包..."
    PACKAGES=$(find . -type f -name "openssh-*.rpm")
    [[ -z "$PACKAGES" ]] && error_exit "找不到 openssh RPM 安装包！"

    log "记录系统当前状态..."
    PRE_INSTALL_STATE=$(mktemp -d)
    BACKUP_PKG_LIST="$PRE_INSTALL_STATE/pkg.list"
    rpm -qa --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' > "$BACKUP_PKG_LIST"

    log "即将安装的包："
    echo "$PACKAGES" | while read -r pkg; do
        log "  $(basename "$pkg")"
    done

    set +e
    if command -v yum &>/dev/null; then
        log "使用 yum 离线安装..."
        yum localinstall -y $YUM_OFFLINE_OPTS $PACKAGES >>"$LOGFILE" 2>&1
        INSTALL_STATUS=$?

        if [[ $INSTALL_STATUS -ne 0 ]]; then
            log "⚠️ yum 安装失败，尝试使用rpm命令强制安装..."
            for pkg in $PACKAGES; do
                rpm -ivh --force --nodeps "$pkg" >>"$LOGFILE" 2>&1
                [[ $? -ne 0 ]] && { INSTALL_STATUS=1; break; }
            done
        fi
    elif command -v rpm &>/dev/null; then
        log "使用 rpm 命令离线安装..."
        for pkg in $PACKAGES; do
            rpm -ivh --force --nodeps "$pkg" >>"$LOGFILE" 2>&1
            [[ $? -ne 0 ]] && { INSTALL_STATUS=1; break; }
        done
    else
        error_exit "未找到支持的包管理器（yum或rpm）"
    fi
    set -e
}

# 回滚安装
rollback_installation() {
    echo -e "\e[31m安装失败，开始执行回退...\e[0m"

    log "回退软件包变更..."
    if command -v rpm &>/dev/null; then
        CURRENT_RPMS=$(mktemp)
        rpm -qa --queryformat '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n' > "$CURRENT_RPMS"
        NEWLY_INSTALLED=$(comm -13 "$BACKUP_PKG_LIST" "$CURRENT_RPMS" | cut -d- -f1 | sort -u)
        for pkg in $NEWLY_INSTALLED; do
            rpm -e --nodeps "$pkg" && log "已卸载 $pkg" || log "卸载 $pkg 失败"
        done
        rm -f "$CURRENT_RPMS"
    fi

    log "恢复配置文件..."
    if [[ -d "$BACKUP_DIR/etc_ssh" ]]; then
        rm -rf /etc/ssh.rollback
        mv /etc/ssh /etc/ssh.rollback
        cp -a "$BACKUP_DIR/etc_ssh" /etc/ssh

        if [[ -f "$BACKUP_DIR/etc_ssh_acls.txt" ]]; then
            log "恢复ACL权限..."
            setfacl --restore="$BACKUP_DIR/etc_ssh_acls.txt" 2>/dev/null || :
        fi

        log "恢复文件时间戳..."
        while IFS= read -r line; do
            file=$(echo "$line" | awk '{print $NF}')
            timestamp=$(echo "$line" | awk '{print $6" "$7" "$8}')
            touch -d "$timestamp" "$file" 2>/dev/null || true
        done < "$BACKUP_DIR/etc_ssh_filelist.txt"
    fi

    log "恢复服务文件..."
    mapfile -t SERVICE_FILES < <(find "$BACKUP_DIR" -type f \( -path "*/sshd.service" -o -path "*/sshd.init" \))
    for backup_file in "${SERVICE_FILES[@]}"; do
        target_file="/${backup_file#$BACKUP_DIR/}"
        mkdir -p "$(dirname "$target_file")"
        cp -a "$backup_file" "$target_file" && log "已恢复服务文件：$target_file" || log "⚠️ 恢复失败：$target_file"
    done

    log "恢复二进制文件..."
    while IFS= read -r binary; do
        src_path="$BACKUP_DIR/$binary"
        dest_path="/$binary"
        if [[ -f "$src_path" ]]; then
            mkdir -p "$(dirname "$dest_path")"
            if cp -a "$src_path" "$dest_path"; then
                log "已恢复二进制文件：$dest_path"
            fi
        fi
    done < <(find "$BACKUP_DIR/usr" -type f -executable)

    log "重新加载系统配置..."
    INIT_SYSTEM=$(cat /proc/1/comm)
    case "$INIT_SYSTEM" in
        systemd)
            systemctl daemon-reexec
            systemctl daemon-reload
            ;;
        *)  # 其他系统尝试通用方式
            /etc/init.d/sshd reload 2>/dev/null || :
            ;;
    esac

    log "验证服务状态..."
    if command -v sshd &>/dev/null; then
        if systemctl is-active sshd &>/dev/null || pgrep sshd &>/dev/null; then
            log "SSH服务正在运行"
        else
            log "尝试启动SSH服务..."
            systemctl start sshd || service sshd start || /etc/init.d/sshd start && log "SSH服务启动成功" || log "⚠️ SSH服务启动失败"
        fi
    fi

    error_exit "已完成回滚操作，OpenSSH安装失败，系统已恢复原状。"
}

# 配置修复
fix_configurations() {
    log "验证配置并修复SSH密钥文件权限..."
    SSHD_CONFIG="/etc/ssh/sshd_config"
    cp -a "$SSHD_CONFIG" "$SSHD_CONFIG.offline.bak"
    log "已备份原始配置到 $SSHD_CONFIG.offline.bak"

    [[ -f "$SSHD_CONFIG" ]] && sed -i '/^StrictScpCheck/d' "$SSHD_CONFIG"

    log "检查SSH登录配置项..."
    grep -qE '^\s*PermitRootLogin\s+yes' "$SSHD_CONFIG" || {
        log "缺少PermitRootLogin yes，正在添加..."
        echo "PermitRootLogin yes" >> "$SSHD_CONFIG"
    }

    grep -qE '^\s*PasswordAuthentication\s+yes' "$SSHD_CONFIG" || {
        log "缺少PasswordAuthentication yes，正在添加..."
        echo "PasswordAuthentication yes" >> "$SSHD_CONFIG"
    }

    log "添加离线环境安全配置..."
    grep -qE '^\s*AllowTcpForwarding\s+no' "$SSHD_CONFIG" || echo "AllowTcpForwarding no" >> "$SSHD_CONFIG"
    grep -qE '^\s*X11Forwarding\s+no' "$SSHD_CONFIG" || echo "X11Forwarding no" >> "$SSHD_CONFIG"

    log "修复SSH主机密钥权限..."
    for key in /etc/ssh/ssh_host_*; do
        [[ -f "$key" ]] && chmod 600 "$key" && log "已修复权限：$key"
    done
}

# 验证配置
validate_config() {
    if sshd -t; then
        log "配置验证通过，重启服务..."
        if command -v systemctl &>/dev/null; then
            systemctl daemon-reexec
            systemctl daemon-reload
            systemctl restart sshd
        else
            /etc/init.d/sshd restart
        fi
    else
        error_exit "配置验证失败，请手动检查 $SSHD_CONFIG。"
    fi
}

# 启动并验证服务
start_and_validate_service() {
    log "启动并验证SSH服务..."
    local INIT_TYPE="unknown"
    if command -v systemctl &>/dev/null; then
        INIT_TYPE="systemd"
        systemctl daemon-reexec
        systemctl daemon-reload
        systemctl enable --now sshd
    elif command -v service &>/dev/null; then
        INIT_TYPE="sysv"
        chkconfig sshd on
        service sshd restart
    else
        INIT_TYPE="other"
        /etc/init.d/sshd restart
    fi

    sleep 3

    local SERVICE_STATUS=0
    case "$INIT_TYPE" in
        systemd)
            systemctl is-active sshd &>/dev/null || SERVICE_STATUS=1
            ;;
        sysv)
            service sshd status &>/dev/null || SERVICE_STATUS=1
            ;;
        *)
            pgrep sshd &>/dev/null || SERVICE_STATUS=1
            ;;
    esac

    if [[ $SERVICE_STATUS -ne 0 ]]; then
        log "❌ SSH 服务启动失败"
        error_exit "SSH 服务启动失败，请检查日志：$LOGFILE"
    else
        log "✅ SSH 服务启动成功"
    fi

    # 版本验证
    if command -v ssh &>/dev/null; then
        NEW_VER=$(ssh -V 2>&1 | awk '{print $1}' | cut -d'_' -f2)
        log "当前安装的 OpenSSH 版本: $NEW_VER"
    fi

    # 端口检查
    local PORT_STATUS=0
    if command -v ss &>/dev/null; then
        ss -ntl | grep -q ':22' || PORT_STATUS=1
    elif command -v netstat &>/dev/null; then
        netstat -ntl | grep -q ':22' || PORT_STATUS=1
    else
        PORT_STATUS=0
    fi

    [[ $PORT_STATUS -eq 0 ]] && log "✅ SSH 服务正在监听 22 端口" || {
        log "❌ SSH 服务未监听 22 端口"
        error_exit "SSH 服务未监听 22 端口，请检查配置"
    }
}

# 显示最终状态
show_final_status() {
    log "显示SSH服务状态..."
    if command -v systemctl &>/dev/null; then
        systemctl status sshd --no-pager
    elif command -v service &>/dev/null; then
        service sshd status
    fi

    log "🎉 SSH离线安装成功！备份路径：$BACKUP_DIR"
    log "📄 安装日志保存在：$LOGFILE"
    log "🔒 离线环境已优化，禁用了不必要的网络功能"
    log "📌 请确认所有安全配置符合您的环境要求"
}

# 删除安装包和依赖
del_clear() {
  rm -rf /root/anolis8-dev.tar.gz
  rm -rf /root/rpms
  rm -rf /root/SSH_10.0p2-rpm.tar.gz
  rm -rf /root/SSH_10.0p2-rpm.tar.gz
}

# 主函数
main() {
    init_logging
    show_welcome
    extract_package
    check_deps
    
    system_check
    manage_selinux
    check_existing_installation
    
    prepare_backup
    backup_configs
    backup_ssh_directory
    backup_service_status
    backup_service_files
    backup_binaries
    record_rpm_info
    verify_backup
    
    install_openssh
    [[ $INSTALL_STATUS -ne 0 ]] && rollback_installation
    
    fix_configurations
    validate_config
    start_and_validate_service
    show_final_status
    del_clear
}

# 执行主函数
main