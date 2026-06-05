//
//  BaseNavigationBarDemoCatalogView.swift
//  SwiftUIDemo
//

import SwiftUI

struct BaseNavigationBarDemoCatalogView: View {
    @State private var navigator = Navigator()

    var body: some View {
        List {
            demoRow("基础用法", subtitle: "title: \"…\"", route: .navBarBasic)
            demoRow("隐藏 / 显示自绘栏", subtitle: "hidden: hideCustomBar", route: .navBarHidden)
            demoRow("背景透明度", subtitle: "backgroundColor.opacity(...)", route: .navBarOpacity)
            demoRow("自定义左 / 标题 / 右", subtitle: "leading / title / trailing", route: .navBarCustom)
            demoRow("滚动渐变透明栏", subtitle: "barOverlaysContent: true", route: .navBarScrollOpacity)
            demoRow("侧滑返回开关 & 返回拦截", subtitle: "allowsSwipeBack / onBack", route: .navBarBackGesture)
        }
        .baseNavigationBar(title: "BaseNavigationBar")
        .navigator(navigator)
    }

    private func demoRow(_ title: String, subtitle: String, route: CustomViewsRoute) -> some View {
        Button {
            navigator.push(route)
        } label: {
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
