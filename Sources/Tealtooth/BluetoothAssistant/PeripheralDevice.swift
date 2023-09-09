import CoreBluetooth

// MARK: Cached peripherals

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

// MARK: RSSI

extension BluetoothAssistant {
    @discardableResult
    public func readRSSI(identifier: String, timeout: TimeInterval?) -> Result<Int, Swift.Error> {
        didInitiateReadRSSI = true
        defer { didInitiateReadRSSI = false }
        logger?.writeConsole(LogLevel.info, "on read RSSI, " +
                             "identifer = \(identifier), " +
                             "timeout = \(timeout == nil ? "nil" : "\(timeout!)")")
        let retrievePeripheralResult = retrievePeripheral(identifier: identifier)
        if let err = retrievePeripheralResult.error {
            logger?.writeConsole(LogLevel.error, "on read RSSI, an error occurred \(err)")
            return .failure(err)
        }
        let peripheral = retrievePeripheralResult.info!
        if peripheral.proxy.state != .connected {
            let error = TealtoothError.peripheralNotConnected
            logger?.writeConsole(LogLevel.error, "on read RSSI, an error occurred \(error)")
            return .failure(error)
        }
        peripheral.proxy.readRSSI()
        let mutex = semaphore(identifier).mutex
        let semaResult: DispatchTimeoutResult
        if let interval = timeout {
            semaResult = mutex.wait(timeout: .now() + interval)
        } else {
            semaResult = .success
            mutex.wait()
        }
        if semaResult == .timedOut {
            return .failure(TealtoothError.timedOutWhileTryingToReadRSSI)
        }
        let result = readRSSIResult ?? .failure(TealtoothError.readRSSIResultIsNil)
        readRSSIResult = nil
        logger?.writeConsole(
            result.error == nil ? LogLevel.info : LogLevel.error,
            "on connect, result = \(result)"
        )
        return result
    }
}

// MARK: Services

extension BluetoothAssistant {
    @discardableResult
    public func discoverServices(
        identifier: String,
        uuids: [String]?,
        timeout: TimeInterval?
    ) -> Result<[Service], Swift.Error> {
        didInitiateDiscoverServices = true
        defer { didInitiateDiscoverServices = false }
        logger?.writeConsole(LogLevel.info, "on discover services, " +
                             "identifer = \(identifier), " +
                             "service UUIDs = \(uuids == nil ? "nil" : "\(uuids!)"), " +
                             "timeout = \(timeout == nil ? "nil" : "\(timeout!)")")
        let retrievePeripheralResult = retrievePeripheral(identifier: identifier)
        if let err = retrievePeripheralResult.error {
            logger?.writeConsole(LogLevel.error, "on discover services, an error occurred \(err)")
            return .failure(err)
        }
        let peripheral = retrievePeripheralResult.info!
        if peripheral.proxy.state != .connected {
            let error = TealtoothError.peripheralNotConnected
            logger?.writeConsole(LogLevel.error, "on discover services, an error occurred \(error)")
            return .failure(error)
        }
        peripheral.proxy.discoverServices(uuids?.map({ CBUUID(string: $0) }))
        let mutex = semaphore(identifier).mutex
        let semaResult: DispatchTimeoutResult
        if let interval = timeout {
            semaResult = mutex.wait(timeout: .now() + interval)
        } else {
            semaResult = .success
            mutex.wait()
        }
        if semaResult == .timedOut {
            return .failure(TealtoothError.timedOutWhileTryingToDiscoverServices)
        }
        let result = discoverServicesResult ?? .failure(TealtoothError.discoverServicesResultIsNil)
        discoverServicesResult = nil
        logger?.writeConsole(
            result.error == nil ? LogLevel.info : LogLevel.error,
            "on discover services, result = \(result)"
        )
        return result
    }
    @discardableResult
    public func discoverService(
        identifier: String,
        uuid: String,
        timeout: TimeInterval?
    ) -> Result<Service, Swift.Error> {
        logger?.writeConsole(LogLevel.info, "on discover service, " +
                             "identifer = \(identifier), " +
                             "service UUID = \(uuid), " +
                             "timeout = \(timeout == nil ? "nil" : "\(timeout!)")")
        let discoverServicesResult = discoverServices(
            identifier: identifier,
            uuids: [uuid],
            timeout: timeout
        )
        if let err = discoverServicesResult.error {
            logger?.writeConsole(LogLevel.error, "on discover service \(uuid), an error occurred \(err)")
            return .failure(err)
        }
        let list = discoverServicesResult.info!
        if let service = list.first(where: { $0.proxy.uuid.uuidString == uuid }) {
            logger?.writeConsole(LogLevel.info, "on discover service \(uuid), found ? YES")
            return .success(service)
        }
        logger?.writeConsole(LogLevel.error, "on discover service \(uuid), found ? NO")
        return .failure(TealtoothError.serviceNotFound)
    }
}

