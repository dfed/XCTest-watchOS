Pod::Spec.new do |s|
  s.name     = 'XCTest-watchOS'
  s.version  = '0.0.1'
  s.license  = 'Apache License, Version 2.0'
  s.summary  = 'An implementation of XCTest for watchOS'
  s.homepage = 'https://github.com/dfed/XCTest-watchOS'
  s.authors  = 'Dan Federman'
  s.source   = { :git => 'https://github.com/dfed/XCTest-watchOS.git', :tag => s.version }
  s.source_files = 'Sources/**/*.{swift,h}'
  s.public_header_files = 'Sources/*.h'
  s.watchos.deployment_target = '2.0'
end
