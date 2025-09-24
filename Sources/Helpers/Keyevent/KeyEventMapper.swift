//
//  KeyEventMapper.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 23.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class KeyEventMapper {
    
    private static var map: [KeyEvent: UIKeyboardHIDUsage?] = [
        // Letter keys
        .codeA: .keyboardA,
        .codeB: .keyboardB,
        .codeC: .keyboardC,
        .codeD: .keyboardD,
        .codeE: .keyboardE,
        .codeF: .keyboardF,
        .codeG: .keyboardG,
        .codeH: .keyboardH,
        .codeI: .keyboardI,
        .codeJ: .keyboardJ,
        .codeK: .keyboardK,
        .codeL: .keyboardL,
        .codeM: .keyboardM,
        .codeN: .keyboardN,
        .codeO: .keyboardO,
        .codeP: .keyboardP,
        .codeQ: .keyboardQ,
        .codeR: .keyboardR,
        .codeS: .keyboardS,
        .codeT: .keyboardT,
        .codeU: .keyboardU,
        .codeV: .keyboardV,
        .codeW: .keyboardW,
        .codeX: .keyboardX,
        .codeY: .keyboardY,
        .codeZ: .keyboardZ,

        // Punctuation and symbols
        .codeEquals: .keyboardEqualSign,
        .codeMinus: .keyboardHyphen,
        .codeSemicolon: .keyboardSemicolon,
        .codeApostrophe: .keyboardQuote,
        .codeSlash: .keyboardSlash,
        .codeGrave: .keyboardGraveAccentAndTilde,
        .codeLeftBracket: .keyboardOpenBracket,
        .codeRightBracket: .keyboardCloseBracket,
        .codeComma: .keyboardComma,
        .codePeriod: .keyboardPeriod,
        
        // DPAD and navigation
        .codeDpadUp: .keyboardUpArrow,
        .codeDpadDown: .keyboardDownArrow,
        .codeDpadLeft: .keyboardLeftArrow,
        .codeDpadRight: .keyboardRightArrow,
        
        .codePageUp: .keyboardPageUp,
        .codePageDown: .keyboardPageDown,
        .codeHome: .keyboardHome,
        .codeMoveEnd: .keyboardEnd,
        .codeInsert: .keyboardInsert,
        
        .codeForwardDel: .keyboardDeleteForward,
        .codeMoveHome: .keyboardHome,
        
        // Special keys
        .codeSpace: .keyboardSpacebar,
        .codeEnter: .keyboardReturnOrEnter,
        .codeTab: .keyboardTab,
        .codeShiftLeft: .keyboardLeftShift,
        .codeShiftRight: .keyboardRightShift,
        .codeCapsLock: .keyboardCapsLock,
        .codeDel: .keyboardDeleteOrBackspace,
        .codeEscape: .keyboardEscape,
        
        // Modifier keys
        .codeNumLock: .keyboardLockingNumLock,
        .codeAltLeft: .keyboardLeftAlt,
        .codeAltRight: .keyboardRightAlt,
        .codeCtrlLeft: .keyboardLeftControl,
        .codeCtrlRight: .keyboardRightControl,
        .codeSysrq: .keyboardSysReqOrAttention,
        .codeScrollLock: .keyboardScrollLock,
        
        // Function keys
        .codeF1: .keyboardF1,
        .codeF2: .keyboardF2,
        .codeF3: .keyboardF3,
        .codeF4: .keyboardF4,
        .codeF5: .keyboardF5,
        .codeF6: .keyboardF6,
        .codeF7: .keyboardF7,
        .codeF8: .keyboardF8,
        .codeF9: .keyboardF9,
        .codeF10: .keyboardF10,
        .codeF11: .keyboardF11,
        .codeF12: .keyboardF12,
        
        // Number keys
        .code0: .keyboard0,
        .code1: .keyboard1,
        .code2: .keyboard2,
        .code3: .keyboard3,
        .code4: .keyboard4,
        .code5: .keyboard5,
        .code6: .keyboard6,
        .code7: .keyboard7,
        .code8: .keyboard8,
        .code9: .keyboard9,
        
        // Media and system keys (no direct analog)
        .codeMediaPause: .keyboardPause,
        .codeMediaStop: .keyboardStop,
        .codeVolumeUp: .keyboardVolumeUp,
        .codeVolumeDown: .keyboardVolumeDown,
        .codeVolumeMute: .keyboardMute,
        .codePower: .keyboardPower,
        
        // Numeric keypad
        .codeNumpad0: .keypad0,
        .codeNumpad1: .keypad1,
        .codeNumpad2: .keypad2,
        .codeNumpad3: .keypad3,
        .codeNumpad4: .keypad4,
        .codeNumpad5: .keypad5,
        .codeNumpad6: .keypad6,
        .codeNumpad7: .keypad7,
        .codeNumpad8: .keypad8,
        .codeNumpad9: .keypad9,
        .codeNumpadDivide: .keypadSlash,
        .codeNumpadMultiply: .keypadAsterisk,
        .codeNumpadSubtract: .keypadHyphen,
        .codeNumpadAdd: .keypadPlus,
        .codeNumpadDot: .keypadPeriod,
        .codeNumpadComma: .keypadComma,
        .codeNumpadEnter: .keypadEnter,
        .codeNumpadEquals: .keypadEqualSign,
        
        // Absent for iOS
        .codePlus: nil,
        .codeDpadCenter: nil,
        .codeBack: nil,
        .codeMenu: nil,
        .codeMediaPlay: nil,
        .codeMediaPlayPause: nil,
        .codeMediaPrevious: nil,
        .codeMediaNext: nil,
        .codeCamera: nil,
        .codeNotification: nil,
        .codeWakeup: nil,
        .codeSoftSleep: nil,
        .codeNumpadLeftParen: nil,
        .codeNumpadRightParen: nil
    ]
    
    static func keyEventToKeyboardHIDUsage(_ keyEvent: KeyEvent) -> UIKeyboardHIDUsage? {
        map[keyEvent] ?? nil
    }
    
    static func keyboardHIDUsageToKeyEvent(_ keyboardHIDUsage: UIKeyboardHIDUsage?) -> KeyEvent {
        map.enumerated().first(where: { $1.value == keyboardHIDUsage }).flatMap { $1.key } ?? .codeUnknown
    }
}
