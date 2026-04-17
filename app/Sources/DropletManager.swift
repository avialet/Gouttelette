import Cocoa
import QuartzCore

class DropletManager: ObservableObject {
    static let shared = DropletManager()

    @Published var droplets: [DropletItem] = []

    @Published var evaporationMinutes: Int {
        didSet { UserDefaults.standard.set(evaporationMinutes, forKey: "evaporationMinutes") }
    }

    private var evaporationTimers: [UUID: Timer] = [:]
    private var dropletPanels: [UUID: DropletPanel] = [:]

    private var detectionWindow: NotchDetectionWindow?
    private var glowWindow: NotchGlowWindow?

    private var globalDragMonitor: Any?
    private var globalMouseUpMonitor: Any?
    private var localDragMonitor: Any?
    private var localMouseUpMonitor: Any?

    private var globalMoveMonitor: Any?
    private var localMoveMonitor: Any?
    private var isRevealed = false
    private static let revealThreshold: CGFloat = 60
    private static let revealDrop: CGFloat = 35
    private static let dropletSpacing: CGFloat = 70  // Espacement fixe entre gouttelettes

    private init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "evaporationMinutes") == nil {
            defaults.set(15, forKey: "evaporationMinutes")
        }
        self.evaporationMinutes = defaults.integer(forKey: "evaporationMinutes")
    }

    // MARK: - Gestion des gouttelettes

    func addDroplet(_ item: DropletItem) {
        droplets.append(item)
        let panel = DropletPanel(dropletItem: item, manager: self)
        dropletPanels[item.id] = panel
        panel.show()
        startEvaporationTimer(for: item)
        redistributeDroplets(animated: true)
    }

    /// Suppression manuelle (clic droit → Supprimer) — fondu simple
    func removeDroplet(_ id: UUID, animated: Bool = true) {
        evaporationTimers[id]?.invalidate()
        evaporationTimers.removeValue(forKey: id)

        guard let panel = dropletPanels.removeValue(forKey: id) else {
            droplets.removeAll { $0.id == id }
            return
        }

        if animated {
            panel.evaporate {
                panel.close()
            }
        } else {
            panel.contentView = nil
            panel.close()
        }

        droplets.removeAll { $0.id == id }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.redistributeDroplets(animated: true)
        }
    }

    /// Expiration par timer — la gouttelette tombe + éclaboussure en bas
    func expireDroplet(_ id: UUID) {
        evaporationTimers[id]?.invalidate()
        evaporationTimers.removeValue(forKey: id)

        guard let panel = dropletPanels.removeValue(forKey: id) else {
            droplets.removeAll { $0.id == id }
            return
        }

        droplets.removeAll { $0.id == id }

        // Garder la position X pour l'éclaboussure
        let splashX = panel.frame.midX

        panel.fall { [weak self] in
            panel.close()
            self?.playSplash(atX: splashX)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.redistributeDroplets(animated: true)
        }
    }

    /// Nettoyage après drag réussi (burst déjà fait)
    func removeDropletTracking(_ id: UUID) {
        evaporationTimers[id]?.invalidate()
        evaporationTimers.removeValue(forKey: id)
        dropletPanels.removeValue(forKey: id)
        droplets.removeAll { $0.id == id }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.redistributeDroplets(animated: true)
        }
    }

    func removeAll() {
        let ids = droplets.map { $0.id }
        for id in ids {
            removeDroplet(id, animated: true)
        }
    }

    // MARK: - Redistribution centrée des gouttelettes

    private func redistributeDroplets(animated: Bool) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let count = droplets.count
        guard count > 0 else { return }

        let size: CGFloat = 60
        let spacing = DropletManager.dropletSpacing

        // Largeur totale du groupe
        let totalWidth = CGFloat(count - 1) * spacing
        let startX = screenFrame.midX - totalWidth / 2

        // Position Y : bien collé en haut, seulement 10px hors écran
        let baseY = screenFrame.origin.y + screenFrame.height - size + 10
        let revealOffset: CGFloat = isRevealed ? DropletManager.revealDrop : 0

        for (i, droplet) in droplets.enumerated() {
            guard let panel = dropletPanels[droplet.id] else { continue }

            let x = startX + CGFloat(i) * spacing - size / 2
            let yJitter = CGFloat(i % 3 == 0 ? -2 : (i % 3 == 1 ? 1 : -1))
            let targetFrame = NSRect(
                x: x,
                y: baseY - revealOffset + yJitter,
                width: size,
                height: size
            )

            if animated {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.5
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    panel.animator().setFrame(targetFrame, display: true)
                }
            } else {
                panel.setFrame(targetFrame, display: true)
            }
        }
    }

    // MARK: - Éclaboussure en bas de l'écran

    private func playSplash(atX x: CGFloat) {
        guard let screen = NSScreen.main else { return }
        let splashSize: CGFloat = 240
        let frame = NSRect(
            x: x - splashSize / 2,
            y: screen.frame.origin.y,
            width: splashSize,
            height: splashSize / 2
        )

        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let splashView = SplashView(frame: NSRect(origin: .zero, size: frame.size))
        window.contentView = splashView
        window.orderFront(nil)

        splashView.animate()

        // Auto-nettoyage
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            window.contentView = nil
            window.close()
        }
    }

    // MARK: - Hover reveal

    private func startHoverMonitoring() {
        globalMoveMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] _ in
            self?.checkMouseProximity()
        }
        localMoveMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.checkMouseProximity()
            return event
        }
    }

    private func stopHoverMonitoring() {
        if let m = globalMoveMonitor { NSEvent.removeMonitor(m) }
        if let m = localMoveMonitor { NSEvent.removeMonitor(m) }
        globalMoveMonitor = nil
        localMoveMonitor = nil
    }

    private func checkMouseProximity() {
        guard let screen = NSScreen.main, !droplets.isEmpty else {
            if isRevealed { hideReveal() }
            return
        }
        let mouseY = NSEvent.mouseLocation.y
        let topOfScreen = screen.frame.origin.y + screen.frame.height
        let distanceFromTop = topOfScreen - mouseY

        if distanceFromTop < DropletManager.revealThreshold && !isRevealed {
            showReveal()
        } else if distanceFromTop >= DropletManager.revealThreshold && isRevealed {
            hideReveal()
        }
    }

    private func showReveal() {
        isRevealed = true
        redistributeDroplets(animated: true)
    }

    private func hideReveal() {
        isRevealed = false
        redistributeDroplets(animated: true)
    }

    // MARK: - Timer d'évaporation

    private func startEvaporationTimer(for item: DropletItem) {
        let interval = TimeInterval(evaporationMinutes * 60)
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.expireDroplet(item.id)
            }
        }
        evaporationTimers[item.id] = timer
    }

    // MARK: - Setup

    func setup() {
        teardown()

        let glow = NotchGlowWindow()
        glowWindow = glow

        let detection = NotchDetectionWindow(manager: self)
        detection.orderFront(nil)
        detectionWindow = detection

        startDragMonitoring()
        startHoverMonitoring()
    }

    func teardown() {
        stopDragMonitoring()
        stopHoverMonitoring()
        detectionWindow?.close()
        detectionWindow = nil
        glowWindow?.close()
        glowWindow = nil
    }

    func refreshWindows() {
        detectionWindow?.setFrame(NotchDetectionWindow.detectionFrame(), display: false)
        glowWindow?.updateFrame()
        redistributeDroplets(animated: false)
    }

    var dropletCount: Int { droplets.count }

    func showNotchGlow() { glowWindow?.showGlow() }
    func hideNotchGlow() { glowWindow?.hideGlow() }

    // MARK: - Monitoring global du drag

    private func startDragMonitoring() {
        globalDragMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] _ in
            self?.activateDetection()
        }
        globalMouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            self?.deactivateDetection()
        }
        localDragMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] event in
            self?.activateDetection()
            return event
        }
        localMouseUpMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            self?.deactivateDetection()
            return event
        }
    }

    private func stopDragMonitoring() {
        if let m = globalDragMonitor { NSEvent.removeMonitor(m) }
        if let m = globalMouseUpMonitor { NSEvent.removeMonitor(m) }
        if let m = localDragMonitor { NSEvent.removeMonitor(m) }
        if let m = localMouseUpMonitor { NSEvent.removeMonitor(m) }
        globalDragMonitor = nil
        globalMouseUpMonitor = nil
        localDragMonitor = nil
        localMouseUpMonitor = nil
    }

    private func activateDetection() {
        if let w = detectionWindow, w.ignoresMouseEvents {
            w.ignoresMouseEvents = false
        }
    }

    private func deactivateDetection() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            if let w = self?.detectionWindow, !w.ignoresMouseEvents {
                w.ignoresMouseEvents = true
            }
        }
    }
}

