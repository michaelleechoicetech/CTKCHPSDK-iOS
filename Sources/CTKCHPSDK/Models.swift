import Foundation

public enum CHPCameraMode: String, CaseIterable {
    // Skin
    case skinXplSpot = "SKIN_XPL_SPOT"
    case skinXplSensitivity = "SKIN_XPL_SENSITIVITY"
    case skinUvl = "SKIN_UVL"
    case skinVslSkintone = "SKIN_VSL_SKINTONE"
    // Hair
    case hairVslOiliness = "HAIR_VSL_OILINESS"
    case hairXplDensity = "HAIR_XPL_DENSITY"
    case hairVslKeratin = "HAIR_VSL_KERATIN"
    case hairVslVessel = "HAIR_VSL_VESSEL"
}

public struct CHPPacket {
    public let cmd: String
    public let params: [String]
    public let status: String? // "y" or "n" for response packets
    
    public static func parse(_ rawText: String) -> CHPPacket? {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{") && trimmed.hasSuffix("}") else { return nil }
        
        let inner = String(trimmed.dropFirst().dropLast())
        let components = inner.components(separatedBy: ":")
        guard components.count >= 2 else { return nil }
        
        let header = components[0]
        if header == "noti" {
            let event = components[1]
            let payload = components.count > 2 ? Array(components[2...]).joined(separator: ":") : ""
            return CHPPacket(cmd: event, params: [payload], status: nil)
        } else if header == "y" || header == "n" {
            let cmdName = components[1]
            let payload = components.count > 2 ? Array(components[2...]).joined(separator: ":") : ""
            let paramsList = payload.isEmpty ? [] : payload.components(separatedBy: ",")
            return CHPPacket(cmd: cmdName, params: paramsList, status: header)
        } else {
            // Request or legacy format
            let cmdName = header
            let payload = Array(components[1...]).joined(separator: ":")
            let paramsList = payload.isEmpty ? [] : payload.components(separatedBy: ",")
            return CHPPacket(cmd: cmdName, params: paramsList, status: nil)
        }
    }
}

public protocol CHPBLEListener: AnyObject {
    func onBLEConnectionSucceed()
    func onBLEConnectionFailed()
    func onBLEDisconnected()
    func onBLEResultResponse(requestCode: Int, result: Bool)
    func onBLEValueResponse(requestCode: Int, result: String)
    func onBLEIndicationReceived(event: String, payload: String)
}

public protocol CHPWIFIListener: AnyObject {
    func onWIFIConnectionSucceed()
    func onWIFIConnectionFailed()
    func onWIFIDisconnected()
    func onWIFIResultResponse(requestCode: Int, result: Bool)
    func onWIFIValueResponse(requestCode: Int, result: String)
    func onWIFICameraSettingComplete()
    func onWIFIIndicationReceived(event: String, payload: String)
}
