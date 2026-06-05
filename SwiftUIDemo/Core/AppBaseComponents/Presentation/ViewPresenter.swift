//
//  ViewPresenter.swift
//  SwiftUIDemo
//
//  页面级 present：各页面 @State 持有，根节点挂 `.viewPresenter(_:)`。
//  - 整页 Cover（presentPage / presentNavigationPage）→ 独立 `pageCover` 槽
//  - Alert / ActionSheet / 自定义 → `dialogStack` 队列，叠在 Cover 之上
//

import SwiftUI

@Observable
final class ViewPresenter {

    private(set) var pageCover: ViewPresenterCoverItem?
    private(set) var dialogStack: [ViewPresenterDialogItem] = []

    private(set) var dismissingDialogID: UUID?
    private var dismissTask: Task<Void, Never>?
    private var dismissCompletion: (() -> Void)?

    /// 弹窗队列深度（不含整页 Cover）。
    var stackDepth: Int { dialogStack.count }

    var isPresentingPage: Bool { pageCover != nil }
    var isPresentingDialog: Bool { !dialogStack.isEmpty || dismissingDialogID != nil }

    /// 是否正在展示任意 present 内容（Cover 或弹窗），用于挂载 fullScreenCover 宿主。
    var isPresentingStack: Bool { isPresentingPage || isPresentingDialog }

    var topDialogItem: ViewPresenterDialogItem? { dialogStack.last }

    // MARK: - Alert

    func presentAlert(
        title: String? = nil,
        message: String? = nil,
        buttons: [DialogButton],
        dismissOnBackgroundTap: Bool = false
    ) {
        enqueueDialog(.alert(ViewPresenterAlertItem(
            title: title,
            message: message,
            content: nil,
            buttons: buttons,
            dismissOnBackgroundTap: dismissOnBackgroundTap
        )))
    }

    func presentAlert<Content: View>(
        title: String? = nil,
        message: String? = nil,
        dismissOnBackgroundTap: Bool = false,
        @ViewBuilder content: () -> Content,
        buttons: [DialogButton]
    ) {
        enqueueDialog(.alert(ViewPresenterAlertItem(
            title: title,
            message: message,
            content: AnyView(content()),
            buttons: buttons,
            dismissOnBackgroundTap: dismissOnBackgroundTap
        )))
    }

    func presentCommonAlert(
        title: String? = nil,
        message: String? = nil,
        cancelBtnText: String? = nil,
        confirmBtnText: String? = nil,
        dismissOnBackgroundTap: Bool = false,
        cancelBtnTap: (() -> Void)? = nil,
        confirmBtnTap: (() -> Void)? = nil
    ) {
        presentAlert(
            title: title,
            message: message,
            buttons: makeCommonButtons(
                cancelBtnText: cancelBtnText,
                confirmBtnText: confirmBtnText,
                cancelBtnTap: cancelBtnTap,
                confirmBtnTap: confirmBtnTap
            ),
            dismissOnBackgroundTap: dismissOnBackgroundTap
        )
    }

    func presentCommonAlert<Content: View>(
        title: String? = nil,
        message: String? = nil,
        dismissOnBackgroundTap: Bool = false,
        @ViewBuilder content: () -> Content,
        cancelBtnText: String? = nil,
        confirmBtnText: String? = nil,
        cancelBtnTap: (() -> Void)? = nil,
        confirmBtnTap: (() -> Void)? = nil
    ) {
        presentAlert(
            title: title,
            message: message,
            dismissOnBackgroundTap: dismissOnBackgroundTap,
            content: content,
            buttons: makeCommonButtons(
                cancelBtnText: cancelBtnText,
                confirmBtnText: confirmBtnText,
                cancelBtnTap: cancelBtnTap,
                confirmBtnTap: confirmBtnTap
            )
        )
    }

    // MARK: - ActionSheet

    func presentActionSheet(
        title: String? = nil,
        message: String? = nil,
        buttons: [DialogButton],
        dismissOnBackgroundTap: Bool = true
    ) {
        enqueueDialog(.actionSheet(ViewPresenterActionSheetItem(
            title: title,
            message: message,
            content: nil,
            buttons: buttons,
            dismissOnBackgroundTap: dismissOnBackgroundTap
        )))
    }

    func presentActionSheet<Content: View>(
        title: String? = nil,
        message: String? = nil,
        dismissOnBackgroundTap: Bool = true,
        @ViewBuilder content: () -> Content,
        buttons: [DialogButton]
    ) {
        enqueueDialog(.actionSheet(ViewPresenterActionSheetItem(
            title: title,
            message: message,
            content: AnyView(content()),
            buttons: buttons,
            dismissOnBackgroundTap: dismissOnBackgroundTap
        )))
    }

    // MARK: - Custom

    func presentCustomView<Content: View>(
        style: ViewPresenterCustomStyle,
        dismissOnBackgroundTap: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        enqueueDialog(.custom(ViewPresenterCustomItem(
            style: style,
            content: AnyView(content()),
            dismissOnBackgroundTap: dismissOnBackgroundTap
        )))
    }

