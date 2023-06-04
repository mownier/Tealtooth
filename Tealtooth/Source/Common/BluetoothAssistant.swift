import CoreBluetooth

public class BluetoothAssistant {
    private var centralManager: CBCentralManager
    private var centralManagerDelegate: CentralManagerDelegate
    public init(
        queue: DispatchQueue? = nil,
        options: [String: Any]? = nil
    ) {
        let centralManagerDelegate = CentralManagerDelegate()
        self.centralManager = CBCentralManager(
            delegate: centralManagerDelegate,
            queue: queue,
            options: options
        )
        self.centralManagerDelegate = centralManagerDelegate
    }
    @discardableResult
    public func scan(services: [CBUUID]? = nil) -> Swift.Error? {
        if centralManager.state != .poweredOn {
            return TealtoothError.bluetoothNotPoweredOn
        }
        if centralManager.isScanning {
            return TealtoothError.alreadyScanning
        }
        centralManager.scanForPeripherals(withServices: services)
        return nil
    }
    @discardableResult
    public func stopScan() -> Swift.Error? {
        if centralManager.state != .poweredOn {
            return TealtoothError.bluetoothNotPoweredOn
        }
        if !centralManager.isScanning {
            return TealtoothError.scanningNotActive
        }
        centralManager.stopScan()
        return nil
    }
    @discardableResult
    public func connect(
        _ peripheral: Peripheral
    ) -> Result<Peripheral, Swift.Error> {
        return .failure(TealtoothError.unimplemented)
    }
    @discardableResult
    public func disconnect(
        _ peripheral: Peripheral
    ) -> Result<Peripheral, Swift.Error> {
        return .failure(TealtoothError.unimplemented)
    }
}
