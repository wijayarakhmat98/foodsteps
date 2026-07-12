import SwiftUI
import MapKit

/// A reusable location-search sheet backing two flows that are otherwise
/// identical UI (search field + results list): adding a new Stop to the
/// trip, and setting/replacing the trip's meeting point. Bundled into one
/// mode-driven view instead of duplicating the search sheet twice.
struct StopMeetingPointSheetView: View {
    enum Kind {
        case stop
        case meetingPoint

        var navigationTitle: String {
            switch self {
            case .stop: return "Add a Place"
            case .meetingPoint: return "Meeting Point"
            }
        }

        var searchPlaceholder: String {
            switch self {
            case .stop: return "Search cafes & restaurants..."
            case .meetingPoint: return "Search a meeting point..."
            }
        }

        /// Which `LocationSearchService` mode to configure the completer
        /// with — `.foodOnly` restricts results to restaurants/cafes/bakeries
        /// for stops, `.anyPlace` allows any place for the meeting point.
        var searchMode: LocationSearchMode {
            switch self {
            case .stop: return .foodOnly
            case .meetingPoint: return .anyPlace
            }
        }
    }

    let kind: Kind
    @Bindable var searchService: LocationSearchService

    /// Shows a spinner instead of the clear button while a selected result
    /// is being resolved. Only meaningful for `.stop` (adding places can
    /// take a moment since we also check for duplicates).
    var isSearching: Bool = false

    /// Marks completions that duplicate something already on the trip.
    /// Only meaningful for `.stop`; the meeting point has no such concept.
    var isAlreadyAdded: (MKLocalSearchCompletion) -> Bool = { _ in false }

    let onSelect: (MKLocalSearchCompletion) -> Void
    let onDone: () -> Void

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField(kind.searchPlaceholder, text: $searchService.searchQuery)
                        .focused($isSearchFocused)
                    if isSearching {
                        ProgressView()
                    } else if !searchService.searchQuery.isEmpty {
                        Button {
                            searchService.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(.regularMaterial)

                List(searchService.completions, id: \.self) { completion in
                    Button {
                        onSelect(completion)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(completion.title).font(.headline)
                                Text(completion.subtitle).font(.subheadline).foregroundColor(.secondary)
                            }
                            Spacer()
                            if isAlreadyAdded(completion) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .foregroundColor(isAlreadyAdded(completion) ? .secondary : .primary)
                }
                .listStyle(.plain)
            }
            .navigationTitle(kind.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onDone)
                }
            }
            .onAppear {
                searchService.configure(for: kind.searchMode)
                if kind == .stop {
                    isSearchFocused = true
                }
            }
        }
    }
}
