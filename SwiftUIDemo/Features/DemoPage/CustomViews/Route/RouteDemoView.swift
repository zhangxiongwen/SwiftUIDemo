//
//  RouteDemoView.swift
//  SwiftUIDemo
//

import SwiftUI

struct RouteDemoView: View {
    @State private var navigator = Navigator()

    var body: some View {
        List {
            Section("push(枚举, query, extra)") {
                demoRow(
                    title: "无参数 push",
                    code: "navigator.push(CustomViewsRoute.toastDemo)",
                    action: { navigator.push(CustomViewsRoute.toastDemo) }
                )

                demoRow(
                    title: "query 字典",
                    code: """
                    navigator.push(
                        CustomViewsRoute.routeParamsDemo,
                        query: ["title": "来自 push", "count": "7"]
                    )
                    """,
                    action: {
                        navigator.push(
                            CustomViewsRoute.routeParamsDemo,
                            query: ["title": "来自 push", "count": "7"]
                        )
                    }
                )

                demoRow(
                    title: "extra 对象",
                    code: """
                    navigator.push(
                        CustomViewsRoute.routeParamsDemo,
                        query: ["title": "extra 示例", "count": "1"],
                        extra: RouteParamsDemoExtra(source: "push(extra:)")
                    )
                    """,
                    action: {
                        navigator.push(
                            CustomViewsRoute.routeParamsDemo,
                            query: ["title": "extra 示例", "count": "1"],
                            extra: RouteParamsDemoExtra(source: "push(extra:)")
                        )
                    }
                )

                demoRow(
                    title: "extra 字典",
                    code: """
                    navigator.push(
                        CustomViewsRoute.routeParamsDemo,
                        query: ["title": "字典 extra", "count": "2"],
                        extra: ["role": "admin", "channel": "demo"]
                    )
                    """,
                    action: {
                        navigator.push(
                            CustomViewsRoute.routeParamsDemo,
                            query: ["title": "字典 extra", "count": "2"],
                            extra: ["role": "admin", "channel": "demo"] as [String: String]
                        )
                    }
                )

                demoRow(
                    title: "extra 数组",
                    code: """
                    navigator.push(
                        CustomViewsRoute.routeParamsDemo,
                        query: ["title": "数组 extra", "count": "3"],
                        extra: ["Swift", "UIKit", "SwiftUI"]
                    )
                    """,
                    action: {
                        navigator.push(
                            CustomViewsRoute.routeParamsDemo,
                            query: ["title": "数组 extra", "count": "3"],
                            extra: ["Swift", "UIKit", "SwiftUI"]
                        )
                    }
                )
            }

            Section("pushPath(字符串, query, extra)") {
                demoRow(
                    title: "rawValue 路径",
                    code: "navigator.pushPath(\"/toastDemo\")",
                    action: { navigator.pushPath("/toastDemo") }
                )

                demoRow(
                    title: "路径内 query",
                    code: """
                    navigator.pushPath(
                        "/routeParamsDemo?title=SwiftUI路由&count=42"
                    )
                    """,
                    action: {
                        navigator.pushPath("/routeParamsDemo?title=SwiftUI路由&count=42")
                    }
                )

                demoRow(
                    title: "额外 query 合并",
                    code: """
                    navigator.pushPath(
                        "/routeParamsDemo",
                        query: ["title": "合并 query", "count": "99"]
                    )
                    """,
                    action: {
                        navigator.pushPath(
                            "/routeParamsDemo",
                            query: ["title": "合并 query", "count": "99"]
                        )
                    }
                )

                demoRow(
                    title: "仅 title，count 默认 0",
                    code: """
                    navigator.pushPath(
                        "/routeParamsDemo?title=only-title"
                    )
                    """,
                    action: {
                        navigator.pushPath("/routeParamsDemo?title=only-title")
                    }
                )
            }

            Section("pop / pop(steps:) / popToRoot") {
                Text("当前 pushDepth：\(navigator.pushDepth)")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)

                demoRow(
                    title: "打开 Pop 栈 Demo（第 1 层）",
                    code: "navigator.push(.routePopStepsDemo, query: [\"layer\": \"1\"])",
                    action: {
                        navigator.push(
                            CustomViewsRoute.routePopStepsDemo,
                            query: ["layer": "1"]
                        )
                    }
                )

                demoRow(
                    title: "一键连 push 3 层",
                    code: "连续 push layer 1 → 2 → 3",
                    action: {
                        navigator.push(CustomViewsRoute.routePopStepsDemo, query: ["layer": "1"])
                        navigator.push(CustomViewsRoute.routePopStepsDemo, query: ["layer": "2"])
                        navigator.push(CustomViewsRoute.routePopStepsDemo, query: ["layer": "3"])
                    }
                )
            }

            Section("404") {
                demoRow(
                    title: "未注册路径",
                    code: "navigator.pushPath(\"/not-a-real-page\")",
                    action: { navigator.pushPath("/not-a-real-page") }
                )
            }

            Section("说明") {
                Text("query 传字符串键值；extra 可传 Hashable 对象、字典、数组等，目标页自行 as? 解析。")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .baseNavigationBar(title: "路由 Demo")
        .navigator(navigator)
    }

    private func demoRow(title: String, code: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .foregroundStyle(AppColors.textPrimary)

                Text(code)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
