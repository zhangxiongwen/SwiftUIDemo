//
//  AuthEndpoint.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

// 模拟登录请求体
struct LoginRequest: Encodable {
    let phone: String
    let code: String
}

// 模拟登录返回数据
struct UserToken: Decodable {
    let token: String
    let userId: Int
}

enum AuthEndpoint: Endpoint {
    case login(phone: String, code: String)
    
    var path: String {
        switch self {
        case .login: return "/api/v1/auth/login"
        }
    }
    
    var method: HTTPMethod { return .post }
    
    var body: Encodable? {
        switch self {
        case .login(let phone, let code):
            return LoginRequest(phone: phone, code: code)
        }
    }
}
