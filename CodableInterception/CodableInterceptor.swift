//
//  CodableInterceptor.swift
//  CodableInterception
//
//  Created by Greg Omelaenko on 9/2/19.
//  Copyright © 2019 Greg Omelaenko. All rights reserved.
//

public struct CodableInterceptor<Value, Customiser: CodingCustomiser> {
    
    fileprivate let value: Value
    
    /// Initialises with the value that is to be encoded as the root value.
    public init(_ value: Value) {
        self.value = value
    }
    
}

final class EncodingInfo<Customiser: CodingCustomiser> {
    
    fileprivate var customiser = Customiser(for: .encoding)
    
    private var identityStore: [ObjectIdentifier : EncodableWrapper<Customiser>] = [:]
    
    func uniqueWrapper<V: Encodable>(for value: V) -> EncodableWrapper<Customiser> {
        if type(of: value) is AnyClass {
            let id = ObjectIdentifier(value as AnyObject)
            // we've seen this object before, we should use the same wrapper so any === identity checks are consistent
            if let wrapper = identityStore[id] {
                return wrapper
            }
            else {
                let wrapper = EncodableWrapper(value, encodingInfo: self)
                identityStore[id] = wrapper
                return wrapper
            }
        }
        else {
            return EncodableWrapper(value, encodingInfo: self)
        }
    }
    
}

final class DecodingInfo<Customiser: CodingCustomiser> {
    
    fileprivate var customiser = Customiser(for: .decoding)
    
}

extension CodableInterceptor: Encodable where Value: Encodable {
    
    public func encode(to encoder: Encoder) throws {
        let encodingInfo = EncodingInfo<Customiser>()
        let wrappedEncoder = EncoderWrapper(wrapping: encoder, encodingInfo: encodingInfo)
        
        try encodingInfo.customiser.encodeRoot(value, to: wrappedEncoder)
    }
    
}

final class EncodableWrapper<Customiser: CodingCustomiser>: Encodable, EncodableWrapperProtocol {
    
    /// Stores a "canned" generic call to `value.encode(to:)` since we discard that type information after `init`.
    private let encodeValue: (Encoder) throws -> Void
    let underlyingValueType: Encodable.Type
    /// The single strong reference to `encodingInfo` is held by the root CodableInterceptor.
    private unowned let encodingInfo: EncodingInfo<Customiser>
    
    fileprivate init<V: Encodable>(_ value: V, encodingInfo: EncodingInfo<Customiser>) {
        self.encodeValue = { [unowned encodingInfo] encoder in
            try encodingInfo.customiser.encode(value, to: encoder)
        }
        self.underlyingValueType = type(of: value)
        self.encodingInfo = encodingInfo
    }
    
    func encode(to encoder: Encoder) throws {
        let wrappedEncoder = EncoderWrapper(wrapping: encoder, encodingInfo: encodingInfo)
        try encodeValue(wrappedEncoder)
    }
    
}

extension CodableInterceptor: Decodable where Value: Decodable {
    
    public var decodedValue: Value {
        return value
    }
    
    public init(from decoder: Decoder) throws {
        let decodingInfo = DecodingInfo<Customiser>()
        let wrappedDecoder = DecoderWrapper(wrapping: decoder, decodingInfo: decodingInfo)
        
        self.value = try decodingInfo.customiser.decodeRoot(Value.self, from: wrappedDecoder)
    }
    
}

final class DecodableWrapper<Value: Decodable, Customiser: CodingCustomiser>: Decodable {
    
    let decodedValue: Value
    
    init(from decoder: Decoder) throws {
        let decodingInfo = popDecodingInfo(for: type(of: self)) as DecodingInfo<Customiser>
        let wrappedDecoder = DecoderWrapper(wrapping: decoder, decodingInfo: decodingInfo)
        self.decodedValue = try decodingInfo.customiser.decode(Value.self, from: wrappedDecoder)
    }
    
}
