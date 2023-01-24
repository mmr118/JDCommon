//
//  File.swift
//  
//
//  Created by Conway Charles on 10/26/22.
//

import Foundation


/// Abstraction to allow different logging libraries to be substituted at runtime.
public protocol GenericLogger {

    func verbose(_ text: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?)
    func debug(_ text: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?)
    func info(_ text: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?)
    func warning(_ text: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?)
    func error(_ text: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?)
}

/// A default placeholder logging instance. This is never intended to be used and will emit a warning on first use.
public struct MockLogger: GenericLogger {
    
    static var hasIssuedWarning = false
    
    static func issueWarning() {
        guard hasIssuedWarning == false else { return }
        print("WARNING: JDCommonLogging.sharedLog used without assigning a logger, log outputs will be lost. This message will not be repeated.")
        hasIssuedWarning = true
    }
    
    public func verbose(_ text: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?) { Self.issueWarning() }
    public func debug(_ text: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?) { Self.issueWarning() }
    public func info(_ text: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?) { Self.issueWarning() }
    public func warning(_ text: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?) { Self.issueWarning() }
    public func error(_ text: @autoclosure () -> Any, _ file: String, _ function: String, line: Int, context: Any?) { Self.issueWarning() }
}

/// An abstraction to allow injection of a logging instance into library dependencies without tightly coupling them to the specific logging library being used
/// by the main application. Each dependency includes the lightweight JDCommonLogging module and then at runtime the main application can inject a
/// logging instance into the `JDCommonLog.sharedLog` singleton property for each of the other libraries to use.
public class JDCommonLog {
    
    /// A shared logging instance to be initialized by the main application and injected into `JDCommonLog` at runtime to make it available to other
    /// libraries.
    public static var sharedLog: JDCommonLog = JDCommonLog(logger: MockLogger())
    
    let logger: GenericLogger
    
    public init(logger: GenericLogger) {
        self.logger = logger
    }
    
    public func verbose(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        logger.verbose(message(), file, function, line: line, context: context)
    }
    
    public func debug(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        logger.debug(message(), file, function, line: line, context: context)
    }
    
    public func info(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        logger.info(message(), file, function, line: line, context: context)
    }
    
    public func warning(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        logger.warning(message(), file, function, line: line, context: context)
    }
    
    public func error(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        logger.error(message(), file, function, line: line, context: context)
    }
}
