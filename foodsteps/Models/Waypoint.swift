struct Waypoint: Identifiable {
    var id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    var image: UIImage?
}