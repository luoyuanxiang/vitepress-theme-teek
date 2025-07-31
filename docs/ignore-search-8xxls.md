---
title: 忽略搜索
date: '2024-01-19 20:55:43'
head: []
outline: deep
sidebar: false
prev: false
next: false
---



# 忽略搜索

## 概述

忽略搜索指的是在搜索时过滤掉某些不需要的结果。

## 使用方式

忽略全局搜索和忽略引用搜索需要分开配置：

- 忽略全局搜索：在文件系统上手动创建或编辑 `工作空间/data/.siyuan/searchignore` 文本文件
- 忽略引用搜索：在文件系统上手动创建或编辑 `工作空间/data/.siyuan/refsearchignore` 文本文件

这些 ignore 配置文件中的每一行会被作为 SQL path NOT LIKE 的一个条件，例如：

```
path NOT LIKE '/20210808180117-6v0mkxr%'
box != '20210808180117-czj9bvb'
id != '20200923234011-ieuun1p'
```

- ​`path NOT LIKE '/20210808180117-6v0mkxr%'`：忽略所在文档路径以 ​/20210808180117-6v0mkxr 开头的内容块搜索
- ​`box != '20210808180117-czj9bvb'`：忽略 data/20210808180117-czj9bvb 笔记本下的内容块搜索
- ​`id != '20200923234011-ieuun1p'`：忽略 id 为 20200923234011-ieuun1p 的内容块搜索

配置文件修改保存后需要等待 30 秒才会生效。
