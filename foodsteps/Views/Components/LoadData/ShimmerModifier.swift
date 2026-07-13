//
//  ShimmerModifier.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 11/07/26.
//


import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color(.systemGray6),
                            Color(.systemGray5),
                            Color(.systemGray6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .mask(content)
                    .offset(x: phase * geo.size.width)
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            phase = 1.5
                        }
                    }
                }
            )
    }
}

// Extension biar manggilnya gampang (.shimmerLoading())
extension View {
    func shimmerLoading() -> some View {
        self.modifier(ShimmerModifier())
    }
}