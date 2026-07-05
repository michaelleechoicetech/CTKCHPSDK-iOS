import Foundation
import CoreBluetooth

class BLEService: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let shared = BLEService()
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var rxCharacteristic: CBCharacteristic?
    private var txCharacteristic: CBCharacteristic?
    
    private let nusServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    private let nusRxUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    private let nusTxUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    
    var onDeviceDiscovered: ((CBPeripheral, Int) -> Void)?
    var onConnected: (() -> Void)?
    var onFailedToConnect: (() -> Void)?
    var onDisconnected: (() -> Void)?
    var onDataReceived: ((String) -> Void)?
    
    private var responseQueue = DispatchQueue(label: "com.choicetech.sdk.chp.bleResponseQueue")
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScan() {
        guard centralManager.state == .poweredOn else { return }
        centralManager.scanForPeripherals(withServices: [nusServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    func connect(peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
        }
    }
    
    func writeCommand(_ cmd: String) {
        guard let p = connectedPeripheral, let rx = rxCharacteristic else { return }
        if let data = cmd.data(using: .utf8) {
            p.writeValue(data, for: rx, type: .withoutResponse)
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("BLE Central Manager powered on")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        onDeviceDiscovered?(peripheral, RSSI.intValue)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([nusServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        onFailedToConnect?()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        rxCharacteristic = nil
        txCharacteristic = nil
        onDisconnected?()
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == nusServiceUUID {
                peripheral.discoverCharacteristics([nusRxUUID, nusTxUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == nusRxUUID {
                rxCharacteristic = characteristic
            } else if characteristic.uuid == nusTxUUID {
                txCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        if rxCharacteristic != nil && txCharacteristic != nil {
            onConnected?()
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == nusTxUUID, let data = characteristic.value else { return }
        if let rawStr = String(data: data, encoding: .utf8) {
            onDataReceived?(rawStr.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}
