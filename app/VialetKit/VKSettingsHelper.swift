import Foundation
import ServiceManagement

enum VKSettingsHelper {

    // MARK: - Launch at Login

    static var launchAtLogin: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Silently fail — user can retry
            }
        }
    }

    // MARK: - Language

    static var languageOverride: String? {
        get { UserDefaults.standard.string(forKey: "VKLanguageOverride") }
        set { VKLocalization.setLanguageOverride(newValue) }
    }
}
