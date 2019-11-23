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
    
    init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        name = subparser.add(positional: "name", kind: String.self, optional: false, usage: "Name: the name of the project", completion: nil)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        guard let name = arguments.get(name) else {
            return
        }
    
        let environment = Environment()
        
        let folder = try Folder.init(path: Process().currentDirectoryPath).createSubfolderIfNeeded(withName: name)
        
        print("Creating project files.. 📝".bold.blue)
        let packageFile = try folder.createFile(named: "Package.swift")
        try packageFile.write(try environment.renderTemplate(string: Templates.ProjectFiles.packageSwift, context: ["name": name]))
        
         let dockerFile = try folder.createFile(named: "Dockerfile")
        try dockerFile.write(try environment.renderTemplate(string: Templates.ProjectFiles.dockerfile, context: nil))
        
        let dockerIgnoreFile = try folder.createFile(named: ".Dockerignore")
        try dockerIgnoreFile.write(try environment.renderTemplate(string: Templates.ProjectFiles.dockerignore, context: nil))

        let gitIgnoreFile = try folder.createFile(named: ".gitignore")
        try gitIgnoreFile.write(try environment.renderTemplate(string: Templates.ProjectFiles.gitignore, context: nil))
        
        let sourcesFolder = try folder.createSubfolderIfNeeded(withName: "Sources")
        let codeFolder = try sourcesFolder.createSubfolderIfNeeded(withName: name)
        let _ = try codeFolder.createSubfolderIfNeeded(withName: "functions")
        
        let mainFile = try codeFolder.createFile(named: "main.swift")
        let mainContent = try environment.renderTemplate(string: Templates.ProjectFiles.mainSwiftEmpty, context: ["name": name])
        try mainFile.write(mainContent)
        
        print("Project created successfully ✅".bold.green)
        
    }
    
}
