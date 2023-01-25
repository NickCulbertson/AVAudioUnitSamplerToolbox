import SwiftUI
import AVFoundation
import Tonic
import MIDIKit

extension ViewConductor {
    // Connect MIDI on init
    func MIDIConnect() {
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
            conductor.instrument.startNote(payload.note.number.uInt8Value, withVelocity: payload.velocity.midi1Value.uInt8Value, onChannel: 0)
            NotificationCenter.default.post(name: .MIDIKey, object: nil, userInfo: ["info": payload.note.number.uInt8Value, "bool": true])
        case .noteOff(let payload):
            print("Note Off:", payload.note, payload.velocity, payload.channel)
            conductor.instrument.stopNote(payload.note.number.uInt8Value, onChannel: 0)
            NotificationCenter.default.post(name: .MIDIKey, object: nil, userInfo: ["info": payload.note.number.uInt8Value, "bool": false])
        case .cc(let payload):
            print("CC:", payload.controller, payload.value, payload.channel)
            if payload.controller == 74 {
                conductor.instrument.sendController(74, withValue: payload.value.midi1Value.uInt8Value, onChannel: 0)
                NotificationCenter.default.post(name: .knobUpdate, object: nil, userInfo: ["info": payload.value.midi1Value.uInt8Value, "knob": 4])
            }
        case .programChange(let payload):
            print("Program Change:", payload.program, payload.channel)
        default:
            break
        }
    }
}

#if os(iOS)

import CoreAudioKit

struct BluetoothMIDIView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> BTMIDICentralViewController {
        BTMIDICentralViewController()
    }
    
    func updateUIViewController(
        _ uiViewController: BTMIDICentralViewController,
        context: Context
    ) { }
    
    typealias UIViewControllerType = BTMIDICentralViewController
}

class BTMIDICentralViewController: CABTMIDICentralViewController {
    var uiViewController: UIViewController?
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneAction)
        )
    }
    
    @objc
    public func doneAction() {
        uiViewController?.dismiss(animated: true, completion: nil)
    }
}

#endif
