//
//  maxWords.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 11/07/26.
//

import Foundation

extension String {
    func limitToWords(_ maxWords: Int) -> String {
        let words = self.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        if words.count <= maxWords {
            return self
        } else {
            let truncated = words.prefix(maxWords).joined(separator: " ")
            return truncated + "..."
        }
    }
}
