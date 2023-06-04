import Foundation

public class UnexpectedDisconnection {
    public var peripheral: Peripheral
    public var error: Swift.Error?
    public init(peripheral: Peripheral, error: Swift.Error?) {
        self.peripheral = peripheral
        self.error = error
    }
}
