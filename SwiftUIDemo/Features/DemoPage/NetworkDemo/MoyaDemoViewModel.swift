//
//  MoyaDemoViewModel.swift
//  SwiftUIDemo
//
//  NetworkDemo 模块 · ViewModel。
//

import Combine
import Foundation

@MainActor
final class MoyaDemoViewModel: ObservableObject {

  @Published private(set) var posts: [DemoPost] = []
  @Published private(set) var selectedPost: DemoPost?
  @Published private(set) var isLoading = false
  @Published private(set) var errorMessage: String?
  @Published private(set) var lastActionLog = "点击下方按钮发起 Moya 请求"

  private let api = DemoAPIService.shared

  func loadPosts() {
    Task { await run(title: "GET /posts 列表") { try await api.fetchPosts() } update: { self.posts = $0 } }
  }

  func loadPostDetail() {
    Task {
      await run(title: "GET /posts/1 详情") {
        try await api.fetchPost(id: 1)
      } update: { post in
        self.selectedPost = post
        self.posts = [post]
      }
    }
  }

  func createPost() {
    Task {
      await run(title: "POST /posts 创建") {
        try await api.createPost(
          title: "Moya Demo",
          body: "由 SwiftUIDemo 通过 Moya 创建",
          userId: 1
        )
      } update: { post in
        self.selectedPost = post
        self.posts.insert(post, at: 0)
      }
    }
  }

  private func run<T>(
    title: String,
    request: () async throws -> T,
    update: (T) -> Void
  ) async {
    isLoading = true
    errorMessage = nil
    lastActionLog = "请求中：\(title)…"

    do {
      let result = try await request()
      update(result)
      lastActionLog = "✅ 成功：\(title)"
    } catch {
      errorMessage = error.localizedDescription
      lastActionLog = "❌ 失败：\(title)"
    }

    isLoading = false
  }
}
