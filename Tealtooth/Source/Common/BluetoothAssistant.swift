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
    public func scan() -> Swift.Error? {
        return nil
    }
    @discardableResult
    public func stopScan() -> Swift.Error? {
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
