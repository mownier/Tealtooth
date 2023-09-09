import CoreBluetooth

class CentralManagerDelegate: NSObject, CBCentralManagerDelegate {
    weak var assistant: BluetoothAssistant?
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        postNotification(
            name: TealtoothNotification.onCentralStateUpdated.name,
            object: central.state
        )
    }
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        postNotification(
            name: TealtoothNotification.onDiscoveredPeripheral.name,
            object: Advertiser(
                peripheral: Peripheral(proxy: peripheral),
                info: advertisementData,
                rssi: RSSI.intValue
            )
        )
    }
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        assistant?.processor(peripheral.keyName).resultQueue.addOperation { [weak self] in
            if self?.assistant?.didInitiateConnect == false {
                return
            }
            self?.assistant?.connectResult = .success(Peripheral(proxy: peripheral))
            self?.assistant?.semaphore(peripheral.keyName).mutex.signal()
        }
    }
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        assistant?.processor(peripheral.keyName).resultQueue.addOperation { [weak self] in
            if self?.assistant?.didInitiateConnect == false {
                return
            }
            self?.assistant?.connectResult = .failure(error ?? TealtoothError.errorNotDetermined)
            self?.assistant?.semaphore(peripheral.keyName).mutex.signal()
        }
    }
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        assistant?.processor(peripheral.keyName).resultQueue.addOperation { [weak self] in
            if self?.assistant?.didInitiateDisconnect == false {
                postNotification(
                    name: TealtoothNotification.onDisconnectedUnexpectedly.name,
                    object: UnexpectedDisconnection(
                        peripheral: Peripheral(proxy: peripheral),
                        error: error
                    )
                )
                return
            }
            defer {
                self?.assistant?.semaphore(peripheral.keyName).mutex.signal()
            }
            if let err = error {
                self?.assistant?.disconnectResult = .failure(err)
                return
            }
            self?.assistant?.disconnectResult = .success(Peripheral(proxy: peripheral))
        }
    }
}
