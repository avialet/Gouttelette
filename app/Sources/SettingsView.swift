import SwiftUI

struct SettingsView: View {
    @ObservedObject var manager: DropletManager

    @State private var hasAccessibility = PermissionManager.hasAccessibilityPermission()

    private let evaporationOptions = [
        (5, "5 minutes"),
        (15, "15 minutes"),
        (60, "1 heure")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // En-tête
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 20))
                    .foregroundColor(kAccentCyan)
                Text("Gouttelette")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Section Zone de dépôt
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Zone de dépôt", systemImage: "arrow.up.to.line")
                                .font(.headline)

                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(kAccentCyan)
                                Text("Glissez vos fichiers vers le haut de l'écran pour créer une gouttelette.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(4)
                    }

                    // Section Évaporation
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Évaporation automatique", systemImage: "timer")
                                .font(.headline)

                            Picker("Délai :", selection: $manager.evaporationMinutes) {
                                ForEach(evaporationOptions, id: \.0) { option in
                                    Text(option.1).tag(option.0)
                                }
                            }
                            .pickerStyle(.segmented)

                            Text("Les gouttelettes disparaissent après \(evaporationText)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(4)
                    }

                    // Section Accessibilité
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Permissions", systemImage: "lock.shield")
                                .font(.headline)

                            HStack {
                                Image(systemName: hasAccessibility ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(hasAccessibility ? .green : .orange)
                                Text(hasAccessibility ? "Accessibilité activée" : "Accessibilité requise")
                                Spacer()
                                if !hasAccessibility {
                                    Button("Activer") {
                                        PermissionManager.requestAccessibilityPermission()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            hasAccessibility = PermissionManager.hasAccessibilityPermission()
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(kAccentCyan)
                                }
                            }

                            if !hasAccessibility {
                                Text("Gouttelette fonctionne sans cette permission, mais certaines fonctionnalités de drag & drop pourraient être limitées.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(4)
                    }

                    // Infos
                    HStack {
                        Spacer()
                        Text("Gouttelette v1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 360, height: 400)
        .onAppear {
            hasAccessibility = PermissionManager.hasAccessibilityPermission()
        }
    }

    private var evaporationText: String {
        switch manager.evaporationMinutes {
        case 5: return "5 minutes"
        case 15: return "15 minutes"
        case 60: return "1 heure"
        default: return "\(manager.evaporationMinutes) minutes"
        }
    }
}
