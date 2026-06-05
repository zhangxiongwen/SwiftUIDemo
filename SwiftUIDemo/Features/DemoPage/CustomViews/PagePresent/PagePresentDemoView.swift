//
//  PagePresentDemoView.swift
//  SwiftUIDemo
//

import SwiftUI

struct PagePresentDemoView: View {
    @State private var navigator = Navigator()

    var body: some View {
        List {
            Section("说明") {
                Text("整页 Present 与 Dialog 弹窗分离演示。本页 @State navigator + .navigator(navigator)。")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Section("presentPage") {
                demoRow(
                    "打开 presentPage",
                    subtitle: "无内层 Nav · 自定义导航栏 · 适合模版根视图"
                ) {
                    navigator.presentPage {
                        PresentPageDemoRootView()
                    }
                }
            }

            Section("presentNavigationPage") {
                demoRow(
                    "打开 presentNavigationPage",
                    subtitle: "内层 Nav + 全量路由 · Cover 内可 push"
                ) {
                    navigator.presentNavigationPage {
                        PresentNavigationPageDemoRootView()
                    }
                }

                demoRow(
                    "多层 push · 深层 dismissCover",
                    subtitle: "Cover 内连 push 3 层 · 最深层一键关掉整页"
                ) {
                    navigator.presentNavigationPage {
                        PresentNavDeepDismissRootView()
                    }
                }
            }
        }
        .baseNavigationBar(title: "整页 Present")
        .navigator(navigator)
    }

    private func demoRow(
        _ title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}
