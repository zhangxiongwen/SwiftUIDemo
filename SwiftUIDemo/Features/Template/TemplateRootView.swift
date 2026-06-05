//
//  TemplateRootView.swift
//  SwiftUIDemo
//
//  模版 Cover 根视图：由 Demo `presentNavigationPage` 打开。
//  NavigationStack / AppRouter 由 PresentedNavigationHost 提供，本文件不再自建。
//

import SwiftUI

struct TemplateRootView: View {
    @State private var userManager = UserManager.shared

    var body: some View {
        templateRootContent
            .onAppear(perform: prepareTemplateEntry)
    }

    @ViewBuilder
    private var templateRootContent: some View {
        if userManager.isLoggedIn {
            TemplateMainTabView()
        } else {
            LoginView()
        }
    }

    private func prepareTemplateEntry() {
        if AppConfig.useMock, !userManager.isLoggedIn {
            userManager.login(token: "mock-demo-token")
        }
    }
}
