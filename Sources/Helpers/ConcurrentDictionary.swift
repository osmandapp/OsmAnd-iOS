//
//  ConcurrentDictionary.swift
//  OsmAnd Maps
//
//  Created by Alexey K on 18.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

class ConcurrentDictionary<Key: Hashable, Value> {
    private var dictionary: [Key: Value] = [:]
    private var rwlock = pthread_rwlock_t()

    init() {
        pthread_rwlock_init(&rwlock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&rwlock)
    }

    func getValue(forKey key: Key) -> Value? {
        pthread_rwlock_rdlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        return dictionary[key]
    }

    func setValue(_ value: Value, forKey key: Key) {
        pthread_rwlock_wrlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        dictionary[key] = value
    }

    func removeValue(forKey key: Key) {
        pthread_rwlock_wrlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        dictionary.removeValue(forKey: key)
    }

    func getAllValues() -> [Value] {
        pthread_rwlock_rdlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        return Array(dictionary.values)
    }
}

