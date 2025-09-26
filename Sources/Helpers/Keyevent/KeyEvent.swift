//
//  KeyEvent.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 23.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

enum KeyEvent: Int {
    case codeUnknown = 0
    
    case codeA = 29
    case codeB = 30
    case codeC = 31
    case codeD = 32
    case codeE = 33
    case codeF = 34
    case codeG = 35
    case codeH = 36
    case codeI = 37
    case codeJ = 38
    case codeK = 39
    case codeL = 40
    case codeM = 41
    case codeN = 42
    case codeO = 43
    case codeP = 44
    case codeQ = 45
    case codeR = 46
    case codeS = 47
    case codeT = 48
    case codeU = 49
    case codeV = 50
    case codeW = 51
    case codeX = 52
    case codeY = 53
    case codeZ = 54
    
    case codePlus = 81
    case codeEquals = 70
    case codeMinus = 69
    case codeSemicolon = 74
    case codeApostrophe = 75
    case codeSlash = 76
    case codeGrave = 68
    case codeLeftBracket = 71
    case codeRightBracket = 72
    case codeComma = 55
    case codePeriod = 56
    
    // DPAD and navigation
    case codeDpadUp = 19
    case codeDpadDown = 20
    case codeDpadLeft = 21
    case codeDpadRight = 22
    case codeDpadCenter = 23
    case codePageUp = 92
    case codePageDown = 93
    case codeHome = 3
    case codeMoveEnd = 123
    case codeInsert = 124
    case codeBack = 4
    case codeForwardDel = 112
    case codeMoveHome = 122
    
    // Modifier and special keys
    case codeSpace = 62
    case codeEnter = 66
    case codeTab = 61
    case codeShiftLeft = 59
    case codeShiftRight = 60
    case codeCapsLock = 115
    case codeDel = 67
    case codeEscape = 111
    case codeMenu = 82
    case codeNumLock = 143
    case codeAltLeft = 57
    case codeAltRight = 58
    case codeCtrlLeft = 113
    case codeCtrlRight = 114
    case codeSysrq = 120
    case codeBreakKey = 121
    case codeScrollLock = 116
    
    // Function keys
    case codeF1 = 131
    case codeF2 = 132
    case codeF3 = 133
    case codeF4 = 134
    case codeF5 = 135
    case codeF6 = 136
    case codeF7 = 137
    case codeF8 = 138
    case codeF9 = 139
    case codeF10 = 140
    case codeF11 = 141
    case codeF12 = 142
    
    // Numbers
    case code0 = 7
    case code1 = 8
    case code2 = 9
    case code3 = 10
    case code4 = 11
    case code5 = 12
    case code6 = 13
    case code7 = 14
    case code8 = 15
    case code9 = 16
    
    // Media keys
    case codeMediaPlay = 126
    case codeMediaPause = 127
    case codeMediaPlayPause = 85
    case codeMediaStop = 86
    case codeMediaPrevious = 88
    case codeMediaNext = 87
    case codeVolumeUp = 24
    case codeVolumeDown = 25
    case codeVolumeMute = 164
    case codeCamera = 27
    case codePower = 26
    case codeNotification = 83
    case codeWakeup = 224
    case codeSoftSleep = 276
    
    // Numeric Keypad
    case codeNumpad0 = 144
    case codeNumpad1 = 145
    case codeNumpad2 = 146
    case codeNumpad3 = 147
    case codeNumpad4 = 148
    case codeNumpad5 = 149
    case codeNumpad6 = 150
    case codeNumpad7 = 151
    case codeNumpad8 = 152
    case codeNumpad9 = 153
    case codeNumpadDivide = 154
    case codeNumpadMultiply = 155
    case codeNumpadSubtract = 156
    case codeNumpadAdd = 157
    case codeNumpadDot = 158
    case codeNumpadComma = 159
    case codeNumpadEnter = 160
    case codeNumpadEquals = 161
    case codeNumpadLeftParen = 162
    case codeNumpadRightParen = 163
}
