import Cocoa
import SwiftUI

// Panel flottant pour une gouttelette individuelle
class DropletPanel: NSPanel {
    let dropletItem: DropletItem
    // Référence forte au manager pour éviter nil dans les completions
    let manager: DropletManager

    private static let dropletSize: CGFloat = 60

    init(dropletItem: DropletItem, manager: DropletManager) {
        self.dropletItem = dropletItem
        self.manager = manager

        let frame = DropletPanel.frameForDroplet(dropletItem)
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false

        let contentView = DropletContentView(dropletItem: dropletItem, panel: self)
        contentView.frame = NSRect(origin: .zero, size: frame.size)
        self.contentView = contentView
    }

    // Positionne la gouttelette en haut de l'écran, à moitié hors écran
    static func frameForDroplet(_ item: DropletItem) -> NSRect {
        guard let screen = NSScreen.main else { return .zero }
        let screenFrame = screen.frame
        let size = dropletSize
        let halfSize = size / 2

        // Position horizontale basée sur l'endroit du drop
        var x = item.position.x - halfSize
        // Position verticale : en haut de l'écran, moitié visible
        let y = screenFrame.origin.y + screenFrame.height - size + halfSize

        // Contraindre X dans l'écran
        x = max(screenFrame.origin.x + 10, min(x, screenFrame.origin.x + screenFrame.width - size - 10))

        return NSRect(x: x, y: y, width: size, height: size)
    }

    // Animation d'apparition
    func show() {
        self.alphaValue = 0
        self.orderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.5
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
        }
    }

    // Animation d'évaporation (suppression manuelle)
    func evaporate(completion: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 1.0
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
        }, completionHandler: {
            self.contentView = nil
            completion()
        })
    }

    // Animation de chute (expiration par timer) — tombe comme une vraie goutte d'eau
    func fall(completion: @escaping () -> Void) {
        guard let screen = NSScreen.main else {
            self.contentView = nil
            completion()
            return
        }

        // Destination : sous le bas de l'écran
        let bottomY = screen.frame.origin.y - self.frame.height - 20
        var targetFrame = self.frame
        targetFrame.origin.y = bottomY

        // Léger tremblement avant la chute (la goutte se détache)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            var wobble = self.frame
            wobble.origin.y -= 4
            self.animator().setFrame(wobble, display: true)
        }, completionHandler: {
            // Chute avec accélération (comme la gravité)
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.8
                // EaseIn = accélération = gravité
                context.timingFunction = CAMediaTimingFunction(controlPoints: 0.6, 0.0, 1.0, 1.0)
                self.animator().setFrame(targetFrame, display: true)
                self.animator().alphaValue = 0.7
            }, completionHandler: {
                self.contentView = nil
                completion()
            })
        })
    }

    // Animation d'éclatement (après un drag réussi)
    func burst(completion: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.4
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 0
            var frame = self.frame
            frame = frame.insetBy(dx: -10, dy: -10)
            self.animator().setFrame(frame, display: true)
        }, completionHandler: {
            self.contentView = nil
            completion()
        })
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

// MARK: - Vue AppKit contenant le SwiftUI + gestion du Drag Source

class DropletContentView: NSView, NSDraggingSource {
    let dropletItem: DropletItem
    weak var panel: DropletPanel?
    private var mouseDownLocation: NSPoint = .zero
    private var isDragging = false

    init(dropletItem: DropletItem, panel: DropletPanel) {
        self.dropletItem = dropletItem
        self.panel = panel
        super.init(frame: .zero)

        let hostingView = NSHostingView(rootView: DropletView(item: dropletItem))
        hostingView.frame = bounds
        hostingView.autoresizingMask = [.width, .height]
        addSubview(hostingView)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Gestion de la souris

    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = event.locationInWindow
        isDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        let currentLocation = event.locationInWindow
        let distance = hypot(
            currentLocation.x - mouseDownLocation.x,
            currentLocation.y - mouseDownLocation.y
        )

        if distance > 3 && !isDragging {
            isDragging = true
            startDragSession(with: event)
        }
    }

    // MARK: - Drag Source

    private func startDragSession(with event: NSEvent) {
        guard let pasteboardWriter = createPasteboardWriter() else { return }

        let dragItem = NSDraggingItem(pasteboardWriter: pasteboardWriter)
        let dragImage = createDragImage()
        dragItem.setDraggingFrame(bounds, contents: dragImage)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            self.panel?.animator().alphaValue = 0.3
        }

        beginDraggingSession(with: [dragItem], event: event, source: self)
    }

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .copy
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        if operation != [] {
            let itemId = dropletItem.id
            // Capturer manager AVANT le burst — après contentView=nil,
            // self sera deallocated et self?.panel sera nil
            let manager = panel?.manager
            panel?.burst {
                manager?.removeDropletTracking(itemId)
            }
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                self.panel?.animator().alphaValue = 1
            }
        }
    }

    // MARK: - Pasteboard

    private func createPasteboardWriter() -> NSPasteboardWriting? {
        switch dropletItem.contentType {
        case .text:
            guard let text = dropletItem.textContent else { return nil }
            return text as NSString

        case .fileURL:
            guard let url = dropletItem.fileURLs?.first else { return nil }
            return url as NSURL

        case .image:
            guard let image = dropletItem.imageContent,
                  let tiffData = image.tiffRepresentation else { return nil }
            let pbItem = NSPasteboardItem()
            pbItem.setData(tiffData, forType: .tiff)
            return pbItem

        case .color:
            guard let color = dropletItem.colorContent else { return nil }
            let pbItem = NSPasteboardItem()
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: true) {
                pbItem.setData(data, forType: .color)
            }
            return pbItem
        }
    }

    private func createDragImage() -> NSImage {
        let size = NSSize(width: 50, height: 50)
        let image = NSImage(size: size)
        image.lockFocus()
        let color = NSColor(red: 0.0, green: 0.737, blue: 0.831, alpha: 0.7)
        color.setFill()
        let path = NSBezierPath(ovalIn: NSRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4))
        path.fill()
        image.unlockFocus()
        return image
    }

    // MARK: - Menu contextuel

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        let deleteItem = NSMenuItem(title: "Supprimer", action: #selector(deleteDroplet), keyEquivalent: "")
        deleteItem.target = self
        menu.addItem(deleteItem)
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    @objc private func deleteDroplet() {
        panel?.manager.removeDroplet(dropletItem.id, animated: true)
    }
}
