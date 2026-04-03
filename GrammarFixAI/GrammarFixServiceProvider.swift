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
           
           let semaphore = DispatchSemaphore(value: 0)

           Task {
               do {
                   let fullPrompt = "\(Preferences.selectedMode.prompt)\n\nText: \(input)"
                   
                   let corrector = GrammarCorrector()
                   let output = try await corrector.correct(textInput: fullPrompt)
                   
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
