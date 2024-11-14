
import SwiftUI
import QuartzCore

public struct SettingsTabGeneral: View {
    
    // MARK: Initializer
    
    public init(userSettings: UserSettings, coffeePurchaser: CoffeePurchaser) {
        self.userSettings = userSettings
        self.coffeePurchaser = coffeePurchaser
    }
    
    // MARK: States
    
    @ObservedObject
    private var userSettings: UserSettings
    
    @Bindable
    private var coffeePurchaser: CoffeePurchaser
    
    @State
    private var wrappedError: WrappedError = .none
    
    // MARK: Helpers
    
    public func setLoginItemBinding() -> Binding<Bool> {
        Binding<Bool>(get: {
            userSettings.isLoginItemEnabled
        }, set: { isEnabled in
            setLoginAppService(isEnabled: isEnabled)
        })
    }
    
    // MARK: Views
    
    public var body: some View {
        VStack(spacing: 8.0) {
            Grid(alignment: .leading, horizontalSpacing: 20.0, verticalSpacing: 8.0) {
                GridRow {
                    Text("Launch application at startup")
                        .gridCellAnchor(.topLeading)
                        .gridColumnAlignment(.leading)
                    Spacer()
                    Toggle(isOn: setLoginItemBinding()) {
                        Text("Launch application at startup")
                    }
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .gridColumnAlignment(.trailing)
                }
                GridRow {
                    Text("Play a sound at ticking")
                        .gridCellAnchor(.topLeading)
                        .gridColumnAlignment(.leading)
                    Spacer()
                    Toggle(isOn: userSettings.$playsSoundAtCountdown) {
                        Text("Play a sound at ticking")
                    }
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .gridColumnAlignment(.trailing)
                }
                GridRow {
                    Text("Play a sound at capture")
                        .gridCellAnchor(.topLeading)
                        .gridColumnAlignment(.leading)
                    Spacer()
                    Toggle(isOn: userSettings.$playsSoundAtCapture) {
                        Text("Play a sound at capture")
                    }
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .gridColumnAlignment(.trailing)
                }
            }
            Divider().padding(.vertical, 8.0)
            Grid(alignment: .leading, horizontalSpacing: 20.0, verticalSpacing: 8.0) {
                GridRow {
                    Text("Capture Screen Now")
                        .gridCellAnchor(.topLeading)
                        .gridColumnAlignment(.leading)
                    Spacer()
                    ShortcutRecorderView(name: .captureNow, style: .default)
                        .frame(width: 120.0)
                        .gridColumnAlignment(.trailing)
                }
                GridRow {
                    Text("Capture Screen with Delay")
                        .gridCellAnchor(.topLeading)
                        .gridColumnAlignment(.leading)
                    Spacer()
                    ShortcutRecorderView(name: .captureWithDelay, style: .default)
                        .frame(width: 120.0)
                        .gridColumnAlignment(.trailing)
                }
            }
            Divider().padding(.vertical, 8.0)
            HStack(spacing: 8.0) {
                if coffeePurchaser.state == .purchased {
                    Text("Thank you for the coffee! ☕️❤️")
                        .font(.title3.weight(.bold))
                } else {
                    GeometryReader { geometry in
                        Button(action: {
                            Task { await coffeePurchaser.buyCoffee()}
                        }, label: {
                            Text("Buy me a Coffee")
                                .frame(maxWidth: .infinity)
                        })
                        .disabled(!coffeePurchaser.canBuyCoffee())
                        .controlSize(.large)
                    }
                    Button(action: {
                        Task { await coffeePurchaser.restorePurchases()}
                    }, label: {
                        Text("Restore Purchases")
                            .frame(maxWidth: .infinity)
                    })
                    .disabled(!coffeePurchaser.canRestorePurchases())
                    .controlSize(.large)
                }
            }
            .frame(minHeight: 28.0)
            
        }
        .alert(isPresented: $wrappedError.isPresented(), error: wrappedError, actions: { })
        .padding(30.0)
        .tabItem { Label("General", systemImage: "gearshape") }
        .frame(width: 400.0)
        .fixedSize(horizontal: true, vertical: true)
    }
    
    // MARK: Actions
    
    private func setLoginAppService(isEnabled: Bool) {
        do {
            try userSettings.setLoginAppService(isEnabled: isEnabled)
        } catch let error {
            wrappedError = .wrapped(error)
        }
    }
}

#Preview {
    PreviewEnvironmentsWrapView { data in
        SettingsTabGeneral(
            userSettings: data.userSettings,
            coffeePurchaser: data.coffeePurchaser
        )
    }
}