    // MARK: - 整页 Present（独立 pageCover 槽，不入弹窗队列）

    /// 整页展示，不包独立导航（模块根已自带 NavigationStack 时用，如模版 App）。
    func presentPage<Content: View>(@ViewBuilder _ content: @escaping () -> Content) {
        openPageCover(ViewPresenterCoverItem(content: AnyView(content())))
    }

    /// 整页展示 + 独立 NavigationStack + 独立 AppRouter + `AppRouteRegistry.all`。
    func presentNavigationPage<Content: View>(@ViewBuilder _ content: @escaping () -> Content) {
        presentPage {
            PresentedNavigationHost(content: content)
        }
    }

    /// 关闭整页 Cover；同时清空其上的弹窗队列。
    func dismissCover(complete: (() -> Void)? = nil) {
        guard pageCover != nil else {
            complete?()
            return
        }
        dialogStack.removeAll()
        dismissingDialogID = nil
        dismissTask?.cancel()
        dismissCompletion = complete
        dismissSystemPage()
    }

    // MARK: - Dismiss

    /// 关闭弹窗队列栈顶一层（Alert / ActionSheet / 自定义）。
    func dismiss(complete: (() -> Void)? = nil) {
        guard let top = topDialogItem else {
            complete?()
            return
        }
        guard dismissingDialogID == nil else { return }

        dismissCompletion = complete
        dismissingDialogID = top.id
        dismissTask?.cancel()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: DialogMetrics.contentAnimationDuration)
            guard !Task.isCancelled else { return }
            finishDismissingTopDialog()
        }
    }

    /// 立即清空弹窗队列（无逐层动画）；**不**关闭整页 Cover。
    func dismissAllDialog(complete: (() -> Void)? = nil) {
        dismissTask?.cancel()
        dismissingDialogID = nil
        dismissCompletion = nil
        DialogMetrics.withoutSystemPresentationAnimation {
            dialogStack.removeAll()
        }
        complete?()
    }

    /// 关闭全部 present 内容（弹窗队列 + 整页 Cover）；系统手势兜底用。
    func dismissAllPresented(complete: (() -> Void)? = nil) {
        dismissAllDialog()
        pageCover = nil
        complete?()
    }

    // MARK: - Private

    private func openPageCover(_ item: ViewPresenterCoverItem) {
        dismissTask?.cancel()
        dismissingDialogID = nil
        let openingFresh = !isPresentingStack
        if openingFresh {
            withAnimation(DialogMetrics.pagePresentationAnimation) {
                pageCover = item
            }
        } else {
            pageCover = item
        }
    }

    private func enqueueDialog(_ item: ViewPresenterDialogItem) {
        dismissTask?.cancel()
        dismissingDialogID = nil
        let openingFresh = !isPresentingStack
        if openingFresh {
            DialogMetrics.withoutSystemPresentationAnimation {
                dialogStack.append(item)
            }
        } else {
            dialogStack.append(item)
        }
    }

    private func dismissSystemPage() {
        dismissTask?.cancel()
        dismissingDialogID = nil
        dismissTask = Task { @MainActor in
            withAnimation(DialogMetrics.pagePresentationAnimation) {
                pageCover = nil
            }
            try? await Task.sleep(for: DialogMetrics.pagePresentationDuration)
            guard !Task.isCancelled else { return }
            let completion = dismissCompletion
            dismissCompletion = nil
            completion?()
        }
    }

    private func finishDismissingTopDialog() {
        if let dismissingDialogID {
            guard dialogStack.last?.id == dismissingDialogID else {
                self.dismissingDialogID = nil
                dismissCompletion = nil
                return
            }
        } else if dialogStack.isEmpty {
            dismissCompletion = nil
            return
        }

        let willBeEmpty = dialogStack.count == 1 && pageCover == nil
        if willBeEmpty {
            DialogMetrics.withoutSystemPresentationAnimation {
                dialogStack.removeLast()
                self.dismissingDialogID = nil
            }
        } else {
            dialogStack.removeLast()
            self.dismissingDialogID = nil
        }

        let completion = dismissCompletion
        dismissCompletion = nil
        completion?()
    }

    private func makeCommonButtons(
        cancelBtnText: String?,
        confirmBtnText: String?,
        cancelBtnTap: (() -> Void)?,
        confirmBtnTap: (() -> Void)?
    ) -> [DialogButton] {
        var buttons: [DialogButton] = []
        if let cancelBtnText {
            buttons.append(.cancel(cancelBtnText) { [weak self] in
                self?.dismiss(complete: cancelBtnTap)
            })
        }
        if let confirmBtnText {
            buttons.append(.default(confirmBtnText) { [weak self] in
                self?.dismiss(complete: confirmBtnTap)
            })
        }
        return buttons
    }
}
