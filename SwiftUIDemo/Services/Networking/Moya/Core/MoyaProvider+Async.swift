//
//  MoyaProvider+Async.swift
//  SwiftUIDemo
//
//  为 MoyaProvider 提供 async/await 封装，供 SwiftUI / ViewModel 使用。
//

import Foundation
import Moya

extension MoyaProvider {

  /// 异步发起请求，成功返回 Response，失败抛出 MoyaError。
  func request(_ target: Target) async throws -> Response {
    try await withCheckedThrowingContinuation { continuation in
      self.request(target) { result in
        switch result {
        case .success(let response):
          continuation.resume(returning: response)
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
  }
}
