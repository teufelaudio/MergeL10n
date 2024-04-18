//
//  LocalizedStringFile.swift
//  MergeL10n
//
//  Created by Luiz Barbosa on 17.06.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import Foundation
import FoundationExtensions
import FunctionalParser

public struct LocalizedStringFile {
    public let basePath: String
    public let language: String
    public var fullPath: String {
        "\(basePath)/\(language).lproj/Localizable.strings"
    }

    public init(basePath: String, language: String) {
        self.basePath = basePath
        self.language = language
    }

    public func read(encoding: String.Encoding, requiresComments: Bool) -> Reader<SimpleFileManager, Result<[LocalizedStringEntry], LocalizedStringFileError>> {
        Reader { fileManager in
            Result.pure(fileManager.fileExists(self.fullPath))
                .flatMap { exists in
                    exists ? .success(()) : .failure(LocalizedStringFileError.folderNotFound(self))
                }
                .flatMap { _ in
                    fileManager
                        .readTextFile(self.fullPath, encoding)
                        .mapError { _ in LocalizedStringFileError.fileCannotBeRead(self) }
                }
                .flatMap { contents in
                    let (match, rest) = LocalizedStringFile.parser(requiresComments: requiresComments).run(contents)
                    guard rest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        return .failure(.fileParserHasUnmatchedString(self, rest: String(rest)))
                    }
                    guard let match else {
                        return .failure(.fileCannotBeParsed(self))
                    }
                    
                    return .success((match, contents))
                }
                .flatMap { (entries: [LocalizedStringEntry], contents: String) in
                    guard !contents.isEmpty else {
                        return .success([])
                    }
                    
                    return .success(entries)
                }
        }
    }

    public func save(entries: [LocalizedStringEntry], encoding: String.Encoding) -> Reader<SimpleFileManager, Result<Void, LocalizedStringFileError>> {
        Reader { fileManager in
            Result.pure(
                entries
                    .map({ $0.description })
                    .joined(separator: "\n\n")
            )
            .flatMap { contents in
                fileManager
                    .createTextFile(self.fullPath, contents.appending("\n\n"), encoding)
                    ? .success(()) : .failure(LocalizedStringFileError.fileCannotBeSaved(self))
            }
        }
    }
}

extension LocalizedStringFile {
    public static func parser(requiresComments: Bool = true) -> Parser<[LocalizedStringEntry]> {
        let comment = Parser.zip(
            .literal("/* "),
            .string(until: .literal(" */")),
            .literal(" */")
        )
        .map { _, comments, _ in comments }

        let localizedStringEntry: Parser<LocalizedStringEntry> = Parser.zip(
            requiresComments ? comment : comment.replaceMismatch(with: ""),
            Parser.zip(.zeroOrMoreSpacesOrLines, .literal("\"")),
            .string(until: .literal("\" = \"")),
            .literal("\" = \""),
            Parser.string(until: .literal("\";")).replaceMismatch(with: ""),
            .literal("\";"),
            .zeroOrMoreSpacesOrLines
        ).map { comment, _, key, _, value, _, _ in
            LocalizedStringEntry(key: key, value: value, comment: comment)
        }

        let entries = Parser.zeroOrMore(localizedStringEntry)

        return Parser.zip(.zeroOrMoreSpacesOrLines, entries).map { _, entries in entries }
    }
}

public enum LocalizedStringFileError: Error {
    case folderNotFound(LocalizedStringFile)
    case fileCannotBeRead(LocalizedStringFile)
    case fileCannotBeParsed(LocalizedStringFile)
    case fileParserHasUnmatchedString(LocalizedStringFile, rest: String)
    case fileCannotBeSaved(LocalizedStringFile)
}

extension LocalizedStringFile {
    public static func replace(language: LocalizedStringFile, withKeysFrom pseudoLanguage: [LocalizedStringEntry], fillWithEmpty: Bool, encoding: String.Encoding)
    -> Reader<SimpleFileManager, Result<Void, LocalizedStringFileError>> {
        language
            .read(encoding: encoding, requiresComments: false)
            .mapValue {
                $0.map { languageEntries -> [LocalizedStringEntry] in
                    LocalizedStringEntry.merge(keysSource: pseudoLanguage, valuesSource: languageEntries, fillWithEmpty: fillWithEmpty)
                }
            }
            .flatMapResult { entries in
                language.save(entries: entries, encoding: encoding)
            }
    }
}
