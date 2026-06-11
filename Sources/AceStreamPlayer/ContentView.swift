import SwiftUI
import AVKit

struct ContentView: View {
    @EnvironmentObject private var engine: EngineManager
    @State private var linkText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            playerArea
            controls
        }
        .frame(minWidth: 640, minHeight: 420)
        .task {
            await engine.ensureEngineRunning()
        }
    }

    @ViewBuilder
    private var playerArea: some View {
        if let player = engine.player {
            PlayerView(player: player)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ZStack {
                Color.black
                VStack(spacing: 12) {
                    Image(systemName: "sportscourt")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(engine.status.description)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    if case .error = engine.status {
                        Button("Retry") {
                            Task { await engine.ensureEngineRunning() }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            TextField("acestream://… or content ID", text: $linkText)
                .textFieldStyle(.roundedBorder)
                .onSubmit(play)

            Button("Play", action: play)
                .keyboardShortcut(.defaultAction)
                .disabled(!engine.status.isReady)

            if let player = engine.player {
                AirPlayButton(player: player)
                    .frame(width: 28, height: 28)
            }
        }
        .padding(12)
    }

    private func play() {
        engine.play(link: linkText)
    }
}
