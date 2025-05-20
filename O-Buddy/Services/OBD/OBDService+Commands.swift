//
//  OBDService+Commands.swift
//  PROVAOBDService
//
//  Created by Daniele Fontana on 14/05/25.
//

import Foundation
import CoreBluetooth

// MARK: - OBD Communication Extension
extension OBDViewModel {

    internal func sendNextSetupCommand() {
        guard currentCommandIndex < setupCommands.count else {
            isInitialized = true
            initializationStatus = "OBD pronto [\(protocolStatus)]"
            // CHANGE: Call startPollingPIDs from OBDService.swift
            startPollingPIDs()
            return
        }

        let command = setupCommands[currentCommandIndex]
        sendCommand(command)
    }

    internal func sendCommand(_ command: String) {
        guard let writeChar = writeCharacteristic else {
            print("⏳ Caratteristica di scrittura non disponibile")
            return
        }

        lastCommand = command

        let commandWithReturn = command + "\r"
        if let data = commandWithReturn.data(using: .utf8) {
            print("🚀 Invio: \(command)")
            obdPeripheral?.writeValue(data, for: writeChar, type: .withoutResponse)
        }
    }

    // REMOVE: Redundant startDataUpdates function, replaced by startPollingPIDs in OBDService.swift
    // REMOVE: Redundant sendNextPidRequest function, replaced by sendNextPidCommand in OBDService.swift
}

// The rest of the file remains the same
