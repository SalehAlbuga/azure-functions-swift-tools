/*
 Copyright (c) 2015, Hoon H. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import Foundation

extension Data {
    func toUInt8Array() -> [UInt8] {
        let p = (self as NSData).bytes
        
        var bs = [] as [UInt8]
        for i in 0..<self.count {
            let dataPtr = p.advanced(by: i)
            let datum = dataPtr.load(as: UInt8.self)
            bs.append(datum)
        }
        
        return bs
    }
    func toString() -> String {
        return NSString(data: self, encoding: String.Encoding.utf8.rawValue)! as String
    }
    
    static func fromUInt8Array(_ bs:[UInt8]) -> Data {
        var r = nil as Data?
        bs.withUnsafeBufferPointer { (p:UnsafeBufferPointer<UInt8>) -> () in
            let p1 = UnsafeRawPointer(p.baseAddress)!
            let opPtr = OpaquePointer(p1)
            r = Data(bytes: UnsafePointer<UInt8>(opPtr), count: p.count)
        }
        return r!
    }
    
    ///    Assumes `cCharacters` is C-string.
    static func fromCCharArray(_ cCharacters:[CChar]) -> Data {
        precondition(cCharacters.count == 0 || cCharacters[(cCharacters.endIndex - 1)] == 0)
        var r = nil as Data?
        cCharacters.withUnsafeBufferPointer { (p:UnsafeBufferPointer<CChar>) -> () in
            let p1 = UnsafeRawPointer(p.baseAddress)!
            let opPtr = OpaquePointer(p1)
            r = Data(bytes: UnsafePointer<UInt8>(opPtr), count: p.count)
        }
        return r!
    }
}



func debugLog(_ msg: String) {
    #if DEBUG
    print(msg)
    #endif
}
