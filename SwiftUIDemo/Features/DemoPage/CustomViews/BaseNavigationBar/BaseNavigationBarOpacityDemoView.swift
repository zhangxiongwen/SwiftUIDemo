//
//  BaseNavigationBarOpacityDemoView.swift
//  SwiftUIDemo
//

import SwiftUI

struct BaseNavigationBarOpacityDemoView: View {
    @State private var barBackgroundOpacity: Double = 1

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("通过 backgroundColor 的 alpha 控制背景透明度，拖动滑块会实时更新。")
                    .appFont(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)

                HStack {
                    Text("背景透明度")
                    Slider(value: $barBackgroundOpacity, in: 0...1)
                    Text("\(Int(barBackgroundOpacity * 100))%")
                        .monospacedDigit()
                        .frame(width: 44, alignment: .trailing)
                }

                Text("""
                .baseNavigationBar(
                    title: "透明度",
                    backgroundColor: AppColors.background.opacity(barBackgroundOpacity)
                )
                """)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(AppColors.textSecondary)

                demoBlock
            }
            .padding()
        }
        .baseNavigationBar(
            title: "透明度",
            backgroundColor: Color.green.opacity(barBackgroundOpacity)
        )
    }

    private var demoBlock: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 200)
            .overlay {
                Text("拖动滑块观察导航栏背景渐变")
                    .foregroundStyle(AppColors.textPrimary)
            }
    }
}
