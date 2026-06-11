//
//  DemoTarget.swift
//  SwiftUIDemo
//
//  NetworkDemo 模块 · Moya Target 定义。
//

import Foundation
import Moya

/// NetworkDemo 模块接口（JSONPlaceholder 开放 API）
enum DemoTarget {
  case fetchPosts
  case fetchPost(id: Int)
  case createPost(title: String, body: String, userId: Int)
}

extension DemoTarget: TargetType {

  var baseURL: URL {
    URL(string: MoyaNetworkConfig.demoBaseURL)!
  }

  var path: String {
    switch self {
    case .fetchPosts, .createPost:
      return "/posts"
    case .fetchPost(let id):
      return "/posts/\(id)"
    }
  }

  var method: Moya.Method {
    switch self {
    case .fetchPosts, .fetchPost:
      return .get
    case .createPost:
      return .post
    }
  }

  var task: Task {
    switch self {
    case .fetchPosts, .fetchPost:
      return .requestPlain
    case .createPost(let title, let body, let userId):
      return .requestParameters(
        parameters: ["title": title, "body": body, "userId": userId],
        encoding: JSONEncoding.default
      )
    }
  }

  var headers: [String: String]? {
    MoyaNetworkConfig.commonHeaders
  }

  var sampleData: Data { Data() }
}

extension DemoTarget: AuthTargetType {
  var requiresAuth: Bool { false }
}
