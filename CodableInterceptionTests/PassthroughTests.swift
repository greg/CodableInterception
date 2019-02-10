//
//  PassthroughTests.swift
//  PassthroughTests
//
//  Created by Greg Omelaenko on 9/2/19.
//  Copyright © 2019 Greg Omelaenko. All rights reserved.
//

import XCTest
@testable import CodableInterception

class PassthroughTests: XCTestCase {
    
    struct A: Equatable, Codable {
        var x: [Int]
        var y: Float
    }
    
    struct B: Equatable, Codable {
        var a: [A]
    }
    
    let sample = [
        B(a: [A(x: [], y: 2), A(x: [2, 8, 7], y: -1.5), A(x: [2], y: 0)]),
        B(a: [])
    ]

    /// A basic test to make sure the wrappers don't ruin anything
    func testPassthrough() {
        
        final class NonCustomiser: CodingCustomiser {
            
            init(for mode: CodingMode) {}
            
        }
        
        typealias UselessInterceptor<V> = CodableInterceptor<V, NonCustomiser>
        
        let json = try! JSONEncoder().encode(UselessInterceptor(sample))
        let decoded = try! JSONDecoder().decode(UselessInterceptor<[B]>.self, from: json).decodedValue
        
        XCTAssert(decoded == sample)
    }
    
    /// Logs encoding and decoding order and compares to what's expected
    func testLoggingPassthrough() {
        
        final class LoggingCustomiser: CodingCustomiser {
            
            let mode: CodingMode
            var log: String
            
            init(for mode: CodingMode) {
                self.mode = mode
                log = "\(mode)\n"
            }
            
            func encodeRoot<T>(_ value: T, to encoder: InterceptedEncoder) throws where T : Encodable {
                print("+ coding root", T.self, to: &log)
                var container = encoder.singleValueContainer()
                try container.encode(value)
                print("- coded root", T.self, to: &log)
            }
            
            func encode<T>(_ value: T, to encoder: InterceptedEncoder) throws where T : Encodable {
                print("+ coding", T.self, to: &log)
                try value.encode(to: encoder)
                print("- coded", T.self, to: &log)
            }
            
            func decodeRoot<T>(_ type: T.Type, from decoder: InterceptedDecoder) throws -> T where T : Decodable {
                print("+ coding root", type, to: &log)
                let container = try decoder.singleValueContainer()
                let r = try container.decode(type)
                print("- coded root", type, to: &log)
                return r
            }
            
            func decode<T>(_ type: T.Type, from decoder: InterceptedDecoder) throws -> T where T : Decodable {
                print("+ coding", type, to: &log)
                let r = try type.init(from: decoder)
                print("- coded", type, to: &log)
                return r
            }
            
            deinit {
                // the original version of this test used a dictionary, and it kept failing because a dictionary encodes in a non-deterministic order
                // the Ints in the array are encoded because array actually calls `encode<T>`, not `encode(Int)` because it's generic.
                XCTAssert(log == """
                    \(mode)
                    + coding root Array<B>
                    + coding Array<B>
                    + coding B
                    + coding Array<A>
                    + coding A
                    + coding Array<Int>
                    - coded Array<Int>
                    - coded A
                    + coding A
                    + coding Array<Int>
                    + coding Int
                    - coded Int
                    + coding Int
                    - coded Int
                    + coding Int
                    - coded Int
                    - coded Array<Int>
                    - coded A
                    + coding A
                    + coding Array<Int>
                    + coding Int
                    - coded Int
                    - coded Array<Int>
                    - coded A
                    - coded Array<A>
                    - coded B
                    + coding B
                    + coding Array<A>
                    - coded Array<A>
                    - coded B
                    - coded Array<B>
                    - coded root Array<B>
                    
                    """, "incorrect log: \(log)")
            }
        }
        
        typealias Interceptor<V> = CodableInterceptor<V, LoggingCustomiser>
        
        let json = try! JSONEncoder().encode(Interceptor(sample))
        let decoded = try! JSONDecoder().decode(Interceptor<[B]>.self, from: json).decodedValue
        
        XCTAssert(decoded == sample)
    }
    
    /// Tests different combinations of single value containers used or not
    func testDifferentContainerUsage() {
        
        final class ContainerCustomiser<WrapRoot, WrapOthers>: CodingCustomiser {
            
            init(for mode: CodingMode) {}
            
            func encodeRoot<T>(_ value: T, to encoder: InterceptedEncoder) throws where T : Encodable {
                if WrapRoot.self is Never.Type {
                    try value.encode(to: encoder)
                }
                else {
                    var container = encoder.singleValueContainer()
                    try container.encode(value)
                }
            }
            
            func encode<T>(_ value: T, to encoder: InterceptedEncoder) throws where T : Encodable {
                if WrapOthers.self is Never.Type {
                    try value.encode(to: encoder)
                }
                else {
                    var container = encoder.uninterceptedSingleValueContainer()
                    try container.encode(value)
                }
            }
            
            func decodeRoot<T>(_ type: T.Type, from decoder: InterceptedDecoder) throws -> T where T : Decodable {
                if WrapRoot.self is Never.Type {
                    return try type.init(from: decoder)
                }
                else {
                    let container = try decoder.singleValueContainer()
                    return try container.decode(type)
                }
            }
            
            func decode<T>(_ type: T.Type, from decoder: InterceptedDecoder) throws -> T where T : Decodable {
                if WrapOthers.self is Never.Type {
                    return try type.init(from: decoder)
                }
                else {
                    let container = try decoder.uninterceptedSingleValueContainer()
                    return try container.decode(type)
                }
            }
        }
        
        typealias Interceptor<V, R, O> = CodableInterceptor<V, ContainerCustomiser<R, O>>
        
        // default behaviour: single-value container for root, direct encoding for other values
        let json1 = try! JSONEncoder().encode(Interceptor<[B], (), Never>(sample))
        let decoded1 = try! JSONDecoder().decode(Interceptor<[B], (), Never>.self, from: json1).decodedValue
        XCTAssert(decoded1 == sample)
        
        // single-value container for both
        let json2 = try! JSONEncoder().encode(Interceptor<[B], (), ()>(sample))
        let decoded2 = try! JSONDecoder().decode(Interceptor<[B], (), ()>.self, from: json2).decodedValue
        XCTAssert(decoded2 == sample)
        
        // direct encoding for both
        let json3 = try! JSONEncoder().encode(Interceptor<[B], Never, Never>(sample))
        let decoded3 = try! JSONDecoder().decode(Interceptor<[B], Never, Never>.self, from: json3).decodedValue
        XCTAssert(decoded3 == sample)
        
        // opposite to default: direct for root, container for others
        let json4 = try! JSONEncoder().encode(Interceptor<[B], Never, ()>(sample))
        let decoded4 = try! JSONDecoder().decode(Interceptor<[B], Never, ()>.self, from: json4).decodedValue
        XCTAssert(decoded4 == sample)
    }

}
