import CoreBluetooth

class CentralManagerDelegate: NSObject, CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        postNotification(
            name: TealtoothNotification.onCentralStateUpdated.name,
            object: central.state
        )
    }
}
