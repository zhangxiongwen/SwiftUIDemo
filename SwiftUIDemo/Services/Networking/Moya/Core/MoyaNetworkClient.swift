//
//  MoyaNetworkClient.swift
//  SwiftUIDemo
//
//  网络请求统一入口：创建 Provider、发起请求、映射错误。
//
//  使用规范：
//  1. View / ViewModel 不直接碰 MoyaProvider，只调本模块 XXXAPIService
//  2. Target / Model / Service 写在各自 Features/XXXModule/ 目录下
//  3. 本文件所在 Core/ 目录仅放公共基建
//

import Foundation
import Moya

final class MoyaNetworkClient {

  static let shared = MoyaNetworkClient()

  private init() {}

  // MARK: - Provider

  func makeProvider<T: TargetType>(
    for type: T.Type,
    plugins: [PluginType] = MoyaPluginFactory.defaultPlugins,
    stubBehavior: Moya.StubBehavior = .never
  ) -> MoyaProvider<T> {
    MoyaProvider<T>(
      requestClosure: MoyaProvider<T>.defaultRequestMapping,
      stubClosure: { _ in stubBehavior },
      plugins: plugins
    )
  }

  // MARK: - 请求（直接解析 JSON → Model）

  /// 接口返回体即为业务模型（或数组），不经 APIResponse 包装。
  func request<T: TargetType, R: Decodable>(
    _ target: T,
    as type: R.Type,
    provider: MoyaProvider<T>? = nil
  ) async throws -> R {
    let provider = provider ?? makeProvider(for: T.self)
    do {
      let response = try await provider.request(target)
      return try MoyaResponseDecoder.decode(response, as: type)
    } catch let error as MoyaError {
      throw mapMoyaError(error)
    }
  }

  // MARK: - 请求（解析 APIResponse<T> 包装）

  /// 自家后端统一格式：{ "code": 0, "message": "ok", "data": { ... } }
  func requestWrapped<T: TargetType, R: Decodable>(
    _ target: T,
    as type: R.Type,
    provider: MoyaProvider<T>? = nil
  ) async throws -> R {
    let provider = provider ?? makeProvider(for: T.self)
    do {
      let response = try await provider.request(target)
      return try MoyaResponseDecoder.decodeWrapped(response, as: type)
    } catch let error as MoyaError {
      throw mapMoyaError(error)
    }
  }

  // MARK: - 错误映射

  private func mapMoyaError(_ error: MoyaError) -> APIError {
    switch error {
    case .statusCode(let response):
      return .httpError(response.statusCode)
    case .imageMapping, .jsonMapping, .stringMapping, .objectMapping:
      return .decodingFailed(error)
    case .encodableMapping(let underlying):
      return .requestFailed(underlying)
    case .underlying(let underlying, let response):
      if let response, !(200...299).contains(response.statusCode) {
        return .httpError(response.statusCode)
      }
      return .requestFailed(underlying)
    case .requestMapping:
      return .invalidURL
    case .parameterEncoding(let underlying):
      return .requestFailed(underlying)
    }
  }
}
