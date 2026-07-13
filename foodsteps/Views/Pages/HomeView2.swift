import SwiftUI

struct HomeView2: View {
    @State private var search = ""
    
    @State private var scrollOffset: CGFloat = 0
    
    @State private var isSearchState: Bool = false
    
    @State private var viewModel = HomeViewModel()

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var isHeaderSticky: Bool {
        scrollOffset > 185
    }
    
    init() {
        self.viewModel.loadCulinaryPlaces()
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

                        Image("Mascot_2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 320, height: 182)
                            .scaleEffect(x: -1, y: 1)
                            .offset(x: 120)
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
                            Text("Hi Jalma!")
                                .font(.largeTitle)
                                .bold()

                            Text("Time for a new **foodstep!**\nWhere to next?")
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 96)
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.white)

                        // MARK: - Sticky Section
                        Section {
                            VStack(spacing: 20) {
                                // Recently
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Recently Foodie Steps")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color(hex: "#4B08B5"))
                                        Spacer()
//                                        Image(systemName: "chevron.right")
//                                            .foregroundStyle(Color(hex: "#4B08B5"))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 20)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            if viewModel.isLoading {
                                                ForEach(0..<4, id: \.self) { _ in
                                                    HorizontalFoodCardSkeleton()
                                                }
                                            } else {
                                                // Pas data beres di-load, ambil indeks 17-27 secara aman
                                                ForEach(viewModel.culinaryPlaces.dropFirst(17).prefix(10)) { place in
                                                    HorizontalFoodCard(culinaryPlace: place)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                    }
                                }

                                // Popular
                                Text("Popular in your area")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color(hex: "#4B08B5"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)

                                LazyVGrid(columns: columns, spacing: 12) {
                                    if viewModel.isLoading {
                                        ForEach(0..<4, id: \.self) { _ in
                                            VerticalFoodCardSkeleton()
                                        }
                                    } else {
                                        ForEach(viewModel.culinaryPlaces) { place in
                                            VerticalFoodCard(culinaryPlace: place)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 20)
                            }
                            .background(Color.white)

                        } header: {
                            // MARK: - SEARCH BAR
                            VStack(spacing: 0) {
                                HStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(.secondary)

                                    TextField("Search", text: $search)
                                        .onSubmit {
                                            AppRoute.push(.search(query: search))
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
    HomeView2()
}
