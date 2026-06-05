//
//  NavigationBarComponents.swift
//  SwiftUIDemo
//
//  导航栏 Modifier、baseNavigationBar 扩展与侧滑返回
//

import SwiftUI
import UIKit



struct BaseNavigationBarModifier<Leading: View, Title: View, Trailing: View>: ViewModifier {
    var hidden: Bool
    var backgroundColor: Color
    var showsDivider: Bool
    /// `false`（默认）：VStack，内容从导航栏下方开始
    /// `true`：ZStack 叠加，导航栏盖在内容上方
    var barOverlaysContent: Bool
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var title: () -> Title
    @ViewBuilder var trailing: () -> Trailing

    private var navigationBar: some View {
        BaseNavigationBar(
            backgroundColor: backgroundColor,
            showsDivider: showsDivider,
            leading: leading,
            title: title,
            trailing: trailing
        )
    }

    func body(content: Content) -> some View {
        Group {
            if hidden {
                content
            } else if barOverlaysContent {
                ZStack(alignment: .top) {
                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    navigationBar
                        .contentShape(Rectangle())
                        .zIndex(1)
                }
            } else {
                VStack(spacing: 0) {
                    navigationBar

                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarHidden(true)
    }
}

// MARK: - 完全自定义左 / 标题 / 右

extension View {
    /// 完全自定义左、标题、右三栏的导航栏；隐藏系统导航栏。
    /// - Parameter barOverlaysContent: `true` 时导航栏浮在内容上方，否则内容在栏下方排布。
    /// - Parameter allowsSwipeBack: 是否允许系统侧滑返回（与 leading 独立配置）。
    func baseNavigationBar<Leading: View, Title: View, Trailing: View>(
        hidden: Bool = false,
        barOverlaysContent: Bool = false,
        backgroundColor: Color = Color(uiColor: .systemBackground),
        showsDivider: Bool = true,
        allowsSwipeBack: Bool = true,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder title: @escaping () -> Title,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) -> some View {
        modifier(BaseNavigationBarModifier(
            hidden: hidden,
            backgroundColor: backgroundColor,
            showsDivider: showsDivider,
            barOverlaysContent: barOverlaysContent,
            leading: leading,
            title: title,
            trailing: trailing
        ))
        .allowsNavigationInteractivePop(allowsSwipeBack)
    }
}

// MARK: - 自定义标题 View + 默认返回

extension View {
    /// 自定义标题 View + 可选右侧区；左侧默认根据导航深度显示返回按钮。
    /// - Parameter showsBackButton: 显式控制返回按钮；`nil` 时子页自动显示。
    /// - Parameter onBack: 自定义返回动作；默认 `router.pop()`。
    func baseNavigationBar<Title: View, Trailing: View>(
        hidden: Bool = false,
        barOverlaysContent: Bool = false,
        backgroundColor: Color = Color(uiColor: .systemBackground),
        showsDivider: Bool = true,
        titleColor: Color = Color.primary,
        showsBackButton: Bool? = nil,
        allowsSwipeBack: Bool? = nil,
        onBack: (() -> Void)? = nil,
        @ViewBuilder title: @escaping () -> Title,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) -> some View {
        modifier(BaseNavigationBarAutoLeadingModifier(
            hidden: hidden,
            barOverlaysContent: barOverlaysContent,
            backgroundColor: backgroundColor,
            showsDivider: showsDivider,
            titleColor: titleColor,
            showsBackButton: showsBackButton,
            allowsSwipeBack: allowsSwipeBack,
            onBack: onBack,
            title: title,
            trailing: trailing
        ))
    }

    /// 同 `baseNavigationBar(title:trailing:)`，无右侧自定义区。
    func baseNavigationBar<Title: View>(
        hidden: Bool = false,
        barOverlaysContent: Bool = false,
        backgroundColor: Color = Color(uiColor: .systemBackground),
        showsDivider: Bool = true,
        titleColor: Color = Color.primary,
        showsBackButton: Bool? = nil,
        allowsSwipeBack: Bool? = nil,
        onBack: (() -> Void)? = nil,
        @ViewBuilder title: @escaping () -> Title
    ) -> some View {
        baseNavigationBar(
            hidden: hidden,
            barOverlaysContent: barOverlaysContent,
            backgroundColor: backgroundColor,
            showsDivider: showsDivider,
            titleColor: titleColor,
            showsBackButton: showsBackButton,
            allowsSwipeBack: allowsSwipeBack,
            onBack: onBack,
            title: title,
            trailing: { EmptyView() }
        )
    }
}

// MARK: - 字符串标题 + 默认返回

extension View {
    /// 字符串标题 + 默认返回按钮（最常用）；参数可绑定 `@State` 实现动态隐藏、透明度等。
    func baseNavigationBar(
        title: String = "",
        hidden: Bool = false,
        barOverlaysContent: Bool = false,
        backgroundColor: Color = Color(uiColor: .systemBackground),
        showsDivider: Bool = true,
        titleColor: Color = Color.primary,
        showsBackButton: Bool? = nil,
        allowsSwipeBack: Bool? = nil,
        onBack: (() -> Void)? = nil
    ) -> some View {
        modifier(BaseNavigationBarStringTitleModifier(
            title: title,
            hidden: hidden,
            barOverlaysContent: barOverlaysContent,
            backgroundColor: backgroundColor,
            showsDivider: showsDivider,
            titleColor: titleColor,
            showsBackButton: showsBackButton,
            allowsSwipeBack: allowsSwipeBack,
            onBack: onBack,
            trailing: { EmptyView() }
        ))
    }

    /// 字符串标题 + 自定义右侧区（如按钮、菜单）。
    func baseNavigationBar<Trailing: View>(
        title: String = "",
        hidden: Bool = false,
        barOverlaysContent: Bool = false,
        backgroundColor: Color = Color(uiColor: .systemBackground),
        showsDivider: Bool = true,
        titleColor: Color = Color.primary,
        showsBackButton: Bool? = nil,
        allowsSwipeBack: Bool? = nil,
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) -> some View {
        modifier(BaseNavigationBarStringTitleModifier(
            title: title,
            hidden: hidden,
            barOverlaysContent: barOverlaysContent,
            backgroundColor: backgroundColor,
            showsDivider: showsDivider,
            titleColor: titleColor,
            showsBackButton: showsBackButton,
            allowsSwipeBack: allowsSwipeBack,
            onBack: onBack,
            trailing: trailing
        ))
    }
}

// MARK: - 返回按钮 / 侧滑

private enum BaseNavigationBarBackSupport {
    static func showsBackButton(
        explicit: Bool?,
        onBack: (() -> Void)?,
        isNavigationDestination: Bool
    ) -> Bool {
        explicit ?? (onBack != nil || isNavigationDestination)
    }

    static func effectiveAllowsSwipeBack(explicit: Bool?, onBack: (() -> Void)?) -> Bool {
        explicit ?? (onBack == nil)
    }
}

private struct BaseNavigationBarAutoLeadingModifier<Title: View, Trailing: View>: ViewModifier {
    var hidden: Bool
    var barOverlaysContent: Bool
    var backgroundColor: Color
    var showsDivider: Bool
    var titleColor: Color
    var showsBackButton: Bool?
    var allowsSwipeBack: Bool?
    var onBack: (() -> Void)?
    @ViewBuilder var title: () -> Title
    @ViewBuilder var trailing: () -> Trailing

    @Environment(AppRouter.self) private var router
    @Environment(\.isNavigationDestination) private var isNavigationDestination

    private var showBackButton: Bool {
        BaseNavigationBarBackSupport.showsBackButton(
            explicit: showsBackButton,
            onBack: onBack,
            isNavigationDestination: isNavigationDestination
        )
    }

    private var effectiveAllowsSwipeBack: Bool {
        BaseNavigationBarBackSupport.effectiveAllowsSwipeBack(
            explicit: allowsSwipeBack,
            onBack: onBack
        )
    }

    private var backAction: () -> Void {
        onBack ?? { router.pop() }
    }

    func body(content: Content) -> some View {
        content.modifier(
            BaseNavigationBarModifier(
                hidden: hidden,
                backgroundColor: backgroundColor,
                showsDivider: showsDivider,
                barOverlaysContent: barOverlaysContent,
                leading: { leadingView },
                title: title,
                trailing: trailing
            )
        )
        .allowsNavigationInteractivePop(effectiveAllowsSwipeBack)
    }

    @ViewBuilder
    private var leadingView: some View {
        if showBackButton {
            BaseNavigationBarBackButton(titleColor: titleColor, action: backAction)
        } else {
            EmptyView()
        }
    }
}

private struct BaseNavigationBarStringTitleModifier<Trailing: View>: ViewModifier {
    let title: String
    var hidden: Bool
    var barOverlaysContent: Bool
    var backgroundColor: Color
    var showsDivider: Bool
    var titleColor: Color
    var showsBackButton: Bool?
    var allowsSwipeBack: Bool?
    var onBack: (() -> Void)?
    @ViewBuilder var trailing: () -> Trailing

    @Environment(AppRouter.self) private var router
    @Environment(\.isNavigationDestination) private var isNavigationDestination

    private var showBackButton: Bool {
        BaseNavigationBarBackSupport.showsBackButton(
            explicit: showsBackButton,
            onBack: onBack,
            isNavigationDestination: isNavigationDestination
        )
    }

    private var effectiveAllowsSwipeBack: Bool {
        BaseNavigationBarBackSupport.effectiveAllowsSwipeBack(
            explicit: allowsSwipeBack,
            onBack: onBack
        )
    }

    private var backAction: () -> Void {
        onBack ?? { router.pop() }
    }

    func body(content: Content) -> some View {
        content.modifier(
            BaseNavigationBarModifier(
                hidden: hidden,
                backgroundColor: backgroundColor,
                showsDivider: showsDivider,
                barOverlaysContent: barOverlaysContent,
                leading: { leadingView },
                title: {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(titleColor)
                        .lineLimit(1)
                },
                trailing: trailing
            )
        )
        .allowsNavigationInteractivePop(effectiveAllowsSwipeBack)
    }

    @ViewBuilder
    private var leadingView: some View {
        if showBackButton {
            BaseNavigationBarBackButton(titleColor: titleColor, action: backAction)
        } else {
            EmptyView()
        }
    }
}

// MARK: - 侧滑返回

extension View {
    /// 设置当前页是否允许 Navigation 侧滑返回，并同步 UIKit 手势（默认 `true`）。
    /// 一般由 `baseNavigationBar` 内部调用，也可单独使用。
    func allowsNavigationInteractivePop(_ allowed: Bool = true) -> some View {
        modifier(AllowsNavigationInteractivePopModifier(allowed: allowed))
    }
}

// MARK: - Modifier

private struct AllowsNavigationInteractivePopModifier: ViewModifier {
    let allowed: Bool

    func body(content: Content) -> some View {
        content.background(
            NavigationInteractivePopConfigurator(allowsSwipeBack: allowed)
        )
    }
}

// MARK: - UIKit

private struct NavigationInteractivePopConfigurator: UIViewRepresentable {
    let allowsSwipeBack: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        let allowed = allowsSwipeBack
        DispatchQueue.main.async {
            guard let viewController = uiView.parentViewController(),
                  let navigationController = viewController.navigationController,
                  navigationController.topViewController === viewController
            else { return }

            if allowed {
                NavigationInteractivePopSupport.enable(on: navigationController)
            } else {
                NavigationInteractivePopSupport.disable(on: navigationController)
            }
        }
    }
}

private enum NavigationInteractivePopSupport {
    static func enable(on navigationController: UINavigationController) {
        guard let pop = navigationController.interactivePopGestureRecognizer else { return }
        if let coordinator = navigationController.transitionCoordinator, coordinator.isInteractive {
            return
        }
        pop.isEnabled = true
        pop.delegate = nil
    }

    static func disable(on navigationController: UINavigationController) {
        guard let pop = navigationController.interactivePopGestureRecognizer else { return }
        if let coordinator = navigationController.transitionCoordinator, coordinator.isInteractive {
            return
        }
        pop.isEnabled = false
    }
}

private extension UIView {
    func parentViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController
            }
            responder = current.next
        }
        return nil
    }
}