// MARK: - Vue de l'éclaboussure (Core Animation pur)

class SplashView: NSView {
    private let cyan = NSColor(red: 0.0, green: 0.737, blue: 0.831, alpha: 1.0)

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) { fatalError() }

    func animate() {
        guard let rootLayer = layer else { return }
        let cx = bounds.width / 2
        let impactY: CGFloat = 10

        let particleCount = 14

        for i in 0..<particleCount {
            let size = CGFloat.random(in: 4...14)
            let particle = CAShapeLayer()
            particle.path = CGPath(
                ellipseIn: CGRect(x: -size / 2, y: -size / 2, width: size, height: size),
                transform: nil
            )
            particle.fillColor = cyan.withAlphaComponent(CGFloat.random(in: 0.4...0.9)).cgColor
            particle.position = CGPoint(x: cx, y: impactY)
            particle.shadowColor = cyan.cgColor
            particle.shadowRadius = 4
            particle.shadowOpacity = 0.6
            particle.shadowOffset = .zero
            rootLayer.addSublayer(particle)

            // Angle : éventail vers le haut (demi-cercle supérieur)
            let angle = (CGFloat(i) / CGFloat(particleCount - 1)) * .pi
                + CGFloat.random(in: -0.15...0.15)
            let distance = CGFloat.random(in: 30...100)
            let dx = cos(angle) * distance
            let dy = sin(angle) * distance

            let duration = 0.5 + Double.random(in: 0...0.3)

            let posAnim = CABasicAnimation(keyPath: "position")
            posAnim.toValue = CGPoint(x: cx + dx, y: impactY + dy)
            posAnim.duration = duration
            posAnim.timingFunction = CAMediaTimingFunction(name: .easeOut)
            posAnim.fillMode = .forwards
            posAnim.isRemovedOnCompletion = false
            particle.add(posAnim, forKey: "pos")

            let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
            scaleAnim.fromValue = 1.0
            scaleAnim.toValue = 0.2
            scaleAnim.duration = duration
            scaleAnim.beginTime = CACurrentMediaTime() + 0.15
            scaleAnim.fillMode = .forwards
            scaleAnim.isRemovedOnCompletion = false
            particle.add(scaleAnim, forKey: "scale")

            let opacityAnim = CABasicAnimation(keyPath: "opacity")
            opacityAnim.fromValue = 1.0
            opacityAnim.toValue = 0.0
            opacityAnim.duration = duration
            opacityAnim.beginTime = CACurrentMediaTime() + 0.2
            opacityAnim.fillMode = .forwards
            opacityAnim.isRemovedOnCompletion = false
            particle.add(opacityAnim, forKey: "opacity")
        }

        // Flash d'impact (cercle qui s'étend rapidement)
        let flash = CAShapeLayer()
        let flashSize: CGFloat = 10
        flash.path = CGPath(
            ellipseIn: CGRect(x: -flashSize / 2, y: -flashSize / 2, width: flashSize, height: flashSize),
            transform: nil
        )
        flash.fillColor = NSColor.clear.cgColor
        flash.strokeColor = cyan.withAlphaComponent(0.7).cgColor
        flash.lineWidth = 2
        flash.position = CGPoint(x: cx, y: impactY)
        rootLayer.addSublayer(flash)

        let ringScale = CABasicAnimation(keyPath: "transform.scale")
        ringScale.fromValue = 1.0
        ringScale.toValue = 8.0
        ringScale.duration = 0.5
        ringScale.timingFunction = CAMediaTimingFunction(name: .easeOut)
        ringScale.fillMode = .forwards
        ringScale.isRemovedOnCompletion = false
        flash.add(ringScale, forKey: "scale")

        let ringFade = CABasicAnimation(keyPath: "opacity")
        ringFade.fromValue = 1.0
        ringFade.toValue = 0.0
        ringFade.duration = 0.5
        ringFade.fillMode = .forwards
        ringFade.isRemovedOnCompletion = false
        flash.add(ringFade, forKey: "fade")
    }
}
