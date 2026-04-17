import Cocoa
import QuartzCore

// ============================================================
// Zone de détection au sommet de l'écran (notch / Dynamic Island)
// ============================================================

class NotchDetectionWindow: NSWindow {
    let manager: DropletManager

    init(manager: DropletManager) {
        self.manager = manager
        let frame = NotchDetectionWindow.detectionFrame()
        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.level = .statusBar
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false

        let dropView = NotchDropView(manager: manager)
        dropView.frame = NSRect(origin: .zero, size: frame.size)
        dropView.autoresizingMask = [.width, .height]
        self.contentView = dropView
        self.registerForDraggedTypes(NotchDropView.acceptedTypes)
    }

    static func detectionFrame() -> NSRect {
        guard let screen = NSScreen.main else { return .zero }
        let screenFrame = screen.frame
        let width: CGFloat = 400
        let height: CGFloat = 160
        let x = screenFrame.origin.x + (screenFrame.width - width) / 2
        let y = screenFrame.origin.y + screenFrame.height - height
        return NSRect(x: x, y: y, width: width, height: height)
    }
}

// MARK: - Vue de réception du drop (NSView pur, PAS de SwiftUI)

class NotchDropView: NSView {
    let manager: DropletManager

    static let acceptedTypes: [NSPasteboard.PasteboardType] = [
        .string, .fileURL, .png, .tiff, .color,
        .URL, .html, .rtf, .rtfd
    ]

    init(manager: DropletManager) {
        self.manager = manager
        super.init(frame: .zero)
        self.registerForDraggedTypes(NotchDropView.acceptedTypes)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        manager.showNotchGlow()
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        manager.hideNotchGlow()
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        manager.hideNotchGlow()

        let pasteboard = sender.draggingPasteboard
        let dropPoint = sender.draggingLocation
        let screenPoint = self.window?.convertPoint(toScreen: dropPoint) ?? dropPoint

        let item: DropletItem

        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ]) as? [URL], !urls.isEmpty {
            item = DropletItem(contentType: .fileURL, position: screenPoint)
            item.fileURLs = urls
        }
        else if let images = pasteboard.readObjects(forClasses: [NSImage.self]) as? [NSImage],
                let image = images.first {
            item = DropletItem(contentType: .image, position: screenPoint)
            item.imageContent = image
        }
        else if let data = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff),
                let image = NSImage(data: data) {
            item = DropletItem(contentType: .image, position: screenPoint)
            item.imageContent = image
        }
        else if let text = pasteboard.string(forType: .string), !text.isEmpty {
            item = DropletItem(contentType: .text, position: screenPoint)
            item.textContent = text
        }
        else if let color = NSColor(from: pasteboard) {
            item = DropletItem(contentType: .color, position: screenPoint)
            item.colorContent = color
        }
        else {
            return false
        }

        manager.addDroplet(item)
        return true
    }
}

// ============================================================
// Fenêtre de glow persistante — PAS de SwiftUI, CALayer uniquement
// ============================================================

class NotchGlowWindow: NSWindow {
    let glowView: NotchGlowView

    init() {
        let frame = NotchGlowWindow.glowFrame()
        let view = NotchGlowView(frame: NSRect(origin: .zero, size: frame.size))
        self.glowView = view

        super.init(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        self.level = .statusBar
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false
        self.alphaValue = 0

        self.contentView = view
        self.orderFront(nil)
    }

    static func glowFrame() -> NSRect {
        guard let screen = NSScreen.main else { return .zero }
        let screenFrame = screen.frame
        let width: CGFloat = 360
        let height: CGFloat = 280
        let x = screenFrame.origin.x + (screenFrame.width - width) / 2
        let y = screenFrame.origin.y + screenFrame.height - height
        return NSRect(x: x, y: y, width: width, height: height)
    }

    func showGlow() {
        glowView.startMorphing()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
        }
    }

    func hideGlow() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.glowView.stopMorphing()
        })
    }

    func updateFrame() {
        let frame = NotchGlowWindow.glowFrame()
        self.setFrame(frame, display: false)
        glowView.frame = NSRect(origin: .zero, size: frame.size)
        glowView.rebuildLayers()
    }
}

// ============================================================
// Vue du glow — Blob organique en Core Animation
// Forme fluide qui morphe en continu, comme une goutte d'eau vivante
// ============================================================

class NotchGlowView: NSView {
    private let cyan = NSColor(red: 0.0, green: 0.737, blue: 0.831, alpha: 1.0)
    private let cyanLight = NSColor(red: 0.302, green: 0.816, blue: 0.882, alpha: 1.0)

