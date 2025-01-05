
import Foundation
@preconcurrency
import ScreenCaptureKit

public actor ScreenCaptureKitShooter {
    
    // MARK: Initializers
    
    public init() { }
    
    // MARK: Properties
    
    private var stream: SCStream?
    
    private var output = ScreenCaptureKitOutput()
    
    public var isShooting: Bool { stream != nil }
    
    // MARK: Process steps
    
    public func stopShooting() async throws {
        guard let currentStream = stream else { return }
        try await currentStream.stopCapture()
        stream = nil
    }
    
    private func shootFilteredElement(
        filter: SCContentFilter,
        configuration: SCStreamConfiguration
    ) async throws -> ScreenCaptureKitElement {
        if stream == nil {
            stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
            try stream?.addStreamOutput(output, type: .screen, sampleHandlerQueue: nil)
            try await stream?.startCapture()
        } else {
            try await stream?.updateContentFilter(filter)
            try await stream?.updateConfiguration(configuration)
        }
        
        output.resetCGImage()
        let cgImage = try await output.waitForCGImage(timeout: .now() + 1.0)
        return ScreenCaptureKitElement(
            cgImage: cgImage,
            contentRect: filter.contentRect,
            pointPixelScale: CGFloat(filter.pointPixelScale)
        )
    }
    
    private func makeDefaultStreamConfiguration() -> SCStreamConfiguration {
        let configuration = SCStreamConfiguration()
        configuration.queueDepth = 1
        configuration.ignoreShadowsDisplay = false
        configuration.ignoreShadowsSingleWindow = false
        configuration.capturesShadowsOnly = false
        configuration.shouldBeOpaque = false
        configuration.showsCursor = false
        configuration.backgroundColor = .clear
        configuration.captureResolution = .best
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.scalesToFit = false
        configuration.presenterOverlayPrivacyAlertSetting = .never
        return configuration
    }
    
    public func shootScreenElement(
        display: SCDisplay
    ) async throws -> ScreenCaptureKitElement {
        let filter = SCContentFilter(display: display, excludingWindows: [])
        filter.includeMenuBar = true
        
        let contentScale = CGFloat(filter.pointPixelScale)
        let configuration = makeDefaultStreamConfiguration()
        configuration.shouldBeOpaque = true
        configuration.backgroundColor = .black
        configuration.showsCursor = true
        configuration.width = Int(display.frame.width * contentScale)
        configuration.height = Int(display.frame.height * contentScale)
        
        var element = try await shootFilteredElement(
            filter: filter, configuration: configuration)
        element.displayOffset = display.frame.origin
        element.isSystemElement = true
        return element
    }
    
    public func shootCursorElement(
        display: SCDisplay
    ) async throws -> ScreenCaptureKitElement {
        let filter = SCContentFilter(display: display, including: [])
        filter.includeMenuBar = false
        
        let contentScale = CGFloat(filter.pointPixelScale)
        let configuration = makeDefaultStreamConfiguration()
        configuration.showsCursor = true
        configuration.width = Int(filter.contentRect.width * contentScale)
        configuration.height = Int(filter.contentRect.height * contentScale)
        
        var element = try await shootFilteredElement(
            filter: filter, configuration: configuration)
        element.displayOffset = .zero
        element.isSystemElement = true
        element.elementName = String(localized: "Cursor")
        return element
    }
    
    public func shootWindowElement(
        display: SCDisplay,
        window: SCWindow
    ) async throws -> ScreenCaptureKitElement {
        let filter = SCContentFilter(display: display, including: [window])
        filter.includeMenuBar = false
        
        let contentScale = CGFloat(filter.pointPixelScale)
        let configuration = makeDefaultStreamConfiguration()
        configuration.streamName = window.title
        configuration.width = Int(filter.contentRect.width * contentScale)
        configuration.height = Int(filter.contentRect.height * contentScale)
        
        var element = try await shootFilteredElement(
            filter: filter, configuration: configuration)
        element.displayOffset = .zero
        element.isSystemElement = false
        element.processName = window.owningApplication?.applicationName
        element.elementName = window.title
        return element
    }
    
    public func shootSystemElement(
        display: SCDisplay,
        window: SCWindow
    ) async throws -> ScreenCaptureKitElement {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        filter.includeMenuBar = true
        
        let contentScale = CGFloat(filter.pointPixelScale)
        let configuration = makeDefaultStreamConfiguration()
        configuration.ignoreShadowsSingleWindow = true
        configuration.ignoreGlobalClipSingleWindow = false
        configuration.streamName = window.title
        configuration.width = Int(filter.contentRect.width * contentScale)
        configuration.height = Int(filter.contentRect.height * contentScale)
        
        var element = try await shootFilteredElement(
            filter: filter, configuration: configuration)
        element.displayOffset = display.frame.origin
        element.isSystemElement = true
        element.processName = window.owningApplication?.applicationName
        element.elementName = window.title
        return element
    }
}
