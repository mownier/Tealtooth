import Foundation

open class WatchDogAssistant {
    public private(set) var isValid: Bool
    public private(set) weak var bluetoothAssistant: BluetoothAssistant?
    private var interval: TimeInterval
    private var timer: Timer?
    private var isStarted: Bool
    private var isStarting: Bool
    public init(interval: TimeInterval) {
        self.interval = interval
        self.isValid = true
        self.isStarted = false
        self.isStarting = false
    }
    open func doAction() {
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
                    self?.doAction()
                }
            }
            this.timer = timer
            RunLoop.main.add(timer, forMode: .default)
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

public class WatchDogAssistantManager {
    private static var currentWatchDog: WatchDogAssistant?
    @discardableResult
    public static func start(watchdog: WatchDogAssistant, bluetooth: BluetoothAssistant) -> Bool {
        if let current = currentWatchDog {
            current.invalidate()
        }
        WatchDogAssistantManager.currentWatchDog = watchdog
        return watchdog.start(bluetooth)
    }
}

public class DefaultWatchDogAssistant : WatchDogAssistant {
    public override func doAction() {
        print("Hi, will do action")
    }
}

func foo() {
    let watchdog = WatchDogAssistant(interval: 1.5)
    let bluetooth = BluetoothAssistant(queue: DispatchQueue(label: "sample.ble.assistant.dq"))
    WatchDogAssistantManager.start(watchdog: watchdog, bluetooth: bluetooth)
}
