//
//  Navigator.swift
//  SwiftUIDemo
//
//  统一门面：转发 AppRouter（push/pop）与 ViewPresenter（present/dismiss）。
//  业务页面用法：@State private var navigator = Navigator() + .navigator(navigator)
//
//  架构说明见同目录 Navigator.md
//

import SwiftUI

// MARK: - Navigator

/// 页面级导航门面。
///
/// 将 **NavigationStack 跳转**（`AppRouter`）与 **弹层展示**（`ViewPresenter`）合并为单一入口，
/// 业务代码只需持有 `Navigator`，无需直接操作 router / presenter。
///
/// ### 绑定方式
/// - 页面根视图：`@State private var navigator = Navigator()`，再 `.navigator(navigator)`
/// - `.navigator` 会读取环境中的宿主 `AppRouter`，并为本页创建 `ViewPresenter`
/// - `presentNavigationPage` 打开后，`PresentedNavigationHost` 会临时把 push/pop 切到 Cover 内独立 router
///
/// ### 注意
/// - 不要在 `View.body` 里修改 `Navigator` 内部状态（会触发 `@Observable` 死循环）
/// - Cover 内继续 push 的子页，通过 `sharedNavigator` 或 `.navigatorRouterScope` 复用同一实例
@Observable
final class Navigator {

    /// 子页面 `.navigator` 自动绑定的宿主；业务无感，统一写 `@State navigator` 即可。
    private weak var upstream: Navigator?
    private var router: AppRouter?
    private var presenter: ViewPresenter?
    private var hostRouter: AppRouter?
    private var presentationRouter: AppRouter?
    private var isPresentationRouterScoped = false

    // MARK: - 状态（只读）

    /// 弹窗队列深度（Alert / ActionSheet / 自定义）；**不含**整页 Cover。
    var stackDepth: Int {
        upstream?.stackDepth ?? (presenter?.stackDepth ?? 0)
    }

    /// 是否正在展示整页 Cover（`presentPage` / `presentNavigationPage`）。
    var isPresentingPage: Bool {
        upstream?.isPresentingPage ?? (presenter?.isPresentingPage ?? false)
    }

    /// 是否正在展示任意 present 内容（Cover 或弹窗）。
    var isPresentingStack: Bool {
        upstream?.isPresentingStack ?? (presenter?.isPresentingStack ?? false)
    }

    var hasPushedPages: Bool {
        upstream?.hasPushedPages ?? (router?.hasPushedPages ?? false)
    }

    var canBack: Bool {
        if let upstream { return upstream.canBack }
        guard let presenter, let router else { return false }
        if presenter.stackDepth > 0 { return true }
        if presenter.isPresentingPage { return true }
        if router.hasPushedPages { return true }
        return false
    }

    // MARK: - Router（NavigationStack push / pop）

    /// 压入路径路由（`AppPathRoute`），可选 query / extra。
    ///
    /// 全 App 统一跳转方式；路由须在 `navigationStackRouter` 中注册。
    ///
    /// - Parameters:
    ///   - route: 路径枚举，如 `CustomViewsRoute.toastDemo`、`TemplateRoute.profile`
    ///   - query: URL 风格参数字典，目标页从 `RoutePush.query` 读取
    ///   - extra: 可选附加对象（会包装为 `AnyHashable`）
    ///
    /// - Note: `presentNavigationPage` 内调用时，写入 Cover 内层 router。
    func push<R: AppPathRoute>(
        _ route: R,
        query: [String: String] = [:],
        extra: (any Hashable)? = nil
    ) {
        if let upstream {
            upstream.push(route, query: query, extra: extra)
            return
        }
        router?.push(route, query: query, extra: extra)
    }

    /// 以字符串路径压入页面，支持路径内 query 与额外合并。
    ///
    /// 示例：
    /// ```swift
    /// navigator.pushPath("/routeParamsDemo?title=hello&count=3")
    /// navigator.pushPath("/presentThenPushTarget", query: ["from": "path"])
    /// ```
    ///
    /// - Parameters:
    ///   - pathString: 以 `/` 开头的路径，可含 `?key=value&…`
    ///   - query: 与路径内 query 合并的字典（同名 key 以入参为准）
    ///   - extra: 可选附加对象
    ///
    /// - Note: 路径未注册时 push 404 占位页（`RouteNotFound`）。
    func pushPath(
        _ pathString: String,
        query: [String: String] = [:],
        extra: (any Hashable)? = nil
    ) {
        if let upstream {
            upstream.pushPath(pathString, query: query, extra: extra)
            return
        }
        router?.pushPath(pathString, query: query, extra: extra)
    }

