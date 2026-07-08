import SwiftUI

/// A single row in a trip's stop list: a circular photo avatar with a
/// numbered badge overlapping its corner, sitting on a thick purple
/// connector line, followed by the place's name/subtitle.
/// Used by both `ActiveRouteView` (Ongoing/Paused) and `TripFinishedView`.
struct StopTimelineRow: View {
    let index: Int
    let title: String
    let subtitle: String
    let isLast: Bool

    /// Highlights the row (e.g. the stop currently being visited).
    var isHighlighted: Bool = false
    /// The photo shown inside the circular avatar, if one exists yet.
    var image: Image? = nil
    /// SF Symbol shown in the avatar when there's no photo.
    var placeholderSystemImage: String = "photo"
    /// When set, this icon replaces the numbered badge (e.g. a flag for "Start").
    var badgeSystemImage: String? = nil

    private let lineWidth: CGFloat = 4
    private let avatarSize: CGFloat = 52
    private let badgeSize: CGFloat = 22

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Connector: circular photo avatar with a numbered badge, plus
            // the thick line down to the next stop.
            VStack(spacing: 0) {
                ZStack(alignment: .bottomTrailing) {
                    avatar

                    ZStack {
                        Circle()
                            .fill(Color.brandPurple)
                            .frame(width: badgeSize, height: badgeSize)
                        if let badgeSystemImage {
                            Image(systemName: badgeSystemImage)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                }
                .frame(width: avatarSize, height: avatarSize)

                if !isLast {
                    Rectangle()
                        .fill(Color.brandPurple)
                        .frame(width: lineWidth)
                        .frame(minHeight: 30)
                }
            }
            .frame(width: avatarSize)

            // Name + subtitle card.
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isHighlighted ? Color.brandOrangeLight : Color.brandPurpleLight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, (avatarSize - 40) / 2)
            .padding(.bottom, isLast ? 0 : 10)
        }
    }

    @ViewBuilder
    private var avatar: some View {
        Circle()
            .fill(Color(uiColor: .systemGray5))
            .overlay {
                if let image {
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                } else {
                    Image(systemName: placeholderSystemImage)
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            }
    }
}