// MARK: Included Services

extension BluetoothAssistant {
    @discardableResult
    public func discoverIncludedServices(
        identifier: String,
        uuids: [String]?,
        serviceUUID: String,
        timeout: TimeInterval?
    ) -> Result<[Service], Swift.Error> {
        didInitiateDiscoverIncludedServices = true
        defer { didInitiateDiscoverIncludedServices = false }
        logger?.writeConsole(LogLevel.info, "on discover included services, " +
                             "identifer = \(identifier), " +
                             "include service UUIDs = \(uuids == nil ? "nil" : "\(uuids!)"), " +
                             "service UUID = \(serviceUUID), " +
                             "timeout = \(timeout == nil ? "nil" : "\(timeout!)")")
        let retrievePeripheralResult = retrievePeripheral(identifier: identifier)
        if let err = retrievePeripheralResult.error {
            logger?.writeConsole(LogLevel.error, "on discover included services, an error occurred \(err)")
            return .failure(err)
        }
        let peripheral = retrievePeripheralResult.info!
        if peripheral.proxy.state != .connected {
            let error = TealtoothError.peripheralNotConnected
            logger?.writeConsole(LogLevel.error, "on discover included services, an error occurred \(error)")
            return .failure(error)
        }
        guard let service = peripheral.proxy.services?.first(where: { $0.uuid.uuidString == serviceUUID }) else {
            logger?.writeConsole(LogLevel.info, "on discover included services, service \(serviceUUID) not found")
            return .failure(TealtoothError.serviceNotFound)
        }
        peripheral.proxy.discoverIncludedServices(uuids?.map({ CBUUID(string: $0) }), for: service)
        let mutex = semaphore(identifier).mutex
        let semaResult: DispatchTimeoutResult
        if let interval = timeout {
            semaResult = mutex.wait(timeout: .now() + interval)
        } else {
            semaResult = .success
            mutex.wait()
        }
        if semaResult == .timedOut {
            return .failure(TealtoothError.timedOutWhileTryingToDiscoverIncludedServices)
        }
        let result = discoverIncludedServicesResult ?? .failure(TealtoothError.discoverIncludedServicesResultIsNil)
        discoverIncludedServicesResult = nil
        logger?.writeConsole(
            result.error == nil ? LogLevel.info : LogLevel.error,
            "on discover included services, result = \(result)"
        )
        return result
    }
    @discardableResult
    public func discoverIncludedService(
        identifier: String,
        uuid: String,
        serviceUUID: String,
        timeout: TimeInterval?
    ) -> Result<Service, Swift.Error> {
        logger?.writeConsole(LogLevel.info, "on discover included service, " +
                             "identifer = \(identifier), " +
                             "included service UUID = \(uuid), " +
                             "service UUID = \(serviceUUID), " +
                             "timeout = \(timeout == nil ? "nil" : "\(timeout!)")")
        let discoverIncludedServicesResult = discoverIncludedServices(
            identifier: identifier,
            uuids: [uuid],
            serviceUUID: serviceUUID,
            timeout: timeout
        )
        if let err = discoverIncludedServicesResult.error {
            logger?.writeConsole(LogLevel.error, "on discover included service \(uuid), an error occurred \(err)")
            return .failure(err)
        }
        let list = discoverIncludedServicesResult.info!
        if let service = list.first(where: { $0.proxy.uuid.uuidString == uuid }) {
            logger?.writeConsole(LogLevel.info, "on discover included service \(uuid), found ? YES")
            return .success(service)
        }
        logger?.writeConsole(LogLevel.error, "on discover included service \(uuid), found ? NO")
        return .failure(TealtoothError.includedServiceNotFound)
    }
}

// MARK: Charactersitics

