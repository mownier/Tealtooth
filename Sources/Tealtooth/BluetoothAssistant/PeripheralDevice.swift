import Foundation

extension BluetoothAssistant {
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
}
