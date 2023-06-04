import CoreBluetooth

class CentralManagerDelegate: NSObject, CBCentralManagerDelegate {
    weak var bluetoothAssistant: BluetoothAssistant?
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        postNotification(
            name: TealtoothNotification.onCentralStateUpdated.name,
            object: central.state
        )
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        postNotification(
            name: TealtoothNotification.onDiscoveredPeripheral.name,
            object: Advertiser(
                peripheral: Peripheral(proxy: peripheral),
                info: advertisementData,
                rssi: RSSI.intValue
            )
        )
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        bluetoothAssistant?.connectResult = .success(Peripheral(proxy: peripheral))
        bluetoothAssistant?.semaphore.signal()
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        bluetoothAssistant?.connectResult = .failure(error ?? TealtoothError.errorNotDetermined)
        bluetoothAssistant?.semaphore.signal()
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if bluetoothAssistant?.didInitiateDisconnect == false {
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
            bluetoothAssistant?.disconnectResult = .failure(err)
            bluetoothAssistant?.semaphore.signal()
        }
        bluetoothAssistant?.disconnectResult = .success(Peripheral(proxy: peripheral))
        bluetoothAssistant?.semaphore.signal()
    }
}
