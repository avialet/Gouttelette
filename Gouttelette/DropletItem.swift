import Cocoa

// Type de contenu stocké dans une gouttelette
enum DropletContentType: String {
    case text
    case image
    case fileURL
    case color

    var sfSymbol: String {
        switch self {
        case .text: return "doc.text"
        case .image: return "photo"
        case .fileURL: return "doc"
        case .color: return "paintpalette"
        }
    }
}

// Représente une gouttelette individuelle
class DropletItem: Identifiable {
    let id = UUID()
    let contentType: DropletContentType
    let position: NSPoint // Position horizontale où l'utilisateur a lâché
    let createdAt: Date

    // Contenu stocké
    var textContent: String?
    var imageContent: NSImage?
    var fileURLs: [URL]?
    var colorContent: NSColor?

    init(contentType: DropletContentType, position: NSPoint) {
        self.contentType = contentType
        self.position = position
        self.createdAt = Date()
    }

    // Miniature pour l'affichage dans la gouttelette
    var thumbnail: NSImage? {
        switch contentType {
        case .image:
            return imageContent
        case .fileURL:
            if let url = fileURLs?.first {
                return NSWorkspace.shared.icon(forFile: url.path)
            }
            return nil
        default:
            return nil
        }
    }
}
