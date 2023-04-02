import Foundation

public protocol Logger {
    func writeConsole(_ level: Any, _ message: Any)
}

public class DefaultLogger: Logger {
    private let dateFormatter: DateFormatter
    private let tag: String
    private let queue: OperationQueue
    public init(tag: String = logTag) {
        self.tag = tag
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "MMM dd, yyyy h:mm:ss a"
        self.queue = OperationQueue()
        self.queue.maxConcurrentOperationCount = 1
    }
    public func writeConsole(_ level: Any, _ message: Any) {
        queue.addOperation { [unowned self] in
            print("\(self.dateFormatter.string(from: Date())) [\(self.tag)] <\(level)> \(message)")
        }
    }
}

public func updateLogger(_ value: Logger?) {
    logger = value
}

public var logTag: String { "Tealtooth" }
private(set) var logger: Logger?
