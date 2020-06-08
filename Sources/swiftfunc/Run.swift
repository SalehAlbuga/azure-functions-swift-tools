//
//  Run.swift
//  SwiftFunc
//
//  Created by Saleh on 11/9/19.
//

import Foundation
import SPMUtility
import Basic
import Files
import Stencil
import Dispatch
import Rainbow


@available(OSX 10.13, *)
final class RunCommand: Command {
    
    let command = "run"
    let overview = "Run a Swift Function project locally. Azure Functions Core Tools is required"
    
    let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    let sigtermSrc = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
    
    var tempFolder: Folder!
    
    init(parser: ArgumentParser) {
        let _ = parser.add(subparser: command, overview: overview)
        
        signal(SIGINT, SIG_IGN)
        signal(SIGTERM, SIG_IGN)
                
        sigintSrc.setEventHandler { [weak self] in
            print("Terminating..".white)
            try! self?.tempFolder.delete()
            exit(SIGINT)
        }
        sigintSrc.resume()
        
        sigtermSrc.setEventHandler { [weak self] in
            print("Terminating..".white)
            try! self?.tempFolder.delete()
            exit(SIGTERM)
        }
        sigtermSrc.resume()
        
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        guard let srcFolder = try? Folder.init(path: Process().currentDirectoryPath), srcFolder.containsFile(at: "Package.swift") else {
            print("Not a Swift Project")
            return
        }
        
        let projectName = srcFolder.name
        
        tempFolder = try Folder.temporary.createSubfolderIfNeeded(withName: "\(projectName)-\(Int32.random(in: 0 ... INT32_MAX))")
        
        print("Compiling Project.. 💻".bold.blue)
        
        let cst = try shellStreamOutput(path: "/bin/bash", command: "-c", "swift build -c release", dir: srcFolder.path, waitUntilExit: true)
        
        if cst == 0 {
            print("Compiled!".green.bold)
        } else {
            print("Compilation error 😞".red.bold)
            exit(1)
        }
        
        let path = "\(srcFolder.path).build/release/functions"
        let est = try shellStreamOutput(path: path, command: "export", "--source", "\(srcFolder.path)", "--root", "\(tempFolder.path)", "--debug", dir: srcFolder.path, waitUntilExit: true)
        
               
               if est == 0 {
                   print("Exported! \n".green.bold)
               } else {
                   print("Exporting error 😞".red.bold)
                   exit(1)
               }
        
        //detect if Core Tools are installed
        var strOutput: String = ""
        shell(path: "/bin/bash", command: "-c", "which func", result: &strOutput, dir: srcFolder.path)
        
        if strOutput == "" { 
            print("Function Core Tools not found 😞 Please install Core Tools: \n".red.bold)
            print(" brew tap azure/functions \n brew install azure-functions-core-tools@2 or brew install azure-functions-core-tools@3 \n\n".yellow.bold)
            exit(1)
        }
        
        print("Starting host 🏠 \n\n".blue.bold)
        
        var env: [String] = []
        for evar in Process().environment {
            env.append("\(evar.key)=\(evar.value)")
        }
        
        //env.append("TERM=ansi")

        let _ = FileManager.default.changeCurrentDirectoryPath(tempFolder.path)  
              
        let p = PseudoTeletypewriter(path: "/usr/local/bin/func", arguments: ["host", "start"], environment: env)!
    
        let fileDescriptor = p.masterFileHandle.fileDescriptor
        
        let global = DispatchQueue.global(qos: .utility)
        let channel = DispatchIO(type: .stream, fileDescriptor: fileDescriptor, queue: global) { (int) in
            DispatchQueue.main.async {
                exit(EXIT_SUCCESS)
            }
        }
        let errChannel = DispatchIO(type: .stream, fileDescriptor: fileDescriptor, queue: global) { (int) in
            DispatchQueue.main.async {
                exit(EXIT_SUCCESS)
            }
        }

        channel.setLimit(lowWater: Int(10000))
        errChannel.setLimit(lowWater: Int(10000))
            
        channel.setInterval(interval: .seconds(1), flags:[.strictInterval])
        errChannel.setInterval(interval: .seconds(1), flags:[.strictInterval])
        
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
                        print(str)
                    }
                }
            }

            if closed {
                channel.close()
            }
        }
        
        dispatchMain()
    }
    
    
    @discardableResult
    func shell(path: String, command: String..., result: inout String, dir: String) -> Int32 {
        
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
    func shellStreamOutput(path: String, command: String..., dir: String?, waitUntilExit: Bool = false) throws -> Int32 {
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
        
        channel.setInterval(interval: .milliseconds(250), flags:[.strictInterval])
        errChannel.setInterval(interval: .milliseconds(250), flags:[.strictInterval])
        
        
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
