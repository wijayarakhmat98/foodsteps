//
//  ConfirmationDialogView.swift
//  foodsteps
//
//  Created by Willy Tanuwijaya on 13/07/26.
//

import SwiftUI

/// The centered white card used for destructive/irreversible confirmations
/// (e.g. "Finish Trip?") — a bold purple title, a gray subtitle, an
/// outlined Cancel button, and a filled orange primary button, matching the
/// design mockups.
struct ConfirmationDialogView: View {
    let title: String
    let message: String
    var cancelTitle: String = "Cancel"
    let confirmTitle: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.brandPurple)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button(action: onCancel) {
                    Text(cancelTitle)
                        .font(.headline)
                        .foregroundColor(.brandPurple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.brandPurple, lineWidth: 1.5)
                        )
                }

                Button(action: onConfirm) {
                    Text(confirmTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.brandOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(24)
        .frame(maxWidth: 320)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.2), radius: 24, y: 8)
    }
}

/// Dims the screen and centers a `ConfirmationDialogView` over it whenever
/// `isPresented` is true. Tapping the dimmed backdrop cancels, same as the
/// Cancel button.
private struct ConfirmationOverlay: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let confirmTitle: String
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture { isPresented = false }

                    ConfirmationDialogView(
                        title: title,
                        message: message,
                        confirmTitle: confirmTitle,
                        onCancel: { isPresented = false },
                        onConfirm: {
                            isPresented = false
                            onConfirm()
                        }
                    )
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                .animation(.easeOut(duration: 0.2), value: isPresented)
            }
        }
    }
}

extension View {
    /// Presents a `ConfirmationDialogView` as a dimmed, centered overlay —
    /// use in place of `.alert` for confirmations that need the custom
    /// (non-native) look from the design mockups, e.g. "Finish Trip?".
    func confirmationDialogOverlay(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String,
        onConfirm: @escaping () -> Void
    ) -> some View {
        modifier(
            ConfirmationOverlay(
                isPresented: isPresented,
                title: title,
                message: message,
                confirmTitle: confirmTitle,
                onConfirm: onConfirm
            )
        )
    }
}
