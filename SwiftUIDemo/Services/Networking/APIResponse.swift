//
//  APIResponse.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation

// 这是一个泛型结构，T 代表具体的业务数据类型（比如 User, [Todo] 等）
struct APIResponse<T: Decodable>: Decodable {
    let code: Int
    let message: String
    let data: T? // data 有可能是 nil（比如报错时，或者某些接口只返回成功状态不返回内容）
    
    // 辅助判断是否成功
    var isSuccess: Bool {
        return code == 0
    }
}

// 针对那些 data 为空的情况（比如只返回 {code:0, message:"ok"} 的操作接口）
struct EmptyData: Decodable {}
