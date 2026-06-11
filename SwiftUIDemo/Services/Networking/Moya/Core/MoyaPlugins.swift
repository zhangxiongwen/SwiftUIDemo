//
//  MoyaPlugins.swift
//  SwiftUIDemo
//
//  Moya 插件：日志、Token 注入等横切逻辑。
//

import Foundation
import Moya

// MARK: - 插件工厂

enum MoyaPluginFactory {

  /// 默认插件链（顺序：鉴权 → 日志）
  static var defaultPlugins: [PluginType] {
    [
      AuthPlugin(),
      NetworkLoggerPlugin()
    ]
  }
}

// MARK: - 鉴权插件

/// 自动注入 Bearer Token（登录态接口使用）。
struct AuthPlugin: PluginType {

  func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
    var request = request

    // 白名单：不需要 Token 的接口在此排除
    if let authTarget = target as? AuthTargetType, authTarget.requiresAuth == false {
      return request
    }

    if let token = TokenManager.shared.getToken() {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    return request
  }
}

/// 可选协议：Target 声明是否需要鉴权。
protocol AuthTargetType: TargetType {
  var requiresAuth: Bool { get }
}

extension AuthTargetType {
  var requiresAuth: Bool { true }
}

// MARK: - 日志插件

struct NetworkLoggerPlugin: PluginType {

  func willSend(_ request: RequestType, target: TargetType) {
    guard let urlRequest = request.request else { return }
    let method = urlRequest.httpMethod ?? "?"
    let url = urlRequest.url?.absoluteString ?? "?"
    AppLogger.network.info("➡️ Moya [\(method)] \(url)")
  }

  func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
    switch result {
    case .success(let response):
      AppLogger.network.info("⬅️ Moya [\(response.statusCode)] \(target.path)")
      #if DEBUG
      if let body = String(data: response.data, encoding: .utf8) {
        AppLogger.network.debug("\(body)")
      }
      #endif
    case .failure(let error):
      AppLogger.network.error("❌ Moya \(target.path): \(error.localizedDescription)")
    }
  }
}
