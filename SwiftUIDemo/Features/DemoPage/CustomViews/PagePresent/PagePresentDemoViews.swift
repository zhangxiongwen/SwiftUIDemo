//
//  PagePresentDemoViews.swift
//  SwiftUIDemo
//
//  presentPage / presentNavigationPage Demo 页面。
//

import SwiftUI

// MARK: - presentPage（无内层 NavigationStack）

struct PresentPageDemoRootView: View {
    @State private var navigator = Navigator()

    var body: some View {
        List {
            Section {
                pageLayerBadge("整页", detail: "presentPage · 无内层 Nav")
                Text("使用自定义 baseNavigationBar；返回即 navigator.back()。此层不能 navigator.push。")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Section("说明") {
                Label("适合模版 App 等根视图已自带 NavigationStack 的场景。", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Section("Toast / Loading") {
                Button("showToast") { showToast("presentPage 内 Toast") }
                Button("showLoading 1.5s") {
                    showLoading()
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        hideLoading()
                    }
                }
            }
        }
        .baseNavigationBar(
            title: "presentPage",
            allowsSwipeBack: false,
            onBack: { navigator.back() }
        )
        .navigator(navigator)
    }
}

// MARK: - presentNavigationPage（内层 Nav + 全量路由）

struct PresentNavigationPageDemoRootView: View {
    @State private var navigator = Navigator()

    var body: some View {
        List {
            Section {
                pageLayerBadge("Cover 根", detail: "presentNavigationPage")
                Text("独立 AppRouter + AppRouteRegistry.all；下列 push 在 Cover 内可见。")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Text("Cover 根返回请用 navigator.back()：无内层 push 时 dismissCover 关 Cover；有 push 时先 pop 内层。")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Section("自定义返回（body 内）") {
                Button {
                    navigator.back()
                } label: {
                    Label("navigator.back()", systemImage: "arrow.uturn.backward")
                }
                Text("与左上角导航栏返回相同，均走 Navigator 统一 back 逻辑。")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Section("路由嵌套 · push") {
                navigationDemoRow(
                    title: "→ Push 目标页",
                    code: "navigator.push(CustomViewsRoute.presentThenPushTarget, query: …)"
                ) {
                    navigator.push(CustomViewsRoute.presentThenPushTarget, query: ["from": "navRoot"])
                }

                navigationDemoRow(
                    title: "→ Dialog 队列 Demo",
                    code: "navigator.push(CustomViewsRoute.dialogNestDemo)"
                ) {
                    navigator.push(CustomViewsRoute.dialogNestDemo)
                }

                navigationDemoRow(
                    title: "→ Toast Demo",
                    code: "navigator.push(CustomViewsRoute.toastDemo)"
                ) {
                    navigator.push(CustomViewsRoute.toastDemo)
                }

                navigationDemoRow(
                    title: "→ 路由参数页",
                    code: "navigator.push(.routeParamsDemo, query: …)"
                ) {
                    navigator.push(
                        CustomViewsRoute.routeParamsDemo,
                        query: ["title": "来自 NavigationPage", "count": "2"]
                    )
                }
            }

            Section("路由嵌套 · pushPath") {
                navigationDemoRow(
                    title: "→ pushPath 目标页",
                    code: "navigator.pushPath(\"/presentThenPushTarget?from=path\")"
                ) {
                    navigator.pushPath("/presentThenPushTarget", query: ["from": "path"])
                }

                navigationDemoRow(
                    title: "→ pushPath 参数页",
                    code: "navigator.pushPath(\"/routeParamsDemo?title=…&count=…\")"
                ) {
                    navigator.pushPath("/routeParamsDemo?title=pushPath嵌套&count=9")
                }
            }

            Section("Toast / Loading") {
                Button("showToast") { showToast("NavigationPage 内 Toast") }
                Button("showLoading 1.5s") {
                    showLoading()
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        hideLoading()
                    }
                }
            }
        }
        .baseNavigationBar(
            allowsSwipeBack: false,
            leading: {
                BaseNavigationBarBackButton(action: { navigator.back() })
            },
            title: {
                Text("presentNavigationPage")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
            },
            trailing: {
                EmptyView()
            }
        )
        .navigator(navigator)
    }
}

// MARK: - presentNavigationPage · 多层 push · 深层 dismissCover

/// Cover 根：进入内层后逐层 push，最深层可 `dismissCover()` 关掉整页。
struct PresentNavDeepDismissRootView: View {
    @State private var navigator = Navigator()

    var body: some View {
        List {
            Section {
                pageLayerBadge("Cover 根", detail: "presentNavigationPage")
                Text("进入内层后连续 push；到第 3 层时点 dismissCover，一次性关闭本 Cover，无需逐层 back。")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Section("进入内层 push") {
                navigationDemoRow(
                    title: "→ 第 1 层",
                    code: "navigator.push(.presentNavDeepDismissLayer, query: [\"depth\": \"1\"])"
                ) {
                    navigator.push(
                        CustomViewsRoute.presentNavDeepDismissLayer,
                        query: ["depth": "1"]
                    )
                }
            }

            Section("对比") {
                Button("navigator.back() 关 Cover") {
                    navigator.back()
                }
                Text("Cover 根无内层 push 时，back() 等价 dismissCover。")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .baseNavigationBar(
            allowsSwipeBack: false,
            leading: {
                BaseNavigationBarBackButton(action: { navigator.back() })
            },
            title: {
                Text("Deep Dismiss Demo")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
            },
            trailing: {
                EmptyView()
            }
        )
        .navigator(navigator)
    }
}

/// Cover 内 push 出的层级页；`depth == 3` 时展示「直接 dismissCover」。
struct PresentNavDeepDismissLayerView: View {
    @State private var navigator = Navigator()
    let depth: Int

    private var isDeepest: Bool { depth >= 3 }

    var body: some View {
        List {
            Section {
                pageLayerBadge("第 \(depth) 层", detail: "presentNavigationPage 内 push")
                Text("navigator.hasPushedPages = \(navigator.hasPushedPages.description)")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if !isDeepest {
                Section("继续 push") {
                    navigationDemoRow(
                        title: "→ 第 \(depth + 1) 层",
                        code: "navigator.push(.presentNavDeepDismissLayer, query: [\"depth\": \"\(depth + 1)\"])"
                    ) {
                        navigator.push(
                            CustomViewsRoute.presentNavDeepDismissLayer,
                            query: ["depth": "\(depth + 1)"]
                        )
                    }
                }
            }

            Section(isDeepest ? "直接关闭整页 Cover" : "逐层返回") {
                if isDeepest {
                    Button {
                        navigator.dismissCover()
                    } label: {
                        Label("navigator.dismissCover()", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                    Text("不逐层 pop，直接关掉 presentNavigationPage 弹出的整页。")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Button("navigator.back() 返回上一层") {
                    navigator.back()
                }
            }
        }
        .baseNavigationBar(title: "第 \(depth) 层")
        .navigator(navigator)
        .navigatorRouterScope(navigator)
    }
}

// MARK: - Push 目标（可继续嵌套）

struct PresentThenPushTargetView: View {
    @State private var navigator = Navigator()
    let from: String

    var body: some View {
        List {
            Section("当前页") {
                pageLayerBadge("栈顶", detail: "PresentThenPushTarget")
                Text("来源 from = \(from)")
                    .appFont(AppFonts.body)
                Text(targetHint)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Section("继续嵌套 push") {
                navigationDemoRow(
                    title: "→ 路由参数页（第 3 层）",
                    code: "navigator.push(.routeParamsDemo, …)"
                ) {
                    navigator.push(
                        CustomViewsRoute.routeParamsDemo,
                        query: ["title": "第3层", "count": "3"]
                    )
                }

                navigationDemoRow(
                    title: "→ Toast Demo（第 3 层）",
                    code: "navigator.push(CustomViewsRoute.toastDemo)"
                ) {
                    navigator.push(CustomViewsRoute.toastDemo)
                }
            }

            Section {
                Button("navigator.back() 返回上一层") {
                    navigator.back()
                }
            }
        }
        .baseNavigationBar(title: "Push 目标页")
        .navigator(navigator)
        .navigatorRouterScope(navigator)
    }

    private var targetHint: String {
        switch from {
        case "none":
            return "对照：无弹层时 push，正常可见。"
        case "navRoot", "path", "withNav":
            return "presentNavigationPage 内 push；可再点上面按钮进第 3 层。"
        default:
            return "外层 presentPage 上 push 时可能被弹层挡住；pop 后弹窗可能仍在。"
        }
    }
}

// MARK: - Shared UI

private func pageLayerBadge(_ layer: String, detail: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(layer)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(AppColors.primary)
            .clipShape(Capsule())
        Text(detail)
            .appFont(AppFonts.caption)
            .foregroundStyle(AppColors.textSecondary)
    }
}

private func navigationDemoRow(
    title: String,
    code: String,
    action: @escaping () -> Void
) -> some View {
    Button(action: action) {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .foregroundStyle(AppColors.textPrimary)
            Text(code)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}
