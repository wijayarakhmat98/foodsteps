//
//  ImageLoader.swift
//  strava-like
//
//  Created by Nazwa Sapta Pradana on 06/07/26.
//


import SwiftUI
import Combine

@MainActor
final class ImageLoader: ObservableObject {

    @Published var image: UIImage?

    private var currentTask: Task<Void, Never>?
    private var currentURL: String?

    func load(urlString: String) {

        // kalau URL sama, jangan reload
        if currentURL == urlString, image != nil {
            return
        }

        currentURL = urlString
        currentTask?.cancel()

        // cache hit
        if let cached = ImageCache.shared.get(urlString) {
            image = cached
            return
        }

        guard let url = URL(string: urlString) else { return }

        currentTask = Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)

                guard let img = UIImage(data: data) else { return }

                ImageCache.shared.set(img, for: urlString)

                guard !Task.isCancelled else { return }

                image = img

            } catch {
                // optional: handle error state
            }
        }
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }
}
