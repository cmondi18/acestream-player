import Foundation

/// Helpers for parsing `acestream://<id>` links (or bare content IDs)
/// and turning them into URLs the local Ace Stream engine can play.
enum AceStreamLink {

    /// Extracts the content ID from an `acestream://<id>` URI or a bare
    /// hex content ID. Returns nil if the input doesn't look valid.
    static func contentID(from raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let candidate: String
        if let url = URL(string: trimmed), url.scheme?.lowercased() == "acestream" {
            candidate = url.host ?? String(trimmed.dropFirst("acestream://".count))
        } else {
            candidate = trimmed
        }

        let hexDigits = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        guard candidate.count >= 8, candidate.unicodeScalars.allSatisfy(hexDigits.contains) else {
            return nil
        }
        return candidate
    }

    /// HLS manifest URL served by the local Ace Stream engine for a content ID.
    static func manifestURL(forContentID id: String, engineBaseURL: URL) -> URL? {
        var components = URLComponents(url: engineBaseURL.appendingPathComponent("ace/manifest.m3u8"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "id", value: id)]
        return components?.url
    }
}