extension BluetoothAssistant {
    @discardableResult
    public func discoverCharacteristics(
        identifier: String,
        uuids: [String]?,
        serviceUUID: String,
        timeout: TimeInterval?
    ) -> Result<[Characteristic], Swift.Error> {
        didInitiateDiscoverCharacteristics = true
        defer { didInitiateDiscoverCharacteristics = false }
        logger?.writeConsole(LogLevel.info, "on discover characteristics, " +
                             "identifer = \(identifier), " +
                             "characteristic UUIDs = \(uuids == nil ? "nil" : "\(uuids!)"), " +
                             "service UUID = \(serviceUUID), " +
                             "timeout = \(timeout == nil ? "nil" : "\(timeout!)")")
        let retrievePeripheralResult = retrievePeripheral(identifier: identifier)
        if let err = retrievePeripheralResult.error {
            logger?.writeConsole(LogLevel.error, "on discover characteristics, an error occurred \(err)")
            return .failure(err)
        }
        let peripheral = retrievePeripheralResult.info!
        if peripheral.proxy.state != .connected {
            let error = TealtoothError.peripheralNotConnected
            logger?.writeConsole(LogLevel.error, "on discover characteristics, an error occurred \(error)")
            return .failure(error)
        }
        guard let service = peripheral.proxy.services?.first(where: { $0.uuid.uuidString == serviceUUID }) else {
            logger?.writeConsole(LogLevel.error, "on discover characteristics, service \(serviceUUID) not found")
            return .failure(TealtoothError.serviceNotFound)
        }
        peripheral.proxy.discoverCharacteristics(uuids?.map({ CBUUID(string: $0) }), for: service)
        let mutex = semaphore(identifier).mutex
        let semaResult: DispatchTimeoutResult
        if let interval = timeout {
            semaResult = mutex.wait(timeout: .now() + interval)
        } else {
            semaResult = .success
            mutex.wait()
        }
        if semaResult == .timedOut {
            return .failure(TealtoothError.timedOutWhileTryingToDiscoverCharacteristics)
        }
        let result = discoverCharacteristicsResult ?? .failure(TealtoothError.discoverCharacteristicsResultIsNil)
        discoverCharacteristicsResult = nil
        logger?.writeConsole(
            result.error == nil ? LogLevel.info : LogLevel.error,
            "on discover characteristics, result = \(result)"
        )
        return result
    }
    @discardableResult
    public func discoverCharacteristic(
        identifier: String,
        uuid: String,
        serviceUUID: String,
        timeout: TimeInterval?
    ) -> Result<Characteristic, Swift.Error> {
        logger?.writeConsole(LogLevel.info, "on discover characteristic, " +
                             "identifer = \(identifier), " +
                             "characteristic UUID = \(uuid), " +
                             "service UUID = \(serviceUUID), " +
                             "timeout = \(timeout == nil ? "nil" : "\(timeout!)")")
        let discoverCharacteristicsResult = discoverCharacteristics(
            identifier: identifier,
            uuids: [uuid],
            serviceUUID: serviceUUID,
            timeout: timeout
        )
        if let err = discoverCharacteristicsResult.error {
            logger?.writeConsole(LogLevel.error, "on discover characteristic \(uuid), an error occurred \(err)")
            return .failure(err)
        }
        let list = discoverCharacteristicsResult.info!
        if let characteristic = list.first(where: { $0.proxy.uuid.uuidString == uuid }) {
            logger?.writeConsole(LogLevel.info, "on discover characteristic \(uuid), found ? YES")
            return .success(characteristic)
        }
        logger?.writeConsole(LogLevel.error, "on discover characteristic \(uuid), found ? NO")
        return .failure(TealtoothError.characteristicNotFound)
    }
    @discardableResult
    public func readCharacteristic(
        identifier: String,
        uuid: String,
        serviceUUID: String,
        timeout: TimeInterval?
    ) -> Result<Characteristic, Swift.Error> {
        didInitiateReadCharacteristic = true
        defer { didInitiateReadCharacteristic = false }
        logger?.writeConsole(LogLevel.info, "on read characteristic, " +
                             "identifer = \(identifier), " +
                             "characteristic UUID = \(uuid), " +
                             "service UUID = \(serviceUUID), " +
                             "timeout = \(timeout == nil ? "nil" : "\(timeout!)")")
        let retrievePeripheralResult = retrievePeripheral(identifier: identifier)
        if let err = retrievePeripheralResult.error {
            logger?.writeConsole(LogLevel.info, "on read characteristic, an error occurred \(err)")
            return .failure(err)
        }
        let peripheral = retrievePeripheralResult.info!
        if peripheral.proxy.state != .connected {
            let error = TealtoothError.peripheralNotConnected
            logger?.writeConsole(LogLevel.error, "on read characteristic, an error occurred \(error)")
            return .failure(error)
        }
        guard let service = peripheral.proxy.services?.first(where: { $0.uuid.uuidString == serviceUUID }) else {
            logger?.writeConsole(LogLevel.error, "on read characteristic, service \(serviceUUID) not found")
            return .failure(TealtoothError.serviceNotFound)
        }
        guard let characteristic = service.characteristics?.first(where: { $0.uuid.uuidString == uuid }) else {
            logger?.writeConsole(LogLevel.error, "on read characteristic, characteristic \(uuid) not found")
            return .failure(TealtoothError.characteristicNotFound)
        }
        peripheral.proxy.readValue(for: characteristic)
        let mutex = semaphore(identifier).mutex
        let semaResult: DispatchTimeoutResult
        if let interval = timeout {
            semaResult = mutex.wait(timeout: .now() + interval)
        } else {
            semaResult = .success
            mutex.wait()
        }
        if semaResult == .timedOut {
            return .failure(TealtoothError.timedOutWhileTryingToReadCharacteristic)
        }
        let result = readCharacteristicResult ?? .failure(TealtoothError.readCharacteristicResultIsNil)
        readCharacteristicResult = nil
        logger?.writeConsole(
            result.error == nil ? LogLevel.info : LogLevel.error,
            "on read characteristic, result = \(result)"
        )
        return result
    }
    @discardableResult
    public func writeCharacteristic(
        identifier: String,
        data: Data,
        hasResponse: Bool,
        uuid: String,
        serviceUUID: String,
        timeout: TimeInterval?
    ) -> Result<Characteristic, Swift.Error> {
        didInitiateWriteCharacteristic = true
        defer { didInitiateWriteCharacteristic = false }
        logger?.writeConsole(LogLevel.info, "on write characteristic, " +
                             "identifer = \(identifier), " +
                             "data = \([UInt8](data)), " +
                             "hasResponse = \(hasResponse), " +
                             "characteristic UUID = \(uuid), " +
                             "service UUID = \(serviceUUID), " +
                             "timeout = \(timeout == nil ? "nil" : "\(timeout!)")")
        let retrievePeripheralResult = retrievePeripheral(identifier: identifier)
        if let err = retrievePeripheralResult.error {
            logger?.writeConsole(LogLevel.error, "on write characteristic, an error occurred \(err)")
            return .failure(err)
        }
        let peripheral = retrievePeripheralResult.info!
        if peripheral.proxy.state != .connected {
            let error = TealtoothError.peripheralNotConnected
            logger?.writeConsole(LogLevel.error, "on write characteristic, an error occurred \(error)")
            return .failure(error)
        }
        guard let service = peripheral.proxy.services?.first(where: { $0.uuid.uuidString == serviceUUID }) else {
            logger?.writeConsole(LogLevel.error, "on write characteristic, service \(serviceUUID) not found")
            return .failure(TealtoothError.serviceNotFound)
        }
        guard let characteristic = service.characteristics?.first(where: { $0.uuid.uuidString == uuid }) else {
            logger?.writeConsole(LogLevel.error, "on write characteristic, characteristic \(uuid) not found")
            return .failure(TealtoothError.characteristicNotFound)
        }
        peripheral.proxy.writeValue(
            data,
            for: characteristic,
            type: hasResponse ? .withResponse : .withoutResponse
        )
        if !hasResponse {
            logger?.writeConsole(LogLevel.info, "on write characteristic, no need to wait for the response")
            return .success(Characteristic(proxy: characteristic))
        }
        let mutex = semaphore(identifier).mutex
        let semaResult: DispatchTimeoutResult
        if let interval = timeout {
            semaResult = mutex.wait(timeout: .now() + interval)
        } else {
            semaResult = .success
            mutex.wait()
        }
        if semaResult == .timedOut {
            return .failure(TealtoothError.timedOutWhileTryingToWriteCharacteristic)
        }
        let result = writeCharacteristicResult ?? .failure(TealtoothError.writeCharacteristicResultIsNil)
        writeCharacteristicResult = nil
        logger?.writeConsole(
            result.error == nil ? LogLevel.info : LogLevel.error,
            "on write characteristic, result = \(result)"
        )
        return result
    }
    @discardableResult
    public func updateNotifyStatus(
        identifier: String,
        enabled: Bool,
        characteristicUUID: String,
        serviceUUID: String,
        timeout: TimeInterval?
    ) -> Result<Characteristic, Swift.Error> {
        didInitiateUpdateNotifyStatus = true
        defer { didInitiateUpdateNotifyStatus = false }
        logger?.writeConsole(LogLevel.info, "on update notify status, " +
                             "identifer = \(identifier), " +
                             "enabled = \(enabled), " +
                             "characteristic UUID = \(characteristicUUID), " +
                             "service UUID = \(serviceUUID), " +
                             "timeout = \(timeout == nil ? "nil" : "\(timeout!)")")
        let retrievePeripheralResult = retrievePeripheral(identifier: identifier)
        if let err = retrievePeripheralResult.error {
            logger?.writeConsole(LogLevel.error, "on update notify status, an error occurred \(err)")
            return .failure(err)
        }
        let peripheral = retrievePeripheralResult.info!
        if peripheral.proxy.state != .connected {
            let error = TealtoothError.peripheralNotConnected
            logger?.writeConsole(LogLevel.error, "on update notify status, an error occurred \(error)")
            return .failure(error)
        }
        guard let service = peripheral.proxy.services?.first(where: { $0.uuid.uuidString == serviceUUID }) else {
            logger?.writeConsole(LogLevel.error, "on update notify status, service \(serviceUUID) not found")
            return .failure(TealtoothError.serviceNotFound)
        }
        guard let characteristic = service.characteristics?.first(where: { $0.uuid.uuidString == characteristicUUID }) else {
            logger?.writeConsole(LogLevel.error, "on update notify status, characteristic \(characteristicUUID) not found")
            return .failure(TealtoothError.characteristicNotFound)
        }
        peripheral.proxy.setNotifyValue(enabled, for: characteristic)
        let mutex = semaphore(identifier).mutex
        let semaResult: DispatchTimeoutResult
        if let interval = timeout {
            semaResult = mutex.wait(timeout: .now() + interval)
        } else {
            semaResult = .success
            mutex.wait()
        }
        if semaResult == .timedOut {
            return .failure(TealtoothError.timedOutWhileTryingToUpdateNotifyStatus)
        }
        let result = updateNotifyStatusResult ?? .failure(TealtoothError.updateNotifyStatusResultIsNil)
        updateNotifyStatusResult = nil
        logger?.writeConsole(
            result.error == nil ? LogLevel.info : LogLevel.error,
            "on update notify status, result = \(result)"
        )
        return result
    }
}

