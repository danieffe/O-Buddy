//
//  OBDService.swift
//  PROVAOBDService
//
//  Created by Daniele Fontana on 14/05/25.
//

import Foundation
import CoreBluetooth
import Combine

// Delegate protocol conformances are now in extensions (OBDService+Bluetooth.swift)
class OBDViewModel: NSObject, ObservableObject {
    // Dati pubblicati
    @Published var speed: Int = 0
    @Published var rpm: Int = 0
    @Published var rawResponse: String = ""
    @Published var cleanedResponse: String = ""
    @Published var isConnected: Bool = false
    @Published var lastCommand: String = ""
    @Published var initializationStatus: String = "Non inizializzato"
    @Published var protocolStatus: String = "Sconosciuto"
    @Published var adapterVersion: String = ""

    // Gestione Bluetooth
    internal var centralManager: CBCentralManager!
    internal var obdPeripheral: CBPeripheral?
    internal var writeCharacteristic: CBCharacteristic?

    // Buffer e timer
    internal var responseBuffer = ""
    internal var dataTimer: Timer? // Explicitly marking as internal here
    internal var isWaitingForResponse = false

    // UUID servizi OBD
    internal let obdServiceUUID = CBUUID(string: "FFF0")
    internal let obdWriteCharacteristicUUID = CBUUID(string: "FFF2")
    internal let obdNotifyCharacteristicUUID = CBUUID(string: "FFF1")

    // Comandi di inizializzazione
    internal let setupCommands = [
        "ATZ",       // Reset
        "ATE0",      // Echo off
        "ATL0",      // Linefeeds off
        "ATH1",      // Headers ON
        "ATS0",      // Spaces off
        "ATSP6",     // Set protocol to ISO 15765-4 (CAN)
        "ATDPN",     // Show protocol number
        "ATI",       // Adapter info
        "0100"       // Check supported PIDs
    ]

    internal var currentCommandIndex = 0
    internal var isInitialized = false

    // Sequenza di richiesta dati
    internal let pidSequence = ["01 0D", "01 0C"] // Speed, RPM
    internal var currentPidIndex = 0

    override init() {
        super.init()
        // centralManager delegate conformance is now handled by the extension OBDService+Bluetooth.swift
        centralManager = CBCentralManager(delegate: self, queue: .main)
        initializationStatus = "Inizializzazione Bluetooth..."
    }

    // MARK: - Bluetooth Management methods moved to OBDService+Bluetooth.swift

    // MARK: - OBD Communication methods moved to OBDService+Commands.swift
    // startDataUpdates() and sendNextPidRequest() methods implementations are now in the OBDService+Commands.swift extension.

    // MARK: - Response Processing methods moved to OBDService+Parsing.swift
    // peripheral(_:didUpdateValueFor:error:), processCompleteResponse(_:), cleanResponse(_:), parseSpeed(from:), parseRPM(from:), mapProtocolNumber methods implementations are now in the OBDService+Parsing.swift extension.

    deinit {
        // Deinit logic remains here as it needs access to properties defined in the base class
        dataTimer?.invalidate()
        if let peripheral = obdPeripheral,
           let service = peripheral.services?.first(where: { $0.uuid == obdServiceUUID }),
           let characteristic = service.characteristics?.first(where: { $0.uuid == obdNotifyCharacteristicUUID }) {
            peripheral.setNotifyValue(false, for: characteristic)
        }
        centralManager.stopScan()
    }
}

// Note: CBCentralManagerDelegate and CBPeripheralDelegate conformances and their methods are in OBDService+Bluetooth.swift
// Note: OBD communication command sending and data request loop methods are in OBDService+Commands.swift
// Note: Response processing and parsing methods are in an extension in OBDService+Parsing.swift.
