//
//  ContentView.swift
//  GrammarFix
//
//  Created by Lancy Norbert Fernandes on 15/08/25.
//

import SwiftUI
import ServiceManagement

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var openAPIKey = ""
    @State private var textInput = ""
    @State private var textOutput = ""
    @State private var isLoadingResult = false
    @State private var launchAtLogin = false
    @State private var selectedMode: GrammarMode = SelectedModePreference.value

    var body: some View {
        VStack(alignment: .leading) {
            modePicker

            TextField(
                "Open AI API Key",
                text: $openAPIKey
            )
            
            Text("Add your text below:")
                .foregroundStyle(.secondary)
            TextEditor(text: $textInput)
                .padding(.vertical, 4)
                .scrollContentBackground(.hidden)
                .background(.quaternary)
                .frame(minHeight: 100)
            
            Button {
                isLoadingResult = true
                Task {
                    let api = GrammarCorrector(apiKey: openAPIKey)
                    let fullPrompt = "\(selectedMode.prompt)\n\nText: \(textInput)"
                    textOutput = try await api.correctGrammar(of: fullPrompt)
                    isLoadingResult = false
                }
            } label: {
                HStack(spacing: 7) {
                    if isLoadingResult {
                        ProgressView().progressViewStyle(.circular).scaleEffect(0.65).tint(.white)
                    } else {
                        Image(systemName: "wand.and.stars").font(.system(size: 12, weight: .semibold))
                    }
                    Text(isLoadingResult ? "Fixing…" : "\(selectedMode.rawValue) with OpenAI")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isLoadingResult || textInput.isEmpty {
                            LinearGradient(colors: [Color.white.opacity(0.07), Color.white.opacity(0.07)],
                                           startPoint: .leading, endPoint: .trailing)
                        } else {
                            LinearGradient(colors: [Color(hex: "#5B8DEF"), Color(hex: "#7C3AED")],
                                           startPoint: .leading, endPoint: .trailing)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .disabled(isLoadingResult || textInput.isEmpty)
            
            Text("Result below:")
                .foregroundStyle(.secondary)

            TextEditor(text: $textOutput)
                .disabled(true)
                .padding(.vertical, 4)
                .scrollContentBackground(.hidden)
                .background(.quaternary)
                .frame(minHeight: 100)
            
            Divider()
            
            HStack {
                Button(
                    "Copy result to clipboard",
                    systemImage: "square.on.square"
                ) {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(textOutput, forType: .string)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .bold()
                .disabled(isLoadingResult || textInput.isEmpty)
                
                Spacer()
                
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                        .bold()
                        .foregroundStyle(.red)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Text("""
                Add GrammarFix app to the menu bar automatically \
                when you log in on your Mac.
                """)
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .onChange(of: launchAtLogin) { _, newValue in
            updateLaunchAtLogin(newValue: newValue)
        }
        .onChange(of: openAPIKey) { _, newValue in
            saveAPIKey(newValue: newValue)
        }
        .onChange(of: selectedMode) { _, newValue in
            SelectedModePreference.value = newValue
        }
        .onAppear {
            loadAPIKey()
        }
    }
    
    private var modePicker: some View {
        HStack(spacing: 6) {
            ForEach(GrammarMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.25)) { selectedMode = mode }
                } label: {
                    Label(mode.rawValue, systemImage: mode.icon)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(
                            selectedMode == mode ? .white : Color.primary.opacity(0.4)
                        )
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Group {
                                if selectedMode == mode {
                                    LinearGradient(
                                        colors: [Color(hex: "#5B8DEF"), Color(hex: "#7C3AED")],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                } else {
                                    Color.primary.opacity(0.06)
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    
    private func updateLaunchAtLogin(newValue: Bool) {
        if newValue == true {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }
    
    private func loadAPIKey() {
        guard let data = KeychainHelper.shared.read(
            service: Constants.Service,
            account: Constants.Account
        ), let key = String(data: data, encoding: .utf8) else {
            return
        }
        openAPIKey = key
    }
    
    private func saveAPIKey(newValue: String) {
        if newValue.isEmpty {
            KeychainHelper.shared.delete(service: Constants.Service, account: Constants.Account)
            return
        }

        guard let data = newValue.data(using: .utf8) else {
            openAPIKey = ""
            return
        }

        if let existingData = KeychainHelper.shared.read(service: Constants.Service, account: Constants.Account),
           let existingKey = String(data: existingData, encoding: .utf8),
           existingKey == newValue {
            return
        }

        KeychainHelper.shared.save(service: Constants.Service, account: Constants.Account, data: data)
    }
}

#Preview {
    ContentView()
}
