//
//  ViewPresenterModels.swift
//  SwiftUIDemo
//

import SwiftUI

enum ViewPresenterCustomStyle: Sendable {
    case alert
    case sheet
}

struct ViewPresenterAlertItem: Identifiable {
    let id = UUID()
    let title: String?
    let message: String?
    let content: AnyView?
    let buttons: [DialogButton]
    let dismissOnBackgroundTap: Bool
}

struct ViewPresenterActionSheetItem: Identifiable {
    let id = UUID()
    let title: String?
    let message: String?
    let content: AnyView?
    let buttons: [DialogButton]
    let dismissOnBackgroundTap: Bool
}

struct ViewPresenterCustomItem: Identifiable {
    let id = UUID()
    let style: ViewPresenterCustomStyle
    let content: AnyView
    let dismissOnBackgroundTap: Bool
}

struct ViewPresenterCoverItem: Identifiable {
    let id = UUID()
    let content: AnyView
}

/// 弹窗队列项（Alert / ActionSheet / 自定义）；整页 Cover 使用独立的 `pageCover` 槽，不入此队列。
enum ViewPresenterDialogItem: Identifiable {
    case alert(ViewPresenterAlertItem)
    case actionSheet(ViewPresenterActionSheetItem)
    case custom(ViewPresenterCustomItem)

    var id: UUID {
        switch self {
        case .alert(let item): item.id
        case .actionSheet(let item): item.id
        case .custom(let item): item.id
        }
    }

    var dismissOnBackgroundTap: Bool {
        switch self {
        case .alert(let item): item.dismissOnBackgroundTap
        case .actionSheet(let item): item.dismissOnBackgroundTap
        case .custom(let item): item.dismissOnBackgroundTap
        }
    }
}

struct ViewPresenterCoverToken: Identifiable {
    let id = 0
}
