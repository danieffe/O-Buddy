//
//  ContentView.swift
//  PROVAOBDService
//
//  Created by Daniele Fontana on 13/05/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = OBDViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Circle()
                            .fill(viewModel.isConnected ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        
                        VStack(alignment: .leading) {
                            Text(viewModel.isConnected ? "CONNESSO" : "DISCONNESSO")
                                .font(.headline)
                            Text(viewModel.initializationStatus)
                                .font(.caption2)
                        }
                    }
                    
                    Text("\(viewModel.protocolStatus) • \(viewModel.adapterVersion)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 8)
                
                // Dati veicolo
                HStack(spacing: 20) {
                    DataPanel(value: viewModel.speed,
                             unit: "km/h",
                             label: "Velocità",
                             color: .blue)
                    
                    DataPanel(value: viewModel.rpm,
                             unit: "RPM",
                             label: "Giri Motore",
                             color: .orange)
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Sezione debug
                VStack(alignment: .leading, spacing: 12) {
                    Text("COMANDO ATTIVO")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(viewModel.lastCommand)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RISPOSTA GREZZA")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(viewModel.rawResponse)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                            .frame(minHeight: 60)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RISPOSTA ELABORATA")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(viewModel.cleanedResponse)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                            .frame(minHeight: 60)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
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

#Preview {
    ContentView()
}
