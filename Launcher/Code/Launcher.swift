
import Cocoa

@main
class LaunchHelper: NSObject, NSApplicationDelegate {

    // MARK: Launch application
    
    private let applicationName = "ScreenToLayers"
        
    private let applicationID = "com.jeremyvizzini.screentolayers.osx"
    
    private func checkMainAppIsRunning() -> Bool {
        let apps = NSWorkspace.shared.runningApplications
        return apps.contains { $0.bundleIdentifier == applicationID }
    }
    
    private func findMainAppLocationURL() -> URL? {
        let path = Bundle.main.bundlePath
        var components = path.components(separatedBy: "/")
        components.removeLast() // Helper app name
        components.removeLast() // LoginItems folder
        components.removeLast() // Library folder
        components.removeLast() // Contents folder
        components.removeLast() // Main app folder
        components.append(applicationName + ".app")
        let newPath = components.joined(separator: "/")
        return URL(fileURLWithPath: newPath)
    }
    
    private func launchMainApp() {
        guard let appURL = findMainAppLocationURL() else { return }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration)
    }
    
    // MARK: Application delegate
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        if !checkMainAppIsRunning() {
            launchMainApp()
        }
        NSApp.terminate(nil)
    }
}
