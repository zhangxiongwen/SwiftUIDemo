//
//  ToolsPage.swift
//  SwiftUIDemo
//

import SwiftUI

struct ToolsPage: View {
    @State private var navigator = Navigator()

    var body: some View {
        List {
            Section("模版模块") {
                Button {
                    TemplateLauncher.open(from: navigator)
                } label: {
                    Label("打开模版应用", systemImage: "doc.text")
                        .foregroundStyle(AppColors.textPrimary)
                }
                .buttonStyle(.plain)
            }

            Section("说明") {
                Label("模版用 presentNavigationPage 打开（内层 Nav + 全量路由）。", systemImage: "info.circle")
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .baseNavigationBar(title: "工具")
        .navigator(navigator)
    }
}
