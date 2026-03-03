//
//  RepositoryCache.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import Foundation

public protocol RepositoryCacheProtocol: Sendable {
    func store(_ repos: [Repository], page: Int)
    func retrieve(page: Int) -> [Repository]?
    func invalidate()
}

// In-memory LRU-style cache with TTL.
public final class RepositoryCache: RepositoryCacheProtocol, @unchecked Sendable {
    private struct Entry {
        let repos: [Repository]
        let date: Date
    }

    private let lock = NSLock()
    private var cache: [Int: Entry] = [:]
    private let ttl: TimeInterval

    public init(ttl: TimeInterval = 300) {
        self.ttl = ttl
    }

    public func store(_ repos: [Repository], page: Int) {
        lock.withLock { cache[page] = Entry(repos: repos, date: Date()) }
    }

    public func retrieve(page: Int) -> [Repository]? {
        lock.withLock {
            guard let entry = cache[page], Date().timeIntervalSince(entry.date) < ttl else {
                cache[page] = nil
                return nil
            }
            return entry.repos
        }
    }

    public func invalidate() {
        lock.withLock { cache.removeAll() }
    }
}
