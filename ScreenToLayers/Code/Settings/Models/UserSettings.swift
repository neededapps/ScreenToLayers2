
import Foundation
import SwiftUI
import Observation
import ServiceManagement

@MainActor
public final class UserSettings: ObservableObject {
    
    // MARK: Initializers
    
    public init() {
        isLoginItemEnabled = (loginItemAppService.status == .enabled)
        Task { userExportDirectoryURL = await loadExportDirectoryURL() }
    }
    
    // MARK: Hidden settings
    
    @AppStorage("should_show_presentation", store: .standard)
    public var shouldShowPresentation: Bool = true
    
    // MARK: General settings
    
    @AppStorage("plays_sound_at_countdown", store: .standard)
    public var playsSoundAtCountdown: Bool = true
    
    @AppStorage("plays_sound_at_capture", store: .standard)
    public var playsSoundAtCapture: Bool = true
    
    // MARK: Export settings
    
    @AppStorage("opens_files_after_export", store: .standard)
    public var opensFilesAfterExport: Bool = true
    
    @AppStorage("opens_folder_after_export", store: .standard)
    public var opensFolderAfterExport: Bool = false
    
    @AppStorage("user_export_directory_url_data", store: .standard)
    public private(set) var userExportDirectoryURLData: Data?

    // MARK: Review management
    
    @AppStorage("review_last_request_date", store: .standard)
    public var reviewLastRequestDate: Date = .now
    
    @AppStorage("review_last_request_count", store: .standard)
    public var reviewLastRequestCount: Int = 0
    
    // MARK: Capture request support
    
    public var captureRequest: CaptureRequest {
        var request = CaptureRequest()
        request.playsSoundAtCountdown = playsSoundAtCountdown
        request.playsSoundAtCapture = playsSoundAtCapture
        request.opensFilesAfterExport = opensFilesAfterExport
        request.opensFolderAfterExport = opensFolderAfterExport
        request.userExportDirectoryURL = userExportDirectoryURL
        return request
    }
    
    // MARK: Export directory support
    
    @Published
    public private(set) var userExportDirectoryURL: URL?
    
    public func loadDefaultExportDirectoryURL() -> URL? {
        let searchFunc = NSSearchPathForDirectoriesInDomains
        let foundPaths = searchFunc(.picturesDirectory, .userDomainMask, true)
        guard let picturesPath = foundPaths.first else { return nil }
        let picturesURL = URL(fileURLWithPath: picturesPath)
        return picturesURL.appendingPathComponent("ScreenToLayers")
    }
    
    private func loadBookmarkedExportDirectoryURL() async throws -> URL? {
        guard let data = userExportDirectoryURLData else { return nil }
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            bookmarkDataIsStale: &isStale
        )
        if isStale {
            try await setExportDirectory(url: url)
        }
        return url
    }
    
    private func loadExportDirectoryURL() async -> URL? {
        let bookmarkedURL = try? await loadBookmarkedExportDirectoryURL()
        return bookmarkedURL ?? loadDefaultExportDirectoryURL()
    }
    
    public func setExportDirectory(url: URL?) async throws {
        let isScoped = url?.startAccessingSecurityScopedResource() ?? false
        defer { url?.stopAccessingSecurityScopedResource(isEnabled: isScoped) }
        
        let bookmarkData = try url?.bookmarkData(options: [.withSecurityScope])
        userExportDirectoryURLData = bookmarkData
        userExportDirectoryURL = url ?? loadDefaultExportDirectoryURL()
    }
    
    // MARK: Login item support
    
    @Published
    public private(set) var isLoginItemEnabled: Bool = false
    
    private let loginItemAppService: SMAppService = {
        let identifier = "com.jeremyvizzini.screentolayers.osx.helper"
        return SMAppService.loginItem(identifier: identifier)
    }()
    
    public func setLoginAppService(isEnabled: Bool) throws {
        guard isLoginItemEnabled != isEnabled else { return }
        if isEnabled {
            try loginItemAppService.register()
            isLoginItemEnabled = true
        } else {
            try loginItemAppService.unregister()
            isLoginItemEnabled = false
        }
    }
    
    // MARK: Review request support
    
    public func canAskForAppStoreReview() -> Bool {
        reviewLastRequestCount += 1
        guard reviewLastRequestCount > 10 else { return false }
        let daysToNow = reviewLastRequestDate.days(to: .now)
        guard daysToNow > 15 else { return false }
        reviewLastRequestCount = 0
        reviewLastRequestDate = .now
        return true
    }
}
