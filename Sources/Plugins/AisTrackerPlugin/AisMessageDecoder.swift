import Foundation

final class AisMessageDecoder {
    private struct FragmentBuffer {
        let total: Int
        var payloads: [Int: String]
        var fillBits: Int
    }

    private var fragments: [String: FragmentBuffer] = [:]

    func decode(sentence: String) -> AisObject? {
        // Remove leading/trailing whitespaces and newlines.
        let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip an optional NMEA TAG block, e.g. `\s:2573267,c:1781087503*0A\!BSVDM...`.
        let cleanSentence: String
        if let lastBackslashIndex = trimmed.lastIndex(of: "\\") {
            cleanSentence = String(trimmed[trimmed.index(after: lastBackslashIndex)...])
        } else {
            cleanSentence = trimmed
        }

        // !AIVDM is a mobile AIS station; !BSVDM is a base AIS station.
        guard cleanSentence.hasPrefix("!AI") || cleanSentence.hasPrefix("!BS") else { return nil }

        let noChecksum = cleanSentence.split(separator: "*", maxSplits: 1).first.map(String.init) ?? cleanSentence

        let fields = noChecksum.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        guard fields.count >= 7 else { return nil }

        let talker = fields[0]
        guard talker.hasSuffix("VDM") || talker.hasSuffix("VDO") else { return nil }

        guard let total = Int(fields[1]), let number = Int(fields[2]) else { return nil }
        let sequentialId = fields[3]
        let channel = fields[4]
        let payload = fields[5]
        let fillBits = Int(fields[6]) ?? 0

        let completePayload: String
        let completeFillBits: Int
        if total > 1 {
            let key = "\(sequentialId)-\(channel)"
            var buffer = fragments[key] ?? FragmentBuffer(total: total, payloads: [:], fillBits: fillBits)

            buffer.payloads[number] = payload
            buffer.fillBits = fillBits
            fragments[key] = buffer

            guard buffer.payloads.count == total else { return nil }

            let orderedPayloads = (1...total).compactMap { buffer.payloads[$0] }
            guard orderedPayloads.count == total else { return nil }
            completePayload = orderedPayloads.joined()
            completeFillBits = buffer.fillBits

            fragments.removeValue(forKey: key)
        } else {
            completePayload = payload
            completeFillBits = fillBits
        }

        let bits = AisBitReader(payload: completePayload)
        bits.dropLast(completeFillBits)

        guard let msgType = bits.uint(0, 6) else { return nil }

        switch msgType {
        case 1, 2, 3:
            return decodePositionReport(bits: bits, msgType: msgType)
        case 4:
            return decodeBaseStation(bits: bits, msgType: msgType)
        case 5:
            return decodeStaticVoyage(bits: bits, msgType: msgType)
        case 9:
            return decodeAircraft(bits: bits, msgType: msgType)
        case 18:
            return decodeClassBPosition(bits: bits, msgType: msgType)
        case 19:
            return decodeExtendedClassBPosition(bits: bits, msgType: msgType)
        case 21:
            return decodeAton(bits: bits, msgType: msgType)
        case 24:
            return decodeStaticDataReport(bits: bits, msgType: msgType)
        case 27:
            return decodeLongRange(bits: bits, msgType: msgType)
        default:
            return nil
        }
    }

    private func decodePositionReport(bits: AisBitReader, msgType: Int) -> AisObject? {
        guard let mmsi = bits.uint(8, 30) else { return nil }
        let ais = AisObject(mmsi: mmsi, msgType: msgType)
        ais.applyPosition(timestamp: bits.uint(137, 6) ?? 0,
                          navStatus: bits.uint(38, 4) ?? AisObjectConstants.invalidNavStatus,
                          maneuverIndicator: bits.uint(143, 2) ?? AisObjectConstants.invalidManeuverIndicator,
                          heading: bits.uint(128, 9) ?? AisObjectConstants.invalidHeading,
                          cog: scaled(bits.uint(116, 12), scale: 10, invalidRaw: 3600, invalid: AisObjectConstants.invalidCog),
                          sog: scaled(bits.uint(50, 10), scale: 10, invalidRaw: 1023, invalid: AisObjectConstants.invalidSog),
                          lat: latitude(bits.int(89, 27), divisor: 600000),
                          lon: longitude(bits.int(61, 28), divisor: 600000),
                          rot: rot(bits.int(42, 8)))
        return ais
    }

    private func decodeBaseStation(bits: AisBitReader, msgType: Int) -> AisObject? {
        guard let mmsi = bits.uint(8, 30) else { return nil }
        let ais = AisObject(mmsi: mmsi, msgType: msgType)
        ais.applyBaseStation(lat: latitude(bits.int(107, 27), divisor: 600000),
                             lon: longitude(bits.int(79, 28), divisor: 600000))
        return ais
    }

