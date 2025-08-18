//
//  ChatMessage.swift
//  GrammarFix
//
//  Created by Lancy Norbert Fernandes on 15/08/25.
//

import Foundation

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

struct ChatChoice: Codable {
    struct Message: Codable {
        let role: String
        let content: String
    }
    let index: Int
    let message: Message
    let finish_reason: String?
}

struct ChatResponse: Codable {
    let id: String
    let choices: [ChatChoice]
}

enum GrammarAPIError: Error, LocalizedError {
    case emptyResponse
    case badStatus(Int, String)
    
    var errorDescription: String? {
        switch self {
        case .emptyResponse: return "Empty response from OpenAI."
        case .badStatus(let code, let body): return "OpenAI API error \(code): \(body)"
        }
    }
}

final class GrammarCorrector {
    private let apiKey: String
    private let model: String
    
    /// - Parameters:
    ///   - apiKey: Your OpenAI API key (e.g. from Keychain or environment)
    ///   - model: A small/fast model is ideal for grammar (e.g. "gpt-4o-mini")
    init(apiKey: String, model: String = "gpt-4.1-nano") {
        self.apiKey = apiKey
        self.model = model
    }
    
    /// Returns the text corrected to standard English.
    func correctGrammar(of text: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        // System prompt keeps the model laser-focused on grammar only.
        let messages = [
            ChatMessage(
                role: "system",
                content: """
                    You are a professional writing assistant.  
                    Your task is to improve user-provided text by:  
                    - Correcting grammar, spelling, punctuation, and capitalization  
                    - Enhancing clarity, conciseness, and readability  
                    - Adjusting tone and style to fit the context appropriately  
                    - Improving flow and vocabulary where beneficial  

                    Preserve the original meaning.  
                    Return only the improved version of the text, without explanations or commentary.
            """),
            ChatMessage(role: "user", content: text)
        ]
        
        let body = ChatRequest(model: model, messages: messages, temperature: 0.0)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw GrammarAPIError.badStatus(http.statusCode, bodyText)
        }
        
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let output = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines),
              !output.isEmpty else {
            throw GrammarAPIError.emptyResponse
        }
        return output
    }
}
