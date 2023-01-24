import AVFoundation
import Tonic
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
    
    // MIDI Manager (MIDI methods are in AVAudioUnitSampler+MIDI)
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
        MIDIConnect()
    }
    
    //Keyboard Events
    func noteOn(pitch: Pitch, point: CGPoint) {
        instrument.startNote(UInt8(pitch.intValue), withVelocity: 127, onChannel: 0)
    }
    
    func noteOff(pitch: Pitch) {
        instrument.stopNote(UInt8(pitch.intValue), onChannel: 0)
    }
}

extension NSNotification.Name {
    static let keyNoteOn = Notification.Name("keyNoteOn")
    static let keyNoteOff = Notification.Name("keyNoteOff")
    static let knobUpdate = Notification.Name("knobUpdate")
    static let MIDIKey = Notification.Name("MIDIKey")
}
