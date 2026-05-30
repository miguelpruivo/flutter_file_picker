# Copied podspec for shared Darwin sources
Pod::Spec.new do |s|
  s.name             = 'file_picker_apple'
  s.version          = '0.0.1'
  s.summary          = 'A flutter plugin to show native file picker dialogs'
  s.description      = <<-DESC
A flutter plugin to show native file picker dialogs
                       DESC
  s.homepage         = 'https://github.com/miguelpruivo/plugins_flutter_file_picker'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Miguel Ruivo, Dominik Roszkowski'
  s.source           = { :path => '.' }
  s.source_files     = 'file_picker_apple/Sources/**/*.swift'

  s.resource_bundles = {
    'file_picker_apple_privacy' => ['file_picker_apple/Sources/file_picker_apple/PrivacyInfo.xcprivacy']
  }

  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '14.0'
  s.osx.deployment_target = '10.13'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end