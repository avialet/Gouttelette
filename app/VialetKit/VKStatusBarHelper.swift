import AppKit

enum VKStatusBarHelper {

    /// Create a status bar item with an SF Symbol icon
    static func createStatusItem(
        systemSymbolName: String,
        accessibilityDescription: String
    ) -> NSStatusItem {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setIcon(statusItem, systemSymbolName: systemSymbolName, accessibilityDescription: accessibilityDescription)
        return statusItem
    }

    /// Set the status bar icon to an SF Symbol
    static func setIcon(
        _ statusItem: NSStatusItem,
        systemSymbolName: String,
        accessibilityDescription: String
    ) {
        guard let button = statusItem.button else { return }
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        button.image = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: accessibilityDescription)?
            .withSymbolConfiguration(config)
        // Store original symbol name for badge operations
        button.toolTip = accessibilityDescription
    }

    /// Add a small red dot badge to the status bar icon
    static func addUpdateBadge(to statusItem: NSStatusItem) {
        guard let button = statusItem.button, let originalImage = button.image else { return }

        let size = originalImage.size
        let badgeSize: CGFloat = 6
        let badgeImage = NSImage(size: size, flipped: false) { rect in
            originalImage.draw(in: rect)
            let badgeRect = NSRect(
                x: size.width - badgeSize - 1,
                y: size.height - badgeSize - 1,
                width: badgeSize,
                height: badgeSize
            )
            NSColor.systemRed.setFill()
            NSBezierPath(ovalIn: badgeRect).fill()
            return true
        }
        badgeImage.isTemplate = false
        button.image = badgeImage
    }

    /// Remove the badge and restore the original icon
    static func removeUpdateBadge(from statusItem: NSStatusItem, systemSymbolName: String, accessibilityDescription: String) {
        setIcon(statusItem, systemSymbolName: systemSymbolName, accessibilityDescription: accessibilityDescription)
    }
}
