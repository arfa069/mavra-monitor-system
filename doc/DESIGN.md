# Design System — Price Monitor & Job Tracker

## Product Context

- **What this is:** 电商价格监控系统（支持淘宝、京东、亚马逊）+ Boss直聘职位搜索监控后台。自动抓取商品/职位信息，价格降价时通过飞书 Webhook 推送告警。
- **Who it's for:** 个人用户或小型团队，需要同时监控多个电商平台价格和职位机会的运营/采购人员。
- **Space/industry:** 电商工具 / 价格追踪 / 后台管理系统（Dashboard）
- **Project type:** Web App / Dashboard / Internal Tool
- **Tech stack:** React 18 + Vite + TypeScript + Ant Design 5

## Aesthetic Direction

- **Direction:** Neo-Brutalist Zine (新粗野主义杂志风)
- **Decoration level:** Expressive (高对比度、粗描边、硬投影、手写贴纸感)
- **Mood:** 强烈、个性、专业。用黑白坚硬的骨架（3px solid black 边框）确立工具的安全感与力量感；用高对比度的波普淡色块（Macaron 2.0）打破传统管理系统的无聊与沉闷，创造一种仿佛在翻阅先锋独立杂志（Zine）的视觉冲击力。
- **Memorable thing:** 绝不无聊、高度耐看、富有报刊印刷张力的极客仪表盘。

## Typography

- **Display/Hero:** Syne — 极具艺术感与几何张力的无衬线字体，大字号下拥有独特的现代解构美感，用于品牌标识、Hero 区域与大标题。
- **Body:** Outfit — 亲和且极易阅读的几何无衬线体，小字号下表现优异，用于正文段落和表单说明。
- **UI/Labels:** Outfit (Same as body) — 部分表头或导航项采用 uppercase 并加重字重。
- **Data/Tables:** Space Grotesk — 充满工业美学特质的几何等宽数字字体，最适合价格对齐和高精度数值呈现。
- **Code:** JetBrains Mono — 用于开发日志、定时表达式及底层配置代码。
- **Loading:**
  - Syne：Google Fonts (`https://fonts.googleapis.com/css2?family=Syne:wght@700;800&display=swap`)
  - Outfit：Google Fonts (`https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&display=swap`)
  - Space Grotesk：Google Fonts (`https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&display=swap`)
  - 使用 `font-display: swap` 防止 FOIT。
- **Scale:**
  | Token | Size | Weight | Line Height | Letter Spacing | Usage |
  |-------|------|--------|-------------|----------------|-------|
  | Hero / Display XL | clamp(32px, 5vw, 48px) | 800 | 1.0 | -1.0px | 登录页品牌标题（Syne） |
  | Display | 28px | 800 | 1.1 | -0.5px | 页面大标题（Syne） |
  | Headline | 20px | 800 | 1.35 | -0.2px | 区块标题、卡片标题（Syne） |
  | Lead | 16px | 400 | 1.45 | -0.1px | 引导段落（Outfit） |
  | Body | 14px | 400 | 1.5 | -0.2px | 正文、表格内容（Outfit） |
  | Small | 13px | 400 | 1.5 | -0.1px | 辅助文字、次要信息（Outfit） |
  | Micro | 11px | 600 | 1.3 | 0.05em | 极小标签、元信息（Outfit） |
  | Mono / Eyebrow | 12px | 700 | 1.3 | 0.5px | 代码标签、表头（Space Grotesk, uppercase）|

## Color

- **Approach:** Pop Art Contrast (波普撞色 + 绝对描边)
- **Primary:** `#000000` (墨黑) — 文字、核心边框、交互主要按钮
- **Canvas:** `#f8f6f0` (纸张暖白) — 页面大背景
- **Surface Soft:** `#fbf6e3` (复古象牙黄) — 卡片备用色、输入框背景、代码块背景
- **Hairline / Border:** `#000000` (绝对黑线) — 所有卡片、按钮、容器边框，宽度固定为 3px
- **Muted:** `#666666` — 极少数非关键辅助文字（其余多使用墨黑配合字重区分）

- **Color Blocks (波普撞色色块 - 语义化映射)：**
  | Name | Hex | Semantic | Used For |
  |------|-----|----------|----------|
  | Yellow | `#FBEE6B` | 强调/高亮 | 品牌主标志、核心强调块 |
  | Lime | `#B8F2A1` | 成功/抓取 | 价格下降标识、商品标题色块、抓取完成状态 |
  | Pink | `#FFB3D9` | 警报/急聘 | 告警卡片、职位搜索急聘卡片、报错及警报状态 |
  | Lilac | `#D2C1FB` | 配置/用户 | 设置页标题、定时调度配置、用户账户相关卡片 |
  | Cyan | `#99F0F9` | 系统/信息 | 页面头部条状横幅、常规监控正常状态、信息提示 |
  | Orange | `#FFB88C` | 交互/警告 | 切换按钮、橙色徽章、中度警示 |

