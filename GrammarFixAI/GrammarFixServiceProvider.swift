//
//  GrammarFixServiceProvider.swift
//  GrammarFix
//
//  Created by Lancy Norbert Fernandes on 15/08/25.
//

import AppKit

final class GrammarFixServiceProvider: NSObject {
    
    @objc func fix(
           _ pasteboard: NSPasteboard,
           userData: String?,
           error: AutoreleasingUnsafeMutablePointer<NSString>
       ) {
           guard let input = pasteboard.string(forType: .string) else {
               error.pointee = "no input string" as NSString
               return
           }
           
           guard let apiKeyData = KeychainHelper.shared.read(
            service: Constants.Service,
            account: Constants.Account
           ), let apiKey = String(data: apiKeyData, encoding: .utf8) else {
               error.pointee = "no api key available" as NSString
               return
           }
           
           let semaphore = DispatchSemaphore(value: 0)

           Task {
               do {
                   let api = GrammarCorrector(apiKey: apiKey)
                   let selectedMode = SelectedModePreference.value
                   let fullPrompt = "\(selectedMode.prompt)\n\nText: \(input)"
                   let output = try await api.correctGrammar(of: fullPrompt)
                   pasteboard.clearContents()
                   pasteboard.setString(output, forType: .string)
               } catch {
                   print(error.localizedDescription)
               }
               semaphore.signal()
           }
           
           semaphore.wait()
       }
}
