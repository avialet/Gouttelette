import SwiftUI

// Couleur accent Gouttelette : Cyan #00BCD4
let kAccentCyan = Color(red: 0.0, green: 0.737, blue: 0.831)
let kAccentCyanLight = Color(red: 0.302, green: 0.816, blue: 0.882) // #4DD0E1
let kAccentCyanDark = Color(red: 0.0, green: 0.592, blue: 0.655)   // #0097A7

// MARK: - Forme organique de gouttelette

struct DropletShape: Shape {
    var phase: Double

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    private func pointAt(angle: Double, cx: Double, cy: Double, radius: Double) -> CGPoint {
        let deform: Double = sin(angle * 2 + phase) * 0.08 + cos(angle * 3 - phase * 0.7) * 0.05
        let r: Double = radius * (1.0 + deform)
        return CGPoint(x: cx + cos(angle) * r, y: cy + sin(angle) * r)
    }

    func path(in rect: CGRect) -> Path {
        let cx = Double(rect.midX)
        let cy = Double(rect.midY)
        let radius = Double(min(rect.width, rect.height)) / 2.0 * 0.85
        let n = 8

        var path = Path()

        let p0 = pointAt(angle: 0, cx: cx, cy: cy, radius: radius)
        path.move(to: p0)

        for i in 1...n {
            let angle = (Double(i % n) / Double(n)) * .pi * 2
            let prevAngle = (Double(i - 1) / Double(n)) * .pi * 2

            let cp1Angle = prevAngle + (angle - prevAngle + (i == n ? .pi * 2 : 0)) * 0.33
            let cp2Angle = prevAngle + (angle - prevAngle + (i == n ? .pi * 2 : 0)) * 0.66

            let dest = pointAt(angle: i == n ? 0 : angle, cx: cx, cy: cy, radius: radius)
            let cp1 = pointAt(angle: cp1Angle, cx: cx, cy: cy, radius: radius)
            let cp2 = pointAt(angle: cp2Angle, cx: cx, cy: cy, radius: radius)

            path.addCurve(to: dest, control1: cp1, control2: cp2)
        }

        return path
    }
}

// MARK: - Vue de la gouttelette (SwiftUI — utilisée dans DropletPanel longue durée)

struct DropletView: View {
    let item: DropletItem
    @State private var phase: Double = 0
    @State private var appeared = false
    @State private var glowOpacity: Double = 0.6

    var body: some View {
        VStack(spacing: -6) {
            // Tige d'attache — connecte la goutte au bord supérieur de l'écran
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [kAccentCyan.opacity(0.5), kAccentCyan.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 8, height: 14)

            // Blob principal
            ZStack {
                // Halo externe (glow)
                DropletShape(phase: phase)
                    .fill(kAccentCyan.opacity(glowOpacity * 0.3))
                    .blur(radius: 12)

                // Forme principale avec matériau
                DropletShape(phase: phase)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        DropletShape(phase: phase)
                            .fill(
                                LinearGradient(
                                    colors: [kAccentCyan.opacity(0.4), kAccentCyanDark.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        DropletShape(phase: phase)
                            .stroke(kAccentCyanLight.opacity(0.5), lineWidth: 1.5)
                    )

                // Reflet en haut (sensation de tension de surface)
                DropletShape(phase: phase)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )

                // Icône centrale
                contentIcon
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(width: 46, height: 46)
        }
        .frame(width: 60, height: 60)
        .scaleEffect(appeared ? 1.0 : 0.3)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                appeared = true
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowOpacity = 1.0
            }
        }
    }

    @ViewBuilder
    private var contentIcon: some View {
        switch item.contentType {
        case .image:
            if let image = item.imageContent {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
            } else {
                Image(systemName: item.contentType.sfSymbol)
            }
        case .fileURL:
            if let thumb = item.thumbnail {
                Image(nsImage: thumb)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: item.contentType.sfSymbol)
            }
        case .text:
            Text("T")
                .font(.system(size: 22, weight: .bold, design: .rounded))
        case .color:
            if let color = item.colorContent {
                Circle()
                    .fill(Color(nsColor: color))
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 1))
            } else {
                Image(systemName: item.contentType.sfSymbol)
            }
        }
    }
}
