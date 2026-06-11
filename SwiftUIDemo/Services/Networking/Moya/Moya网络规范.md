# Moya 网络请求规范

> SwiftUI 项目推荐：**Moya**（基于 Alamofire 的网络抽象层）  
> 本项目的 Moya 封装位于 `Services/Networking/Moya/`。

---

## 1. SwiftUI 一般用什么网络框架？

| 方案 | 说明 | 适用 |
|------|------|------|
| **URLSession** | 系统原生，async/await 直接调 | 小项目、学习、极简场景 |
| **Alamofire (AF)** | 底层 HTTP 库，功能全 | 需要精细控制请求时 |
| **Moya** | 在 AF 之上，用 `enum` 描述 API | **SwiftUI 业务项目首选** |
| **原生 + 自己封装** | 类似本项目旧的 HTTPClient | 可控但要自己维护 |

**为什么推荐 Moya？**

- 每个接口是一个 `enum case`，**类型安全、可搜索、可 Mock**
- `TargetType` 把 path、method、参数集中定义，不散落在 ViewModel
- 插件机制（Plugin）统一处理 Token、日志、Loading
- 与 SwiftUI + async/await + ViewModel 配合自然

关系：

```
ViewModel → APIService → TargetType(enum) → MoyaProvider → Alamofire → 服务器
```

---

## 2. 目录结构规范

**核心原则：`Services/Networking/Moya/` 只放通用基础设施；每个业务模块自己的 Target / Model / Service 写在各自模块目录下。**

```
Services/Networking/Moya/          # 仅公共网络基建
├── Core/
│   ├── MoyaNetworkConfig.swift
│   ├── MoyaPlugins.swift
│   ├── MoyaNetworkClient.swift
│   ├── MoyaResponseDecoder.swift
│   └── MoyaProvider+Async.swift
└── Moya网络规范.md

Features/                          # 各业务模块自包含网络层
├── DemoPage/NetworkDemo/          # 示例：网络 Demo 模块
│   ├── API/DemoTarget.swift
│   ├── Models/DemoPost.swift
│   ├── Service/DemoAPIService.swift
│   ├── MoyaDemoViewModel.swift
│   ├── MoyaDemoView.swift
│   └── NetworkDemoRoute.swift
├── Template/Auth/                   # 示例：登录模块（未来可加）
│   ├── API/AuthTarget.swift
│   ├── Models/LoginRequest.swift
│   └── Service/AuthAPIService.swift
└── Template/Home/                   # 示例：首页模块（未来可加）
    ├── API/HomeTarget.swift
    └── Service/HomeAPIService.swift
```

> **不要**把 `UserAPIService` 写到 `Tools/` 或 `Services/Networking/Moya/Service/` 里——那是模块自己的代码。

---

## 3. 分层职责（必须遵守）

| 层级 | 职责 | 谁调用谁 |
|------|------|----------|
| **View** | 展示 UI、触发加载 | 调 ViewModel 方法 |
| **ViewModel** | 状态管理、调用 Service | 调 `XXXAPIService` |
| **Service** | 业务语义方法（fetchUserList） | 调 `MoyaNetworkClient` + Target |
| **Target** | 描述单个 API（path/method/body） | 被 Service 使用 |
| **Client** | 发请求、解析、错误映射 | 被 Service 使用 |

**禁止：**

- View 里直接 `MoyaProvider.request`
- ViewModel 里写 `path = "/users"` 字符串
- Target 里写 UI 逻辑

---

## 4. 如何定义一个新接口（三步走）

### 第一步：定义 Model

```swift
struct UserProfile: Codable, Identifiable {
    let id: Int
    let username: String
    let avatarURL: String?
}
```

### 第二步：定义 Target（enum + TargetType）

