import AVFoundation
import Tonic
import MIDIKit

class ViewConductor: ObservableObject {
    // Audio Engine
    var conductor = Conductor()
    
    // Keyboard options
    @Published var firstOctave = 2
    @Published var octaveCount = 2
    
    // MIDI Manager (MIDI methods are in AVAudioUnitSampler+MIDI)
    let midiManager = MIDIManager(
        clientName: "TestAppMIDIManager",
        model: "TestApp",
        manufacturer: "MyCompany"
    )
    
    init() {
        // Start the engine
        conductor.start()
        
        // Set up MIDI
        MIDIConnect()
    }
    
    //Keyboard Events
    func noteOn(pitch: Pitch, point: CGPoint) {
        conductor.instrument.startNote(UInt8(pitch.intValue), withVelocity: 127, onChannel: 0)
    }
    
    func noteOff(pitch: Pitch) {
        conductor.instrument.stopNote(UInt8(pitch.intValue), onChannel: 0)
    }
    
    func updateMIDIFilter(Param: AUValue, knobNumber: Int){
        if knobNumber == 1 {
            conductor.reverb.wetDryMix = Param
        } else if knobNumber == 2 {
            conductor.delay.wetDryMix = Param
        } else if knobNumber == 3 {
            conductor.delay.delayTime = TimeInterval(Param)
        } else if knobNumber == 4 {
            conductor.lowPassCutoff = Param
        } else if knobNumber == 5 {
            conductor.instrument.overallGain = Param
        }
    }
}

extension NSNotification.Name {
    static let keyNoteOn = Notification.Name("keyNoteOn")
    static let keyNoteOff = Notification.Name("keyNoteOff")
    static let knobUpdate = Notification.Name("knobUpdate")
    static let MIDIKey = Notification.Name("MIDIKey")
}
