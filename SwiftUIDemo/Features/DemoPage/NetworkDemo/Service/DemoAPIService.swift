//
//  DemoAPIService.swift
//  SwiftUIDemo
//
//  NetworkDemo 模块 · Service 层。
//  ViewModel 直接调这个类的方法即可，不需要再套一层 Protocol。
//

import Foundation

final class DemoAPIService {

  static let shared = DemoAPIService()

  private let client: MoyaNetworkClient

  private init(client: MoyaNetworkClient = .shared) {
    self.client = client
  }

  func fetchPosts() async throws -> [DemoPost] {
    try await client.request(DemoTarget.fetchPosts, as: [DemoPost].self)
  }

  func fetchPost(id: Int) async throws -> DemoPost {
    try await client.request(DemoTarget.fetchPost(id: id), as: DemoPost.self)
  }

  func createPost(title: String, body: String, userId: Int) async throws -> DemoPost {
    try await client.request(
      DemoTarget.createPost(title: title, body: body, userId: userId),
      as: DemoPost.self
    )
  }
}
