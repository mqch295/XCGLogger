//
//  XCGLogger.swift
//  XCGLogger: https://github.com/DaveWoodCom/XCGLogger
//
//  Created by Dave Wood on 2014-06-06.
//  Copyright © 2014 Dave Wood, Cerebral Gardens.
//  Some rights reserved: https://github.com/DaveWoodCom/XCGLogger/blob/master/LICENSE.txt
//

#if os(OSX)
    import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#endif

// MARK: - XCGLogger
/// The main logging class
open class XCGLogger: CustomDebugStringConvertible {
    // MARK: - Constants
    public struct Constants {
        /// Prefix identifier to use for all other identifiers
        public static let baseIdentifier = "com.cerebralgardens.xcglogger"

        /// Identifier for the default instance of XCGLogger
        public static let defaultInstanceIdentifier = "\(baseIdentifier).defaultInstance"

        /// Identifer for the Xcode console destination
        public static let baseConsoleDestinationIdentifier = "\(baseIdentifier).logdestination.console"

        /// Identifier for the Apple System Log destination
        public static let systemLogDestinationIdentifier = "\(baseIdentifier).logdestination.console.nslog"

        /// Identifier for the file logging destination
        public static let fileDestinationIdentifier = "\(baseIdentifier).logdestination.file"

        /// Identifier for the default dispatch queue
        public static let logQueueIdentifier = "\(baseIdentifier).queue"

        /// Library version number
        public static let versionString = "4.0.0-beta.1"
    }

    // MARK: - Enums
    /// Enum defining our log levels
    public enum Level: Int, Comparable, CustomStringConvertible {
        case verbose
        case debug
        case info
        case warning
        case error
        case severe
        case none

        public var description: String {
            switch self {
            case .verbose:
                return "Verbose"
            case .debug:
                return "Debug"
            case .info:
                return "Info"
            case .warning:
                return "Warning"
            case .error:
                return "Error"
            case .severe:
                return "Severe"
            case .none:
                return "None"
            }
        }
    }

    /// Structure to manage log colours
    public struct XcodeColor {

        /// ANSI code Escape sequence
        public static let escape = "\u{001b}["

        /// ANSI code to reset the foreground colour
        public static let resetFg = "\u{001b}[fg;"

        /// ANSI code to reset the background colour
        public static let resetBg = "\u{001b}[bg;"

        /// ANSI code to reset the foreground and background colours
        public static let reset = "\u{001b}[;"

        /// Tuple to store the foreground RGB colour values
        public var fg: (r: Int, g: Int, b: Int)? = nil

        /// Tuple to store the background RGB colour values
        public var bg: (r: Int, g: Int, b: Int)? = nil

        /// Generate the complete ANSI code required to set the colours specified in the object.
        ///
        /// - Parameters:
        ///     - None
        ///
        /// - Returns:  The complete ANSI code needed to set the text colours
        ///
        public func format() -> String {
            guard fg != nil || bg != nil else {
                // neither set, return reset value
                return XcodeColor.reset
            }

            var format: String = ""

            if let fg = fg {
                format += "\(XcodeColor.escape)fg\(fg.r),\(fg.g),\(fg.b);"
            }
            else {
                format += XcodeColor.resetFg
            }

            if let bg = bg {
                format += "\(XcodeColor.escape)bg\(bg.r),\(bg.g),\(bg.b);"
            }
            else {
                format += XcodeColor.resetBg
            }

            return format
        }

        public init(fg: (r: Int, g: Int, b: Int)? = nil, bg: (r: Int, g: Int, b: Int)? = nil) {
            self.fg = fg
            self.bg = bg
        }

#if os(OSX)
        public init(fg: NSColor, bg: NSColor? = nil) {
            if let fgColorSpaceCorrected = fg.usingColorSpaceName(NSCalibratedRGBColorSpace) {
                self.fg = (Int(fgColorSpaceCorrected.redComponent * 255), Int(fgColorSpaceCorrected.greenComponent * 255), Int(fgColorSpaceCorrected.blueComponent * 255))
            }
            else {
                self.fg = nil
            }

            if let bg = bg,
                let bgColorSpaceCorrected = bg.usingColorSpaceName(NSCalibratedRGBColorSpace) {

                    self.bg = (Int(bgColorSpaceCorrected.redComponent * 255), Int(bgColorSpaceCorrected.greenComponent * 255), Int(bgColorSpaceCorrected.blueComponent * 255))
            }
            else {
                self.bg = nil
            }
        }
#elseif os(iOS) || os(tvOS) || os(watchOS)
        public init(fg: UIColor, bg: UIColor? = nil) {
            var redComponent: CGFloat = 0
            var greenComponent: CGFloat = 0
            var blueComponent: CGFloat = 0
            var alphaComponent: CGFloat = 0

            fg.getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha:&alphaComponent)
            self.fg = (Int(redComponent * 255), Int(greenComponent * 255), Int(blueComponent * 255))
            if let bg = bg {
                bg.getRed(&redComponent, green: &greenComponent, blue: &blueComponent, alpha:&alphaComponent)
                self.bg = (Int(redComponent * 255), Int(greenComponent * 255), Int(blueComponent * 255))
            }
            else {
                self.bg = nil
            }
        }
#endif

