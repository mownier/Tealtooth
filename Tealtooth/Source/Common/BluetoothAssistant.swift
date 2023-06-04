import CoreBluetooth

public class BluetoothAssistant {
    private var centralManager: CBCentralManager
    private var centralManagerDelegate: CentralManagerDelegate
    private(set) var semaphore: DispatchSemaphore
    var connectResult: Result<Peripheral, Swift.Error>?
    public init(
        queue: DispatchQueue? = nil,
        options: [String: Any]? = nil
    ) {
        let centralManagerDelegate = CentralManagerDelegate()
        self.centralManager = CBCentralManager(
            delegate: centralManagerDelegate,
            queue: queue,
            options: options
        )
        self.centralManagerDelegate = centralManagerDelegate
        self.semaphore = DispatchSemaphore(value: 1)
        self.centralManagerDelegate.bluetoothAssistant = self
    }
    @discardableResult
    public func scan(services: [CBUUID]? = nil) -> Swift.Error? {
        if centralManager.state != .poweredOn {
            return TealtoothError.bluetoothNotPoweredOn
        }
        if centralManager.isScanning {
            return TealtoothError.alreadyScanning
        }
        centralManager.scanForPeripherals(withServices: services)
        return nil
    }
    @discardableResult
    public func stopScan() -> Swift.Error? {
        if centralManager.state != .poweredOn {
            return TealtoothError.bluetoothNotPoweredOn
        }
        if !centralManager.isScanning {
            return TealtoothError.scanningNotActive
        }
        centralManager.stopScan()
        return nil
    }
    @discardableResult
    public func connect(
        _ peripheral: Peripheral,
        timeout: Double,
        options: [String : Any]? = nil
    ) -> Result<Peripheral, Swift.Error> {
        if centralManager.state != .poweredOn {
            let error = TealtoothError.bluetoothNotPoweredOn
            logger?.writeConsole(LogLevel.error, "on connect, an error occurred \(error)")
            return .failure(error)
        }
        if peripheral.proxy.state == .connected {
            logger?.writeConsole(LogLevel.info, "on connect, it seems that the peripheral is already connected")
            return .success(peripheral)
        }
        if peripheral.proxy.state == .connecting {
            let error = TealtoothError.stillConnecting
            logger?.writeConsole(LogLevel.error, "on connect, an error occurred \(error)")
            return .failure(error)
        }
        centralManager.connect(peripheral.proxy, options: options)
        let semaphoreResult = semaphore.wait(timeout: .now() + timeout)
        if semaphoreResult == .timedOut {
            return .failure(TealtoothError.timedOutWhileTryingToConnect)
        }
        let result = connectResult ?? .failure(TealtoothError.connectResultIsNil)
        connectResult = nil
        return result
    }
    @discardableResult
    public func disconnect(
        _ peripheral: Peripheral
    ) -> Result<Peripheral, Swift.Error> {
        return .failure(TealtoothError.unimplemented)
    }
}
