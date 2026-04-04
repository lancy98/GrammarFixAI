import Foundation

enum Preferences {
    
    private static var selectedModeStorage: SharedPreference<GrammarMode> {
        SharedPreference<GrammarMode>(
            key: "selectedMode",
            defaultValue: .fix
        )
    }
    
    static var selectedMode: GrammarMode {
        get { selectedModeStorage.value }
        set { selectedModeStorage.value = newValue }
    }
    
    private static var selectedProviderStorage: SharedPreference<AIProvider> {
        SharedPreference<AIProvider>(
           key: "selectedProvider",
           defaultValue: .apple
       )
    }
    
    static var selectedProvider: AIProvider {
        get { selectedProviderStorage.value }
        set { selectedProviderStorage.value = newValue }
    }
}

final class SharedPreference<Value: RawRepresentable> where Value.RawValue == String {
    private let suiteName: String = "group.com.lancy.grammarfixai.shared"
    private let key: String
    private let defaultValue: Value
    
    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }
    
    init(key: String, defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var value: Value {
        get {
            guard
                let defaults,
                let rawValue = defaults.string(forKey: key),
                let value = Value(rawValue: rawValue)
            else {
                return defaultValue
            }
            return value
        }
        
        set {
            defaults?.set(newValue.rawValue, forKey: key)
        }
    }
}
