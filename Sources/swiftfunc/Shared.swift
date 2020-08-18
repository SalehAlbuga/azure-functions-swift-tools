//
//  Shared.swift
//  SwiftFunc
//
//  Created by Saleh on 08/10/20.
//

import Foundation
import SPMUtility
import Basic
import Files
import Stencil
import Dispatch
import Rainbow

@available(OSX 10.13, *)
struct Shared {

    static func buildAndExport(sourceFolder: Folder, destFolder: Folder, debug: Bool = false, azureWorkerPath: Bool = false) throws {
         
        let cst = try shellStreamOutput(path: "/bin/bash", command: "-c", "swift build -c release", dir: sourceFolder.path, waitUntilExit: true)
        
        if cst == 0 {
            print("Compiled!".green.bold)
        } else {
            print("Compilation error 😞".red.bold)
            exit(1)
        }
        
        let path = "\(sourceFolder.path).build/release/functions"
        let est = try shellStreamOutput(path: path, command: "export", "--source", "\(sourceFolder.path)", "--root", "\(destFolder.path)", debug ? "--debug" : "", azureWorkerPath ? "--azure-worker-path" : "", dir: sourceFolder.path, waitUntilExit: true)
        
        if est == 0 {
            print("Exported! \n".green.bold)
        } else {
            print("Exporting error 😞".red.bold)
            exit(1)
        }
    }

    static func checkFuncToolsInstallation() {
         //detect if Core Tools are installed
        var strOutput: String = ""
        Shared.shell(path: "/bin/bash", command: "-c", "which func", result: &strOutput, dir: Folder.current.path)
        
        if strOutput == "" { 
            print("Function Core Tools not found 😞 Please install Core Tools: \n".red.bold)

            #if os(macOS)
            print(" brew tap azure/functions \n brew install azure-functions-core-tools@2 or brew install azure-functions-core-tools@3 \n\n".yellow.bold)
            #else
            print(" https://github.com/Azure/azure-functions-core-tools#linux \n\n".yellow.bold)
            #endif

            exit(1)
        }
    }

    @discardableResult
    static func shell(path: String, command: String..., result: inout String, dir: String) -> Int32 {
        
        let task = Process()
        task.launchPath = path
        task.arguments = command
        task.qualityOfService = .default
        task.currentDirectoryPath = dir
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
        } catch {
            print("\(error.localizedDescription)")
        }
            
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        result = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        
        task.waitUntilExit()
        return task.terminationStatus
    }
    
    
    @discardableResult
    static func shellStreamOutput(path: String, command: String..., dir: String?, waitUntilExit: Bool = false) throws -> Int32 {
        let task = Process()
        task.launchPath = path
        task.arguments = command
        //    task.qualityOfService = .userInitiated
        if let curDir = dir {
            task.currentDirectoryPath = curDir
        }
        let pipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = pipe
        task.standardError = errorPipe
        
        
        let global = DispatchQueue.global(qos: .background)
        let channel = DispatchIO(type: .stream, fileDescriptor: pipe.fileHandleForReading.fileDescriptor, queue: global) { (int) in
            DispatchQueue.main.async {
//                print("Clean-up Handler: \(int)")
//                exit(EXIT_SUCCESS)
            }
        }
        let errChannel = DispatchIO(type: .stream, fileDescriptor: errorPipe.fileHandleForReading.fileDescriptor, queue: global) { (int) in
            DispatchQueue.main.async {
//                print("Clean-up Handler: \(int)")
//                exit(EXIT_SUCCESS)
            }
        }
        
        channel.setLimit(lowWater: Int(1000))
        errChannel.setLimit(lowWater: Int(1000))
        
        channel.setInterval(interval: .milliseconds(500), flags:[.strictInterval])
        errChannel.setInterval(interval: .milliseconds(500), flags:[.strictInterval])
        
        
        channel.read(offset: 0, length: Int.max, queue: global) { (closed, dispatchData, error) in
            if let data = dispatchData, !data.isEmpty {
                DispatchQueue.main.async {
                    if let str = String.init(bytes: data, encoding: .utf8) {
                        print(str)
                    }
                }
            }
            
            if closed {
                channel.close()
            }
        }
        
        
        errChannel.read(offset: 0, length: Int.max, queue: global) { (closed, dispatchData, error) in
            if let data = dispatchData, !data.isEmpty {
                DispatchQueue.main.async {
                    if let str = String.init(bytes: data, encoding: .utf8) {
                        print("\(str)")
                    }
                }
            }
            
            if closed {
                channel.close()
            }
        }
        
        
        task.terminationHandler = { (process) in
//            print("\ndidFinish: \(!process.isRunning)")
        }
        
        do {
            try task.run()
        } catch {
            print("exec error: \(error)")
            return -1
        }
        
        if waitUntilExit {
            task.waitUntilExit()
            return task.terminationStatus
        } else {
            return -1
        }
    }
    
}