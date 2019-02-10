//
//  EncoderWrapper.swift
//  CodableInterception
//
//  Created by Greg Omelaenko on 9/2/19.
//  Copyright © 2019 Greg Omelaenko. All rights reserved.
//

struct EncoderWrapper<Customiser: CodingCustomiser>: Encoder, EncoderWrapperProtocol, InterceptedEncoder {
    
    private let actualEncoder: Encoder
    let encodingInfo: EncodingInfo<Customiser>
    
    var underlyingEncoderType: Encoder.Type {
        return type(of: actualEncoder)
    }
    
    init(wrapping encoder: Encoder, encodingInfo: EncodingInfo<Customiser>) {
        self.actualEncoder = encoder
        self.encodingInfo = encodingInfo
    }
    
    var codingPath: [CodingKey] {
        return actualEncoder.codingPath
    }
    
    var userInfo: [CodingUserInfoKey : Any] {
        return actualEncoder.userInfo
    }
    
    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = actualEncoder.container(keyedBy: type)
        let wrapped = KeyedContainerWrapper(wrapping: container, encodingInfo: encodingInfo, interceptEncodes: true)
        return KeyedEncodingContainer(wrapped)
    }
    
    func uninterceptedContainer<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let container = actualEncoder.container(keyedBy: type)
        let wrapped = KeyedContainerWrapper(wrapping: container, encodingInfo: encodingInfo, interceptEncodes: false)
        return KeyedEncodingContainer(wrapped)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedContainerWrapper(wrapping: actualEncoder.unkeyedContainer(), encodingInfo: encodingInfo, interceptEncodes: true)
    }
    
    func uninterceptedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedContainerWrapper(wrapping: actualEncoder.unkeyedContainer(), encodingInfo: encodingInfo, interceptEncodes: false)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return SingleValueContainerWrapper(wrapping: actualEncoder.singleValueContainer(), encodingInfo: encodingInfo, interceptEncodes: true)
    }
    
    func uninterceptedSingleValueContainer() -> SingleValueEncodingContainer {
        return SingleValueContainerWrapper(wrapping: actualEncoder.singleValueContainer(), encodingInfo: encodingInfo, interceptEncodes: false)
    }
    
}

fileprivate struct KeyedContainerWrapper<Key: CodingKey, Customiser: CodingCustomiser>: KeyedEncodingContainerProtocol {
    
    private var actualContainer: KeyedEncodingContainer<Key>
    let encodingInfo: EncodingInfo<Customiser>
    let interceptEncodes: Bool
    
    init(wrapping container: KeyedEncodingContainer<Key>, encodingInfo: EncodingInfo<Customiser>, interceptEncodes: Bool) {
        self.actualContainer = container
        self.encodingInfo = encodingInfo
        self.interceptEncodes = interceptEncodes
    }
    
    var codingPath: [CodingKey] {
        return actualContainer.codingPath
    }
    
    mutating func encodeNil(forKey key: Key) throws {
        return try actualContainer.encodeNil(forKey: key)
    }
    
    mutating func encode(_ value: Bool,      forKey key: Key) throws { try actualContainer.encode(value, forKey: key) }
    mutating func encode(_ value: String,    forKey key: Key) throws { try actualContainer.encode(value, forKey: key) }
    mutating func encode(_ value: Double,    forKey key: Key) throws { try actualContainer.encode(value, forKey: key) }
    mutating func encode(_ value: Float,     forKey key: Key) throws { try actualContainer.encode(value, forKey: key) }
    mutating func encode(_ value: Int,       forKey key: Key) throws { try actualContainer.encode(value, forKey: key) }
    mutating func encode(_ value: Int8,      forKey key: Key) throws { try actualContainer.encode(value, forKey: key) }
    mutating func encode(_ value: Int16,     forKey key: Key) throws { try actualContainer.encode(value, forKey: key) }
    mutating func encode(_ value: Int32,     forKey key: Key) throws { try actualContainer.encode(value, forKey: key) }
    mutating func encode(_ value: Int64,     forKey key: Key) throws { try actualContainer.encode(value, forKey: key) }
    mutating func encode(_ value: UInt,      forKey key: Key) throws { try actualContainer.encode(value, forKey: key) }
    mutating func encode(_ value: UInt8,     forKey key: Key) throws { try actualContainer.encode(value, forKey: key) }
    mutating func encode(_ value: UInt16,    forKey key: Key) throws { try actualContainer.encode(value, forKey: key) }
    mutating func encode(_ value: UInt32,    forKey key: Key) throws { try actualContainer.encode(value, forKey: key) }
    mutating func encode(_ value: UInt64,    forKey key: Key) throws { try actualContainer.encode(value, forKey: key) }
    
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        try actualContainer.encode(encodingInfo.uniqueWrapper(for: value, customiseEncode: interceptEncodes), forKey: key)
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let nested = actualContainer.nestedContainer(keyedBy: keyType, forKey: key)
        let wrapped = KeyedContainerWrapper<NestedKey, Customiser>(wrapping: nested, encodingInfo: encodingInfo, interceptEncodes: interceptEncodes)
        return KeyedEncodingContainer(wrapped)
    }
    
    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        return UnkeyedContainerWrapper(wrapping: actualContainer.nestedUnkeyedContainer(forKey: key), encodingInfo: encodingInfo, interceptEncodes: interceptEncodes)
    }
    
    mutating func superEncoder() -> Encoder {
        return EncoderWrapper(wrapping: actualContainer.superEncoder(), encodingInfo: encodingInfo)
    }
    
    mutating func superEncoder(forKey key: Key) -> Encoder {
        return EncoderWrapper(wrapping: actualContainer.superEncoder(forKey: key), encodingInfo: encodingInfo)
    }
    
}

