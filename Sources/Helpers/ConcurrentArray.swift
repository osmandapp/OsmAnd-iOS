//
//  ConcurrentArray.swift
//  OsmAnd Maps
//
//  Created by Skalii on 02.08.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

class ConcurrentArray<Value> {
    private var array: [Value] = []
    private var rwlock = pthread_rwlock_t()

    init() {
        pthread_rwlock_init(&rwlock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&rwlock)
    }

    func append(_ value: Value) {
        pthread_rwlock_wrlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        array.append(value)
    }

    func remove(at index: Int) {
        pthread_rwlock_wrlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        array.remove(at: index)
    }

    func removeAll() {
        pthread_rwlock_wrlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        array.removeAll()
    }

    func removeAll(where predicate: (Value) throws -> Bool) rethrows {
        pthread_rwlock_wrlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        try array.removeAll(where: predicate)
    }

    func replaceAll(with newValues: [Value]) {
        pthread_rwlock_wrlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        array.removeAll()
        array.append(contentsOf: newValues)
    }

    func get(at index: Int) -> Value? {
        pthread_rwlock_rdlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        return array[index]
    }

    func first(where predicate: (Value) throws -> Bool) rethrows -> Value? {
        pthread_rwlock_rdlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        return try array.first(where: predicate)
    }

    func contains(where predicate: (Value) throws -> Bool) rethrows -> Bool {
        pthread_rwlock_rdlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        return try array.contains(where: predicate)
    }

    func forEach(_ body: (Value) throws -> Void) rethrows {
        pthread_rwlock_rdlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        return try array.forEach(body)
    }

    func asArray() -> [Value] {
        pthread_rwlock_rdlock(&rwlock)
        defer { pthread_rwlock_unlock(&rwlock) }
        return array
    }
}
