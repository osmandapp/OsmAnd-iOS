//
//  protocol_legacy.swift
//
//
//  Created by kemo konteh on 5/15/24.
//

import Foundation
import OSLog

struct FramesByECU {
    let txID: ECUID
    var frames: [LegacyFrame]
}

public struct LegacyParcer {
    let messages: [LegacyMessage]
    let frames: [LegacyFrame]

    public init(_ lines: [String]) throws {
        let obdLines = lines
            .compactMap { $0.replacingOccurrences(of: " ", with: "") }
            .filter(\.isHex)

        frames = try obdLines.compactMap {
            try LegacyFrame(raw: $0)
        }

        let framesByECU = Dictionary(grouping: frames) { $0.txID }
        messages = try framesByECU.values.compactMap {
            try LegacyMessage(frames: $0)
        }
    }
}

struct LegacyMessage: MessageProtocol {
    var frames: [LegacyFrame]
    public var data: Data?

    public var ecu: ECUID

    init(frames: [LegacyFrame]) throws {
//        guard !frames.isEmpty else {
//            return nil
//        }
        self.frames = frames
        ecu = frames.first?.txID ?? .unknown

        switch frames.count {
        case 1:
            data = try parseSingleFrameMessage(frames)
        case 2...:
            data = try parseMultiFrameMessage(frames)
        default:
            throw ParserError.error("Invalid frame count")
        }
    }

    private func parseSingleFrameMessage(_ frames: [LegacyFrame]) throws -> Data {
        guard let frame = frames.first else { // Pre-validate the length
            throw ParserError.error("Frame validation failed")
        }

        let mode = frame.data.first

        if mode == 0x43 {
            var data = Data([0x43, 0x00])

            for frame in frames {
                data.append(frame.data.dropFirst())
            }

            return data
        } else {
            return frame.data.dropFirst()
        }
    }

    private func parseMultiFrameMessage(_ frames: [LegacyFrame]) throws -> Data {
        let mode = frames.first?.data.first

        if mode == 0x43 {
            var data = Data([0x43, 0x00])

            for frame in frames {
                data.append(frame.data.dropFirst())
            }

            return data
        } else {
            ///  generic multiline requests carry an order byte

            ///  Ex.
            ///           [      Frame       ]
            ///  48 6B 10 49 02 01 00 00 00 31 ck
            ///  48 6B 10 49 02 02 44 34 47 50 ck
            ///  48 6B 10 49 02 03 30 30 52 35 ck
            ///  etc...         [] [  Data   ]

            ///  becomes:
            ///  49 02 [] 00 00 00 31 44 34 47 50 30 30 52 35
            ///       |  [         ] [         ] [         ]
            ///   order byte is removed

            //  sort the frames by the order byte
            let sortedFrames = frames.sorted { $0.data[2] < $1.data[2] }

            // check contiguity
            guard sortedFrames.first?.data[2] == 1 else {
                throw ParserError.error("Invalid order byte")
            }

            // now that they're in order, accumulate the data from each frame
            var data = Data()
            for frame in sortedFrames {
                // pop off the only the order byte
                data.append(frame.data.dropFirst(3))
            }

            return data
        }
    }

//    private func assembleData(firstFrame: LegacyFrame, consecutiveFrames: [LegacyFrame]) -> Data {
//        var assembledFrame: LegacyFrame = firstFrame
//        // Extract data from consecutive frames, skipping the PCI byte
//        for frame in consecutiveFrames {
//            assembledFrame.data.append(frame.data[1...])
//        }
//        return extractDataFromFrame(assembledFrame, startIndex: 3)
//    }
//
//    private func extractDataFromFrame(_ frame: LegacyFrame, startIndex: Int) -> Data? {
//        return nil
//    }
}

struct LegacyFrame {
    var raw: String
    var data = Data()
    var priority: UInt8
    var rxID: UInt8
    var txID: ECUID

    init(raw: String) throws {
        self.raw = raw
        let rawData = raw

        let dataBytes = rawData.hexBytes

        data = Data(dataBytes.dropFirst(3).dropLast())
        guard dataBytes.count >= 6, dataBytes.count <= 12 else {
            throw ParserError.error("Invalid frame size")
        }

        priority = dataBytes[0]
        rxID = dataBytes[1]
        txID = ECUID(rawValue: dataBytes[2] & 0x07) ?? .unknown
    }
}

public protocol MessageProtocol {
    var data: Data? { get }
    var ecu: ECUID { get }
}

class SAE_J1850_PWM: CANProtocol {
    let elmID = "1"
    let name = "SAE J1850 PWM"
    func parse(_ lines: [String]) throws -> [MessageProtocol] {
        try parseLegacy(lines)
    }
}

class SAE_J1850_VPW: CANProtocol {
    let elmID = "2"
    let name = "SAE J1850 VPW"
    func parse(_ lines: [String]) throws -> [MessageProtocol] {
        try parseLegacy(lines)
    }
}

class ISO_9141_2: CANProtocol {
    let elmID = "3"
    let name = "ISO 9141-2"
    func parse(_ lines: [String]) throws -> [MessageProtocol] {
        try parseLegacy(lines)
    }
}

class ISO_14230_4_KWP_5Baud: CANProtocol {
    let elmID = "4"
    let name = "ISO 14230-4 KWP (5 baud init)"
    func parse(_ lines: [String]) throws -> [MessageProtocol] {
        try parseLegacy(lines)
    }
}

public class ISO_14230_4_KWP_Fast: CANProtocol {
    let elmID = "5"
    let name = "ISO 14230-4 KWP (fast init)"
    public init() {}

    public func parse(_ lines: [String]) throws -> [MessageProtocol] {
        try parseLegacy(lines)
    }
}
