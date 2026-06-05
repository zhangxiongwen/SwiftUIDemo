//
//  AsyncPage.swift
//  SwiftUIDemo
//

import SwiftUI

struct AsyncPage: View {
    @State private var resultText = "点击下方按钮开始"
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            if isLoading {
                ProgressView()
                Text("加载中...")
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                Text(resultText)
                    .appFont(AppFonts.body)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            PrimaryButton(title: "模拟 async/await 请求", isLoading: isLoading) {
                Task { await runMockRequest() }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .baseNavigationBar(title: "异步")
    }

    private func runMockRequest() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        resultText = "请求完成：\(Date().formatted(date: .omitted, time: .standard))"
        isLoading = false
    }
}
