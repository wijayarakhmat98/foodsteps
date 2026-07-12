//
//  WaypointAnnotationView.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 12/07/26.
//
import SwiftUI

struct WaypointAnnotationView: View {
    let waypoint: Waypoint
    let onTapCamera: () -> Void
    
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 6) {
            if let img = waypoint.image {
                // Preview Gambar melingkar bawaan di layar peta aplikasi
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 55, height: 55)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(hex: "#4B08B5"), lineWidth: 3))
                    .shadow(radius: 4)
            } else {
                ZStack {
                    Circle()
                        .stroke(Color(hex: "#4B08B5").opacity(0.35), lineWidth: 3)
                        .frame(width: 56, height: 56)
                        .scaleEffect(animate ? 1.6 : 1)
                        .opacity(animate ? 0 : 1)

                    Image(systemName: "camera.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Color(hex: "#4B08B5"))
                        .clipShape(Circle())
                        .shadow(radius: 4)
                        .onTapGesture {
                            onTapCamera()
                        }
                }
                .onAppear {
                    withAnimation(
                        .easeOut(duration: 1.4)
                        .repeatForever(autoreverses: false)
                    ) {
                        animate = true
                    }
                }
            }
        }
    }
}
