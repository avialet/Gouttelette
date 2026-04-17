import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let manager = DropletManager.shared
    let updateChecker = VKUpdateChecker(appKey: "gouttelette")
    var settingsWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = VKStatusBarHelper.createStatusItem(
            systemSymbolName: "drop.fill",
            accessibilityDescription: "Gouttelette"
        )
        statusItem.menu = NSMenu()
        statusItem.menu?.delegate = self

        manager.setup()
        updateChecker.startPeriodicCheck()

        updateChecker.$updateAvailable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] avail in
                guard let self = self, avail else { return }
                VKStatusBarHelper.addUpdateBadge(to: self.statusItem)
            }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
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
        window.title = "Gouttelette — \(AL("gouttelette.settings"))"
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
        menu.removeAllItems()

        // Active count
        let countItem = NSMenuItem(
            title: AL("gouttelette.activeCount", manager.dropletCount),
            action: nil,
            keyEquivalent: ""
        )
        countItem.isEnabled = false
        menu.addItem(countItem)

        menu.addItem(NSMenuItem.separator())

        // Remove all
        let deleteAllItem = NSMenuItem(
            title: AL("gouttelette.removeAll"),
            action: #selector(removeAllDroplets),
            keyEquivalent: ""
        )
        deleteAllItem.target = self
        deleteAllItem.isEnabled = manager.dropletCount > 0
        menu.addItem(deleteAllItem)

        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(
            title: AL("gouttelette.settings"),
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        // Launch at login
        let loginItem = NSMenuItem(
            title: VL("vk.launchAtLogin"),
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = VKSettingsHelper.launchAtLogin ? .on : .off
        menu.addItem(loginItem)

        // VialetKit common items (update, about, quit)
        VKMenuBuilder.addCommonItems(
            to: menu,
            appName: "Gouttelette",
            updateChecker: updateChecker,
            aboutTarget: nil,
            aboutAction: nil
        )
    }

    @objc private func toggleLaunchAtLogin() {
        VKSettingsHelper.launchAtLogin.toggle()
    }
}
