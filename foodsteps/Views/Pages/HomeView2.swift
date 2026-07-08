import SwiftUI

struct HomeView2: View {
    @State private var search = ""
    // Menggunakan state offset hasil tangkapan iOS 17 native API
    @State private var scrollOffset: CGFloat = 0

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // Evaluasi status sticky berdasarkan offset scroll
    // Jika scroll sudah berjalan lebih dari 105pt, nyalakan status sticky
    private var isHeaderSticky: Bool {
        scrollOffset > 185
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
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(Color(hex: "#4B08B5"))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 20)

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(0..<10, id: \.self) { index in
                                                let data = restaurants[index + 5]
                                                HorizontalFoodCard(
                                                    url: data["image_url"] as? String ?? "",
                                                    title: data["name"] as? String ?? "",
                                                    type: data["type"] as? String ?? "",
                                                    rating: data["rating"] as? Double ?? 4.7
                                                )
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
                                    ForEach(restaurants.indices, id: \.self) { index in
                                        let data = restaurants[index]
                                        VerticalFoodCard(
                                            url: data["image_url"] as? String ?? "",
                                            title: data["name"] as? String ?? "",
                                            type: data["type"] as? String ?? "",
                                            comment: data["comment"] as? String ?? "",
                                            rating: data["rating"] as? Double ?? 4.7
                                        )
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
