import Foundation

extension Result {
    public var error: Swift.Error? {
        switch self {
        case let .failure(error):
            return error
        case .success:
            return nil
        }
    }
    public var info: Success? {
        switch self {
        case .failure:
            return nil
        case let .success(info):
            return info
        }
    }
}
