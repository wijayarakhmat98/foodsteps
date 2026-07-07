import SwiftUI
import MapKit

struct ActiveRouteView: View {

    var routePlanner: RoutePlanner
    var locationManager: LocationManager

    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var followUser = true

    var body: some View {

        ZStack {

            Map(position: $mapPosition) {

                UserAnnotation()

                if let route = routePlanner.currentNavigationLeg {

                    MapPolyline(route)
                        .stroke(.blue, lineWidth: 6)

                }

                ForEach(routePlanner.orderedStops) { stop in

                    Marker(
                        stop.name,
                        coordinate: stop.mapItem.placemark.coordinate
                    )

                }

            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea()

            VStack {

                Spacer()

                navigationCard

            }

        }
        .onAppear {

            if !routePlanner.isNavigating {

                routePlanner.startNavigation()

            }

            if let stop = routePlanner.currentNavigationStop {

                locationManager.monitorArrival(
                    at: stop.mapItem.placemark.coordinate,
                    identifier: stop.name
                )

            }

            updateCamera()

            locationManager.onLocationUpdate = { _ in

                DispatchQueue.main.async {

                    routePlanner.updateNavigation(
                        using: locationManager
                    )

                    updateCamera()

                }

            }

            locationManager.onRegionEntered = { _ in

                DispatchQueue.main.async {

                    routePlanner.updateNavigation(
                        using: locationManager
                    )

                    updateCamera()

                }

            }

        }

        .onDisappear {

            locationManager.onLocationUpdate = nil
            locationManager.onRegionEntered = nil

        }

        .onChange(of: routePlanner.currentLegIndex) { _, _ in

            updateCamera()

        }

    }

    private var navigationCard: some View {

        VStack(spacing: 12) {

            if let stop = routePlanner.currentNavigationStop {

                Text("Heading to")
                    .font(.caption)

                Text(stop.name)
                    .font(.headline)

            }

            HStack {

                Button(routePlanner.isPaused ? "Resume" : "Pause") {

                    if routePlanner.isPaused {

                        routePlanner.resumeNavigation()

                    } else {

                        routePlanner.pauseNavigation()

                    }

                }

                .buttonStyle(.borderedProminent)

                Button("Next Stop") {

                    if routePlanner.advanceToNextStop() {

                        if let next = routePlanner.currentNavigationStop {

                            locationManager.monitorArrival(
                                at: next.mapItem.placemark.coordinate,
                                identifier: next.name
                            )

                        }

                    }

                }

                .buttonStyle(.bordered)

            }

        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding()

    }

    private func updateCamera() {

        guard followUser else { return }

        guard let location = locationManager.currentLocation else { return }

        mapPosition = .camera(

            MapCamera(

                centerCoordinate: location,

                distance: 700,

                heading: 0,

                pitch: 60

            )

        )

    }

}
