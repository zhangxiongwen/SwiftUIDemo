//
//  SystemViewsPage.swift
//  SwiftUIDemo
//

import SwiftUI

struct SystemViewsPage: View {
    @State private var toggleOn = true
    @State private var sliderValue = 0.5
    @State private var selectedSegment = 0

    var body: some View {
        Form {
            Section("开关与滑块") {
                Toggle("通知开关", isOn: $toggleOn)
                Slider(value: $sliderValue)
                Text("当前值：\(Int(sliderValue * 100))%")
                    .foregroundStyle(AppColors.textSecondary)
            }

            Section("分段与选择") {
                Picker("模式", selection: $selectedSegment) {
                    Text("列表").tag(0)
                    Text("网格").tag(1)
                }
                .pickerStyle(.segmented)
            }

            Section("按钮样式") {
                Button("主要按钮") {}
                    .buttonStyle(.borderedProminent)
                Button("次要按钮") {}
                    .buttonStyle(.bordered)
            }
        }
        .baseNavigationBar(title: "系统控件")
    }
}
