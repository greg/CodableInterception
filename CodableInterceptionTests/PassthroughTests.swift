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
        var a: [String : A]
    }
    
    let sample = [
        B(a: ["a": A(x: [], y: 2), "": A(x: [2, 8, 7], y: -1.5), "htns": A(x: [2], y: 0)]),
        B(a: [:])
    ]
    
    final class NonCustomiser: CodingCustomiser {
        
        init(for mode: CodingMode) {}
        
    }
    
    typealias UselessInterceptor<V> = CodableInterceptor<V, NonCustomiser>

    func testPassthrough() {
        let json = try! JSONEncoder().encode(UselessInterceptor(sample))
        let decoded = try! JSONDecoder().decode(UselessInterceptor<[B]>.self, from: json).decodedValue
        
        XCTAssert(decoded == sample)
    }

}
