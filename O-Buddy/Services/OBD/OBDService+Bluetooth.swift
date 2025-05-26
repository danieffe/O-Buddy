//
//  OBDService+Bluetooth.swift
//  PROVAOBDService
//
//  Created by Daniele Fontana on 14/05/25.
//

import CoreBluetooth
import Combine

// MARK: - Bluetooth Management Extension
extension OBDViewModel: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            initializationStatus = "Ricerca dispositivi OBD..."
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        case .poweredOff:
            initializationStatus = "Accendi il Bluetooth"
        default:
            initializationStatus = "Bluetooth non disponibile"
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let peripheralName = peripheral.name ?? "Sconosciuto"
        
        if peripheralName.uppercased().contains("OBD") || peripheralName.uppercased().contains("ELM327") {
            centralManager.stopScan()
            obdPeripheral = peripheral
            initializationStatus = "Connessione a \(peripheralName)..."
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        peripheral.delegate = self
        initializationStatus = "Ricerca servizi..."
        peripheral.discoverServices([obdServiceUUID])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services where service.uuid == obdServiceUUID {
            initializationStatus = "Ricerca caratteristiche..."
            peripheral.discoverCharacteristics([obdWriteCharacteristicUUID, obdNotifyCharacteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == obdNotifyCharacteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
            } else if characteristic.uuid == obdWriteCharacteristicUUID {
                writeCharacteristic = characteristic
                initializationStatus = "Configurazione OBD..."
                sendNextSetupCommand()
            }
        }
    }

    // Note: peripheral(_:didUpdateValueFor:error:) moved to OBDService+Parsing.swift as it primarily handles response data.
}
