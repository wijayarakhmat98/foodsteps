//
//  SearchView.swift
//  strava-like
//
//  Created by Nazwa Sapta Pradana on 07/07/26.
//

import SwiftUI

struct SearchView: View {
    
    @State var search: String = ""
    
    @State private var scrollOffset: CGFloat = 0

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var isHeaderSticky: Bool {
        scrollOffset > 185
    }
    
    init(query: String?) {
        self._search = State(initialValue: query ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text("What’s next?")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 36)
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(.white)
            .background(
                Color(hex: "#4B08B5")
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 40,
                            style: .continuous
                        )
                    )
            )
            
            HStack(alignment: .top,) {
                HStack(spacing: 15) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color(hex: "#727272"))
                    
                    TextField("Search", text: $search)
                    
                    Image(systemName: "mic.fill")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(Color(hex: "#E5E5EA"))
                .foregroundStyle(Color(hex: "#727272"))
                .clipShape(Capsule())
                .padding(.horizontal, 16)
                
                Button(action: {
                    print("Button Tapped!")
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark")
                    }
                }
                .padding(10)
                .foregroundStyle(.black)
                .glassEffect()
            }
            .padding(.top, 14)
            .padding(.horizontal, 18)
            
            ScrollView(.vertical, showsIndicators: true) {
                
                LazyVGrid(
                    columns: columns,
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(restaurants.indices, id: \.self) { index in
                        let data = restaurants[index]
                        
//                        VerticalFoodCard(
//                            url: data["image_url"] as? String ?? "",
//                            title: data["name"] as? String ?? "",
//                            type: data["type"] as? String ?? "",
//                            comment: data["comment"] as? String ?? "",
//                            rating: data["rating"] as? Double ?? 4.7,
//                        )
                    }
                }
                .padding(.bottom, 16)
                .padding(.horizontal, 16)
                
            }
                .padding(.horizontal, 0)
                .padding(.top, 24)
//                .contentMargins(42)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SearchView(query: "Test")
}
