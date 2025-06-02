//
//  FuelPriceService.swift
//  O-Buddy
//
//  Created by Daniele Fontana on 02/06/25.
//

import Foundation

class FuelPriceService {
    func fetchStations(lat: Double, lon: Double, fuelType: String = "gasolio", distance: Int = 10, completion: @escaping ([FuelStation]) -> Void) {
        let baseURL = "https://prezzi-carburante.onrender.com/api/distributori"
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "distance", value: String(distance)),
            URLQueryItem(name: "fuel", value: fuelType),
            URLQueryItem(name: "results", value: "50")
        ]

        guard let url = components.url else {
            print("❌ URL non valido")
            completion([])
            return
        }
        print("DEBUG: FuelPriceService - Fetching from URL: \(url.absoluteString)")
        // ADD: Debug print for data task initiation
        print("DEBUG: FuelPriceService - Data task initiated.")

        URLSession.shared.dataTask(with: url) { data, response, error in
            // ADD: Debug print for completion handler entry
            print("DEBUG: FuelPriceService - Data task completion handler entered.")

            if let error = error {
                print("❌ Errore richiesta: \(error.localizedDescription)")
                completion([])
                return
            }

            // ADD: Debug print for HTTP response status code
            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG: FuelPriceService - HTTP Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("DEBUG: FuelPriceService - Server returned non-200 status code.")
                    completion([])
                    return
                }
            } else {
                print("DEBUG: FuelPriceService - Response is not HTTPURLResponse or is nil.")
            }

            guard let data = data else {
                print("❌ Nessun dato")
                completion([])
                return
            }
            if let jsonString = String(data: data, encoding: .utf8) {
                print("DEBUG: FuelPriceService - Raw JSON Response:\n\(jsonString.prefix(500))...")
            }


            do {
                let rawDict = try JSONDecoder().decode([String: FuelStationRaw].self, from: data)
                print("DEBUG: FuelPriceService - Decoded \(rawDict.count) raw stations.")

                let stations: [FuelStation] = rawDict.values.compactMap { raw in
                    guard
                        let prezzo = Double(raw.prezzo.replacingOccurrences(of: ",", with: ".")),
                        let distanza = Double(raw.distanza),
                        let lat = Double(raw.latitudine),
                        let lon = Double(raw.longitudine)
                    else {
                        print("DEBUG: FuelPriceService - Failed to parse raw station: \(raw.gestore ?? "N/A"), Prezzo: \(raw.prezzo ?? "N/A")")
                        return nil
                    }

                    return FuelStation(
                        gestore: raw.gestore,
                        indirizzo: raw.indirizzo,
                        prezzo: String(format: "%.3f", prezzo),
                        selfService: raw.selfService?.trimmingCharacters(in: .whitespacesAndNewlines) == "1",
                        data: raw.data,
                        distanza: distanza,
                        latitudine: lat,
                        longitudine: lon
                    )
                }

                DispatchQueue.main.async {
                    print("DEBUG: FuelPriceService - Completed with \(stations.count) valid stations.")
                    completion(stations.sorted(by: { $0.distanza < $1.distanza }))
                }
            } catch {
                print("❌ Errore parsing JSON: \(error)")
                completion([])
            }
        }.resume()
    }
}
// End of file. No additional code.
