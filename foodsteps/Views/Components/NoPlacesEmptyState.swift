//
//  NoPlacesEmptyState.swift
//  foodsteps
//
//  Created by Willy Tanuwijaya on 13/07/26.
//


import SwiftUI

/// The empty state shown on both the Places and Route tabs before any stop
/// has been added yet — a mascot illustration plus a short headline and
/// subtitle, matching the target design. Shared between `PlacesView` and
/// `RouteView` so both tabs look identical while there's nothing to show.
struct NoPlacesEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            Image("Mascot_6")
                .resizable()
                .scaledToFit()
                .frame(height: 180)

            VStack(spacing: 6) {
                Text("No Place Added Yet...")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Click \"+ Add Place\" to add a new place")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
    }
}
