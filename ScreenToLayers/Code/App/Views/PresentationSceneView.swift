
import SwiftUI

public struct PresentationSceneView: View {
    
    // MARK: States
    
    @Environment(\.dismissWindow)
    private var dismissWindow
    
    // MARK: Views
    
    public var body: some View {
        HStack {
            Spacer(minLength: 0.0)
            VStack(spacing: 30.0) {
                Text("Welcome to ScreenToLayers")
                    .font(.system(size: 30.0).weight(.bold))
                Grid(alignment: .top, horizontalSpacing: 40.0, verticalSpacing: 12.0) {
                    GridRow(content: {
                        Image("SettingsPreview")
                            .resizable().scaledToFit()
                            .border(.separator)
                            .gridCellAnchor(.top)
                        Image("MenuBarPreview")
                            .resizable().scaledToFit()
                            .border(.separator)
                            .gridCellAnchor(.top)
                    })
                    GridRow(content: {
                        Text("To use the app, go to **Privacy & Security** > **Screen & System Audio Recording** and allow access for ScreenToLayers.")
                            .multilineTextAlignment(.center)
                            .lineLimit(10)
                            .gridCellAnchor(.top)
                        Text("Once enabled, the app will restart. **ScreenToLayers** is located in the main menu bar, giving you access anywhere.")
                            .multilineTextAlignment(.center)
                            .lineLimit(10)
                            .gridCellAnchor(.top)
                    })
                }
                HStack {
                    Spacer()
                    Button(action: {
                        dismissWindow(name: UniqueWindowName.presentationWindow)
                    }, label: {
                        Text("Start Using the App")
                    })
                    .frame(minWidth: 200.0)
                    .controlSize(.extraLarge)
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
            }
            Spacer(minLength: 0.0)
        }
        .padding(.vertical, 20.0)
        .padding(.horizontal, 60.0)
        .frame(width: 780.0, height: 580.0)
        .background(.textBackground)
        .fixedSize()
    }
}

#Preview {
    PresentationSceneView()
}
