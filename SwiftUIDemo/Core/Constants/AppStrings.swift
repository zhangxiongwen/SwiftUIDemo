//
//  AppStrings.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation

// 前提：你必须保留之前写的 String+Localized.swift 扩展
// 现在的逻辑：AppStrings 直接返回翻译好的中文/英文，View 拿来直接用

struct AppStrings {
    
    // MARK: - 通用
    struct Common {
        static var loading: String { "common_loading".localized }
        static var confirm: String { "common_confirm".localized }
        static var prompt: String  { "common_prompt".localized }
    }
    
    // MARK: - 网络与错误
    struct Network {
        static var invalidURL: String       { "error_invalid_url".localized }
        static var invalidResponse: String  { "error_invalid_response".localized }
        static var decodingFailed: String   { "error_decoding_failed".localized }
        static var unknown: String          { "error_unknown".localized }
        
        // 带参数的比较特殊，还是得返回 Key，或者写个方法
        static func requestFailed(_ msg: String) -> String {
            return String(format: "error_request_failed".localized, msg)
        }
        
        static func serverError(_ code: Int) -> String {
            return String(format: "error_server_error".localized, code)
        }
    }
    
    // MARK: - 登录模块
    struct Login {
        static var welcome: String          { "login_welcome".localized }
        static var subtitle: String         { "login_subtitle".localized }
        static var phonePlaceholder: String { "login_phone_placeholder".localized }
        static var codePlaceholder: String  { "login_code_placeholder".localized }
        static var btnTitle: String         { "login_btn_title".localized }
        static var agreement: String        { "login_agreement".localized }
    }
    
    // MARK: - 首页
    struct Home {
        static var tabTitle: String { "home_tab_title".localized }
        static var navTitle: String { "home_nav_title".localized }
        static var noData: String   { "home_no_data".localized }
    }
    
    struct Detail {
        static var navTitle: String { "detail_nav_title".localized }
    }
    
    // MARK: - 设置
    struct Settings {
        static var tabTitle: String     { "settings_tab_title".localized } // 我的
        static var navTitle: String     { "settings_nav_title".localized } // 设置
        
        static var profile: String      { "settings_profile".localized }   // 个人资料
        static var theme: String        { "settings_theme".localized }     // 主题设置
        static var language: String     { "settings_language".localized }  // 语言设置
        static var clearCache: String   { "settings_clear_cache".localized } // 清理缓存
        static var about: String        { "settings_about".localized }     // 关于我们
        static var privacy: String      { "settings_privacy".localized }   // 隐私政策
        static var terms: String        { "settings_terms".localized }     // 用户协议
        static var version: String      { "settings_version".localized }   // 当前版本
        static var logout: String       { "settings_logout".localized }    // 退出登录
    }
    
    struct Web {
        static var loading: String      { "web_loading".localized } // 加载中...
    }
}
