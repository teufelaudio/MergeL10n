//
//  PseudoToLanguages.swift
//  MergeL10n
//
//  Created by Luiz Barbosa on 17.06.20.
//  Copyright © 2020 Lautsprecher Teufel GmbH. All rights reserved.
//

import ArgumentParser
import Combine
import Foundation
import FoundationExtensions
import L10nModels

struct World {
    let fileManager: SimpleFileManager
    let environmentVariables: EnvironmentVariables
}

extension World {
    static var `default`: World {
        .init(
            fileManager: .default,
            environmentVariables: .default
        )
    }
}

extension SimpleFileManager {
    static var `default`: SimpleFileManager {
        .init(
            fileExists: FileManager.default.fileExists,
            readTextFile: { path, encoding in
                Result { try String(contentsOfFile: path, encoding: encoding) }
            },
            createTextFile: { path, contents, encoding in
                FileManager.default.createFile(atPath: path, contents: contents.data(using: encoding))
            }
        )
    }
}

struct EnvironmentVariables {
    let get: (String) -> String?
    let set: (String, String) -> Void
    let loadDotEnv: (String) -> Void
}

extension EnvironmentVariables {
    static var `default`: EnvironmentVariables {
        .init(
            get: { name in (getenv(name)).flatMap { String(utf8String: $0) } },
            set: { key, value in setenv(key, value, 1) },
            loadDotEnv: { path in
                guard let file = try? String(contentsOfFile: path, encoding: .utf8) else { return }
                file
                    .split { $0 == "\n" || $0 == "\r\n" }
                    .map(String.init)
                    .forEach { fullLine in
                        let line = fullLine.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        guard line[line.startIndex] != "#" else { return }
                        guard !line.isEmpty else { return }
                        let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
                        let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .init(arrayLiteral: "\""))
                        setenv(key, value, 1)
                    }
            }
        )
    }
}

struct PseudoToLanguages: ParsableCommand {
    @Option(help: "Separated-by-comma list of languages that should be created. Environment Variable SUPPORTED_LANGUAGES is an alternative.")
    var languages: String?

    @Option(help: "Separated-by-comma list of paths to base localizable strings folders. In this folder we expect to find zz.lproj directory and files. Environment Variable L10N_BASE_PATHS is an alternative.")
    var basePaths: String?

    @Option(help: "Which language is used for development. Default: en.")
    var developmentLanguage: String = "en"

    func run() throws {
        let world = World.default
        let paramLanguages = self.languages
        let paramBasePaths = self.basePaths
        let paramDevelopmentLanguage = self.developmentLanguage

        _ = try languagesAndPaths(languages: paramLanguages, paths: paramBasePaths)
            .mapResultError(identity)
            .contramapEnvironment(\World.environmentVariables)
            .flatMapResult { languages, paths -> Reader<World, Result<[Void], Error>> in
                print("Running MergeL10n with languages: \(languages) and development language: \(paramDevelopmentLanguage)")

                return paths
                    .traverse { folder in
                        self.run(folder: folder, languages: languages, developmentLanguage: paramDevelopmentLanguage)
                            .mapResultError(identity)
                            .contramapEnvironment(\.fileManager)
                    }
                    .mapValue { $0.traverse(identity) }
            }
            .inject(world)
            .get()
    }

    private func run(folder: String, languages: [String], developmentLanguage: String) -> Reader<SimpleFileManager, Result<Void, LocalizedStringFileError>>{
        Reader { fileManager in
            LocalizedStringFile(basePath: folder, language: "zz")
                .read(encoding: .utf16, requiresComments: true)
                .inject(fileManager)
                .flatMap { zzEntries in
                    languages.traverse { language in
                        LocalizedStringFile.replace(
                            language: LocalizedStringFile(basePath: folder, language: language),
                            withKeysFrom: zzEntries,
                            fillWithEmpty: language == developmentLanguage,
                            encoding: .utf8
                        ).inject(fileManager)
                    }
            }.map(ignore)
        }
    }

    private func languagesAndPaths(languages: String?, paths: String?) -> Reader<EnvironmentVariables, Result<(languages: [String], paths: [String]), ValidationError>> {

        Reader { environmentVariables in
            if self.languages == nil || self.basePaths == nil {
                // Load the .env file
                environmentVariables.loadDotEnv(".env")
            }

            return zip(
                languages.map(Result<String, ValidationError>.success)
                    ?? self.supportedLanguagesFromEnvironment().inject(environmentVariables),
                paths.map(Result<String, ValidationError>.success)
                    ?? self.basePathsFromEnvironment().inject(environmentVariables)
            ).map { (languages: String, paths: String) -> (languages: [String], paths: [String]) in
                (
                    languages: languages.split(separator: ",").map(String.init),
                    paths: paths.split(separator: ",").map(String.init)
                )
            }
        }
    }

    private func supportedLanguagesFromEnvironment() -> Reader<EnvironmentVariables, Result<String, ValidationError>> {
        Reader { environmentVariables in
            environmentVariables.get("SUPPORTED_LANGUAGES")
                .toResult(orError: ValidationError(
                    "Use --languages:\"en,pt\" option or set `SUPPORTED_LANGUAGES` environment variable before running the script. File .env is also an option."
                ))
        }
    }

    private func basePathsFromEnvironment() -> Reader<EnvironmentVariables, Result<String, ValidationError>> {
        Reader { environmentVariables in
            environmentVariables.get("L10N_BASE_PATHS")
                .toResult(orError: ValidationError(
                    "Use --base-paths:\"SomeFolder/Resources,AnotherFolder/Resources\" option or set `L10N_BASE_PATHS` environment variable before running the script. File .env is also an option."
                ))
        }
    }
}
