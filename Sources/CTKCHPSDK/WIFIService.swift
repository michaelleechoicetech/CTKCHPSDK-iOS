import Foundation
import Network
import UIKit

class WIFIService {
    
    static let shared = WIFIService()
    
    private var cmdConnection: NWConnection?
    private var streamConnection: NWConnection?
    private let queue = DispatchQueue(label: "com.choicetech.sdk.chp.wifiQueue")
    
    var onConnected: (() -> Void)?
    var onFailedToConnect: (() -> Void)?
    var onDisconnected: (() -> Void)?
    var onIndicationReceived: ((String, String) -> Void)?
    var onFrameDecoded: ((UIImage) -> Void)?
    var onStatsUpdated: ((Double, Double) -> Void)?
    
    private let streamReader = MJPEGStreamReader()
    private var deviceIp = "192.168.4.1" // Default AP IP address
    private let cmdPort: UInt16 = 5289
    private let streamPort: UInt16 = 5290
    
    private var isPlaying = false
    
    // Command response matching fields
    private var pendingRequestCode: Int = 0
    private var completionHandler: ((String) -> Void)?
    private let responseSemaphore = DispatchSemaphore(value: 0)
    
    private init() {
        streamReader.onFrameDecoded = { [weak self] image in
            self?.onFrameDecoded?(image)
        }
        streamReader.onStatsUpdated = { [weak self] fps, kbps in
            self?.onStatsUpdated?(fps, kbps)
        }
    }
    
    func connect(ip: String = "192.168.4.1") {
        self.deviceIp = ip
        let endpoint = NWEndpoint.hostPort(host: .init(ip), port: .init(rawValue: cmdPort)!)
        
        let parameters = NWParameters.tcp
        parameters.requiredInterfaceType = .wifi
        
        cmdConnection = NWConnection(to: endpoint, using: parameters)
        cmdConnection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Command connection ready")
                self?.onConnected?()
                self?.startReceiveLoop()
            case .failed(let error):
                print("Command connection failed: \(error)")
                self?.onFailedToConnect?()
            case .cancelled:
                self?.onDisconnected?()
            default:
                break
            }
        }
        cmdConnection?.start(queue: queue)
    }
    
    func disconnect() {
        isPlaying = false
        stopStream()
        cmdConnection?.cancel()
        cmdConnection = nil
    }
    
    func sendCommand(_ cmd: String, completion: @escaping (String) -> Void) {
        guard let conn = cmdConnection else {
            completion("{n:connection_lost}")
            return
        }
        
        let formattedCmd = cmd.hasPrefix("{") ? cmd : "{\(cmd)}"
        guard let data = formattedCmd.data(using: .utf8) else {
            completion("{n:parse_error}")
            return
        }
        
        self.completionHandler = completion
        
        conn.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Send command failed: \(error)")
                completion("{n:send_error}")
            }
        })
    }
    
    private func startReceiveLoop() {
        cmdConnection?.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                let text = String(data: data, encoding: .utf8) ?? ""
                self?.handleIncomingText(text)
            }
            
            if isComplete || error != nil {
                self?.disconnect()
            } else {
                self?.startReceiveLoop() // Loop next read
            }
        }
    }
    
    private func handleIncomingText(_ rawText: String) {
        // Text may contain multiple brackets
        let packets = parseBracketPackets(rawText)
        for packet in packets {
            guard let parsed = CHPPacket.parse(packet) else { continue }
            
            if let status = parsed.status {
                // This is a direct command response, notify pending callback
                let handler = completionHandler
                completionHandler = nil
                DispatchQueue.main.async {
                    handler?(packet)
                }
            } else {
                // This is a notification
                if parsed.cmd == "camfps" || parsed.cmd == "camjpeg" {
                    if parsed.cmd == "camfps" {
                        CHPWIFIManager.lastCamFps = parsed.params.first ?? "12"
                    } else if parsed.cmd == "camjpeg" {
                        CHPWIFIManager.lastCamJpeg = parsed.params.first ?? "6"
                    }
                }
                DispatchQueue.main.async {
                    self.onIndicationReceived?(parsed.cmd, parsed.params.first ?? "")
                }
            }
        }
    }
    
    private func parseBracketPackets(_ text: String) -> [String] {
        var list = [String]()
        var depth = 0
        var current = ""
        for char in text {
            if char == "{" {
                depth += 1
                current.append(char)
            } else if char == "}" {
                depth -= 1
                current.append(char)
                if depth == 0 {
                    list.append(current)
                    current = ""
                }
            } else if depth > 0 {
                current.append(char)
            }
        }
        return list
    }
    
    func startStream() {
        guard !isPlaying else { return }
        isPlaying = true
        
        sendCommand("{stream:1}") { [weak self] response in
            guard let self = self else { return }
            guard response.contains("{y:stream}") else {
                print("Failed to start stream command on firmware")
                self.isPlaying = false
                return
            }
            
            self.streamReader.reset()
            self.connectToStreamSocket()
        }
    }
    
    private func connectToStreamSocket() {
        let endpoint = NWEndpoint.hostPort(host: .init(deviceIp), port: .init(rawValue: streamPort)!)
        let parameters = NWParameters.tcp
        parameters.requiredInterfaceType = .wifi
        
        streamConnection = NWConnection(to: endpoint, using: parameters)
        streamConnection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Stream connection ready")
                self?.startStreamReceiveLoop()
            case .failed(let error):
                print("Stream connection failed: \(error)")
                self?.stopStream()
            default:
                break
            }
        }
        streamConnection?.start(queue: queue)
    }
    
    private func startStreamReceiveLoop() {
        guard isPlaying else { return }
        streamConnection?.receive(minimumIncompleteLength: 1, maximumLength: 131072) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.streamReader.parseBytes(data)
            }
            
            if isComplete || error != nil {
                self?.stopStream()
            } else {
                self?.startStreamReceiveLoop()
            }
        }
    }
    
    func stopStream() {
        isPlaying = false
        streamConnection?.cancel()
        streamConnection = nil
        streamReader.reset()
        
        sendCommand("{stream:0}") { _ in }
    }
}
