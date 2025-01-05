
import Foundation
@preconcurrency
import ScreenCaptureKit

internal class ScreenCaptureKitOutput: NSObject, SCStreamOutput, @unchecked Sendable {
    
    // MARK: Errors
    
    public enum OutputError: Error, LocalizedError {
        case imageCaptureFailed
        
        public var errorDescription: String? {
            switch self {
            case .imageCaptureFailed:
                return String(localized: "The capture of the image failed.")
            }
        }
    }
    
    // MARK: Initializers
    
    public override init() {
        self.ciContext = CIContext(options: nil)
        self.syncSemaphore = DispatchSemaphore(value: 1)
        self.waitSemaphore = DispatchSemaphore(value: 0)
        super.init()
    }
    
    // MARK: Properties
    
    private var cgImage: CGImage?
    
    private let ciContext: CIContext
    
    private let syncSemaphore: DispatchSemaphore
    
    private let waitSemaphore: DispatchSemaphore
    
    // MARK: Capture method
    
    private var synchronizedCGImage: CGImage? {
        get {
            syncSemaphore.wait()
            let value = self.cgImage
            syncSemaphore.signal()
            return value
        }
        set {
            syncSemaphore.wait()
            self.cgImage = newValue
            syncSemaphore.signal()
        }
    }
    
    public func waitForCGImage(timeout: DispatchTime) async throws -> CGImage {
        return try await withCheckedThrowingContinuation { continuation in
            _ = waitSemaphore.wait(timeout: timeout)
            if let cgImage = synchronizedCGImage {
                continuation.resume(returning: cgImage)
            } else {
                let error = OutputError.imageCaptureFailed
                continuation.resume(throwing: error)
            }
        }
    }
    
    public func resetCGImage() {
        synchronizedCGImage = nil
    }
    
    // MARK: Stream output
    
    public func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .screen && synchronizedCGImage == nil else { return }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
        
        synchronizedCGImage = cgImage
        waitSemaphore.signal()
    }
}
