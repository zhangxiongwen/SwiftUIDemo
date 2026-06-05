//
//  CustomViewsPage.swift
//  SwiftUIDemo
//

import SwiftUI

struct CustomViewsPage: View {
    @State private var navigator = Navigator()

    var body: some View {
        List {
            Section("目录") {
                catalogRow(
                    title: "BaseNavigationBar",
                    subtitle: "自绘导航栏 · 隐藏 / 透明度 / 自定义槽位",
                    icon: "rectangle.topthird.inset.filled"
                ) {
                    navigator.pushPath(CustomViewsRoute.navBarCatalog.rawValue)
                }

                catalogRow(
                    title: "整页 Present",
                    subtitle: "presentPage · presentNavigationPage",
                    icon: "rectangle.inset.filled"
                ) {
                    navigator.pushPath(CustomViewsRoute.pagePresentDemo.rawValue)
                }

                catalogRow(
                    title: "Dialog",
                    subtitle: "Alert · ActionSheet · Sheet · 自定义",
                    icon: "bubble.left.and.bubble.right"
                ) {
                    navigator.pushPath(CustomViewsRoute.dialogDemo.rawValue)
                }

                catalogRow(
                    title: "Toast",
                    subtitle: "自定义 ToastView + ToastManager",
                    icon: "text.bubble"
                ) {
                    navigator.pushPath(CustomViewsRoute.toastDemo.rawValue)
                }

                catalogRow(
                    title: "Loading",
                    subtitle: "全局 HUD Loading",
                    icon: "arrow.clockwise.circle"
                ) {
                    navigator.pushPath(CustomViewsRoute.loadingDemo.rawValue)
                }

                catalogRow(
                    title: "路由",
                    subtitle: "push · pushPath · query · extra",
                    icon: "link"
                ) {
                    navigator.pushPath(CustomViewsRoute.routeDemo.rawValue)
                }
            }

            Section("组件预览") {
                HStack(spacing: 16) {
                    ToastView(message: "操作成功")
                    PrimaryButton(title: "PrimaryButton", action: {})
                }
                .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 8) {
                    Text("PrimaryButton · ToastView 等")
                        .appFont(AppFonts.h2)
                    Text("设计系统组件，与 AppBaseComponents 分离。")
                        .appFont(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .baseNavigationBar(title: "自定义控件")
        .navigator(navigator)
    }

    private func catalogRow(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.6))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
