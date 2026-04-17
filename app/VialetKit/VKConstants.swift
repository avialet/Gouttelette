import Foundation

enum VK {
    static let versionsURL = "https://vialet.app/versions.json"
    static let updateCheckInterval: TimeInterval = 43200 // 12h
    static let bundleIdentifierPrefix = "app.vialet."
    static let supportedLanguages = ["fr", "en", "de", "it", "es"]
    static let defaultLanguage = "en"
    static let websiteBaseURL = "https://vialet.app"
}
