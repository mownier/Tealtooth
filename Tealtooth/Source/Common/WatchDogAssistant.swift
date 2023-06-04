import Foundation

open class WatchDogAssistant {
    public private(set) var isValid: Bool
    public private(set) var interval: TimeInterval
    public private(set) weak var bluetoothAssistant: BluetoothAssistant?
    private var timer: Timer?
    private var isStarted: Bool
    private var isStarting: Bool
    public init(interval: TimeInterval) {
        self.interval = interval
        self.isValid = true
        self.isStarted = false
        self.isStarting = false
    }
    open func onTick() {
    }
    open func onInvalidate() {
    }
    @discardableResult
    fileprivate func start(_ assistant: BluetoothAssistant) -> Bool {
        if !isValid || isStarted || isStarting {
            return false
        }
        isStarted = false
        isStarting = true
        bluetoothAssistant = assistant
        DispatchQueue.main.async { [weak self] in
            guard let this = self else {
                return
            }
            if let timer = this.timer, timer.isValid {
                timer.invalidate()
            }
            this.timer = nil
            let timer = Timer.scheduledTimer(
                withTimeInterval: this.interval,
                repeats: true
            ) { [weak self] _ in
                if self?.isValid == true {
                    self?.onTick()
                }
            }
            this.timer = timer
            RunLoop.main.add(timer, forMode: .default)
            timer.fire()
            this.isStarted = true
            this.isStarting = false
        }
        return true
    }
    @discardableResult
    fileprivate func invalidate() -> Bool {
        if !isValid {
            return false
        }
        isValid = false
        bluetoothAssistant = nil
        onInvalidate()
        DispatchQueue.main.async { [weak self] in
            guard let this = self else {
                return
            }
            if let timer = this.timer, timer.isValid {
                timer.invalidate()
            }
            this.timer = nil
        }
        return true
    }
}

open class DefaultWatchDogAssistant : WatchDogAssistant {
    private var queue: OperationQueue?
    private var shouldAddOperation: Bool = true
    open override func onTick() {
        if queue == nil {
            queue = OperationQueue()
            queue?.maxConcurrentOperationCount = 1
        }
        if !shouldAddOperation {
            return
        }
        shouldAddOperation = false
        queue?.addOperation { [weak self] in
            self?.performOperation()
            self?.shouldAddOperation = true
        }
    }
    open override func onInvalidate() {
        queue?.cancelAllOperations()
        queue = nil
    }
    open func performOperation() {
    }
}

public class WatchDogAssistantManager {
    private static var watchDogAssistants: [String : WatchDogAssistant] = [:]
    @discardableResult
    public static func start(
        key: String,
        watchDog: WatchDogAssistant,
        bluetooth: BluetoothAssistant
    ) -> Bool {
        if let current = watchDogAssistants[key] {
            current.invalidate()
            watchDogAssistants.removeValue(forKey: key)
        }
        watchDogAssistants[key] = watchDog
        return watchDog.start(bluetooth)
    }
    @discardableResult
    public static func invalidate(key: String) -> Bool {
        if let current = watchDogAssistants[key] {
            let result = current.invalidate()
            watchDogAssistants.removeValue(forKey: key)
            return result
        }
        return false
    }
}
