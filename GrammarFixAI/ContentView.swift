//
//  ContentView.swift
//  GrammarFix
//
//  Created by Lancy Norbert Fernandes on 15/08/25.
//

import SwiftUI
import ServiceManagement
import Firebase

struct ContentView: View {
    @State private var openAPIKey = ""
    @State private var textInput = ""
    @State private var textOutput = ""
    @State private var isLoadingResult = false
    @State private var launchAtLogin = false

    var body: some View {
        VStack(alignment: .leading) {
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
                    textOutput = try await api.correctGrammar(of: textInput)
                    isLoadingResult = false
                }
            } label: {
                Text("Fix")
                    .bold()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
            }
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
        .onAppear {
            loadAPIKey()
            Analytics.logEvent("Content View Appear", parameters: nil)
        }
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