    /// 当前生效 router 的 push 深度（NavigationStack 已压入页数，不含栈根）。
    var pushDepth: Int {
        upstream?.pushDepth ?? (router?.pushDepth ?? 0)
    }

    /// 弹出 NavigationStack 栈顶一页。
    func pop() {
        if let upstream { upstream.pop(); return }
        router?.pop()
    }

    /// 连续后退多页；`steps <= 0` 无操作，超出当前深度时只退到栈根。
    ///
    /// 示例：push 了 A→B→C 后 `pushDepth == 3`，`pop(steps: 2)` 去掉 C、B，回到 A。
    func pop(steps: Int) {
        if let upstream { upstream.pop(steps: steps); return }
        router?.pop(steps: steps)
    }

    /// 清空 push 栈，回到 NavigationStack 栈根。
    func popToRoot() {
        if let upstream { upstream.popToRoot(); return }
        router?.popToRoot()
    }

    // MARK: - Present（ViewPresenter 弹层）

    /// 展示 Alert 弹窗（纯文案 + 按钮）。
    ///
    /// - Parameters:
    ///   - title: 标题，可为 nil
    ///   - message: 正文，可为 nil
    ///   - buttons: 按钮列表，使用 `DialogButton.cancel` / `.default` 等构建
    ///   - dismissOnBackgroundTap: 点击遮罩是否关闭，Alert 默认 `false`
    func presentAlert(
        title: String? = nil,
        message: String? = nil,
        buttons: [DialogButton],
        dismissOnBackgroundTap: Bool = false
    ) {
        if let upstream {
            upstream.presentAlert(
                title: title,
                message: message,
                buttons: buttons,
                dismissOnBackgroundTap: dismissOnBackgroundTap
            )
            return
        }
        presenter?.presentAlert(
            title: title,
            message: message,
            buttons: buttons,
            dismissOnBackgroundTap: dismissOnBackgroundTap
        )
    }

    /// 展示带自定义内容区的 Alert 弹窗。
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 说明文字（显示在自定义内容上方）
    ///   - dismissOnBackgroundTap: 点击遮罩是否关闭
    ///   - content: 自定义 SwiftUI 内容（如表单、示意图）
    ///   - buttons: 底部按钮
    func presentAlert<Content: View>(
        title: String? = nil,
        message: String? = nil,
        dismissOnBackgroundTap: Bool = false,
        @ViewBuilder content: () -> Content,
        buttons: [DialogButton]
    ) {
        if let upstream {
            upstream.presentAlert(
                title: title,
                message: message,
                dismissOnBackgroundTap: dismissOnBackgroundTap,
                content: content,
                buttons: buttons
            )
            return
        }
        presenter?.presentAlert(
            title: title,
            message: message,
            dismissOnBackgroundTap: dismissOnBackgroundTap,
            content: content,
            buttons: buttons
        )
    }

    /// 展示双按钮通用 Alert（取消 + 确认），无自定义内容区。
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 正文
    ///   - cancelBtnText: 取消按钮文案，nil 则不显示取消钮
    ///   - confirmBtnText: 确认按钮文案，nil 则不显示确认钮
    ///   - dismissOnBackgroundTap: 点击遮罩是否关闭
    ///   - cancelBtnTap: 取消回调（在 dismiss 完成后执行）
    ///   - confirmBtnTap: 确认回调（在 dismiss 完成后执行）
    func presentCommonAlert(
        title: String? = nil,
        message: String? = nil,
        cancelBtnText: String? = nil,
        confirmBtnText: String? = nil,
        dismissOnBackgroundTap: Bool = false,
        cancelBtnTap: (() -> Void)? = nil,
        confirmBtnTap: (() -> Void)? = nil
    ) {
        if let upstream {
            upstream.presentCommonAlert(
                title: title,
                message: message,
                cancelBtnText: cancelBtnText,
                confirmBtnText: confirmBtnText,
                dismissOnBackgroundTap: dismissOnBackgroundTap,
                cancelBtnTap: cancelBtnTap,
                confirmBtnTap: confirmBtnTap
            )
            return
        }
        presenter?.presentCommonAlert(
            title: title,
            message: message,
            cancelBtnText: cancelBtnText,
            confirmBtnText: confirmBtnText,
            dismissOnBackgroundTap: dismissOnBackgroundTap,
            cancelBtnTap: cancelBtnTap,
            confirmBtnTap: confirmBtnTap
        )
    }

