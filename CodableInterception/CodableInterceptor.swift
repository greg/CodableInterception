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
    
    func uniqueWrapper<V: Encodable>(for value: V, customiseEncode: Bool) -> EncodableWrapper<Customiser> {
        if type(of: value) is AnyClass {
            let id = ObjectIdentifier(value as AnyObject)
            // we've seen this object before, we should use the same wrapper so any === identity checks are consistent
            if let wrapper = identityStore[id] {
                wrapper.customiseEncode = customiseEncode
                return wrapper
            }
            else {
                let wrapper = EncodableWrapper(value, encodingInfo: self, customiseEncode: customiseEncode)
                identityStore[id] = wrapper
                return wrapper
            }
        }
        else {
            return EncodableWrapper(value, encodingInfo: self, customiseEncode: customiseEncode)
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
    private let encodeValue: (InterceptedEncoder, _ customise: Bool) throws -> Void
    let underlyingValueType: Encodable.Type
    let underlyingObjectIdentifier: ObjectIdentifier?
    /// The single strong reference to `encodingInfo` is held by the root CodableInterceptor.
    private unowned let encodingInfo: EncodingInfo<Customiser>
    fileprivate var customiseEncode: Bool
    
    fileprivate init<V: Encodable>(_ value: V, encodingInfo: EncodingInfo<Customiser>, customiseEncode: Bool) {
        self.encodeValue = { [unowned encodingInfo] (wrappedEncoder, customise) in
            if customise {
                try encodingInfo.customiser.encode(value, to: wrappedEncoder)
            }
            else {
                try value.encode(to: wrappedEncoder)
            }
        }
        self.underlyingValueType = type(of: value)
        self.underlyingObjectIdentifier = V.self is AnyClass ? ObjectIdentifier(value as AnyObject) : nil
        self.encodingInfo = encodingInfo
        self.customiseEncode = customiseEncode
    }
    
    func encode(to encoder: Encoder) throws {
        let wrappedEncoder = EncoderWrapper(wrapping: encoder, encodingInfo: encodingInfo)
        try encodeValue(wrappedEncoder, customiseEncode)
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

final class DecodableWrapper<Value: Decodable, Customiser: CodingCustomiser>: Decodable, DecodableWrapperProtocol {
    
    let underlyingValueType: Decodable.Type = Value.self
    
    let decodedValue: Value
    
    init(from decoder: Decoder) throws {
        let (decodingInfo, customise) = popDecodingInfo(for: type(of: self)) as (DecodingInfo<Customiser>, Bool)
        let wrappedDecoder = DecoderWrapper(wrapping: decoder, decodingInfo: decodingInfo)
        if customise {
            self.decodedValue = try decodingInfo.customiser.decode(Value.self, from: wrappedDecoder)
        }
        else {
            self.decodedValue = try Value(from: wrappedDecoder)
        }
    }
    
}
