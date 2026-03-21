# Contexte de développement — Gouttelette

Tu vas développer **Gouttelette**, une nouvelle application macOS menu bar + son site vitrine. Ce document te donne tout le contexte nécessaire : conventions techniques, patterns de code, direction artistique, et architecture issus de mes précédentes apps (Chuchotte et Pastille).

---

## 1. QUI JE SUIS

Je développe des petites apps macOS utilitaires distribuées en DMG via GitHub + site vitrine. Mes apps existantes :

- **Chuchotte** — Dictée vocale locale (Whisper.cpp), couleur violette (#7B2FBE), blob morphing
- **Papartager** (Écran Total) — Mode présentation macOS (cache les apps, change le wallpaper), couleur rose→teal (#E84393→#00B894), animation rideau
- **Pastille** — Picture-in-Picture système, couleur vermillon (#E74C3C), bordure morphing
- **Gouttelette** — [À définir], couleur [À définir]

Toutes suivent la même direction artistique et les mêmes conventions techniques.

> Note : Papartager utilise un projet Xcode, mais Chuchotte et Pastille utilisent swiftc + build.sh. La convention préférée est **swiftc + build.sh** (pas de Xcode).

---

## 2. CONVENTIONS TECHNIQUES — APPLICATION macOS

### Architecture

- **Langage** : Swift pur (AppKit + SwiftUI), compilé avec `swiftc` en ligne de commande
- **Pas de Xcode project** : pas de .xcodeproj, pas de SPM, pas de CocoaPods
- **Build** : script `build.sh` qui fait `find . -name "*.swift" | swiftc`
- **Distribution** : DMG créé via `make-dmg.sh` avec `hdiutil`
- **Menu bar app** : `LSUIElement: true` dans Info.plist (pas d'icône dans le Dock)
- **Target** : `arm64-apple-macosx13.0` (Apple Silicon, macOS 13+)
- **Sandbox** : désactivé (`com.apple.security.app-sandbox: false`)
- **Signature** : ad-hoc (`codesign --force --sign -`)

### Structure de fichiers type

```
MonApp/
├── build.sh              # Compilation swiftc
├── make-dmg.sh           # Création DMG
├── MonApp/               # Sources Swift
│   ├── main.swift        # Point d'entrée
│   ├── AppDelegate.swift # NSApplicationDelegate, NSStatusItem
│   ├── ...Manager.swift  # Logique métier
│   └── ...View.swift     # Vues SwiftUI
├── Resources/
│   ├── Info.plist
│   └── MonApp.entitlements
└── site/                 # Site vitrine
    ├── server.js
    └── public/
        ├── index.html
        ├── style.css
        └── script.js
```

### build.sh — Pattern type

```bash
#!/bin/bash
set -e

APP_NAME="MonApp"
VERSION="${1:-1.0.0}"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "🔨 Building $APP_NAME v$VERSION..."

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RESOURCES"

SOURCES=$(find MonApp -name "*.swift" | tr '\n' ' ')

swiftc \
    $SOURCES \
    -o "$MACOS/$APP_NAME" \
    -target arm64-apple-macosx13.0 \
    -framework AppKit \
    -framework SwiftUI \
    -framework CoreGraphics \
    -framework Carbon \
    -Osize \
    -whole-module-optimization

cp Resources/Info.plist "$CONTENTS/"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS/Info.plist"

# IMPORTANT : nettoyer les attributs étendus avant signature
xattr -cr "$APP_BUNDLE"

if [ -f Resources/MonApp.entitlements ]; then
    codesign --force --sign - --entitlements Resources/MonApp.entitlements "$APP_BUNDLE"
else
    codesign --force --sign - "$APP_BUNDLE"
fi

echo "✅ $APP_NAME.app prêt dans $BUILD_DIR/"
```

### make-dmg.sh — Pattern type

```bash
#!/bin/bash
set -e

APP_NAME="MonApp"
VERSION="${1:-1.0.0}"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ $APP_BUNDLE introuvable. Lance d'abord ./build.sh"
    exit 1
fi

DMG_TEMP="$BUILD_DIR/dmg-temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

cp -R "$APP_BUNDLE" "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"

rm -f "$BUILD_DIR/$DMG_NAME"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov \
    -format UDBZ \
    "$BUILD_DIR/$DMG_NAME"

rm -rf "$DMG_TEMP"
echo "✅ DMG créé : $BUILD_DIR/$DMG_NAME"
```

### main.swift — Pattern type

```swift
import Cocoa

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
```

### AppDelegate.swift — Pattern type

```swift
import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "MON_SF_SYMBOL", accessibilityDescription: "MonApp")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Action principale", action: #selector(mainAction), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quitter MonApp", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc func mainAction() {
        // Logique principale
    }
}
```

### GlobalShortcut.swift — Carbon Hotkey Pattern

```swift
import Carbon

class GlobalShortcut {
    private var hotKeyRef: EventHotKeyRef?
    private static var callback: (() -> Void)?

    func register(callback: @escaping () -> Void) {
        GlobalShortcut.callback = callback

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            GlobalShortcut.callback?()
            return noErr
        }, 1, &eventType, nil, nil)

        let hotKeyID = EventHotKeyID(signature: OSType(0x4D4F4E41), id: 1) // "MONA"
        // Exemple : Cmd+Option+L
        RegisterEventHotKey(
            UInt32(kVK_ANSI_L),
            UInt32(cmdKey | optionKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
}
```

### Floating Panel — Pattern type (NSPanel)

```swift
import Cocoa

class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = true // Click-through par défaut
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
}
```

### MorphingBorder — Pattern SwiftUI (bordure animée signature)

```swift
import SwiftUI

struct MorphingBorder: View {
    var isHovered: Bool = false
    var accentColor: Color = .red // Adapter à la couleur de l'app

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size).insetBy(dx: 8, dy: 8)
                let path = RoundedRectangle(cornerRadius: 12).path(in: rect)

                // Layer 1 : Halo (glow externe)
                // Layer 2 : Bordure principale (gradient angulaire tournant)
                // Layer 3 : Reflet interne (rotation inverse, blend plusLighter)
            }
        }
    }
}
```

### Permissions — Pattern type

```swift
import CoreGraphics

class PermissionManager {
    static func hasScreenCapturePermission() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    static func requestScreenCapturePermission() {
        CGRequestScreenCaptureAccess()
    }

    static func openSystemPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
```

### Info.plist — Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MonApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.monapp.app</string>
    <key>CFBundleName</key>
    <string>MonApp</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
```

### Entitlements — Template

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```

---

## 3. CONVENTIONS TECHNIQUES — SITE VITRINE

### Stack

- **Serveur** : Node.js + Express
- **Frontend** : Vanilla HTML/CSS/JS (pas de framework)
- **Animations** : GSAP 3.12.5 + ScrollTrigger (CDN)
- **Fonts** : Inter (Google Fonts, weights 400-900)
- **Pas de bundler** : pas de Webpack/Vite, fichiers servis directement

### server.js — Pattern type

```javascript
const express = require('express');
const path = require('path');
const compression = require('compression');
const app = express();
const PORT = process.env.PORT || 3000;
const isDev = process.env.NODE_ENV !== 'production';

app.use(compression());

if (isDev) {
    app.use((req, res, next) => {
        res.set('Cache-Control', 'no-cache, no-store, must-revalidate');
        res.set('Pragma', 'no-cache');
        res.set('Expires', '0');
        next();
    });
}

app.use(express.static(path.join(__dirname, 'public'), {
    maxAge: isDev ? 0 : '1y',
    etag: !isDev
}));

app.get('/download', (req, res) => {
    const dmgPath = path.join(__dirname, '..', 'build', 'MonApp-1.0.0.dmg');
    res.download(dmgPath);
});

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
```

### package.json — Pattern type

```json
{
  "name": "monapp-site",
  "version": "1.0.0",
  "scripts": {
    "start": "node site/server.js",
    "dev": "NODE_ENV=development node site/server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "compression": "^1.7.4"
  }
}
```

---

## 4. DIRECTION ARTISTIQUE COMMUNE

### Thème sombre

| Token | Valeur | Usage |
|-------|--------|-------|
| `--bg` / `--bg-deep` | `#0d0d1a` | Fond principal (très sombre, bleuté) |
| `--bg-primary` | `#1a1a2e` | Fond de sections |
| `--bg-secondary` | `#16213e` | Fond alternatif |
| `--text` | `#f0f0f5` | Texte principal |
| `--text-secondary` | `#8a8a9a` à `#a0a0b8` | Texte secondaire |
| `--glass-bg` | `rgba(255,255,255,0.04)` | Fond verre |
| `--glass-border` | `rgba(255,255,255,0.08)` | Bordure verre |

### Couleur d'accent par app

Chaque app a sa propre couleur signature, déclinée en 2-3 tons :

- **Chuchotte** : Violet `#7B2FBE` / `#9B59D0` (light) / `#5B3FD9` (dark)
- **Papartager** : Rose→Teal gradient `#E84393` (rose) / `#00B894` (teal) / `#a855f7` (intermédiaire violet)
- **Pastille** : Vermillon `#E74C3C` / `#F06E63` (light) / `#C0392B` (dark)
- **Gouttelette** : [À définir] — choisir une couleur distincte des précédentes

### Glass Morphism

```css
.glass-card {
    background: rgba(255, 255, 255, 0.04);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 20px;
    backdrop-filter: blur(12px);
}
.glass-card:hover {
    background: rgba(255, 255, 255, 0.07);
    border-color: rgba(255, 255, 255, 0.12);
}
```

### Typographie

```css
font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
-webkit-font-smoothing: antialiased;
-moz-osx-font-smoothing: grayscale;

/* Titres */
.hero-title { font-size: clamp(2.5rem, 5vw, 4rem); font-weight: 800; letter-spacing: -0.04em; line-height: 1.1; }
.section-title { font-size: clamp(1.8rem, 3vw, 2.5rem); font-weight: 700; letter-spacing: -0.03em; }

/* Corps */
body { font-size: 16px; font-weight: 400; line-height: 1.6; color: #f0f0f5; }
```

### Bordures arrondies

```css
--radius-sm: 12px;   /* Petits éléments, badges */
--radius-md: 20px;   /* Cards */
--radius-lg: 28px;   /* Sections */
--radius-xl: 36px;   /* Grands conteneurs */
```

### Boutons

```css
.btn-primary {
    background: linear-gradient(135deg, var(--accent), var(--accent-dark));
    color: white;
    padding: 14px 32px;
    border-radius: 12px;
    font-weight: 600;
    border: none;
    box-shadow: 0 4px 24px rgba(accent, 0.4);
    transition: all 0.3s ease;
}
.btn-primary:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 32px rgba(accent, 0.5);
}
```

---

## 5. PATTERNS D'ANIMATION — SITE VITRINE

### Structure GSAP commune

```javascript
// IIFE pour éviter les conflits
(function() {
    gsap.registerPlugin(ScrollTrigger);

    // 1. États initiaux (remplace CSS opacity:0 pour éviter les problèmes de cache)
    gsap.set('.hero-title, .hero-tagline, .hero-cta', { opacity: 0, y: 30 });
    gsap.set('.feature-card', { opacity: 0, y: 60 });

    // 2. Hero entrance timeline
    const heroTl = gsap.timeline({ delay: 0.3 });
    heroTl
        .to('.hero-icon', { scale: 1, opacity: 1, duration: 0.8, ease: 'back.out(1.7)' })
        .to('.hero-title', { opacity: 1, y: 0, duration: 0.7 }, '-=0.3')
        .to('.hero-tagline', { opacity: 1, y: 0, duration: 0.6 }, '-=0.4')
        .to('.hero-cta', { opacity: 1, y: 0, duration: 0.5 }, '-=0.3');

    // 3. Feature cards — stagger depuis le centre
    ScrollTrigger.create({
        trigger: '.features',
        start: 'top 80%',
        onEnter: () => {
            const cards = gsap.utils.toArray('.feature-card');
            gsap.to(cards, {
                opacity: 1, y: 0, scale: 1,
                duration: 0.8,
                ease: 'power4.out',
                stagger: { each: 0.12, from: 'center' }
            });
        },
        once: true
    });

    // 4. Sections — scroll-triggered fade-in
    gsap.utils.toArray('.section-animate').forEach(section => {
        gsap.from(section, {
            scrollTrigger: { trigger: section, start: 'top 85%', once: true },
            opacity: 0, y: 40, duration: 0.8, ease: 'power3.out'
        });
    });

    // 5. Effet magnétique sur boutons
    document.querySelectorAll('.btn-magnetic').forEach(btn => {
        btn.addEventListener('mousemove', e => {
            const rect = btn.getBoundingClientRect();
            const x = e.clientX - rect.left - rect.width / 2;
            const y = e.clientY - rect.top - rect.height / 2;
            gsap.to(btn, { x: x * 0.15, y: y * 0.15, duration: 0.3, ease: 'power2.out' });
        });
        btn.addEventListener('mouseleave', () => {
            gsap.to(btn, { x: 0, y: 0, duration: 0.5, ease: 'elastic.out(1, 0.4)' });
        });
    });

    // 6. Feature cards — glow radial au survol
    document.querySelectorAll('.feature-card').forEach(card => {
        card.addEventListener('mousemove', e => {
            const rect = card.getBoundingClientRect();
            const x = ((e.clientX - rect.left) / rect.width) * 100;
            const y = ((e.clientY - rect.top) / rect.height) * 100;
            card.style.setProperty('--glow-x', x + '%');
            card.style.setProperty('--glow-y', y + '%');
        });
    });
})();
```

### Hero Icon animé — Pattern SVG (logo navbar + hero)

Chaque app a un SVG animé qui représente sa fonctionnalité :

- **Chuchotte** : Blob morphing violet (280×280px) avec pulse rings, gradient violet→bleu
- **Papartager** : 3 couches rideau animées (rose, violet, teal) montant de bas en haut, glow radial pulsant
- **Pastille** : Rectangle arrondi en pointillés vermillon (180px) avec glow tournant conic-gradient

Pattern CSS commun pour le logo animé :

```css
/* Glow pulsant */
@keyframes iconGlow {
    0%, 100% { filter: drop-shadow(0 0 8px rgba(ACCENT, 0.4)); transform: scale(1); }
    50% { filter: drop-shadow(0 0 20px rgba(ACCENT, 0.7)); transform: scale(1.03); }
}

/* Flottement subtil */
@keyframes iconFloat {
    0%, 100% { transform: translateY(0) rotate(0deg); }
    50% { transform: translateY(-6px) rotate(1deg); }
}

/* Stroke animé (si tracé en pointillés) */
@keyframes iconDash {
    to { stroke-dashoffset: -100; }
}
```

### Hero Visual — Simulation d'app

Pattern récurrent : simuler l'interface de l'app dans le hero pour montrer ce qu'elle fait.

- **Chuchotte** : Blob morphing 280×280px + pulse rings + gradient violet→bleu
- **Papartager** : 3 couches rideau animées (300×200px container) montant de bas en haut (rose→violet→teal), glow radial pulsant, comparaison avant/après
- **Pastille** : Fausse fenêtre macOS (440×280px) + pastille flottante 160×100px avec bordure morphing conic-gradient

### Section Support (Amazon Wishlist)

Toutes les apps incluent une section de support avec le même lien Amazon :

```html
<section class="support">
    <h2>Soutenir le projet</h2>
    <p>Si l'app vous plaît, vous pouvez me soutenir via ma liste Amazon</p>
    <a href="https://www.amazon.fr/hz/wishlist/ls/3QFCGBSNKMYHO" target="_blank" class="btn-secondary">
        Ma liste Amazon
    </a>
</section>
```

---

## 6. STRUCTURE HTML — Template de page

```html
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MonApp — Tagline courte</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="/style.css">
</head>
<body>
    <!-- NAV -->
    <nav class="navbar">
        <div class="nav-content">
            <a href="#" class="nav-logo">
                <!-- SVG animé du logo -->
                <span class="nav-logo-text">MonApp</span>
            </a>
            <div class="nav-links">
                <a href="#features">Fonctionnalités</a>
                <a href="#how-it-works">Comment ça marche</a>
                <a href="#download" class="btn-nav">Télécharger</a>
            </div>
        </div>
    </nav>

    <!-- HERO -->
    <section class="hero">
        <div class="hero-content">
            <!-- Icône animée grande (250-280px) -->
            <div class="hero-icon">...</div>
            <h1 class="hero-title">Titre accrocheur en français.</h1>
            <p class="hero-tagline">Description en 1-2 phrases.</p>
            <div class="hero-cta">
                <a href="#download" class="btn-primary btn-magnetic">Télécharger gratuitement</a>
                <span class="hero-hint">macOS 13+ · Apple Silicon</span>
            </div>
        </div>
        <!-- Visual simulant l'app -->
        <div class="hero-visual">...</div>
    </section>

    <!-- FEATURES (6 cards en grille 3×2) -->
    <section id="features" class="features">
        <h2 class="section-title">Fonctionnalités</h2>
        <div class="features-grid">
            <div class="feature-card">
                <div class="feature-icon">🎯</div>
                <h3>Titre feature</h3>
                <p>Description courte.</p>
            </div>
            <!-- ... 5 autres cards -->
        </div>
    </section>

    <!-- HOW IT WORKS (3 étapes) -->
    <section id="how-it-works" class="steps-section">
        <h2 class="section-title">Comment ça marche</h2>
        <div class="steps">
            <div class="step">
                <div class="step-number">1</div>
                <h3>Étape 1</h3>
                <p>Description.</p>
            </div>
            <!-- étapes 2 et 3 -->
        </div>
    </section>

    <!-- DOWNLOAD -->
    <section id="download" class="download-section">
        <h2 class="section-title">Télécharger MonApp</h2>
        <a href="/download" class="btn-primary btn-magnetic btn-download">
            Télécharger le .dmg
        </a>
        <p class="download-info">Gratuit · macOS 13+ · Apple Silicon</p>
    </section>

    <!-- SUPPORT -->
    <section class="support-section">
        <h2>Soutenir le projet</h2>
        <p>Si MonApp vous est utile, vous pouvez me soutenir via ma liste Amazon.</p>
        <a href="https://www.amazon.fr/hz/wishlist/ls/3QFCGBSNKMYHO" target="_blank" class="btn-secondary btn-magnetic">
            Ma liste Amazon ☕
        </a>
    </section>

    <!-- FOOTER -->
    <footer>
        <p>MonApp — Fait avec ❤️</p>
    </footer>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/ScrollTrigger.min.js"></script>
    <script src="/script.js"></script>
</body>
</html>
```

---

## 7. DÉPLOIEMENT

### GitHub

- Repo public sur mon compte GitHub perso
- Le site ET l'app sont dans le même repo
- Le code source de l'app Swift est dans le repo
- Le DMG est buildé localement et distribué via le site

### Site sur Hostinger

- Le site est hébergé sur Hostinger (hosting web)
- Après un push sur GitHub, il faut que les changements soient déployés sur Hostinger
- Le serveur Express tourne sur Hostinger

### .claude/launch.json — Preview serveur

```json
{
    "servers": {
        "monapp-site": {
            "command": "node",
            "args": ["site/server.js"],
            "cwd": ".",
            "env": {
                "PORT": "3000",
                "NODE_ENV": "development"
            },
            "url": "http://localhost:3000"
        }
    }
}
```

---

## 8. PIÈGES CONNUS & SOLUTIONS

| Problème | Solution |
|----------|----------|
| `codesign` échoue avec "resource fork, detritus" | Ajouter `xattr -cr "$APP_BUNDLE"` avant `codesign` |
| GSAP animations ne se lancent pas (opacity:0 reste) | Utiliser `gsap.set()` au lieu de CSS `opacity:0`, et mettre le serveur en mode dev (no-cache) |
| `var` warning dans Carbon callback | Utiliser `let` pour `hotKeyID` |
| Capture suit l'écran au lieu de la fenêtre | Utiliser `CGWindowListCreateImage(.null, .optionIncludingWindow, windowID)` avec crop relatif |
| Performance capture trop gourmande | Limiter à 10 FPS, cache les bounds de fenêtre (refresh toutes les 10 frames) |
| NSPanel reçoit pas les clicks | Dual mouse monitors (global + local) + toggle `ignoresMouseEvents` au hover |

---

## 9. RÉCAPITULATIF DES APPS EXISTANTES

### Chuchotte — Dictée vocale locale
- **Couleur** : Violet #7B2FBE
- **Fonction** : Transcription voix→texte avec Whisper.cpp embarqué, insertion dans l'app active
- **Raccourci** : ⌥ Option + Fn (push-to-talk ou toggle)
- **Permissions** : Micro, Accessibilité
- **Overlay** : Blob morphing 10 points (BlobShape + Catmull-Rom), 60 FPS, réactif à l'amplitude audio
- **4 styles blob** : Organic, WaveBar, Ring, Minimal
- **Build** : swiftc + build.sh (link statique whisper.cpp + ggml + Metal + Accelerate)
- **Spécificité** : Modèle Whisper embarqué (488MB-3.1GB), anti-hallucination, beam search 5
- **SF Symbol menu bar** : waveform.circle
- **Site hero** : Blob morphing 280px avec pulse rings

### Papartager (Écran Total) — Mode présentation
- **Couleur** : Rose #E84393 → Teal #00B894 (gradient)
- **Fonction** : Cache les apps distractantes, change le wallpaper, nettoie le bureau pour les présentations
- **Raccourci** : Cmd+Shift+P
- **Permissions** : AppleEvents (Finder, System Events)
- **Transition** : 5 couches rideau animées (rose→violet→teal), wave sinusoïdale, 1.9s
- **Modes** : Whitelist (montrer seulement) / Blacklist (cacher seulement)
- **Technique unique** : SIGSTOP pour suspendre les apps (retire du Cmd+Tab), guard d'activation qui re-cache
- **Build** : Xcode project (exception — les autres apps utilisent swiftc)
- **SF Symbol menu bar** : eye / eye.slash
- **Site hero** : 3 couches rideau animées + comparaison avant/après
- **Entitlements spéciaux** : automation.apple-events, exceptions Finder/System Events

### Pastille — Picture-in-Picture système
- **Couleur** : Vermillon #E74C3C
- **Fonction** : Capturer n'importe quelle zone d'écran en miniature flottante, suit la fenêtre source
- **Raccourci** : Cmd+Option+L (Carbon hotkey)
- **Permissions** : Screen Recording
- **Panel** : NSPanel floating, click-through, hover pour interagir, resize homothétique
- **Capture** : CGWindowListCreateImage avec .optionIncludingWindow, crop relatif, 10 FPS
- **Bordure** : MorphingBorder SwiftUI 3 couches (halo, gradient angulaire tournant, reflet interne)
- **Build** : swiftc + build.sh
- **SF Symbol menu bar** : rectangle.dashed
- **Site hero** : Fausse fenêtre macOS + pastille flottante avec bordure morphing

---

## 10. CE QUE TU DOIS FAIRE

Quand je te donnerai le brief de Gouttelette, tu devras :

1. **Me poser des questions** si le brief est ambigu (raccourci clavier, permissions nécessaires, etc.)
2. **Proposer un plan** avant de coder
3. **Développer l'app** en suivant exactement les patterns ci-dessus (swiftc, build.sh, même architecture)
4. **Développer le site** en suivant la même DA (thème sombre, glass morphism, GSAP, même structure HTML)
5. **Choisir une couleur signature** pour Gouttelette (différente de violet, rose/teal, et vermillon)
6. **Créer le hero visual** avec une animation qui représente ce que fait l'app
7. **Inclure la section support** avec le lien Amazon : `https://www.amazon.fr/hz/wishlist/ls/3QFCGBSNKMYHO`
8. **Déployer sur GitHub** (repo public, compte perso) + préparer le déploiement Hostinger
9. **Tout en français** (interface app, site, commentaires code)
10. **Ne pas utiliser Xcode** — compilation via swiftc + build.sh uniquement

---

*Ce document capture l'ensemble des conventions de mes apps macOS. Utilise-le comme référence absolue pour développer Gouttelette.*
