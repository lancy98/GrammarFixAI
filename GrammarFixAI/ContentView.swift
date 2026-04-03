//
//  ContentView.swift
//  GrammarFix
//
//  Created by Lancy Norbert Fernandes on 15/08/25.
//

import SwiftUI
import ServiceManagement
import FoundationModels

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var openAPIKey = ""
    @State private var textInput = ""
    @State private var textOutput = ""
    @State private var isLoadingResult = false
    @State private var launchAtLogin = false
    @State private var selectedMode: GrammarMode = Preferences.selectedMode
    @State private var selectedProvider: AIProvider = Preferences.selectedProvider
    @State private var errorMessage: String? = nil
    @State private var appleAvailability: SystemLanguageModel.Availability = .available
    @State private var apiKeyMasked: Bool   = true
    @State private var apiKeySaved: Bool    = false
    @State private var copiedToClipboard: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                providerToggle
                providerBadge
            }
            modePicker

            if selectedProvider == .openAI {
                apiKeyRow
            }
            
            Text("Add your text below:")
                .foregroundStyle(.secondary)
            TextEditor(text: $textInput)
                .padding(.vertical, 4)
                .scrollContentBackground(.hidden)
                .background(.quaternary)
                .frame(minHeight: 100)
            
            Button {
                errorMessage = nil
                isLoadingResult = true
                Task {
                    let fullPrompt = "\(selectedMode.prompt)\n\nText: \(textInput)"
                    let corrector = GrammarCorrector()
                    do {
                        textOutput = try await corrector.correct(textInput: fullPrompt)
                    } catch GrammarCorrector.CorrectorError.error(let error) {
                        errorMessage = error
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                    isLoadingResult = false
                }
            } label: {
                HStack(spacing: 7) {
                    if isLoadingResult {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                            .tint(actionButtonForeground)
                    } else {
                        Image(systemName: "wand.and.stars")
                            .imageScale(.small)
                    }
                    Text(isLoadingResult ? "Fixing…" : "\(selectedMode.rawValue) with \(selectedProvider.rawValue)")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(actionButtonForeground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isLoadingResult || textInput.isEmpty {
                            LinearGradient(colors: [disabledActionButtonBackground, disabledActionButtonBackground],
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

            TextEditor(text: textOutput.isEmpty ? .constant("Corrected text will appear here…") : $textOutput)
                .disabled(true)
                .padding(.vertical, 4)
                .foregroundColor(outputTextColor)
                .scrollContentBackground(.hidden)
                .background(outputBG)
                .frame(minHeight: 100)

            if let error = errorMessage {
                errorBanner(error)
            }
            
            Divider()
            
            HStack {
                Button {
                    copyToClipboard()
                } label: {
                    Label(copiedToClipboard ? "Copied!" : "Copy Result",
                          systemImage: copiedToClipboard ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(copiedToClipboard ? Color(hex: "#34D399") : Color(hex: "#5B8DEF"))
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
        .onChange(of: selectedMode) { _, newValue in
            Preferences.selectedMode = newValue
        }
        .onChange(of: selectedProvider) { _, newValue in
            Preferences.selectedProvider = newValue
        }
        .onAppear {
            appleAvailability = SystemLanguageModel.default.availability
            loadAPIKey()
        }
    }
    
    private var apiKeyRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "key.horizontal")
                .font(.system(size: 11))
                .foregroundColor(apiKeyIconColor)

            Group {
                if apiKeyMasked && !openAPIKey.isEmpty {
                    Text(String(repeating: "•", count: min(openAPIKey.count, 30)))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(apiKeyMaskedColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                } else {
                    TextField("Paste your OpenAI API key…", text: $openAPIKey)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(apiKeyTextColor)
                        .textFieldStyle(.plain)
                        .onSubmit { saveAPIKey() }
                }
            }

            // Show / hide
            Button {
                apiKeyMasked.toggle()
            } label: {
                Image(systemName: apiKeyMasked ? "eye" : "eye.slash")
                    .font(.system(size: 11))
                    .foregroundColor(apiKeyIconColor)
            }
            .buttonStyle(.plain)

            // Save
            Button { saveAPIKey() } label: {
                Text(apiKeySaved ? "Saved ✓" : "Save")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(apiKeySaved ? Color(hex: "#34D399") : Color(hex: "#60A5FA"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        (apiKeySaved ? Color(hex: "#34D399") : Color(hex: "#60A5FA")).opacity(0.12)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            .disabled(openAPIKey.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(apiKeyBackgroundColor)
    }

    
    private var outputBG: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(textOutput.isEmpty
                  ? outputBackgroundEmpty
                  : outputBackgroundFilled)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(textOutput.isEmpty
                            ? outputBorderEmpty
                            : outputBorderFilled,
                            lineWidth: 0.5)
            )
    }
    
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill")
            Text(message)
        }
        .font(.system(size: 11))
        .foregroundColor(Color(hex: "#F87171"))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#F87171").opacity(0.09))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    @MainActor
    private func runWithApple(prompt: String) async -> String {
        do {
            var outputText = ""
            let session = LanguageModelSession()
            let stream  = session.streamResponse(to: prompt)
            for try await snapshot in stream {
                outputText = snapshot.content
            }
            return outputText
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            errorMessage = "Content flagged by on-device guardrails."
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            print("Text too long. Please shorten your input")
            errorMessage = "Text too long. Please shorten your input."
        } catch {
            errorMessage = "Apple model error: \(error.localizedDescription)"
        }
        return ""
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

    private var providerToggle: some View {
        HStack(spacing: 0) {
            ForEach(AIProvider.allCases, id: \.self) { provider in
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        selectedProvider = provider
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: provider.icon)
                            .font(.system(size: 10, weight: .medium))
                        Text(provider.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(selectedProvider == provider ? .white : providerToggleInactiveText)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Group {
                            if selectedProvider == provider {
                                LinearGradient(
                                    colors: [Color(hex: "#5B8DEF"), Color(hex: "#7C3AED")],
                                    startPoint: .leading, endPoint: .trailing
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            } else {
                                Color.clear
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(providerToggleBackground)
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(providerToggleBorder, lineWidth: 0.5))
    }

    private var isDark: Bool {
        colorScheme == .dark
    }

    private var actionButtonForeground: Color {
        if isLoadingResult || textInput.isEmpty {
            return isDark ? Color.white.opacity(0.6) : Color.primary.opacity(0.6)
        }
        return .white
    }

    private var disabledActionButtonBackground: Color {
        isDark ? Color.white.opacity(0.07) : Color.black.opacity(0.08)
    }

    private var outputTextColor: Color {
        if textOutput.isEmpty {
            return .secondary
        }
        return isDark ? Color(hex: "#A7F3D0") : Color(hex: "#065F46")
    }

    private var outputBackgroundEmpty: Color {
        isDark ? Color.white.opacity(0.03) : Color.black.opacity(0.04)
    }

    private var outputBackgroundFilled: Color {
        isDark ? Color(hex: "#064E3B").opacity(0.28) : Color(hex: "#A7F3D0").opacity(0.22)
    }

    private var outputBorderEmpty: Color {
        isDark ? Color.white.opacity(0.07) : Color.black.opacity(0.08)
    }

    private var outputBorderFilled: Color {
        isDark ? Color(hex: "#34D399").opacity(0.22) : Color(hex: "#059669").opacity(0.35)
    }

    private var apiKeyIconColor: Color {
        isDark ? Color.white.opacity(0.35) : Color.black.opacity(0.35)
    }

    private var apiKeyMaskedColor: Color {
        isDark ? Color.white.opacity(0.5) : Color.black.opacity(0.5)
    }

    private var apiKeyTextColor: Color {
        isDark ? .white : .primary
    }

    private var apiKeyBackgroundColor: Color {
        isDark ? Color.white.opacity(0.025) : Color.black.opacity(0.04)
    }

    private var providerToggleBackground: Color {
        isDark ? Color.white.opacity(0.07) : Color.black.opacity(0.06)
    }

    private var providerToggleBorder: Color {
        isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.12)
    }

    private var providerToggleInactiveText: Color {
        isDark ? Color.white.opacity(0.4) : Color.primary.opacity(0.6)
    }
    
    @ViewBuilder
    private var providerBadge: some View {
        let isReady: Bool = {
            switch selectedProvider {
            case .apple:  return appleAvailability == .available
            case .openAI: return !openAPIKey.trimmingCharacters(in: .whitespaces).isEmpty
            }
        }()
        let color = isReady ? Color(hex: selectedProvider.badgeColor) : Color(hex: "#F87171")
        let label = isReady ? selectedProvider.badgeLabel : "Not Set"
        let icon  = isReady ? selectedProvider.badgeIcon  : "exclamationmark.triangle"

        Label(label, systemImage: icon)
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
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
    
    private func saveAPIKey() {
        saveAPIKey(newValue: openAPIKey)
        apiKeyMasked = true
        apiKeySaved  = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { apiKeySaved = false }
    }
    
    private func copyToClipboard() {
        guard !textOutput.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(textOutput, forType: .string)

        withAnimation { copiedToClipboard = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copiedToClipboard = false }
        }
    }
}

#Preview {
    ContentView()
}
