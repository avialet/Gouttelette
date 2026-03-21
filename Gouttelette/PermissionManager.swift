import Cocoa
import ApplicationServices

class PermissionManager {
    // Vérifie si l'accès Accessibilité est accordé
    static func hasAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    // Demande l'accès Accessibilité (affiche la boîte de dialogue système)
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    // Ouvre les Préférences Système à la section Accessibilité
    static func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
