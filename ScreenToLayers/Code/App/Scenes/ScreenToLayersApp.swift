
import SwiftUI

@main
struct ScreenToLayersApp: App {
    
    // MARK: States
    
    @StateObject
    private var userSettings = UserSettings()
    
    @State
    private var coffeePurchaser = CoffeePurchaser()
    
    @State
    private var captureManager = CaptureManager()
    
    @Environment(\.openWindow)
    private var openWindow
    
    // MARK: Scene
    
    public var body: some Scene {
        MenuBarExtra(content: {
            MenuBarContentView()
                .environment(captureManager)
                .environment(coffeePurchaser)
                .environmentObject(userSettings)
        }, label: {
            MenuBarLabelView().alert(
                isPresented: $captureManager.captureError.isPresented(),
                error: captureManager.captureError,
                actions: { }
            )
            .environment(captureManager)
        })
        .onChange(of: userSettings.shouldShowPresentation, initial: true) { _, should in
            guard should else { return }
            userSettings.shouldShowPresentation = false
            openWindow(name: UniqueWindowName.presentationWindow)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        .onChange(of: MASShortcutBinder.shared(), initial: true) { _, binder in
            binder?.bindShortcut(withDefaultsKey: ShortcutName.captureNow.rawValue) {
                [weak userSettings, weak captureManager] in
                guard let request = userSettings?.captureRequest else { return }
                captureManager?.captureScreenNow(request: request)
            }
            binder?.bindShortcut(withDefaultsKey: ShortcutName.captureWithDelay.rawValue) {
                [weak userSettings, weak captureManager] in
                guard let request = userSettings?.captureRequest else { return }
                captureManager?.captureScreenWithDelay(request: request)
            }
        }
        
        WindowGroup(name: UniqueWindowName.presentationWindow) {
            PresentationSceneView()
                .navigationTitle("Welcome to ScreenToLayers")
                .toolbarVisibility(.visible, for: .windowToolbar)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        }
        .windowResizability(.contentSize)
        .windowIdealSize(.fitToContent)
        .windowToolbarStyle(.unified(showsTitle: false))
        .restorationBehavior(.disabled)
        .windowBackgroundDragBehavior(.enabled)
        
        Settings {
            TabView {
                SettingsTabGeneral(
                    userSettings: userSettings,
                    coffeePurchaser: coffeePurchaser)
                SettingsTabExport(
                    userSettings: userSettings)
            }
        }
    }
}
