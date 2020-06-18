//
//  MergeL10n.swift
//  MergeL10n
//
//  Created by Luiz Barbosa on 17.06.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import ArgumentParser

struct MergeL10n: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Localizable utils",
        subcommands: [PseudoToLanguages.self]
    )
}
