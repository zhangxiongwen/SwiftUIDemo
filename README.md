# SwiftUIDemo

基于 [IOS-App-Template](https://github.com/rongguanhui/IOS-App-Template) 搭建的 SwiftUI 学习 / 演示项目。

- **Swift** 5.0
- **iOS** 18.5+（SwiftUI 5 能力）
- **架构**：SwiftUI + MVVM + 模块化目录

## 目录结构

```text
SwiftUIDemo/
├── App/                    # 入口、根布局、路由注册、环境配置
├── Core/AppBaseComponents/ # 导航门面、路由、弹层、导航栏、TabBar、HUD
├── DesignSystem/           # AppColors、AppFonts
│   └── Components/         # 可复用 UI：Dialog、NavigationBar、TabBar、Toast…
├── Services/               # 网络、存储、系统能力
├── Managers/               # 用户状态、Toast 等全局状态
├── Features/
│   ├── DemoPage/           # DemoRootView + SystemViews / CustomViews / Async / Tools
│   └── 模版/               # 原脚手架：Auth、Home、Settings + TemplateRootView
├── Data/Models/            # 跨模块数据模型
└── Resources/              # Assets、Localizable.xcstrings
```

## 快速开始

1. 用 Xcode 打开 `SwiftUIDemo.xcodeproj`
2. 等待 SPM 解析 **Kingfisher** 依赖
3. 选择模拟器运行（⌘R）

## 配置

- 环境与 Mock：`SwiftUIDemo/App/AppConfig.swift`
- 路由注册：`SwiftUIDemo/Core/AppBaseComponents/Router/AppRouteRegistry.swift`
- 重命名其他工程名：`python3 rename_project.py SwiftUIDemo <新名称>`

## 导航（Navigator）

页面统一使用 `Navigator` 处理 push 与 present，详见：

**[Navigator.md](SwiftUIDemo/Core/AppBaseComponents/Navigation/Navigator.md)**

快速接入：

```swift
@State private var navigator = Navigator()

var body: some View {
    content
        .navigator(navigator)
}
```

## 下一步

基础框架已就绪，可按业务继续扩展 Feature、Endpoint 与数据模型。
