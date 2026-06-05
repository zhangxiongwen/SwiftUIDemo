# Navigator 导航门面

## 业务 API vs 框架内部 API

### 业务直接使用（公开）

| 类型 | 名称 | 用途 |
|------|------|------|
| 类 | `Navigator` | `@State` 持有，调用 push / present / back |
| 修饰符 | `.navigator(_:)` | 页面根挂载，绑定宿主 router + 本页 ViewPresenter |
| 修饰符 | `.navigatorRouterScope(_:)` | Cover 内被 push 出的子页，对齐内层 router |

**统一写法**：每个页面根视图 `@State private var navigator = Navigator()` + `.navigator(navigator)`。Cover / 子页无需 `@Environment`；`.navigator` 检测到上层 `sharedNavigator` 时自动 `bindUpstream`，`back()` / `present` / `push` 内部转发到宿主。

### 框架内部（业务勿调用）

| 名称 | 调用方 | 作用 |
|------|--------|------|
| `attach`（fileprivate） | `.navigator` → `NavigatorHostBinding` | 绑定宿主 AppRouter + ViewPresenter |
| `bindPresentationRouter`（fileprivate） | `PresentedNavigationHost.onAppear` | Cover 打开时切到内层 router |
| `clearPresentationRouter`（fileprivate） | `PresentedNavigationHost.onDisappear` | Cover 关闭时恢复宿主 router |
| `rebindRouter`（fileprivate） | `.navigatorRouterScope` | 子页 onAppear 对齐环境 router |
| `PresentedNavigationHost` | `ViewPresenter.presentNavigationPage` | 内层 Nav + 独立 router + 全量路由 |

实现均在 `Navigator.swift` 底部 **「框架内部 · Modifier」** 区；绑定方法为 `fileprivate`，模块内其他文件无法调用。

---

`Navigator` 把 **NavigationStack 跳转**（`AppRouter`）和 **弹层展示**（`ViewPresenter`）合并成单一入口，业务页面只需：

```swift
@State private var navigator = Navigator()

var body: some View {
    content
        .navigator(navigator)
}
```

底层 `AppRouter` / `ViewPresenter` 逻辑不变，`Navigator` 只做转发与 router 作用域切换。

---

## 架构总览

```text
RootView
  @State router = AppRouter()
  NavigationStack(path: router.path)
    .environment(router)
    └── 各 Feature 页面
          @State navigator = Navigator()
          .navigator(navigator)          ← 绑定宿主 router + 本页 ViewPresenter
                │
                ├── navigator.push(...)     → 宿主 AppRouter.path
                ├── navigator.presentAlert  → 本页 ViewPresenter 队列
                └── navigator.presentNavigationPage { ... }
                          │
                          └── fullScreenCover
                                PresentedNavigationHost
                                  @State 内层 router = AppRouter()   ← 新建，与宿主隔离
                                  navigationStackRouter(..., AppRouteRegistry.all)
                                  .environment(内层 router)
                                  .environment(navigator)              ← 同一 Navigator
                                  onAppear  → bindPresentationRouter
                                  onDisappear → clearPresentationRouter
                                        │
                                        └── Cover 根视图 / push 子页
                                              navigator.push → 内层 router.path
                                              navigator.back() → 先 pop 内层，再 dismiss Cover
```

---

## 三个核心对象

| 对象 | 职责 | 谁创建 |
|------|------|--------|
| `AppRouter` | `NavigationStack` 的 `path`，`push` / `pop` / `pushPath` | 根视图或 `PresentedNavigationHost` 各一份 |
| `ViewPresenter` | Alert / Sheet / 整页 Cover 队列 | `.navigator` modifier 内 `@State`，每页一个 |
| `Navigator` | 统一 API，按场景选择上面两个 | 业务页 `@State` |

---

## presentPage vs presentNavigationPage

| | `presentPage` | `presentNavigationPage` |
|---|---------------|-------------------------|
| 内层 NavigationStack | 无 | 有（`PresentedNavigationHost`） |
| 内层 AppRouter | 无 | 新建独立实例 |
| 路由注册 | 无 | `AppRouteRegistry.all` 全量注册 |
| Cover 内 `push` | 写到**宿主** path，页面在 Cover 下面 | 写到**内层** path，正常可见 |
| 典型场景 | 模版 App 根视图（自带导航） | 需在弹层模块里继续路由跳转 |

---

## router 作用域切换

