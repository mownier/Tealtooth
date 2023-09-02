import CoreBluetooth

extension BluetoothAssistant {
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
        _ = scanSemaphore().mutex.wait(timeout: .now() + 1.0)
        _ = scanSemaphore().mutex.wait(timeout: .now() + timeout)
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
            scanSemaphore().mutex.signal()
            return nil
        }
        return handleStopScan()
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
