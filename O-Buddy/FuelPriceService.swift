import Foundation

class FuelPriceService {
    func fetchStations(lat: Double, lon: Double, fuelType: String = "benzina", distance: Int = 10, completion: @escaping ([FuelStation]) -> Void) {
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

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ Errore richiesta: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let data = data else {
                print("❌ Nessun dato")
                completion([])
                return
            }

            do {
                let rawDict = try JSONDecoder().decode([String: FuelStationRaw].self, from: data)
                let stations: [FuelStation] = rawDict.values.compactMap { raw in
                    guard
                        let prezzo = Double(raw.prezzo.replacingOccurrences(of: ",", with: ".")),
                        let distanza = Double(raw.distanza),
                        let lat = Double(raw.latitudine),
                        let lon = Double(raw.longitudine)
                    else {
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
                    completion(stations.sorted(by: { $0.distanza < $1.distanza }))
                }
            } catch {
                print("❌ Errore parsing JSON: \(error)")
                completion([])
            }
        }.resume()
    }
}
