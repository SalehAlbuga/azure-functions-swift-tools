/*
Copyright (c) 2015, Hoon H. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation
// BSD functions properly wrapped in more simple and typesafe Swift manner.


public struct FileDescriptor {
    fileprivate var value:Int32
    public func toFileHandle(_ closeOnDealloc: Bool) -> FileHandle {
        return FileHandle(fileDescriptor: value, closeOnDealloc: closeOnDealloc)
    }
}

public struct ForkResult {
    fileprivate var value:pid_t
    public var ok:Bool {
        return value != 1
    }
    public var isRunningInParentProcess:Bool {
        return value > 0
    }
    public var isRunningInChildProcess:Bool {
        return value == 0
    }
    
    ///  Calling this in child process side will crash the program.
    public var processID:pid_t {
        precondition(isRunningInParentProcess, "You tried to read this property from child process side. It is not allowed.")
        return value
    }
}

/// BSD `forkpty`.
/// https://developer.apple.com/library/ios/documentation/System/Conceptual/ManPages_iPhoneOS/man3/openpty.3.html
public func forkPseudoTeletypewriter() -> (result:ForkResult, master:FileDescriptor) {
    var amaster = 0 as Int32
    let pid = forkpty(&amaster, nil, nil, nil)
    return (ForkResult(value: pid), FileDescriptor(value: amaster))
}

/// BSD `execve`
/// Does not return on success.
/// Returns on any error.
/// https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man3/exec.3.html
public func execute(_ path:String, _ arguments:[String], _ environment:[String]) {
    path.withCString { (pathP:UnsafePointer<Int8>) -> () in
        withCPointerToNullTerminatingCArrayOfCStrings(arguments, { (argP:UnsafePointer<UnsafeMutablePointer<Int8>?>) -> () in
            withCPointerToNullTerminatingCArrayOfCStrings(environment, { (envP:UnsafePointer<UnsafeMutablePointer<Int8>?>) -> () in
                execve(pathP, argP, envP)
                return
            })
        })
        fatalError("`execve` call returned that means failure.")
    }
}

///    MARK:

/// Generates proper pointer arrays for `exec~` family calls.
/// Terminatin `NULL` is required for `exec~` family calls.
private func withCPointerToNullTerminatingCArrayOfCStrings(_ strings:[String], _ block:@escaping (UnsafePointer<UnsafeMutablePointer<Int8>?>)-> Void) {
    /// Keep this in memory until the `block` to be finished.
    let a: [NSMutableData] = strings.map { (s:String) -> NSMutableData in
        let b = s.cString(using: String.Encoding.utf8)!
        assert(b[b.endIndex-1] == 0)
        return (Data.fromCCharArray(b) as NSData).mutableCopy() as! NSMutableData
    }
    
    let a1: [UnsafeMutablePointer<Int8>?] = a.map { (d:NSMutableData) -> UnsafeMutablePointer<Int8> in
        let opPtr = OpaquePointer(d.mutableBytes)
        return UnsafeMutablePointer<Int8>(opPtr)
    } + [nil]
//    debugLog(a1)
    
    a1.withUnsafeBufferPointer { buffer -> Void in
        block(buffer.baseAddress!)
    }
}














