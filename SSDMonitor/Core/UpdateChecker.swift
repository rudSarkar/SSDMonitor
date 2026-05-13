import Foundation

@MainActor
final class UpdateChecker: ObservableObject {
    // ← After pushing to GitHub, replace with your "owner/repo"
    static let repo = "rudSarkar/SSDMonitor"

    @Published var availableVersion: String? = nil
    @Published var releasePageURL:   URL?    = nil
    @Published var isChecking               = false
    @Published var isUpToDate               = false

    func checkForUpdates() {
        guard !isChecking,
              let url = URL(string: "https://api.github.com/repos/\(Self.repo)/releases/latest")
        else { return }

        isChecking = true
        var req = URLRequest(url: url)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 10

        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            Task { @MainActor [weak self] in
                defer { self?.isChecking = false }
                guard let data,
                      let release = try? JSONDecoder().decode(GHRelease.self, from: data) else { return }

                let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
                let tag = release.tagName.hasPrefix("v") ? String(release.tagName.dropFirst()) : release.tagName

                if tag.compare(current, options: .numeric) == .orderedDescending {
                    self?.availableVersion = release.tagName
                    self?.releasePageURL   = URL(string: release.htmlUrl)
                } else {
                    self?.isUpToDate = true
                    // Clear the "up to date" badge after 3 seconds
                    try? await Task.sleep(for: .seconds(3))
                    self?.isUpToDate = false
                }
            }
        }.resume()
    }
}

private struct GHRelease: Decodable {
    let tagName: String
    let htmlUrl: String
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlUrl = "html_url"
    }
}
