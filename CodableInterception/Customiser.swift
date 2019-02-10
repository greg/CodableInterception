//
//  Customiser.swift
//  CodableInterception
//
//  Created by Greg Omelaenko on 9/2/19.
//  Copyright © 2019 Greg Omelaenko. All rights reserved.
//

public enum CodingMode {
    case encoding
    case decoding
}

/// An `Encoder` which intercepts encoding calls made to its containers in order to allow customisation.
///
/// Calling `Encoder`s regular functions like `singleValueContainer()` will return a container which
/// intercepts the call to `encode(to:)` on the object encoded to it, and calls `CodingCustomiser`'s `encode(_:to:)`,
/// which may lead to infinite recursion.
///
/// This protocol provides `unintercepted` versions of the container request functions,
/// which will encode values encoded to them without calling `CodingCustomiser`'s `encode(_:to:)`.
/// Subsequent nested encodes performed by those values will still be intercepted.
public protocol InterceptedEncoder: EncoderWrapperProtocol {
    
    /// Returns a keyed container which encodes values without calling `CodingCustomiser`'s `encode(_:to:)` in order to avoid infinite recursion.
    /// Subsequent nested encodes performed by those values will still be intercepted.
    func uninterceptedContainer<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key>
    
    /// Returns a single value container which encodes values without calling `CodingCustomiser`'s `encode(_:to:)` in order to avoid infinite recursion.
    /// Subsequent nested encodes performed by those values will still be intercepted.
    func uninterceptedSingleValueContainer() -> SingleValueEncodingContainer
    
    /// Returns an unkeyed container which encodes values without calling `CodingCustomiser`'s `encode(_:to:)` in order to avoid infinite recursion.
    /// Subsequent nested encodes performed by those values will still be intercepted.
    func uninterceptedUnkeyedContainer() -> UnkeyedEncodingContainer
    
}

/// A `Decoder` which intercepts decoding calls made to its containers in order to allow customisation.
///
/// Calling `Decoder`s regular functions like `singleValueContainer()` will return a container which
/// intercepts the call to `init(from:)` on the object decoded from it, and calls `CodingCustomiser`'s `decode(_:from:)`,
/// which may lead to infinite recursion.
///
/// This protocol provides `unintercepted` versions of the container request functions,
/// which will decode values encoded to them without calling `CodingCustomiser`'s `decode(_:from:)`.
/// Subsequent nested decodes performed by those values will still be intercepted.
public protocol InterceptedDecoder: DecoderWrapperProtocol {
    
    /// Returns a keyed container which decodes values without calling `CodingCustomiser`'s `decode(_:from:)` in order to avoid infinite recursion.
    /// Subsequent nested decodes performed by those values will still be intercepted.
    func uninterceptedContainer<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key>
    
    /// Returns a single value container which decodes values without calling `CodingCustomiser`'s `decode(_:from:)` in order to avoid infinite recursion.
    /// Subsequent nested decodes performed by those values will still be intercepted.
    func uninterceptedSingleValueContainer() throws -> SingleValueDecodingContainer
    
    /// Returns an unkeyed container which decodes values without calling `CodingCustomiser`'s `decode(_:from:)` in order to avoid infinite recursion.
    /// Subsequent nested decodes performed by those values will still be intercepted.
    func uninterceptedUnkeyedContainer() throws -> UnkeyedDecodingContainer
    
}

/// A type that can customise the way `Codable` values are encoded and decoded.
public protocol CodingCustomiser: AnyObject {
    
    /// Initialises the customiser for encoding or decoding, as specified.
    init(for mode: CodingMode)
    
    /// A customisation point for encoding the root value.
    ///
    /// The same caveats with regards to `T` and `encoder`'s types apply as for `encode(_:to:)`.
    ///
    /// This function will be called *once*, and _before_ `encode(_:to:)` is called.
    /// The default implementation requests a single value container and encodes `value` to it.
    /// This means that `encode(_:to:)` will also be called for the root value.
    ///
    /// When anything is encoded to `encoder`, calls to `encode(_:to:)` will be made to this object,
    /// before the encode call returns.
    ///
    /// One way this function could be used is to encode `value`, collect supplementary information
    /// via `encode(_:to:)`, and then encode this information.
    func encodeRoot<T: Encodable>(_ value: T, to encoder: InterceptedEncoder) throws
    
    /// A customisation point for an intercepted call to `value.encode(to: encoder)`.
    ///
    /// The type `T` of `value` will be the type of the value to which the encode call was intercepted.
    /// If multiple nested `CodableInterceptor`s are in use at once, **this may not actually be the real type of the value being encoded**.
    /// In such cases, if you rely on the type, check if `value` conforms to `EncodableWrapperProtocol`.
    ///
    /// The default implementation calls `value.encode(to: encoder)`.
    ///
    /// The type of `encoder` will **not** be the type of the actual underlying encoder used.
    func encode<T: Encodable>(_ value: T, to encoder: InterceptedEncoder) throws
    
    /// A customisation point for an intercepted call to decoding the root value.
    ///
    /// The same caveats with regards to `T` and `decoder`'s types apply as for `encode(_:to:)`.
    ///
    /// This function will be called *once*, and _before_ `decode(_:from:)` is called.
    /// The default implementation requests a single value container and decodes `type` from it.
    func decodeRoot<T: Decodable>(_ type: T.Type, from decoder: InterceptedDecoder) throws -> T
    
    /// A customisation point for an intercepted call to `T(from: decoder)`.
    ///
    /// The same caveats with regards to `T` and `decoder`'s types apply as for `encode(_:to:)`.
    ///
    /// The default implementation returns `type.init(from: decoder)`.
    func decode<T: Decodable>(_ type: T.Type, from decoder: InterceptedDecoder) throws -> T
    
}

/// For those of us who can't spell ;)
public typealias CodingCustomizer = CodingCustomiser

public extension CodingCustomiser {
    
    func encodeRoot<T: Encodable>(_ value: T, to encoder: InterceptedEncoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
    func encode<T: Encodable>(_ value: T, to encoder: InterceptedEncoder) throws {
        try value.encode(to: encoder)
    }
    
    func decodeRoot<T: Decodable>(_ type: T.Type, from decoder: InterceptedDecoder) throws -> T {
        let container = try decoder.singleValueContainer()
        return try container.decode(type)
    }
    
    func decode<T: Decodable>(_ type: T.Type, from decoder: InterceptedDecoder) throws -> T {
        return try type.init(from: decoder)
    }
    
}
