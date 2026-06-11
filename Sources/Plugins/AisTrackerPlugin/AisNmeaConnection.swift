//
//  AisNmeaConnection.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import CoreLocation
import Network

@objc enum AisNmeaProtocol: Int {
    case udp = 0
    case tcp = 1
}

@objc enum AisNmeaConnectionState: Int {
    case disconnected
    case connecting
    case connected
    case failed
}

// NOTE: for test: tcp 153.44.253.27 5631

final class AisNmeaConnection {
    var isDebugLoggingEnabled: (() -> Bool)?
    var onLocation: ((CLLocation) -> Void)?
    var onSentence: ((String) -> Void)?
    var onStateChanged: ((AisNmeaConnectionState) -> Void)?

    private let queue = DispatchQueue(label: "net.osmand.ais.nmea.connection")
    private var listener: NWListener?
    private var connection: NWConnection?
    private var reconnectWorkItem: DispatchWorkItem?
    private var buffer = ""
    private var shouldReconnect = false
    private var host = ""
    private var port: UInt16 = 0
    var isRunning: Bool {
        listener != nil || connection != nil || shouldReconnect
    }

    func startUDP(port: UInt16) {
        stop()
        log("start UDP port=\(port)")
        updateState(.connecting)
        do {
            let params = NWParameters.udp
            params.allowLocalEndpointReuse = true
            guard let endpointPort = NWEndpoint.Port(rawValue: port) else {
                log("UDP start failed: invalid port \(port)")
                updateState(.failed)
                return
            }
            let listener = try NWListener(using: params, on: endpointPort)
            self.listener = listener
            listener.newConnectionHandler = { [weak self] connection in
                self?.log("UDP connection accepted endpoint=\(connection.endpoint)")
                self?.receiveDatagrams(connection)
                connection.start(queue: self?.queue ?? DispatchQueue.global())
            }
            listener.stateUpdateHandler = { [weak self] state in
                self?.log("UDP listener state=\(state)")
                switch state {
                case .ready:
                    self?.updateState(.connected)
                case .failed(let error):
                    self?.log("UDP listener failed error=\(error)")
                    self?.updateState(.failed)
                case .cancelled:
                    self?.updateState(.disconnected)
                default:
                    break
                }
            }
            listener.start(queue: queue)
        } catch {
            log("UDP start failed error=\(error)")
            updateState(.failed)
        }
    }

    func startTCP(host: String, port: UInt16) {
        stop()
        log("start TCP host=\(host) port=\(port)")
        self.host = host
        self.port = port
        shouldReconnect = true
        connectTCP()
    }

    func stop() {
        log("stop listener=\(listener != nil) connection=\(connection != nil) reconnect=\(shouldReconnect)")
        shouldReconnect = false
        reconnectWorkItem?.cancel()
        reconnectWorkItem = nil
        listener?.cancel()
        listener = nil
        connection?.cancel()
        connection = nil
        buffer = ""
        updateState(.disconnected)
    }

    private func connectTCP() {
        log("TCP connect host=\(host) port=\(port)")
        updateState(.connecting)
        guard let endpointPort = NWEndpoint.Port(rawValue: port) else {
            log("TCP connect failed: invalid port \(port)")
            updateState(.failed)
            return
        }
        let nwConnection = NWConnection(host: NWEndpoint.Host(host), port: endpointPort, using: .tcp)
        connection = nwConnection
        nwConnection.stateUpdateHandler = { [weak self] state in
            self?.log("TCP state=\(state)")
            switch state {
            case .ready:
                self?.updateState(.connected)
                self?.receiveStream(nwConnection)
            case .failed(let error):
                self?.log("TCP failed error=\(error)")
                self?.updateState(.failed)
                self?.scheduleReconnect()
            case .waiting(let error):
                self?.log("TCP waiting error=\(error)")
                self?.updateState(.failed)
                self?.scheduleReconnect()
            case .cancelled:
                self?.updateState(.disconnected)
            default:
                break
            }
        }
        nwConnection.start(queue: queue)
    }

    private func scheduleReconnect() {
        guard shouldReconnect else {
            log("skip reconnect: disabled")
            return
        }
        log("schedule TCP reconnect in 5s")
        connection?.cancel()
        connection = nil
        let work = DispatchWorkItem { [weak self] in
            self?.connectTCP()
        }
        reconnectWorkItem = work
        queue.asyncAfter(deadline: .now() + 5, execute: work)
    }

    private func receiveDatagrams(_ connection: NWConnection) {
        connection.receiveMessage { [weak self] data, _, isComplete, error in
            if let error {
                self?.log("UDP receive error=\(error)")
            }
            if let data, let text = String(data: data, encoding: .ascii) {
                self?.log("UDP datagram bytes=\(data.count) complete=\(isComplete)")
                self?.consume(text)
            } else if let data {
                self?.log("UDP datagram ignored: non-ascii bytes=\(data.count)")
            }
            self?.receiveDatagrams(connection)
        }
    }

    private func receiveStream(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, error in
            if let data, let text = String(data: data, encoding: .ascii) {
                self?.log("TCP chunk bytes=\(data.count) complete=\(isComplete)")
                self?.consume(text)
            } else if let data {
                self?.log("TCP chunk ignored: non-ascii bytes=\(data.count)")
            }
            if isComplete || error != nil {
                if let error {
                    self?.log("TCP receive ended error=\(error)")
                } else {
                    self?.log("TCP receive completed")
                }
                self?.scheduleReconnect()
            } else {
                self?.receiveStream(connection)
            }
        }
    }

    private func consume(_ text: String) {
        buffer += text
        let separators = CharacterSet.newlines
        while let range = buffer.rangeOfCharacter(from: separators) {
            let line = String(buffer[..<range.lowerBound])
            buffer.removeSubrange(buffer.startIndex...range.lowerBound)
            DispatchQueue.main.async { [weak self] in
                self?.onSentence?(line)
            }
            log("sentence chars=\(line.count) type=\(sentenceType(line))")
            if let location = AisNmeaParser.parseLocation(from: line) {
                log(String(format: "location lat=%.6f lon=%.6f speed=%.2f course=%.1f",
                           location.coordinate.latitude,
                           location.coordinate.longitude,
                           location.speed,
                           location.course))
                DispatchQueue.main.async { [weak self] in
                    self?.onLocation?(location)
                }
            }
        }
        if buffer.count > 8192 {
            log("drop buffered data: size=\(buffer.count)")
            buffer.removeAll()
        }
    }

    private func updateState(_ state: AisNmeaConnectionState) {
        log("state -> \(state)")
        DispatchQueue.main.async { [weak self] in
            self?.onStateChanged?(state)
        }
    }

    private func sentenceType(_ sentence: String) -> String {
        let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSentence: String
        if let lastBackslashIndex = trimmed.lastIndex(of: "\\") {
            cleanSentence = String(trimmed[trimmed.index(after: lastBackslashIndex)...])
        } else {
            cleanSentence = trimmed
        }
        return cleanSentence.split(separator: ",", maxSplits: 1).first.map(String.init) ?? "unknown"
    }

    private func log(_ message: @autoclosure () -> String) {
        guard isDebugLoggingEnabled?() == true else { return }
        NSLog("[AIS][AisNmeaConnection] %@", message())
    }
}
