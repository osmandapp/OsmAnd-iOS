//
//  KeySymbolMapper.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 03.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class KeySymbolMapper {
    private static var keySymbolMap: [UIKeyboardHIDUsage: String] = [:]
    
    static func getKeySymbol(for usage: UIKeyboardHIDUsage) -> String {
        if keySymbolMap.isEmpty {
            load()
        }
        return keySymbolMap[usage] ?? "\(usage.rawValue)"
    }
    
    private static func load() {
        // Letters A–Z
        keySymbolMap[.keyboardA] = "A"
        keySymbolMap[.keyboardB] = "B"
        keySymbolMap[.keyboardC] = "C"
        keySymbolMap[.keyboardD] = "D"
        keySymbolMap[.keyboardE] = "E"
        keySymbolMap[.keyboardF] = "F"
        keySymbolMap[.keyboardG] = "G"
        keySymbolMap[.keyboardH] = "H"
        keySymbolMap[.keyboardI] = "I"
        keySymbolMap[.keyboardJ] = "J"
        keySymbolMap[.keyboardK] = "K"
        keySymbolMap[.keyboardL] = "L"
        keySymbolMap[.keyboardM] = "M"
        keySymbolMap[.keyboardN] = "N"
        keySymbolMap[.keyboardO] = "O"
        keySymbolMap[.keyboardP] = "P"
        keySymbolMap[.keyboardQ] = "Q"
        keySymbolMap[.keyboardR] = "R"
        keySymbolMap[.keyboardS] = "S"
        keySymbolMap[.keyboardT] = "T"
        keySymbolMap[.keyboardU] = "U"
        keySymbolMap[.keyboardV] = "V"
        keySymbolMap[.keyboardW] = "W"
        keySymbolMap[.keyboardX] = "X"
        keySymbolMap[.keyboardY] = "Y"
        keySymbolMap[.keyboardZ] = "Z"
        
        // Digits 0–9
        keySymbolMap[.keyboard0] = "0"
        keySymbolMap[.keyboard1] = "1"
        keySymbolMap[.keyboard2] = "2"
        keySymbolMap[.keyboard3] = "3"
        keySymbolMap[.keyboard4] = "4"
        keySymbolMap[.keyboard5] = "5"
        keySymbolMap[.keyboard6] = "6"
        keySymbolMap[.keyboard7] = "7"
        keySymbolMap[.keyboard8] = "8"
        keySymbolMap[.keyboard9] = "9"
        
        // Navigation / editing
        keySymbolMap[.keyboardUpArrow] = "↑"
        keySymbolMap[.keyboardDownArrow] = "↓"
        keySymbolMap[.keyboardLeftArrow] = "←"
        keySymbolMap[.keyboardRightArrow] = "→"
        keySymbolMap[.keyboardEscape] = "⎋"
        keySymbolMap[.keyboardTab] = "⇥"
        keySymbolMap[.keyboardReturnOrEnter] = "↵"
        keySymbolMap[.keyboardDeleteOrBackspace] = "⌫"
        keySymbolMap[.keyboardDeleteForward] = "Forward Delete"
        keySymbolMap[.keyboardSpacebar] = "␣"
        keySymbolMap[.keyboardCapsLock] = "⇪"
        keySymbolMap[.keyboardPageUp] = "⇞"
        keySymbolMap[.keyboardPageDown] = "⇟"
        keySymbolMap[.keyboardHome] = "⇱"
        keySymbolMap[.keyboardEnd] = "⇲"
        keySymbolMap[.keyboardInsert] = "Ins"
        
        // Punctuation / symbols
        keySymbolMap[.keyboardHyphen] = "-"
        keySymbolMap[.keyboardEqualSign] = "="
        keySymbolMap[.keyboardGraveAccentAndTilde] = "~"
        keySymbolMap[.keyboardSemicolon] = ";"
        keySymbolMap[.keyboardQuote] = "'"
        keySymbolMap[.keyboardSlash] = "/"
        keySymbolMap[.keyboardBackslash] = "\\"
        keySymbolMap[.keyboardOpenBracket] = "["
        keySymbolMap[.keyboardCloseBracket] = "]"
        keySymbolMap[.keyboardComma] = ","
        keySymbolMap[.keyboardPeriod] = "."
        
        // Function keys F1–F12
        keySymbolMap[.keyboardF1] = "F1"
        keySymbolMap[.keyboardF2] = "F2"
        keySymbolMap[.keyboardF3] = "F3"
        keySymbolMap[.keyboardF4] = "F4"
        keySymbolMap[.keyboardF5] = "F5"
        keySymbolMap[.keyboardF6] = "F6"
        keySymbolMap[.keyboardF7] = "F7"
        keySymbolMap[.keyboardF8] = "F8"
        keySymbolMap[.keyboardF9] = "F9"
        keySymbolMap[.keyboardF10] = "F10"
        keySymbolMap[.keyboardF11] = "F11"
        keySymbolMap[.keyboardF12] = "F12"
        
        // Modifiers
        keySymbolMap[.keyboardLeftShift] = "⇧"
        keySymbolMap[.keyboardRightShift] = "⇧"
        keySymbolMap[.keyboardLeftControl] = "Ctrl"
        keySymbolMap[.keyboardRightControl] = "Ctrl"
        keySymbolMap[.keyboardLeftAlt] = "Alt"
        keySymbolMap[.keyboardRightAlt] = "Alt"
        keySymbolMap[.keyboardLeftGUI] = "⌘"
        keySymbolMap[.keyboardRightGUI] = "⌘"
        
        // Keypad (numpad)
        keySymbolMap[.keypad0] = "Num 0"
        keySymbolMap[.keypad1] = "Num 1"
        keySymbolMap[.keypad2] = "Num 2"
        keySymbolMap[.keypad3] = "Num 3"
        keySymbolMap[.keypad4] = "Num 4"
        keySymbolMap[.keypad5] = "Num 5"
        keySymbolMap[.keypad6] = "Num 6"
        keySymbolMap[.keypad7] = "Num 7"
        keySymbolMap[.keypad8] = "Num 8"
        keySymbolMap[.keypad9] = "Num 9"
        keySymbolMap[.keypadSlash] = "Num /"
        keySymbolMap[.keypadAsterisk] = "Num *"
        keySymbolMap[.keypadHyphen] = "Num -"
        keySymbolMap[.keypadPlus] = "Num +"
        keySymbolMap[.keypadEnter] = "Num Enter"
        keySymbolMap[.keypadPeriod] = "Num ."
        keySymbolMap[.keypadEqualSign] = "Num ="
        keySymbolMap[.keypadComma] = "Num ,"
        if let keypadLeftParenthesis: UIKeyboardHIDUsage = .keypadLeftParenthesis {
            keySymbolMap[keypadLeftParenthesis] = "Num ("
        }
        if let keypadRightParenthesis: UIKeyboardHIDUsage = .keypadRightParenthesis {
            keySymbolMap[keypadRightParenthesis] = "Num ("
        }
    }
}

extension UIKeyboardHIDUsage {
    static let keypadLeftParenthesis = UIKeyboardHIDUsage(rawValue: 0xB6)
    static let keypadRightParenthesis = UIKeyboardHIDUsage(rawValue: 0xB7)
}
