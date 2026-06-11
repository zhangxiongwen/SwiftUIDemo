//
//  DemoRootView.swift
//  SwiftUIDemo
//

import SwiftUI

private enum DemoTab: Int, Hashable, CaseIterable {
    case system, custom, async, tools
}

struct DemoRootView: View {
    @State private var selectedTab: DemoTab = .system

    private var tabItems: [CustomTabBarItem<DemoTab>] {
        [
            .init(selection: .system, title: "系统控件", systemImage: "square.grid.2x2"),
            .init(selection: .custom, title: "自定义控件", systemImage: "paintbrush"),
            .init(selection: .async, title: "Combine", systemImage: "arrow.triangle.2.circlepath"),
            .init(selection: .tools, title: "工具", systemImage: "wrench.and.screwdriver")
        ]
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            SystemViewsPage()
                .tag(DemoTab.system)

            CustomViewsPage()
                .tag(DemoTab.custom)

            CombinePage()
                .tag(DemoTab.async)

            ToolsPage()
                .tag(DemoTab.tools)
        }
        .tabViewStyle(.page(indexDisplayMode: .never)) 
        .disablePageTabViewBounce()    //去掉弹簧效果
        .disablePageTabViewSwipe()     //禁用左右滑动
        // Demo 内统一使用自定义导航栏，隐藏系统导航栏
        .toolbar(.hidden, for: .navigationBar)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(items: tabItems, selection: $selectedTab, tint: AppColors.primary)
        }
        .background(AppColors.background)
    }
}
