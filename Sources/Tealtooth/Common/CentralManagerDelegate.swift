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
        if assistant?.didInitiateConnect == false {
            return
        }
        assistant?.connectResult = .success(Peripheral(proxy: peripheral))
        assistant?.semaphore(peripheral.keyName).mutex.signal()
    }
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        if assistant?.didInitiateConnect == false {
            return
        }
        assistant?.connectResult = .failure(error ?? TealtoothError.errorNotDetermined)
        assistant?.semaphore(peripheral.keyName).mutex.signal()
    }
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        if assistant?.didInitiateDisconnect == false {
            postNotification(
                name: TealtoothNotification.onDisconnectedUnexpectedly.name,
                object: UnexpectedDisconnection(
                    peripheral: Peripheral(proxy: peripheral),
                    error: error
                )
            )
            return
        }
        if let err = error {
            assistant?.disconnectResult = .failure(err)
            assistant?.semaphore(peripheral.keyName).mutex.signal()
            return
        }
        assistant?.disconnectResult = .success(Peripheral(proxy: peripheral))
        assistant?.semaphore(peripheral.keyName).mutex.signal()
    }
}
