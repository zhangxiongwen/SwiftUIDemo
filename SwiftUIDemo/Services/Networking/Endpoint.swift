//
//  Endpoint.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation

// HTTP 方法枚举
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// 定义一个 API 接口必须包含什么
protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var body: Encodable? { get }
}

// 提供默认值扩展
extension Endpoint {
    var headers: [String: String]? {
        // 默认 Header，比如 JSON
        return ["Content-Type": "application/json"]
    }
    
    var body: Encodable? { return nil }
}
