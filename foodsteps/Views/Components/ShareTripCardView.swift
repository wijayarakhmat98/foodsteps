//
//  ShareTripCardView.swift
//  foodsteps
//
//  Created by Willy Tanuwijaya on 13/07/26.
//


//
//  ShareTripCardView.swift
//  foodsteps
//
//  A polished, brand-styled summary card rendered to an image (via
//  ImageRenderer) and shared directly through `CustomShareSheetView`.
//  Designed to be self-contained and fixed-width so it renders
//  consistently regardless of the device it's captured on.
//

import SwiftUI

struct ShareTripCardView: View {
    let tripName: String
    let dateText: String
    let participantName: String
    let distanceKm: Double
    let placeCount: Int
    let stopNames: [String]

    private let cardWidth: CGFloat = 360

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 18) {
                statsRow

                if !stopNames.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Places Visited")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)

                        VStack(spacing: 8) {
                            ForEach(Array(stopNames.enumerated()), id: \.offset) { index, name in
                                stopRow(index: index, name: name)
                            }
                        }
                    }
                }

                footer
            }
            .padding(20)
        }
        .frame(width: cardWidth)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            LinearGradient(
                colors: [Color.brandPurple, Color.brandPurple.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "fork.knife.circle.fill")
                        .foregroundColor(.white.opacity(0.9))
                    Text("FoodSteps")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white.opacity(0.9))
                        .textCase(.uppercase)
                        .tracking(1.2)
                }

                Text(tripName)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                Text(dateText)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .frame(height: 120)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: String(format: "%.1f km", distanceKm), label: "Distance")
            Divider().frame(height: 32)
            statItem(value: "\(placeCount)", label: placeCount == 1 ? "Place" : "Places")
            Divider().frame(height: 32)
            statItem(value: participantName, label: "By")
        }
        .padding(.vertical, 4)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.brandPurple)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stops

    private func stopRow(index: Int, name: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.brandPurple)
                    .frame(width: 22, height: 22)
                Text("\(index + 1)")
                    .font(.caption2.bold())
                    .foregroundColor(.white)
            }
            Text(name)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.brandPurpleLight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Image(systemName: "figure.walk")
                .foregroundColor(.brandOrange)
            Text("Made with FoodSteps")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.top, 4)
    }
}