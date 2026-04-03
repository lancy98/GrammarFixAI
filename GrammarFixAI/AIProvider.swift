import Foundation

enum AIProvider: String, CaseIterable {
    case apple = "Apple"
    case openAI = "OpenAI"

    var icon: String {
        switch self {
        case .apple:  return "apple.logo"
        case .openAI: return "brain.head.profile"
        }
    }

    var badgeLabel: String {
        switch self {
        case .apple:  return "On-Device"
        case .openAI: return OpenAIGrammarCorrector.model
        }
    }

    var badgeIcon: String {
        switch self {
        case .apple:  return "cpu"
        case .openAI: return "network"
        }
    }

    var badgeColor: String {
        switch self {
        case .apple:  return "#34D399"
        case .openAI: return "#60A5FA"
        }
    }
}
