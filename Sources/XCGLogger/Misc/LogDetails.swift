//
//  LogDetails.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

// MARK: - LogDetails
/// Data structure to hold all info about a log message, passed to destination classes
public struct LogDetails {

    /// Log level required to display this log
    public var level: XCGLogger.Level

    /// Date this log was sent
    public var date: Date

    /// The log message to display
    public var message: String

    /// Name of the function that generated this log
    public var functionName: String

    /// Name of the file the function exists in
    public var fileName: String

    /// The line number that generated this log
    public var lineNumber: Int

    public init(level: XCGLogger.Level, date: Date, message: String, functionName: StaticString, fileName: StaticString, lineNumber: Int) {
        self.level = level
        self.date = date
        self.message = message
        self.functionName = functionName.description
        self.fileName = fileName.description
        self.lineNumber = lineNumber
    }
}