// MARK: Descriptors

extension BluetoothAssistant {
    @discardableResult
    public func discoverDescriptors(
        identifier: String,
        uuids: [String]?,
        characteristicUUID: String,
        serviceUUID: String,
        timeout: TimeInterval?
    ) -> Result<[Descriptor], Swift.Error> {
        didInitiateDiscoverDescriptors = true
        defer { didInitiateDiscoverDescriptors = false }
        logger?.writeConsole(LogLevel.info, "on discover descriptors, " +
                             "identifer = \(identifier), " +
                             "descriptor UUIDs = \(uuids == nil ? "nil" : "\(uuids!)"), " +
                             "characteristicUUID UUID = \(characteristicUUID), " +
                             "service UUID = \(serviceUUID), " +
                             "timeout = \(timeout == nil ? "nil" : "\(timeout!)")")
        let retrievePeripheralResult = retrievePeripheral(identifier: identifier)
        if let err = retrievePeripheralResult.error {
            logger?.writeConsole(LogLevel.error, "on discover descriptors, an error occurred \(err)")
            return .failure(err)
        }
        let peripheral = retrievePeripheralResult.info!
        if peripheral.proxy.state != .connected {
            let error = TealtoothError.peripheralNotConnected
            logger?.writeConsole(LogLevel.error, "on discover descriptors, an error occurred \(error)")
            return .failure(error)
        }
        guard let service = peripheral.proxy.services?.first(where: { $0.uuid.uuidString == serviceUUID }) else {
            logger?.writeConsole(LogLevel.error, "on discover descriptors, service \(serviceUUID) not found")
            return .failure(TealtoothError.serviceNotFound)
        }
        guard let characteristic = service.characteristics?.first(where: { $0.uuid.uuidString == characteristicUUID }) else {
            logger?.writeConsole(LogLevel.error, "on discover descriptors, characteristic \(characteristicUUID) not found")
            return .failure(TealtoothError.characteristicNotFound)
        }
        peripheral.proxy.discoverDescriptors(for: characteristic)
        let mutex = semaphore(identifier).mutex
        let semaResult: DispatchTimeoutResult
        if let interval = timeout {
            semaResult = mutex.wait(timeout: .now() + interval)
        } else {
            semaResult = .success
            mutex.wait()
        }
        if semaResult == .timedOut {
            return .failure(TealtoothError.timedOutWhileTryingToDiscoverDescriptors)
        }
        let result = discoverDescriptorsResult ?? .failure(TealtoothError.discoverDescriptorsResultIsNil)
        discoverDescriptorsResult = nil
        logger?.writeConsole(
            result.error == nil ? LogLevel.info : LogLevel.error,
            "on discover descriptors, result = \(result)"
        )
        return result
    }
    @discardableResult
    public func discoverDescriptor(
        identifier: String,
        uuid: String,
        characteristicUUID: String,
        serviceUUID: String,
        timeout: TimeInterval?
    ) -> Result<Descriptor, Swift.Error> {
        logger?.writeConsole(LogLevel.info, "on discover descriptor, " +
                             "identifer = \(identifier), " +
                             "descriptor UUID = \(uuid), " +
                             "characteristic UUID = \(characteristicUUID), " +
                             "service UUID = \(serviceUUID), " +
                             "timeout = \(timeout == nil ? "nil" : "\(timeout!)")")
        let discoverDescriptorsResult = discoverDescriptors(
            identifier: identifier,
            uuids: [uuid],
            characteristicUUID: characteristicUUID,
            serviceUUID: serviceUUID,
            timeout: timeout
        )
        if let err = discoverDescriptorsResult.error {
            logger?.writeConsole(LogLevel.error, "on discover descriptor \(uuid), an error occurred \(err)")
            return .failure(err)
        }
        let list = discoverDescriptorsResult.info!
        if let descriptor = list.first(where: { $0.proxy.uuid.uuidString == uuid }) {
            logger?.writeConsole(LogLevel.info, "on discover descriptor \(uuid), found ? YES")
            return .success(descriptor)
        }
        logger?.writeConsole(LogLevel.error, "on discover descriptor \(uuid), found ? NO")
        return .failure(TealtoothError.descriptorNotFound)
    }
    @discardableResult
    public func readDescriptor(
        identifier: String,
        uuid: String,
        characteristicUUID: String,
        serviceUUID: String,
        timeout: TimeInterval?
    ) -> Result<Descriptor, Swift.Error> {
        didInitiateReadDescriptor = true
        defer { didInitiateReadDescriptor = false }
        logger?.writeConsole(LogLevel.info, "on read descriptor, " +
                             "identifer = \(identifier), " +
                             "descriptor UUID = \(uuid), " +
                             "characteristic UUID = \(characteristicUUID), " +
                             "service UUID = \(serviceUUID), " +
                             "timeout = \(timeout == nil ? "nil" : "\(timeout!)")")
        let retrievePeripheralResult = retrievePeripheral(identifier: identifier)
        if let err = retrievePeripheralResult.error {
            logger?.writeConsole(LogLevel.info, "on read descriptor, an error occurred \(err)")
            return .failure(err)
        }
        let peripheral = retrievePeripheralResult.info!
        if peripheral.proxy.state != .connected {
            let error = TealtoothError.peripheralNotConnected
            logger?.writeConsole(LogLevel.error, "on read descriptor, an error occurred \(error)")
            return .failure(error)
        }
        guard let service = peripheral.proxy.services?.first(where: { $0.uuid.uuidString == serviceUUID }) else {
            logger?.writeConsole(LogLevel.error, "on read descriptor, service \(serviceUUID) not found")
            return .failure(TealtoothError.serviceNotFound)
        }
        guard let characteristic = service.characteristics?.first(where: { $0.uuid.uuidString == characteristicUUID }) else {
            logger?.writeConsole(LogLevel.error, "on read descriptor, characteristic \(characteristicUUID) not found")
            return .failure(TealtoothError.characteristicNotFound)
        }
        guard let descriptor = characteristic.descriptors?.first(where: { $0.uuid.uuidString == uuid }) else {
            logger?.writeConsole(LogLevel.error, "on read descriptor, descriptor \(uuid) not found")
            return .failure(TealtoothError.descriptorNotFound)
        }
        peripheral.proxy.readValue(for: descriptor)
        let mutex = semaphore(identifier).mutex
        let semaResult: DispatchTimeoutResult
        if let interval = timeout {
            semaResult = mutex.wait(timeout: .now() + interval)
        } else {
            semaResult = .success
            mutex.wait()
        }
        if semaResult == .timedOut {
            return .failure(TealtoothError.timedOutWhileTryingToReadDescriptor)
        }
        let result = readDescriptorResult ?? .failure(TealtoothError.readDescriptorResultIsNil)
        readDescriptorResult = nil
        logger?.writeConsole(
            result.error == nil ? LogLevel.info : LogLevel.error,
            "on read descriptor, result = \(result)"
        )
        return result
    }
    @discardableResult
    public func writeDescriptor(
        identifier: String,
        data: Data,
        uuid: String,
        characteristicUUID: String,
        serviceUUID: String,
        timeout: TimeInterval?
    ) -> Result<Descriptor, Swift.Error> {
        didInitiateWriteCharacteristic = true
        defer { didInitiateWriteCharacteristic = false }
        logger?.writeConsole(LogLevel.info, "on write descriptor, " +
                             "identifer = \(identifier), " +
                             "data = \([UInt8](data)), " +
                             "descriptor UUID = \(uuid), " +
                             "characteristic UUID = \(characteristicUUID), " +
                             "service UUID = \(serviceUUID), " +
                             "timeout = \(timeout == nil ? "nil" : "\(timeout!)")")
        let retrievePeripheralResult = retrievePeripheral(identifier: identifier)
        if let err = retrievePeripheralResult.error {
            logger?.writeConsole(LogLevel.error, "on write descriptor, an error occurred \(err)")
            return .failure(err)
        }
        let peripheral = retrievePeripheralResult.info!
        if peripheral.proxy.state != .connected {
            let error = TealtoothError.peripheralNotConnected
            logger?.writeConsole(LogLevel.error, "on write descriptor, an error occurred \(error)")
            return .failure(error)
        }
        guard let service = peripheral.proxy.services?.first(where: { $0.uuid.uuidString == serviceUUID }) else {
            logger?.writeConsole(LogLevel.error, "on write descriptor, service \(serviceUUID) not found")
            return .failure(TealtoothError.serviceNotFound)
        }
        guard let characteristic = service.characteristics?.first(where: { $0.uuid.uuidString == characteristicUUID }) else {
            logger?.writeConsole(LogLevel.error, "on write descriptor, characteristic \(characteristicUUID) not found")
            return .failure(TealtoothError.characteristicNotFound)
        }
        guard let descriptor = characteristic.descriptors?.first(where: { $0.uuid.uuidString == uuid }) else {
            logger?.writeConsole(LogLevel.error, "on read descriptor, descriptor \(uuid) not found")
            return .failure(TealtoothError.descriptorNotFound)
        }
        peripheral.proxy.writeValue(
            data,
            for: descriptor
        )
        let mutex = semaphore(identifier).mutex
        let semaResult: DispatchTimeoutResult
        if let interval = timeout {
            semaResult = mutex.wait(timeout: .now() + interval)
        } else {
            semaResult = .success
            mutex.wait()
        }
        if semaResult == .timedOut {
            return .failure(TealtoothError.timedOutWhileTryingToWriteDescriptor)
        }
        let result = writeDescriptorResult ?? .failure(TealtoothError.writeDescriptorResultIsNil)
        writeDescriptorResult = nil
        logger?.writeConsole(
            result.error == nil ? LogLevel.info : LogLevel.error,
            "on write descriptor, result = \(result)"
        )
        return result
    }
}
