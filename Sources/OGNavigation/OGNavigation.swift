import SwiftUI

// MARK: - Protocols & Types

public protocol NavigationRoute: Equatable, Hashable, Identifiable {}
public extension NavigationRoute {
    var id: String { "\(self.hashValue)" }
}

public enum NavigationPresentationOption: Equatable {
    case navigation(inSheet: Bool)
    case popover
    case fullscreenCover
    case sheet
}

public struct NavigationPresentedItem<T: NavigationRoute>: Identifiable {
    public var id = UUID()
    var router: NavigationRouter<T>
    var option: NavigationPresentationOption
}

public struct TabItem {
    public let title: String
    public let icon: String
    public let unselectedIcon: String?

    public init(title: String, icon: String, unselectedIcon: String? = nil) {
        self.title = title
        self.icon = icon
        self.unselectedIcon = unselectedIcon
    }
}

// MARK: - Core Navigation Classes

@Observable
public final class NavigationRouter<T: NavigationRoute>: Identifiable {
    public let id = UUID()
    var root: T
    var routes: [T] = []
    var presentedItem: NavigationPresentedItem<T>?
    
    var onDismiss: (() -> Void)? 
    var onDismissCount: Int = 0

    var deeplinkHandler: NavigationDeeplinkHandler<T>?
    weak var parent: NavigationRouter<T>?

    public init(root: T, deeplinkHandler: NavigationDeeplinkHandler<T>? = nil) {
        self.root = root
        self.deeplinkHandler = deeplinkHandler
    }

    deinit {
        if onDismissCount == 0 {
            onDismissCount += 1
            onDismiss?()
            debugPrint("NavigationRouter deinitialized -> onDismiss called")
        } else {
            debugPrint("NavigationRouter deinitialized -> onDismiss not called")
        }
        debugPrint("NavigationRouter deinitialized")
    }

    func updateRoot(_ route: T) {
        root = route
        routes.removeAll()
    }

    public func present(
        _ route: T,
        inTab: T? = nil,
        option: NavigationPresentationOption = .navigation(inSheet: false),
        onDismiss: (() -> Void)? = nil,
        closePrevious: Bool = false
    ) {
        switch option {
        case .navigation(let inSheet):
            if inSheet {
                if let presentedRouter = presentedItem?.router, presentedItem?.option == .sheet {
                    presentedRouter.push(route)
                } else {
                    createAndPresent(route, option: .sheet, onDismiss: onDismiss)
                }
            } else {
                push(route)
            }
        case .sheet, .fullscreenCover, .popover:
            if closePrevious {
                presentedItem = nil
            }
            createAndPresent(route, option: option, onDismiss: onDismiss)
        }
    }

    public func dismiss(_ option: NavigationPresentationOption? = nil) {
        switch option {
        case .fullscreenCover, .sheet, .popover:
            if presentedItem?.option == option {
                presentedItem = nil
            } else {
                parent?.dismiss(option)
            }
        case .navigation:
            !routes.isEmpty ? pop() : parent?.dismiss(option)
        case .none:
            if presentedItem != nil {
                presentedItem = nil
            } else if !routes.isEmpty {
                pop()
            } else {
                parent?.dismiss(option)
            }
        }
        onDismissCount += 1
        onDismiss?()
    }

    public func handleDeeplink(url: URL) {
        if let (route, option) = deeplinkHandler?.handleDeeplink(url: url) {
            present(route, option: option)
        }
    }

    private func createAndPresent(_ route: T, option: NavigationPresentationOption, onDismiss: (() -> Void)?) {
        let newRouter = NavigationRouter(root: route, deeplinkHandler: deeplinkHandler)
        newRouter.onDismiss = onDismiss
        newRouter.parent = self
        presentedItem = NavigationPresentedItem(router: newRouter, option: option)
    }

    private func push(_ route: T) {
        routes.append(route)
    }

    private func pop() {
        if !routes.isEmpty { routes.removeLast() }
    }
}

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

    public func present(
        _ route: T,
        inTab: T? = nil,
        option: NavigationPresentationOption = .navigation(inSheet: false),
        onDismiss: (() -> Void)? = nil,
        closePrevious: Bool = false
    ) {
        if let targetTab = inTab {
            updateSelectedTab(targetTab)
            if let idx = tabs.firstIndex(of: targetTab) {
                routers[idx].present(route, option: option, onDismiss: onDismiss, closePrevious: closePrevious)
            }
        } else {
            if let idx = tabs.firstIndex(of: selected) {
                routers[idx].present(route, option: option, onDismiss: onDismiss, closePrevious: closePrevious)
            }
        }
    }

    public func resetToRoot(for tab: T) {
        if let idx = tabs.firstIndex(of: tab) {
            while !routers[idx].routes.isEmpty {
                routers[idx].dismiss()
            }
            routers[idx].presentedItem = nil
        }
    }
}

// MARK: - Views

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

public struct OGNavigationView<T: NavigationRoute, ContentView: View>: View {
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

public struct NavigationTabView<T: NavigationRoute, ContentView: View, TabItem: View, CustomTabBar: View>: View {
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
                OGNavigationView(router: getRouter(for: router.selected), content: contentBuilder)
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
                    OGNavigationView(router: getRouter(for: tab), content: contentBuilder)
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

// MARK: - Modifiers & Environment

public struct NavigationPresentationModifier<T: NavigationRoute, ContentView: View>: ViewModifier {
    @Bindable var router: NavigationRouter<T>
    let contentBuilder: (T) -> ContentView

    public func body(content: Content) -> some View {
        let popoverBinding = Binding<NavigationPresentedItem<T>?>(
            get: { router.presentedItem?.option == .popover ? router.presentedItem : nil },
            set: {
                if $0 == nil {
                    router.presentedItem = nil
                    router.onDismissCount += 1
                    router.onDismiss?()
                }
            }
        )
        let sheetBinding = Binding<NavigationPresentedItem<T>?>(
            get: { router.presentedItem?.option == .sheet ? router.presentedItem : nil },
            set: {
                if $0 == nil {
                    router.presentedItem = nil
                    router.onDismissCount += 1
                    router.onDismiss?()
                }
            }
        )
        content
            .sheet(item: sheetBinding) { item in
                OGNavigationView(router: item.router, content: contentBuilder)
            }
            .fullScreenCover(
                item: Binding(
                    get: { router.presentedItem?.option == .fullscreenCover ? router.presentedItem : nil },
                    set: { _ in }
                ),
                onDismiss: {
                    router.onDismissCount += 1
                    router.onDismiss?()
                }
            ) { item in
                OGNavigationView(router: item.router, content: contentBuilder)
            }
            .popover(
                item: popoverBinding,
                attachmentAnchor: .rect(.rect(.init(x: 30, y: 60, width: 50, height: 200))),
                arrowEdge: .top
            ) { item in
                OGNavigationView(router: item.router, content: contentBuilder)
            }
    }
}

private struct TintKey: EnvironmentKey {
    static let defaultValue: Color = .blue
}

public extension EnvironmentValues {
    var tint: Color {
        get { self[TintKey.self] }
        set { self[TintKey.self] = newValue }
    }
}

// MARK: - Deeplink Handling

public final class NavigationDeeplinkHandler<T: NavigationRoute> {
    public init() {}
    func handleDeeplink(url: URL) -> (T, NavigationPresentationOption)? {
        fatalError("Implement in subclass.")
    }
}
