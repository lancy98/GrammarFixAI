import Foundation

enum GrammarMode: String, CaseIterable {
    case fix     = "Fix"
    case formal  = "Formalize"
    case concise = "Shorten"
    
    var icon: String {
        switch self {
        case .fix:     return "checkmark.circle"
        case .formal:  return "briefcase"
        case .concise: return "scissors"
        }
    }
    
    var prompt: String {
        switch self {
        case .fix:
            return "Fix all grammar, spelling, and punctuation mistakes in the following text. Return only the corrected text, nothing else."
        case .formal:
            return "Rewrite the following text in a professional, formal tone. Fix any grammar issues. Return only the rewritten text, nothing else."
        case .concise:
            return "Rewrite the following text to be more concise and clear. Fix any grammar issues. Return only the rewritten text, nothing else."
        }
    }
}
