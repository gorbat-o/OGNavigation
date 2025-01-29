import OGNavigation

enum AppRoute: NavigationRoute {
    // TABS
    case homeTab
    case dataTab
    case accountTab
    
    // VIEWS
    case dataDetail(id: Int)
    case profile
    
    var id: String {
        switch self {
            // TABS
        case .homeTab: return "homeTab"
        case .dataTab: return "dataTab"
        case .accountTab: return "settingsTab"
            
            // VIEWS
        case .dataDetail(let id): return "dataDetail_\(id)"
        case .profile: return "profile"
        }
    }
}