    /// 展示带自定义内容区的双按钮通用 Alert。
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 说明文字
    ///   - dismissOnBackgroundTap: 点击遮罩是否关闭
    ///   - content: 自定义内容区
    ///   - cancelBtnText: 取消按钮文案
    ///   - confirmBtnText: 确认按钮文案
    ///   - cancelBtnTap: 取消回调
    ///   - confirmBtnTap: 确认回调
    func presentCommonAlert<Content: View>(
        title: String? = nil,
        message: String? = nil,
        dismissOnBackgroundTap: Bool = false,
        @ViewBuilder content: () -> Content,
        cancelBtnText: String? = nil,
        confirmBtnText: String? = nil,
        cancelBtnTap: (() -> Void)? = nil,
        confirmBtnTap: (() -> Void)? = nil
    ) {
        if let upstream {
            upstream.presentCommonAlert(
                title: title,
                message: message,
                dismissOnBackgroundTap: dismissOnBackgroundTap,
                content: content,
                cancelBtnText: cancelBtnText,
                confirmBtnText: confirmBtnText,
                cancelBtnTap: cancelBtnTap,
                confirmBtnTap: confirmBtnTap
            )
            return
        }
        presenter?.presentCommonAlert(
            title: title,
            message: message,
            dismissOnBackgroundTap: dismissOnBackgroundTap,
            content: content,
            cancelBtnText: cancelBtnText,
            confirmBtnText: confirmBtnText,
            cancelBtnTap: cancelBtnTap,
            confirmBtnTap: confirmBtnTap
        )
    }

    /// 展示 ActionSheet 风格底部弹窗（纯文案 + 按钮）。
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 说明
    ///   - buttons: 操作按钮列表
    ///   - dismissOnBackgroundTap: 点击遮罩是否关闭，默认 `true`
    func presentActionSheet(
        title: String? = nil,
        message: String? = nil,
        buttons: [DialogButton],
        dismissOnBackgroundTap: Bool = true
    ) {
        if let upstream {
            upstream.presentActionSheet(
                title: title,
                message: message,
                buttons: buttons,
                dismissOnBackgroundTap: dismissOnBackgroundTap
            )
            return
        }
        presenter?.presentActionSheet(
            title: title,
            message: message,
            buttons: buttons,
            dismissOnBackgroundTap: dismissOnBackgroundTap
        )
    }

    /// 展示带自定义内容区的 ActionSheet 风格底部弹窗。
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - message: 说明
    ///   - dismissOnBackgroundTap: 点击遮罩是否关闭
    ///   - content: 自定义内容（显示在按钮上方）
    ///   - buttons: 底部操作按钮
    func presentActionSheet<Content: View>(
        title: String? = nil,
        message: String? = nil,
        dismissOnBackgroundTap: Bool = true,
        @ViewBuilder content: () -> Content,
        buttons: [DialogButton]
    ) {
        if let upstream {
            upstream.presentActionSheet(
                title: title,
                message: message,
                dismissOnBackgroundTap: dismissOnBackgroundTap,
                content: content,
                buttons: buttons
            )
            return
        }
        presenter?.presentActionSheet(
            title: title,
            message: message,
            dismissOnBackgroundTap: dismissOnBackgroundTap,
            content: content,
            buttons: buttons
        )
    }

