//
//  HTTPClient.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation

// 辅助扩展：获取当前系统语言，格式如 "zh-CN", "en-US"
extension Locale {
    static var apiLanguageCode: String {
        // 获取首选语言，如果获取不到默认用英文
        return Locale.preferredLanguages.first ?? "en"
    }
}

class HTTPClient {
    static let shared = HTTPClient()
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    // 注意：这里的 T 是业务层真正想要的数据类型，不需要再包一层 APIResponse
    func sendRequest<T: Decodable>(_ endpoint: Endpoint, responseModel: T.Type) async throws -> T {
        
        // ✨Mock 拦截
        if AppConfig.useMock {
            // 1. 获取假数据 (Data)
            let data = try await MockService.request(endpoint: endpoint)
            
            // 2. 复用已有的解析逻辑 (APIResponse -> T)
            // 这样能保证 Mock 数据也必须符合 APIResponse 结构，测试了解析层
            return try decodeData(data, to: responseModel)
        }
        
        guard let url = URL(string: AppConfig.current.baseURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = AppConfig.timeoutInterval
        
        // 1. 设置通用的 Header
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 2. 【关键】自动注入多语言 Header
        // 告诉后端：“请给我返回中文的 message”
        request.setValue(Locale.apiLanguageCode, forHTTPHeaderField: "Accept-Language")
        
        // 自动注入 Token
        // 只有当本地有 Token，且接口不是登录/注册接口(你可以加个白名单判断)时，才携带
        if let token = TokenManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            AppLogger.network.debug("🔑 Token injected")
        }
        
        // 合并 Endpoint 特有的 Header
        if let customHeaders = endpoint.headers {
            for (key, value) in customHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let body = endpoint.body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw APIError.requestFailed(error)
            }
        }
        
        AppLogger.network.info("➡️ [\(endpoint.method.rawValue)] \(url.absoluteString)")
        AppLogger.network.debug("Language: \(Locale.apiLanguageCode)")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }
            
            AppLogger.network.info("⬅️ HTTP Status: \(httpResponse.statusCode)")
            
            // 3. 处理 HTTP 状态码
            // 按照需求：接口异常为 500 (或者其他非 200 系列)
            guard httpResponse.statusCode == 200 else {
                // 如果是 500 或 404，直接抛出 HTTP 错误
                throw APIError.httpError(httpResponse.statusCode)
            }
            
            // 4. 解析统一的外层结构 (APIResponse)
            // 我们先尝试把 data 解析成目标类型 T
            let apiResponse = try JSONDecoder().decode(APIResponse<T>.self, from: data)
            
            // 5. 校验业务 Code
            if apiResponse.isSuccess {
                // Code == 0，成功
                // 如果 data 存在则返回，如果 data 为 nil (有些接口可能不返回数据)，这需要和后端约定。
                // 这里我们假设 T 为 Optional 或者必然有数据。
                // 强行解包的风险在于：如果后端 code=0 但 data 没给，这里会崩。
                // 建议：如果 T 允许为空，T 应该是 Optional 的，但在泛型里不好处理。
                // 稳妥方案：如果 data 为 nil，抛出解析错误（除非 T 是 EmptyData）
                if let validData = apiResponse.data {
                    return validData
                } else if T.self == EmptyData.self {
                    // 如果业务不需要 data，可以传 EmptyData 类型
                    // return EmptyData() as! T
                    // ✅ 修复后：使用 as? 尝试转换，如果（理论上不可能的）失败发生了，则抛出错误
                    if let empty = EmptyData() as? T {
                        return empty
                    }
                    // 这种情况几乎不会发生，但为了满足编译器和 Lint 的安全性要求
                    throw APIError.decodingFailed(NSError(domain: "CastError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to cast EmptyData"]))
                } else {
                    // code 0 但 data 缺失
                     throw APIError.decodingFailed(NSError(domain: "DataMissing", code: -1))
                }
            } else {
                // Code != 0，失败
                // 抛出业务错误，message 是后端翻译好的
                AppLogger.network.error("Business Error: \(apiResponse.code) - \(apiResponse.message)")
                throw APIError.businessError(code: apiResponse.code, message: apiResponse.message)
            }
            
        } catch {
            // 捕获所有错误并打印
            AppLogger.network.error("Request Error: \(error)")
            if let apiError = error as? APIError {
                throw apiError
            } else if let decodingError = error as? DecodingError {
                throw APIError.decodingFailed(decodingError)
            } else {
                throw APIError.requestFailed(error)
            }
        }
    }
    // ✨【新增私有方法】统一解析逻辑
    private func decodeData<T: Decodable>(_ data: Data, to type: T.Type) throws -> T {
        // 1. 解析外层 APIResponse
        let apiResponse = try JSONDecoder().decode(APIResponse<T>.self, from: data)
        
        // 2. 校验业务 Code
        if apiResponse.isSuccess {
            if let validData = apiResponse.data {
                return validData
            } else if T.self == EmptyData.self {
                //return EmptyData() as! T
                // ✅ 修复后：使用 as? 尝试转换，如果（理论上不可能的）失败发生了，则抛出错误
                if let empty = EmptyData() as? T {
                    return empty
                }
                // 这种情况几乎不会发生，但为了满足编译器和 Lint 的安全性要求
                throw APIError.decodingFailed(NSError(domain: "CastError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to cast EmptyData"]))
            } else {
                throw APIError.decodingFailed(NSError(domain: "DataMissing", code: -1))
            }
        } else {
            throw APIError.businessError(code: apiResponse.code, message: apiResponse.message)
        }
    }
}
