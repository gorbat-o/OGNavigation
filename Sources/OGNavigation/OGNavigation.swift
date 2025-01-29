import SwiftUI

// MARK: - Route Protocol

public protocol NavigationRoute: Equatable, Hashable, Identifiable {}
public extension NavigationRoute {
    var id: String { "\(self.hashValue)" }
}

// MARK: - Presentation Option Enum

public enum NavigationPresentationOption: Equatable {
    case navigation(inSheet: Bool)
    case popover
    case fullscreenCover
    case sheet
}

// MARK: - Deeplink Handler

final public class NavigationDeeplinkHandler<T: NavigationRoute> {
    public init() {}
    
    func handleDeeplink(url: URL) -> (T, NavigationPresentationOption)? {
        fatalError("Handle the deeplink in your own subclass that implements this method.")
    }
}

// MARK: - Router Class

@Observable
final public class NavigationRouter<T: NavigationRoute>: Identifiable {
    public let id = UUID()
    
    var root: T
    var routes: [T] = []
    var presentedItem: NavigationPresentedItem<T>?
    
    var onDismiss: (() -> Void)?
    var deeplinkHandler: NavigationDeeplinkHandler<T>?
    
    weak var parent: NavigationRouter<T>?
    
    public init(root: T, deeplinkHandler: NavigationDeeplinkHandler<T>? = nil) {
        self.root = root
        self.deeplinkHandler = deeplinkHandler
    }
    
    func updateRoot(_ route: T) {
        root = route
        routes.removeAll()
    }
    
    public func present(_ route: T, inTab: T? = nil,option: NavigationPresentationOption = .navigation(inSheet: false), onDismiss: (() -> Void)? = nil, closePrevious: Bool = false) {
        switch option {
        case .navigation(let inSheet):
            if inSheet {
                if let presentedRouter = presentedItem?.router, presentedItem?.option == .sheet {
                    presentedRouter.push(route)
                } else {
                    let newRouter = NavigationRouter(root: route, deeplinkHandler: deeplinkHandler)
                    newRouter.onDismiss = onDismiss
                    newRouter.parent = self // Set parent
                    self.presentedItem = NavigationPresentedItem(router: newRouter, option: .sheet)
                }
            } else {
                push(route)
            }
        case .sheet, .fullscreenCover, .popover:
            if closePrevious {
                presentedItem = nil
            }
            let newRouter = NavigationRouter(root: route, deeplinkHandler: deeplinkHandler)
            newRouter.onDismiss = onDismiss
            newRouter.parent = self
            self.presentedItem = NavigationPresentedItem(router: newRouter, option: option)
        }
    }
    
    public func dismiss(_ option: NavigationPresentationOption? = nil) {
        switch option {
        case .fullscreenCover, .sheet, .popover:
            if presentedItem?.option == option {
                presentedItem = nil
            } else {
                presentedItem?.router.dismiss(option)
            }
        case .navigation:
            if !routes.isEmpty {
                pop()
            } else {
                parent?.dismiss(option)
            }
        case .none:
            if presentedItem != nil {
                presentedItem = nil
            } else if !routes.isEmpty {
                pop()
            } else {
                parent?.dismiss(option)
            }
        }
    }
    
    public func handleDeeplink(url: URL) {
        if let (route, option) = deeplinkHandler?.handleDeeplink(url: url) {
            present(route, option: option)
        }
    }
    
    private func push(_ route: T) {
        routes.append(route)
    }
    
    private func pop() {
        if !routes.isEmpty {
            routes.removeLast()
        }
    }
}

// MARK: - Presented Item

public struct NavigationPresentedItem<T: NavigationRoute>: Identifiable {
    public var id = UUID()
    var router: NavigationRouter<T>
    var option: NavigationPresentationOption
}

// MARK: - Base View

public struct NavigationBaseView<T: NavigationRoute, ContentView: View>: View {
    @Bindable private var router: NavigationRouter<T>
    private let contentBuilder: (T) -> ContentView
    