    /// 展示自定义样式弹层（Alert 居中或 Sheet 底部上滑）。
    ///
    /// - Parameters:
    ///   - style: `.alert` 居中缩放；`.sheet` 底部滑入
    ///   - dismissOnBackgroundTap: 点击遮罩是否关闭
    ///   - content: 完全自定义的弹层内容
    func presentCustomView<Content: View>(
        style: ViewPresenterCustomStyle,
        dismissOnBackgroundTap: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        if let upstream {
            upstream.presentCustomView(
                style: style,
                dismissOnBackgroundTap: dismissOnBackgroundTap,
                content: content
            )
            return
        }
        presenter?.presentCustomView(
            style: style,
            dismissOnBackgroundTap: dismissOnBackgroundTap,
            content: content
        )
    }

    /// 整页全屏展示（`fullScreenCover`），**不**创建内层 NavigationStack。
    ///
    /// 适用于：
    /// - 模块根视图已自带导航结构（如模版 App 的 `TemplateRootView`）
    /// - 单页内容，无需在 Cover 内继续 `push`
    ///
    /// - Parameter content: Cover 根视图；页面内统一 `@State private var navigator = Navigator()` + `.navigator(navigator)`
    ///
    /// - Important: Cover 内调用 `push` 会写到**宿主** NavigationStack，新页可能被挡在 Cover 下方。
    ///   若需在 Cover 内继续路由跳转，请用 `presentNavigationPage`。
    func presentPage<Content: View>(@ViewBuilder _ content: @escaping () -> Content) {
        if let upstream {
            upstream.presentPage(content)
            return
        }
        presenter?.presentPage(content)
    }

    /// 整页全屏展示，并包裹独立 NavigationStack + 独立 `AppRouter` + 全量路由注册。
    ///
    /// 内部等价于：
    /// ```text
    /// presentPage {
    ///     PresentedNavigationHost { content }
    /// }
    /// ```
    ///
    /// Cover 打开后：
    /// - 新建 `@State AppRouter`，与宿主 router **完全隔离**
    /// - 注册 `AppRouteRegistry.all` 全部路由，可在 Cover 内 `push` / `pushPath`
    /// - 共享同一 `Navigator` 与 `ViewPresenter`（present / dismiss 仍走宿主页队列）
    ///
    /// - Parameter content: Cover 内 NavigationStack 的根视图
    ///
    /// - SeeAlso: `PresentedNavigationHost`、`back()`
    func presentNavigationPage<Content: View>(@ViewBuilder _ content: @escaping () -> Content) {
        if let upstream {
            upstream.presentNavigationPage(content)
            return
        }
        presenter?.presentNavigationPage(content)
    }

    // MARK: - Dismiss

    /// 关闭弹层队列栈顶一层（Alert / ActionSheet / 自定义 / 整页 Cover）。
    ///
    /// 带动画；动画结束后执行 `complete`（类似 UIKit `dismiss(animated:completion:)`）。
    ///
    /// - Parameter complete: 关闭完成回调，可选
    func dismiss(complete: (() -> Void)? = nil) {
        if let upstream {
            upstream.dismiss(complete: complete)
            return
        }
        presenter?.dismiss(complete: complete)
    }

    /// 关闭栈顶整页 Cover（`presentPage` / `presentNavigationPage`）。
    ///
    /// 与 `dismiss()` 不同：若栈顶不是整页 Cover，则直接执行 `complete` 而不操作栈。
    /// Cover 内已 push 多层时，可一次关掉整个 present 模块（无需逐层 `back()`）。
    ///
    /// - Parameter complete: 关闭完成回调
    func dismissCover(complete: (() -> Void)? = nil) {
        if let upstream {
            upstream.dismissCover(complete: complete)
            return
        }
        presenter?.dismissCover(complete: complete)
    }

    /// 立即清空全部弹层队列（Alert / ActionSheet / 自定义 / Cover，无逐层动画）。
    ///
    /// - Parameter complete: 清空后回调
    func dismissAllDialog(complete: (() -> Void)? = nil) {
        if let upstream {
            upstream.dismissAllDialog(complete: complete)
            return
        }
        presenter?.dismissAllDialog(complete: complete)
    }

    // MARK: - back（统一返回）

