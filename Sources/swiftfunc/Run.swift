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
        
        Shared.checkFuncToolsInstallation()

        let projectName = srcFolder.name
        
        tempFolder = try Folder.temporary.createSubfolderIfNeeded(withName: "\(projectName)-\(Int32.random(in: 0 ... INT32_MAX))")
        
        print("Swift Functions tools v\(version)".bold)

        print("Compiling Project.. 💻".bold.blue)

        try Shared.buildAndExport(sourceFolder: srcFolder, destFolder:tempFolder)
        
        print("Starting host 🏠 \n\n".blue.bold)
        
        var env: [String] = []
        for evar in Process().environment {
            env.append("\(evar.key)=\(evar.value)")
        }
        
        //env.append("TERM=ansi")

        let _ = FileManager.default.changeCurrentDirectoryPath(tempFolder.path)  
        
        #if os(macOS)
        let coreToolsPath = "/usr/local/bin/func"
        #else
        let coreToolsPath = "/usr/bin/func"
        #endif

        let p = PseudoTeletypewriter(path: coreToolsPath, arguments: ["host", "start", "--verbose"], environment: env)!
    
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
    
}
