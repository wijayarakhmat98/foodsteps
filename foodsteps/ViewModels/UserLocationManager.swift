//
//  LocationManager.swift
//  foodsteps
//
//  Created by Nazwa Sapta Pradana on 12/07/26.
//


import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var liveCoordinates: [CLLocationCoordinate2D] = []
    
    @Published var livePathCoordinates: [CLLocationCoordinate2D] = []
    @Published var isRecording: Bool = false
    @Published var isPaused: Bool = false // 👈 Tambah status Pause
    @Published var totalDistance: Double = 0.0
    @Published var routePolyline: MKPolyline?
    
    override init() {
        super.init()
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" { return }
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 2
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
    }
    
    func startRecording() {
        self.liveCoordinates.removeAll()
        DispatchQueue.main.async {
            self.livePathCoordinates.removeAll()
            self.routePolyline = nil
            self.totalDistance = 0.0
            self.isPaused = false
            self.isRecording = true
        }
    }
    
    // 👈 Fungsi Pause Baru
    func pauseRecording() {
        DispatchQueue.main.async {
            self.isPaused = true
        }
    }
    
    // 👈 Fungsi Resume Baru
    func resumeRecording() {
        DispatchQueue.main.async {
            self.isPaused = false
        }
    }
    
    func stopRecording() {
        DispatchQueue.main.async {
            self.isRecording = false
            self.isPaused = false
            if self.liveCoordinates.count > 1 {
                self.routePolyline = MKPolyline(coordinates: self.liveCoordinates, count: self.liveCoordinates.count)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Hanya rekam jika aplikasi sedang RECORDING dan TIDAK DI-PAUSE
        if isRecording && !isPaused {
            if let lastCoordinate = liveCoordinates.last {
                let previousLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
                let distanceInMeters = location.distance(from: previousLocation)
                
                DispatchQueue.main.async {
                    self.totalDistance += (distanceInMeters / 1000.0)
                }
            }
            
            liveCoordinates.append(location.coordinate)
            
            DispatchQueue.main.async {
                self.livePathCoordinates.append(location.coordinate)
            }
        }
    }
}