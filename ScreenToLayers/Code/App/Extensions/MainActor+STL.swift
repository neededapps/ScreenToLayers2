
extension MainActor {
    
    internal static func run(in duration: Duration, body: @escaping @MainActor () -> ()) {
        Task {
            try await Task.sleep(for: duration)
            await body()
        }
    }
}
