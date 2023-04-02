import Foundation

public protocol Logger {
    func writeConsole(_ level: Any, _ message: Any)
}

public class DefaultLogger: Logger {
    private let dateFormatter: DateFormatter
    private let tag: String
    public init(tag: String = logTag) {
        self.tag = tag
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "MMM dd, yyyy h:mm:ss a"
    }
    public func writeConsole(_ level: Any, _ message: Any) {
        print("\(dateFormatter.string(from: Date())) [\(tag)] <\(level)> \(message)")
    }
}

public func updateLogger(_ value: Logger?) {
    logger = value
}

public var logTag: String { "Tealtooth" }
private(set) var logger: Logger?
