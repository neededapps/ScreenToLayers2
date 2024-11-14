
import Foundation
import SwiftUI

// MARK: -

private struct PreviewEnvironmentsModifier: ViewModifier {

    // MARK: States

    @StateObject
    private var userSettings = UserSettings()
    
    @State
    private var coffeePurchaser = CoffeePurchaser()
    
    @State
    private var captureManager = CaptureManager()
    
    // MARK: Views

    public func body(content: Content) -> some View {
        content.environmentObject(userSettings)
            .environment(coffeePurchaser)
            .environment(captureManager)
    }
}

// MARK: -

extension View {

    // MARK: Modifier

    public func previewEnvironments() -> some View {
        modifier(PreviewEnvironmentsModifier())
    }
}

// MARK: -

public struct PreviewEnvironmentsData {

    // MARK: States

    public let userSettings: UserSettings
    
    public let coffeePurchaser: CoffeePurchaser
    
    public let captureManager: CaptureManager
}

// MARK: -

public struct PreviewEnvironmentsInnerView<Content: View>: View {
    
    // MARK: States

    @EnvironmentObject
    private var userSettings: UserSettings
    
    @Environment(CoffeePurchaser.self)
    private var coffeePurchaser: CoffeePurchaser
    
    @Environment(CaptureManager.self)
    private var captureManager: CaptureManager
    
    public var content: (PreviewEnvironmentsData) -> Content
    
    // MARK: Views

    public var body: some View {
        let data = PreviewEnvironmentsData(
            userSettings: userSettings,
            coffeePurchaser: coffeePurchaser,
            captureManager: captureManager)
        content(data)
    }
}

// MARK: -

public struct PreviewEnvironmentsWrapView<Content: View>: View {
    
    // MARK: States

    public var content: (PreviewEnvironmentsData) -> Content
    
    // MARK: Views

    public var body: some View {
        PreviewEnvironmentsInnerView(content: content)
            .previewEnvironments()
    }
}
