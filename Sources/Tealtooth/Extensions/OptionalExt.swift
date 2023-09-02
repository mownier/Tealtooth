import Foundation

extension Optional<[String : Any]> {
    var debugString: String {
        return self == nil ? "nil" : String(describing: self)
    }
}
