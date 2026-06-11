//
//  MoyaNetworkConfig.swift
//  SwiftUIDemo
//
//  Moya 网络层全局配置：BaseURL、超时、公共 Header。
//

import Foundation

enum MoyaNetworkConfig {

  /// 默认请求超时（秒）
  static let timeoutInterval: TimeInterval = AppConfig.timeoutInterval

  /// 业务接口 BaseURL（走自家后端时用）
  static var businessBaseURL: String {
    AppConfig.current.baseURL
  }

  /// Demo / 第三方开放接口 BaseURL
  static let demoBaseURL = "https://jsonplaceholder.typicode.com"

  /// 所有请求都会带的公共 Header（可在 Plugin 里追加 Token）
  static var commonHeaders: [String: String] {
    [
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Accept-Language": Locale.apiLanguageCode
    ]
  }
}
