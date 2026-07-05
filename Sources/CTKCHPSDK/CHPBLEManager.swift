import Foundation
import CoreBluetooth

public class CHPBLEManager {
    
    public static let shared = CHPBLEManager()
    
    public weak var listener: CHPBLEListener?
    
    private let bleService = BLEService.shared
    
    private var pendingRequestCode: Int = 0
    private var pendingResponse: String?
    private let semaphore = DispatchSemaphore(value: 0)
    
    private init() {
        setupCallbacks()
    }
    
    private func setupCallbacks() {
        bleService.onDeviceDiscovered = { [weak self] peripheral, rssi in
            // Handle discovery forwarding or custom notification
        }
        
        bleService.onConnected = { [weak self] in
            self?.listener?.onBLEConnectionSucceed()
        }
        
        bleService.onFailedToConnect = { [weak self] in
            self?.listener?.onBLEConnectionFailed()
        }
        
        bleService.onDisconnected = { [weak self] in
            self?.listener?.onBLEDisconnected()
        }
        
        bleService.onDataReceived = { [weak self] rawText in
            self?.handleReceivedData(rawText)
        }
    }
    
    public func startScan(onDiscovered: @escaping (CBPeripheral, Int) -> Void) {
        bleService.onDeviceDiscovered = onDiscovered
        bleService.startScan()
    }
    
    public func stopScan() {
        bleService.stopScan()
    }
    
    public func connect(peripheral: CBPeripheral, listener: CHPBLEListener) {
        self.listener = listener
        bleService.connect(peripheral: peripheral)
    }
    
    public func disconnect() {
        bleService.disconnect()
    }
    
    public func requestKnock(requestCode: Int) {
        // Send knock hash (usually CID hash or hardcoded code)
        sendAsyncCommand(cmd: "{knock:CID_DXPRO}", requestCode: requestCode)
    }
    
    public func requestAPOpen(requestCode: Int, pin: String) {
        sendAsyncCommand(cmd: "{apopen:\(pin)}", requestCode: requestCode)
    }
    
    public func requestAPClose(requestCode: Int) {
        sendAsyncCommand(cmd: "{apclose:}", requestCode: requestCode)
    }
    
    private func sendAsyncCommand(cmd: String, requestCode: Int) {
        bleService.writeCommand(cmd)
    }
    
    private func handleReceivedData(_ rawText: String) {
        guard let packet = CHPPacket.parse(rawText) else { return }
        
        if let status = packet.status {
            // It is a response packet
            let success = (status == "y")
            if packet.cmd == "knock" {
                listener?.onBLEResultResponse(requestCode: 1, result: success)
            } else if packet.cmd == "apopen" {
                listener?.onBLEResultResponse(requestCode: 4, result: success)
            } else if packet.cmd == "apclose" {
                listener?.onBLEResultResponse(requestCode: 3, result: success)
            }
        } else {
            // It is an indication/notification packet
            if packet.cmd == "camfps" || packet.cmd == "camjpeg" {
                if packet.cmd == "camfps" {
                    CHPWIFIManager.lastCamFps = packet.params.first ?? "12"
                } else if packet.cmd == "camjpeg" {
                    CHPWIFIManager.lastCamJpeg = packet.params.first ?? "6"
                }
            }
            listener?.onBLEIndicationReceived(event: packet.cmd, payload: packet.params.first ?? "")
        }
    }
}
