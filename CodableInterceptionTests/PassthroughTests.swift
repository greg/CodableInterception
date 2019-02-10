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

    func testPassthrough() {
        
        final class NonCustomiser: CodingCustomiser {
            
            init(for mode: CodingMode) {}
            
        }
        
        typealias UselessInterceptor<V> = CodableInterceptor<V, NonCustomiser>
        
        let json = try! JSONEncoder().encode(UselessInterceptor(sample))
        let decoded = try! JSONDecoder().decode(UselessInterceptor<[B]>.self, from: json).decodedValue
        
        XCTAssert(decoded == sample)
    }
    
    func testLoggingPassthrough() {
        
        final class LoggingCustomiser: CodingCustomiser {
            
            let mode: CodingMode
            var log: String
            
            init(for mode: CodingMode) {
                self.mode = mode
                log = "\(mode)\n"
            }
            
            func encodeRoot<T>(_ value: T, to encoder: Encoder) throws where T : Encodable {
                print("+ coding root", T.self, to: &log)
                var container = encoder.singleValueContainer()
                try container.encode(value)
                print("- coded root", T.self, to: &log)
            }
            
            func encode<T>(_ value: T, to encoder: Encoder) throws where T : Encodable {
                print("+ coding", T.self, to: &log)
                try value.encode(to: encoder)
                print("- coded", T.self, to: &log)
            }
            
            func decodeRoot<T>(_ type: T.Type, from decoder: Decoder) throws -> T where T : Decodable {
                print("+ coding root", type, to: &log)
                let container = try decoder.singleValueContainer()
                let r = try container.decode(type)
                print("- coded root", type, to: &log)
                return r
            }
            
            func decode<T>(_ type: T.Type, from decoder: Decoder) throws -> T where T : Decodable {
                print("+ coding", type, to: &log)
                let r = try type.init(from: decoder)
                print("- coded", type, to: &log)
                return r
            }
            
            deinit {
                // the original version of this test used a dictionary, and it kept failing because a dictionary encodes in a non-deterministic order
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

}
