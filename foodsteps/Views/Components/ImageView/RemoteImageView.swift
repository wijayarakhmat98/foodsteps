//
//  RemoteImageView.swift
//  strava-like
//
//  Created by Nazwa Sapta Pradana on 06/07/26.
//


import SwiftUI

struct RemoteImageView: View {
    let url: String
    var height: CGFloat = 120
    var cornerRadius: CGFloat = 12

    @StateObject private var loader = ImageLoader()

    var body: some View {
        GeometryReader { geo in
            Group {
                if let img = loader.image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    SkeletonView()
                }
            }
            .frame(width: geo.size.width, height: height)
            .clipped()
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .task(id: url) {
            loader.load(urlString: url)
        }
    }
}
