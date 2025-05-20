//
//  parser.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/19/23.
//

import Foundation

enum FrameType: UInt8, Codable {
    case singleFrame = 0x00
    case firstFrame = 0x10
    case consecutiveFrame = 0x20
}

public enum ECUID: UInt8, Codable {
    case engine = 0x00
    case transmission = 0x01
    case unknown = 0x02

    public var description: String {
        switch self {
        case .engine:
            return "Engine"
        case .transmission:
            return "Transmission"
        case .unknown:
            return "Unknown"
        }
    }
}

enum TxId: UInt8, Codable {
    case engine = 0x00
    case transmission = 0x01
}

public struct CANParser {
    public let messages: [Message]
    let frames: [Frame]

    public init(_ lines: [String], idBits: Int) throws {
        let obdLines = lines
            .map { $0.replacingOccurrences(of: " ", with: "") }
            .filter(\.isHex)

        frames = try obdLines.compactMap { try Frame(raw: $0, idBits: idBits) }

        let framesByECU = Dictionary(grouping: frames) { $0.txID }

        messages = try framesByECU.values.compactMap { try Message(frames: $0) }
    }
}

public struct Message: MessageProtocol {
    var frames: [Frame]
    public var data: Data?

    public var ecu: ECUID {
        frames.first?.txID ?? .unknown
    }

    init(frames: [Frame]) throws {
        self.frames = frames
        switch frames.count {
        case 1:
            data = try parseSingleFrameMessage(frames)
        case 2...:
            data = try parseMultiFrameMessage(frames)
        default:
            throw ParserError.error("Invalid frame count")
        }
    }

    private func parseSingleFrameMessage(_ frames: [Frame]) throws -> Data {
        guard let frame = frames.first, frame.type == .singleFrame,
              let dataLen = frame.dataLen, dataLen > 0,
              frame.data.count >= dataLen + 1
        else { // Pre-validate the length
            throw ParserError.error("Frame validation failed")
        }
        return frame.data.dropFirst(2)
    }

    private func parseMultiFrameMessage(_ frames: [Frame]) throws -> Data {
        guard let firstFrame = frames.first(where: { $0.type == .firstFrame }) else {
            throw ParserError.error("Failed to parse multi frame message")
        }
        let consecutiveFrames = frames.filter { $0.type == .consecutiveFrame }
        return try assembleData(firstFrame: firstFrame, consecutiveFrames: consecutiveFrames)
    }

    private func assembleData(firstFrame: Frame, consecutiveFrames: [Frame]) throws -> Data {
        var assembledFrame: Frame = firstFrame
        // Extract data from consecutive frames, skipping the PCI byte
        for frame in consecutiveFrames {
            assembledFrame.data.append(frame.data[1...])
        }
        return try extractDataFromFrame(assembledFrame, startIndex: 3)
    }

    private func extractDataFromFrame(_ frame: Frame, startIndex: Int) throws -> Data {
        guard let frameDataLen = frame.dataLen else {
            throw ParserError.error("Failed to extract data from frame")
        }
        let endIndex = startIndex + Int(frameDataLen) - 1
        guard endIndex <= frame.data.count else {
            return frame.data[startIndex...]
        }
        return frame.data[startIndex ..< endIndex]
    }
}

struct Frame {
    var raw: String
    var data = Data()
    var priority: UInt8
    var addrMode: UInt8
    var rxID: UInt8
    var txID: ECUID
    var type: FrameType
    var seqIndex: UInt8 = 0 // Only used when type = CF
    var dataLen: UInt8?

    init(raw: String, idBits: Int) throws {
        self.raw = raw

        let paddedRawData = idBits == 11 ? "00000" + raw : raw

        let dataBytes = paddedRawData.hexBytes

        data = Data(dataBytes.dropFirst(4))

        guard dataBytes.count >= 6, dataBytes.count <= 12 else {
            print("invalid frame size", dataBytes.compactMap { String(format: "%02X", $0) }.joined(separator: " "))
            throw ParserError.error("Invalid frame size")
        }

        guard let dataType = data.first,
              let type = FrameType(rawValue: dataType & 0xF0)
        else {
            print("invalid frame type", dataBytes.compactMap { String(format: "%02X", $0) })
            throw ParserError.error("Invalid frame type")
        }

        priority = dataBytes[2] & 0x0F
        addrMode = dataBytes[3] & 0xF0
        rxID = dataBytes[2]
        txID = ECUID(rawValue: dataBytes[3] & 0x07) ?? .unknown
        self.type = type

        switch type {
        case .singleFrame:
            dataLen = (data[0] & 0x0F)
        case .firstFrame:
            dataLen = ((UInt8(data[0] & 0x0F) << 8) + UInt8(data[1]))
        case .consecutiveFrame:
            seqIndex = data[0] & 0x0F
        }
    }
}

enum ParserError: Error {
    case error(String)
}

extension String {
    var hexBytes: [UInt8] {
        var position = startIndex
        return (0 ..< count / 2).compactMap { _ in
            defer { position = index(position, offsetBy: 2) }
            return UInt8(self[position ... index(after: position)], radix: 16)
        }
    }

    var isHex: Bool {
        !isEmpty && allSatisfy(\.isHexDigit)
    }
}
