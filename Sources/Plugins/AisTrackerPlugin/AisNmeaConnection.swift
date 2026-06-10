import CoreLocation
import Foundation
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
// NOTE: for test tcp 153.44.253.27 5631

final class AisNmeaConnection {
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

    func startUDP(port: UInt16) {
        stop()
        updateState(.connecting)
        do {
            let params = NWParameters.udp
            params.allowLocalEndpointReuse = true
            let listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
            self.listener = listener
            listener.newConnectionHandler = { [weak self] connection in
                self?.receiveDatagrams(connection)
                connection.start(queue: self?.queue ?? DispatchQueue.global())
            }
            listener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.updateState(.connected)
                case .failed:
                    self?.updateState(.failed)
                case .cancelled:
                    self?.updateState(.disconnected)
                default:
                    break
                }
            }
            listener.start(queue: queue)
        } catch {
            updateState(.failed)
        }
    }

    func startTCP(host: String, port: UInt16) {
        stop()
        self.host = host
        self.port = port
        shouldReconnect = true
        connectTCP()
    }

    func stop() {
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
        updateState(.connecting)
        let nwConnection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
        connection = nwConnection
        nwConnection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.updateState(.connected)
                self?.receiveStream(nwConnection)
            case .failed, .waiting:
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
        guard shouldReconnect else { return }
        connection?.cancel()
        connection = nil
        let work = DispatchWorkItem { [weak self] in
            self?.connectTCP()
        }
        reconnectWorkItem = work
        queue.asyncAfter(deadline: .now() + 5, execute: work)
    }

    private func receiveDatagrams(_ connection: NWConnection) {
        connection.receiveMessage { [weak self] data, _, _, _ in
            if let data, let text = String(data: data, encoding: .ascii) {
                self?.consume(text)
            }
            self?.receiveDatagrams(connection)
        }
    }

    private func receiveStream(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, error in
            if let data, let text = String(data: data, encoding: .ascii) {
                self?.consume(text)
            }
            if isComplete || error != nil {
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
            if let location = AisNmeaParser.parseLocation(from: line) {
                DispatchQueue.main.async { [weak self] in
                    self?.onLocation?(location)
                }
            }
        }
        if buffer.count > 8192 {
            buffer.removeAll()
        }
    }

    private func updateState(_ state: AisNmeaConnectionState) {
        DispatchQueue.main.async { [weak self] in
            self?.onStateChanged?(state)
        }
    }
}
