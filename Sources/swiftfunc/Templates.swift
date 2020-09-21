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
        .devcontainer
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
        .devcontainer
        """


        struct devContainer {

            static let devContainerJson = """
            {
                "name": "Swift",
                "build": {
                    "dockerfile": "Dockerfile",
                    "args": {
                        // Update the VARIANT arg to pick a Swift version
                        "VARIANT": "5.2",
                        // Options
                        "INSTALL_NODE": "false",
                        "NODE_VERSION": "lts/*"
                    }
                },
                "runArgs": [
                    "--cap-add=SYS_PTRACE",
                    "--security-opt",
                    "seccomp=unconfined"
                ],

                // Set *default* container specific settings.json values on container create.
                "settings": {
                    "terminal.integrated.shell.linux": "/bin/bash",
                    "lldb.adapterType": "bundled",
                    "lldb.executable": "/usr/bin/lldb",
                    "sde.languageservermode": "sourcekite",
                    "swift.path.sourcekite": "/usr/local/bin/sourcekite"
                },

                // Add the IDs of extensions you want installed when the container is created.
                "extensions": [
                    "vknabel.vscode-swift-development-environment",
                    "vadimcn.vscode-lldb"
                ]

                // Use 'forwardPorts' to make a list of ports inside the container available locally.
                // "forwardPorts": [],

                // Use 'postCreateCommand' to run commands after the container is created.
                // "postCreateCommand": "swiftc --version",

                // Uncomment to connect as a non-root user. See https://aka.ms/vscode-remote/containers/non-root.
                // "remoteUser": "vscode"
            }
            """

            static let dockerfile = """
            # Update the VARIANT arg in devcontainer.json to pick a Swift version
            ARG VARIANT=5.2
            FROM swift:${VARIANT}

            # Options for setup script
            ARG INSTALL_ZSH="true"
            ARG UPGRADE_PACKAGES="false"
            ARG USERNAME=vscode
            ARG USER_UID=1000
            ARG USER_GID=$USER_UID

            # Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
            COPY library-scripts/common-debian.sh /tmp/library-scripts/
            RUN apt-get update && export DEBIAN_FRONTEND=noninteractive
            RUN /bin/bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}"
            RUN apt-get -y install --no-install-recommends lldb python3-minimal libpython3.7 ninja-build libsqlite3-dev libedit-dev
            RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/* && rm -rf /tmp/library-scripts

            # Install Azure CLI
            RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

            # Setup Functions Core Tools package feed
            RUN wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
            RUN dpkg -i packages-microsoft-prod.deb
            # Install Core Tools
            RUN apt-get update && export DEBIAN_FRONTEND=noninteractive
            RUN apt-get -y install --no-install-recommends azure-functions-core-tools-3

            # Install Swift Functions Tools
            RUN git clone https://github.com/SalehAlbuga/azure-functions-swift-tools.git
            RUN cd azure-functions-swift-tools && make install

            # Install SourceKite, see https://github.com/vknabel/vscode-swift-development-environment/blob/master/README.md#installation
            # RUN git clone https://github.com/vknabel/sourcekite \
            #     && export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/swift:/usr/lib \
            #     && ln -s /usr/lib/libsourcekitdInProc.so /usr/lib/sourcekitdInProc \
            #     && cd sourcekite && make install PREFIX=/usr/local -j2

            # # [Optional] Install Node.js for use with web applications - update the INSTALL_NODE arg in devcontainer.json to enable.
            # ARG INSTALL_NODE="false"
            # ARG NODE_VERSION="lts/*"
            # ENV NVM_DIR=/usr/local/share/nvm \
            #     NVM_SYMLINK_CURRENT=true \
            #     PATH=${NVM_DIR}/current/bin:${PATH}
            # COPY library-scripts/node-debian.sh /tmp/library-scripts/
            # RUN if [ "$INSTALL_NODE" = "true" ]; then \
            #         /bin/bash /tmp/library-scripts/node-debian.sh "${NVM_DIR}" "${NODE_VERSION}" "${USERNAME}" \
            #         && apt-get clean -y && rm -rf /var/lib/apt/lists/*; \
            #     fi \
            #     && rm -rf /tmp/library-scripts


            # [Optional] Uncomment this section to install additional OS packages you may want.
            # RUN apt-get update \
            #     && export DEBIAN_FRONTEND=noninteractive \
            #     && apt-get -y install --no-install-recommends <your-package-list-here>
            """

            static let commonDebian = """
            #!/usr/bin/env bash
            #-------------------------------------------------------------------------------------------------------------
            # Copyright (c) Microsoft Corporation. All rights reserved.
            # Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
            #-------------------------------------------------------------------------------------------------------------

            # Syntax: ./common-debian.sh <install zsh flag> <username> <user UID> <user GID> <upgrade packages flag>

            set -e

            INSTALL_ZSH=${1:-"true"}
            USERNAME=${2:-"$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)"}
            USER_UID=${3:-1000}
            USER_GID=${4:-1000}
            UPGRADE_PACKAGES=${5:-"true"}

            if [ "$(id -u)" -ne 0 ]; then
                echo 'Script must be run a root. Use sudo or set "USER root" before running the script.'
                exit 1
            fi

            # Treat a user name of "none" as root
            if [ "${USERNAME}" = "none" ] || [ "${USERNAME}" = "root" ]; then
                USERNAME=root
                USER_UID=0
                USER_GID=0
            fi

            # Ensure apt is in non-interactive to avoid prompts
            export DEBIAN_FRONTEND=noninteractive

            # Install apt-utils to avoid debconf warning
            apt-get -y install --no-install-recommends apt-utils 2> >( grep -v 'debconf: delaying package configuration, since apt-utils is not installed' >&2 )

            # Get to latest versions of all packages
            if [ "${UPGRADE_PACKAGES}" = "true" ]; then
                apt-get -y upgrade --no-install-recommends
            fi

            # Install common developer tools and dependencies
            apt-get -y install --no-install-recommends \
                git \
                openssh-client \
                less \
                iproute2 \
                procps \
                curl \
                wget \
                unzip \
                nano \
                jq \
                lsb-release \
                ca-certificates \
                apt-transport-https \
                dialog \
                gnupg2 \
                libc6 \
                libgcc1 \
                libgssapi-krb5-2 \
                libicu[0-9][0-9] \
                liblttng-ust0 \
                libstdc++6 \
                zlib1g \
                locales

            # Ensure at least the en_US.UTF-8 UTF-8 locale is available.
            # Common need for both applications and things like the agnoster ZSH theme.
            echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
            locale-gen

            # Install libssl1.1 if available
            if [[ ! -z $(apt-cache --names-only search ^libssl1.1$) ]]; then
                apt-get -y install  --no-install-recommends libssl1.1
            fi

            # Install appropriate version of libssl1.0.x if available
            LIBSSL=$(dpkg-query -f '${db:Status-Abbrev}\t${binary:Package}\n' -W 'libssl1\\.0\\.?' 2>&1 || echo '')
            if [ "$(echo "$LIBSSL" | grep -o 'libssl1\\.0\\.[0-9]:' | uniq | sort | wc -l)" -eq 0 ]; then
                if [[ ! -z $(apt-cache --names-only search ^libssl1.0.2$) ]]; then
                    # Debian 9
                    apt-get -y install  --no-install-recommends libssl1.0.2
                elif [[ ! -z $(apt-cache --names-only search ^libssl1.0.0$) ]]; then
                    # Ubuntu 18.04, 16.04, earlier
                    apt-get -y install  --no-install-recommends libssl1.0.0
                fi
            fi

            # Create or update a non-root user to match UID/GID - see https://aka.ms/vscode-remote/containers/non-root-user.
            if id -u $USERNAME > /dev/null 2>&1; then
                # User exists, update if needed
                if [ "$USER_GID" != "$(id -G $USERNAME)" ]; then
                    groupmod --gid $USER_GID $USERNAME
                    usermod --gid $USER_GID $USERNAME
                fi
                if [ "$USER_UID" != "$(id -u $USERNAME)" ]; then
                    usermod --uid $USER_UID $USERNAME
                fi
            else
                # Create user
                groupadd --gid $USER_GID $USERNAME
                useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME
            fi

            # Add add sudo support for non-root user
            apt-get install -y sudo
            echo $USERNAME ALL=\\(root\\) NOPASSWD:ALL > /etc/sudoers.d//$USERNAME
            chmod 0440 /etc/sudoers.d/$USERNAME

            # Ensure ~/.local/bin is in the PATH for root and non-root users for bash. (zsh is later)
            echo "export PATH=\\$PATH:\\$HOME/.local/bin" | tee -a /root/.bashrc >> /home/$USERNAME/.bashrc
            chown $USER_UID:$USER_GID /home/$USERNAME/.bashrc

            # Optionally install and configure zsh
            if [ "$INSTALL_ZSH" = "true" ] && [ ! -d "/root/.oh-my-zsh" ]; then
                apt-get install -y zsh
                sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
                echo "export PATH=\\$PATH:\\$HOME/.local/bin" >> /root/.zshrc
                cp -R /root/.oh-my-zsh /home/$USERNAME
                cp /root/.zshrc /home/$USERNAME
                sed -i -e "s/\\/root\\/.oh-my-zsh/\\/home\\/$USERNAME\\/.oh-my-zsh/g" /home/$USERNAME/.zshrc
                chown -R $USER_UID:$USER_GID /home/$USERNAME/.oh-my-zsh /home/$USERNAME/.zshrc
            fi
            """

            static let nodeDebian = """
            #!/usr/bin/env bash
            #-------------------------------------------------------------------------------------------------------------
            # Copyright (c) Microsoft Corporation. All rights reserved.
            # Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
            #-------------------------------------------------------------------------------------------------------------

            # Syntax: ./node-debian.sh <directory to install nvm> <node version to install (use "none" to skip)> <non-root user>

            set -e

            export NVM_DIR=${1:-"/usr/local/share/nvm"}
            export NODE_VERSION=${2:-"lts/*"}
            NONROOT_USER=${3:-"vscode"}

            if [ "$(id -u)" -ne 0 ]; then
                echo 'Script must be run a root. Use sudo or set "USER root" before running the script.'
                exit 1
            fi

            # Ensure apt is in non-interactive to avoid prompts
            export DEBIAN_FRONTEND=noninteractive

            if [ "${NODE_VERSION}" = "none" ]; then
                export NODE_VERSION=
            fi

            # Install NVM
            mkdir -p ${NVM_DIR}
            curl -so- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash 2>&1
            if [ "${NODE_VERSION}" != "" ]; then
                /bin/bash -c "source $NVM_DIR/nvm.sh && nvm alias default ${NODE_VERSION}" 2>&1
            fi

            echo -e "export NVM_DIR=\"${NVM_DIR}\"\n\
            [ -s \"\\$NVM_DIR/nvm.sh\" ] && \\. \"\\$NVM_DIR/nvm.sh\"\n\
            [ -s \"\\$NVM_DIR/bash_completion\" ] && \\. \"\\$NVM_DIR/bash_completion\"" \
            | tee -a /home/${NONROOT_USER}/.bashrc /home/${NONROOT_USER}/.zshrc >> /root/.zshrc

            echo -e "if [ \"\\$(stat -c '%U' \'$NVM_DIR)\" != \"${NONROOT_USER}\" ]; then\n\
                sudo chown -R ${NONROOT_USER}:root \\$NVM_DIR\n\
            fi" | tee -a /root/.bashrc /root/.zshrc /home/${NONROOT_USER}/.bashrc >> /home/${NONROOT_USER}/.zshrc

            chown ${NONROOT_USER}:${NONROOT_USER} /home/${NONROOT_USER}/.bashrc /home/${NONROOT_USER}/.zshrc
            chown -R ${NONROOT_USER}:root ${NVM_DIR}

            # Install yarn
            curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - 2>/dev/null
            echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
            apt-get update
            apt-get -y install --no-install-recommends yarn

            """
        }
    }
}
