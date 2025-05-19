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
