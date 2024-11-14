
import SwiftUI
import StoreKit

public struct MenuBarContentView: View {
    
    // MARK: States
    
    @EnvironmentObject
    private var userSettings: UserSettings
    
    @Environment(CaptureManager.self)
    private var captureManager
    
    @Environment(CoffeePurchaser.self)
    private var coffeePurchaser
    
    @Environment(\.openSettings)
    private var openSettings
    
    @Environment(\.openWindow)
    private var openWindow
    
    @Environment(\.openURL)
    private var openURL
    
    @Environment(\.requestReview)
    private var requestReview
    
    // MARK: Views
    
    public var body: some View {
        Button(NSScreen.screens.count > 1 ? "Capture All Screens" : "Capture Screen") {
            captureManager.captureScreenNow(request: userSettings.captureRequest)
            guard userSettings.canAskForAppStoreReview() else { return }
            MainActor.run(in: .seconds(1.0)) { requestReview() }
        }
        .disabled(!captureManager.canCapture(request: userSettings.captureRequest))
        Button("Capture with a Delay") {
            captureManager.captureScreenWithDelay(request: userSettings.captureRequest)
            guard userSettings.canAskForAppStoreReview() else { return }
            MainActor.run(in: .seconds(4.0)) { requestReview() }
        }
        .disabled(!captureManager.canCapture(request: userSettings.captureRequest))
        Divider()
        Button("Open the Export Folder...") {
            guard let url = userSettings.userExportDirectoryURL else { return }
            try? FileManager.default.createDirectory(
                at: url, withIntermediateDirectories: true)
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
        .disabled(userSettings.userExportDirectoryURL == nil)
        Divider()
        Button("Show Presentation...") {
            openWindow(name: UniqueWindowName.presentationWindow)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        Button("Show More Apps...") {
            let url = URL(string: "https://neededapps.com/")
            guard let websiteURL = url else { return }
            openURL(websiteURL)
        }
        Divider()
        switch coffeePurchaser.state {
        case .notPurchased:
            Button("Buy me a Coffee...") {
                Task { await coffeePurchaser.buyCoffee() }
            }
            .disabled(!coffeePurchaser.canBuyCoffee())
        case .purchasing:
            Text("The coffee is being purchased...")
        case .purchased:
            Text("Thanks for the coffee!")
        }
        Button("About the App...") {
            NSApp.orderFrontStandardAboutPanel()
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        Button("App Settings...") {
            openSettings()
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",", modifiers: .command)
        Divider()
        Button("Quit") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("Q", modifiers: .command)
    }
}

#Preview {
    Menu(content: {
        MenuBarContentView()
    }, label: {
        Image(systemName: "square.3.layers.3d")
    })
    .padding(30.0)
    .previewEnvironments()
}