    /// 统一返回：按优先级自动选择 dismiss 或 pop，适合绑定导航栏返回按钮。
    ///
    /// 决策顺序：
    /// 1. 弹窗队列非空 → `dismiss()` 关掉栈顶弹窗
    /// 2. 有整页 Cover：
    ///    - `presentNavigationPage` 内层 router 仍有 push → `pop()` 内层
    ///    - 否则 → `dismissCover()` 关 Cover
    /// 3. NavigationStack 有 push → `pop()`
    /// 4. 以上皆无 → 仅执行 `complete`
    ///
    /// - Parameter complete: 返回动作完成后的回调（pop 为同步；dismiss 在动画结束后）
    ///
    /// - Important: 从宿主 push 进 Demo 页后再 `presentPage`（非 NavigationPage），
    ///   Cover 根调用 `back()` 会 `dismissCover`，**不会** pop 掉宿主 push 的 Demo 页。
    func back(complete: (() -> Void)? = nil) {
        if let upstream {
            upstream.back(complete: complete)
            return
        }
        guard let presenter, let router else {
            complete?()
            return
        }

        if presenter.stackDepth > 0 {
            presenter.dismiss(complete: complete)
            return
        }

        if presenter.isPresentingPage {
            if isPresentationRouterScoped, router.hasPushedPages {
                router.pop()
                complete?()
            } else {
                presenter.dismissCover(complete: complete)
            }
            return
        }

        if router.hasPushedPages {
            router.pop()
            complete?()
            return
        }

        complete?()
    }

    // MARK: - 内部绑定（fileprivate · 仅供本文件 Modifier 调用，业务勿用）

    /// 调用方：`.navigator` → `NavigatorHostBinding`
    /// 子页面 `.navigator` 绑定环境中已有宿主（共享 ViewPresenter / router）。
    fileprivate func bindUpstream(_ host: Navigator) {
        guard host !== self else { return }
        upstream = host
    }

    fileprivate func attach(router: AppRouter, presenter: ViewPresenter) {
        if let upstream {
            upstream.attach(router: router, presenter: presenter)
            return
        }
        if self.presenter !== presenter { self.presenter = presenter }
        if hostRouter !== router { hostRouter = router }
        syncActiveRouter()
    }

    /// 调用方：`navigatorPresentationHost` → `NavigatorPresentationHostModifier`
    fileprivate func bindPresentationRouter(_ router: AppRouter) {
        if let upstream {
            upstream.bindPresentationRouter(router)
            return
        }
        guard presentationRouter !== router else { return }
        presentationRouter = router
        isPresentationRouterScoped = true
        self.router = router
    }

    /// 调用方：`navigatorPresentationHost` → `NavigatorPresentationHostModifier`
    fileprivate func clearPresentationRouter() {
        if let upstream {
            upstream.clearPresentationRouter()
            return
        }
        guard presentationRouter != nil else { return }
        presentationRouter = nil
        isPresentationRouterScoped = false
        router = hostRouter
    }

    /// 调用方：`.navigatorRouterScope` → `NavigatorRouterScopeModifier`
    fileprivate func rebindRouter(_ router: AppRouter) {
        if let upstream {
            upstream.rebindRouter(router)
            return
        }
        bindPresentationRouter(router)
    }

    private func syncActiveRouter() {
        guard let presenter else {
            if router !== hostRouter { router = hostRouter }
            return
        }
        if isPageCoverActive(on: presenter), let presentationRouter {
            if router !== presentationRouter {
                router = presentationRouter
                isPresentationRouterScoped = true
            }
        } else if !isPageCoverActive(on: presenter) {
            if presentationRouter != nil { presentationRouter = nil }
            if isPresentationRouterScoped { isPresentationRouterScoped = false }
            if router !== hostRouter { router = hostRouter }
        }
    }

    private func isPageCoverActive(on presenter: ViewPresenter) -> Bool {
        presenter.isPresentingPage
    }
}

// MARK: - 业务公开 · Environment

private enum SharedNavigatorKey: EnvironmentKey {
    static let defaultValue: Navigator? = nil
}

