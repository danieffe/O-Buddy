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

    internal func processCompleteResponse(_ response: String) {
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

        if !isInitialized && setupCommands.contains(lastCommand) {
            currentCommandIndex += 1
            sendNextSetupCommand()
        }
    }

    internal func cleanResponse(_ response: String) -> String {
        return response
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: ">", with: "")
            //.trimmingCharacters(in: .whitespacesAndNewlines)
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
            return
        }

        let rpmValue = (byteA * 256 + byteB) / 4
        DispatchQueue.main.async {
            self.rpm = rpmValue
            print("✅ RPM: \(rpmValue)")
        }
    }

    internal func mapProtocolNumber(_ num: String) -> String {
        switch num {
        case "6": return "ISO 15765-4 (CAN)"
        case "3": return "ISO 9141-2"
        case "4": return "ISO 14230-4 (KWP)"
        default: return "Protocollo \(num)"
        }
    }
}