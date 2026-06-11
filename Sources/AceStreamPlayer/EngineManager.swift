import Foundation
import AVKit

/// Current state of the local Ace Stream engine (run via Docker).
enum EngineStatus: Equatable {
    case checkingDocker
    case startingEngine
    case waitingForEngine
    case ready
    case error(String)

    var description: String {
        switch self {
        case .checkingDocker:
            return "Checking Docker…"
        case .startingEngine:
            return "Starting Ace Stream engine…"
        case .waitingForEngine:
            return "Waiting for engine to come online (first run downloads the engine image and can take a few minutes)…"
        case .ready:
            return "Engine ready. Paste an acestream:// link and press Play."
        case .error(let message):
            return message
        }
    }

    var isReady: Bool {
        if case .ready = self { return true }
        return false
    }
}

/// Manages the Docker-hosted Ace Stream engine and AVPlayer playback.
@MainActor
final class EngineManager: ObservableObject {
    @Published private(set) var status: EngineStatus = .checkingDocker
    @Published var player: AVPlayer?

    private let containerName = "acestream-engine"
    private let image = "ghcr.io/martinbjeldbak/acestream-http-proxy"
    private let baseURL = URL(string: "http://127.0.0.1:6878")!

    func ensureEngineRunning() async {
        status = .checkingDocker
        do {
            _ = try await runDocker(["info"])
        } catch {
            status = .error("Docker Desktop doesn't seem to be running. Start Docker Desktop, then relaunch this app.")
            return
        }

        do {
            if try await !containerIsRunning() {
                status = .startingEngine
                try await startContainer()
            }
        } catch {
            status = .error("Failed to start the Ace Stream engine: \(error.localizedDescription)")
            return
        }

        status = .waitingForEngine
        if await waitUntilReady(timeout: 180) {
            status = .ready
        } else {
            status = .error("Ace Stream engine didn't come online in time. Check `docker logs \(containerName)`.")
        }
    }

    func play(link: String) {
        guard let id = AceStreamLink.contentID(from: link) else {
            status = .error("That doesn't look like a valid acestream:// link or content ID.")
            return
        }
        guard let url = AceStreamLink.manifestURL(forContentID: id, engineBaseURL: baseURL) else {
            return
        }

        player?.pause()
        let newPlayer = AVPlayer(url: url)
        player = newPlayer
        newPlayer.play()
        status = .ready
    }

    /// Stops the engine container. Bounded so app quit isn't held up indefinitely.
    func stopEngineSync() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["docker", "stop", "-t", "2", containerName]
        try? process.run()
        process.waitUntilExit()
    }

    // MARK: - Docker helpers

    private func containerIsRunning() async throws -> Bool {
        let output = try await runDocker(["ps", "--filter", "name=^/\(containerName)$", "--filter", "status=running", "-q"])
        return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func containerExists() async throws -> Bool {
        let output = try await runDocker(["ps", "-a", "--filter", "name=^/\(containerName)$", "-q"])
        return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func startContainer() async throws {
        if try await containerExists() {
            _ = try await runDocker(["start", containerName])
        } else {
            _ = try await runDocker(["run", "-d", "--platform", "linux/amd64", "--name", containerName, "-p", "6878:6878", image])
        }
    }

    @discardableResult
    private func runDocker(_ arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["docker"] + arguments

            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe

            process.terminationHandler = { proc in
                let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                let out = String(data: outData, encoding: .utf8) ?? ""
                let err = String(data: errData, encoding: .utf8) ?? ""
                if proc.terminationStatus == 0 {
                    continuation.resume(returning: out)
                } else {
                    let message = err.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? out : err
                    continuation.resume(throwing: NSError(domain: "docker", code: Int(proc.terminationStatus), userInfo: [NSLocalizedDescriptionKey: message]))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Readiness polling

    private func waitUntilReady(timeout: TimeInterval) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let (_, response) = try? await URLSession.shared.data(from: baseURL),
               (response as? HTTPURLResponse) != nil {
                return true
            }
            try? await Task.sleep(for: .seconds(2))
        }
        return false
    }
}
