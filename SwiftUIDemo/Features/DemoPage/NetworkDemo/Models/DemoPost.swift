//
//  DemoPost.swift
//  SwiftUIDemo
//
//  NetworkDemo 模块 · 业务模型。
//

import Foundation

struct DemoPost: Codable, Identifiable, Hashable {
  let id: Int
  let userId: Int
  let title: String
  let body: String
}

struct CreatePostRequest: Encodable {
  let title: String
  let body: String
  let userId: Int
}