    public init(
        router: NavigationRouter<T>,
        @ViewBuilder content: @escaping (T) -> ContentView
    ) {
        self.router = router
        self.contentBuilder = content
    }
    
    public var body: some View {
        contentBuilder(router.root)
            .modifier(NavigationPresentationModifier(router: router, contentBuilder: contentBuilder))
            .environment(router)
            .onOpenURL { url in
                router.handleDeeplink(url: url)
            }
    }
}

// MARK: - Navigation View

public struct NavigationView<T: NavigationRoute, ContentView: View>: View {
    @Bindable private var router: NavigationRouter<T>
    private let contentBuilder: (T) -> ContentView
    
    public init(
        router: NavigationRouter<T>,
        @ViewBuilder content: @escaping (T) -> ContentView
    ) {
        self.router = router
        self.contentBuilder = content
    }
    
    public var body: some View {
        NavigationStack(path: $router.routes) {
            contentBuilder(router.root)
                .navigationDestination(for: T.self) { route in
                    contentBuilder(route)
                }
        }
        .modifier(NavigationPresentationModifier(router: router, contentBuilder: contentBuilder))
        .environment(router)
        .onOpenURL { url in
            router.handleDeeplink(url: url)
        }
    }
}

// MARK: - Presentation Modifier

public struct NavigationPresentationModifier<T: NavigationRoute, ContentView: View>: ViewModifier {
    @Bindable var router: NavigationRouter<T>
    let contentBuilder: (T) -> ContentView
    
    public func body(content: Content) -> some View {
        let popoverBinding = Binding<NavigationPresentedItem<T>?>(
            get: {
                if router.presentedItem?.option == .popover {
                    return router.presentedItem
                } else {
                    return nil
                }
            },
            set: { newValue in
                if newValue == nil {
                    router.presentedItem = nil
                    router.onDismiss?()
                }
            }
        )
        
        content
            .sheet(item: Binding(
                get: { router.presentedItem?.option == .sheet ? router.presentedItem : nil },
                set: { _ in }
            ), onDismiss: {
                router.presentedItem = nil
                router.onDismiss?()
            }) { item in
                NavigationView(router: item.router, content: contentBuilder)
            }
            .fullScreenCover(item: Binding(
                get: { router.presentedItem?.option == .fullscreenCover ? router.presentedItem : nil },
                set: { _ in }
            ), onDismiss: {
                router.presentedItem = nil
                router.onDismiss?()
            }) { item in
                NavigationView(router: item.router, content: contentBuilder)
            }
            .popover(
                item: popoverBinding,
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .top
            ) { item in
                NavigationView(router: item.router, content: contentBuilder)
            }
    }
}

// MARK: - Tab Router

@Observable
public final class NavigationTabRouter<T: NavigationRoute> {
    var tabs: [T]
    public var selected: T
    var routers: [NavigationRouter<T>]
    
    public init(tabs: [T], selected: T, deeplinkHandler: NavigationDeeplinkHandler<T>? = nil) {
        self.tabs = tabs
        self.selected = selected
        self.routers = tabs.map { NavigationRouter<T>(root: $0, deeplinkHandler: deeplinkHandler) }
    }
    
    public func updateSelectedTab(_ to: T) {
        selected = to
    }
    
    public func present(_ route: T, inTab: T? = nil, option: NavigationPresentationOption = .navigation(inSheet: false), onDismiss: (() -> Void)? = nil, closePrevious: Bool = false) {
        if let targetTab = inTab {
            // Switch to target tab first
            updateSelectedTab(targetTab)
            // Get the router for that tab
            if let index = tabs.firstIndex(of: targetTab) {
                routers[index].present(route, option: option, onDismiss: onDismiss, closePrevious: closePrevious)
            }
        } else {
            // Present in current tab
            if let index = tabs.firstIndex(of: selected) {
                routers[index].present(route, option: option, onDismiss: onDismiss, closePrevious: closePrevious)
            }
        }
    }
}

// MARK: - Tab View

public struct TabItem {
    public let title: String
    public let icon: String
    public let unselectedIcon: String?
    
