import SwiftUI
import AVFoundation
import Keyboard
import Tonic
import Controls

struct ContentView: View {
    @StateObject var sampler = AVAudioUnitSamplerClass()
    @State var knob1: Float = 50
    @State var knob2: Float = 20
    @State var knob3: Float = 0.3
    @State var knob4: Float = 127
    @State var knob5: Float = 0
    @Environment(\.scenePhase) var scenePhase
    @State private var showingPopover = false
    
    func updateKnobs(){
        knob1 = sampler.engine.reverb.wetDryMix
        knob2 = sampler.engine.delay.wetDryMix
        knob3 = Float(sampler.engine.delay.delayTime)
        knob4 = sampler.engine.lowPassCutoff
        knob5 = sampler.engine.instrument.overallGain
    }
    
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [.pink, .black]), center: .center, startRadius: 2, endRadius: 650).edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    SwiftUIRack(knob1: $knob1, knob2: $knob2, knob3: $knob3, knob4: $knob4, knob5: $knob5, updateMIDIFilter: sampler.updateMIDIFilter(Param:knobNumber:)).padding(20)
                }
                Spacer()
                SwiftUIKeyboard(firstOctave: sampler.firstOctave, octaveCount: sampler.octaveCount, noteOn: sampler.noteOn(pitch:point:), noteOff: sampler.noteOff)
            }
        }.onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                if !sampler.engine.AVEngine.isRunning {
                    try? sampler.engine.instrument.loadInstrument(at: Bundle.main.url(forResource: "Sounds/Instrument1", withExtension: "aupreset")!)
                    try? sampler.engine.AVEngine.start()
                }
            } else if newPhase == .background {
                sampler.engine.AVEngine.stop()
            }
        }.onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { event in
            switch event.userInfo![AVAudioSessionRouteChangeReasonKey] as! UInt {
            case AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue:
                reloadAudio()
            case AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue:
                reloadAudio()
            default:
                break
            }
        }.onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { event in
            guard let info = event.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            if type == .began {
                self.sampler.engine.AVEngine.stop()
            } else if type == .ended {
                guard let optionsValue =
                        info[AVAudioSessionInterruptionOptionKey] as? UInt else {
                    return
                }
                if AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                    reloadAudio()
                }
            }
        }.onReceive(NotificationCenter.default.publisher(for: .knobUpdate), perform: { obj in
            if let userInfo = obj.userInfo, let info = userInfo["info"] as? UInt8, let knobnum = userInfo["knob"] as? Int {
//                if knobnum == 1 {
//                    sampler.engine.lowPassCutoff = Float(info)
//                }
                if knobnum == 1 {
                    knob1 = Float(info)
                }else if knobnum == 2 {
                    knob2 = Float(info)
                }else if knobnum == 3 {
                    knob3 = Float(info)
                }else if knobnum == 4 {
                    knob4 = Float(info)
                }else if knobnum == 5 {
                    knob5 = Float(info)
                }
            }
        })
        .onDisappear() { self.sampler.engine.AVEngine.stop() }
            .environmentObject(sampler.midiManager)
    }
    func reloadAudio() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if !sampler.engine.AVEngine.isRunning {
                try? sampler.engine.instrument.loadInstrument(at: Bundle.main.url(forResource: "Sounds/Instrument1", withExtension: "aupreset")!)
                sampler.engine.start()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
