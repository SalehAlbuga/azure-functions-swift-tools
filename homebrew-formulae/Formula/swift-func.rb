class SwiftFunc < Formula
    desc "Azure Functions for Swift CLI tools"
    homepage "https://github.com/SalehAlbuga/azure-functions-swift-tools"
    url "https://github.com/SalehAlbuga/azure-functions-swift-tools.git", :branch => "dev", :tag => "v0.0.8-dev"
    sha256 "1be333b8311a1b1504804025e3f57a8fac0317fdecfe9ccb404ef4297581e5fe"

    depends_on :xcode => ["11.0", :build]
  
    def install    
      system "make", "install", "prefix=#{prefix}"
    end
  
    test do
       system "false"
    end
  end
  