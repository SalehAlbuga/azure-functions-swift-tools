/*
Copyright (c) 2015, Hoon H. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

///    Provides simple access to BSD `pty`.
///    
///    This spawns a new child process using supplied arguments,
///    and setup a proper pseudo terminal connected to it.
///
///    The child process will run in interactive mode terminal,
///    and will emit terminal escape code accordingly if you set
///    a proper terminal environment variable.
///
///        TERM=ansi
///
///    Here's full recommended example.
///
///        let    pty    =    PseudoTeletypewriter(path: "/bin/ls", arguments: ["/bin/ls", "-Gbla"], environment: ["TERM=ansi"])!
///        println(pty.masterFileHandle.readDataToEndOfFile().toString())
///        pty.waitUntilChildProcessFinishes()
///
///    It is recommended to use executable name as the first argument by convention.
///
///    The child process will be launched immediately when you 
///    instantiate this class.
///
///    This is a sort of `NSTask`-like class and modeled on it.
///    This does not support setting terminal dimensions.
///
public final class PseudoTeletypewriter {
    private let _masterFileHandle:FileHandle
    private let _childProcessID:pid_t

    public init?(path:String, arguments:[String], environment:[String]) {
//        assert(arguments.count >= 1)
//        assert(path.hasSuffix(arguments[0]))
        
        let r = forkPseudoTeletypewriter()
        if r.result.ok {
            if r.result.isRunningInParentProcess {
//                debugLog("parent: ok, child pid = \(r.result.processID)")
                self._masterFileHandle = r.master.toFileHandle(true)
                self._childProcessID = r.result.processID
            } else {
//                debugLog("child: ok")
                execute(path, arguments, environment)
                fatalError("Returning from `execute` means the command was failed. This is unrecoverable error in child process side, so just abort the execution.")
            }
        } else {
            debugLog("`forkpty` failed.")
            
            ///    Below two lines are useless but inserted to suppress compiler error.
            _masterFileHandle = FileHandle.init(fileDescriptor: 0)
            _childProcessID = 0
            return nil
        }
    }
    deinit {
    }
    
    public var masterFileHandle:FileHandle {
        return _masterFileHandle
    }
    
    public var childProcessID:pid_t {
        return _childProcessID
    }
    
    /// Waits for child process finishes synchronously.
    public func waitUntilChildProcessFinishes() {
        var stat_loc = 0 as Int32
        let childpid1 = waitpid(_childProcessID, &stat_loc, 0)
        debugLog("child process quit: pid = \(childpid1)")
    }
}

