import AVFoundation
class AudioEngine: ObservableObject {
    // Audio Engine
    let engine = AVAudioEngine()
    
    // Sampler Instrument
    var instrument = AVAudioUnitSampler()
    
    // Effects
    var reverb = AVAudioUnitReverb()
    var delay = AVAudioUnitDelay()
    var delayTime: Float = 0.3 {
        didSet {
            delay.delayTime = TimeInterval(delayTime)
        }
    }
    @Published var lowPassCutoff: AUValue = 127 {
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
    }
    
    func start() {
        try? engine.start()
    }
}
