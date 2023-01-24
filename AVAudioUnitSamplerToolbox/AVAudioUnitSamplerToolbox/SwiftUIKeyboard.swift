import Foundation
import SwiftUI
import Keyboard
import Tonic
import AVFoundation
struct SwiftUIKeyboard: View {
    var firstOctave: Int
    var octaveCount: Int
    var noteOn: (Pitch, CGPoint) -> Void = { _, _ in }
    var noteOff: (Pitch)->Void
    
    var body: some View {
        Keyboard(layout: .piano(pitchRange: Pitch(intValue: firstOctave * 12 + 24)...Pitch(intValue: firstOctave * 12 + octaveCount * 12 + 24)),
                 noteOn: noteOn, noteOff: noteOff){ pitch, isActivated in
            SwiftUIKeyboardKey(pitch: pitch,
                               isActivated: isActivated)
        }.cornerRadius(5)
    }
}

struct SwiftUIKeyboardKey: View {
    @State var MIDIKeyPressed = [Bool](repeating: false, count: 128)
    var pitch : Pitch
    var isActivated : Bool
    
    var body: some View {
        VStack{
            KeyboardKey(pitch: pitch,
                        isActivated: isActivated,
                        text: "",
                        whiteKeyColor: .white,
                        blackKeyColor: .black,
                        pressedColor:  .pink,
                        flatTop: true,
                        isActivatedExternally: MIDIKeyPressed[pitch.intValue])
        }.onReceive(NotificationCenter.default.publisher(for: .MIDIKey), perform: { obj in
            if let userInfo = obj.userInfo, let info = userInfo["info"] as? UInt8, let val = userInfo["bool"] as? Bool {
                self.MIDIKeyPressed[Int(info)] = val
            }
        })
    }
}


