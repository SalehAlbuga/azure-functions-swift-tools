//
//  Templates.swift
//  SwiftFunc
//
//  Created by Saleh on 11/14/19.
//

import Foundation

struct Templates {
    
    struct Functions {
        
        static func template(forType: String, isHttp: Bool = false) -> String {
            switch forType {
            case "http":
                return isHttp ? httpHttpWorker : http
            case "queue":
                return isHttp ? queueHttpWorker : queue
            case "timer":
                return isHttp ? timerHttpWorker : timer
            default:
                return ""
            }
        }
        
        static let httpHttpWorker = """
        //
        //  {{ name }}.swift
        //  {{ project }}
        //
        //  Created on {{ date }}.
        //

        import Foundation
        import AzureFunctions
        import Vapor

        class {{ name }}: Function {
            
            required init() {
                super.init()
                self.name = "{{ name }}"
                self.functionJsonBindings =
                    [
                        ["authLevel": "anonymous",
                        "type": "httpTrigger",
                        "direction": "in",
                        "name": "req",
                        "methods": [
                            "get",
                            "post"
                         ]],
                        ["type": "http",
                        "direction": "out",
                        "name": "res"]
                    ]
                // or
                // self.trigger = HttpRequest(name: "req", methods: ["GET", "POST"])

                app.get([PathComponent(stringLiteral: name)], use: run(req:))
                app.post([PathComponent(stringLiteral: name)], use: run(req:))

            }
            
            func run(req: Request) -> String {
                if let name: String = req.query["name"] {
                    return "Hello, \\(name)!"
                } else if let name: String = req.content["name"] {
                    return "Hello, \\(name)!"
                } else {
                    return "Hello!"
                }
            }
        }
        """
        
        static let queueHttpWorker = """
        //
        //  {{ name }}.swift
        //  {{ project }}
        //
        //  Created on {{ date }}.
        //

        import Foundation
        import AzureFunctions
        import Vapor

        class {{ name }}: Function {
            
            required init() {
                super.init()
                self.name = "{{ name }}"
                self.functionJsonBindings = [
                        [
                          "connection" : "AzureWebJobsStorage",
                          "type" : "queueTrigger",
                          "name" : "myQueueTrigger",
                          "queueName" : "myqueue",
                          "direction" : "in"
                        ]
                      ]
                // or
                //self.trigger = Queue(name: "myQueueTrigger", queueName: "myqueue", connection: "AzureWebJobsStorage")
                
                app.post([PathComponent(stringLiteral: name)], use: run(req:))
            }
            
            func run(req: Request) -> InvocationResponse {
                var res = InvocationResponse()
                if let payload = try? req.content.decode(InvocationRequest.self), let queueItem = payload.data?["myQueueTrigger"] {
                    res.appendLog("Got \\(queueItem)")
                }
                return res
            }
        }
        """
        
        static let timerHttpWorker = """
        //
        //  {{ name }}.swift
        //  {{ project }}
        //
        //  Created on {{ date }}.
        //

        import Foundation
        import AzureFunctions
        import Vapor

        class {{ name }}: Function {
               
            required init() {
                super.init()
                self.name = "{{ name }}"
                self.functionJsonBindings =
                    [
                      [
                        "type" : "timerTrigger",
                        "name" : "myTimer",
                        "direction" : "in",
                        "schedule" : "*/5 * * * * *"
                      ]
                    ]
                //or
                //self.trigger = TimerTrigger(name: "myTimer", schedule: "*/5 * * * * *")

                app.post([PathComponent(stringLiteral: name)], use: run(req:))
            }
           
            func run(req: Request) -> InvocationResponse {
                var res = InvocationResponse()
                res.appendLog("Its is time!")
                return res
            }
        }
        """
        
        static let http = """
        //
        //  {{ name }}.swift
        //  {{ project }}
        //
        //  Created on {{ date }}.
        //

        import Foundation
        import AzureFunctions

        class {{ name }}: Function {
            
            required init() {
                super.init()
                self.name = "{{ name }}"
                self.trigger = HttpRequest(name: "req", methods: ["GET", "POST"])
            }
            
            override func exec(request: HttpRequest, context: inout Context, callback: @escaping callback) throws {
                
                context.log("Function executing!")
        
                let res = HttpResponse()
                res.statusCode = 200

                var name: String?
                
                if let data = request.body, let bodyObj: [String: Any] = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    name = bodyObj["name"] as? String
                } else {
                    name = request.query["name"] 
                }
                res.body  = "Hello \\(name ?? "buddy")!".data(using: .utf8)
                
                return callback(res);
            }
        }
        """

        static let queue = """
        //
        //  {{ name }}.swift
        //  {{ project }}
        //
        //  Created on {{ date }}.
        //

        import Foundation
        import AzureFunctions

        class {{ name }}: Function {

            required init() {
                super.init()
                self.name = "{{ name }}"
                self.trigger = Queue(name: "myQueueTrigger", queueName: "queueName", connection: "AzureWebJobsStorage")
            }

            override func exec(string: String, context: inout Context, callback: @escaping callback) throws {
                context.log("Got queue item: \\(string)")
                callback(true)
            }
        }
        """
        
