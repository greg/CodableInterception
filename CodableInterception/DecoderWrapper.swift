//
//  DecoderWrapper.swift
//  CodableInterception
//
//  Created by Greg Omelaenko on 9/2/19.
//  Copyright © 2019 Greg Omelaenko. All rights reserved.
//

struct DecoderWrapper<Customiser: CodingCustomiser>: Decoder, DecoderWrapperProtocol {
    
    private let actualDecoder: Decoder
    let decodingInfo: DecodingInfo<Customiser>
    
    var underlyingDecoderType: Decoder.Type {
        return type(of: actualDecoder)
    }
    
    init(wrapping decoder: Decoder, decodingInfo: DecodingInfo<Customiser>) {
        self.actualDecoder = decoder
        self.decodingInfo = decodingInfo
    }
    
    var codingPath: [CodingKey] {
        return actualDecoder.codingPath
    }
    
    var userInfo: [CodingUserInfoKey : Any] {
        return actualDecoder.userInfo
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        let container = try actualDecoder.container(keyedBy: type)
        let wrapped = KeyedContainerWrapper(wrapping: container, decodingInfo: decodingInfo)
        return KeyedDecodingContainer(wrapped)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return UnkeyedContainerWrapper(wrapping: try actualDecoder.unkeyedContainer(), decodingInfo: decodingInfo)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return SingleValueContainerWrapper(wrapping: try actualDecoder.singleValueContainer(), decodingInfo: decodingInfo)
    }
    
}

fileprivate struct KeyedContainerWrapper<Key: CodingKey, Customiser: CodingCustomiser>: KeyedDecodingContainerProtocol {
    
    private let actualContainer: KeyedDecodingContainer<Key>
    let decodingInfo: DecodingInfo<Customiser>
    
    init(wrapping container: KeyedDecodingContainer<Key>, decodingInfo: DecodingInfo<Customiser>) {
        self.actualContainer = container
        self.decodingInfo = decodingInfo
    }
    
    var codingPath: [CodingKey] {
        return actualContainer.codingPath
    }
    
    var allKeys: [Key] {
        return actualContainer.allKeys
    }
    
    func contains(_ key: Key) -> Bool {
        return actualContainer.contains(key)
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        return try actualContainer.decodeNil(forKey: key)
    }
    
    func decode(_ type: Bool.Type,      forKey key: Key) throws -> Bool     { return try actualContainer.decode(type, forKey: key) }
    func decode(_ type: String.Type,    forKey key: Key) throws -> String   { return try actualContainer.decode(type, forKey: key) }
    func decode(_ type: Double.Type,    forKey key: Key) throws -> Double   { return try actualContainer.decode(type, forKey: key) }
    func decode(_ type: Float.Type,     forKey key: Key) throws -> Float    { return try actualContainer.decode(type, forKey: key) }
    func decode(_ type: Int.Type,       forKey key: Key) throws -> Int      { return try actualContainer.decode(type, forKey: key) }
    func decode(_ type: Int8.Type,      forKey key: Key) throws -> Int8     { return try actualContainer.decode(type, forKey: key) }
    func decode(_ type: Int16.Type,     forKey key: Key) throws -> Int16    { return try actualContainer.decode(type, forKey: key) }
    func decode(_ type: Int32.Type,     forKey key: Key) throws -> Int32    { return try actualContainer.decode(type, forKey: key) }
    func decode(_ type: Int64.Type,     forKey key: Key) throws -> Int64    { return try actualContainer.decode(type, forKey: key) }
    func decode(_ type: UInt.Type,      forKey key: Key) throws -> UInt     { return try actualContainer.decode(type, forKey: key) }
    func decode(_ type: UInt8.Type,     forKey key: Key) throws -> UInt8    { return try actualContainer.decode(type, forKey: key) }
    func decode(_ type: UInt16.Type,    forKey key: Key) throws -> UInt16   { return try actualContainer.decode(type, forKey: key) }
    func decode(_ type: UInt32.Type,    forKey key: Key) throws -> UInt32   { return try actualContainer.decode(type, forKey: key) }
    func decode(_ type: UInt64.Type,    forKey key: Key) throws -> UInt64   { return try actualContainer.decode(type, forKey: key) }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        pushDecodingInfo(decodingInfo, for: DecodableWrapper<T, Customiser>.self)
        return try actualContainer.decode(DecodableWrapper<T, Customiser>.self, forKey: key).decodedValue
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let nested = try actualContainer.nestedContainer(keyedBy: type, forKey: key)
        let wrapped = KeyedContainerWrapper<NestedKey, Customiser>(wrapping: nested, decodingInfo: decodingInfo)
        return KeyedDecodingContainer(wrapped)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        return UnkeyedContainerWrapper(wrapping: try actualContainer.nestedUnkeyedContainer(forKey: key), decodingInfo: decodingInfo)
    }
    
    func superDecoder() throws -> Decoder {
        return DecoderWrapper(wrapping: try actualContainer.superDecoder(), decodingInfo: decodingInfo)
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        return DecoderWrapper(wrapping: try actualContainer.superDecoder(forKey: key), decodingInfo: decodingInfo)
    }
    
}

