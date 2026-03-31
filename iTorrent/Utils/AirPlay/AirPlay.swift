import SwiftUI

public extension View {
    func airPlay() -> some View {
        modifier(AirPlayStatusModifier())
    }
}

private struct AirPlayStatusModifier: ViewModifier {
    @State private var isConnected = Air.shared.connected
    @State private var registeredCallback = false

    func body(content: Content) -> some View {
        content
            .overlay {
                if isConnected {
                    ZStack {
                        Color.black.ignoresSafeArea()

                        Label("Displaying via AirPlay", systemImage: "airplayvideo")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(.white.opacity(0.12), in: Capsule())
                    }
                }
            }
            .onAppear {
                guard !registeredCallback else { return }
                registeredCallback = true
                Air.connection { connected in
                    Task { @MainActor in
                        isConnected = connected
                    }
                }
            }
    }
}
