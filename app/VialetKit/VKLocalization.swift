import Foundation

/// Lookup a VialetKit common string from VialetKit.strings
func VL(_ key: String) -> String {
    let lang = VKLocalization.currentLanguage
    if let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
       let bundle = Bundle(path: path) {
        let value = bundle.localizedString(forKey: key, value: nil, table: "VialetKit")
        if value != key { return value }
    }
    // Fallback to English
    if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
       let bundle = Bundle(path: path) {
        let value = bundle.localizedString(forKey: key, value: nil, table: "VialetKit")
        if value != key { return value }
    }
    return key
}

/// Lookup a VialetKit common string with format arguments
func VL(_ key: String, _ args: CVarArg...) -> String {
    let format = VL(key)
    return String(format: format, arguments: args)
}

/// Lookup an app-specific string from Localizable.strings
func AL(_ key: String) -> String {
    let lang = VKLocalization.currentLanguage
    if let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
       let bundle = Bundle(path: path) {
        let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
        if value != key { return value }
    }
    if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
       let bundle = Bundle(path: path) {
        let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
        if value != key { return value }
    }
    return key
}

/// Lookup an app-specific string with format arguments
func AL(_ key: String, _ args: CVarArg...) -> String {
    let format = AL(key)
    return String(format: format, arguments: args)
}

enum VKLocalization {
    private static let overrideKey = "VKLanguageOverride"

    /// Current active language code
    static var currentLanguage: String {
        // 1. User override
        if let override = UserDefaults.standard.string(forKey: overrideKey),
           VK.supportedLanguages.contains(override) {
            return override
        }
        // 2. System language
        for preferred in Locale.preferredLanguages {
            let code = String(preferred.prefix(2))
            if VK.supportedLanguages.contains(code) {
                return code
            }
        }
        // 3. Fallback
        return VK.defaultLanguage
    }

    /// Set a language override (nil to use system language)
    static func setLanguageOverride(_ code: String?) {
        if let code = code, VK.supportedLanguages.contains(code) {
            UserDefaults.standard.set(code, forKey: overrideKey)
        } else {
            UserDefaults.standard.removeObject(forKey: overrideKey)
        }
    }

    /// Get the display name of a language code in its own language
    static func displayName(for code: String) -> String {
        let locale = Locale(identifier: code)
        return locale.localizedString(forLanguageCode: code)?.capitalized ?? code.uppercased()
    }
}
