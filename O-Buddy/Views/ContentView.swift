//
//  ContentView.swift
//  PROVAOBDService
//
//  Created by Daniele Fontana on 13/05/25.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var obdViewModel = OBDViewModel()
    @StateObject private var locationService = LocationService()
    @StateObject private var brakingViewModel: BrakingViewModel

    init() {
        let obdVM = OBDViewModel()
        _brakingViewModel = StateObject(
            wrappedValue: BrakingViewModel(
                speedPublisher: obdVM.$speed,
                rpmPublisher: obdVM.$rpm,
                fuelPressurePublisher: obdVM.$fuelPressure
            )
        )
        _obdViewModel = StateObject(wrappedValue: obdVM)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                ConnectionHeaderView(
                    isConnected: obdViewModel.isConnected,
                    status: obdViewModel.initializationStatus,
                    protocolStatus: obdViewModel.protocolStatus,
                    adapterVersion: obdViewModel.adapterVersion
                )

                // Dati veicolo
                HStack(spacing: 20) {
                    DataPanel(
                        value: obdViewModel.speed,
                        unit: "km/h",
                        label: "Velocità",
                        color: .blue
                    )

                    DataPanel(
                        value: obdViewModel.rpm,
                        unit: "RPM",
                        label: "Giri Motore",
                        color: .orange
                    )

                    DataPanel(
                        value: obdViewModel.fuelPressure,
                        unit: "kPa",
                        label: "Pressione Carb.",
                        color: .purple
                    )
                }
                .padding(.vertical, 8)

                // Indicatori frenata
                VStack(spacing: 16) {
                    BrakingIndicatorView(viewModel: brakingViewModel)

                    BrakingIntensityView(intensity: brakingViewModel.brakingIntensity)
                }

                // Eventi di frenata
                if !brakingViewModel.brakingEvents.isEmpty {
                    BrakingEventsListView(events: $brakingViewModel.brakingEvents)
                        .transition(.opacity)
                }

                Divider()

                // CHANGE: Button to toggle the session state
                Button(obdViewModel.isConnected ? "Stop Session" : "Start Session") {
                    if obdViewModel.isConnected {
                        obdViewModel.stopDrivingSession()
                    } else {
                        obdViewModel.startDrivingSession()
                    }
                }
                .padding()
                // CHANGE: Button color based on connection status
                .background(obdViewModel.isConnected ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)

                Divider()

                // Sezione debug
                DebugSectionView(
                    lastCommand: obdViewModel.lastCommand,
                    rawResponse: obdViewModel.rawResponse,
                    cleanedResponse: obdViewModel.cleanedResponse
                )
            }
            .padding()
        }
        .onChange(of: locationService.currentLocation) { newLocation in
            if brakingViewModel.isBraking {
                brakingViewModel.addLocationToLastEvent(
                    newLocation,
                    address: locationService.currentAddress
                )
            }
        }
    }
}

// MARK: - Subviews

struct ConnectionHeaderView: View {
    let isConnected: Bool
    let status: String
    let protocolStatus: String
    let adapterVersion: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading) {
                    Text(isConnected ? "CONNESSO" : "DISCONNESSO")
                        .font(.headline)
                    Text(status)
                        .font(.caption2)
                }
            }

            Text("\(protocolStatus) • \(adapterVersion)")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.bottom, 8)
    }
}

struct DataPanel: View {
    let value: Int
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct BrakingIndicatorView: View {
    @ObservedObject var viewModel: BrakingViewModel

    var body: some View {
        VStack(spacing: 8) {
            Text("STATO FRENATA".uppercased())
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 16) {
                Image(systemName: viewModel.isBraking ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(viewModel.isBraking ? .red : .green)

                VStack(alignment: .leading) {
                    Text(viewModel.isBraking ? "FRENATA RILEVATA" : "NORMALE")
                        .font(.subheadline)
                        .bold()
                    Text(viewModel.isBraking ? "Attenzione: decelerazione brusca" : "Guida regolare")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct BrakingIntensityView: View {
    let intensity: Double

    var body: some View {
        VStack(spacing: 8) {
            Text("INTENSITÀ FRENATA".uppercased())
                .font(.caption)
                .foregroundColor(.secondary)

            ZStack {
                Circle()
                    .stroke(lineWidth: 10)
                    .opacity(0.3)
                    .foregroundColor(.gray)

                Circle()
                    .trim(from: 0, to: CGFloat(intensity))
                    // CHANGE: Use StrokeStyle instead of Style
                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .foregroundColor(intensity > 0.7 ? .red : (intensity > 0.4 ? .orange : .green))
                    .rotationEffect(Angle(degrees: -90))

                VStack {
                    Text(String(format: "%.0f%%", intensity * 100))
                        .font(.system(size: 20, weight: .bold))
                    Text(intensity > 0.7 ? "Forte" : (intensity > 0.4 ? "Media" : "Leggera"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 120, height: 120)
            .padding(.vertical, 8)
        }
    }
}

struct BrakingEventsListView: View {
    @Binding var events: [BrakingEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("EVENTI DI FRENATA BRUSCA".uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(events.count) eventi")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            ForEach(events.reversed()) { event in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)

                        Text(event.timestamp.formatted(date: .omitted, time: .standard))
                            .font(.subheadline)
                            .bold()

                        Spacer()

                        Text(String(format: "%.1f km/h/s", event.deceleration))
                            .foregroundColor(.red)
                            .bold()
                    }

                    if !event.address.isEmpty {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                            Text(event.address)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    if let speed = event.speed {
                        HStack {
                            Image(systemName: "speedometer")
                            Text("Velocità: \(speed) km/h")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "gauge.with.dots.needle.50percent")
                        Text("Intensità: \(String(format: "%.0f", event.intensity * 100))%")
                            .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
    }

struct DebugSectionView: View {
    let lastCommand: String
    let rawResponse: String
    let cleanedResponse: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DEBUG OBD".uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)

            Group {
                Text("Ultimo comando inviato:")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(lastCommand)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
            }

            Group {
                Text("Risposta grezza:")
                    .font(.caption)
                    .foregroundColor(.gray)

                ScrollView(.vertical, showsIndicators: true) {
                    Text(rawResponse)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 60, maxHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            }

            Group {
                Text("Risposta elaborata:")
                    .font(.caption)
                    .foregroundColor(.gray)

                ScrollView(.vertical, showsIndicators: true) {
                    Text(cleanedResponse)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 60, maxHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview{
    ContentView()
}
