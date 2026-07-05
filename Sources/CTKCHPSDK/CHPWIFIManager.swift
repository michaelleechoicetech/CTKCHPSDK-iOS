import Foundation
import UIKit

public class CHPWIFIManager {
    
    public static let shared = CHPWIFIManager()
    
    public weak var listener: CHPWIFIListener?
    
    public static var lastCamFps: String = "12"
    public static var lastCamJpeg: String = "6"
    
    private let wifiService = WIFIService.shared
    
    private init() {
        setupCallbacks()
    }
    
    private func setupCallbacks() {
        wifiService.onConnected = { [weak self] in
            self?.listener?.onWIFIConnectionSucceed()
        }
        
        wifiService.onFailedToConnect = { [weak self] in
            self?.listener?.onWIFIConnectionFailed()
        }
        
        wifiService.onDisconnected = { [weak self] in
            self?.listener?.onWIFIDisconnected()
        }
        
        wifiService.onIndicationReceived = { [weak self] event, payload in
            self?.listener?.onWIFIIndicationReceived(event: event, payload: payload)
        }
    }
    
    public func bindWIFIService(listener: CHPWIFIListener, onFrameDecoded: @escaping (UIImage) -> Void, onStatsUpdated: @escaping (Double, Double) -> Void) {
        self.listener = listener
        wifiService.onFrameDecoded = onFrameDecoded
        wifiService.onStatsUpdated = onStatsUpdated
    }
    
    public func requestWIFIConnect(ip: String = "192.168.4.1") {
        wifiService.connect(ip: ip)
    }
    
    public func requestWIFIDisconnect() {
        wifiService.disconnect()
    }
    
    public func requestKnock(requestCode: Int) {
        wifiService.sendCommand("{knock:CID_DXPRO}") { [weak self] response in
            let success = response.contains("{y:knock}")
            self?.listener?.onWIFIResultResponse(requestCode: requestCode, result: success)
        }
    }
    
    public func requestPlay() {
        wifiService.startStream()
    }
    
    public func requestStop() {
        wifiService.stopStream()
    }
    
    public func requestCameraMode(_ cameraMode: CHPCameraMode) {
        // Formulate camera mode command (sets registers based on mode)
        let modeCmd = getCommandForCameraMode(cameraMode)
        wifiService.sendCommand(modeCmd) { [weak self] response in
            // Notify listener that setup is complete
            self?.listener?.onWIFICameraSettingComplete()
        }
    }
    
    public func requestSetFps(requestCode: Int, sendValue: Int) {
        wifiService.sendCommand("{camfps:\(sendValue)}") { [weak self] response in
            let success = response.contains("{y:camfps}")
            self?.listener?.onWIFIResultResponse(requestCode: requestCode, result: success)
        }
    }
    
    public func requestSetJpegQuality(requestCode: Int, sendValue: Int) {
        wifiService.sendCommand("{camjpeg:\(sendValue)}") { [weak self] response in
            let success = response.contains("{y:camjpeg}")
            self?.listener?.onWIFIResultResponse(requestCode: requestCode, result: success)
        }
    }
    
    private func getCommandForCameraMode(_ mode: CHPCameraMode) -> String {
        // Return matching register setting sequences or simple command
        switch mode {
        case .skinXplSpot: return "{setsdreg:0,0x3c07,0x08}"
        case .skinXplSensitivity: return "{setsdreg:0,0x3c07,0x09}"
        case .skinUvl: return "{setsdreg:0,0x3c07,0x0A}"
        case .skinVslSkintone: return "{setsdreg:0,0x3c07,0x0B}"
        case .hairVslOiliness: return "{setsdreg:0,0x3c07,0x0C}"
        case .hairXplDensity: return "{setsdreg:0,0x3c07,0x0D}"
        case .hairVslKeratin: return "{setsdreg:0,0x3c07,0x0E}"
        case .hairVslVessel: return "{setsdreg:0,0x3c07,0x0F}"
        }
    }
}
