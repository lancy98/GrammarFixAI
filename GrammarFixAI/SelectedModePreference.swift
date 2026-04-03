import Foundation

struct SelectedModePreference {
    static private let suiteName = "group.com.lancy.grammarfixai.shared"
    static private let keyName = "selectedMode"
    
    static private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
    
    static var value: GrammarMode {
        get {
            guard let defaults, let rawValue = defaults.string(forKey: keyName) else { return .fix }
            return GrammarMode(rawValue: rawValue) ?? .fix
        }
        
        set {
            guard let defaults else { return }
            defaults.set(newValue.rawValue, forKey: keyName)
        }
    }
}
