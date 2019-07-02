//
// Automat
//
// Copyright (c) 2019 Automat Berlin GmbH - https://automat.berlin/
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import CocoaLumberjack

class Logging {
    static func configure() {
        guard let ttyLogger = DDTTYLogger.sharedInstance else { return }
        ttyLogger.logFormatter = LogFormatter()
        DDLog.add(ttyLogger)

        guard let logDirectoryPath = logDirectoryPath else { return }

        do {
            try createLogDirectoryIfNeeeded()
        } catch {
            return
        }

        let logFileManager = DDLogFileManagerDefault(logsDirectory: logDirectoryPath)
        let fileLogger = DDFileLogger(logFileManager: logFileManager)
        fileLogger.rollingFrequency = 0
        let maximumFileSize = 1024 * 1024 * 20
        fileLogger.maximumFileSize = UInt64(maximumFileSize)

        // contrary to the documentation, CocoaLumberjack (ATM) keeps only `maximumNumberOfLogFiles` files, not `maximumNumberOfLogFiles + active` files
        fileLogger.logFileManager.maximumNumberOfLogFiles = 3
        fileLogger.logFileManager.logFilesDiskQuota = 0
        DDLog.add(fileLogger)
    }

    private static var logDirectoryPath: String? {
        let logDirectoryPaths: [String] = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        guard let firstPath = logDirectoryPaths.first else { return nil }

        return (firstPath as NSString).appendingPathComponent("Logs")
    }

    private static func createLogDirectoryIfNeeeded() throws {
        guard let logDirectoryPath = logDirectoryPath else { return }

        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: logDirectoryPath) {
            try fileManager.createDirectory(atPath: logDirectoryPath, withIntermediateDirectories: false, attributes: nil)
        }
    }
}

class LogFormatter: NSObject, DDLogFormatter {
    private let dateFormatter: DateFormatter

    override init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSSS"

        super.init()
    }

    private func ddFlagIndicator(_ flag: DDLogFlag) -> String {
        switch flag {
        case .error:
            return "💥"  // collision
        case .warning:
            return "⚠️"  // warning
        case .info:
            return "✏️"  // pencil
        case .debug:
            return "🔧"  // wrench
        case .verbose:
            return "📣 " // cheering megaphone
        default:
            return ""
        }
    }

    static private let loggingOptions: [String: UInt] = [
        "Error": DDLogFlag.error.rawValue,
        "Warning": DDLogFlag.warning.rawValue,
        "Info": DDLogFlag.info.rawValue,
        "Debug": DDLogFlag.debug.rawValue,
        "Verbose": DDLogFlag.verbose.rawValue
    ]

    func format(message logMessage: DDLogMessage) -> String? {
        let dateAndTime = dateFormatter.string(from: logMessage.timestamp)
        let logFormat   = "%6$@%7$@ %1$@ [%5$@]-[%2$@:%3$i]: %4$@"

        let contextName: String = { () -> String in
            switch logMessage.context {
            case 42:
                return "SDK"
            default:
                return "Automat"
            }
        }()
        let indicator: String = "∆"     // ⌥J
        let levelIndicator: String = ddFlagIndicator(logMessage.flag)
        let minimumLogLevelInt: UInt = { () -> UInt in
            switch logMessage.context {
            case 42:
                return LogFormatter.loggingOptions["Verbose"]!
            default:
                return LogFormatter.loggingOptions["Info"]!
            }
        }()

        if logMessage.flag.rawValue > minimumLogLevelInt {
            return nil
        }

        return String(format: logFormat, dateAndTime, logMessage.fileName, logMessage.line, logMessage.message, contextName, indicator, levelIndicator)
    }
}
