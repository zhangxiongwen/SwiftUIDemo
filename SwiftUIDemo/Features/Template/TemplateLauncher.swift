//
//  TemplateLauncher.swift
//  SwiftUIDemo
//

import SwiftUI

enum TemplateLauncher {
    /// 从 Demo 以 `presentNavigationPage` 打开模版（内层 Nav + 全量路由，复用外层 navigator）。
    @MainActor
    static func open(from navigator: Navigator) {
        if AppConfig.useMock, !UserManager.shared.isLoggedIn {
            UserManager.shared.login(token: "mock-demo-token")
        }
        navigator.presentNavigationPage {
            TemplateRootView()
        }
    }

    /// 关闭模版整页 Cover
    @MainActor
    static func close(from navigator: Navigator) {
        navigator.dismissCover()
    }
}