```swift
import Moya

enum UserTarget {
    case fetchProfile(userId: Int)
    case updateProfile(userId: Int, nickname: String)
}

extension UserTarget: TargetType {
    var baseURL: URL {
        URL(string: MoyaNetworkConfig.businessBaseURL)!
    }

    var path: String {
        switch self {
        case .fetchProfile(let id), .updateProfile(let id, _):
            return "/users/\(id)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .fetchProfile: return .get
        case .updateProfile: return .put
        }
    }

    var task: Task {
        switch self {
        case .fetchProfile:
            return .requestPlain
        case .updateProfile(_, let nickname):
            return .requestParameters(
                parameters: ["nickname": nickname],
                encoding: JSONEncoding.default
            )
        }
    }

    var headers: [String: String]? {
        MoyaNetworkConfig.commonHeaders
    }
}

// 需要登录的接口：默认 requiresAuth = true（AuthPlugin 自动加 Token）
extension UserTarget: AuthTargetType {}
```

### 第三步：定义 Service（直接写类，不用 Protocol）

```swift
final class UserAPIService {

    static let shared = UserAPIService()
    private let client = MoyaNetworkClient.shared

    private init() {}

    func fetchProfile(userId: Int) async throws -> UserProfile {
        try await client.requestWrapped(
            UserTarget.fetchProfile(userId: userId),
            as: UserProfile.self
        )
    }
}
```

> **要不要写 Protocol？**  
> 日常业务开发：**不用写**。直接一个 `XXXAPIService` 类，把方法定义好，ViewModel 调就行。  
> 只有下面几种情况才考虑加 Protocol：要写单元测试注入 Mock、同一接口有多种实现、做依赖注入框架。  
> 初学者和大部分页面：**类就够了，别多写一层。**

---

## 5. ViewModel 里怎么用

```swift
@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = UserAPIService.shared

    func load(userId: Int) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                profile = try await api.fetchProfile(userId: userId)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
```

---

## 6. 两种响应解析方式

| 方法 | 何时用 | 后端 JSON 格式 |
|------|--------|----------------|
| `request(_:as:)` | 第三方 API、无包装 | 直接是对象或数组 |
| `requestWrapped(_:as:)` | 自家后端 | `{ "code": 0, "message": "ok", "data": {} }` |

Demo 使用 JSONPlaceholder（无包装）→ `request`  
业务接口 → `requestWrapped`

---

## 7. 插件说明

| 插件 | 作用 |
|------|------|
| `AuthPlugin` | 自动加 `Authorization: Bearer <token>` |
| `NetworkLoggerPlugin` | Debug 打印请求/响应 |

接口不需要 Token 时：

```swift
extension DemoTarget: AuthTargetType {
    var requiresAuth: Bool { false }
}
```

---

## 8. 错误处理

统一映射为项目已有的 `APIError`：

| 情况 | APIError |
|------|----------|
| HTTP 4xx/5xx | `.httpError(statusCode)` |
| JSON 解析失败 | `.decodingFailed` |
| 网络断开 | `.requestFailed` |
| 业务 code != 0 | `.businessError(code:message:)` |

ViewModel 里：

```swift
} catch {
    errorMessage = error.localizedDescription
}
```

---

## 9. 本项目的 Demo

- **入口**：工具 Tab → Moya 网络 Demo
- **模块目录**：`Features/DemoPage/NetworkDemo/`（API + Service + View 都在此模块内）
- **公共基建**：`Services/Networking/Moya/Core/`
- **接口**：JSONPlaceholder（公网测试 API，无需后端）

演示：GET 列表、GET 详情、POST 创建。

---

## 10. 新增模块 Checklist

- [ ] 在 `Features/XXXModule/` 下建 `API/XXXTarget.swift`
- [ ] 在同模块 `Models/` 新建请求/响应模型
- [ ] 在同模块 `Service/` 新建 `XXXAPIService.swift`（直接写类即可）
- [ ] ViewModel 注入 Service，用 `async throws` 调用
- [ ] 确认用 `request` 还是 `requestWrapped`
- [ ] 确认 `requiresAuth` 是否需要 Token

---

*Demo 路径：工具 Tab → Moya 网络 Demo*