fileprivate struct UnkeyedContainerWrapper<Customiser: CodingCustomiser>: UnkeyedEncodingContainer {
    
    
    private var actualContainer: UnkeyedEncodingContainer
    let encodingInfo: EncodingInfo<Customiser>
    let interceptEncodes: Bool
    
    init(wrapping container: UnkeyedEncodingContainer, encodingInfo: EncodingInfo<Customiser>, interceptEncodes: Bool) {
        self.actualContainer = container
        self.encodingInfo = encodingInfo
        self.interceptEncodes = interceptEncodes
    }
    
    var codingPath: [CodingKey] {
        return actualContainer.codingPath
    }
    
    var count: Int {
        return actualContainer.count
    }
    
    mutating func encodeNil() throws {
        try actualContainer.encodeNil()
    }
    
    mutating func encode(_ value: Bool)     throws { try actualContainer.encode(value) }
    mutating func encode(_ value: String)   throws { try actualContainer.encode(value) }
    mutating func encode(_ value: Double)   throws { try actualContainer.encode(value) }
    mutating func encode(_ value: Float)    throws { try actualContainer.encode(value) }
    mutating func encode(_ value: Int)      throws { try actualContainer.encode(value) }
    mutating func encode(_ value: Int8)     throws { try actualContainer.encode(value) }
    mutating func encode(_ value: Int16)    throws { try actualContainer.encode(value) }
    mutating func encode(_ value: Int32)    throws { try actualContainer.encode(value) }
    mutating func encode(_ value: Int64)    throws { try actualContainer.encode(value) }
    mutating func encode(_ value: UInt)     throws { try actualContainer.encode(value) }
    mutating func encode(_ value: UInt8)    throws { try actualContainer.encode(value) }
    mutating func encode(_ value: UInt16)   throws { try actualContainer.encode(value) }
    mutating func encode(_ value: UInt32)   throws { try actualContainer.encode(value) }
    mutating func encode(_ value: UInt64)   throws { try actualContainer.encode(value) }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        try actualContainer.encode(encodingInfo.uniqueWrapper(for: value, customiseEncode: interceptEncodes))
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let nested = actualContainer.nestedContainer(keyedBy: keyType)
        let wrapped = KeyedContainerWrapper(wrapping: nested, encodingInfo: encodingInfo, interceptEncodes: interceptEncodes)
        return KeyedEncodingContainer(wrapped)
    }
    
    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedContainerWrapper(wrapping: actualContainer.nestedUnkeyedContainer(), encodingInfo: encodingInfo, interceptEncodes: interceptEncodes)
    }
    
    mutating func superEncoder() -> Encoder {
        return EncoderWrapper(wrapping: actualContainer.superEncoder(), encodingInfo: encodingInfo)
    }
    
}

fileprivate struct SingleValueContainerWrapper<Customiser: CodingCustomiser>: SingleValueEncodingContainer {
    
    private var actualContainer: SingleValueEncodingContainer
    let encodingInfo: EncodingInfo<Customiser>
    let interceptEncodes: Bool
    
    init(wrapping container: SingleValueEncodingContainer, encodingInfo: EncodingInfo<Customiser>, interceptEncodes: Bool) {
        self.actualContainer = container
        self.encodingInfo = encodingInfo
        self.interceptEncodes = interceptEncodes
    }
    
    var codingPath: [CodingKey] {
        return actualContainer.codingPath
    }
    
    mutating func encodeNil() throws {
        try actualContainer.encodeNil()
    }
    
    mutating func encode(_ value: Bool)     throws { try actualContainer.encode(value) }
    mutating func encode(_ value: String)   throws { try actualContainer.encode(value) }
    mutating func encode(_ value: Double)   throws { try actualContainer.encode(value) }
    mutating func encode(_ value: Float)    throws { try actualContainer.encode(value) }
    mutating func encode(_ value: Int)      throws { try actualContainer.encode(value) }
    mutating func encode(_ value: Int8)     throws { try actualContainer.encode(value) }
    mutating func encode(_ value: Int16)    throws { try actualContainer.encode(value) }
    mutating func encode(_ value: Int32)    throws { try actualContainer.encode(value) }
    mutating func encode(_ value: Int64)    throws { try actualContainer.encode(value) }
    mutating func encode(_ value: UInt)     throws { try actualContainer.encode(value) }
    mutating func encode(_ value: UInt8)    throws { try actualContainer.encode(value) }
    mutating func encode(_ value: UInt16)   throws { try actualContainer.encode(value) }
    mutating func encode(_ value: UInt32)   throws { try actualContainer.encode(value) }
    mutating func encode(_ value: UInt64)   throws { try actualContainer.encode(value) }
    
    mutating func encode<T>(_ value: T) throws where T : Encodable {
        try actualContainer.encode(encodingInfo.uniqueWrapper(for: value, customiseEncode: interceptEncodes))
    }
    
}
