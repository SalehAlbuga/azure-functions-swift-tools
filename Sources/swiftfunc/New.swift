//
//  New.swift
//  SwiftFunc
//
//  Created by Saleh on 11/9/19.
//

import Foundation
import SPMUtility
import Basic
import Files
import Stencil

struct NewCommand: Command {
    
    let command = "new"
    let overview = "Create a new function in a Swift Functions project!"
    
    private let type: PositionalArgument<String>
    private let name: OptionArgument<String>
    
    private let templates: [String] = ["http", "queue", "timer"]
    
    init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        type = subparser.add(positional: "type", kind: String.self, optional: false, usage: "Function type: http, timer, blob, empty.", completion: nil)
        name = subparser.add(option: "--name", shortName: "-n", kind: String.self, usage: "Function name!", completion: nil)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        guard let type = arguments.get(type), let name = arguments.get(name) else {
            return
        }
        
        guard templates.contains(type) else {
            print("Please select one of the available templates: http, blob, timer".bold.yellow)
            exit(0)
        }
        
        //        guard let folder = try? Folder.init(path: "/Users/saleh/Documents/Swift/codegenYard/swf/Sources/swf/functions"), let parentFolder = try? Folder.init(path: "/Users/saleh/Documents/Swift/codegenYard/swf/"), parentFolder.containsFile(at: "Package.swift")  else {
        //            print("Not a Swift Functions project, please run Swiftfunc init first")
        //            exit(0)
        //        }
        
        guard let parentFolder = try? Folder.init(path: Process().currentDirectoryPath), parentFolder.containsFile(at: "Package.swift") else {
            print("Not a Swift Functions project, please run Swiftfunc init first".bold.red)
            exit(1)
        }
        
        let projectName = parentFolder.name
        
        guard let folder = try? Folder.init(path: "\(parentFolder.path)Sources/\(projectName)/functions") else {
            print("Not a Swift Functions project, please run Swiftfunc init first".bold.red)
            exit(1)
        }
        
        let environment = Environment()
        
        
        print("Creating Function with \(type) template ⚡️".bold.blue)
        
        guard !folder.containsFile(named: "\(name).swift") else {
            print("A function with the name \(name) exits ☹️".bold.yellow)
            exit(0)
        }
        
        let funcFile = try folder.createFile(named: "\(name).swift")
        //
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-YY"
        let content = try environment.renderTemplate(string: Templates.Functions.template(forType: type), context: ["name": name, "project": projectName, "date": formatter.string(from: date)])
        try funcFile.write(content)
        
        let sourcesFolder = try parentFolder.createSubfolderIfNeeded(withName: "Sources")
        let codeFolder = try sourcesFolder.createSubfolderIfNeeded(withName: parentFolder.name)
        let functionsFolder = try codeFolder.createSubfolderIfNeeded(withName: "functions")
        
        print("Registering function 📝".bold.blue)
        
        var functions = ""
        for file in functionsFolder.files {
            let name = file.nameExcludingExtension
            functions.append("registry.register(\(name).self) \n")
        }
        let mainFile = try codeFolder.createFileIfNeeded(withName: "main.swift")
        try mainFile.write(environment.renderTemplate(string: Templates.ProjectFiles.mainSwiftWithFunctions, context: ["functions": functions]))
        
        
        print("New \(type) function created! 💃".bold.green)
        
    }
    
}
