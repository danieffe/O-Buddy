//
//  OBDService.swift
//  PROVAOBDService
//
//  Created by Daniele Fontana on 14/05/25.
//

import Foundation
import CoreBluetooth
import Combine

class OBDViewModel: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
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
    private var centralManager: CBCentralManager!
    private var obdPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    
    // Buffer e timer
    private var responseBuffer = ""
    private var dataTimer: Timer?
    private var isWaitingForResponse = false
    
    // UUID servizi OBD
    private let obdServiceUUID = CBUUID(string: "FFF0")
    private let obdWriteCharacteristicUUID = CBUUID(string: "FFF2")
    private let obdNotifyCharacteristicUUID = CBUUID(string: "FFF1")
    
    // Comandi di inizializzazione
    private let setupCommands = [
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
    
    private var currentCommandIndex = 0
    private var isInitialized = false
    
    // Sequenza di richiesta dati
    private let pidSequence = ["01 0D", "01 0C"] // Speed, RPM
    private var currentPidIndex = 0
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
        initializationStatus = "Inizializzazione Bluetooth..."
    }
    
    // MARK: - Bluetooth Management
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
    
    // MARK: - OBD Communication
    private func sendNextSetupCommand() {
        guard currentCommandIndex < setupCommands.count else {
            isInitialized = true
            initializationStatus = "OBD pronto [\(protocolStatus)]"
            startDataUpdates()
            return
        }
        
        let command = setupCommands[currentCommandIndex]
        sendCommand(command)
    }
    
    private func sendCommand(_ command: String) {
        guard !isWaitingForResponse, let writeChar = writeCharacteristic else {
            print("⏳ Salto richiesta: in attesa di risposta precedente")
            return
        }
        
        isWaitingForResponse = true
        lastCommand = command
        
        let commandWithReturn = command + "\r"
        if let data = commandWithReturn.data(using: .utf8) {
            print("🚀 Invio: \(command)")
            obdPeripheral?.writeValue(data, for: writeChar, type: .withResponse)
        }
    }
    
    private func startDataUpdates() {
        dataTimer?.invalidate()
        dataTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            self.sendNextPidRequest()
        }
    }
    
    private func sendNextPidRequest() {
        let pid = pidSequence[currentPidIndex]
        sendCommand(pid)
        currentPidIndex = (currentPidIndex + 1) % pidSequence.count
    }
    
    // MARK: - Response Processing
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        defer { isWaitingForResponse = false }
        
        guard let data = characteristic.value,
              let chunk = String(data: data, encoding: .ascii) ?? String(data: data, encoding: .utf8) else {
            print("⚠️ Dati non validi")
            return
        }
        
        responseBuffer += chunk
        print("📥 Ricevuto: \(chunk)")
        
        guard responseBuffer.contains(">") else { return }
        
        processCompleteResponse(responseBuffer)
        responseBuffer = ""
    }
    
    private func processCompleteResponse(_ response: String) {
        let cleaned = cleanResponse(response)
        
        DispatchQueue.main.async {
            self.rawResponse = response
            self.cleanedResponse = cleaned
        }
        
        if lastCommand == "ATI" {
            adapterVersion = cleaned
        }
        else if lastCommand == "ATDPN" {
            protocolStatus = mapProtocolNumber(cleaned)
        }
        else if lastCommand == "01 0D" {
            parseSpeed(from: cleaned)
        }
        else if lastCommand == "01 0C" {
            parseRPM(from: cleaned)
        }
        
        if !isInitialized {
            currentCommandIndex += 1
            sendNextSetupCommand()
        }
    }
    
    private func cleanResponse(_ response: String) -> String {
        return response
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: ">", with: "")
            //.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseSpeed(from response: String) {
        let cleanResponse = response.replacingOccurrences(of: " ", with: "")
        
        // Cerca il pattern: 7E8 [indirizzo ECU] + 03 [lunghezza] + 41 [modalità] + 0D [PID] + XX [valore]
        guard cleanResponse.count >= 10,
              cleanResponse.hasPrefix("7E8"),
              cleanResponse.dropFirst(3).prefix(2) == "03",
              cleanResponse.dropFirst(5).prefix(2) == "41",
              cleanResponse.dropFirst(7).prefix(2) == "0D",
              let speedValue = Int(cleanResponse.dropFirst(9).prefix(2), radix: 16) else {
            print("🚫 Formato velocità non valido: \(response)")
            return
        }
        
        DispatchQueue.main.async {
            self.speed = speedValue
            print("✅ Velocità: \(speedValue) km/h")
        }
    }

    private func parseRPM(from response: String) {
        let cleanResponse = response.replacingOccurrences(of: " ", with: "")
        
        // Cerca il pattern: 7E8 [indirizzo ECU] + 04 [lunghezza] + 41 [modalità] + 0C [PID] + XX XX [valore]
        guard cleanResponse.count >= 12,
              cleanResponse.hasPrefix("7E8"),
              cleanResponse.dropFirst(3).prefix(2) == "04",
              cleanResponse.dropFirst(5).prefix(2) == "41",
              cleanResponse.dropFirst(7).prefix(2) == "0C",
              let byteA = Int(cleanResponse.dropFirst(9).prefix(2), radix: 16),
              let byteB = Int(cleanResponse.dropFirst(11).prefix(2), radix: 16) else {
            print("🚫 Formato RPM non valido: \(response)")
            return
        }
        
        let rpmValue = (byteA * 256 + byteB) / 4
        DispatchQueue.main.async {
            self.rpm = rpmValue
            print("✅ RPM: \(rpmValue)")
        }
    }
    
    private func mapProtocolNumber(_ num: String) -> String {
        switch num {
        case "6": return "ISO 15765-4 (CAN)"
        case "3": return "ISO 9141-2"
        case "4": return "ISO 14230-4 (KWP)"
        default: return "Protocollo \(num)"
        }
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
