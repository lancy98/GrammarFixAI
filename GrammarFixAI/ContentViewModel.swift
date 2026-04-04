//
//  ContentViewModel.swift
//  GrammarFixAI
//
//  Created by Lancy Norbert Fernandes on 04/04/26.
//

import SwiftUI
import ServiceManagement
import FoundationModels

@MainActor
@Observable
final class ContentViewModel {
    
    // MARK: - Private properties

    private var keychainHelper = KeychainHelper()

    // MARK: - UI State

    var textInput: String = ""
    var textOutput: String = ""
    var isLoadingResult: Bool = false
    var launchAtLogin: Bool = false
    var errorMessage: String? = nil
    var copiedToClipboard: Bool = false

    // MARK: - Provider / Mode

    var selectedMode: GrammarMode = Preferences.selectedMode {
        didSet { Preferences.selectedMode = selectedMode }
    }

    var selectedProvider: AIProvider = Preferences.selectedProvider {
        didSet { Preferences.selectedProvider = selectedProvider }
    }

    // MARK: - API Key

    var openAPIKey: String = ""
    var apiKeyMasked: Bool = true
    var apiKeySaved: Bool = false

    // MARK: - Apple Model

    var appleAvailability: SystemLanguageModel.Availability = .available

    // MARK: - Computed:

    var isProviderReady: Bool {
        switch selectedProvider {
        case .apple:  return appleAvailability == .available
        case .openAI: return !openAPIKey.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
    
    var isTextOutputEmpty: Bool {
        textOutput.isEmpty
    }
    
    var isCorrectionButtonDisabled: Bool {
        isLoadingResult || textInput.isEmpty
    }

    // MARK: - Lifecycle

    func onAppear() {
        appleAvailability = SystemLanguageModel.default.availability
        loadAPIKey()
    }

    // MARK: - Grammar correction

    func correct() async {
        errorMessage = nil
        isLoadingResult = true

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

    // MARK: - Clipboard

    func copyToClipboard() {
        guard !textOutput.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(textOutput, forType: .string)

        withAnimation { copiedToClipboard = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            withAnimation { self?.copiedToClipboard = false }
        }
    }

    // MARK: - Launch at login

    func updateLaunchAtLogin(_ enabled: Bool) {
        if enabled {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }

    // MARK: - API Key management

    func toggleAPIKeyVisibility() {
        apiKeyMasked.toggle()
    }

    func saveAPIKey() {
        persistAPIKey(openAPIKey)
        apiKeyMasked = true
        apiKeySaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.apiKeySaved = false
        }
    }

    private func loadAPIKey() {
        guard
            let data = keychainHelper.read(service: Constants.Service, account: Constants.Account),
            let key = String(data: data, encoding: .utf8)
        else { return }
        openAPIKey = key
    }

    private func persistAPIKey(_ newValue: String) {
        guard !newValue.isEmpty else {
            keychainHelper.delete(service: Constants.Service, account: Constants.Account)
            return
        }

        guard let data = newValue.data(using: .utf8) else {
            openAPIKey = ""
            return
        }

        // Skip write if key hasn't changed
        if let existingData = keychainHelper.read(service: Constants.Service, account: Constants.Account),
           let existingKey = String(data: existingData, encoding: .utf8),
           existingKey == newValue {
            return
        }

        keychainHelper.save(service: Constants.Service, account: Constants.Account, data: data)
    }
}