    public init(
        title: String,
        icon: String,
        unselectedIcon: String? = nil
    ) {
        self.title = title
        self.icon = icon
        self.unselectedIcon = unselectedIcon
    }
}

// MARK: - Tab View

private struct TintKey: EnvironmentKey {
    static let defaultValue: Color = .blue
}

public extension EnvironmentValues {
    var tint: Color {
        get { self[TintKey.self] }
        set { self[TintKey.self] = newValue }
    }
}

public struct NavigatonTabView<T: NavigationRoute, ContentView: View, TabItem: View, CustomTabBar: View>: View {
    @Bindable private var router: NavigationTabRouter<T>
    private let contentBuilder: (T) -> ContentView
    private let tabItemBuilder: (T) -> TabItem
    private let customTabBarBuilder: ((Binding<T>, [T], Binding<Bool>, Binding<Bool>) -> CustomTabBar)?
    @Binding private var isCustomIconsActivated: Bool
    @Binding private var isCustomColorsActivated: Bool
    private let selectedTintColor: Color
    private let unselectedTintColor: Color
    
    public init(
        router: NavigationTabRouter<T>,
        isCustomIconsActivated: Binding<Bool> = .constant(true),
        isCustomColorsActivated: Binding<Bool> = .constant(true),
        selectedTintColor: Color = .purple,
        unselectedTintColor: Color = .gray,
        @ViewBuilder content: @escaping (T) -> ContentView,
        @ViewBuilder tabItem: @escaping (T) -> TabItem,
        @ViewBuilder customTabBar: @escaping (Binding<T>, [T], Binding<Bool>, Binding<Bool>) -> CustomTabBar
    ) {
        self.router = router
        self._isCustomIconsActivated = isCustomIconsActivated
        self._isCustomColorsActivated = isCustomColorsActivated
        self.selectedTintColor = selectedTintColor
        self.unselectedTintColor = unselectedTintColor
        self.contentBuilder = content
        self.tabItemBuilder = tabItem
        self.customTabBarBuilder = customTabBar
    }
    
    public init(
        router: NavigationTabRouter<T>,
        isCustomIconsActivated: Binding<Bool> = .constant(true),
        isCustomColorsActivated: Binding<Bool> = .constant(true),
        selectedTintColor: Color = .purple,
        unselectedTintColor: Color = .gray,
        @ViewBuilder content: @escaping (T) -> ContentView,
        @ViewBuilder tabItem: @escaping (T) -> TabItem
    ) where CustomTabBar == EmptyView {
        self.router = router
        self._isCustomIconsActivated = isCustomIconsActivated
        self._isCustomColorsActivated = isCustomColorsActivated
        self.selectedTintColor = selectedTintColor
        self.unselectedTintColor = unselectedTintColor
        self.contentBuilder = content
        self.tabItemBuilder = tabItem
        self.customTabBarBuilder = nil
    }
    
    public var body: some View {
        if let customTabBarBuilder {
            ZStack {
                NavigationView(router: getRouter(for: router.selected), content: contentBuilder)
                
                VStack {
                    Spacer()
                    customTabBarBuilder(
                        $router.selected,
                        router.tabs,
                        $isCustomIconsActivated,
                        $isCustomColorsActivated
                    )
                }
            }
            .environment(router)
        } else {
            TabView(selection: $router.selected) {
                ForEach(router.tabs, id: \.id) { tab in
                    NavigationView(router: getRouter(for: tab), content: contentBuilder)
                        .tabItem {
                            if isCustomIconsActivated {
                                tabItemBuilder(tab)
                                    .environment(\.tint, isCustomColorsActivated ? selectedTintColor : .blue)
                            } else {
                                tabItemBuilder(tab)
                            }
                        }
                        .tag(tab)
                }
            }
            .tint(isCustomColorsActivated ? selectedTintColor : .blue)
            .environment(router)
        }
    }
    
    private func getRouter(for tab: T) -> NavigationRouter<T> {
        guard let index = router.tabs.firstIndex(of: tab) else {
            fatalError("Tab not found")
        }
        return router.routers[index]
    }
}