fileprivate struct UnkeyedContainerWrapper<Customiser: CodingCustomiser>: UnkeyedDecodingContainer {
    
    private var actualContainer: UnkeyedDecodingContainer
    let decodingInfo: DecodingInfo<Customiser>
    
    init(wrapping container: UnkeyedDecodingContainer, decodingInfo: DecodingInfo<Customiser>) {
        self.actualContainer = container
        self.decodingInfo = decodingInfo
    }
    
    var codingPath: [CodingKey] {
        return actualContainer.codingPath
    }
    
    var count: Int? {
        return actualContainer.count
    }
    
    var isAtEnd: Bool {
        return actualContainer.isAtEnd
    }
    
    var currentIndex: Int {
        return actualContainer.currentIndex
    }
    
    mutating func decodeNil() throws -> Bool {
        return try actualContainer.decodeNil()
    }
    
    mutating func decode(_ type: Bool.Type)     throws -> Bool     { return try actualContainer.decode(type) }
    mutating func decode(_ type: String.Type)   throws -> String   { return try actualContainer.decode(type) }
    mutating func decode(_ type: Double.Type)   throws -> Double   { return try actualContainer.decode(type) }
    mutating func decode(_ type: Float.Type)    throws -> Float    { return try actualContainer.decode(type) }
    mutating func decode(_ type: Int.Type)      throws -> Int      { return try actualContainer.decode(type) }
    mutating func decode(_ type: Int8.Type)     throws -> Int8     { return try actualContainer.decode(type) }
    mutating func decode(_ type: Int16.Type)    throws -> Int16    { return try actualContainer.decode(type) }
    mutating func decode(_ type: Int32.Type)    throws -> Int32    { return try actualContainer.decode(type) }
    mutating func decode(_ type: Int64.Type)    throws -> Int64    { return try actualContainer.decode(type) }
    mutating func decode(_ type: UInt.Type)     throws -> UInt     { return try actualContainer.decode(type) }
    mutating func decode(_ type: UInt8.Type)    throws -> UInt8    { return try actualContainer.decode(type) }
    mutating func decode(_ type: UInt16.Type)   throws -> UInt16   { return try actualContainer.decode(type) }
    mutating func decode(_ type: UInt32.Type)   throws -> UInt32   { return try actualContainer.decode(type) }
    mutating func decode(_ type: UInt64.Type)   throws -> UInt64   { return try actualContainer.decode(type) }
    
    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        pushDecodingInfo(decodingInfo, for: DecodableWrapper<T, Customiser>.self)
        return try actualContainer.decode(DecodableWrapper<T, Customiser>.self).decodedValue
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let nested = try actualContainer.nestedContainer(keyedBy: type)
        let wrapped = KeyedContainerWrapper(wrapping: nested, decodingInfo: decodingInfo)
        return KeyedDecodingContainer(wrapped)
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return UnkeyedContainerWrapper(wrapping: try actualContainer.nestedUnkeyedContainer(), decodingInfo: decodingInfo)
    }
    
    mutating func superDecoder() throws -> Decoder {
        return DecoderWrapper(wrapping: try actualContainer.superDecoder(), decodingInfo: decodingInfo)
    }
    
}

fileprivate struct SingleValueContainerWrapper<Customiser: CodingCustomiser>: SingleValueDecodingContainer {
    
    private let actualContainer: SingleValueDecodingContainer
    let decodingInfo: DecodingInfo<Customiser>
    
    init(wrapping container: SingleValueDecodingContainer, decodingInfo: DecodingInfo<Customiser>) {
        self.actualContainer = container
        self.decodingInfo = decodingInfo
    }
    
    var codingPath: [CodingKey] {
        return actualContainer.codingPath
    }
    
    func decodeNil() -> Bool {
        return actualContainer.decodeNil()
    }
    
    func decode(_ type: Bool.Type)     throws -> Bool     { return try actualContainer.decode(type) }
    func decode(_ type: String.Type)   throws -> String   { return try actualContainer.decode(type) }
    func decode(_ type: Double.Type)   throws -> Double   { return try actualContainer.decode(type) }
    func decode(_ type: Float.Type)    throws -> Float    { return try actualContainer.decode(type) }
    func decode(_ type: Int.Type)      throws -> Int      { return try actualContainer.decode(type) }
    func decode(_ type: Int8.Type)     throws -> Int8     { return try actualContainer.decode(type) }
    func decode(_ type: Int16.Type)    throws -> Int16    { return try actualContainer.decode(type) }
    func decode(_ type: Int32.Type)    throws -> Int32    { return try actualContainer.decode(type) }
    func decode(_ type: Int64.Type)    throws -> Int64    { return try actualContainer.decode(type) }
    func decode(_ type: UInt.Type)     throws -> UInt     { return try actualContainer.decode(type) }
    func decode(_ type: UInt8.Type)    throws -> UInt8    { return try actualContainer.decode(type) }
    func decode(_ type: UInt16.Type)   throws -> UInt16   { return try actualContainer.decode(type) }
    func decode(_ type: UInt32.Type)   throws -> UInt32   { return try actualContainer.decode(type) }
    func decode(_ type: UInt64.Type)   throws -> UInt64   { return try actualContainer.decode(type) }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        pushDecodingInfo(decodingInfo, for: DecodableWrapper<T, Customiser>.self)
        return try actualContainer.decode(DecodableWrapper<T, Customiser>.self).decodedValue
    }
    
}

