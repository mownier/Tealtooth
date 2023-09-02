import CoreBluetooth

extension BluetoothAssistant {
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
        let semaphoreResult = semaphore(peripheral.keyName).mutex.wait(timeout: .now() + timeout)
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
        let semaphoreResult = semaphore(peripheral.keyName).mutex.wait(timeout: .now() + timeout)
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
}
