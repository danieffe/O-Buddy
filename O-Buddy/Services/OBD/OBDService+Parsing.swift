//
//  OBDService+Parsing.swift
//  PROVAOBDService
//
//  Created by Daniele Fontana on 14/05/25.
//

import Foundation
import CoreBluetooth

// MARK: - Response Processing Extension
extension OBDViewModel {

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        guard let data = characteristic.value,
              let chunk = String(data: data, encoding: .ascii) ?? String(data: data, encoding: .utf8) else {
            print("⚠️ Dati non validi")
            return
        }

        responseBuffer += chunk
        print("📥 Ricevuto: \(chunk)")

        guard responseBuffer.contains(">") else { return }

        processCompleteResponse(responseBuffer)
        responseBuffer = "" // Reset buffer after processing
        // REMOVE: Old logic for sending next setup command here
    }

    internal func processCompleteResponse(_ response: String) {
        let cleaned = cleanResponse(response)

        DispatchQueue.main.async {
            self.rawResponse = response
            self.cleanedResponse = cleaned
        }

        // ADD: Set waiting flag to false as response is received
        isWaitingForResponse = false

        // Handle initialization commands
        if !isInitialized {
             if lastCommand == "ATI" {
                adapterVersion = cleaned
            }
            else if lastCommand == "ATDPN" {
                protocolStatus = mapProtocolNumber(cleaned)
            }

            // ADD: Check if the last command was the final setup command ("0100")
            if lastCommand == setupCommands.last {
                isInitialized = true
                initializationStatus = "Inizializzazione completata. Avvio polling dati..."
                startPollingPIDs() // Start polling after initialization
            } else if setupCommands.contains(lastCommand) {
                 // Only send the next setup command if the response is for a setup command
                currentCommandIndex += 1
                sendNextSetupCommand()
            }

        } else {
            // Handle PID responses after initialization
            switch lastCommand {
            case "01 0D":
                parseSpeed(from: cleaned)
            case "01 0C":
                parseRPM(from: cleaned)
            // ADD: Handle Fuel Pressure PID
            case "01 0A":
                parseFuelPressure(from: cleaned)
            default:
                // Handle unexpected responses during polling if necessary
                print("Received unexpected response for command: \(lastCommand)")
            }
            // ADD: Immediately send the next PID command after processing a response
            sendNextPidCommand()
        }
    }

    internal func cleanResponse(_ response: String) -> String {
        return response
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: ">", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines) // ADD: Trim whitespace
    }

    internal func parseSpeed(from response: String) {
        let cleanResponse = response.replacingOccurrences(of: " ", with: "")

        // Cerca il pattern: 7E8 [indirizzo ECU] + 03 [lunghezza] + 41 [modalità] + 0D [PID] + XX [valore]
        guard cleanResponse.count >= 10,
              cleanResponse.hasPrefix("7E8"),
              cleanResponse.dropFirst(3).prefix(2) == "03",
              cleanResponse.dropFirst(5).prefix(2) == "41",
              cleanResponse.dropFirst(7).prefix(2) == "0D",
              let speedValue = Int(cleanResponse.dropFirst(9).prefix(2), radix: 16) else {
            print("🚫 Formato velocità non valido: \(response)")
            DispatchQueue.main.async { self.speed = 0 } // ADD: Reset on error
            return
        }

        DispatchQueue.main.async {
            self.speed = speedValue
            print("✅ Velocità: \(speedValue) km/h")
        }
    }

    internal func parseRPM(from response: String) {
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
            DispatchQueue.main.async { self.rpm = 0 } // ADD: Reset on error
            return
        }

        let rpmValue = (byteA * 256 + byteB) / 4
        DispatchQueue.main.async {
            self.rpm = rpmValue
            print("✅ RPM: \(rpmValue)")
        }
    }

    internal func parseFuelPressure(from response: String) {
        let cleanResponse = response.replacingOccurrences(of: " ", with: "")

        guard cleanResponse.count >= 10,
              cleanResponse.hasPrefix("7E8"),
              cleanResponse.dropFirst(3).prefix(2) == "03",
              cleanResponse.dropFirst(5).prefix(2) == "41",
              cleanResponse.dropFirst(7).prefix(2) == "0A",
              let pressureValue = Int(cleanResponse.dropFirst(9).prefix(2), radix: 16) else {
            print("🚫 Formato pressione carburante non valido: \(response)")
            DispatchQueue.main.async { self.fuelPressure = 0 } // ADD: Reset on error
            return
        }

        DispatchQueue.main.async {
            // CHANGE: Calculation corrected for Fuel Pressure PID 01 0A (A*3 kPa)
            self.fuelPressure = pressureValue * 3
            print("✅ Pressione carburante: \(self.fuelPressure) kPa")
        }
    }

    internal func mapProtocolNumber(_ num: String) -> String {
        switch num.trimmingCharacters(in: .whitespacesAndNewlines) { // ADD: Trim whitespace
        case "6": return "ISO 15765-4 (CAN)"
        case "3": return "ISO 9141-2"
        case "4": return "ISO 14230-4 (KWP)"
        // ADD: Handle "AUTO" response from ATSP0
        case "A": return "AUTO"
        default: return "Protocollo \(num)"
        }
    }
}
// The rest of the file remains the same
