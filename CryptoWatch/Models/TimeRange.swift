enum TimeRange: String, CaseIterable, Identifiable {
    case day = "1D"
    case week = "7D"
    case month = "1M"
    case year = "1A"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }
}