extension EnvironmentValues {
    /// 上层注入的共享 `Navigator` 实例。
    ///
    /// - 由 `.navigator` 或 `PresentedNavigationHost` 写入
    /// - Cover 内 push 出的子页可读取，避免重复创建 `Navigator` / `ViewPresenter`
    /// - 主栈直接 push 进来的页面通常为 `nil`，需自建 `@State navigator`
    var sharedNavigator: Navigator? {
        get { self[SharedNavigatorKey.self] }
        set { self[SharedNavigatorKey.self] = newValue }
    }
}

// MARK: - 业务公开 · View

extension View {

    /// 为页面绑定 `Navigator`：挂载 `ViewPresenter`，并关联环境中的宿主 `AppRouter`。
    ///
    /// 典型写法：
    /// ```swift
    /// struct MyPage: View {
    ///     @State private var navigator = Navigator()
    ///     var body: some View {
    ///         content
    ///             .navigator(navigator)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter navigator: 页面级 `@State` 持有的 `Navigator` 实例
    /// - Returns: 附带弹层能力与环境注入的视图
    func navigator(_ navigator: Navigator) -> some View {
        modifier(NavigatorModifier(navigator: navigator))
    }

    /// 将 `navigator` 的 push/pop 对齐到当前环境中的 `AppRouter`（Cover 内层 router）。
    ///
    /// 使用场景：
    /// - `presentNavigationPage` 内 **被 push 出来** 的子页（路由注册构建的页面）
    /// - 需复用宿主页 `Navigator`，但 router 必须是 Cover 内层实例
    ///
    /// 在子页 `onAppear` 时绑定内层 router，**不会**新建 `ViewPresenter`。
    ///
    /// - Parameter navigator: 页面 `@State` 持有的 `Navigator`（`.navigator` 已自动绑定 upstream 时仍传同一实例）
    func navigatorRouterScope(_ navigator: Navigator) -> some View {
        modifier(NavigatorRouterScopeModifier(navigator: navigator))
    }
}

// MARK: - 框架内部 · PresentedNavigationHost（业务勿用）

/// `ViewPresenter.presentNavigationPage` 专用：内层 NavigationStack + 独立 AppRouter + 全量路由。
struct PresentedNavigationHost<Content: View>: View {
    @Environment(Navigator.self) private var navigator
    @State private var router = AppRouter()
    @ViewBuilder private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .navigationStackRouter(router: router, routes: AppRouteRegistry.all)
            .environment(router)
            .environment(navigator)
            .environment(\.sharedNavigator, navigator)
            .onAppear { navigator.bindPresentationRouter(router) }
            .onDisappear { navigator.clearPresentationRouter() }
    }
}

// MARK: - 框架内部 · Modifier（private，业务勿用）

private struct NavigatorModifier: ViewModifier {
    var navigator: Navigator
    @Environment(\.sharedNavigator) private var hostNavigator
    @Environment(AppRouter.self) private var router
    @State private var presenter = ViewPresenter()

    @ViewBuilder
    func body(content: Content) -> some View {
        if let host = hostNavigator, host !== navigator {
            content
                .environment(navigator)
                .background {
                    NavigatorUpstreamBinding(child: navigator, host: host)
                }
        } else {
            content
                .viewPresenter(presenter)
                .environment(navigator)
                .environment(\.sharedNavigator, navigator)
                .background {
                    NavigatorHostBinding(
                        navigator: navigator,
                        hostRouter: router,
                        presenter: presenter
                    )
                }
        }
    }
}

private struct NavigatorUpstreamBinding: View {
    let child: Navigator
    let host: Navigator

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear { child.bindUpstream(host) }
    }
}

/// 仅在 appear / 宿主 router 变化时 attach，避免在 `body` 里写 `@Observable` 造成死循环。
private struct NavigatorHostBinding: View {
    let navigator: Navigator
    let hostRouter: AppRouter
    let presenter: ViewPresenter

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                navigator.attach(router: hostRouter, presenter: presenter)
            }
            .onChange(of: ObjectIdentifier(hostRouter)) { _, _ in
                navigator.attach(router: hostRouter, presenter: presenter)
            }
    }
}

private struct NavigatorRouterScopeModifier: ViewModifier {
    let navigator: Navigator
    @Environment(AppRouter.self) private var router

    func body(content: Content) -> some View {
        content.onAppear {
            navigator.rebindRouter(router)
        }
    }
}
