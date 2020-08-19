//
//  Publish.swift
//  SwiftFunc
//
//  Created by Saleh on 08/14/20.
//

import Foundation
import SPMUtility
import Basic
import Files
import Stencil
import Dispatch
import Rainbow

@available(OSX 10.13, *)
final class PublishCommand: Command {
    
    let command = "publish"
    let overview = "Publish Swift Function App to Azure to run outside a container (Consumption Plan)"
    
    private let name: PositionalArgument<String>

    var tempFolder: Folder!

    let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    let sigtermSrc = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)

    init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        name = subparser.add(positional: "name", kind: String.self, optional: false, usage: "Name: the name of the Function App in Azure", completion: nil)

        signal(SIGINT, SIG_IGN)
        signal(SIGTERM, SIG_IGN)
                
        sigintSrc.setEventHandler { [weak self] in
            print("\nTerminating..".white)
            try! self?.tempFolder.delete()
            exit(SIGINT)
        }
        sigintSrc.resume()
        
        sigtermSrc.setEventHandler { [weak self] in
            print("\nTerminating..".white)
            try! self?.tempFolder.delete()
            exit(SIGTERM)
        }
        sigtermSrc.resume()
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        #if os(macOS)
        print("This command should be run from a Linux host. Please publish from a Swift Functions Dev Container".yellow)
        exit(1)
        #endif
        let coreToolsPath = "/usr/bin/func"

        guard let name = arguments.get(name) else {
            print("Please specify the Function App name".yellow)
            return
        }
        
         guard let srcFolder = try? Folder.init(path: Process().currentDirectoryPath), srcFolder.containsFile(at: "Package.swift") else {
            print("Not a Swift Project")
            return
        }

        let projectName = srcFolder.name
        
        tempFolder = try Folder.temporary.createSubfolderIfNeeded(withName: "\(projectName)-\(Int32.random(in: 0 ... INT32_MAX))")
        
        print("Swift Functions tools v\(version)".bold)

        print("Compiling Project.. 💻".bold.blue)

        try Shared.buildAndExport(sourceFolder: srcFolder, destFolder:tempFolder, azureWorkerPath: true)

        let srcLibFolder = try? Folder.init(path: "/usr/lib/swift/linux")
        
        if let destLibFolder = try? tempFolder.createSubfolderIfNeeded(at: "workers").createSubfolderIfNeeded(at: "swift") {
            try srcLibFolder?.copy(to: destLibFolder)
            try destLibFolder.subfolders.first?.rename(to: "lib")
        }

        Shared.checkFuncToolsInstallation()

        print("Publishing ⚡️ \n\n".blue.bold)
        
        var env: [String] = []
        for evar in Process().environment {
            env.append("\(evar.key)=\(evar.value)")
        }
        
        let dGroup = DispatchGroup()

        let _ = FileManager.default.changeCurrentDirectoryPath(tempFolder.path)  

        let p = PseudoTeletypewriter(path: coreToolsPath, arguments: ["func", "azure", "functionapp", "publish", "\(name)", "--force"], environment: env)!    
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
            
        channel.setInterval(interval: .seconds(3), flags:[.strictInterval])
        errChannel.setInterval(interval: .seconds(3), flags:[.strictInterval])
        
        dGroup.enter()
        channel.read(offset: 0, length: Int.max, queue: global) { (closed, dispatchData, error) in
            if let data = dispatchData, !data.isEmpty {
                DispatchQueue.main.async {
                    if let str = String.init(bytes: data, encoding: .utf8) {
                        print(str)
                    }
                }
            }
            if closed {
                dGroup.leave()
                channel.close()
            }
        }

        dGroup.enter()
        errChannel.read(offset: 0, length: Int.max, queue: global) { (closed, dispatchData, error) in
            if let data = dispatchData, !data.isEmpty {
                DispatchQueue.main.async {
                    if let str = String.init(bytes: data, encoding: .utf8) {
                        print(str)
                    }
                }
            }
            if closed {
                dGroup.leave()
                channel.close()
            }
        }

        dGroup.notify(queue: DispatchQueue.main) {
           try! self.tempFolder.delete()
           exit(0)
        }
        
        dispatchMain()
    }  
}
