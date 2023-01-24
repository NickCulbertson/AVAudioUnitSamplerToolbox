import AVFoundation
class AudioEngine: ObservableObject {
    // Audio Engine
    let AVEngine = AVAudioEngine()
    
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
        AVEngine.attach(instrument)
        AVEngine.attach(delay)
        AVEngine.attach(reverb)
        AVEngine.attach(limiter)
            
            // Connect Nodes to the Engine's output
        AVEngine.connect(instrument, to: reverb, format: nil)
        AVEngine.connect(reverb, to: delay, format: nil)
        AVEngine.connect(delay, to: limiter, format: nil)
        AVEngine.connect(limiter, to: AVEngine.mainMixerNode, format: nil)
            
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
        try? AVEngine.start()
    }
}
