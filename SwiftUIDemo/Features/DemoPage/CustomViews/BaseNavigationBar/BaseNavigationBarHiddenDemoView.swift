//
//  BaseNavigationBarHiddenDemoView.swift
//  SwiftUIDemo
//

import SwiftUI

struct BaseNavigationBarHiddenDemoView: View {
    @State private var hideCustomBar = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("hidden 控制是否绘制自绘栏；系统栏始终由 modifier 隐藏。")
                    .appFont(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Toggle("隐藏自绘导航栏 (hidden)", isOn: $hideCustomBar)

                Text("""
                @State private var hideCustomBar = false

                .baseNavigationBar(
                    title: "隐藏/显示",
                    hidden: hideCustomBar
                )
                """)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(AppColors.textSecondary)

                demoBlock
            }
            .padding()
        }
        .baseNavigationBar(title: "隐藏/显示", hidden: hideCustomBar)
    }

    private var demoBlock: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AppColors.surface)
            .frame(height: 160)
            .overlay {
                Text(hideCustomBar ? "自绘栏已隐藏" : "自绘栏显示中")
                    .foregroundStyle(AppColors.textSecondary)
            }
    }
}
