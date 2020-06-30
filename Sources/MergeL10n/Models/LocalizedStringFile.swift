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

struct LocalizedStringFile {
    let basePath: String
    let language: String
    var fullPath: String {
        "\(basePath)/\(language).lproj/Localizable.strings"
    }

    func read(encoding: String.Encoding) -> Reader<SimpleFileManager, Result<[LocalizedStringEntry], LocalizedStringFileError>> {
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
                    let (match, rest) = self.parser().run(contents)
                    guard rest.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        return .failure(.fileParserHasUnmatchedString(self, rest: String(rest)))
                    }
                    return match.toResult(orError: .fileCannotBeParsed(self))
                }
                .flatMap { entries in
                    entries.isEmpty
                        ? .failure(.filePossibleEncodingProblemWhileParsing(self))
                        : .success(entries)
                }
        }
    }

    func save(entries: [LocalizedStringEntry], encoding: String.Encoding) -> Reader<SimpleFileManager, Result<Void, LocalizedStringFileError>> {
        Reader { fileManager in
            Result.pure(
                entries
                    .map({ $0.description })
                    .joined(separator: "\n\n")
            )
            .flatMap { contents in
                fileManager
                    .createTextFile(self.fullPath, contents, encoding)
                    ? .success(()) : .failure(LocalizedStringFileError.fileCannotBeSaved(self))
            }
        }
    }
}

extension LocalizedStringFile {
    func parser() -> Parser<[LocalizedStringEntry]> {
        let comment = Parser.zip(
            .literal("/* "),
            .string(until: .literal(" */")),
            .literal(" */"),
            .zeroOrMoreSpacesOrLines
        ).map { _, comments, _, _ in comments }

        let localizedStringEntry: Parser<LocalizedStringEntry> = Parser.zip(
            comment,
            .literal("\""),
            .string(until: .literal("\" = \"")),
            .literal("\" = \""),
            .string(until: .literal("\";")),
            .literal("\";"),
            .zeroOrMoreSpacesOrLines
        ).map { comment, _, key, _, value, _, _ in
            LocalizedStringEntry(key: key, value: value, comment: comment)
        }

        return Parser.zeroOrMore(localizedStringEntry)
    }
}

enum LocalizedStringFileError: Error {
    case folderNotFound(LocalizedStringFile)
    case fileCannotBeRead(LocalizedStringFile)
    case fileCannotBeParsed(LocalizedStringFile)
    case filePossibleEncodingProblemWhileParsing(LocalizedStringFile)
    case fileParserHasUnmatchedString(LocalizedStringFile, rest: String)
    case fileCannotBeSaved(LocalizedStringFile)
}

extension LocalizedStringFile {
    static func replace(language: LocalizedStringFile, withKeysFrom pseudoLanguage: [LocalizedStringEntry], fillWithEmpty: Bool, encoding: String.Encoding)
    -> Reader<SimpleFileManager, Result<Void, LocalizedStringFileError>> {
        language
            .read(encoding: encoding)
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
