//
//  BaseNavigationBar.swift
//  SwiftUIDemo
//
//  布局：ZStack 左 / 中 / 右；内容区高度取自系统 UINavigationBar（不含状态栏）
//

import SwiftUI
import UIKit

enum BaseNavigationBarMetrics {
    /// 与系统 `UINavigationBar` 内容区一致（不含状态栏 / 顶部 Safe Area）
    static var contentHeight: CGFloat {
        let bar = UINavigationBar()
        return bar.intrinsicContentSize.height
    }
}

/// 自绘导航栏内容区（左 / 中 / 右三列）；高度对齐系统 `UINavigationBar` 内容区。
/// 一般通过 `.baseNavigationBar(...)` 使用，而非直接嵌入页面。
struct BaseNavigationBar<Leading: View, Title: View, Trailing: View>: View {
    /// 导航栏背景色。
    var backgroundColor: Color = Color(uiColor: .systemBackground)
    /// 是否显示底部分割线。
    var showsDivider: Bool = true
    @ViewBuilder var leading: () -> Leading
    @ViewBuilder var title: () -> Title
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        ZStack {
            HStack {
                leading()
                Spacer(minLength: 0)
            }

            title()

            HStack {
                Spacer(minLength: 0)
                trailing()
            }
        }
        .frame(maxWidth: .infinity, minHeight: BaseNavigationBarMetrics.contentHeight)
        .padding(.horizontal)
        .background(backgroundColor)
        .overlay(alignment: .bottom) {
            if showsDivider {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)
            }
        }
    }
}

/// 默认返回按钮，可在自定义 `leading` 时复用
struct BaseNavigationBarBackButton: View {
    var titleColor: Color = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(titleColor)
        }
        .buttonStyle(.plain)
        .frame(minHeight: BaseNavigationBarMetrics.contentHeight)
        .contentShape(Rectangle())
    }
}
