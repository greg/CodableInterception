//
//  WrapperProtocols.swift
//  CodableInterception
//
//  Created by Greg Omelaenko on 9/2/19.
//  Copyright © 2019 Greg Omelaenko. All rights reserved.
//

/// A type which wraps the `Encodable` value that is actually to be encoded, in order to customise the process.
/// The purpose of this protocol is to expose the underlying type of the wrapped value.
public protocol EncodableWrapperProtocol: Encodable {
    
    /// The type of the underlying value wrapped by this object.
    ///
    /// Note that this type may have been obtained using `type(of:)`,
    /// and so might be more specific than the declared type of the value wherever it is used.
    var underlyingValueType: Encodable.Type { get }
    
}

/// A type which wraps the `Decodable` value that is to be decoded, in order to customise the process.
/// The purpose of this protocol is to expose the underlying type to be decoded.
public protocol DecodableWrapperProtocol: Decodable {
    
    /// The type of the underlying value to be decoded.
    var underlyingValueType: Decodable.Type { get }
    
}

/// A type which wraps an `Encoder` which is doing the actual encoding work, in order to customise the process.
/// The purpose of this protocol is to expose the underlying type of the wrapped encoder.
///
/// Note that when using e.g. `JSONEncoder` to encode a value,
/// the type of the `encoder` passed to `encode(to:)` will not actually be `JSONEncoder` or a subtype of it.
/// The only reason to use this protocol is when implementing your own encoder, and exposing types to the user
/// which need to have special knowledge of your encoder.
public protocol EncoderWrapperProtocol: Encoder {
    
    /// The type of the underlying encoder wrapped by this object.
    var underlyingEncoderType: Encoder.Type { get }
    
}

/// A type which wraps a `Decoder` which is doing the actual decoding work, in order to customise the process.
/// The purpose of this protocol is to expose the underlying type of the wrapped decoder.
///
/// Note that when using e.g. `JSONDecoder` to decode a value,
/// the type of the `decoder` passed to `init(from:)` will not actually be `JSONDecoder` or a subtype of it.
/// The only reason to use this protocol is when implementing your own decoder, and exposing types to the user
/// which need to have special knowledge of your decoder.
public protocol DecoderWrapperProtocol: Decoder {
    
    /// The type of the underlying decoder wrapped by this object.
    var underlyingDecoderType: Decoder.Type { get }
    
}
