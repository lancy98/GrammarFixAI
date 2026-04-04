//
//  GrammarFixServiceProvider.swift
//  GrammarFix
//
//  Created by Lancy Norbert Fernandes on 15/08/25.
//

import AppKit

final class GrammarFixServiceProvider: NSObject {
    private final class ResultBox<T>: @unchecked Sendable {
        var value: Result<T, Error>?
    }
    
    @objc func fix(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString>
    ) {
        guard let input = pasteboard.string(forType: .string) else {
            error.pointee = "no input string" as NSString
            return
        }
        
        let fullPrompt = "\(Preferences.selectedMode.prompt)\n\nText: \(input)"
        let result = runAsyncOnCurrent {
            let corrector = GrammarCorrector()
            return try await corrector.correct(textInput: fullPrompt)
        }
        
        switch result {
        case .success(let output):
            pasteboard.clearContents()
            pasteboard.setString(output, forType: .string)
        case .failure(let err):
            error.pointee = err.localizedDescription as NSString
        }
    }
    
    private func runAsyncOnCurrent<T: Sendable>(
        _ work: @Sendable @escaping () async throws -> T
    ) -> Result<T, Error> {
        let box = ResultBox<T>()
        let group = DispatchGroup()
        group.enter()
        
        Task {
            do {
                box.value = .success(try await work())
            } catch {
                box.value = .failure(error)
            }
            group.leave()
        }
        
        while group.wait(timeout: .now()) == .timedOut {
            RunLoop.current.run(mode: .default, before: .distantPast)
        }
        
        return box.value!
    }
}
