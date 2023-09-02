import Foundation

public enum TealtoothNotification: String {
    case onCentralStateUpdated
    case onDiscoveredPeripheral
    case onDisconnectedUnexpectedly
    case onScanTimedOut
    public var name: Notification.Name {
        return Notification.Name(rawValue: "TealtoothNotification.\(self.rawValue)")
    }
}

func postNotification(
    name: Notification.Name,
    object: Any? = nil,
    userInfo: [String: Any]?  = nil
) {
    DispatchQueue.main.async {
        NotificationCenter.default.post(
            name: name,
            object: object,
            userInfo: userInfo
        )
    }
}
