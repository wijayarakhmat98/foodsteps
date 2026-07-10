//
//  SearchView2.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 09/07/26.
//

import SwiftUI

struct SearchView2: View {
    @State private var search = ""
    
    @State private var scrollOffset: CGFloat = 0
    
    @State private var isSearchState: Bool = false

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // Evaluasi status sticky berdasarkan offset scroll
    // Jika scroll sudah berjalan lebih dari 105pt, nyalakan status sticky
    private var isHeaderSticky: Bool {
        scrollOffset > 185
    }
    
    init(query: String?) {
        self._search = State(initialValue: query ?? "")
    }

    var body: some View {
        GeometryReader { globalGeometry in
            let topSafeArea = globalGeometry.safeAreaInsets.top

            ScrollView(showsIndicators: false) {
                ZStack(alignment: .top) {
                    
                    // MARK: - Hero Background & Mascot (Struktur Asli Kamu)
                    ZStack(alignment: .bottomTrailing) {
                        Color.clear
                            .frame(height: 262)

                        Image("Mascot_4")
                            .resizable()
                            .scaledToFit()
                            .padding(.leading, 120)
                            .frame(width: 320, height: 182)
                            
                    }
                    .background(
                        Color(hex: "#4B08B5")
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 40,
                                    style: .continuous
                                )
                            )
                    )
                    
                    // MARK: - Konten Utama
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        
                        // Greeting Text
                        VStack(alignment: .leading) {
                            Text("What's Next")
                                .font(.largeTitle)
                                .bold()
                                .padding(.top, 40)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 96)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.white)

                        // MARK: - Sticky Section
                        Section {
                                // Recently
                                ScrollView(.horizontal, showsIndicators: false) {
                                    VStack(spacing: 16) {
                                        ForEach(0..<10, id: \.self) { index in
                                            let data = restaurants[index + 5]
                                            SearchFoodCard()
//                                            (
//                                                url: data["image_url"] as? String ?? "",
//                                                title: data["name"] as? String ?? "",
//                                                type: data["type"] as? String ?? "",
//                                                rating: data["rating"] as? Double ?? 4.7
//                                            )
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 40)
                                    .padding(.top, 16)
                                    .background(Color.white)
                                }

                        } header: {
                            // MARK: - SEARCH BAR
                            VStack(spacing: 0) {
                                HStack() {
                                    HStack(spacing: 12) {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundStyle(.secondary)
                                        
                                        TextField("Search", text: $search)
                                            .onSubmit {
                                                AppRoute.push(.search(query: ""))
                                            }
                                        
                                        Image(systemName: "mic.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(height: 44)
                                    .background(.white)
                                    .clipShape(Capsule())
                                    .padding(.leading, 16)
                                    .padding(.trailing, 16)
                                    
                                    Button(action: {
                                        print("Button Tapped!")
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "xmark")
                                                .font(.title3)
                                        }
                                    }
                                    .padding(14)
                                    .foregroundStyle(.black)
                                    .glassEffect()
                                    .padding(.trailing, 16)
                                }
                            }
                            // Mengatur ganjalan atas agar pas di bawah dynamic island hanya saat status sticky aktif
                            .padding(.top, isHeaderSticky ? topSafeArea + 10 : 10)
                            .padding(.bottom, 10)
                            // Ubah warna background container terluar
                            .background(isHeaderSticky ? Color(hex: "#4B08B5") : Color.clear)
                            .animation(.easeOut(duration: 0.15), value: isHeaderSticky)
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // MARK: - NATIVE SCROLL TRACKER (iOS 17+)
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                return geometry.contentOffset.y
            } action: { oldValue, newValue in
                self.scrollOffset = newValue
                //print("Scroll Offset Terdeteksi: \(scrollOffset) | Sticky: \(isHeaderSticky)")
            }
        }
    }
}

#Preview {
    SearchView2(query: "Hello World")
}
