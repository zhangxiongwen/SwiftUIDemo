//
//  TemplateMainTabView.swift
//  SwiftUIDemo
//

import SwiftUI

private enum TemplateTab: Int, Hashable {
    case home = 0
    case settings = 1
}

struct TemplateMainTabView: View {
    @State private var navigator = Navigator()
    @State private var selectedTab: TemplateTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label(AppStrings.Home.tabTitle, systemImage: "house")
                }
                .tag(TemplateTab.home)

            SettingsView()
                .tabItem {
                    Label(AppStrings.Settings.tabTitle, systemImage: "person")
                }
                .tag(TemplateTab.settings)
        }
        .tint(AppColors.primary)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if showsModuleBackButton {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        navigator.back()
                    } label: {
                        Label("返回", systemImage: "chevron.left")
                    }
                }
            }
        }
        .toolbar(navigator.hasPushedPages ? .hidden : .automatic, for: .tabBar)
        .navigator(navigator)
    }

    private var navigationTitle: String {
        switch selectedTab {
        case .home:
            return AppStrings.Home.navTitle
        case .settings:
            return AppStrings.Settings.navTitle
        }
    }

    /// Cover Tab 根层显示返回；模版内 push 子页后由 `navigator.back()` 先 pop 内层。
    private var showsModuleBackButton: Bool {
        !navigator.hasPushedPages
    }
}
