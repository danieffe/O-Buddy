//
//  OBDService.swift
//  PROVAOBDService
//
//  Created by Daniele Fontana on 14/05/25.
//

import Foundation
import CoreBluetooth
import Combine

class OBDViewModel: NSObject, ObservableObject {
    // Dati pubblicati
    @Published var speed: Int = 0
    @Published var rpm: Int = 0
    @Published var fuelPressure: Int = 0 // Aggiunto nuovo parametro
    @Published var rawResponse: String = ""
    @Published var cleanedResponse: String = ""
    @Published var isConnected: Bool = false
    @Published var lastCommand: String = ""
    @Published var initializationStatus: String = "Non inizializzato"
    @Published var protocolStatus: String = "Sconosciuto"
    @Published var adapterVersion: String = ""

    // Gestione Bluetooth (resta invariato)
    internal var centralManager: CBCentralManager!
    internal var obdPeripheral: CBPeripheral?
    internal var writeCharacteristic: CBCharacteristic?
    internal var responseBuffer = ""
    internal var dataTimer: Timer?
    internal var isWaitingForResponse = false

    // UUID servizi OBD (resta invariato)
    internal let obdServiceUUID = CBUUID(string: "FFF0")
    internal let obdWriteCharacteristicUUID = CBUUID(string: "FFF2")
    internal let obdNotifyCharacteristicUUID = CBUUID(string: "FFF1")

    // Comandi di inizializzazione (resta invariato)
    internal let setupCommands = [
        "ATZ", "ATE0", "ATL0", "ATH1", "ATS0", "ATSP6", "ATDPN", "ATI", "0100"
    ]

    // Sequenza PID aggiornata
    internal let pidSequence = ["01 0D", "01 0C", "01 0D", "01 0A"] // Speed, RPM, Fuel Pressure
    internal var currentCommandIndex = 0
    internal var currentPidIndex = 0
    internal var isInitialized = false

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
        initializationStatus = "Inizializzazione Bluetooth..."
    }

    // Method to stop the driving session
    func stopDrivingSession() {
        dataTimer?.invalidate()
        dataTimer = nil // Ensure timer is nil after invalidation
        initializationStatus = "Sessione interrotta" // Update status
        isConnected = false // Update connection status
        print("OBD Session Stopped")

        // Optional: Disconnect from the peripheral
        if let peripheral = obdPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        obdPeripheral = nil // Clear the peripheral reference
        writeCharacteristic = nil // Clear the characteristic reference
        isInitialized = false // Reset initialization state
        currentPidIndex = 0 // Reset command index
    }

    // ADD: Method to start the driving session
    func startDrivingSession() {
        // Only start if Bluetooth is powered on and not already connected
        guard centralManager.state == .poweredOn && !isConnected else {
            if centralManager.state != .poweredOn {
                initializationStatus = "Accendi il Bluetooth per iniziare"
            } else if isConnected {
                initializationStatus = "Già connesso e in esecuzione"
            }
            return
        }

        initializationStatus = "Ricerca dispositivi OBD..."
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        print("OBD Session Started (Scanning)")
    }


    deinit {
        dataTimer?.invalidate()
        if let peripheral = obdPeripheral,
           let service = peripheral.services?.first(where: { $0.uuid == obdServiceUUID }),
           let characteristic = service.characteristics?.first(where: { $0.uuid == obdNotifyCharacteristicUUID }) {
            peripheral.setNotifyValue(false, for: characteristic)
        }
        centralManager.stopScan()
    }
}

// The rest of the file remains the samehe rest of the file remains the same