    private func decodeStaticVoyage(bits: AisBitReader, msgType: Int) -> AisObject? {
        guard let mmsi = bits.uint(8, 30) else { return nil }
        let ais = AisObject(mmsi: mmsi, msgType: msgType)
        ais.applyStatic(imo: bits.uint(40, 30) ?? 0,
                        callSign: bits.string(70, 42),
                        shipName: bits.string(112, 120),
                        shipType: bits.uint(232, 8) ?? AisObjectConstants.invalidShipType,
                        bow: bits.uint(240, 9) ?? 0,
                        stern: bits.uint(249, 9) ?? 0,
                        port: bits.uint(258, 6) ?? 0,
                        starboard: bits.uint(264, 6) ?? 0,
                        draught: scaled(bits.uint(294, 8), scale: 10, invalidRaw: 0, invalid: 0),
                        destination: bits.string(302, 120),
                        etaMonth: bits.uint(274, 4) ?? 0,
                        etaDay: bits.uint(278, 5) ?? 0,
                        etaHour: bits.uint(283, 5) ?? AisObjectConstants.invalidEtaHour,
                        etaMinute: bits.uint(288, 6) ?? AisObjectConstants.invalidEtaMin)
        return ais
    }

    private func decodeAircraft(bits: AisBitReader, msgType: Int) -> AisObject? {
        guard let mmsi = bits.uint(8, 30) else { return nil }
        let ais = AisObject(mmsi: mmsi, msgType: msgType)
        ais.applyAircraft(timestamp: bits.uint(137, 6) ?? 0,
                          altitude: bits.uint(38, 12) ?? AisObjectConstants.invalidAltitude,
                          cog: scaled(bits.uint(116, 12), scale: 10, invalidRaw: 3600, invalid: AisObjectConstants.invalidCog),
                          sog: scaled(bits.uint(50, 10), scale: 10, invalidRaw: 1023, invalid: AisObjectConstants.invalidSog),
                          lat: latitude(bits.int(89, 27), divisor: 600000),
                          lon: longitude(bits.int(61, 28), divisor: 600000))
        return ais
    }

    private func decodeClassBPosition(bits: AisBitReader, msgType: Int) -> AisObject? {
        guard let mmsi = bits.uint(8, 30) else { return nil }
        let ais = AisObject(mmsi: mmsi, msgType: msgType)
        ais.applyPosition(timestamp: bits.uint(133, 6) ?? 0,
                          navStatus: AisObjectConstants.invalidNavStatus,
                          maneuverIndicator: AisObjectConstants.invalidManeuverIndicator,
                          heading: bits.uint(124, 9) ?? AisObjectConstants.invalidHeading,
                          cog: scaled(bits.uint(116, 12), scale: 10, invalidRaw: 3600, invalid: AisObjectConstants.invalidCog),
                          sog: scaled(bits.uint(46, 10), scale: 10, invalidRaw: 1023, invalid: AisObjectConstants.invalidSog),
                          lat: latitude(bits.int(85, 27), divisor: 600000),
                          lon: longitude(bits.int(57, 28), divisor: 600000),
                          rot: AisObjectConstants.invalidRot)
        return ais
    }

    private func decodeExtendedClassBPosition(bits: AisBitReader, msgType: Int) -> AisObject? {
        guard let ais = decodeClassBPosition(bits: bits, msgType: msgType) else { return nil }
        ais.applyStatic(imo: 0,
                        callSign: ais.callSign,
                        shipName: bits.string(143, 120),
                        shipType: bits.uint(263, 8) ?? AisObjectConstants.invalidShipType,
                        bow: bits.uint(271, 9) ?? 0,
                        stern: bits.uint(280, 9) ?? 0,
                        port: bits.uint(289, 6) ?? 0,
                        starboard: bits.uint(295, 6) ?? 0,
                        draught: AisObjectConstants.invalidDraught,
                        destination: nil,
                        etaMonth: AisObjectConstants.invalidEta,
                        etaDay: AisObjectConstants.invalidEta,
                        etaHour: AisObjectConstants.invalidEtaHour,
                        etaMinute: AisObjectConstants.invalidEtaMin)
        return ais
    }

    private func decodeAton(bits: AisBitReader, msgType: Int) -> AisObject? {
        guard let mmsi = bits.uint(8, 30) else { return nil }
        let ais = AisObject(mmsi: mmsi, msgType: msgType)
        ais.applyAton(lat: latitude(bits.int(164, 27), divisor: 600000),
                      lon: longitude(bits.int(135, 28), divisor: 600000),
                      aidType: bits.uint(38, 5) ?? AisObjectConstants.unspecifiedAidType,
                      bow: bits.uint(219, 9) ?? 0,
                      stern: bits.uint(228, 9) ?? 0,
                      port: bits.uint(237, 6) ?? 0,
                      starboard: bits.uint(243, 6) ?? 0)
        return ais
    }