        /// XcodeColor preset foreground colour: Red
        public static let red: XcodeColor = {
            return XcodeColor(fg: (255, 0, 0))
        }()

        /// XcodeColor preset foreground colour: Green
        public static let green: XcodeColor = {
            return XcodeColor(fg: (0, 255, 0))
        }()

        /// XcodeColor preset foreground colour: Blue
        public static let blue: XcodeColor = {
            return XcodeColor(fg: (0, 0, 255))
        }()

        /// XcodeColor preset foreground colour: Black
        public static let black: XcodeColor = {
            return XcodeColor(fg: (0, 0, 0))
        }()

        /// XcodeColor preset foreground colour: White
        public static let white: XcodeColor = {
            return XcodeColor(fg: (255, 255, 255))
        }()

        /// XcodeColor preset foreground colour: Light Grey
        public static let lightGrey: XcodeColor = {
            return XcodeColor(fg: (211, 211, 211))
        }()

        /// XcodeColor preset foreground colour: Dark Grey
        public static let darkGrey: XcodeColor = {
            return XcodeColor(fg: (169, 169, 169))
        }()

        /// XcodeColor preset foreground colour: Orange
        public static let orange: XcodeColor = {
            return XcodeColor(fg: (255, 165, 0))
        }()

        /// XcodeColor preset colours: White foreground, Red background
        public static let whiteOnRed: XcodeColor = {
            return XcodeColor(fg: (255, 255, 255), bg: (255, 0, 0))
        }()

