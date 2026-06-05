//
//  ViewPresenterModifier.swift
//  SwiftUIDemo
//

import SwiftUI

struct ViewPresenterModifier: ViewModifier {
    @Bindable var presenter: ViewPresenter

    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: stackCoverBinding) { _ in
                ViewPresenterStackHost(presenter: presenter)
            }
    }

    private var stackCoverBinding: Binding<ViewPresenterCoverToken?> {
        Binding(
            get: { presenter.isPresentingStack ? ViewPresenterCoverToken() : nil },
            set: { newValue in
                guard newValue == nil, presenter.dismissingDialogID == nil else { return }
                presenter.dismissAllPresented()
            }
        )
    }
}

extension View {
    func viewPresenter(_ presenter: ViewPresenter) -> some View {
        modifier(ViewPresenterModifier(presenter: presenter))
    }
}

// MARK: - Stack Host

private struct ViewPresenterStackHost: View {
    @Bindable var presenter: ViewPresenter

    var body: some View {
        ZStack {
            if let page = presenter.pageCover {
                page.content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if let item = presenter.topDialogItem {
                ViewPresenterDialogLayer(
                    item: item,
                    isDismissing: item.id == presenter.dismissingDialogID,
                    onBackgroundTap: {
                        guard item.dismissOnBackgroundTap else { return }
                        presenter.dismiss()
                    }
                )
                .id(item.id)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(ViewPresenterStackHostStyle(
            usesSystemPresentation: presenter.pageCover != nil && presenter.dialogStack.isEmpty
        ))
    }
}

private struct ViewPresenterStackHostStyle: ViewModifier {
    let usesSystemPresentation: Bool

    func body(content: Content) -> some View {
        if usesSystemPresentation {
            content
                .interactiveDismissDisabled(true)
        } else {
            content
                .background(Color.clear)
                .presentationBackground(.clear)
                .interactiveDismissDisabled(true)
        }
    }
}

private struct ViewPresenterDialogLayer: View {
    let item: ViewPresenterDialogItem
    let isDismissing: Bool
    let onBackgroundTap: () -> Void

    @State private var isEntered = false

    var body: some View {
        ZStack {
            Color.black
                .opacity(isDismissing ? 0 : (isEntered ? DialogMetrics.scrimOpacity : 0))
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .allowsHitTesting(!isDismissing && isEntered)
                .onTapGesture(perform: onBackgroundTap)
                .animation(DialogMetrics.scrimAnimation, value: isEntered)
                .animation(DialogMetrics.scrimAnimation, value: isDismissing)

            dialogContent
                .allowsHitTesting(!isDismissing)
                .animation(contentAnimation, value: isEntered)
                .animation(contentAnimation, value: isDismissing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(DialogMetrics.scrimAnimation) { isEntered = true }
        }
        .onChange(of: isDismissing) { _, dismissing in
            if dismissing {
                withAnimation(DialogMetrics.scrimAnimation) { isEntered = false }
            }
        }
        .onChange(of: item.id) { _, _ in
            isEntered = false
            withAnimation(DialogMetrics.scrimAnimation) { isEntered = true }
        }
    }

    @ViewBuilder
    private var dialogContent: some View {
        switch item {
        case .alert(let alert):
            AppAlertView(
                title: alert.title,
                message: alert.message,
                content: alert.content,
                buttons: alert.buttons
            )
            .scaleEffect(isEntered && !isDismissing ? 1 : 0.94)
            .opacity(isEntered && !isDismissing ? 1 : 0)

        case .actionSheet(let sheet):
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                AppActionSheetView(
                    title: sheet.title,
                    message: sheet.message,
                    content: sheet.content,
                    buttons: sheet.buttons
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .bottom)
            .offset(y: isEntered && !isDismissing ? 0 : 320)
            .opacity(isEntered && !isDismissing ? 1 : 0)

        case .custom(let custom):
            switch custom.style {
            case .alert:
                custom.content
                    .scaleEffect(isEntered && !isDismissing ? 1 : 0.98)
                    .opacity(isEntered && !isDismissing ? 1 : 0)

            case .sheet:
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    custom.content
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .bottom)
                .offset(y: isEntered && !isDismissing ? 0 : 320)
                .opacity(isEntered && !isDismissing ? 1 : 0)
            }
        }
    }

    private var contentAnimation: Animation {
        switch item {
        case .alert: DialogMetrics.alertAnimation
        case .actionSheet: DialogMetrics.actionSheetAnimation
        case .custom(let custom):
            switch custom.style {
            case .alert: DialogMetrics.alertAnimation
            case .sheet: DialogMetrics.actionSheetAnimation
            }
        }
    }
}
