//
//  MoyaResponseDecoder.swift
//  SwiftUIDemo
//
//  统一解析 Moya Response：HTTP 校验、业务 code 校验、JSON 解码。
//

import Foundation
import Moya

enum MoyaResponseDecoder {

  private static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }()

  // MARK: - 直接解析（接口 JSON 即为业务模型）

  static func decode<T: Decodable>(_ response: Response, as type: T.Type) throws -> T {
    try validateHTTP(response)
    return try decodeData(response.data, as: type)
  }

  // MARK: - 解析 APIResponse 包装（{ code, message, data }）

  static func decodeWrapped<T: Decodable>(_ response: Response, as type: T.Type) throws -> T {
    try validateHTTP(response)
    let wrapper = try decodeData(response.data, as: APIResponse<T>.self)

    guard wrapper.isSuccess else {
      throw APIError.businessError(code: wrapper.code, message: wrapper.message)
    }

    guard let data = wrapper.data else {
      throw APIError.businessError(code: wrapper.code, message: wrapper.message)
    }
    return data
  }

  // MARK: - 私有

  private static func validateHTTP(_ response: Response) throws {
    guard (200...299).contains(response.statusCode) else {
      throw APIError.httpError(response.statusCode)
    }
  }

  private static func decodeData<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
    do {
      return try decoder.decode(type, from: data)
    } catch {
      throw APIError.decodingFailed(error)
    }
  }
}
