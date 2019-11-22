//
//  CommandRegistry.swift
//  SwiftFunc
//
//  Created by Saleh on 11/1/19.
//

import Foundation
import SPMUtility
import Basic

struct CommandRegistry {
    
    private let parser: ArgumentParser
    private var commands: [Command] = []
    
    init(usage: String, overview: String) {
        parser = ArgumentParser(usage: usage, overview: overview)
    }
    
    mutating func register(command: Command.Type) {
        commands.append(command.init(parser: parser))
    }
    
    func run() {
        do {
            let parsedArguments = try parse()
            try process(arguments: parsedArguments)
        }
        catch let error as ArgumentParserError {
            print(error.description)
        }
        catch let error {
            print(error.localizedDescription)
        }
    }
    
    private func parse() throws -> ArgumentParser.Result {
        let arguments = Array(ProcessInfo.processInfo.arguments.dropFirst())
        return try parser.parse(arguments)
    }
    
    private func process(arguments: ArgumentParser.Result) throws {
        guard let subparser = arguments.subparser(parser),
            let command = commands.first(where: { $0.command == subparser }) else {
                parser.printUsage(on: stdoutStream)
                return
        }
        try command.run(with: arguments)
    }
    
}