- **Dark Mode (赛博高刷粗野模式)：**
  当切换到赛博暗色模式时，画布变为极深曜石色，边框反转为纯白描边，色块升级为发光霓虹：
  - Canvas → `#0e0e11`
  - Primary → `#ffffff`
  - Border → `#ffffff` (宽度维持 3px，投影阴影色同步反转为 `#ffffff`)
  - Swatches (发光霓虹模式):
    - Yellow: `#f8e400`
    - Lime: `#00ff66`
    - Pink: `#ff007f`
    - Lilac: `#8b3dff`
    - Cyan: `#00f0ff`
    - Orange: `#ff7f00`
    - Cream/Surface Soft: `#1b1b24`

## Spacing

- **Base unit:** 4px
- **Density:** 紧凑 (Compact) / 舒适 (Comfortable)
- **Scale:**
  | Token | Value | Usage |
  |-------|-------|-------|
  | hair | 3px | 核心粗边框 / 分割线线宽 |
  | xxs | 4px | 按钮图标间距、紧凑内边距 |
  | xs | 8px | 标签内边距、按钮内侧间距 |
  | sm | 12px | 表单行间距、常规组件间隙 |
  | md | 16px | 表格行内边距、卡片行距 |
  | lg | 24px | 卡片内部内边距、区块外边距 |
  | xl | 32px | 页面大边距、大区块间隔 |
  | xxl | 48px | 登录面板大留白 |

## Layout

- **Approach:** Grid-disciplined + Layered Asymmetry (网格对齐 + 错位重叠)
- **Grid:** 12列网格，大屏严格对齐数据表，小屏适配折叠。
- **Max content width:** 1280px。
- **Border radius hierarchy:** 粗野主义不提倡大圆角，采用低圆角设计维持硬朗感。
  - sm: 4px — 徽章、提示框
  - md: 8px — 输入框、小卡片
  - lg: 16px — 大卡片、数据表容器、面板
  - pill: 9999px — 状态胶囊标签、圆形头像
- **Elevation (硬投影阴影):**
  新粗野主义不使用任何软模糊阴影 (blur: 0)，取而代之的是纯色硬边错位阴影：
  - Card / Panel Shadow: `box-shadow: 6px 6px 0px #000000`
  - Interactive Button Shadow: `box-shadow: 3px 3px 0px #000000`
  - Active / Expanded State: `box-shadow: 10px 10px 0px #000000`
  - Dark Mode: 对应阴影色反转为 `#ffffff` 

## Motion

- **Approach:** Snappy + Bounce (清脆硬朗与轻微弹跳)
- **Easing:** `cubic-bezier(0.175, 0.885, 0.32, 1.275)` (轻微回弹/过冲)
- **Interactive Rules:**
  - Hover 效果：当鼠标悬浮在卡片/按钮上时，产生向左上角平移且硬阴影向右下角伸展的动效：
    ```css
    transform: translate(-3px, -3px);
    box-shadow: 9px 9px 0px #000000;
    ```
  - Active 效果：当点击按钮时，产生向右下角压实且阴影消失的动效，创造极强的交互反响：
    ```css
    transform: translate(3px, 3px);
    box-shadow: 0px 0px 0px #000000;
    ```
  - Duration scale:
    - Micro: 80ms (Hover 状态的平移缩回)
    - Short: 150ms (弹窗弹出、卡片翻转)
    - Medium: 250ms (路由过渡动画)

## Decisions Log

| Date       | Decision                                            | Rationale                                                                                                               |
|------------|-----------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------|
| 2026-05-11 | Initial design system documented                    | Created by /design-consultation based on existing Figma Marketing Style implementation                                  |
| 2026-05-11 | Replace Inter with General Sans + DM Sans           | Inter is overused in AI-generated designs; General Sans adds modern character without sacrificing professionalism       |
| 2026-06-08 | Migrate to Neo-Brutalist Zine design system        | Selected via user choices to implement a highly visually distinct, high-contrast, premium pop art layout for monitors.    |
| 2026-06-08 | Introduce Syne + Outfit + Space Grotesk typography   | Syne adds raw header personality; Outfit handles micro-readability; Space Grotesk formats price alignment with precision.|
| 2026-06-08 | Revamp color palette to Pop Art Macaron 2.0         | Added bold 3px black strokes with offset flat shadows to represent a retro zine look; dark mode flips to white borders.  |
