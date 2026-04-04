import Foundation
import FoundationModels

struct GrammarCorrector {
    enum CorrectorError: Error {
        case error(String)
    }
        
    private var openAPIKey: String? {
        guard let data = KeychainHelper().read(
            service: Constants.Service,
            account: Constants.Account
        ), let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    func correct(textInput: String) async throws -> String {
        let selectedMode = Preferences.selectedMode
        let fullPrompt = "\(selectedMode.prompt)\n\nText: \(textInput)"

        if Preferences.selectedProvider == .apple {
            return try await runWithApple(prompt: fullPrompt)
        } else {
            guard let openAPIKey else { throw CorrectorError.error("Open API Key not found") }
            let api = OpenAIGrammarCorrector(apiKey: openAPIKey)
            let fullPrompt = "\(selectedMode.prompt)\n\nText: \(textInput)"
            return try await api.correctGrammar(of: fullPrompt)
        }
    }
    
    private func runWithApple(prompt: String) async throws(CorrectorError) -> String {
        do {
            var outputText = ""
            let session = LanguageModelSession()
            let stream  = session.streamResponse(to: prompt)
            for try await snapshot in stream {
                outputText = snapshot.content
            }
            return outputText
        } catch LanguageModelSession.GenerationError.guardrailViolation {
            throw .error("Content flagged by on-device guardrails.")
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            throw .error("Text too long. Please shorten your input.")
        } catch {
            throw .error("Apple model error: \(error.localizedDescription)")
        }
    }
}
