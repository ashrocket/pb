import Carbon
import Foundation

enum HotkeyError: Error {
    case eventHandlerInstallFailed(OSStatus)
    case registrationFailed(OSStatus)
}

final class HotkeyManager {
    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private let hotKeyID = EventHotKeyID(signature: fourCharCode("CLP3"), id: 1)

    var onHotkey: (() -> Void)?

    init() throws {
        try register()
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    private func register() throws {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else {
                    return noErr
                }

                var identifier = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &identifier
                )

                guard status == noErr else {
                    return status
                }

                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                if identifier.signature == manager.hotKeyID.signature && identifier.id == manager.hotKeyID.id {
                    manager.onHotkey?()
                }
                return noErr
            },
            1,
            &eventSpec,
            selfPointer,
            &eventHandler
        )

        guard installStatus == noErr else {
            throw HotkeyError.eventHandlerInstallFailed(installStatus)
        }

        let modifiers = UInt32(cmdKey | shiftKey)
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_V),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard registerStatus == noErr else {
            throw HotkeyError.registrationFailed(registerStatus)
        }
    }
}

private func fourCharCode(_ text: String) -> OSType {
    text.utf16.reduce(0) { partial, scalar in
        (partial << 8) + OSType(scalar)
    }
}
