# Combine 使用文档

> 面向新手的 Combine 学习指南：先懂概念，再看用法，最后看代码和 SwiftUI 实战。
> 建议按章节顺序阅读，不要跳节。

---

## 目录

1. [Combine 是什么？解决什么问题？](#1-combine-是什么解决什么问题)
2. [四个核心概念（含 Output、Failure、Never、Publisher 家族）](#2-四个核心概念)
3. [最小入门 + 一次性 vs 持续发送](#3-最小入门--一次性-vs-持续发送)
4. [订阅的完整写法（sink）](#4-订阅的完整写法sink)
5. [assign 用法全解（sink 的另一选择）](#5-assign-用法全解sink-的另一选择)
6. [`.publisher` 不限数字：所有类型都能用](#6-publisher-不限数字所有类型都能用)
7. [必须记住的两条规则](#7-必须记住的两条规则)
8. [常用发布者（Publisher）](#8-常用发布者publisher)
9. [Subject：可以手动发值的 Publisher](#9-subject可以手动发值的-publisher)
10. [操作符（Operator）：管道的核心](#10-操作符operator管道的核心)
11. [组合多个数据流](#11-组合多个数据流)
12. [错误处理](#12-错误处理)
13. [线程切换：后台干活，主线程更新 UI](#13-线程切换后台干活主线程更新-ui)
14. [SwiftUI 集成：View 到底是不是订阅者？](#14-swiftui-集成view-到底是不是订阅者)
15. [SwiftUI 状态管理完全指南](#15-swiftui-状态管理完全指南)
16. [SwiftUI 实战场景大全](#16-swiftui-实战场景大全)
17. [推荐学习路径](#17-推荐学习路径)

---

## 1. Combine 是什么？解决什么问题？

### 概念

**Combine** 是 Apple 官方的**响应式编程框架**（iOS 13+）。

你可以把它理解成一条**数据流水线**：

```
数据来源 → 中间处理 → 最终结果
(Publisher)  (Operator)  (Subscriber)
```

### 它解决什么问题？

日常开发中，有很多「会随时间变化」的事情：


| 场景           | 传统写法          | Combine 写法           |
| ------------ | ------------- | -------------------- |
| 用户输入搜索词      | 手动 `Timer` 防抖 | `debounce` 操作符       |
| 网络请求返回       | 回调嵌套          | Publisher 链式处理       |
| 多个输入决定按钮是否可点 | 每个输入都写 `if`   | `combineLatest` 组合   |
| 页面数据刷新       | 手动调 `reload`  | `@Published` 自动驱动 UI |


**一句话总结**：Combine 让你用「管道」的方式，把异步事件和数据变化组织起来，而不是写一堆散落的回调。

---

## 2. 四个核心概念

读代码之前，先记住这四个角色：

### ① Publisher（发布者）

- **作用**：数据的源头，负责「发出值」
- **类比**：水龙头，能源源不断出水
- **例子**：`Just(1)`、`@Published` 属性、`URLSession` 网络请求

```swift
// Publisher 协议（简化理解）
protocol Publisher {
    associatedtype Output    // 发出的值是什么类型
    associatedtype Failure: Error  // 失败时，错误是什么类型
}
```

每个 Publisher 都有**两个类型参数**，写作 `Publisher<Output, Failure>` 或具体类型如 `PassthroughSubject<String, Never>`。

---

### ①.1 Output 和 Failure 到底是什么？

用一句公式记住：

```
Publisher<Output, Failure>
           ↑        ↑
        发什么值   失败时错误类型
```

#### 例子 1：`PassthroughSubject<String, Never>()`

```swift
let subject = PassthroughSubject<String, Never>()
//                              ↑       ↑
//                           Output   Failure
```

| 泛型参数 | 这里是 | 含义 |
|----------|--------|------|
| `Output` | `String` | 每次 `.send()` 发出的是 `String` |
| `Failure` | `Never` | **这个流永远不会失败** |

订阅时，`receiveValue` 收到的是 `String`；`receiveCompletion` **只会**收到 `.finished`，**不会**收到 `.failure`。

#### 例子 2：会失败的网络 Publisher

```swift
URLSession.shared.dataTaskPublisher(for: url)
// 等价于：Publisher<(Data, URLResponse), URLError>
//                    ↑ Output              ↑ Failure
```

网络可能断、超时、404，所以 `Failure` 是 `URLError`，不是 `Never`。

```swift
.sink(
    receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("成功结束")
        case .failure(let error):   // error 类型是 URLError
            print("失败了: \(error)")
        }
    },
    receiveValue: { data, response in
        // data 类型是 (Data, URLResponse)
    }
)
```

#### 例子 3：自定义错误类型

```swift
enum LoginError: Error {
    case wrongPassword
    case accountLocked
}

// Fail 的 Output 是 String，Failure 是 LoginError
Fail<String, LoginError>(error: .wrongPassword)
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                // error 是 LoginError，不是 Never
                print(error)
            }
        },
        receiveValue: { _ in }
    )
```

---

### ①.2 `Never` 是什么意思？

`Never` 是 Swift 内置的**特殊类型**，意思是：**「这种情况永远不可能发生」**。

在 Combine 里：

```swift
PassthroughSubject<String, Never>
//                         ↑
//              Failure = Never → 表示「这个 Publisher 不会失败」
```

**实际影响**：

1. `receiveCompletion` 里**只有** `.finished`，写 `.failure` 分支也永远不会执行
2. 编译器知道不会失败，有些 API 可以简化（比如 `assign` 要求 `Failure == Never`）
3. 常见 `Never` 场景：`Subject`、 `@Published` 的 `$property`、`Just`、`数组.publisher`

```swift
// Failure 是 Never 时，completion 只有 finished
subject.send(completion: .finished)   // ✅ 可以手动结束
subject.send(completion: .failure(...)) // ❌ 编译错误！Never 不能有 failure
```

**对比**：

| Failure 类型 | 会不会失败 | 典型场景 |
|-------------|-----------|----------|
| `Never` | 不会 | Subject、@Published、Just、Timer |
| `URLError` | 会 | 网络请求 |
| `DecodingError` | 会 | JSON 解析 |
| 自定义 `Error` | 会 | 业务逻辑错误 |

---

### ①.3 PassthroughSubject 是 Publisher 吗？

**是的。** `PassthroughSubject` 不仅是一种 Publisher，还是一种 **Subject**（可以手动 `.send()` 的 Publisher）。

继承关系（简化）：

```
Publisher（协议）
    ↑
Subject（协议，多了 send() 方法）
    ↑
PassthroughSubject（具体类）
CurrentValueSubject（具体类）
```

所以你可以把 `PassthroughSubject` 当 Publisher 一样用：`.map`、`.filter`、`.sink`、`.assign` 都能接在后面。

```swift
let subject = PassthroughSubject<Int, Never>()

subject
    .filter { $0 > 0 }      // ✅ 操作符能用，因为它就是 Publisher
    .map { "数字: \($0)" }
    .sink { print($0) }
    .store(in: &cancellables)

subject.send(5)   // 输出: 数字: 5
```

---

### ①.4 Publisher 有哪些？（家族全景图）

Publisher 是一个**协议**，不是某一个类。  
实际开发中你接触的是「遵循了 Publisher 协议」的各种类型：

#### 第一类：内置具体 Publisher（拿来就用）

| 类型 | 写法示例 | Output | Failure | 发完就结束？ |
|------|----------|--------|---------|-------------|
| `Just` | `Just("Hi")` | `String` | `Never` | ✅ 发 1 个就结束 |
| `Empty` | `Empty(completeImmediately: true)` | 你指定的类型 | `Never` | ✅ 0 个值就结束 |
| `Fail` | `Fail(error: .network)` | 你指定的类型 | 你的 Error | ✅ 立刻失败 |
| `Future` | `Future { promise in … }` | 你指定的类型 | 你的 Error | ✅ 发 1 次就结束 |
| `Deferred` | `Deferred { Just(1) }` | 取决于内部 | 取决于内部 | 取决于内部 |
| `Sequence` | `[1,2,3].publisher` | 元素类型 | `Never` | ✅ 发完序列就结束 |

#### 第二类：Subject（可手动 `.send()` 的 Publisher）

| 类型 | 特点 | Failure 通常是 |
|------|------|---------------|
| `PassthroughSubject` | 不保存当前值，只转发订阅后的新值 | `Never` |
| `CurrentValueSubject` | 保存最新值，新订阅者立刻收到当前值 | `Never` |

#### 第三类：系统提供的 Publisher

| 来源 | 写法 | Failure |
|------|------|---------|
| 网络 | `URLSession.shared.dataTaskPublisher(for: url)` | `URLError` |
| 定时器 | `Timer.publish(every: 1, on: .main, in: .common)` | `Never` |
| 通知 | `NotificationCenter.default.publisher(for: name)` | `Never` |
| `@Published` | `$count`（属性前的 `$`） | `Never` |

#### 第四类：操作符返回的 Publisher（管道中间产物）

你对任何 Publisher 调用 `.map`、`.filter`、`.debounce` 等，**返回的也是 Publisher**：

```swift
[1, 2, 3].publisher   // Publishers.Sequence<[Int], Never>
    .map { $0 * 2 }    // Publishers.Map<..., Int, Never>  ← 还是 Publisher
    .filter { $0 > 2 } // Publishers.Filter<..., Int, Never>  ← 还是
    .sink { … }
```

#### 第五类：类型擦除 `AnyPublisher`（隐藏具体类型）

函数返回值太长时，用 `AnyPublisher` 包装：

```swift
func fetchUser() -> AnyPublisher<User, APIError> {
    return URLSession.shared.dataTaskPublisher(for: url)
        .map(\.data)
        .decode(type: User.self, decoder: JSONDecoder())
        .mapError { … as APIError }
        .eraseToAnyPublisher()  // 擦掉具体类型，只留 Output + Failure
}
```

#### 一张图总结

```
Publisher（协议）
├── 内置：Just / Empty / Fail / Future / Deferred / Sequence
├── Subject：PassthroughSubject / CurrentValueSubject
├── 系统：URLSession / Timer / NotificationCenter / @Published
├── 操作符产物：Map / Filter / Debounce / CombineLatest / …
└── 类型擦除：AnyPublisher
```

---

### ② Subscriber（订阅者）

- **作用**：接收 Publisher 发出的值
- **类比**：水桶，接水
- **例子**：`.sink { }`、`.assign(to: &$property)`、SwiftUI 的 `@ObservedObject`、`.onReceive`

### ③ Subscription（订阅关系）

- **作用**：连接 Publisher 和 Subscriber 的「合同」
- **关键**：可以 `.cancel()` 取消订阅
- **你不需要手写**，框架自动管理

### ④ Operator（操作符）

- **作用**：站在管道中间，对数据做变换、过滤、合并
- **类比**：净水器、过滤器
- **例子**：`.map`、`.filter`、`.debounce`、`.combineLatest`

### 关系图

```
Publisher  →  Operator  →  Operator  →  Subscriber
  发值         变换          过滤         接收
```

---

## 3. 最小入门 + 一次性 vs 持续发送

这一章解决新手最常困惑的问题：**发完一个值之后，还想继续发怎么办？**

---

### 3.1 先搞懂：Publisher 分两大类

| 类型 | 特征 | 典型代表 | 什么时候用 |
|------|------|----------|------------|
| **有限（Finite）** | 发完固定个数的值就 `.finished` 结束 | `Just`、`[1,2,3].publisher`、网络请求 | 一次性任务：加载数据、解析数组 |
| **无限（Infinite）** | 可以一直发，不会自动结束 | `Subject`、`Timer`、`@Published`（`$count`） | 持续事件：用户输入、定时器、属性变化 |

**关键理解**：

- `Just("Hello")` 属于**有限**：发 1 个值 → 结束，**你没法让它再发第 2 个值**
- 如果你想「过一会儿再发」「用户点击后再发」「属性变了再发」→ 必须用**能持续发送**的 Publisher

---

### 3.2 有限 Publisher 入门：Just（发一个就结束）

#### 用法说明

1. 创建一个 Publisher
2. 用 `.sink` 订阅它
3. 把返回的 `AnyCancellable` 存起来（**非常重要**）

#### 代码

```swift
import Combine

var cancellables = Set<AnyCancellable>()

// Just：立刻发出 "Hello"，然后流结束（.finished）
let publisher = Just("Hello")

publisher
    .sink(
        receiveCompletion: { completion in
            // Just 正常结束时走这里
            if case .finished = completion {
                print("流结束了，不会再有值了")
            }
        },
        receiveValue: { value in
            print(value)  // 输出: Hello
        }
    )
    .store(in: &cancellables)

// ⚠️ 下面这行没有任何作用！Just 已经结束了，不能再 send
// publisher.send("World")  // ❌ 编译错误：Just 没有 send 方法
```

#### 详细说明

| 代码 | 含义 |
|------|------|
| `Just("Hello")` | 最简单的有限 Publisher，发出 1 个值就结束 |
| `receiveValue` | 每收到一个值执行一次（Just 只调 1 次） |
| `receiveCompletion` | 流结束时执行（Just 会走 `.finished`） |
| `.store(in: &cancellables)` | **必须保存**，否则订阅立刻被取消 |

> ⚠️ **新手最容易犯的错**：不写 `.store(in: &cancellables)`，导致订阅刚建立就被取消，什么都不会发生。

---

### 3.3 有限 Publisher：数组依次发完（也不是只有数字！）

`[1, 2, 3].publisher` 会依次发出 3 个值，然后结束。  
**不只是 Int**，任何数组元素类型都可以（详见第 6 章）。

```swift
var cancellables = Set<AnyCancellable>()

["苹果", "香蕉", "橙子"].publisher
    .sink(
        receiveCompletion: { _ in print("水果发完了") },
        receiveValue: { fruit in print("收到: \(fruit)") }
    )
    .store(in: &cancellables)

// 输出:
// 收到: 苹果
// 收到: 香蕉
// 收到: 橙子
// 水果发完了
// → 结束后同样不能再发
```

---

### 3.4 核心问题：想继续发值，应该怎么写？

`Just` 和 `[].publisher` 都是**发完就结束**。  
如果你需要「后续再发」，用下面三种方式：

---

#### 方式 A：Subject — 你手动 `.send()`，想发几次发几次

```swift
var cancellables = Set<AnyCancellable>()

// PassthroughSubject：不会自动结束，除非你主动 complete
let subject = PassthroughSubject<String, Never>()

subject
    .sink(
        receiveCompletion: { _ in print("Subject 结束了") },
        receiveValue: { print("收到: \($0)") }
    )
    .store(in: &cancellables)

// 第 1 秒
subject.send("第一条消息")

// 第 2 秒（模拟用户又做了操作）
DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
    subject.send("第二条消息")   // ✅ 可以继续发！
}

// 第 3 秒
DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    subject.send("第三条消息")   // ✅ 还能发！
}

// 不再需要时，手动结束
DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
    subject.send(completion: .finished)  // 告诉订阅者：不会再发了
}
```

**适用场景**：按钮点击事件、把旧式回调桥接进 Combine、自定义事件总线。

---

#### 方式 B：Timer — 按时间间隔自动发

```swift
var cancellables = Set<AnyCancellable>()

// 每 1 秒发出当前时间，不会自动停
let timer = Timer.publish(every: 1.0, on: .main, in: .common)
    .autoconnect()  // 自动连接，开始计时

timer
    .sink { date in
        print("tick: \(date.formatted(date: .omitted, time: .standard))")
    }
    .store(in: &cancellables)

// 只想收 5 次然后停？加 prefix
Timer.publish(every: 1.0, on: .main, in: .common)
    .autoconnect()
    .prefix(5)  // 只取前 5 个值，然后自动 .finished
    .sink(
        receiveCompletion: { _ in print("定时器停止") },
        receiveValue: { print($0) }
    )
    .store(in: &cancellables)
```

**适用场景**：倒计时、轮询刷新、心跳检测。

---

#### 方式 C：@Published — 属性变了就自动发（SwiftUI 最常用）

```swift
class CounterViewModel: ObservableObject {
    @Published var count = 0   // 底层是 CurrentValueSubject
    private var cancellables = Set<AnyCancellable>()

    init() {
        // $count 是 Publisher，count 每次变化都会 emit 新值
        $count
            .sink { newValue in
                print("count 变成: \(newValue)")
            }
            .store(in: &cancellables)
    }

    func increment() {
        count += 1  // ← 这里赋值后，$count 自动发出新值
    }
}

// 使用:
let vm = CounterViewModel()
vm.increment()  // 输出: count 变成: 1
vm.increment()  // 输出: count 变成: 2
vm.increment()  // 输出: count 变成: 3
// → 只要 count 还在变，就会一直发
```

**适用场景**：页面状态驱动、表单输入、SwiftUI 数据绑定。

---

### 3.5 一张表总结：我该用哪个？

| 你的需求 | 用什么 | 怎么继续发 |
|----------|--------|------------|
| 发一个固定值 | `Just(值)` | 不能继续发，已经结束 |
| 把数组/序列每个元素发一遍 | `[].publisher` | 不能继续发，发完就结束 |
| 用户操作后再发、想发几次发几次 | `PassthroughSubject` | `.send(新值)` |
| 要有当前值，新订阅者能立刻拿到 | `CurrentValueSubject` 或 `@Published` | `.send(新值)` 或 `属性 = 新值` |
| 按时间间隔自动发 | `Timer.publish` | 自动发，或用 `prefix` 限制次数 |
| 网络请求结果 | `URLSession.dataTaskPublisher` | 一次性，返回后结束 |

---

## 4. 订阅的完整写法（sink）

### 用法说明

`sink` 有两个闭包：

1. `receiveValue`：每收到一个值
2. `receiveCompletion`：流结束（成功或失败）

### 代码

```swift
import Combine

var cancellables = Set<AnyCancellable>()

[1, 2, 3].publisher
    .sink(
        receiveCompletion: { completion in
            // 流结束了
            switch completion {
            case .finished:
                print("正常结束")
            case .failure(let error):
                print("出错了: \(error)")
            }
        },
        receiveValue: { number in
            // 每收到一个数字
            print("收到: \(number)")
        }
    )
    .store(in: &cancellables)

// 输出:
// 收到: 1
// 收到: 2
// 收到: 3
// 正常结束
```

### 详细说明

- `[1, 2, 3].publisher`：把数组变成 Publisher，依次发出 1、2、3
- `receiveValue` 会被调用 3 次
- 全部发完后，`receiveCompletion` 收到 `.finished`
- 如果 Publisher 可能失败，`Failure` 类型不是 `Never`，就会在 `.failure(error)` 分支处理
- `[1, 2, 3].publisher` 里的元素**不限于 Int**，String、Struct、Enum 都可以（见第 6 章）

---

## 5. assign 用法全解（sink 的另一选择）

很多人只学了 `sink`，但 **`assign` 同样重要**，尤其在 SwiftUI 的 ViewModel 里。

### 5.1 sink 和 assign 是什么关系？

两者都是**订阅者（Subscriber）**，都返回 `AnyCancellable`，都要 `store`。

| | `sink` | `assign` |
|--|--------|----------|
| **做什么** | 收到值后执行闭包（任意逻辑） | 收到值后**自动赋值给属性** |
| **适合** | 打日志、弹窗、导航、复杂副作用 | 把一个 Publisher 的值绑定到另一个属性 |
| **能处理 completion 吗** | ✅ 能（成功/失败） | ❌ 不能（只关心值） |
| **SwiftUI 典型用法** | 网络请求完成后改 `@Published` | `$a.map{}.assign(to: &$b)` |

**一句话**：

- 需要**干一件事**（包括处理错误）→ 用 `sink`
- 需要**把 A 的变化同步到 B** → 用 `assign`

---

### 5.2 assign 写法一：`assign(to: &$property)` — iOS 14+，最推荐

直接把 Publisher 的输出写到 `@Published` 属性上，**自动管理内存**，不需要 `[weak self]`。

```swift
class FormViewModel: ObservableObject {
    @Published var email = ""
    @Published var isEmailValid = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        // 每当 email 变化 → 计算是否合法 → 自动写入 isEmailValid
        $email
            .map { $0.contains("@") && $0.contains(".") }
            .assign(to: &$isEmailValid)
        // 等价于：
        // $email.map { ... }.sink { [weak self] valid in
        //     self?.isEmailValid = valid
        // }.store(in: &cancellables)
    }
}
```

**详细说明**：

- `$email` 是 `@Published` 自动生成的 `Publisher<String, Never>`
- `.assign(to: &$isEmailValid)` 中的 `&` 表示「绑定到这个属性的发布通道」
- 只要 ViewModel 还活着，绑定就一直有效

---

### 5.3 assign 写法二：`assign(to:on:)` — iOS 13，KVO 方式

通过 KeyPath 赋值，目标属性**不能是 `@Published`**（早期限制），且要注意循环引用。

```swift
class PersonViewModel: ObservableObject {
    // 普通属性（不能用 @Published 配合 assign(to:on:)）
    @objc dynamic var displayName: String = ""

    private var cancellables = Set<AnyCancellable>()

    func bind(from namePublisher: AnyPublisher<String, Never>) {
        namePublisher
            .assign(to: \.displayName, on: self)
            .store(in: &cancellables)
    }
}
```

> 现在 SwiftUI 项目一般都部署 iOS 14+，**优先用 `assign(to: &$property)`**，更简洁安全。

---

### 5.4 sink vs assign 对照示例（同一个需求两种写法）

**需求**：`$celsius` 变化时，自动更新 `fahrenheit`。

```swift
class TemperatureViewModel: ObservableObject {
    @Published var celsius: Double = 25
    @Published var fahrenheit: Double = 77
    private var cancellables = Set<AnyCancellable>()

    init() {
        // ✅ 写法 A：assign（推荐，绑定属性）
        $celsius
            .map { $0 * 9 / 5 + 32 }
            .assign(to: &$fahrenheit)

        // ✅ 写法 B：sink（也可以，但要 store + weak self）
        // $celsius
        //     .map { $0 * 9 / 5 + 32 }
        //     .sink { [weak self] f in
        //         self?.fahrenheit = f
        //     }
        //     .store(in: &cancellables)
    }
}
```

**网络请求只能用 sink**（因为要处理 completion 里的失败）：

```swift
func loadUser() {
    api.fetchUser()
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                // assign 做不到这里！
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            },
            receiveValue: { [weak self] user in
                self?.user = user
            }
        )
        .store(in: &cancellables)
}
```

---

### 5.5 什么时候用 sink，什么时候用 assign？

| 场景 | 用哪个 | 原因 |
|------|--------|------|
| 属性 A → 属性 B 同步 | `assign(to: &)` | 纯赋值，无额外逻辑 |
| 网络请求 | `sink` | 要处理 `.failure` |
| 收到值后弹 Toast | `sink` | 副作用，不是赋值 |
| 搜索后更新 results 数组 | `sink` | 通常伴随 `isLoading` 等多个状态变化 |
| 表单验证写回 `isValid` | `assign(to: &)` | 典型 Publisher → Bool 属性 |

---

## 6. `.publisher` 不限数字：所有类型都能用

### 6.1 核心规则

`.publisher` 是 `Sequence` 协议上的扩展：

```swift
// 伪代码：任何遵循 Sequence 的类型都能 .publisher
extension Sequence {
    var publisher: Publishers.Sequence<Self, Never> { ... }
}
```

**所以：不是只有数字能用。** 只要你是「一组有序的元素」，都可以。

---

### 6.2 各种数据类型的示例

```swift
var cancellables = Set<AnyCancellable>()

// ✅ Int 数组
[1, 2, 3].publisher.sink { print($0) }.store(in: &cancellables)

// ✅ String 数组
["Swift", "Combine", "SwiftUI"].publisher
    .sink { print($0) }
    .store(in: &cancellables)

// ✅ 字符串的每个字符
"ABC".publisher
    .sink { print($0) }  // A, B, C
    .store(in: &cancellables)

// ✅ 字典的键（注意：字典本身无序，但 keys 可以转数组）
["name": "张三", "age": "20"].keys
    .publisher
    .sink { print($0) }
    .store(in: &cancellables)

// ✅ 自定义结构体
struct User: Codable { let name: String; let age: Int }

let users = [User(name: "张三", age: 20), User(name: "李四", age: 25)]
users.publisher
    .sink { user in
        print("\(user.name), \(user.age)岁")
    }
    .store(in: &cancellables)

// ✅ 枚举
enum Status: String { case loading, success, failed }
[Status.loading, .success].publisher
    .sink { print($0.rawValue) }
    .store(in: &cancellables)

// ✅ 范围 Range
(1...5).publisher
    .sink { print($0) }  // 1, 2, 3, 4, 5
    .store(in: &cancellables)

// ✅ Optional 的 Publisher（不是 Sequence，但是内置的）
Just<Int?>(42).publisher  // 也可以 Just(42)
    .compactMap { $0 }     // 去掉 nil
    .sink { print($0) }
    .store(in: &cancellables)
```

---

### 6.3 发完之后还能继续发吗？

**不能。** `[].publisher` 是有限 Publisher：

```swift
[1, 2, 3].publisher
// 发出 1 → 2 → 3 → .finished
// 结束后流就关了，不能再追加 4

// 如果想「先发数组里的，后面再手动追加」：
let subject = PassthroughSubject<Int, Never>()

[1, 2, 3].publisher
    .sink { subject.send($0) }  // 先转发数组里的值
    .store(in: &cancellables)

subject
    .sink { print($0) }
    .store(in: &cancellables)

subject.send(4)  // ✅ 后续还能继续发
subject.send(5)
```

---

### 6.4 Output 类型是怎么确定的？

Publisher 的 `Output` 类型 = 序列的元素类型：

| 写法 | Output 类型 |
|------|-------------|
| `[1, 2, 3].publisher` | `Int` |
| `["a", "b"].publisher` | `String` |
| `users.publisher`（`[User]`） | `User` |
| `$email`（`@Published var email: String`） | `String` |
| `PassthroughSubject<Int, Never>` | `Int` |

订阅时 `receiveValue` 的参数类型就是 Output：

```swift
users.publisher
    .sink { (user: User) in   // 类型是 User，不是 Int
        print(user.name)
    }
    .store(in: &cancellables)
```

---

## 7. 必须记住的两条规则

### 规则 1：订阅必须保存

```swift
// ❌ 错误：cancellable 是局部变量，函数结束就释放了
func load() {
    api.fetch().sink { print($0) }  // 订阅立刻取消，什么都不打印
}

// ✅ 正确：存到属性里
class ViewModel {
    private var cancellables = Set<AnyCancellable>()

    func load() {
        api.fetch()
            .sink { print($0) }
            .store(in: &cancellables)
    }
}
```

### 规则 2：更新 UI 必须在主线程

```swift
// ❌ 错误：网络回调在后台线程，直接改 UI 可能崩溃
URLSession.shared.dataTaskPublisher(for: url)
    .sink { data in
        self.title = "加载完成"  // 可能在后台线程！
    }

// ✅ 正确：切回主线程再更新
URLSession.shared.dataTaskPublisher(for: url)
    .receive(on: DispatchQueue.main)  // 切到主线程
    .sink { data in
        self.title = "加载完成"  // 安全
    }
    .store(in: &cancellables)
```

---

## 8. 常用发布者（Publisher）

### 概念

Publisher 是数据源头。下面是开发中最常见的几种。

---

### 8.1 Just — 发一个值就结束

**用法**：传递单个固定值。

```swift
Just("Swift")
    .sink { print($0) }  // 输出: Swift
    .store(in: &cancellables)
```

---

### 8.2 数组 / 序列的 publisher

**用法**：依次发出序列中的每个元素，**发完就结束**（不能继续追加）。

> 不限 Int，String、Struct、Enum 等任意元素类型都可以，详见 **第 6 章**。

```swift
// Int 数组
[10, 20, 30].publisher
    .sink { print($0) }  // 依次输出 10, 20, 30
    .store(in: &cancellables)

// String 数组一样可以
["北京", "上海", "深圳"].publisher
    .sink { print($0) }
    .store(in: &cancellables)

// 自定义模型一样可以
struct Book { let title: String }
[Book(title: "Swift"), Book(title: "Combine")].publisher
    .sink { print($0.title) }
    .store(in: &cancellables)
```

---

### 8.3 Empty — 不发值，直接结束

**用法**：表示「没有数据但流程正常结束」。

```swift
Empty<String, Never>()
    .sink(
        receiveCompletion: { _ in print("结束了，但没收到任何值") },
        receiveValue: { _ in }
    )
    .store(in: &cancellables)
```

---

### 8.4 Fail — 不发值，直接失败

**用法**：表示「立刻出错」。

```swift
enum MyError: Error { case network }

Fail<String, MyError>(error: .network)
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("失败: \(error)")
            }
        },
        receiveValue: { _ in }
    )
    .store(in: &cancellables)
```

---

### 8.5 Future — 包装一次性异步任务

**用法**：把「回调式异步」转成 Publisher。类似 `async/await` 出现之前的常见写法。

```swift
enum APIError: Error { case failed }

let future = Future<String, APIError> { promise in
    // promise 只能调用一次：成功 或 失败
    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
        promise(.success("用户数据"))
        // 或者: promise(.failure(.failed))
    }
}

future
    .receive(on: DispatchQueue.main)
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { data in print(data) }
    )
    .store(in: &cancellables)
```

**详细说明**：

- `promise(.success(value))` = 成功，发出值，然后结束
- `promise(.failure(error))` = 失败，走 completion 的 `.failure` 分支

---

### 8.6 URLSession — 网络请求（实战最常用）

```swift
let url = URL(string: "https://api.example.com/user")!

URLSession.shared.dataTaskPublisher(for: url)
    .map(\.data)                              // 取出 Data
    .decode(type: User.self, decoder: JSONDecoder())  // 解析 JSON
    .receive(on: DispatchQueue.main)          // 切主线程
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("请求失败: \(error)")
            }
        },
        receiveValue: { user in
            print("用户名: \(user.name)")
        }
    )
    .store(in: &cancellables)
```

---

## 9. Subject：可以手动发值的 Publisher

### 概念

普通 Publisher（如 `Just`）的值是固定的。  
**Subject** 是一种特殊的 Publisher，你可以随时 `.send(值)` 进去。

两种 Subject：


| 类型                    | 特点                | 类比      |
| --------------------- | ----------------- | ------- |
| `PassthroughSubject`  | 不保存状态，只转发订阅后的新值   | 广播电台    |
| `CurrentValueSubject` | 保存最新值，新订阅者立刻收到当前值 | 带初始值的盒子 |


---

### 9.1 PassthroughSubject

```swift
let subject = PassthroughSubject<String, Never>()

subject
    .sink { print("收到: \($0)") }
    .store(in: &cancellables)

subject.send("第一条")  // 输出: 收到: 第一条
subject.send("第二条")  // 输出: 收到: 第二条
```

---

### 9.2 CurrentValueSubject

```swift
let score = CurrentValueSubject<Int, Never>(0)  // 初始值 0

score
    .sink { print("分数: \($0)") }
    .store(in: &cancellables)
// 立刻输出: 分数: 0（订阅时收到当前值）

score.send(10)  // 输出: 分数: 10
score.send(20)  // 输出: 分数: 20

print(score.value)  // 直接读取当前值: 20
```

---

### 9.3 实战：把旧式回调桥接进 Combine

很多老 API 用闭包回调，可以用 Subject 接进来：

```swift
// 假设有个旧 SDK，用闭包通知
class OldSDK {
    var onResult: ((String) -> Void)?
    func fetch() { onResult?("数据") }
}

// 用 Subject 桥接
let bridge = PassthroughSubject<String, Never>()
let sdk = OldSDK()

sdk.onResult = { value in
    bridge.send(value)  // 回调 → Combine 管道
}

bridge
    .sink { print("Combine 收到: \($0)") }
    .store(in: &cancellables)

sdk.fetch()  // 输出: Combine 收到: 数据
```

---

## 10. 操作符（Operator）：管道的核心

### 概念

操作符是 Publisher 的扩展方法，**输入一个 Publisher，返回一个新的 Publisher**。

可以串联：

```swift
publisher
    .filter { ... }
    .map { ... }
    .debounce { ... }
    .sink { ... }
```

---

### 10.1 map — 变换每个值

**用法**：把每个值映射成另一个值（类似数组的 `map`）。

```swift
[1, 2, 3].publisher
    .map { "第\($0)个" }
    .sink { print($0) }
    .store(in: &cancellables)

// 输出:
// 第1个
// 第2个
// 第3个
```

---

### 10.2 filter — 过滤

**用法**：只保留满足条件的值。

```swift
(1...10).publisher
    .filter { $0 % 2 == 0 }  // 只留偶数
    .sink { print($0) }
    .store(in: &cancellables)

// 输出: 2, 4, 6, 8, 10
```

---

### 10.3 compactMap — 转换并丢弃失败

**用法**：转换值，转换失败（返回 nil）的自动丢弃。

```swift
["10", "abc", "20"].publisher
    .compactMap { Int($0) }  // "abc" 转不成 Int，丢弃
    .sink { print($0) }
    .store(in: &cancellables)

// 输出: 10, 20
```

---

### 10.4 removeDuplicates — 去掉连续重复

```swift
["A", "A", "B", "B", "C"].publisher
    .removeDuplicates()
    .sink { print($0) }
    .store(in: &cancellables)

// 输出: A, B, C
```

---

### 10.5 scan — 累加（每步都输出中间结果）

```swift
[1, 2, 3, 4].publisher
    .scan(0, +)  // 累加
    .sink { print($0) }
    .store(in: &cancellables)

// 输出: 1, 3, 6, 10（每步的累计值）
```

---

### 10.6 debounce — 防抖（搜索框必用）

**概念**：用户停下来一段时间后才触发。  
**场景**：搜索框输入，不要每个字都请求接口。

```swift
let searchInput = PassthroughSubject<String, Never>()

searchInput
    .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
    .removeDuplicates()
    .sink { keyword in
        print("真正去搜索: \(keyword)")
    }
    .store(in: &cancellables)

searchInput.send("S")
searchInput.send("Sw")
searchInput.send("Swi")
searchInput.send("Swift")
// 用户停止输入 0.5 秒后，只输出一次: 真正去搜索: Swift
```

---

### 10.7 throttle — 节流（按钮连点）

**概念**：固定时间窗口内只取第一个或最后一个。  
**场景**：防止按钮被疯狂点击。

```swift
buttonTapSubject
    .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: false)
    .sink { _ in
        print("执行提交")
    }
    .store(in: &cancellables)
```

---

### 10.8 flatMap — 把一个值变成新的 Publisher

**场景**：先拿到用户 ID，再用 ID 请求详情（多步网络请求）。

```swift
fetchUserID()                    // 发出 ID: 42
    .flatMap { id in
        fetchUserDetail(id: id)  // ID → 新的 Publisher
    }
    .sink { user in
        print(user.name)
    }
    .store(in: &cancellables)
```

---

### 10.9 switchToLatest — 取消过期的请求

**场景**：搜索时，上一次请求还没回来，用户又输入了新词。应该丢弃旧请求。

```swift
$searchText
    .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
    .map { text in searchAPI(text) }  // 返回 Publisher
    .switchToLatest()                  // 新搜索来了，取消旧的
    .sink { results in
        self.items = results
    }
    .store(in: &cancellables)
```

---

## 11. 组合多个数据流

### 11.1 combineLatest — 任一方变化，发出最新组合

**场景**：用户名 + 密码 → 决定登录按钮是否可点。

```swift
Publishers.CombineLatest($username, $password)
    .map { user, pass in
        user.count >= 3 && pass.count >= 6
    }
    .sink { canLogin in
        self.isLoginEnabled = canLogin
    }
    .store(in: &cancellables)
```

**说明**：

- `$username` 是 `@Published` 自动生成的 Publisher
- 用户名或密码任一变化，都会重新计算

---

### 11.2 merge — 合并多个同类型流

**场景**：多个来源的事件，统一处理。

```swift
notificationA.merge(with: notificationB)
    .sink { event in
        print("收到事件: \(event)")
    }
    .store(in: &cancellables)
```

---

### 11.3 zip — 一对一配对

**场景**：两个数组按位置配对。

```swift
let names = ["张三", "李四"].publisher
let scores = [90, 85].publisher

names.zip(scores)
    .sink { name, score in
        print("\(name): \(score)分")
    }
    .store(in: &cancellables)

// 输出:
// 张三: 90分
// 李四: 85分
```

---

## 12. 错误处理

### 概念

Publisher 都有 `Failure` 类型。`Never` 表示不会失败。

### 12.1 catch — 失败后给兜底数据

```swift
fetchData()
    .catch { error -> Just<String> in
        print("出错了: \(error)，用缓存")
        return Just("缓存数据")
    }
    .sink { data in print(data) }
    .store(in: &cancellables)
```

### 12.2 retry — 自动重试

```swift
fetchData()
    .retry(3)  // 失败后最多重试 3 次
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { data in print(data) }
    )
    .store(in: &cancellables)
```

### 12.3 replaceError — 失败变成功

```swift
fetchData()
    .replaceError(with: "默认数据")
    .sink { data in print(data) }  // 一定不会走 failure
    .store(in: &cancellables)
```

### 12.4 mapError — 转换错误类型

```swift
enum NetworkError: Error { case timeout }
struct AppError: Error { let message: String }

fetchData()
    .mapError { networkError in
        AppError(message: "请检查网络: \(networkError)")
    }
    .sink(
        receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print(error.message)
            }
        },
        receiveValue: { _ in }
    )
    .store(in: &cancellables)
```

---

## 13. 线程切换：后台干活，主线程更新 UI

### 概念


| 操作符              | 作用          | 放哪里         |
| ---------------- | ----------- | ----------- |
| `subscribe(on:)` | 指定上游在哪个线程执行 | 管道靠前        |
| `receive(on:)`   | 指定下游在哪个线程接收 | 管道靠后，UI 更新前 |


### 口诀

> **干活在后台，展示在主线程**

### 标准网络请求模板

```swift
URLSession.shared.dataTaskPublisher(for: url)
    .subscribe(on: DispatchQueue.global())   // 网络在后台
    .map { /* 解析 JSON */ }
    .receive(on: DispatchQueue.main)         // 结果回主线程
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { [weak self] user in
            self?.user = user  // 安全更新 UI
        }
    )
    .store(in: &cancellables)
```

---

## 14. SwiftUI 集成：View 到底是不是订阅者？

### 14.0 先回答你的疑问：SwiftUI 的 View 是订阅者吗？

**严格说**：`View` 结构体本身**不直接**实现 Combine 的 `Subscriber` 协议。  
**但实际上**：SwiftUI 的 View **一直在订阅数据变化**，只是通过属性包装器帮你自动完成了。

可以这样理解：

```
Publisher（数据源）
    ↓
属性包装器（中间层，帮你订阅）
    ↓
View（根据新数据重新计算 body，重新渲染）
```

| SwiftUI 写法 | 它订阅了什么 | 本质 |
|-------------|-------------|------|
| `@StateObject var vm` | `vm.objectWillChange`（内部 Publisher） | View 订阅 ViewModel 的变化 |
| `@ObservedObject var vm` | 同上 | 同上，但 View 不拥有 vm |
| `@Published var count`（在 vm 里） | 属性变化时发事件 | CurrentValueSubject |
| `TextField("x", text: $vm.name)` | `$vm.name`（双向 Binding） | 既订阅又写入 |
| `.onReceive(publisher)` | 任意 Publisher | **View 直接订阅 Publisher** |
| `@State` / `@Binding` | 值变化通知 | 不是 Combine，但机制类似 |

**所以你的理解方向是对的**：SwiftUI 页面确实在「接收」数据变化，只是大多数情况下你不需要手写 `.sink`，框架替你做完了。

---

### 14.1 三种订阅路径（由隐式到显式）

#### 路径 1：最常见 — ViewModel 的 @Published 驱动 View（隐式订阅）

```swift
class CounterViewModel: ObservableObject {
    @Published var count = 0   // Publisher（底层）
}

struct CounterView: View {
    @StateObject var vm = CounterViewModel()

    var body: some View {
        // body 里读取了 vm.count
        // → SwiftUI 自动订阅 vm 的变化
        // → count 变了，body 重新执行，界面刷新
        Text("\(vm.count)")
        Button("+1") { vm.count += 1 }
    }
}
```

数据流：

```
vm.count += 1
  → @Published 发出新值
  → objectWillChange 通知
  → CounterView.body 重新计算
  → Text 显示新数字
```

你**没有写 sink**，但 View 已经在「听」了。

---

#### 路径 2：ViewModel 内部用 assign/sink 连接多个属性

```swift
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isFormValid = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        // ViewModel 内部订阅 $email 和 $password 的变化
        Publishers.CombineLatest($email, $password)
            .map { email, pass in email.contains("@") && pass.count >= 6 }
            .assign(to: &$isFormValid)   // assign：属性同步
    }
}
```

```swift
struct LoginView: View {
    @StateObject var vm = LoginViewModel()

    var body: some View {
        TextField("邮箱", text: $vm.email)      // $vm.email = Binding，双向
        SecureField("密码", text: $vm.password)
        Button("登录") { }
            .disabled(!vm.isFormValid)          // 读 isFormValid，自动刷新
    }
}
```

这里有两层订阅：

1. **ViewModel 内部**：`combineLatest` 订阅 `$email` + `$password`（assign 写回 `isFormValid`）
2. **View 层**：隐式订阅 `vm` 的 `@Published` 变化

---

#### 路径 3：View 直接用 `.onReceive` 订阅 Publisher（显式订阅）

当 View 需要**直接听某个 Publisher**（不经过 ViewModel 的 @Published）时用：

```swift
struct TimerView: View {
    // 发布者：每秒发出一个时间
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    @State private var currentTime = Date()

    var body: some View {
        Text(currentTime.formatted(date: .omitted, time: .standard))
            .onReceive(timer) { date in
                // ← View 直接作为订阅者接收值
                currentTime = date
            }
    }
}
```

还有监听通知中心：

```swift
.onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
    print("App 回到前台")
    refreshData()
}
```

> `.onReceive` 就是 **View 层面最直接的 Combine 订阅者写法**。

---

### 14.2 SwiftUI 与 Combine 的对应关系

| SwiftUI 特性 | 底层 Combine 机制 |
|-------------|------------------|
| `@Published` | `CurrentValueSubject` + `objectWillChange` |
| `ObservableObject` | `objectWillChange: ObservableObjectPublisher` |
| `$viewModel.property` | `Publisher<PropertyType, Never>` |
| `TextField(text: $binding)` | `Binding` = 读 + 写 的双向通道 |
| `.onReceive(publisher)` | View 直接 `sink` 的 SwiftUI 封装 |

---

### 14.3 标准模式：ViewModel + @Published

这是 **SwiftUI 页面中最常见的写法**。

#### 第一步：写 ViewModel

```swift
import Combine
import SwiftUI

class UserListViewModel: ObservableObject {

    // 用 @Published 标记「会驱动 UI 刷新」的属性
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    func loadUsers() {
        isLoading = true
        errorMessage = nil

        URLSession.shared.dataTaskPublisher(for: apiURL)
            .map(\.data)
            .decode(type: [User].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] users in
                    self?.users = users
                }
            )
            .store(in: &cancellables)
    }
}
```

#### 第二步：在 View 中使用

```swift
struct UserListView: View {

    // @StateObject：View 自己创建并拥有 ViewModel（推荐）
    @StateObject private var viewModel = UserListViewModel()

    var body: some View {
        List(viewModel.users) { user in
            Text(user.name)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") { viewModel.errorMessage = nil }
        }
        .onAppear {
            viewModel.loadUsers()
        }
    }
}
```

#### 详细说明


| 写法                   | 什么时候用                                  |
| -------------------- | -------------------------------------- |
| `@StateObject`       | View 自己 `= ViewModel()` 创建，View 拥有生命周期 |
| `@ObservedObject`    | ViewModel 从外部传入（父 View 创建）             |
| `@EnvironmentObject` | 跨多层 View 共享（如全局 UserManager）           |


---

### 14.4 @Published 的 $ 符号

`@Published var count = 0` 会自动生成一个 Publisher：`$count`

```swift
class FormViewModel: ObservableObject {
    @Published var email = ""
    @Published var isEmailValid = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        // $email 是 Publisher<String, Never>
        // 每当 email 变化，重新验证
        $email
            .map { email in
                email.contains("@") && email.contains(".")
            }
            .assign(to: &$isEmailValid)
    }
}
```

**说明**：

- `$email`：监听 email 的变化
- `.assign(to: &$isEmailValid)`：把结果自动写回另一个 @Published 属性
- 页面里 `TextField("邮箱", text: $viewModel.email)` 双向绑定

---

### 14.5 Binding 和 Publisher 的区别（很多人搞混）

```swift
// $vm.email 有两种「面孔」：

// 面孔 1：Binding<String> — 给 TextField 双向绑定用
TextField("邮箱", text: $vm.email)

// 面孔 2：Publisher<String, Never> — 给 Combine 管道用
$vm.email
    .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
    .sink { email in print(email) }
    .store(in: &cancellables)
```

| | `Binding` | `Publisher`（`$property` 在 Combine 链里） |
|--|-----------|---------------------------------------------|
| 方向 | 可读可写 | 只读（发出新值通知） |
| 用于 | `TextField`、`Toggle` 等控件 | `map`、`debounce`、`combineLatest` |
| 写法 | `text: $vm.email` | `$vm.email.debounce(...)` |

---

### 14.6 页面中的完整数据流

```
用户点击按钮
    ↓
View 调用 viewModel.load()
    ↓
ViewModel 发起网络请求（Combine 管道）
    ↓
收到数据，赋值给 @Published var items
    ↓
SwiftUI 自动检测到变化
    ↓
View 重新渲染
```

你不需要手动 `reloadData()` 或 `setNeedsLayout()`，改 `@Published` 属性就行。

---

## 15. SwiftUI 状态管理完全指南

这一章专门理清：**@State、@StateObject、@ObservedObject、@Binding、@EnvironmentObject** 以及你容易遗漏的其他状态写法。  
每个都有 **Demo + 什么时候用 + 注意事项**。

---

### 15.0 先建立全局认识：SwiftUI 状态分两大类

```
┌─────────────────────────────────────────────────────────┐
│                    SwiftUI 状态管理                       │
├──────────────────────┬──────────────────────────────────┤
│  View 内部的简单状态    │  复杂 / 跨组件 / 有业务逻辑的状态    │
│  （值类型、UI 临时）    │  （引用类型、网络、表单、全局）        │
├──────────────────────┼──────────────────────────────────┤
│  @State              │  ObservableObject + @Published    │
│  @Binding（双向传递）  │  @StateObject / @ObservedObject   │
│  @FocusState 等      │  @EnvironmentObject               │
│                      │  @Observable（iOS 17+ 新方案）     │
└──────────────────────┴──────────────────────────────────┘
```

**选型口诀**：

- 只有这个 View 自己用、简单值（Bool、Int、String）→ **`@State`**
- 有业务逻辑、网络请求、多个属性联动 → **`ObservableObject` + `@StateObject`**
- 父 View 创建好，传给子 View → 子 View 用 **`@ObservedObject`**
- 全 App 多处要用（登录用户、主题）→ **`@EnvironmentObject`**
- 子组件要改父组件的 `@State` → 传 **`@Binding`**

---

### 15.1 @State — View 私有的简单状态

#### 概念

- 状态**属于当前 View**，别的 View 访问不到
- 适合**值类型**：`Bool`、`Int`、`String`、`enum`
- View 销毁，状态一起销毁
- **不是** Combine 的 Publisher，但变化同样会触发 `body` 重算

#### Demo：开关 + 计数器

```swift
struct ToggleCounterView: View {
    // @State：这个 View 自己拥有的状态
    @State private var isOn = false
    @State private var count = 0

    var body: some View {
        VStack(spacing: 20) {
            Toggle("开关", isOn: $isOn)   // $isOn → Binding，双向绑定
                .padding()

            if isOn {
                Text("当前计数: \(count)")
                Button("点我 +1") {
                    count += 1   // 直接改 @State，界面自动刷新
                }
            } else {
                Text("开关关闭中")
            }
        }
    }
}
```

#### 什么时候用 @State

| 场景 | 示例 |
|------|------|
| 控制弹窗显示 | `@State private var showAlert = false` |
| Tab 选中项 | `@State private var selectedTab = 0` |
| 临时输入（简单页） | `@State private var nickname = ""` |
| 动画状态 | `@State private var isExpanded = false` |

#### 注意事项

```swift
// ❌ 错误：把 @State 声明成 let
@State let count = 0   // 编译错误，必须是 var

// ❌ 错误：在 View 里放 class 引用类型用 @State 管理业务
@State private var viewModel = UserViewModel()  // 能用但不推荐！
// → class 应该用 @StateObject

// ❌ 错误：子 View 直接接收 @State 的值（单向传值），子 View 改了不会回传
ChildView(count: count)  // 子 View 收到的是副本

// ✅ 正确：子 View 需要修改时，传 Binding
ChildView(count: $count)
```

---

### 15.2 ObservableObject + @Published — ViewModel 类

#### 概念

当你的状态**不止一个字段**，或者有**网络请求、表单验证、Combine 管道**时，用一个 `class` 集中管理：

```swift
import Combine
import SwiftUI

// ① 遵循 ObservableObject → SwiftUI 能「观察」这个对象
class ProfileViewModel: ObservableObject {

    // ② @Published → 属性变化时自动通知 View 刷新（底层是 Combine）
    @Published var name = ""
    @Published var age = 0
    @Published var isSaving = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    // ③ 业务方法
    func save() {
        isSaving = true
        errorMessage = nil

        // 模拟网络请求
        Just(name)
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.isSaving = false
            }
            .store(in: &cancellables)
    }
}
```

```swift
struct ProfileView: View {
    // ④ View 层用 @StateObject 持有 ViewModel（下一节细讲）
    @StateObject private var vm = ProfileViewModel()

    var body: some View {
        Form {
            TextField("姓名", text: $vm.name)
            Stepper("年龄: \(vm.age)", value: $vm.age, in: 1...120)

            if vm.isSaving {
                ProgressView("保存中…")
            }

            Button("保存") { vm.save() }
                .disabled(vm.name.isEmpty)
        }
        .alert("错误", isPresented: .constant(vm.errorMessage != nil)) {
            Button("好") { vm.errorMessage = nil }
        }
    }
}
```

#### ObservableObject 和 Combine 的关系

```
ProfileViewModel（ObservableObject）
    ├── @Published var name     → 底层 CurrentValueSubject
    ├── @Published var age      → 变化时触发 objectWillChange
    └── Combine 管道（sink/assign）→ 改 @Published → View 刷新
```

---

### 15.3 @StateObject vs @ObservedObject — 最容易搞混的一对

这是新手**最高频的坑**。

#### 核心区别：谁「拥有」这个对象？

| | `@StateObject` | `@ObservedObject` |
|--|----------------|-------------------|
| **谁创建对象** | 当前 View 自己 `= ViewModel()` | 外部（父 View）创建好传进来 |
| **谁拥有生命周期** | 当前 View 拥有，View 在对象就在 | 不拥有，只是「观察」 |
| **View 重建时** | **不会**重新创建 ViewModel | 可能跟着外部重建 |
| **典型写法** | `@StateObject var vm = VM()` | `@ObservedObject var vm`（无 `=`） |

#### Demo：正确用法 — 父创建，子观察

```swift
// ===== 父 View：创建并拥有 ViewModel =====
struct ParentView: View {
    @StateObject private var vm = CartViewModel()  // ✅ 父创建，用 @StateObject

    var body: some View {
        VStack {
            Text("共 \(vm.totalCount) 件商品")
            // 传给子 View
            CartDetailView(vm: vm)
        }
    }
}

// ===== 子 View：接收外部传入的 ViewModel =====
struct CartDetailView: View {
    @ObservedObject var vm   // ✅ 外部传入，用 @ObservedObject（没有 = VM()）

    var body: some View {
        List(vm.items) { item in
            Text(item.name)
        }
        Button("清空") { vm.clear() }
    }
}

class CartViewModel: ObservableObject {
    @Published var items: [CartItem] = []
    var totalCount: Int { items.count }
    func clear() { items.removeAll() }
}
```

#### 经典错误：子 View 里写 `@ObservedObject var vm = ViewModel()`

```swift
// ❌ 错误示范
struct BadView: View {
    @ObservedObject var vm = ProfileViewModel()
    // 每次 View 重绘，可能创建新的 ViewModel，数据丢失！
}

// ✅ 正确
struct GoodView: View {
    @StateObject var vm = ProfileViewModel()
    // View 生命周期内只创建一次
}
```

#### 记忆法

> **谁 `new`（`= ViewModel()`），谁用 `@StateObject`**  
> **别人传给我的，我用 `@ObservedObject`**

---

### 15.4 @Binding — 双向绑定（父子 View 之间传「可写的引用」）

#### 概念

`@Binding` 不拥有数据，只是**别人状态的「遥控器」**——能读也能写。

```swift
// 父 View 拥有 @State
@State private var username = ""

// $username 的类型是 Binding<String>
// 传给子 View
ChildTextField(text: $username)

// 子 View 用 @Binding 接收
struct ChildTextField: View {
    @Binding var text: String   // 能读能写，改了就改到父的 @State

    var body: some View {
        TextField("用户名", text: $text)
    }
}
```

#### Demo：父管状态，子管输入框 UI

```swift
struct SignUpView: View {
    @State private var email = ""
    @State private var agreed = false

    var body: some View {
        VStack(spacing: 16) {
            // 自定义输入组件，通过 Binding 双向连接
            FormTextField(title: "邮箱", text: $email)
            AgreementRow(isAgreed: $agreed)

            Button("注册") { register() }
                .disabled(email.isEmpty || !agreed)
        }
        .padding()
    }

    func register() { print("注册: \(email)") }
}

// 可复用子组件
struct FormTextField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption)
            TextField(title, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

struct AgreementRow: View {
    @Binding var isAgreed: Bool

    var body: some View {
        Toggle("同意用户协议", isOn: $isAgreed)
    }
}
```

#### @Binding 和 @Published 的 `$` 关系

```swift
class FormVM: ObservableObject {
    @Published var email = ""
}

struct MyView: View {
    @StateObject var vm = FormVM()

    var body: some View {
        // $vm.email 在这里是 Binding<String>，可以给 TextField
        TextField("邮箱", text: $vm.email)
    }
}
```

| 写法 | 类型 | 谁拥有数据 |
|------|------|-----------|
| `@State var x` | 值本身 | 当前 View |
| `$x`（State 的） | `Binding` | 当前 View 借出去 |
| `@Published var x`（在 VM 里） | 值本身 | ViewModel |
| `$vm.x` | `Binding` | ViewModel 借给 View 写 |

#### 注意事项

```swift
// ❌ 子 View 只接收值，改了不影响父
struct Child: View {
    let text: String   // 单向，只读副本
}

// ✅ 子 View 需要改父的状态
struct Child: View {
    @Binding var text: String
}

// 常量 Binding（Preview 或测试用）
Child(text: .constant("预览文字"))
```

---

### 15.5 @EnvironmentObject — 跨多层 View 共享状态

#### 概念

数据从 App 根部注入，**任意深层子 View** 都能取，不用一层层传参。  
适合：登录用户、全局设置、购物车、主题。

#### Demo：全局 UserManager

```swift
// ① 定义全局状态类
class UserManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userName = ""

    func login(name: String) {
        userName = name
        isLoggedIn = true
    }
    func logout() {
        userName = ""
        isLoggedIn = false
    }
}

// ② App 入口注入
@main
struct MyApp: App {
    @StateObject private var userManager = UserManager()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(userManager)  // 注入环境
        }
    }
}

// ③ 深层页面直接取用（不需要父 View 传参）
struct ProfileTabView: View {
    @EnvironmentObject var userManager   // 自动从环境取

    var body: some View {
        if userManager.isLoggedIn {
            Text("你好，\(userManager.userName)")
            Button("退出") { userManager.logout() }
        } else {
            LoginPromptView()
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var userManager   // 同一个实例

    var body: some View {
        Text(userManager.isLoggedIn ? "已登录" : "未登录")
    }
}
```

#### 什么时候用

| 场景 | 用 @EnvironmentObject |
|------|----------------------|
| 登录态全 App 共享 | ✅ |
| 深色模式 / 语言设置 | ✅ |
| 仅父子两层传递 | ❌ 用 `@Binding` 或传 `@ObservedObject` 即可 |
| 单个页面私有状态 | ❌ 用 `@State` / `@StateObject` |

#### 注意事项

```swift
// ⚠️ 如果忘了 .environmentObject() 注入，运行时会崩溃！
// 比 @ObservedObject 更危险，要确保 App 根部一定注入

// ❌ 不要同时又 @StateObject 又重新创建
@EnvironmentObject var userManager   // 用环境的
@StateObject var userManager = UserManager()  // 又创建一个，两套数据！
```

---

### 15.6 容易遗漏的其他状态写法（实战也会用到）

| 属性包装器 | 作用 | 典型场景 |
|-----------|------|----------|
| `@Environment` | 读取系统环境值 | `@Environment(\.dismiss)` 关闭页面、`\.colorScheme` 深色模式 |
| `@AppStorage` | 持久化到 UserDefaults | 「记住登录」「上次选的分组」 |
| `@SceneStorage` | 场景级恢复 | 多窗口 iPad 恢复滚动位置 |
| `@FocusState` | 管理输入框焦点 | 键盘跳转、回车切下一个字段 |
| `@GestureState` | 手势过程中的临时状态 | 拖拽偏移量 |
| `@Bindable`（iOS 17+） | 配合 `@Observable` 生成 Binding | 新 Observation 框架 |
| `@Observable`（iOS 17+） | 替代 `ObservableObject` 的新方案 | 新项目的 ViewModel |

#### @Environment 示例

```swift
struct DetailView: View {
    @Environment(\.dismiss) private var dismiss   // 系统提供的「关闭」动作

    var body: some View {
        Button("返回") { dismiss() }
    }
}
```

#### @AppStorage 示例

```swift
struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        Toggle("深色模式", isOn: $isDarkMode)
        // 值自动存 UserDefaults，下次启动还在
    }
}
```

#### iOS 17+ @Observable 简提（你的项目 iOS 18 可用）

```swift
import Observation

@Observable               // 新方案，不需要 @Published
class NewCounterModel {
    var count = 0
}

struct NewCounterView: View {
    @State private var model = NewCounterModel()  // 注意：@State 持有 @Observable 对象
    // 或 @Bindable var model（从外部传入时）

    var body: some View {
        Text("\(model.count)")
        Button("+1") { model.count += 1 }
    }
}
```

> 本 App 目前以 `ObservableObject` + `@Published` + Combine 为主；新项目可了解 `@Observable`，但 Combine 管道仍常与 `ObservableObject` 配合。

---

### 15.7 选型总表：什么情况用什么？

| 你的情况 | 推荐写法 | 理由 |
|----------|----------|------|
| 本页一个开关 / 弹窗显隐 | `@State` | 简单、私有 |
| 本页简单表单，无网络 | `@State` + `@Binding` 拆子组件 | 够用 |
| 页面有网络请求、多字段、Combine | `ObservableObject` + `@StateObject` | 业务集中管理 |
| 父页面创建 VM，子页面展示 | 父 `@StateObject`，子 `@ObservedObject` | 生命周期正确 |
| 子组件要改父的 `@State` | 父传 `$state`，子用 `@Binding` | 双向同步 |
| TextField 绑定 VM 属性 | `$vm.email`（@Published 的 Binding） | 标准写法 |
| 登录用户、全局配置 | `@EnvironmentObject` | 免层层传参 |
| 关闭页面、取系统主题 | `@Environment` | 系统内置 |
| 记住用户偏好到本地 | `@AppStorage` | 自动持久化 |
| VM 内多属性联动验证 | `$a.combineLatest($b).assign(to: &$valid)` | Combine 在 VM 内部 |
| View 直接听 Timer / 通知 | `.onReceive(publisher)` | 不经过 VM |

---

### 15.8 常见错误清单（务必避开）

```swift
// 1. 用 @ObservedObject 却又自己创建实例
@ObservedObject var vm = MyViewModel()  // ❌ → 改 @StateObject

// 2. class 对象用 @State 而不是 @StateObject
@State var vm = MyViewModel()  // ❌ 可能反复重建 → 改 @StateObject

// 3. 忘了 @Published，改了属性 UI 不刷新
class VM: ObservableObject {
    var count = 0   // ❌ 没有 @Published
}
class VM: ObservableObject {
    @Published var count = 0  // ✅
}

// 4. @EnvironmentObject 没注入就使用 → 运行时崩溃
// 5. 网络回调里改 @Published 不在主线程 → 加 .receive(on: .main)
// 6. Combine 订阅没 store → 管道立刻失效
// 7. 子 View 需要改父状态，却只传了 let 值而不是 Binding
```

---

### 15.9 综合实战 Demo：一个注册页用到多种状态

把本章知识点串在一个例子里：

```swift
// ========== ViewModel：业务 + Combine ==========
class RegisterViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isFormValid = false
    @Published var isSubmitting = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        Publishers.CombineLatest($email, $password)
            .map { email, pass in
                email.contains("@") && pass.count >= 6
            }
            .assign(to: &$isFormValid)
    }

    func submit() {
        isSubmitting = true
        // 模拟请求…
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isSubmitting = false
        }
    }
}

// ========== 可复用子组件：用 @Binding ==========
struct PasswordField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        SecureField(title, text: $text)
            .textFieldStyle(.roundedBorder)
    }
}

// ========== 主页面 ==========
struct RegisterView: View {
    @StateObject private var vm = RegisterViewModel()     // ① 本页拥有 VM
    @State private var showTips = false                 // ② 本页私有 UI 状态
    @EnvironmentObject var appConfig: AppConfigManager  // ③ 全局配置

    var body: some View {
        Form {
            Section("账号") {
                TextField("邮箱", text: $vm.email)       // ④ @Published 的 Binding
                PasswordField(title: "密码", text: $vm.password)  // ⑤ 子组件 Binding
            }

            Section {
                Toggle("显示提示", isOn: $showTips)     // ⑥ 本页 @State
                if showTips {
                    Text("密码至少 6 位").font(.caption)
                }
            }

            Button {
                vm.submit()
            } label: {
                if vm.isSubmitting {
                    ProgressView()
                } else {
                    Text("注册")
                }
            }
            .disabled(!vm.isFormValid || vm.isSubmitting)
        }
        .navigationTitle(appConfig.appName)               // ⑦ EnvironmentObject
    }
}
```

**这个页面用到了**：

| 知识点 | 在哪里 |
|--------|--------|
| `ObservableObject` + `@Published` | `RegisterViewModel` |
| `@StateObject` | `RegisterView` 持有 VM |
| `@State` | `showTips` 弹窗提示 |
| `@Binding` | `PasswordField` 接收密码 |
| `$vm.email` | @Published 转 Binding |
| `combineLatest` + `assign` | VM 内表单验证 |
| `@EnvironmentObject` | 读取全局 `appConfig` |

---

### 15.10 状态管理 + Combine 协作关系图

```
┌────────────── RegisterView ──────────────┐
│  @StateObject vm ─────────────────────┐  │
│  @State showTips                      │  │
│  @EnvironmentObject appConfig         │  │
│                                       ▼  │
│                            RegisterViewModel
│                            (@Published email/password)
│                            ($email + $password → isFormValid)
│                                       │  Combine assign
│  TextField ← $vm.email ←──────────────┘
│  PasswordField ← $vm.password (Binding)
└──────────────────────────────────────────┘
```

---

## 16. SwiftUI 实战场景大全

---

### 场景 1：搜索框防抖

**需求**：用户输入时不立刻搜索，停下来 0.4 秒后再请求。

```swift
class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [String] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        $query
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .filter { !$0.isEmpty }
            .sink { [weak self] keyword in
                self?.performSearch(keyword)
            }
            .store(in: &cancellables)
    }

    private func performSearch(_ keyword: String) {
        // 调接口…
        results = ["\(keyword) 的结果1", "\(keyword) 的结果2"]
    }
}
```

```swift
struct SearchView: View {
    @StateObject private var vm = SearchViewModel()

    var body: some View {
        VStack {
            TextField("搜索", text: $vm.query)
                .textFieldStyle(.roundedBorder)

            List(vm.results, id: \.self) { item in
                Text(item)
            }
        }
    }
}
```

---

### 场景 2：表单验证（登录按钮）

**需求**：邮箱和密码都合法时，登录按钮才可点击。

```swift
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isFormValid = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        Publishers.CombineLatest($email, $password)
            .map { email, password in
                email.contains("@") && password.count >= 6
            }
            .assign(to: &$isFormValid)
    }
}
```

```swift
struct LoginView: View {
    @StateObject private var vm = LoginViewModel()

    var body: some View {
        Form {
            TextField("邮箱", text: $vm.email)
            SecureField("密码", text: $vm.password)

            Button("登录") {
                // 执行登录
            }
            .disabled(!vm.isFormValid)
        }
    }
}
```

---

### 场景 3：页面加载状态（Loading / Error / Data）

**需求**：列表页有三种状态：加载中、出错、有数据。

```swift
class ArticleListViewModel: ObservableObject {
    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    func fetchArticles() {
        isLoading = true
        errorMessage = nil

        api.fetchArticles()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] articles in
                    self?.articles = articles
                }
            )
            .store(in: &cancellables)
    }
}
```

```swift
struct ArticleListView: View {
    @StateObject private var vm = ArticleListViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView("加载中…")
            } else if let error = vm.errorMessage {
                Text("出错了: \(error)")
            } else {
                List(vm.articles) { article in
                    Text(article.title)
                }
            }
        }
        .onAppear { vm.fetchArticles() }
    }
}
```

---

### 场景 4：两个输入联动（温度换算）

**需求**：滑块改摄氏度，华氏度自动更新。

```swift
class TemperatureViewModel: ObservableObject {
    @Published var celsius: Double = 25
    @Published var fahrenheit: Double = 77

    private var cancellables = Set<AnyCancellable>()

    init() {
        $celsius
            .map { $0 * 9 / 5 + 32 }
            .assign(to: &$fahrenheit)
    }
}
```

```swift
struct TemperatureView: View {
    @StateObject private var vm = TemperatureViewModel()

    var body: some View {
        VStack {
            Slider(value: $vm.celsius, in: -20...50)
            Text("\(Int(vm.celsius))°C = \(String(format: "%.1f", vm.fahrenheit))°F")
        }
    }
}
```

---

### 场景 5：多步网络请求链

**需求**：先拿 userId，再拿用户详情。

```swift
func loadUserProfile() {
    isLoading = true

    fetchUserID()
        .flatMap { [weak self] userId -> AnyPublisher<User, Error> in
            guard let self else {
                return Fail(error: URLError(.unknown)).eraseToAnyPublisher()
            }
            return self.fetchUserDetail(id: userId)
        }
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            },
            receiveValue: { [weak self] user in
                self?.user = user
            }
        )
        .store(in: &cancellables)
}
```

---

### 场景 6：全局状态共享（EnvironmentObject）

**需求**：登录状态在多个页面共享。

```swift
class UserManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userName = ""

    func login(name: String) {
        userName = name
        isLoggedIn = true
    }

    func logout() {
        userName = ""
        isLoggedIn = false
    }
}
```

```swift
// App 入口注入
@main
struct MyApp: App {
    @StateObject private var userManager = UserManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(userManager)
        }
    }
}
```

```swift
// 任意子页面使用
struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager

    var body: some View {
        if userManager.isLoggedIn {
            Text("欢迎, \(userManager.userName)")
        } else {
            Text("请先登录")
        }
    }
}
```

---

### 场景 7：页面销毁时自动取消请求

**需求**：用户离开页面后，不需要的网络请求应该取消。

```swift
class DetailViewModel: ObservableObject {
    @Published var detail: Detail?
    private var cancellables = Set<AnyCancellable>()

    func load(id: String) {
        api.fetchDetail(id: id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] detail in
                    self?.detail = detail
                }
            )
            .store(in: &cancellables)
    }
}
// ViewModel 销毁 → cancellables 释放 → 所有订阅自动 cancel
```

**说明**：把订阅存进 `cancellables`，当 ViewModel 随 View 销毁时，Combine 会自动取消所有进行中的请求。

---

### 场景对照表


| 页面场景   | 用什么                   | 关键操作符 / 写法               |
| ------ | --------------------- | ------------------------ |
| 列表加载   | `@Published` + `sink` | `receive(on: .main)`     |
| 搜索框    | `$query` + `debounce` | `removeDuplicates`       |
| 表单验证   | `combineLatest`       | `map` + `assign`         |
| 按钮防连点  | `throttle`            | —                        |
| 多接口串联  | `flatMap`             | `switchToLatest`         |
| 全局登录态  | `@EnvironmentObject`  | `@Published`             |
| 错误提示   | `sink` completion     | `catch` / `replaceError` |
| 属性联动计算 | `$property` + `map`   | `assign(to: &)`          |


---

## 17. 推荐学习路径

按这个顺序学，不要跳：

```
第 1 步：看懂四个概念（Publisher / Subscriber / Operator / Cancellable）
    ↓
第 2 步：区分「一次性」和「持续发送」，写通 Just / Subject / @Published
    ↓
第 3 步：学 sink 和 assign 的区别，知道什么时候用哪个
    ↓
第 4 步：理解 .publisher 不限类型，各种数组/结构体都能用
    ↓
第 5 步：学 map / filter / debounce
    ↓
第 6 步：学 @State / @StateObject / @ObservedObject / @Binding 区别（第 15 章）
    ↓
第 7 步：学 @Published + ObservableObject + SwiftUI View 如何隐式订阅
    ↓
第 8 步：学 combineLatest（表单验证）+ assign(to: &)
    ↓
第 9 步：学 @EnvironmentObject、@AppStorage 等全局/持久化状态
    ↓
第 10 步：学网络请求 + receive(on:) + 错误处理（只能 sink）
    ↓
第 11 步：学 flatMap + switchToLatest（搜索、多步请求）
    ↓
第 12 步：学 .onReceive，让 View 直接订阅 Publisher
    ↓
第 13 步：做一遍第 15.9 综合注册页 Demo，串起所有状态写法
```

---

## 附：Combine vs async/await 怎么选？


|         | Combine           | async/await    |
| ------- | ----------------- | -------------- |
| 适合      | 持续的事件流、多源组合、UI 绑定 | 一次性异步任务        |
| 例子      | 搜索框输入、表单验证、通知监听   | 单次网络请求、读文件     |
| SwiftUI | `@Published` 天然配合 | `.task { }` 配合 |


**实际项目中的建议**：

- 页面 ViewModel 驱动 UI → 继续用 `@Published` + Combine
- 单次网络请求 → 可以用 `async/await`，更直观
- 搜索框、表单联动 → Combine 更合适
- 两者可以混用：`Task { let data = await fetch(); self.items = data }`

---

## 附：本 App 中的对应代码位置


| 文档章节 | App 内对应页面 |
|----------|---------------|
| 第 3 章 一次性 vs 持续发送 | 核心概念 + 基础发布者 + Subject |
| 第 5 章 assign | SwiftUI 集成 |
| 第 6 章 .publisher 类型 | 基础发布者 |
| 第 10 章 操作符 | 变换与过滤 |
| 第 11 章 组合多个流 | 组合多个流 |
| 第 12 章 错误处理 | 错误处理 |
| 第 13 章 线程调度 | 线程调度 |
| 第 14 章 SwiftUI 订阅 | SwiftUI 集成 |
| 第 15 章 实战 | 综合案例 |


建议：**先看本文档理解概念，再到 App 里点「运行演示」对照验证。**

---

*源码路径：`SwiftUIDemo/Features/DemoPage/Combine/Combine使用文档.md`*  
*App 内阅读：Combine Tab → 使用文档（Bundle：`Resources/CombineGuide.md`）*