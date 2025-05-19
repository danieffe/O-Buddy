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
            startDataUpdates()
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

    private func startDataUpdates() {
        dataTimer?.invalidate()
        dataTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.sendNextPidRequest()
        }
    }
    

    private func sendNextPidRequest() {
        guard isInitialized else { return }
        let pid = pidSequence[currentPidIndex]
        sendCommand(pid)
        currentPidIndex = (currentPidIndex + 1) % pidSequence.count
    }
}
