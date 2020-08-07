//
//  main.swift
//  SwiftFunc
//
//  Created by Saleh on 11/1/19.
//

import Foundation
import SPMUtility

let version = "0.4.2"

protocol Command {
    var command: String { get }
    var overview: String { get }
    
    init(parser: ArgumentParser)
    func run(with arguments: ArgumentParser.Result) throws
}


var registry = CommandRegistry(usage: "<command> <options>", overview: "Swift Functions tools v\(version)")

registry.register(command: InitCommand.self)
registry.register(command: NewCommand.self)
if #available(OSX 10.13, *) {
    registry.register(command: RunCommand.self)
} else {
    print("Requires OSX 10.13 or later ☹️")
}

registry.run()


