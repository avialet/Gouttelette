import Foundation
import AppKit

struct VKVersionEntry: Codable {
    let version: String
    let url: String
}

struct VKVersionsManifest: Codable {
    let apps: [String: VKVersionEntry]
}

class VKUpdateChecker: ObservableObject {
    @Published var updateAvailable: Bool = false
    @Published var latestVersion: String?
    @Published var downloadURL: String?

    private let appKey: String
    private var timer: Timer?
    private let lastCheckKey = "VKLastUpdateCheck"

    init(appKey: String) {
        self.appKey = appKey
    }

    // MARK: - Public

    func startPeriodicCheck() {
        checkNow()
        timer = Timer.scheduledTimer(withTimeInterval: VK.updateCheckInterval, repeats: true) { [weak self] _ in
            self?.checkNow()
        }
    }

    func stopPeriodicCheck() {
        timer?.invalidate()
        timer = nil
    }

    func checkNow(force: Bool = false) {
        if !force {
            let lastCheck = UserDefaults.standard.double(forKey: lastCheckKey)
            if lastCheck > 0 && Date().timeIntervalSince1970 - lastCheck < VK.updateCheckInterval {
                return
            }
        }

        guard let url = URL(string: VK.versionsURL) else { return }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.handleResponse(data: data, error: error)
            }
        }.resume()
    }

    func openDownloadPage() {
        guard let urlString = downloadURL, let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: - Private

    private func handleResponse(data: Data?, error: Error?) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastCheckKey)

        guard let data = data, error == nil else { return }

        guard let manifest = try? JSONDecoder().decode(VKVersionsManifest.self, from: data),
              let entry = manifest.apps[appKey] else { return }

        let current = currentVersion()

        if compareVersions(entry.version, current) == .orderedDescending {
            latestVersion = entry.version
            downloadURL = entry.url
            updateAvailable = true
        } else {
            updateAvailable = false
        }
    }

    private func currentVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    private func compareVersions(_ a: String, _ b: String) -> ComparisonResult {
        let partsA = a.split(separator: ".").compactMap { Int($0) }
        let partsB = b.split(separator: ".").compactMap { Int($0) }
        let count = max(partsA.count, partsB.count)

        for i in 0..<count {
            let va = i < partsA.count ? partsA[i] : 0
            let vb = i < partsB.count ? partsB[i] : 0
            if va > vb { return .orderedDescending }
            if va < vb { return .orderedAscending }
        }
        return .orderedSame
    }
}
