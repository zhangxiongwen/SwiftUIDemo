//
//  LoginViewModel.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation

@Observable
class LoginViewModel: BaseViewModel {
    
    var phone: String = ""
    var code: String = ""
    
    // 输入校验
    var isValid: Bool {
        return !phone.isEmpty && !code.isEmpty
    }
    
    func login() async {
        guard isValid else { return }
        
        // 1. 继承自 BaseViewModel，自动设置状态为 .loading
        startLoading()
        
        do {
            // 2. 调用网络层 (泛型指定为 UserToken)
            // 注意：这里如果后端 code!=0，HTTPClient 会抛出 APIError.businessError
            let userToken = try await HTTPClient.shared.sendRequest(
                AuthEndpoint.login(phone: phone, code: code),
                responseModel: UserToken.self
            )
            
            // AppLogger.ui.debug("登录成功，Token: \(userToken.token)")
            // 3. 成功逻辑 (这里以后可以保存 Token 到 Keychain)
            // stopLoading()
            
            // 2. 【关键】告诉 UserManager 我登录了！
            // UI 会瞬间自动切换到 MainTabView
            await MainActor.run {
                UserManager.shared.login(token: userToken.token)
                stopLoading()
            }
            
        } catch {
            // 4. 继承自 BaseViewModel，自动处理错误消息和弹窗
            handleError(error)
        }
    }
}
