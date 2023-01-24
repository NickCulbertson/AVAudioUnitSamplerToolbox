import SwiftUI
import AVFoundation
import Keyboard
import Tonic
import Controls

struct ContentView: View {
    @StateObject var sampler = AVAudioUnitSamplerClass()
    @Environment(\.scenePhase) var scenePhase
    @State private var showingPopover = false
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [.pink, .black]), center: .center, startRadius: 2, endRadius: 650).edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    VStack {
                        Text("Reverb Mix\n\(sampler.reverb.wetDryMix, specifier: "%.2f")")
                            .multilineTextAlignment(.center)
                        SmallKnob(value: $sampler.reverb.wetDryMix, range: 0...100)
                    }.frame(maxWidth:100)
                    VStack {
                        Text("Delay Mix\n\(sampler.delay.wetDryMix, specifier: "%.2f")")
                            .multilineTextAlignment(.center)
                        SmallKnob(value: $sampler.delay.wetDryMix, range: 0...100)
                        
                    }.frame(maxWidth:100)
                    VStack {
                        Text("Delay Time\n\(sampler.delay.delayTime, specifier: "%.2f")")
                            .multilineTextAlignment(.center)
                        SmallKnob(value: $sampler.delayTime, range: 0...2)
                        
                    }.frame(maxWidth:100)
                    VStack {
                        Text("Low Pass\n\(sampler.lowPassCutoff, specifier: "%.0f")")
                            .multilineTextAlignment(.center)
                        SmallKnob(value: $sampler.lowPassCutoff, range: 0...127)
                    }.frame(maxWidth:100)
                    VStack {
                        Text("Volume\n\(sampler.instrument.overallGain, specifier: "%.2f")")
                            .multilineTextAlignment(.center)
                        SmallKnob(value: $sampler.instrument.overallGain, range: -12...12)
                    }.frame(maxWidth:100)
                    // Use this to as a MIDI Bluetooth connection view
//                    Button("Connect MIDI Bluetooth") {
//                        showingPopover.toggle()
//                    }.popover(isPresented: $showingPopover) {
//                        NavigationView {
//                            BluetoothMIDIView()
//                                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                                .navigationTitle("Connect MIDI Bluetooth").navigationBarTitleDisplayMode(.inline).navigationBarItems(leading: Button(action: {showingPopover = false }) {
//                                    HStack {
//                                        Image(systemName: "chevron.left").imageScale(.large).foregroundColor(.white)
//                                    }
//                                }).frame(maxWidth:.infinity)
//                        }.navigationViewStyle(.stack).frame(minWidth: 300, minHeight: 200)
//                    }
                }
                Spacer()
                SwiftUIKeyboard(firstOctave: sampler.firstOctave, octaveCount: sampler.octaveCount, noteOn: sampler.noteOn(pitch:point:), noteOff: sampler.noteOff)
            }
        }.onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                if !sampler.engine.isRunning {
                    try? sampler.instrument.loadInstrument(at: Bundle.main.url(forResource: "Sounds/Instrument1", withExtension: "aupreset")!)
                    try? sampler.engine.start()
                }
            } else if newPhase == .background {
                sampler.engine.stop()
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
                self.sampler.engine.stop()
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
                print(info)
                if knobnum == 1 {
                    sampler.lowPassCutoff = Float(info)
                }
            }
        })
        .onDisappear() { self.sampler.engine.stop() }
            .environmentObject(sampler.midiManager)
    }
    func reloadAudio() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if !sampler.engine.isRunning {
                try? sampler.instrument.loadInstrument(at: Bundle.main.url(forResource: "Sounds/Instrument1", withExtension: "aupreset")!)
                try? sampler.engine.start()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
