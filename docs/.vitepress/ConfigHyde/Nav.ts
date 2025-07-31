// nav导航栏配置

export const Nav = [
    {text: "🏡首页", link: "/"},
    {
        text: '🗃️笔记',
        items: [
            {
                // 分组标题2
                text: `
                <div style="display: flex; align-items: center; gap: 4px;">
                  <img src="https://cdn.luoyuanxiang.top/img/nav/编程.svg" alt="" style="width: 16px; height: 16px;">
                  <span>后端</span>
                </div>
                `,
                link: '/service',
            },
            {
                text: `
                <div style="display: flex; align-items: center; gap: 4px;">
                  <img src="https://cdn.luoyuanxiang.top/img/nav/运维.svg" alt="" style="width: 16px; height: 16px;">
                  <span>运维</span>
                </div>
                `,
                link: '/operations',
            },
            {
                text: `
                <div style="display: flex; align-items: center; gap: 4px;">
                  <img src="https://cdn.luoyuanxiang.top/img/nav/前端.svg" alt="" style="width: 16px; height: 16px;">
                  <span>前端</span>
                </div>
                `,
                link: '/web',
            },
        ],
    },
    {
        text: '📝随笔',
        items: [
            {
                text: `<div style="display: flex; align-items: center; gap: 4px;">
              <img src="https://cdn.luoyuanxiang.top/img/nav/Java-Light.svg" alt="" style="width: 16px; height: 16px;">
              <span>Java代码性能优化总结</span>
            </div>`,
                link: '/Java/optimize'
            },
            // {
            //     text: `<div style="display: flex; align-items: center; gap: 4px;">
            //   <img src="https://cdn.luoyuanxiang.top/img/nav/mysql.png" alt="" style="width: 16px; height: 16px;">
            //   <span>SQL优化</span>
            // </div>`,
            //     link: '/SQL/optimize'
            // },
        ]
    },
    {
        text: '👏索引',
        items: [
            {text: '📃分类页', link: '/categories'},
            {text: '🔖标签页', link: '/tags'},
            {
                text: `
            <div style="display: flex; align-items: center; gap: 4px;">
              <img src="https://cdn.luoyuanxiang.top/img/nav/归档.svg" alt="" style="width: 16px; height: 16px;">
              <span>归档页</span>
            </div>
            `,
                link: '/archives',
            },
            {
                text: `
            <div style="display: flex; align-items: center; gap: 4px;">
              <img src="https://cdn.luoyuanxiang.top/img/nav/风险提示.svg" alt="" style="width: 16px; height: 16px;">
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
            // {text: '🎉关于本站', link: '/about-website'},
            {text: '🌐网站导航', link: '/websites'},
            // {text: "👂留言区", link: "/liuyanqu"},
            // {text: "💡思考", link: "/thinking"},
            {
                text: `
            <div style="display: flex; align-items: center; gap: 4px;">
              <img src="https://cdn.luoyuanxiang.top/img/nav/网站统计.svg" alt="" style="width: 16px; height: 16px;">
              <span>网站统计</span>
            </div>
            `,
                link: 'https://umami.luoyuanxiang.top/share/VCFFhbiG0aJn0dTf/luoyuanxiang.top',
            },
        ],
    },
]
