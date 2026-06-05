//
//  User.swift
//  SwiftUIDemo
//
//  跨模块复用的数据模型示例
//

import Foundation

struct User: Codable, Hashable, Identifiable {
    let id: Int
    var username: String
    var avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case avatarURL = "avatar_url"
    }
}
