import AppKit

enum VKMenuBuilder {

    /// Add common Vialet items to the bottom of a menu
    static func addCommonItems(
        to menu: NSMenu,
        appName: String,
        updateChecker: VKUpdateChecker,
        aboutTarget: AnyObject?,
        aboutAction: Selector?
    ) {
        menu.addItem(NSMenuItem.separator())

        // Update available
        if updateChecker.updateAvailable, let version = updateChecker.latestVersion {
            let updateItem = NSMenuItem(
                title: VL("vk.update.available", version),
                action: #selector(VKMenuActionHandler.openUpdate(_:)),
                keyEquivalent: ""
            )
            let handler = VKMenuActionHandler(updateChecker: updateChecker)
            updateItem.target = handler
            updateItem.representedObject = handler // retain
            updateItem.image = NSImage(systemSymbolName: "arrow.down.circle.fill", accessibilityDescription: nil)
            menu.addItem(updateItem)
        }

        // Check for updates
        let checkItem = NSMenuItem(
            title: VL("vk.update.check"),
            action: #selector(VKMenuActionHandler.checkUpdate(_:)),
            keyEquivalent: ""
        )
        let handler = VKMenuActionHandler(updateChecker: updateChecker)
        checkItem.target = handler
        checkItem.representedObject = handler
        menu.addItem(checkItem)

        menu.addItem(NSMenuItem.separator())

        // About
        if let aboutTarget = aboutTarget, let aboutAction = aboutAction {
            let aboutItem = NSMenuItem(
                title: VL("vk.about", appName),
                action: aboutAction,
                keyEquivalent: ""
            )
            aboutItem.target = aboutTarget
            menu.addItem(aboutItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: VL("vk.quit", appName),
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
    }
}

/// Action handler retained by menu items
class VKMenuActionHandler: NSObject {
    let updateChecker: VKUpdateChecker

    init(updateChecker: VKUpdateChecker) {
        self.updateChecker = updateChecker
    }

    @objc func openUpdate(_ sender: Any?) {
        updateChecker.openDownloadPage()
    }

    @objc func checkUpdate(_ sender: Any?) {
        updateChecker.checkNow(force: true)
    }
}
