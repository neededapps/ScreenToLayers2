
import SwiftUI

// MARK: -

private struct MenuBarLabelStateView: View {
    
    // MARK: State
    
    public var captureState: CaptureManager.CaptureState
    
    // MARK: Views
    
    public var body: some View {
        switch captureState {
        case .idle:
            Image(systemName: "square.3.layers.3d")
                .help("ScreenToLayers")
        case .count3:
            Image(systemName: "3.circle")
                .help("Capture in 3 seconds")
        case .count2:
            Image(systemName: "2.circle")
                .help("Capture in 2 seconds")
        case .count1:
            Image(systemName: "1.circle")
                .help("Capture in 1 seconds")
        case .capturing:
            Image(systemName: "camera.fill")
                .help("Capture in progress")
        case .exporting:
            Image(systemName: "camera.fill")
                .help("Exporting files")
        }
    }
}

// MARK: -

public struct MenuBarLabelView: View {
    
    // MARK: State
    
    @Environment(CaptureManager.self)
    private var captureManager
    
    // MARK: Views
    
    public var body: some View {
        MenuBarLabelStateView(captureState: captureManager.captureState)
    }
}

#Preview {
    VStack(spacing: 10.0) {
        ForEach(CaptureManager.CaptureState.allCases, id: \.self) { state in
            MenuBarLabelStateView(captureState: state)
                .frame(width: 122.0, height: 22.0)
                .border(.black)
        }
    }
    .padding(30.0)
    .previewEnvironments()
}
