//
//  LocalizedStringEntry.swift
//  MergeL10n
//
//  Created by Luiz Barbosa on 17.06.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation

struct LocalizedStringEntry: Equatable, Hashable, CustomStringConvertible {
    let key: String
    let value: String
    var comment: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }

    var description: String {
        """
        /* \(comment) */
        "\(key)" = "\(value)";
        """
    }
}

extension LocalizedStringEntry {
    static func merge(keysSource: [LocalizedStringEntry], valuesSource: [LocalizedStringEntry], fillWithEmpty: Bool) -> [LocalizedStringEntry] {
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