    private var blobGlowLayer: CAShapeLayer?
    private var blobFillLayer: CAShapeLayer?
    private var blobStrokeLayer: CAShapeLayer?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        rebuildLayers()
    }

    required init?(coder: NSCoder) { fatalError() }

    func rebuildLayers() {
        blobGlowLayer?.removeFromSuperlayer()
        blobFillLayer?.removeFromSuperlayer()
        blobStrokeLayer?.removeFromSuperlayer()

        guard let rootLayer = layer else { return }
        let w = bounds.width
        let h = bounds.height

        let pathA = createBlobPath(width: w, height: h, phase: 0)
        let pathB = createBlobPath(width: w, height: h, phase: .pi)
        let pathC = createBlobPath(width: w, height: h, phase: .pi * 1.5)

        // 1. Glow diffus (ombre large)
        let glow = CAShapeLayer()
        glow.path = pathA
        glow.fillColor = cyan.withAlphaComponent(0.08).cgColor
        glow.strokeColor = NSColor.clear.cgColor
        glow.shadowColor = cyan.cgColor
        glow.shadowRadius = 40
        glow.shadowOpacity = 0.9
        glow.shadowOffset = .zero
        rootLayer.addSublayer(glow)
        blobGlowLayer = glow

        // 2. Remplissage translucide du blob
        let fill = CAShapeLayer()
        fill.path = pathA
        fill.fillColor = cyan.withAlphaComponent(0.08).cgColor
        fill.strokeColor = cyan.withAlphaComponent(0.25).cgColor
        fill.lineWidth = 5
        fill.shadowColor = cyan.cgColor
        fill.shadowRadius = 18
        fill.shadowOpacity = 0.6
        fill.shadowOffset = .zero
        rootLayer.addSublayer(fill)
        blobFillLayer = fill

        // 3. Bordure fine nette
        let stroke = CAShapeLayer()
        stroke.path = pathA
        stroke.fillColor = NSColor.clear.cgColor
        stroke.strokeColor = cyanLight.withAlphaComponent(0.6).cgColor
        stroke.lineWidth = 1.5
        stroke.lineCap = .round
        stroke.lineJoin = .round
        rootLayer.addSublayer(stroke)
        blobStrokeLayer = stroke

        // Préparer les paths pour le morphing
        blobPaths = [pathA, pathB, pathC, pathA]
    }

    private var blobPaths: [CGPath] = []

    /// Crée un blob organique — comme une goutte d'eau en suspension
    private func createBlobPath(width w: CGFloat, height h: CGFloat, phase: CGFloat) -> CGPath {
        let cx = w / 2
        // Blob centré en haut de la vue (connecté au haut de l'écran)
        let cy = h * 0.55
        let baseRadius = min(w, h) * 0.33
        let n = 8

        func pointAt(angle: CGFloat) -> CGPoint {
            // Déformations organiques multi-fréquences
            let d1 = sin(angle * 2.0 + phase) * 0.14
            let d2 = cos(angle * 3.0 - phase * 0.7) * 0.09
            let d3 = sin(angle * 5.0 + phase * 1.3) * 0.05
            // Plus large en haut (simuler la connexion au bord supérieur)
            let verticalStretch: CGFloat = 1.0 + cos(angle) * 0.12
            let r = baseRadius * (1.0 + d1 + d2 + d3) * verticalStretch
            return CGPoint(x: cx + cos(angle) * r, y: cy + sin(angle) * r)
        }

        let path = CGMutablePath()
        let p0 = pointAt(angle: 0)
        path.move(to: p0)

        for i in 1...n {
            let angle = CGFloat(i % n) / CGFloat(n) * .pi * 2
            let prevAngle = CGFloat(i - 1) / CGFloat(n) * .pi * 2
            let step = angle - prevAngle + (i == n ? .pi * 2 : 0)

            let cp1 = pointAt(angle: prevAngle + step * 0.33)
            let cp2 = pointAt(angle: prevAngle + step * 0.66)
            let dest = pointAt(angle: i == n ? 0 : angle)

            path.addCurve(to: dest, control1: cp1, control2: cp2)
        }

        return path
    }

    // MARK: - Morphing continu

    func startMorphing() {
        guard blobPaths.count >= 4 else { return }

        let morphAnim = CAKeyframeAnimation(keyPath: "path")
        morphAnim.values = blobPaths
        morphAnim.keyTimes = [0, 0.33, 0.66, 1.0] as [NSNumber]
        morphAnim.duration = 3.0
        morphAnim.repeatCount = .infinity
        morphAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        morphAnim.calculationMode = .cubic

        blobGlowLayer?.add(morphAnim, forKey: "morph")
        blobFillLayer?.add(morphAnim, forKey: "morph")
        blobStrokeLayer?.add(morphAnim, forKey: "morph")

        // Pulsation du glow
        let pulse = CABasicAnimation(keyPath: "shadowOpacity")
        pulse.fromValue = 0.4
        pulse.toValue = 1.0
        pulse.duration = 1.2
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        blobGlowLayer?.add(pulse, forKey: "pulse")
        blobFillLayer?.add(pulse, forKey: "pulse")
    }

    func stopMorphing() {
        blobGlowLayer?.removeAllAnimations()
        blobFillLayer?.removeAllAnimations()
        blobStrokeLayer?.removeAllAnimations()
    }
}
