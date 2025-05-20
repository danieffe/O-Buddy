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
    // REMOVE: pollingTimer property
    // REMOVE: pollingInterval property
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
    // CHANGE: Removed duplicate "01 0D"
    internal let pidSequence = ["01 0D", "01 0C", "01 0A"] // Speed, RPM, Fuel Pressure
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
        // REMOVE: Timer invalidation as pollingTimer is removed
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
        currentPidIndex = 0 // Reset PID index
        currentCommandIndex = 0 // ADD: Reset setup command index
        isWaitingForResponse = false // ADD: Reset waiting flag
        // ADD: Reset published values on stop
        DispatchQueue.main.async {
            self.speed = 0
            self.rpm = 0
            self.fuelPressure = 0
            self.rawResponse = ""
            self.cleanedResponse = ""
        }
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

    // ADD: Method to start PID polling
    internal func startPollingPIDs() {
        print("Starting PID polling...")
        // ADD: Send the first PID command immediately
        currentPidIndex = 0 // Start from the beginning of the PID sequence
        sendNextPidCommand()
    }

    // ADD: Method to send the next PID command
    internal func sendNextPidCommand() {
        guard isConnected && isInitialized && !isWaitingForResponse else {
            // If not connected, not initialized, or waiting for a response, don't send
            return
        }

        // ADD: Get the command for the current PID index
        let command = pidSequence[currentPidIndex]
        print("⬆️ Invio PID (\(currentPidIndex + 1)/\(pidSequence.count)): \(command)")
        sendCommand(command)

        isWaitingForResponse = true
        // ADD: Move to the next PID index, loop around
        currentPidIndex = (currentPidIndex + 1) % pidSequence.count
    }


    deinit {
        // REMOVE: Timer invalidation
        if let peripheral = obdPeripheral,
           let service = peripheral.services?.first(where: { $0.uuid == obdServiceUUID }),
           let characteristic = service.characteristics?.first(where: { $0.uuid == obdNotifyCharacteristicUUID }) {
            peripheral.setNotifyValue(false, for: characteristic)
        }
        centralManager.stopScan()
    }
}

// The rest of the file remains the same
