//
//  MergeL10n.swift
//  MergeL10n
//
//  Created by Luiz Barbosa on 17.06.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import ArgumentParser
import Foundation

struct MergeL10n: ParsableCommand {
    // Swift 6 requires statics to be thread safe!
    nonisolated(unsafe) private static var _configuration = CommandConfiguration(
        abstract: "Localizable utils",
        subcommands: [PseudoToLanguages.self]
    )
    private static let lock = NSLock()

    public static var configuration: CommandConfiguration {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _configuration
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _configuration = newValue
        }
    }
}
