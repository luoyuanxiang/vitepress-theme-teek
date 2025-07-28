// nav导航栏配置

export const Nav = [
    {text: "🏡首页", link: "/"},
    // 笔记
    {
        text: '🏓主题',
        items: [
            {
                text: '指南',
                items: [
                    {
                        text: `
                <div style="display: flex; align-items: center; gap: 4px;">
                  <img src="/img/nav/teek.svg" alt="" style="width: 16px; height: 16px;">
                  <span>指南</span>
                </div>
                `,
                        link: '/guide',
                    },
                ],
            },
            {
                text: '配置',
                items: [
                    {
                        text: `
                <div style="display: flex; align-items: center; gap: 4px;">
                  <img src="/img/nav/teek.svg" alt="" style="width: 16px; height: 16px;">
                  <span>配置</span>
                </div>
                `,
                        link: '/reference',
                    },
                ],
            },
            {
                text: '主题开发',
                items: [
                    {
                        text: `
                <div style="display: flex; align-items: center; gap: 4px;">
                  <img src="/img/nav/teek.svg" alt="" style="width: 16px; height: 16px;">
                  <span>主题开发</span>
                </div>
                `,
                        link: '/develop',
                    },
                ],
            },
        ]
    },
    {
        text: '🗃️笔记',
        items: [
            {
                // 分组标题2
                text: `
                <div style="display: flex; align-items: center; gap: 4px;">
                  <img src="/img/nav/Java-Light.svg" alt="" style="width: 16px; height: 16px;">
                  <span>后端</span>
                </div>
                `,
                link: '/service',
            },
            {
                text: `
                <div style="display: flex; align-items: center; gap: 4px;">
                  <img src="/img/nav/linux.svg" alt="" style="width: 16px; height: 16px;">
                  <span>运维</span>
                </div>
                `,
                link: '/operations',
            },
            {
                text: `
                <div style="display: flex; align-items: center; gap: 4px;">
                  <img src="/img/nav/html.png" alt="" style="width: 16px; height: 16px;">
                  <span>前端</span>
                </div>
                `,
                link: '/web',
            },
        ],
    },
    {
        text: '👏索引',
        items: [
            {text: '📃分类页', link: '/categories'},
            {text: '🔖标签页', link: '/tags'},
            {
                text: `
            <div style="display: flex; align-items: center; gap: 4px;">
              <img src="/img/nav/归档.svg" alt="" style="width: 16px; height: 16px;">
              <span>归档页</span>
            </div>
            `,
                link: '/archives',
            },
            {
                text: `
            <div style="display: flex; align-items: center; gap: 4px;">
              <img src="/img/nav/风险提示.svg" alt="" style="width: 16px; height: 16px;">
              <span>风险链接提示页</span>
            </div>
            `,
                link: '/risk-link?target=https://onedayxyy.cn/',
            },
        ],
    },

    // 关于
    {
        text: '🍷关于',
        items: [
            {text: '👋关于我', link: '/about-me'},
            {text: '🎉关于本站', link: '/about-website'},
            {text: '🌐网站导航', link: '/websites'},
            {text: "👂留言区", link: "/liuyanqu"},
            {text: "💡思考", link: "/thinking"},
            {
                text: `
            <div style="display: flex; align-items: center; gap: 4px;">
              <img src="/img/nav/网站统计.svg" alt="" style="width: 16px; height: 16px;">
              <span>网站统计</span>
            </div>
            `,
                link: 'https://umami.luoyuanxiang.top/share/VCFFhbiG0aJn0dTf/luoyuanxiang.top',
            },
        ],
    },
]