    private func decodeStaticDataReport(bits: AisBitReader, msgType: Int) -> AisObject? {
        guard let mmsi = bits.uint(8, 30) else { return nil }
        let ais = AisObject(mmsi: mmsi, msgType: msgType)
        let part = bits.uint(38, 2) ?? 0
        if part == 0 {
            ais.applyStatic(imo: 0, callSign: nil, shipName: bits.string(40, 120),
                            shipType: AisObjectConstants.invalidShipType,
                            bow: 0, stern: 0, port: 0, starboard: 0,
                            draught: 0, destination: nil,
                            etaMonth: 0, etaDay: 0, etaHour: 24, etaMinute: 60)
        } else {
            ais.applyStatic(imo: 0,
                            callSign: bits.string(90, 42),
                            shipName: nil,
                            shipType: bits.uint(40, 8) ?? AisObjectConstants.invalidShipType,
                            bow: bits.uint(132, 9) ?? 0,
                            stern: bits.uint(141, 9) ?? 0,
                            port: bits.uint(150, 6) ?? 0,
                            starboard: bits.uint(156, 6) ?? 0,
                            draught: 0, destination: nil,
                            etaMonth: 0, etaDay: 0, etaHour: 24, etaMinute: 60)
        }
        return ais
    }

    private func decodeLongRange(bits: AisBitReader, msgType: Int) -> AisObject? {
        guard let mmsi = bits.uint(8, 30) else { return nil }
        let ais = AisObject(mmsi: mmsi, msgType: msgType)
        ais.applyPosition(timestamp: 0,
                          navStatus: bits.uint(40, 4) ?? AisObjectConstants.invalidNavStatus,
                          maneuverIndicator: AisObjectConstants.invalidManeuverIndicator,
                          heading: AisObjectConstants.invalidHeading,
                          cog: scaled(bits.uint(80, 9), scale: 10, invalidRaw: 511, invalid: AisObjectConstants.invalidCog),
                          sog: scaled(bits.uint(69, 6), scale: 1, invalidRaw: 63, invalid: AisObjectConstants.invalidSog),
                          lat: latitude(bits.int(62, 17), divisor: 600),
                          lon: longitude(bits.int(44, 18), divisor: 600),
                          rot: AisObjectConstants.invalidRot)
        return ais
    }

    private func scaled(_ raw: Int?, scale: Double, invalidRaw: Int, invalid: Double) -> Double {
        guard let raw, raw != invalidRaw else { return invalid }
        return Double(raw) / scale
    }

    private func latitude(_ raw: Int?, divisor: Double) -> Double {
        guard let raw else { return AisObjectConstants.invalidLat }
        let value = Double(raw) / divisor
        return abs(value) > 90 ? AisObjectConstants.invalidLat : value
    }

    private func longitude(_ raw: Int?, divisor: Double) -> Double {
        guard let raw else { return AisObjectConstants.invalidLon }
        let value = Double(raw) / divisor
        return abs(value) > 180 ? AisObjectConstants.invalidLon : value
    }

    private func rot(_ raw: Int?) -> Double {
        guard let raw, raw != -128 else { return AisObjectConstants.invalidRot }
        return Double(raw)
    }
}

private final class AisBitReader {
    private var bits: [Int] = []

    init(payload: String) {
        for scalar in payload.unicodeScalars {
            var value = Int(scalar.value) - 48
            if value > 40 { value -= 8 }
            guard value >= 0 && value <= 63 else { continue }
            for shift in stride(from: 5, through: 0, by: -1) {
                bits.append((value >> shift) & 1)
            }
        }
    }

    func dropLast(_ count: Int) {
        guard count > 0, count <= bits.count else { return }
        bits.removeLast(count)
    }

    func uint(_ start: Int, _ length: Int) -> Int? {
        guard start >= 0, length > 0, start + length <= bits.count else { return nil }
        var value = 0
        for idx in start..<(start + length) {
            value = (value << 1) | bits[idx]
        }
        return value
    }

    func int(_ start: Int, _ length: Int) -> Int? {
        guard let unsigned = uint(start, length) else { return nil }
        let signBit = 1 << (length - 1)
        if unsigned & signBit == 0 {
            return unsigned
        }
        return unsigned - (1 << length)
    }

    func string(_ start: Int, _ length: Int) -> String? {
        guard length > 0, start + length <= bits.count else { return nil }
        let chars = stride(from: start, to: start + length, by: 6).compactMap { index -> Character? in
            guard let value = uint(index, 6) else { return nil }
            if value == 0 { return "@" }
            if value >= 1 && value <= 26 {
                return Character(UnicodeScalar(value + 64)!)
            }
            if value >= 32 && value <= 63 {
                return Character(UnicodeScalar(value)!)
            }
            return " "
        }
        let text = String(chars).trimmingCharacters(in: CharacterSet(charactersIn: " @"))
        return text.isEmpty ? nil : text
    }
}
