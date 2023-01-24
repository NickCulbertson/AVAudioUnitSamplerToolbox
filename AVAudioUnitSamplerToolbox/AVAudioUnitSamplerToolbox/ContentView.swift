import SwiftUI
import AVFoundation
import Keyboard
import Tonic
import Controls
import MIDIKit

class AVAudioUnitSamplerClass: ObservableObject {
    // Audio Engine
    let engine = AVAudioEngine()
    
    // Sampler Instrument
    @Published var instrument = AVAudioUnitSampler()
    @Published var firstOctave = 2
    @Published var octaveCount = 2
    
    // Effects
    @Published var reverb = AVAudioUnitReverb()
    @Published var delay = AVAudioUnitDelay()
    @Published var delayTime: Float = 0.3 {
        didSet {
            delay.delayTime = TimeInterval(delayTime)
        }
    }
    @Published var lowPassCutoff: Float = 127 {
        didSet {
            instrument.sendController(74, withValue: UInt8(lowPassCutoff), onChannel: 0)
        }
    }
    var limiter = AVAudioUnitEffect(audioComponentDescription: AudioComponentDescription(
                                            componentType:kAudioUnitType_Effect,
                                            componentSubType: kAudioUnitSubType_PeakLimiter,
                                            componentManufacturer: kAudioUnitManufacturer_Apple,
                                            componentFlags: 0,
                                            componentFlagsMask: 0))
    
    // MIDI Manager
    let midiManager = MIDIManager(
        clientName: "TestAppMIDIManager",
        model: "TestApp",
        manufacturer: "MyCompany"
    )
    
    init() {
        // Attach Nodes to the Engine
        engine.attach(instrument)
        engine.attach(delay)
        engine.attach(reverb)
        engine.attach(limiter)
        
        // Connect Nodes to the Engine's output
        engine.connect(instrument, to: reverb, format: nil)
        engine.connect(reverb, to: delay, format: nil)
        engine.connect(delay, to: limiter, format: nil)
        engine.connect(limiter, to: engine.mainMixerNode, format: nil)
        
        // Load AVAudioUnitSampler Instrument
        try? instrument.loadInstrument(at: Bundle.main.url(forResource: "Sounds/Instrument1", withExtension: "aupreset")!)
        
        // Set default values for Nodes
        // (the lowPassCutoff is a part of the sampler instrument)
        lowPassCutoff = 127
        delay.wetDryMix = 20
        delay.delayTime = 0.3
        reverb.wetDryMix = 50
        reverb.loadFactoryPreset(.largeHall)
        
        // Start the engine
        try? engine.start()
        
        // Set up MIDI
        do {
            print("Starting MIDI services.")
            try midiManager.start()
        } catch {
            print("Error starting MIDI services:", error.localizedDescription)
        }
        
        do {
            try midiManager.addInputConnection(
                toOutputs: [], // no need to specify if we're using .allEndpoints
                tag: "Listener",
                mode: .allEndpoints, // auto-connect to all outputs that may appear
                filter: .owned(), // don't allow self-created virtual endpoints
                receiver: .events { [weak self] events in
                    // Note: this handler will be called on a background thread
                    // so call the next line on main if it may result in UI updates
                    DispatchQueue.main.async {
                        events.forEach { self?.received(midiEvent: $0) }
                    }
                }
            )
        } catch {
            print(
                "Error setting up managed MIDI all-listener connection:",
                error.localizedDescription
            )
        }
        
    }
    
    // MIDI Events
    private func received(midiEvent: MIDIEvent) {
        switch midiEvent {
        case .noteOn(let payload):
            print("Note On:", payload.note, payload.velocity, payload.channel)
            instrument.startNote(payload.note.number.uInt8Value, withVelocity: payload.velocity.midi1Value.uInt8Value, onChannel: 0)
            NotificationCenter.default.post(name: .MIDIKey, object: nil, userInfo: ["info": payload.note.number.uInt8Value, "bool": true])
        case .noteOff(let payload):
            print("Note Off:", payload.note, payload.velocity, payload.channel)
            instrument.stopNote(payload.note.number.uInt8Value, onChannel: 0)
            NotificationCenter.default.post(name: .MIDIKey, object: nil, userInfo: ["info": payload.note.number.uInt8Value, "bool": false])
        case .cc(let payload):
            print("CC:", payload.controller, payload.value, payload.channel)
        case .programChange(let payload):
            print("Program Change:", payload.program, payload.channel)
        default:
            break
        }
    }
    
    //Keyboard Events
    func noteOn(pitch: Pitch, point: CGPoint) {
        instrument.startNote(UInt8(pitch.intValue), withVelocity: 127, onChannel: 0)
    }
    
    func noteOff(pitch: Pitch) {
        instrument.stopNote(UInt8(pitch.intValue), onChannel: 0)
    }
}
struct ContentView: View {
    @StateObject var sampler = AVAudioUnitSamplerClass()
    @Environment(\.scenePhase) var scenePhase
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
        }.onDisappear() { self.sampler.engine.stop() }
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
