//
//  BaseNavigationBarCustomDemoView.swift
//  SwiftUIDemo
//

import SwiftUI

struct BaseNavigationBarCustomDemoView: View {
    @State private var navigator = Navigator()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("leading / title / trailing 均可传入任意 View。")
                    .appFont(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)

                demoBlock
            }
            .padding()
        }
        .baseNavigationBar(
            leading: {
                
                HStack{
                    BaseNavigationBarBackButton {
                        navigator.back()
                    }
                    VStack(alignment: .leading){
                        Text("大标题")
                            .font(.system(size: 15))
                        Text("小标题")
                            .font(.system(size: 10))
                    }
                }
            },
            title: {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.orange)
                    Text("自定义标题")
                        .font(.headline)
                }
            },
            trailing: {
                Button("完成") {}
                    .font(.subheadline.weight(.semibold))
            }
        )
        .navigator(navigator)
    }

    private var demoBlock: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AppColors.surface)
            .frame(height: 120)
            .overlay {
                Text("左侧关闭 · 中间图标标题 · 右侧完成")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
    }
}
