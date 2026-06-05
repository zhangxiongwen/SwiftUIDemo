//
//  LoginView.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import SwiftUI

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @FocusState private var isPhoneFocused: Bool

    var body: some View {
        loginContent
    }

    private var loginContent: some View {
        ZStack {
            // 背景色 (使用设计系统)
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // --- 头部区域 ---
                VStack(spacing: 10) {
                    Image(systemName: "swift") // 这里以后换成 App Logo
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundStyle(AppColors.primary)
                    
                    Text(AppStrings.Login.welcome)
                        .appFont(AppFonts.h1)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text(AppStrings.Login.subtitle)
                        .appFont(AppFonts.body)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.top, 60)
                
                // --- 表单区域 ---
                VStack(spacing: 20) {
                    // 手机号输入框
                    TextField(AppStrings.Login.phonePlaceholder, text: $viewModel.phone)
                        .textFieldStyle(CustomTextFieldStyle()) // 下面定义的样式
                        .keyboardType(.numberPad)
                        .focused($isPhoneFocused)
                        .onChange(of: viewModel.phone) { _, newValue in
                            // 简单的长度限制
                            if newValue.count > 11 {
                                viewModel.phone = String(newValue.prefix(11))
                            }
                        }
                    
                    // 验证码输入框
                    TextField(AppStrings.Login.codePlaceholder, text: $viewModel.code)
                        .textFieldStyle(CustomTextFieldStyle())
                        .keyboardType(.numberPad)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // --- 底部按钮区域 ---
                VStack(spacing: 16) {
                    // 使用我们封装的 PrimaryButton
                    PrimaryButton(
                        title: AppStrings.Login.btnTitle,
                        isLoading: viewModel.state == .loading,
                        isDisabled: !viewModel.isValid
                    ) {
                        // 点击收起键盘
                        hideKeyboard()
                        
                        // 执行登录
                        Task {
                            await viewModel.login()
                        }
                    }
                    
                    Text(AppStrings.Login.agreement)
                        .appFont(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        // --- 交互反馈 ---
        // 1. 全屏 Loading 遮罩
        .overlay {
            if viewModel.state == .loading {
                LoadingView()
            }
        }
        // 3. 点击空白处收起键盘
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // 辅助函数：收起键盘
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - 局部样式组件
// 在实际项目中，这个可以移到 DesignSystem/Modifiers 中
struct CustomTextFieldStyle: TextFieldStyle {
    // swiftlint:disable:next identifier_name
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(AppColors.surface) // 使用设计系统颜色
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.textSecondary.opacity(0.2), lineWidth: 1)
            )
            .appFont(AppFonts.body)
    }
}

#Preview {
    LoginView()
}
