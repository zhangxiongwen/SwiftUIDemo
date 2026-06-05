//
//  SettingsView.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var navigator = Navigator()
    
    var body: some View {
        settingsContent
            .navigator(navigator)
//            .baseNavigationBar(hidden: true)
    }

    private var settingsContent: some View {
        List {
            // Section 1: 个人信息卡片
            Section {
                HStack(spacing: 16) {
                    Image(systemName: viewModel.userAvatar)
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundStyle(AppColors.primary)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.userName)
                            .appFont(AppFonts.h2)
                        Text("138****8888")
                            .appFont(AppFonts.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.gray)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    push(.profile)
                }
            }
            
            // Section 2: 通用设置
            Section {
                // 清理缓存
                SettingsRow(
                    icon: "trash",
                    iconColor: .orange,
                    title: AppStrings.Settings.clearCache,
                    value: viewModel.cacheSize
                ) {
                    viewModel.clearCache()
                }
                
                // 隐私政策
                SettingsRow(icon: "lock.shield", iconColor: .blue, title: AppStrings.Settings.privacy) {
                    push(.webView, query: [
                        "url": "https://www.apple.com/privacy",
                        "title": AppStrings.Settings.privacy
                    ])
                }
                
                // 用户协议
                SettingsRow(icon: "doc.text", iconColor: .blue, title: AppStrings.Settings.terms) {
                    push(.webView, query: [
                        "url": "https://www.apple.com/legal",
                        "title": AppStrings.Settings.terms
                    ])
                }
            }
            
            // Section 3: 关于
            Section {
                SettingsRow(
                    icon: "info.circle",
                    iconColor: .gray,
                    title: AppStrings.Settings.about,
                    value: viewModel.appVersion
                ) {
                    push(.about)
                }
            }
            
            // Section 4: 退出登录
            Section {
                Button {
                    viewModel.logout()
                } label: {
                    Text(AppStrings.Settings.logout)
                        .appFont(AppFonts.body)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        // ✨【修复重点】这里加了 else { EmptyView() } 消除类型推断歧义
        .overlay {
            if viewModel.state == .loading {
                LoadingView()
            } else {
                EmptyView()
            }
        }
    }

    private func push(
        _ route: TemplateRoute,
        query: [String: String] = [:],
        extra: (any Hashable)? = nil
    ) {
        navigator.push(route, query: query, extra: extra)
    }
}

// MARK: - 辅助组件 SettingsRow
// 确保这个 struct 在 SettingsView 之外，或者是独立的文件
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var value: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(iconColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Text(title)
                    .appFont(AppFonts.body)
                    .foregroundStyle(AppColors.textPrimary)
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .appFont(AppFonts.caption)
                        .foregroundStyle(.secondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.gray.opacity(0.5))
            }
        }
    }
}
