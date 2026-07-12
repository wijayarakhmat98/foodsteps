//
//  SkeletonView.swift
//  strava-like
//
//  Created by Nazwa Sapta Pradana on 06/07/26.
//

import SwiftUI

struct SkeletonView: View {
    @State private var move = false

    var body: some View {
        LinearGradient(
            colors: [
                Color.gray.opacity(0.2),
                Color.gray.opacity(0.3),
                Color.gray.opacity(0.2)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
                .fill(Color.white)
                .rotationEffect(.degrees(20))
                .offset(x: move ? 300 : -300)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                move = true
            }
        }
    }
}
