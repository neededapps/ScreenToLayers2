
import Foundation
@preconcurrency
import ScreenCaptureKit

public struct ScreenCaptureKitElement: Equatable, @unchecked Sendable {
    
    // MARK: Initializers
    
    public init(
        cgImage: CGImage,
        contentRect: CGRect,
        pointPixelScale: CGFloat,
        displayOffset: CGPoint = .zero,
        isSystemElement: Bool = false,
        processName: String? = nil,
        elementName: String? = nil
    ) {
        self.cgImage = cgImage
        self.contentRect = contentRect
        self.displayOffset = displayOffset
        self.pointPixelScale = pointPixelScale
        self.isSystemElement = isSystemElement
        self.processName = processName
        self.elementName = elementName
    }
    
    // MARK: Properties
    
    public var cgImage: CGImage
    
    public var contentRect: CGRect
    
    public var pointPixelScale: CGFloat
    
    public var displayOffset: CGPoint
    
    public var isSystemElement: Bool
    
    public var processName: String?
    
    public var elementName: String?
    
    public var displayedName: String {
        var components: [String] = []
        let processNameComponent = (processName?.isEmpty ?? true)
            ? String(localized: "Unknown") : (processName ?? "")
        let elementNameComponent =  (elementName?.isEmpty ?? true)
            ? String(localized: "Unknown") : (elementName ?? "")
        let hasNameItem = elementNameComponent.hasPrefix("Item")
        
        if !isSystemElement || hasNameItem {
            components.append(processNameComponent)
        }
        if !hasNameItem {
            components.append(elementNameComponent)
        }
        return components.joined(separator: " - ")
    }
    
    public var scaledContentRect: CGRect {
        CGRect(
            x: (contentRect.origin.x - displayOffset.x) * pointPixelScale,
            y: (contentRect.origin.y - displayOffset.y) * pointPixelScale,
            width: contentRect.size.width * pointPixelScale,
            height: contentRect.size.height * pointPixelScale
        )
    }
}
