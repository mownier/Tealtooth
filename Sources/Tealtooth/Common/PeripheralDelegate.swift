import CoreBluetooth

class PeripheralDelegate: NSObject, CBPeripheralDelegate {
    weak var assistant: BluetoothAssistant?
    func peripheral(
        _ peripheral: CBPeripheral,
        didReadRSSI RSSI: NSNumber,
        error: Error?
    ) {
        assistant?.processor(peripheral.keyName).resultQueue.addOperation { [weak self] in
            if self?.assistant?.didInitiateReadRSSI == false {
                return
            }
            self?.assistant?.readRSSIResult = .success(RSSI.intValue)
            self?.assistant?.semaphore(peripheral.keyName).mutex.signal()
        }
    }
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?
    ) {
        assistant?.processor(peripheral.keyName).resultQueue.addOperation { [weak self] in
            if self?.assistant?.didInitiateDiscoverServices == false {
                return
            }
            defer {
                self?.assistant?.semaphore(peripheral.keyName).mutex.signal()
            }
            if let err = error {
                self?.assistant?.discoverServicesResult = .failure(err)
                return
            }
            let list: [Service] = peripheral.services?.map({ Service(proxy: $0) }) ?? []
            self?.assistant?.discoverServicesResult = .success(list)
        }
    }
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverIncludedServicesFor service: CBService,
        error: Error?
    ) {
        assistant?.processor(peripheral.keyName).resultQueue.addOperation { [weak self] in
            if self?.assistant?.didInitiateDiscoverIncludedServices == false {
                return
            }
            defer {
                self?.assistant?.semaphore(peripheral.keyName).mutex.signal()
            }
            if let err = error {
                self?.assistant?.discoverIncludedServicesResult = .failure(err)
                return
            }
            let list: [Service] = service.includedServices?.map({ Service(proxy: $0) }) ?? []
            self?.assistant?.discoverIncludedServicesResult = .success(list)
        }
        
    }
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        assistant?.processor(peripheral.keyName).resultQueue.addOperation { [weak self] in
            if self?.assistant?.didInitiateDiscoverCharacteristics == false {
                return
            }
            defer {
                self?.assistant?.semaphore(peripheral.keyName).mutex.signal()
            }
            if let err = error {
                self?.assistant?.discoverCharacteristicsResult = .failure(err)
                return
            }
            let list: [Characteristic] = service.characteristics?.map({ Characteristic(proxy: $0) }) ?? []
            self?.assistant?.discoverCharacteristicsResult = .success(list)
        }
    }
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        assistant?.processor(peripheral.keyName).resultQueue.addOperation { [weak self] in
            if self?.assistant?.didInitiateDiscoverDescriptors == false {
                return
            }
            defer {
                self?.assistant?.semaphore(peripheral.keyName).mutex.signal()
            }
            if let err = error {
                self?.assistant?.discoverDescriptorsResult = .failure(err)
                return
            }
            let list: [Descriptor] = characteristic.descriptors?.map({ Descriptor(proxy: $0) }) ?? []
            self?.assistant?.discoverDescriptorsResult = .success(list)
        }
    }
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        assistant?.processor(peripheral.keyName).resultQueue.addOperation { [weak self] in
            if self?.assistant?.didInitiateSubscribeCharacteristic == true {
                if let err = error {
                    self?.assistant?.subscribeCharacteristicResult = .failure(err)
                } else {
                    self?.assistant?.subscribeCharacteristicResult = .success(Characteristic(proxy: characteristic))
                }
                self?.assistant?.semaphore(peripheral.keyName).mutex.signal()
            }
            if self?.assistant?.didInitiateReadCharacteristic == true {
                if let err = error {
                    self?.assistant?.readCharacteristicResult = .failure(err)
                } else {
                    self?.assistant?.readCharacteristicResult = .success(Characteristic(proxy: characteristic))
                }
                self?.assistant?.semaphore(peripheral.keyName).mutex.signal()
            }
        }
    }
    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        assistant?.processor(peripheral.keyName).resultQueue.addOperation { [weak self] in
            if self?.assistant?.didInitiateWriteCharacteristic == false {
                return
            }
            defer {
                self?.assistant?.semaphore(peripheral.keyName).mutex.signal()
            }
            if let err = error {
                self?.assistant?.writeCharacteristicResult = .failure(err)
                return
            }
            self?.assistant?.writeCharacteristicResult = .success(Characteristic(proxy: characteristic))
        }
    }
    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor descriptor: CBDescriptor,
        error: Error?
    ) {
        assistant?.processor(peripheral.keyName).resultQueue.addOperation { [weak self] in
            if self?.assistant?.didInitiateWriteDescriptor == false {
                return
            }
            defer {
                self?.assistant?.semaphore(peripheral.keyName).mutex.signal()
            }
            if let err = error {
                self?.assistant?.writeDescriptorResult = .failure(err)
                return
            }
            self?.assistant?.writeDescriptorResult = .success(Descriptor(proxy: descriptor))
        }
    }
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        assistant?.processor(peripheral.keyName).resultQueue.addOperation { [weak self] in
            if self?.assistant?.didInitiateUpdateNotifyStatus == false {
                return
            }
            defer {
                self?.assistant?.semaphore(peripheral.keyName).mutex.signal()
            }
            if let err = error {
                self?.assistant?.updateNotifyStatusResult = .failure(err)
                return
            }
            self?.assistant?.updateNotifyStatusResult = .success(Characteristic(proxy: characteristic))
        }
    }
}
