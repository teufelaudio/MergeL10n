//
//  LocalizedStringEntry.swift
//  MergeL10n
//
//  Created by Luiz Barbosa on 17.06.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation

public struct LocalizedStringEntry: Equatable, Hashable, CustomStringConvertible {
    public let key: String
    public let value: String
    public var comment: String

    public init(key: String, value: String, comment: String) {
        self.key = key
        self.value = value
        self.comment = comment
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }

    public var description: String {
        """
        /* \(comment) */
        "\(key)" = "\(value)";
        """
    }
}

extension LocalizedStringEntry {
    public static func merge(keysSource: [LocalizedStringEntry], valuesSource: [LocalizedStringEntry], fillWithEmpty: Bool) -> [LocalizedStringEntry] {
        keysSource.compactMap { keysSourceEntry in
            guard var valuesSourceEntry = valuesSource.first(where: { $0.key == keysSourceEntry.key }) else {
                return fillWithEmpty
                    ? LocalizedStringEntry(key: keysSourceEntry.key, value: "", comment: keysSourceEntry.comment)
                    : nil
            }

            valuesSourceEntry.comment = keysSourceEntry.comment
            return valuesSourceEntry
        }
    }
}
