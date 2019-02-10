//
//  DecodingInfoStack.swift
//  CodableInterception
//
//  Created by Greg Omelaenko on 10/2/19.
//  Copyright © 2019 Greg Omelaenko. All rights reserved.
//

import Foundation
import Dispatch

/// A per-customiser-type, per-thread, dictionary of stacks of `DecodingInfo`.
///
/// This is global because it can't be static in `DecodingInfo` (Swift 4).
/// It can't be an instance variable because `DecodableWrapper.init(from:)` needs to access it.
fileprivate var _decodingInfoStacks: [ObjectIdentifier : [Thread : Any]] = [:]
fileprivate let _decodingInfoStacksSemaphore = DispatchSemaphore(value: 1)

fileprivate func withDecodingInfoStack<Customiser: CodingCustomiser, R>(for customiserType: Customiser.Type, inThread thread: Thread = Thread.current, _ f: (inout [(receiver: Any.Type, decodingInfo: DecodingInfo<Customiser>, customise: Bool)]) throws -> R) rethrows -> R {
    _decodingInfoStacksSemaphore.wait()
    defer { _decodingInfoStacksSemaphore.signal() }
    
    let id = ObjectIdentifier(Customiser.self)
    var byThread = _decodingInfoStacks[id] ?? [:]
    var stack = byThread[thread].map({ $0 as! [(receiver: Any.Type, decodingInfo: DecodingInfo<Customiser>, customise: Bool)] }) ?? []
    let result = try f(&stack)
    byThread[thread] = stack
    _decodingInfoStacks[id] = byThread
    
    return result
}

/// - Parameter receiver: Recorded for debugging purposes.
func pushDecodingInfo<Customiser: CodingCustomiser>(_ decodingInfo: DecodingInfo<Customiser>, customiseDecode: Bool, for receiver: Any.Type) {
    withDecodingInfoStack(for: Customiser.self) { stack in
        stack.append((receiver, decodingInfo, customiseDecode))
    }
}

func popDecodingInfo<Customiser: CodingCustomiser>(for receiver: Any.Type) -> (decodingInfo: DecodingInfo<Customiser>, customise: Bool) {
    let (intended, decodingInfo, customise) = withDecodingInfoStack(for: Customiser.self) { stack -> (Any.Type, DecodingInfo<Customiser>, Bool) in
        guard let top = stack.popLast() else {
            preconditionFailure("BUG: Tried to pop a \(DecodingInfo<Customiser>.self) for \(receiver) but the stack is empty.")
        }
        return top
    }
    precondition(intended == receiver, "BUG: \(DecodingInfo<Customiser>.self) was intended for \(intended) but was popped by \(receiver).")
    return (decodingInfo, customise)
}
