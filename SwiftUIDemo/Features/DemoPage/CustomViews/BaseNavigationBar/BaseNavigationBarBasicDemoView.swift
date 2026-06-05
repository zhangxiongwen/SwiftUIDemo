//
//  BaseNavigationBarBasicDemoView.swift
//  SwiftUIDemo
//

import SwiftUI

struct BaseNavigationBarBasicDemoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("字符串标题 + 自动返回")
                    .appFont(AppFonts.h2)
                Text("""
                .baseNavigationBar(title: "基础用法")
                """)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(AppColors.textSecondary)

                demoBlock
            }
            .padding()
        }
        .baseNavigationBar(title: "基础用法")
    }

    private var demoBlock: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AppColors.surface)
            .frame(height: 120)
            .overlay {
                Text("页面内容区域")
                    .foregroundStyle(AppColors.textSecondary)
            }
    }
}
