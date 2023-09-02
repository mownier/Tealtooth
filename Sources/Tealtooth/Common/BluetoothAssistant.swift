import CoreBluetooth

public class BluetoothAssistant {
    public private(set) var name: String
    private var centralManager: CBCentralManager
    private var centralManagerDelegate: CentralManagerDelegate
    private(set) var semaphore: DispatchSemaphore
    private(set) var scanSemaphore: DispatchSemaphore
    private(set) var didInitiateDisconnect: Bool = false
    private(set) var didInitiateConnect: Bool = false
    private(set) var didInitiateStopScanWithTimeout: Bool = false
    var connectResult: Result<Peripheral, Swift.Error>?
    var disconnectResult: Result<Peripheral, Swift.Error>?
    public init(
        name: String,
        queue: DispatchQueue? = nil,
        options: [String: Any]? = nil
    ) {
        self.name = name
        let centralManagerDelegate = CentralManagerDelegate()
        self.centralManager = CBCentralManager(
            delegate: centralManagerDelegate,
            queue: queue,
            options: options
        )
        self.centralManagerDelegate = centralManagerDelegate
        self.semaphore = DispatchSemaphore(value: 1)
        self.scanSemaphore = DispatchSemaphore(value: 1)
        self.centralManagerDelegate.bluetoothAssistant = self
    }
    @discardableResult
    public func scan(services: [String]? = nil) -> Swift.Error? {
        if centralManager.state != .poweredOn {
            let error = TealtoothError.bluetoothNotPoweredOn
            logger?.writeConsole(LogLevel.error, "on scan, an error occurred \(error)")
            return error
        }
        if centralManager.isScanning {
            let error = TealtoothError.alreadyScanning
            logger?.writeConsole(LogLevel.error, "on scan, an error occurred \(error)")
            return error
        }
        logger?.writeConsole(LogLevel.info, "on scan for peripherals, " +
                             "services = \(String(describing: services))")
        centralManager.scanForPeripherals(withServices: services?.compactMap({ CBUUID(string: $0) }))
        return nil
    }
    @discardableResult
    public func stopScanAfter(_ timeout: Double) -> Swift.Error? {
        didInitiateStopScanWithTimeout = true
        _ = scanSemaphore.wait(timeout: .now() + 1.0)
        _ = scanSemaphore.wait(timeout: .now() + timeout)
        didInitiateStopScanWithTimeout = false
        let result = handleStopScan()
        postNotification(
            name: TealtoothNotification.onScanTimedOut.name,
            object: self
        )
        return result
    }
    @discardableResult
    public func stopScan() -> Swift.Error? {
        if didInitiateStopScanWithTimeout {
            scanSemaphore.signal()
            return nil
        }
        return handleStopScan()
    }
    @discardableResult
    public func retrievePeripherals(identifiers: [String]) -> Result<[Peripheral], Swift.Error> {
        if centralManager.state != .poweredOn {
            let error = TealtoothError.bluetoothNotPoweredOn
            logger?.writeConsole(LogLevel.error, "on retrieve peripherals, an error occurred \(error)")
            return .failure(error)
        }
        let uuids = identifiers.compactMap({ UUID(uuidString: $0) })
        logger?.writeConsole(LogLevel.error, "on retrieve peripherals, identifiers = \(identifiers)")
        logger?.writeConsole(LogLevel.error, "on retrieve peripherals, uuids = \(uuids)")
        let list = centralManager.retrievePeripherals(withIdentifiers: uuids).map({ Peripheral(proxy: $0) })
        logger?.writeConsole(LogLevel.info, "on retrieve peripherals, list = \(list.map({ $0.proxy.identifier }))")
        return .success(list)
    }
    @discardableResult
    public func retrievePeripheral(identifier: String) -> Result<Peripheral, Swift.Error> {
        logger?.writeConsole(LogLevel.info, "on retrieve single peripheral, identifier = \(identifier)")
        guard let uuid = UUID(uuidString: identifier) else {
            let error = TealtoothError.failedToConvertFromStringToUUID
            logger?.writeConsole(LogLevel.error, "on retrieve single peripheral, an error occured \(error)")
            return .failure(error)
        }
        let result = retrievePeripherals(identifiers: [identifier])
        if let error = result.error {
            logger?.writeConsole(LogLevel.error, "on retrieve single peripheral, an error occured \(error)")
            return .failure(error)
        }
        let list = result.info!
        guard let peripheral = list.filter({ $0.proxy.identifier == uuid }).first else {
            let error = TealtoothError.peripheralNotFound
            logger?.writeConsole(LogLevel.error, "on retrieve single peripheral, an error occured \(error)")
            return .failure(error)
        }
        logger?.writeConsole(LogLevel.error, "on retrieve single peripheral, found the peripheral with identifer = \(identifier)")
        return .success(peripheral)
    }
    @discardableResult
    public func connect(
        _ peripheral: Peripheral,
        timeout: Double,
        options: [String : Any]? = nil
    ) -> Result<Peripheral, Swift.Error> {
        didInitiateConnect = true
        defer { didInitiateConnect = false }
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
        logger?.writeConsole(LogLevel.info, "on connect, timeout = \(timeout), options = \(options.debugString)")
        centralManager.connect(peripheral.proxy, options: options)
        let semaphoreResult = semaphore.wait(timeout: .now() + timeout)
        if semaphoreResult == .timedOut {
            let error = TealtoothError.timedOutWhileTryingToConnect
            logger?.writeConsole(LogLevel.error, "on connect, an error occurred \(error)")
            return .failure(error)
        }
        let result = connectResult ?? .failure(TealtoothError.connectResultIsNil)
        connectResult = nil
        logger?.writeConsole(LogLevel.error, "on connect, result = \(result)")
        return result
    }
    @discardableResult
    public func disconnect(
        _ peripheral: Peripheral,
        timeout: Double
    ) -> Result<Peripheral, Swift.Error> {
        didInitiateDisconnect = true
        defer { didInitiateDisconnect = false }
        if centralManager.state != .poweredOn {
            let error = TealtoothError.bluetoothNotPoweredOn
            logger?.writeConsole(LogLevel.error, "on disconnect, an error occurred \(error)")
            return .failure(error)
        }
        if peripheral.proxy.state == .disconnected {
            logger?.writeConsole(LogLevel.info, "on disconnect, it seems that the peripheral is already disconnected")
            return .success(peripheral)
        }
        if peripheral.proxy.state == .disconnecting {
            let error = TealtoothError.stillDisconnecting
            logger?.writeConsole(LogLevel.error, "on disconnect, an error occurred \(error)")
            return .failure(error)
        }
        logger?.writeConsole(LogLevel.info, "on disconnect, timeout = \(timeout)")
        centralManager.cancelPeripheralConnection(peripheral.proxy)
        let semaphoreResult = semaphore.wait(timeout: .now() + timeout)
        if semaphoreResult == .timedOut {
            let error = TealtoothError.timedOutWhileTryingToDisconnect
            logger?.writeConsole(LogLevel.error, "on disconnect, an error occurred \(error)")
            return .failure(error)
        }
        let result = disconnectResult ?? .failure(TealtoothError.disconnectResultIsNil)
        disconnectResult = nil
        logger?.writeConsole(LogLevel.error, "on disconnect, result = \(result)")
        return result
    }
    private func handleStopScan() -> Swift.Error? {
        if centralManager.state != .poweredOn {
            let error = TealtoothError.bluetoothNotPoweredOn
            logger?.writeConsole(LogLevel.error, "on stop scan, an error occurred \(error)")
            return error
        }
        if !centralManager.isScanning {
            let error = TealtoothError.scanningNotActive
            logger?.writeConsole(LogLevel.error, "on stop scan, an error occurred \(error)")
            return error
        }
        logger?.writeConsole(LogLevel.info, "on stop scan")
        centralManager.stopScan()
        return nil
    }
}
