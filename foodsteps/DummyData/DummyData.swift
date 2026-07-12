//
//  DummyData.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 11/07/26.
//
import SwiftUI

var jsonArrayCache: [[String: Any]] = []

func getRawDummyDataFromAssets(assetName: String) -> [[String: Any]] {
    
    if !jsonArrayCache.isEmpty {
        return jsonArrayCache
    }
    
    guard let asset = NSDataAsset(name: assetName) else {
        print("❌ Data Asset \(assetName) tidak ditemukan di Assets.xcassets")
        return []
    }
    
    do {
        if let jsonArray = try JSONSerialization.jsonObject(with: asset.data, options: []) as? [[String: Any]] {
            print("✅ Berhasil memuat data dari Assets: \(assetName)!")
            jsonArrayCache = jsonArray;
            return jsonArray
        }
    } catch {
        print("❌ Gagal parsing JSON dari Assets: \(error.localizedDescription)")
    }
    
    return []
}

//var dummyData = getRawDummyDataFromAssets(assetName: "dummy.json")