宿主页与 Cover 共用**同一个** `Navigator`，但 push/pop 可能对应**两个** `AppRouter`：

```text
平时：navigator.router = 宿主 hostRouter（来自 .navigator 环境的 AppRouter）

presentNavigationPage 打开：
  PresentedNavigationHost.onAppear → bindPresentationRouter(内层 router)
  navigator.router = 内层 presentationRouter

Cover 关闭：
  PresentedNavigationHost.onDisappear → clearPresentationRouter()
  navigator.router = 宿主 hostRouter
```

绑定由框架 Modifier 在 `onAppear` / `onDisappear` 完成，业务**不要**自行调用 `attach` / `bindPresentationRouter`（已 private，且在 `body` 里改 `@Observable` 会卡死）。

---

## 两层 Present 模型

```text
pageCover 槽     → presentPage / presentNavigationPage（整页，不入弹窗队列）
dialogStack 队列 → presentAlert / presentActionSheet / presentCustomView
```

Cover 内 `presentAlert` 时，**整页保持挂载**，弹窗叠在 Cover 之上；关弹窗后 Cover 立即恢复，不会「整页消失」。

## back() 决策顺序

```text
dialogStack 非空      → dismiss()           // 关掉最上层弹窗
有 pageCover
  ├─ presentNavigationPage 且内层有 push → pop()
  └─ 否则                               → dismissCover()
NavigationStack 有 push → pop()
否则                  → 无操作，执行 complete
```

---

## Dismiss API（统一弹层队列）

| 方法 | 作用 |
|------|------|
| `dismiss()` | 关闭弹层栈顶一层（Alert / ActionSheet / custom / Cover） |
| `dismissCover()` | 仅当栈顶为整页 Cover 时关闭；Cover 内有多层 push 也可一次关掉整个模块 |
| `dismissAllDialog()` | 立即清空全部弹层队列（无逐层动画） |
| `back()` | 导航栏返回：按上表决策顺序自动 dismiss / pop |

底部 Sheet 样式请用 `presentCustomView(style: .sheet)`，与 Alert 等同走队列，统一 `dismiss()` 关闭。

---

## 页面写法速查

### 普通页面（宿主栈内）

```swift
struct MyDemoView: View {
    @State private var navigator = Navigator()

    var body: some View {
        List {
            Button("跳转") {
                navigator.push(CustomViewsRoute.toastDemo)
            }
            Button("弹窗") {
                navigator.presentCommonAlert(title: "提示", message: "内容")
            }
        }
        .baseNavigationBar(title: "Demo", onBack: { navigator.back() })
        .navigator(navigator)
    }
}
```

### 整页 Cover 根视图（由 present 闭包构建）

```swift
struct CoverRootView: View {
    @State private var navigator = Navigator()

    var body: some View {
        content
            .baseNavigationBar(title: "Cover", onBack: { navigator.back() })
            .navigator(navigator)
        // presentNavigationPage 时 PresentedNavigationHost 已 bind 内层 router
    }
}
```

### Cover 内被 push 出来的子页（路由注册构建）

```swift
struct PushedChildView: View {
    @State private var navigator = Navigator()

    var body: some View {
        content
            .navigator(navigator)
            .navigatorRouterScope(navigator)
    }
}
```

---

## 相关文件

| 文件 | 说明 |
|------|------|
| `Navigation/Navigator.swift` | 门面实现与 API 注释 |
| `Navigation/Navigator.swift`（底部 `PresentedNavigationHost`） | `presentNavigationPage` 内层 Nav + router |
| `Presentation/ViewPresenter.swift` | 弹层队列 |
| `Router/AppRouter.swift` | NavigationStack path |
| `Router/AppRouteRegistry.swift` | 全量路由注册 |

---

## API 索引

完整每个方法的参数说明见 `Navigator.swift` 内 `///` 文档注释，主要包括：

- **状态**：`stackDepth`、`isPresentingPage`、`isPresentingStack`、`hasPushedPages`、`canBack`
- **Router**：`push`、`pushPath`、`pushDepth`、`pop`、`pop(steps:)`、`popToRoot`
- **Present**：`presentAlert`、`presentCommonAlert`、`presentActionSheet`、`presentCustomView`、`presentPage`、`presentNavigationPage`
- **Dismiss**：`dismiss`、`dismissCover`、`dismissAllDialog`
- **统一返回**：`back`
- **View 扩展**：`.navigator(_:)`、`.navigatorRouterScope(_:)`
