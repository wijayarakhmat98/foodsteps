import SwiftUI

extension Color {
    /// The deep purple used for headers, status banners, and timeline connectors.
    /// Matches the header purple in the design mockups (#4B08B5).
    static let brandPurple = Color(hex: "#4B08B5")

    /// A lighter tint of the brand purple, used for inactive stop row backgrounds
    /// and the back-button pill on top of the purple header.
    static let brandPurpleLight = Color(red: 0.93, green: 0.90, blue: 0.98)

    /// The warm accent used to highlight the currently active/ongoing stop.
    static let brandOrangeLight = Color(red: 1.0, green: 0.93, blue: 0.85)

    /// The orange accent used for primary actions (Start Trip, Add Place),
    /// edit links, and heart/vote icons. Matches the app's tab tint (#FF8F14).
    static let brandOrange = Color(hex: "#FF8F14")
}
