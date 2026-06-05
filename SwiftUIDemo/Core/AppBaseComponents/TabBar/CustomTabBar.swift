//
//  CustomTabBar.swift
//  SwiftUIDemo
//
//  仅绘制 Tab 内容区（49pt + 分割线）。Home Indicator 由系统 Safe Area 处理，勿在栏内再留空。
//

import SwiftUI
import UIKit

enum CustomTabBarMetrics {
    static let iconPointSize: CGFloat = 22
    static let titleFontSize: CGFloat = 10
    static let iconTitleSpacing: CGFloat = 4
    static let itemAreaHeight: CGFloat = 49
    static var separatorHeight: CGFloat { 1 / UIScreen.main.scale }

    /// 本 View 实际占位高度（不含 Home Indicator）
    static var layoutHeight: CGFloat {
        itemAreaHeight + separatorHeight
    }
}

/// 自定义底部 Tab 的一项配置。
struct CustomTabBarItem<Selection: Hashable> {
    /// 与 `selection` 绑定值对应。
    let selection: Selection
    /// 标题文案。
    let title: String
    /// SF Symbol 名称。
    let systemImage: String
}

/// 自绘底部 Tab 栏（49pt 内容区 + 顶部分割线）；Home Indicator 由系统 Safe Area 处理。
struct CustomTabBar<Selection: Hashable>: View {
    /// Tab 项列表。
    let items: [CustomTabBarItem<Selection>]
    /// 当前选中项，与 `TabView(selection:)` 等配合。
    @Binding var selection: Selection
    /// 选中态主题色。
    var tint: Color = .accentColor

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(uiColor: .separator))
                .frame(height: CustomTabBarMetrics.separatorHeight)
            Color.clear.frame(height: 4)
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    tabButton(item)
                }
            }
            .frame(height: CustomTabBarMetrics.itemAreaHeight)
        }
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .systemBackground))
    }

    private func tabButton(_ item: CustomTabBarItem<Selection>) -> some View {
        let isSelected = selection == item.selection

        return Button {
            selection = item.selection
        } label: {
            VStack(spacing: CustomTabBarMetrics.iconTitleSpacing) {
                Image(systemName: item.systemImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: CustomTabBarMetrics.iconPointSize, height: CustomTabBarMetrics.iconPointSize)
                Text(item.title)
                    .font(.system(size: CustomTabBarMetrics.titleFontSize, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(isSelected ? tint : Color(uiColor: .secondaryLabel))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}
