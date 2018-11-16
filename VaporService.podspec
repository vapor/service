

#
#  Be sure to run `pod spec lint Service.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "VaporService"
  s.version      = "1.0.0"
  s.summary      = "Dependency injection / inversion of control framework."

  s.description  = <<-DESC
    Dependency injection / inversion of control framework used in Vapor.
  DESC

  s.homepage     = "https://github.com/vapor/service"
  s.license      = { :type => "MIT", :file => "LICENSE.txt" }

  s.author             = { "Tanner Nelson" => "" }

  s.ios.deployment_target = "10.0"

  s.source       = { :git => "https://github.com/twof/service.git", :branch => "master" }

  s.source_files  = "Sources/Service/**/*.swift"
  s.module_name = "Service"
  
  s.swift_version = "4.2"

  s.dependency "VaporCore"
end
