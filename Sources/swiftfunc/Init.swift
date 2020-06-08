//
//  init.swift
//  SwiftFunc
//
//  Created by Saleh on 11/9/19.
//

import Foundation
import SPMUtility
import Basic
import Files
import Stencil

struct InitCommand: Command {
    
    let command = "init"
    let overview = "Create a new Swift Function project"
    
    private let name: PositionalArgument<String>
    private let isHttpWorker: OptionArgument<Bool>

    init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        name = subparser.add(positional: "name", kind: String.self, optional: false, usage: "Name: the name of the project", completion: nil)
        isHttpWorker = subparser.add(option: "--http-worker", shortName: "-hw", kind: Bool.self, usage: "init the project as an Azure Functions custom handler (http worker)", completion: nil)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        guard let name = arguments.get(name) else {
            print("Please specify the project name with -n".yellow)
            return
        }
        
        let httpWorker: Bool = arguments.get(isHttpWorker) ?? false
        
        let environment = Environment()
        
        let folder = try Folder.init(path: Process().currentDirectoryPath).createSubfolderIfNeeded(withName: name)
        
        print("Creating project files.. 📝".bold.blue)
        let packageFile = try folder.createFile(named: "Package.swift")
        try packageFile.write(try environment.renderTemplate(string: Templates.ProjectFiles.packageSwift, context: ["name": name]))
        
        let dockerFile = try folder.createFile(named: "Dockerfile")
        try dockerFile.write(try environment.renderTemplate(string: httpWorker ? Templates.ProjectFiles.dockerfile : Templates.ProjectFiles.dockerfileclassic, context: nil))
        
        let dockerIgnoreFile = try folder.createFile(named: ".Dockerignore")
        try dockerIgnoreFile.write(try environment.renderTemplate(string: Templates.ProjectFiles.dockerignore, context: nil))

        let gitIgnoreFile = try folder.createFile(named: ".gitignore")
        try gitIgnoreFile.write(try environment.renderTemplate(string: Templates.ProjectFiles.gitignore, context: nil))
        
        let sourcesFolder = try folder.createSubfolderIfNeeded(withName: "Sources")
        let codeFolder = try sourcesFolder.createSubfolderIfNeeded(withName: name)
        let _ = try codeFolder.createSubfolderIfNeeded(withName: "functions")
        
        let mainFile = try codeFolder.createFile(named: "main.swift")
        let mainContent = try environment.renderTemplate(string: Templates.ProjectFiles.mainSwift, context: ["name": name, "start": httpWorker ? Templates.ProjectFiles.httpStart : Templates.ProjectFiles.classicStart])
        try mainFile.write(mainContent)
        
        print("Project created successfully ✅".bold.green)
        
    }
    
}
