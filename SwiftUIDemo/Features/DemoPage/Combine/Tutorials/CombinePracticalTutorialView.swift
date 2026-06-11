//
//  CombinePracticalTutorialView.swift
//  SwiftUIDemo
//
//  综合实战：搜索防抖、表单验证、网络请求链
//

import Combine
import SwiftUI

// MARK: - 实战 1：搜索防抖 ViewModel

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [String] = []
    @Published private(set) var isSearching = false

    private let allItems = [
        "Swift", "SwiftUI", "Combine", "UIKit",
        "Core Data", "CloudKit", "WidgetKit", "MapKit"
    ]
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 完整的搜索防抖管道：
        // 输入 → debounce 等用户停手 → removeDuplicates 去重 → switchToLatest 取消旧请求 → 搜索
        $query
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] _ in
                self?.isSearching = true
            })
            .map { [weak self] text -> AnyPublisher<[String], Never> in
                guard let self else { return Just([]).eraseToAnyPublisher() }
                return self.simulateSearch(text: text)
            }
            .switchToLatest() // 关键：新搜索发出时，自动取消上一次未完成的搜索
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.results = items
                self?.isSearching = false
            }
            .store(in: &cancellables)
    }

    /// 模拟网络搜索（随机延迟 0.3~0.8 秒）
    private func simulateSearch(text: String) -> AnyPublisher<[String], Never> {
        guard !text.isEmpty else {
            return Just([]).eraseToAnyPublisher()
        }

        return Future<[String], Never> { [allItems] promise in
            let delay = Double.random(in: 0.3...0.8)
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                let matched = allItems.filter {
                    $0.localizedCaseInsensitiveContains(text)
                }
                promise(.success(matched))
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - 实战 2：表单验证 ViewModel

@MainActor
final class RegistrationViewModel: ObservableObject {
    @Published var email = ""
    @Published var age = ""
    @Published private(set) var emailError: String?
    @Published private(set) var ageError: String?
    @Published private(set) var isFormValid = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        // 邮箱验证管道
        $email
            .map { email -> String? in
                if email.isEmpty { return nil }
                let pattern = #"^[\w.-]+@[\w.-]+\.\w{2,}$"#
                return email.range(of: pattern, options: .regularExpression) != nil
                    ? nil : "邮箱格式不正确"
            }
            .assign(to: &$emailError)

        // 年龄验证管道
        $age
            .map { text -> String? in
                if text.isEmpty { return nil }
                guard let value = Int(text), (1...150).contains(value) else {
                    return "请输入 1~150 之间的整数"
                }
                return nil
            }
            .assign(to: &$ageError)

        // 组合判断：两个字段都有值且无错误
        Publishers.CombineLatest3($email, $age, Publishers.CombineLatest($emailError, $ageError))
            .map { email, age, errors in
                let (emailErr, ageErr) = errors
                return !email.isEmpty && !age.isEmpty && emailErr == nil && ageErr == nil
            }
            .assign(to: &$isFormValid)
    }
}

// MARK: - 实战 3：网络请求链 ViewModel

@MainActor
final class FetchPipelineViewModel: ObservableObject, TutorialLogging {
    @Published var logLines: [String] = []
    @Published private(set) var userDisplay = "（点击加载）"
    @Published private(set) var isLoading = false

    private var cancellables = Set<AnyCancellable>()

    enum APIError: Error, CustomStringConvertible {
        case notFound
        case decodeFailed
        var description: String {
            switch self {
            case .notFound: return "用户不存在"
            case .decodeFailed: return "数据解析失败"
            }
        }
    }

    struct UserDTO: Decodable {
        let id: Int
        let name: String
        let email: String
    }

    /// 模拟三步网络管道：获取 ID → 获取详情 → 格式化展示
    func loadUser() {
        resetLogs()
        isLoading = true
        userDisplay = "加载中…"
        appendLog("🚀 开始网络请求链")

        // 第一步：获取用户 ID
        fetchUserID()
            .handleEvents(receiveOutput: { [weak self] id in
                self?.appendLog("① 获取到 userID: \(id)")
            })
            // 第二步：用 ID 获取详情（flatMap 把上一步输出转成新的 Publisher）
            .flatMap { [weak self] userID -> AnyPublisher<UserDTO, APIError> in
                guard let self else {
                    return Fail(error: APIError.notFound).eraseToAnyPublisher()
                }
                return self.fetchUserDetail(id: userID)
            }
            .handleEvents(receiveOutput: { [weak self] user in
                self?.appendLog("② 获取到详情: \(user.name)")
            })
            // 第三步：格式化
            .map { user in
                "\(user.name) <\(user.email)>"
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.appendLog("❌ 失败: \(error)")
                    self?.userDisplay = "加载失败"
                }
            } receiveValue: { [weak self] display in
                self?.appendLog("③ 展示: \(display)")
                self?.userDisplay = display
            }
            .store(in: &cancellables)
    }

    private func fetchUserID() -> AnyPublisher<Int, APIError> {
        Future { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                promise(.success(42))
            }
        }
        .eraseToAnyPublisher()
    }

    private func fetchUserDetail(id: Int) -> AnyPublisher<UserDTO, APIError> {
        Future { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                let json = """
                {"id": \(id), "name": "张三", "email": "zhangsan@example.com"}
                """.data(using: .utf8)!
                if let user = try? JSONDecoder().decode(UserDTO.self, from: json) {
                    promise(.success(user))
                } else {
                    promise(.failure(.decodeFailed))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - View

struct CombinePracticalTutorialView: View {
    @StateObject private var searchVM = SearchViewModel()
    @StateObject private var registrationVM = RegistrationViewModel()
    @StateObject private var fetchVM = FetchPipelineViewModel()

    var body: some View {
        CombineTutorialPage(title: "综合案例") {
            TutorialConceptCard(
                title: "三个真实场景",
                content: """
                ① 搜索防抖 + switchToLatest：取消过期请求
                ② 多字段表单验证：combineLatest + map
                ③ 网络请求链：flatMap 串联多步 API
                """
            )

            // 案例 1
            practicalSection(title: "案例 1 · 搜索防抖", icon: "magnifyingglass") {
                TutorialCodeBlock(
                    title: "核心管道",
                    code: """
                    $query
                        .debounce(for: .milliseconds(400), …)
                        .removeDuplicates()
                        .map { simulateSearch($0) }
                        .switchToLatest()  // 取消旧搜索
                        .assign(to: &$results)
                    """
                )

                HStack {
                    TextField("搜索框架名称…", text: $searchVM.query)
                        .textFieldStyle(.roundedBorder)
                    if searchVM.isSearching {
                        ProgressView()
                    }
                }

                if searchVM.results.isEmpty && !searchVM.query.isEmpty && !searchVM.isSearching {
                    Text("无匹配结果")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                } else {
                    ForEach(searchVM.results, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle")
                            .font(.subheadline)
                    }
                }
            }

            // 案例 2
            practicalSection(title: "案例 2 · 表单验证", icon: "doc.text.fill") {
                TutorialCodeBlock(
                    title: "核心管道",
                    code: """
                    $email.map { validateEmail($0) }
                        .assign(to: &$emailError)

                    Publishers.CombineLatest3($email, $age, …)
                        .map { … }
                        .assign(to: &$isFormValid)
                    """
                )

                VStack(alignment: .leading, spacing: 8) {
                    TextField("邮箱", text: $registrationVM.email)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    if let error = registrationVM.emailError {
                        Text(error).font(.caption).foregroundStyle(AppColors.error)
                    }

                    TextField("年龄", text: $registrationVM.age)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                    if let error = registrationVM.ageError {
                        Text(error).font(.caption).foregroundStyle(AppColors.error)
                    }

                    Button("注册") {}
                        .buttonStyle(.borderedProminent)
                        .disabled(!registrationVM.isFormValid)
                }
            }

            // 案例 3
            practicalSection(title: "案例 3 · 网络请求链", icon: "network") {
                TutorialCodeBlock(
                    title: "核心管道",
                    code: """
                    fetchUserID()
                        .flatMap { id in fetchUserDetail(id: id) }
                        .map { user in format(user) }
                        .receive(on: DispatchQueue.main)
                        .sink { … }
                    """
                )

                Text(fetchVM.userDisplay)
                    .font(.title3)
                    .foregroundStyle(AppColors.primary)

                Button {
                    fetchVM.loadUser()
                } label: {
                    Label("加载用户", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(fetchVM.isLoading)

                TutorialLogPanel(title: "请求日志", logs: fetchVM.logLines)
            }
        }
    }

    private func practicalSection<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)

            content()
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
