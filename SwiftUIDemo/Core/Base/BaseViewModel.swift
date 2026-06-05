//
//  BaseViewModel.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation
import SwiftUI

// 定义页面状态
enum ViewState: Equatable {
    case idle       // 空闲
    case loading    // 加载中
    case success    // 成功
    case error(String) // 失败（带消息）
}

@Observable // iOS 17+ 新宏，替代 ObservableObject
class BaseViewModel {
    // 当前页面状态
    var state: ViewState = .idle
    
    // 控制 Toast 或 Alert 显示的辅助变量
    // 🗑️ 删除旧的 Alert 相关变量
    // var showErrorAlert: Bool = false
    // var errorMessage: String = ""
    
    // 通用错误处理方法
    func handleError(_ error: Error) {
        self.state = .error(error.localizedDescription)
        //self.errorMessage = error.localizedDescription
        //self.showErrorAlert = true
        
        // 打印错误日志
        AppLogger.ui.error("UI Error caught: \(error.localizedDescription)")
        
        // ✅ 调用 Toast 显示错误
        // 必须在 MainActor 执行，虽然 Observable 也是线程安全的，但涉及 UI 最好明确
        Task { @MainActor in
            showToast(error.localizedDescription, position: .center)
        }
    }
    
    // 提供一个便捷方法给子类显示成功信息
    func showSuccess(_ message: String) {
        Task { @MainActor in
            showToast(message, position: .center)
        }
    }
    
    // 快捷方法：开始加载
    func startLoading() {
        self.state = .loading
    }
    
    // 快捷方法：结束加载（成功）
    func stopLoading() {
        self.state = .success
    }
}
