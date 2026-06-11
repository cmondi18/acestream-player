import SwiftUI
import AVKit

/// Native AirPlay route picker for an `AVPlayer`.
struct AirPlayButton: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.player = player
        return view
    }

    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {
        if nsView.player !== player {
            nsView.player = player
        }
    }
}
