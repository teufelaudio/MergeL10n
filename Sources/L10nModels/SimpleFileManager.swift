import Foundation

public struct SimpleFileManager {
    public let fileExists: (String) -> Bool
    public let readTextFile: (String, String.Encoding) -> Result<String, Error>
    public let createTextFile: (String, String, String.Encoding) -> Bool

    public init(
        fileExists: @escaping (String) -> Bool,
        readTextFile: @escaping (String, String.Encoding) -> Result<String, Error>,
        createTextFile: @escaping (String, String, String.Encoding) -> Bool
    ) {
        self.fileExists = fileExists
        self.readTextFile = readTextFile
        self.createTextFile = createTextFile
    }
}
