//
//  SearchView2.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 09/07/26.
//

import SwiftUI

import SwiftUI

struct SearchView2: View {
    let query: String
    @State private var scrollOffset: CGFloat = 0
    @State private var isSearchState: Bool = false
    
    // Inisialisasi ViewModel Baru
    @State private var viewModel = SearchViewModel()

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var isHeaderSticky: Bool {
        scrollOffset > 185
    }

    var body: some View {
        GeometryReader { globalGeometry in
            let topSafeArea = globalGeometry.safeAreaInsets.top

            ScrollView(showsIndicators: false) {
                ZStack(alignment: .top) {
                    
                    // MARK: - Hero Background & Mascot
                    ZStack(alignment: .bottomTrailing) {
                        Color.clear
                            .frame(height: 262)

                        Image("Mascot_4")
                            .resizable()
                            .scaledToFit()
                            .padding(.leading, 120)
                            .frame(width: 320, height: 182)
                            .scaleEffect(x: -1, y: 1)
                            .offset(x: 130)
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
                            VStack(alignment: .leading, spacing: 20) {
                                if viewModel.isLoading {
                                    ProgressView("Searching spots...")
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.top, 40)
                                }
                                else if (viewModel.filteredPlaces.isEmpty && viewModel.mapKitPlaces.isEmpty) || viewModel.searchQuery == "" {
                                    VStack(alignment: .center, spacing: 0) {
                                        Image("Mascot_3")
                                            .resizable()
                                            .frame(width: 310, height: 201)
                                        
                                        Text("Place Not found")
                                            .font(.subheadline)
                                            .fontWeight(.regular)
                                            .foregroundStyle(Color(hex: "#8E8E93"))
                                            .padding(.top, 20)
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                    .padding(.top, 60)
                                }
                                else {
                                    // 1. SECTION HASIL INTERNAL (JSON)
                                    if !viewModel.filteredPlaces.isEmpty {
                                        VStack(alignment: .leading, spacing: 14) {
//                                            Text("Internal Recommendations")
//                                                .font(.headline)
//                                                .foregroundColor(.secondary)
//                                                .padding(.horizontal, 16)
                                            
                                            ForEach(viewModel.filteredPlaces) { place in
                                                SearchFoodCard(culinaryPlace: place)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                    
                                    // 2. SECTION HASIL MAPKIT (APPLE MAPS)
//                                    if !viewModel.mapKitPlaces.isEmpty {
//                                        VStack(alignment: .leading, spacing: 12) {
//                                            Text("Results from Apple Maps")
//                                                .font(.headline)
//                                                .foregroundColor(.secondary)
//                                                .padding(.horizontal, 16)
//                                                .padding(.top, 10)
//
//                                            ForEach(viewModel.mapKitPlaces, id: \.self) { item in
//                                                VStack(alignment: .leading, spacing: 4) {
//                                                    Text(item.name ?? "Unknown Place")
//                                                        .font(.headline)
//                                                        .foregroundColor(.primary)
//                                                    Text(item.placemark.title ?? "")
//                                                        .font(.caption)
//                                                        .foregroundColor(.secondary)
//                                                }
//                                                .padding()
//                                                .frame(maxWidth: .infinity, alignment: .leading)
//                                                .background(Color(.systemGray6))
//                                                .cornerRadius(12)
//                                                .padding(.horizontal, 16)
//                                            }
//                                        }
//                                    }
                                }
                                
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 16)
                            .padding(.bottom, 40)
                            .background(Color.white)

                        }
                        header: {
                            // MARK: - SEARCH BAR
                            VStack(spacing: 0) {
                                HStack {
                                    HStack(spacing: 12) {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundStyle(.secondary)
                                        
                                        // onChange memicu pencarian realtime saat user mengetik teks
                                        TextField("Search", text: $viewModel.searchQuery)
                                            .onChange(of: viewModel.searchQuery) { _, newValue in
                                                viewModel.search(query: newValue)
                                            }
                                            .onSubmit {
                                                viewModel.search(query: viewModel.searchQuery)
                                            }
                                        
                                        Image(systemName: "mic.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(height: 44)
                                    .background(.white)
                                    .clipShape(Capsule())
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.top, isHeaderSticky ? topSafeArea + 10 : 10)
                            .padding(.bottom, 10)
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
            }
        }
        .onAppear() {
            if (query != "") {
                viewModel.search(query: query)
            }
        }
    }
}

#Preview {
    SearchView2(query: "")
}
