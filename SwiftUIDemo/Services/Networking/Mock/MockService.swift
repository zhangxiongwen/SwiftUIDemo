//
//  MockService.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation

struct MockService {
    
    // 核心分发器：输入 Endpoint，输出 Data (模拟服务器返回的原始 JSON Data)
    static func request(endpoint: Endpoint) async throws -> Data {
        
        // 1. 模拟网络延迟 (0.5 ~ 1.5秒)
        let delay = UInt64(Double.random(in: 0.05...0.5) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: delay)
        
        // 2. 打印日志
        AppLogger.network.debug("👻 [MOCK] Hit: \(endpoint.path)")
        
        // 3. 根据 Path 匹配假数据
        // 注意：这里的 path 必须和你 Endpoint 定义的一致
        switch endpoint.path {
            
        // MARK: - Auth 模块
        case "/api/v1/auth/login":
            return json(from: [
                "code": 0,
                "message": "登录成功",
                "data": [
                    "token": "mock_jwt_token_888888",
                    "userId": 1001,
                    "nickname": "Mock用户"
                ]
            ])
            
        // MARK: - Home 模块 (Mock 首页数据)
        case "/api/v1/home/data":
            return json(from: [
                "code": 0,
                "message": "ok",
                "data": [
                    "banners": [
                        ["id": "uuid-1", "title": "Mock 轮播图 1", "url": "...", "color": "blue"],
                        ["id": "uuid-2", "title": "Mock 轮播图 2", "url": "...", "color": "red"]
                    ],
                    "feeds": [
                        ["id": 1, "title": "Mock 动态 1", "desc": "测试内容...", "time": "1分钟前"],
                        ["id": 2, "title": "Mock 动态 2", "desc": "测试内容...", "time": "2分钟前"]
                    ]
                ]
            ])
            
        default:
            // 如果没匹配到，返回一个通用的成功空包，或者抛错
            AppLogger.network.error("👻 [MOCK] 404 Not Found: \(endpoint.path)")
            return json(from: [
                "code": 404,
                "message": "Mock 数据未定义",
                "data": nil
            ])
        }
    }
    
    // 辅助工具：把 Dictionary 转成 Data
    private static func json(from dict: [String: Any]) -> Data {
        do {
            return try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        } catch {
            fatalError("Mock JSON 格式错误: \(error)")
        }
    }
}
