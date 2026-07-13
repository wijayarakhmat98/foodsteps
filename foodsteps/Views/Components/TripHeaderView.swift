//
//  TripHeaderView.swift
//  foodsteps
//
//  Created by Willy Tanuwijaya on 13/07/26.
//


import SwiftUI

/// The purple, rounded-bottom header used on the trip hub screen: a back
/// button, centered title, optional trailing action, and the Places/Route
/// tab switcher — all matching the design mockups (deep purple card with a
/// white capsule for the active tab).
struct TripHeaderView<Tab: Hashable>: View {
    let title: String
    let tabs: [(tab: Tab, label: String)]
    @Binding var selectedTab: Tab
    var onBack: (() -> Void)? = nil
    var trailing: (() -> AnyView)? = nil

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack {
                    if let onBack {
                        translucentCircleButton(systemImage: "chevron.left", action: onBack)
                    }
                    Spacer()
                    if let trailing {
                        trailing()
                    }
                }
            }

            tabSwitcher
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity)
        .background(
            Color.brandPurple
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 40, bottomTrailingRadius: 40))
                .ignoresSafeArea(edges: .top)
        )
    }

    /// Translucent white circle, white icon — used for the back chevron.
    private func translucentCircleButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white.opacity(0.22)))
        }
    }

    private var tabSwitcher: some View {
        HStack(spacing: 4) {
            ForEach(tabs, id: \.tab) { entry in
                let isSelected = entry.tab == selectedTab
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedTab = entry.tab
                    }
                } label: {
                    Text(entry.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isSelected ? Color.brandPurple : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(isSelected ? Color.white : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(Capsule().fill(Color.white.opacity(0.22)))
    }
}