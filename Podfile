# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'
use_frameworks!

def commonPods

end

def appPods
  pod 'CocoaLumberjack/Swift'
  pod 'CodableKeychain'
end

def testPods

end

target 'Afone' do
  appPods
end

target 'AfoneTests' do
  inherit! :search_paths
  testPods
end
