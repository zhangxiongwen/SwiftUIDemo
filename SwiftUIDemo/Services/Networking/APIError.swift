//
//  APIError.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case decodingFailed(Error)
    
    // HTTP 层面的错误 (比如 404, 500)
    case httpError(Int)
    
    // 业务层面的错误 (HTTP 200, 但 code != 0)
    // 这里的 message 直接透传后端返回的多语言 message
    case businessError(code: Int, message: String)
    
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 URL"
        case .requestFailed(let error): return "网络请求失败: \(error.localizedDescription)"
        case .decodingFailed: return "数据解析失败"
        case .httpError(let code): return "服务器异常 (HTTP \(code))"
        case .businessError(_, let message): return message // 直接展示后端给的错误提示
        case .unknown: return "未知错误"
        }
    }
}
