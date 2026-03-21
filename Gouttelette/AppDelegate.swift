import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let manager = DropletManager.shared
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        manager.setup()

        // Observer les changements d'écran (moniteur branché/débranché)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    // MARK: - Status Bar

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "drop.fill", accessibilityDescription: "Gouttelette")
        }

        updateMenu()
    }

    private func updateMenu() {
        let menu = NSMenu()

        let countItem = NSMenuItem(title: "Gouttelettes actives : \(manager.dropletCount)", action: nil, keyEquivalent: "")
        countItem.isEnabled = false
        menu.addItem(countItem)

        menu.addItem(NSMenuItem.separator())

        let deleteAllItem = NSMenuItem(title: "Supprimer toutes les Gouttelettes", action: #selector(removeAllDroplets), keyEquivalent: "")
        deleteAllItem.target = self
        deleteAllItem.isEnabled = manager.dropletCount > 0
        menu.addItem(deleteAllItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Paramètres…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quitter Gouttelette", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        menu.delegate = self
        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func removeAllDroplets() {
        manager.removeAll()
    }

    @objc private func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(manager: manager)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Gouttelette — Paramètres"
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.settingsWindow = window
    }

    @objc private func screenDidChange() {
        manager.refreshWindows()
    }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        if let countItem = menu.items.first {
            countItem.title = "Gouttelettes actives : \(manager.dropletCount)"
        }
        if menu.items.count > 2 {
            menu.items[2].isEnabled = manager.dropletCount > 0
        }
    }
}
