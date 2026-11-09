import Foundation

/// The bill in progress. Persisted so a quick app switch (checking Venmo, say)
/// doesn't lose it, but forgotten after 10 minutes, like the 2017 original.
struct BillSession: Codable, Equatable, Sendable {
    /// Editing text in POSIX form ("129.50").
    var billText: String
    var tipPercent: Int
    var people: Int
}

struct SessionStore: Sendable {
    static let lifetime: TimeInterval = 10 * 60

    private static let sessionKey = "billSession"
    private static let savedAtKey = "billSessionSavedAt"

    // UserDefaults is thread-safe; the suite name lets tests use their own domain.
    nonisolated(unsafe) let defaults: UserDefaults
    let now: @Sendable () -> Date

    init(defaults: UserDefaults = .standard, now: @escaping @Sendable () -> Date = { Date() }) {
        self.defaults = defaults
        self.now = now
    }

    func save(_ session: BillSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        defaults.set(data, forKey: Self.sessionKey)
        touch()
    }

    /// Marks the session as still in use (called when the app goes to the background).
    func touch() {
        defaults.set(now().timeIntervalSince1970, forKey: Self.savedAtKey)
    }

    /// The saved session, if it was last used less than 10 minutes ago.
    func restore() -> BillSession? {
        guard isFresh,
              let data = defaults.data(forKey: Self.sessionKey),
              let session = try? JSONDecoder().decode(BillSession.self, from: data)
        else { return nil }
        return session
    }

    var isFresh: Bool {
        guard defaults.object(forKey: Self.savedAtKey) != nil else { return false }
        let savedAt = Date(timeIntervalSince1970: defaults.double(forKey: Self.savedAtKey))
        let age = now().timeIntervalSince(savedAt)
        // A negative age means the clock moved backwards; don't trust it.
        return age >= 0 && age < Self.lifetime
    }

    func clear() {
        defaults.removeObject(forKey: Self.sessionKey)
        defaults.removeObject(forKey: Self.savedAtKey)
    }
}
