//
//  ImageMemoryCache.swift
//  strava-like
//
//  Created by Nazwa Sapta Pradana on 06/07/26.
//


import UIKit

@MainActor
final class ImageCache {
    static let shared = ImageCache()

    private var storage: [String: UIImage] = [:]
    private var order: [String] = []

    private let maxItems = 50

    private init() {}

    func get(_ key: String) -> UIImage? {
        guard let image = storage[key] else { return nil }

        // update LRU order
        if let index = order.firstIndex(of: key) {
            order.remove(at: index)
            order.append(key)
        }

        return image
    }

    func set(_ image: UIImage, for key: String) {
        // update existing
        if storage[key] != nil {
            storage[key] = image
            _ = get(key)
            return
        }

        // evict oldest if full
        if storage.count >= maxItems, let oldest = order.first {
            storage.removeValue(forKey: oldest)
            order.removeFirst()
        }

        storage[key] = image
        order.append(key)
    }

    func clear() {
        storage.removeAll()
        order.removeAll()
    }
}
