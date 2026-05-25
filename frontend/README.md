# 价格监控系统前端

React + Vite + TypeScript + Ant Design + Figma Design System（黑白核心 + 马卡龙色块 + 胶囊按钮）前端应用。

## 安装

```bash
npm install
```

## 开发

```bash
# 确保后端运行在 http://127.0.0.1:8000
npm run dev
```

前端运行在 http://localhost:3000，自动代理 `/api` 请求到后端。

## 构建

```bash
npm run build
```

产物输出到 `dist/` 目录。

## 目录结构

```
src/
├── features/       # 按业务域组织页面、组件、hooks、api、types
│   ├── dashboard/  # KPI 卡片、趋势图、SSE hook
│   ├── products/   # 商品管理
│   ├── jobs/       # 职位配置、职位列表、简历匹配
│   ├── schedule/   # 商品/职位 cron 配置
│   ├── admin/      # 用户、审计、RBAC 权限矩阵
│   └── auth/       # 登录、注册、资料
├── shared/         # axios client、AuthContext、布局、公共类型/组件
├── styles/         # Figma Design System（design-tokens.css + components.css）
├── App.tsx         # 路由与布局
└── main.tsx        # 入口，QueryClientProvider
```

## 功能

- **仪表盘**: KPI 卡片、趋势图、平台/薪资分布、SSE 实时更新；管理员可查看系统健康和最近告警
- **商品管理页**: CRUD 操作、批量导入/删除/启停、分页（15条/页）、多条件筛选
- **职位管理页**: 搜索配置管理、职位列表（含可点击链接跳转Boss详情页）、单配置/全量爬取
- **定时配置页**: 商品 per-platform cron 配置表（添加/修改/删除定时器）、职位 per-config cron 配置表、数据保留天数 + 飞书 Webhook URL 设置
- **权限控制**: UI 根据后端返回的 RBAC `permissions` 控制菜单和操作入口
- **告警管理**: 商品级别价格告警设置，在编辑弹窗内集成
- **爬取日志面板**: 实时查看爬取状态和历史记录
- **无障碍支持**: WCAG 合规（键盘导航、aria 属性、减少动画偏好）
- **移动端适配**: 侧边栏在移动端自动变为 Drawer 抽屉
