import Async

public protocol ServiceSupplement {
    /// The instance type of the service which is supplemented. Services
    /// may only be supplemented by actual type, not by implemented interface,
    /// for safety's sake.
    var supplementedServiceType: Any.Type { get }
    
    /// The tag, if any, of the service to supplement. Note that `nil` means
    /// "only supplement services of this type without a tag", NOT "supplement
    /// all tags for this service type"
    var supplementedServiceTag: String? { get }
    
    /// Perform the supplementation on the instance, in the
    /// given container.
    ///
    /// Because Swift existentials are not yet powerful enough,
    /// the instance must be declared `Any` here. It is an API
    /// guarantee that `instance as! supplementedServiceType`
    /// will always succeed.
    func supplementService(_ instance: inout Any, in container: Container) throws
}

public struct BasicServiceSupplement<S>: ServiceSupplement {
    /// Accepts an instance to modify and a Container within which
    /// to work.
    public typealias ServiceSupplementClosure = (inout S, Container) throws -> Void
    
    /// See ServiceSupplement.supplementedServiceType
    public var supplementedServiceType: Any.Type { return S.self }
    
    /// See ServiceSupplement.supplementedServiceTag
    public var supplementedServiceTag: String?
    
    /// Closure that applies the supplement.
    public let closure: ServiceSupplementClosure
    
    public init(tag: String? = nil, closure: @escaping ServiceSupplementClosure) {
        self.supplementedServiceTag = tag
        self.closure = closure
    }
    
    public func supplementService(_ instance: inout Any, in container: Container) throws {
        // FIXME: Is there any better way to force the downcast than copying twice?
        // Not a problem for reference types but ugly for value types.
        var downcastInstance = instance as! S
        
        try closure(&downcastInstance, container)
        instance = downcastInstance
    }
}