        /// XcodeColor preset foreground colour: Dark Green
        public static let darkGreen: XcodeColor = {
            return XcodeColor(fg: (0, 128, 0))
        }()
    }

    // MARK: - Default instance
    /// The default XCGLogger object
    open static var `default`: XCGLogger = {
        struct Statics {
            static let instance: XCGLogger = XCGLogger(identifier: XCGLogger.Constants.defaultInstanceIdentifier)
        }

        return Statics.instance
    }()

    // MARK: - Properties (Options)
    /// Identifier for this logger object (should be unique)
    open var identifier: String = ""

    /// The log level of this logger, any logs received at this level or higher will be output to the destinations
    open var outputLevel: Level = .debug {
        didSet {
            for index in 0 ..< destinations.count {
                destinations[index].outputLevel = outputLevel
            }
        }
    }

    /// Option: enable ANSI colour codes
    open var xcodeColorsEnabled: Bool = false

    /// The colours to use for each log level
    open var xcodeColors: [XCGLogger.Level: XCGLogger.XcodeColor] = [
        .verbose: .lightGrey,
        .debug: .darkGrey,
        .info: .blue,
        .warning: .orange,
        .error: .red,
        .severe: .whiteOnRed
    ]

    /// Option: a closure to execute whenever a logging method is called without a log message
    open var noMessageClosure: () -> Any? = { return "" }

    // MARK: - Properties
    /// The default dispatch queue used for logging
    open class var logQueue: DispatchQueue {
        struct Statics {
            static var logQueue = DispatchQueue(label: XCGLogger.Constants.logQueueIdentifier, attributes: [])
        }

        return Statics.logQueue
    }

    /// The date formatter object to use when displaying the dates of log messages (internal storage)
    internal var _dateFormatter: DateFormatter? = nil
    /// The date formatter object to use when displaying the dates of log messages
    open var dateFormatter: DateFormatter? {
        get {
            if _dateFormatter != nil {
                return _dateFormatter
            }

            let defaultDateFormatter = DateFormatter()
            defaultDateFormatter.locale = NSLocale.current
            defaultDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            _dateFormatter = defaultDateFormatter

            return _dateFormatter
        }
        set {
            _dateFormatter = newValue
        }
    }

    /// Array containing all of the destinations for this logger
    open var destinations: [DestinationProtocol] = []

    // MARK: - Life Cycle
    public init(identifier: String = "", includeDefaultDestinations: Bool = true) {
        self.identifier = identifier

        // Check if XcodeColors is installed and enabled
        if let xcodeColors = ProcessInfo.processInfo.environment["XcodeColors"] {
            xcodeColorsEnabled = xcodeColors == "YES"
        }

        if includeDefaultDestinations {
            // Setup a standard console destination
            add(destination: ConsoleDestination(owner: self, identifier: XCGLogger.Constants.baseConsoleDestinationIdentifier))
        }
    }

    // MARK: - Setup methods
    /// A shortcut method to configure the default logger instance.
    ///
    /// - Note: The function exists to get you up and running quickly, but it's recommended that you use the advanced usage configuration for most projects. See https://github.com/DaveWoodCom/XCGLogger/blob/master/README.md#advanced-usage-recommended
    ///
    /// - Parameters:
    ///     - level: The log level of this logger, any logs received at this level or higher will be output to the destinations. **Default:** Debug
    ///     - showLogIdentifier: Whether or not to output the log identifier. **Default:** false
    ///     - showFunctionName: Whether or not to output the function name that generated the log. **Default:** true
    ///     - showThreadName: Whether or not to output the thread's name the log was created on. **Default:** false
    ///     - showLevel: Whether or not to output the log level of the log. **Default:** true
    ///     - showFileNames: Whether or not to output the filename that generated the log. **Default:** true
    ///     - showLineNumbers: Whether or not to output the line number where the log was generated. **Default:** true
    ///     - showDate: Whether or not to output the date the log was created. **Default:** true
    ///     - writeToFile: FileURL or path (as String) to a file to log all messages to (this file is overwritten each time the logger is created). **Default:** nil => no log file
    ///     - fileLevel: An alternate log level for the file destination. **Default:** nil => use the same log level as the console destination
    ///
    /// - Returns:  Nothing
    ///
    open class func setup(level: Level = .debug, showLogIdentifier: Bool = false, showFunctionName: Bool = true, showThreadName: Bool = false, showLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, showDate: Bool = true, writeToFile: Any? = nil, fileLevel: Level? = nil) {
        self.default.setup(level: level, showLogIdentifier: showLogIdentifier, showFunctionName: showFunctionName, showThreadName: showThreadName, showLevel: showLevel, showFileNames: showFileNames, showLineNumbers: showLineNumbers, showDate: showDate, writeToFile: writeToFile)
    }

    /// A shortcut method to configure the logger.
    ///
    /// - Note: The function exists to get you up and running quickly, but it's recommended that you use the advanced usage configuration for most projects. See https://github.com/DaveWoodCom/XCGLogger/blob/master/README.md#advanced-usage-recommended
    ///
    /// - Parameters:
    ///     - level: The log level of this logger, any logs received at this level or higher will be output to the destinations. **Default:** Debug
    ///     - showLogIdentifier: Whether or not to output the log identifier. **Default:** false
    ///     - showFunctionName: Whether or not to output the function name that generated the log. **Default:** true
    ///     - showThreadName: Whether or not to output the thread's name the log was created on. **Default:** false
    ///     - showLevel: Whether or not to output the log level of the log. **Default:** true
    ///     - showFileNames: Whether or not to output the filename that generated the log. **Default:** true
    ///     - showLineNumbers: Whether or not to output the line number where the log was generated. **Default:** true
    ///     - showDate: Whether or not to output the date the log was created. **Default:** true
    ///     - writeToFile: FileURL or path (as String) to a file to log all messages to (this file is overwritten each time the logger is created). **Default:** nil => no log file
    ///     - fileLevel: An alternate log level for the file destination. **Default:** nil => use the same log level as the console destination
    ///
    /// - Returns:  Nothing
    ///
    open func setup(level: Level = .debug, showLogIdentifier: Bool = false, showFunctionName: Bool = true, showThreadName: Bool = false, showLevel: Bool = true, showFileNames: Bool = true, showLineNumbers: Bool = true, showDate: Bool = true, writeToFile: Any? = nil, fileLevel: Level? = nil) {
        outputLevel = level

        if let standardConsoleDestination = destination(withIdentifier: XCGLogger.Constants.baseConsoleDestinationIdentifier) as? ConsoleDestination {
            standardConsoleDestination.showLogIdentifier = showLogIdentifier
            standardConsoleDestination.showFunctionName = showFunctionName
            standardConsoleDestination.showThreadName = showThreadName
            standardConsoleDestination.showLevel = showLevel
            standardConsoleDestination.showFileName = showFileNames
            standardConsoleDestination.showLineNumber = showLineNumbers
            standardConsoleDestination.showDate = showDate
            standardConsoleDestination.outputLevel = level
        }

        if let writeToFile: Any = writeToFile {
            // We've been passed a file to use for logging, set up a file logger
            let standardFileDestination: FileDestination = FileDestination(owner: self, writeToFile: writeToFile, identifier: XCGLogger.Constants.fileDestinationIdentifier)

            standardFileDestination.showLogIdentifier = showLogIdentifier
            standardFileDestination.showFunctionName = showFunctionName
            standardFileDestination.showThreadName = showThreadName
            standardFileDestination.showLevel = showLevel
            standardFileDestination.showFileName = showFileNames
            standardFileDestination.showLineNumber = showLineNumbers
            standardFileDestination.showDate = showDate
            standardFileDestination.outputLevel = fileLevel ?? level

            add(destination: standardFileDestination)
        }

        logAppDetails()
    }

    // MARK: - Logging methods
    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - level:     Specified log level **Default:** *Debug*.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing
    ///
    open class func logln(_ closure: @autoclosure @escaping () -> Any?, level: Level = .debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(level, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - level:     Specified log level **Default:** *Debug*.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing
    ///
    open class func logln(_ level: Level = .debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.default.logln(level, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - level:     Specified log level **Default:** *Debug*.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing
    ///
    open func logln(_ closure: @autoclosure @escaping () -> Any?, level: Level = .debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(level, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - level:     Specified log level **Default:** *Debug*.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing
    ///
    open func logln(_ level: Level = .debug, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        var logDetails: LogDetails!
        for destination in self.destinations {
            guard destination.isEnabledFor(level: level) else {
                continue
            }

            if logDetails == nil {
                guard let closureResult = closure() else {
                    break
                }

                logDetails = LogDetails(level: level, date: Date(), message: String(describing: closureResult), functionName: functionName, fileName: fileName, lineNumber: lineNumber)
            }

            destination.process(logDetails: logDetails)
        }
    }

    /// Execute some code only when at the specified log level.
    ///
    /// - Parameters:
    ///     - level:     Specified log level **Default:** *Debug*.
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func exec(_ level: Level = .debug, closure: () -> () = {}) {
        self.default.exec(level, closure: closure)
    }

    /// Execute some code only when at the specified log level.
    ///
    /// - Parameters:
    ///     - level:     Specified log level **Default:** *Debug*.
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func exec(_ level: Level = .debug, closure: () -> () = {}) {
        guard isEnabledFor(level:level) else {
            return
        }

        closure()
    }

    /// Generate logs to display your app's vitals (app name, version, etc) as well as XCGLogger's version and log level.
    ///
    /// - Parameters:
    ///     - level:     Specified log level **Default:** *Debug*.
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func logAppDetails(selectedDestination: DestinationProtocol? = nil) {
        let date = Date()

        var buildString = ""
        if let infoDictionary = Bundle.main.infoDictionary {
            if let CFBundleShortVersionString = infoDictionary["CFBundleShortVersionString"] as? String {
                // buildString = "Version: \(CFBundleShortVersionString) " // Note: Leaks in Swift versions prior to Swift 3
                buildString = "Version: " + CFBundleShortVersionString + " "
            }
            if let CFBundleVersion = infoDictionary["CFBundleVersion"] as? String {
                // buildString += "Build: \(CFBundleVersion) " // Note: Leaks in Swift versions prior to Swift 3
                buildString += "Build: " + CFBundleVersion + " "
            }
        }

        let processInfo: ProcessInfo = ProcessInfo.processInfo
        let XCGLoggerVersionNumber = XCGLogger.Constants.versionString

        // let logDetails: Array<LogDetails> = [LogDetails(level: .info, date: date, message: "\(processInfo.processName) \(buildString)PID: \(processInfo.processIdentifier)", functionName: "", fileName: "", lineNumber: 0),
        //     LogDetails(level: .info, date: date, message: "XCGLogger Version: \(XCGLoggerVersionNumber) - Level: \(outputLevel)", functionName: "", fileName: "", lineNumber: 0)] // Note: Leaks in Swift versions prior to Swift 3
        var logDetails: [LogDetails] = []
        logDetails.append(LogDetails(level: .info, date: date, message: processInfo.processName + " " + buildString + "PID: " + String(processInfo.processIdentifier), functionName: "", fileName: "", lineNumber: 0))
        logDetails.append(LogDetails(level: .info, date: date, message: "XCGLogger Version: " + XCGLoggerVersionNumber + " - Level: " + outputLevel.description, functionName: "", fileName: "", lineNumber: 0))

        for destination in (selectedDestination != nil ? [selectedDestination!] : destinations) {
            for logDetail in logDetails {
                guard destination.isEnabledFor(level:.info) else {
                    continue
                }

                destination.processInternal(logDetails: logDetail)
            }
        }
    }

    // MARK: - Convenience logging methods
    // MARK: * Verbose
    /// Log something at the Verbose log level. This format of verbose() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func verbose(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.default.noMessageClosure)
    }

    /// Log something at the Verbose log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func verbose(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Verbose log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func verbose(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.default.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Verbose log level. This format of verbose() isn't provided the object to log, instead the property *`noMessageClosure`* is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func verbose(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
    }

    /// Log something at the Verbose log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func verbose(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Verbose log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func verbose(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Debug
    /// Log something at the Debug log level. This format of debug() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func debug(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.default.noMessageClosure)
    }

    /// Log something at the Debug log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func debug(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Debug log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func debug(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.default.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Debug log level. This format of debug() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func debug(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
    }

    /// Log something at the Debug log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func debug(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Debug log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func debug(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Info
    /// Log something at the Info log level. This format of info() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func info(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.default.noMessageClosure)
    }

    /// Log something at the Info log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func info(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Info log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func info(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.default.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Info log level. This format of info() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func info(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
    }

    /// Log something at the Info log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func info(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Info log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func info(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Warning
    /// Log something at the Warning log level. This format of warning() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func warning(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.default.noMessageClosure)
    }

    /// Log something at the Warning log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func warning(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Warning log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func warning(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.default.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Warning log level. This format of warning() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func warning(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
    }

    /// Log something at the Warning log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func warning(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Warning log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func warning(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Error
    /// Log something at the Error log level. This format of error() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func error(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.default.noMessageClosure)
    }

    /// Log something at the Error log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func error(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Error log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func error(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.default.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Error log level. This format of error() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func error(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
    }

    /// Log something at the Error log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func error(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Error log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func error(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: * Severe
    /// Log something at the Severe log level. This format of severe() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func severe(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.default.noMessageClosure)
    }

    /// Log something at the Severe log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open class func severe(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.default.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Severe log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open class func severe(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.default.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Severe log level. This format of severe() isn't provided the object to log, instead the property `noMessageClosure` is executed instead.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func severe(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: self.noMessageClosure)
    }

    /// Log something at the Severe log level.
    ///
    /// - Parameters:
    ///     - closure:      A closure that returns the object to be logged.
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///
    /// - Returns:  Nothing.
    ///
    open func severe(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        self.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    /// Log something at the Severe log level.
    ///
    /// - Parameters:
    ///     - functionName: Normally omitted **Default:** *#function*.
    ///     - fileName:     Normally omitted **Default:** *#file*.
    ///     - lineNumber:   Normally omitted **Default:** *#line*.
    ///     - closure:      A closure that returns the object to be logged.
    ///
    /// - Returns:  Nothing.
    ///
    open func severe(_ functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: () -> Any?) {
        self.logln(.severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }

    // MARK: - Exec Methods
    // MARK: * Verbose
    /// Execute some code only when at the Verbose log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func verboseExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.Level.verbose, closure: closure)
    }

    /// Execute some code only when at the Verbose log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func verboseExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.Level.verbose, closure: closure)
    }

    // MARK: * Debug
    /// Execute some code only when at the Debug or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func debugExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.Level.debug, closure: closure)
    }

    /// Execute some code only when at the Debug or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func debugExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.Level.debug, closure: closure)
    }

    // MARK: * Info
    /// Execute some code only when at the Info or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func infoExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.Level.info, closure: closure)
    }

    /// Execute some code only when at the Info or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func infoExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.Level.info, closure: closure)
    }

    // MARK: * Warning
    /// Execute some code only when at the Warning or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func warningExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.Level.warning, closure: closure)
    }

    /// Execute some code only when at the Warning or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func warningExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.Level.warning, closure: closure)
    }

    // MARK: * Error
    /// Execute some code only when at the Error or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func errorExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.Level.error, closure: closure)
    }

    /// Execute some code only when at the Error or lower log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func errorExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.Level.error, closure: closure)
    }

    // MARK: * Severe
    /// Execute some code only when at the Severe log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open class func severeExec(_ closure: () -> () = {}) {
        self.default.exec(XCGLogger.Level.severe, closure: closure)
    }

    /// Execute some code only when at the Severe log level.
    ///
    /// - Parameters:
    ///     - closure:      The code closure to be executed.
    ///
    /// - Returns:  Nothing.
    ///
    open func severeExec(_ closure: () -> () = {}) {
        self.exec(XCGLogger.Level.severe, closure: closure)
    }

    // MARK: - Log destination methods
    /// Get the destination with the specified identifier.
    ///
    /// - Parameters:
    ///     - identifier:   Identifier of the destination to return.
    ///
    /// - Returns:  The destination with the specified identifier, if one exists, nil otherwise.
    /// 
    open func destination(withIdentifier identifier: String) -> DestinationProtocol? {
        for destination in destinations {
            if destination.identifier == identifier {
                return destination
            }
        }

        return nil
    }

    /// Add a new destination to the logger.
    ///
    /// - Parameters:
    ///     - destination:   The destination to add.
    ///
    /// - Returns:
    ///     - true:     Log destination was added successfully.
    ///     - false:    Failed to add the destination.
    ///
    @discardableResult open func add(destination: DestinationProtocol) -> Bool {
        let existingDestination: DestinationProtocol? = self.destination(withIdentifier: destination.identifier)
        if existingDestination != nil {
            return false
        }

        destinations.append(destination)
        return true
    }

    /// Remove the destination from the logger.
    ///
    /// - Parameters:
    ///     - destination:   The destination to remove.
    ///
    /// - Returns:  Nothing
    ///
    open func remove(destination: DestinationProtocol) {
        remove(destinationWithIdentifier: destination.identifier)
    }

    /// Remove the destination with the specified identifier from the logger.
    ///
    /// - Parameters:
    ///     - identifier:   The identifier of the destination to remove.
    ///
    /// - Returns:  Nothing
    ///
    open func remove(destinationWithIdentifier identifier: String) {
        destinations = destinations.filter({$0.identifier != identifier})
    }

    // MARK: - Misc methods
    /// Check if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - level: The log level to check.
    ///
    /// - Returns:
    ///     - true:     Logger is at the log level specified or lower.
    ///     - false:    Logger is at a higher log levelss.
    ///
    open func isEnabledFor(level: XCGLogger.Level) -> Bool {
        return level >= self.outputLevel
    }

    // MARK: - Private methods
    /// Log a message if the logger's log level is equal to or lower than the specified level.
    ///
    /// - Parameters:
    ///     - message:   Message to log.
    ///     - level:     Specified log level.
    ///
    /// - Returns:  Nothing
    ///
    internal func _logln(_ message: String, level: Level = .debug) {

        var logDetails: LogDetails? = nil
        for destination in self.destinations {
            if (destination.isEnabledFor(level:level)) {
                if logDetails == nil {
                    logDetails = LogDetails(level: level, date: Date(), message: message, functionName: "", fileName: "", lineNumber: 0)
                }

                destination.processInternal(logDetails: logDetails!)
            }
        }
    }

    // MARK: - DebugPrintable
    open var debugDescription: String {
        get {
            var description: String = "\(extractTypeName(self)): \(identifier) - destinations: \r"
            for destination in destinations {
                description += "\t \(destination.debugDescription)\r"
            }

            return description
        }
    }
}

// Implement Comparable for XCGLogger.Level
public func < (lhs: XCGLogger.Level, rhs: XCGLogger.Level) -> Bool {
    return lhs.rawValue < rhs.rawValue
}