        static let timer = """
        //
        //  {{ name }}.swift
        //  {{ project }}
        //
        //  Created on {{ date }}.
        //

        import Foundation
        import AzureFunctions

        class {{ name }}: Function {
            
            required init() {
                super.init()
                self.name = "{{ name }}"
                self.trigger = TimerTrigger(name: "myTimer", schedule: "*/5 * * * * *")
            }
            
            override func exec(timer: TimerTrigger, context: inout Context, callback: @escaping callback) throws {
                context.log("It is time!")
                callback(true)
            }
            
        }
        """

        static let servicebus = """
        //
        //  {{ name }}.swift
        //  {{ project }}
        //
        //  Created on {{ date }}.
        //

        import Foundation
        import AzureFunctions

        class {{ name }}: Function {
            
            required init() {
                super.init()
                self.name = "{{ name }}"
                self.trigger = ServiceBusMessage(name: "sbTrigger", topicName: "mytopic", subscriptionName: "mysubscription", connection: "ServiceBusConnection")
            }

        override func exec(sbMessage: ServiceBusMessage, context: inout Context, callback: @escaping callback) throws {
            if let msg: String = sbMessage.message as? String {
                context.log("Got topic message: \\(msg)")
            } 

            callback(true)
        }
        }
        """
        
    }
    
    struct ProjectFiles {
        
        static let mainSwift = """
        //
        //  main.swift
        //  {{ name }}
        //
        //  Auto Generated by SwiftFunctionsSDK
        //
        //  Only register/remove Functions. Do Not add other code
        //

        import AzureFunctions

        let registry = FunctionRegistry()

        // ****** register/remove your functions. Optionally, set your debug AzureWebJobsStorage and others environment variable ******

        //registry.AzureWebJobsStorage = "your debug AzureWebJobsStorage" //Remove before deploying. Do not commit or push any Storage Account keys
        //registry.EnvironmentVariables = ["otherStorageConnection": "connectionsString"]

        //registry.register(name: "name", function: MyFunction.self)

        {{ functions }}
        // ******

        {{ start }}

        """
        static let classicStart = "AzureFunctionsWorker.shared.main(registry: registry)"
        static let httpStart = "AzureFunctionsWorker.shared.main(registry: registry, mode: .HTTP)"
        
        static let packageSwift = """
            // swift-tools-version:5.2
            // The swift-tools-version declares the minimum version of Swift required to build this package.

            import PackageDescription

            let package = Package(
                name: "{{ name }}",
                platforms: [
                    .macOS(.v10_15)
                ],
                products: [
                    .executable(name: "functions", targets: ["{{ name }}"]),
                 ],
                dependencies: [
                    // Dependencies declare other packages that this package depends on.
                    // .package(url: /* package url */, from: "1.0.0"),
                     .package(url: "https://github.com/SalehAlbuga/azure-functions-swift", from: "0.6.0"),
                ],
                targets: [
                    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
                    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
                    .target(
                        name: "{{ name }}",
                        dependencies: [.product(name: "AzureFunctions", package: "azure-functions-swift")])
                ]
            )
            """
        
        static let gitignore = """
        .DS_Store
        /.build
        /Packages
        /*.xcodeproj
        xcuserdata/
        """
        
        static let dockerfile = """
        FROM swift:5.2.3 AS build-image

        WORKDIR /src
        COPY . .
        RUN swift build -c release
        WORKDIR /home/site/wwwroot
        RUN [ "/src/.build/release/functions", "export", "--source", "/src", "--root", "/home/site/wwwroot" ]

        FROM mcr.microsoft.com/azure-functions/base:3.0 as functions-image

        FROM salehalbuga/azure-functions-swift-runtime:1.0

        COPY --from=functions-image [ "/azure-functions-host", "/azure-functions-host" ]

        COPY --from=build-image ["/home/site/wwwroot", "/home/site/wwwroot/"]

        CMD [ "/azure-functions-host/Microsoft.Azure.WebJobs.Script.WebHost" ]

        """
        
        static let dockerfileclassic = """
        FROM swift:5.2.3 AS build-image

        WORKDIR /src
        COPY . .
        RUN swift build -c release
        WORKDIR /home/site/wwwroot
        RUN [ "/src/.build/release/functions", "export", "--source", "/src", "--root", "/home/site/wwwroot" ]

        FROM mcr.microsoft.com/azure-functions/base:3.0 as functions-image

        FROM salehalbuga/azure-functions-swift-runtime-classic:1.0

        COPY --from=functions-image [ "/azure-functions-host", "/azure-functions-host" ]

        COPY --from=build-image ["/home/site/wwwroot", "/home/site/wwwroot/"]

        CMD [ "/azure-functions-host/Microsoft.Azure.WebJobs.Script.WebHost" ]

        """
        
        static let dockerignore = """
        .build
        .vscode
        .git
        """
        
    }
}
