import SwiftUI
import AVFoundation

@main
struct AVAudioUnitSamplerToolboxApp: App {
    init() {
#if os(iOS)
        do {
//            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.01)
            try AVAudioSession.sharedInstance().setCategory(.playback,
                                                            options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let err {
            print(err)
        }
#endif
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
