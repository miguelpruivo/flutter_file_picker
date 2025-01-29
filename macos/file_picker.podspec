#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint file_picker.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'file_picker'
  s.version          = '0.0.1'
  s.summary          = 'A flutter plugin to show native file picker dialogs'
  s.description      = <<-DESC
A flutter plugin to show native file picker dialogs
                       DESC
  s.homepage         = 'https://github.com/miguelpruivo/plugins_flutter_file_picker'
  s.license          = { :file => '../LICENSE' }
  s.author           = 'Miguel Ruivo, Dominik Roszkowski'
  s.source           = { :path => '.' }
  s.source_files = 'file_picker/Sources/**/*.swift'

  s.resource_bundles = {'file_picker_privacy' => ['file_picker/Sources/file_picker/PrivacyInfo.xcprivacy']}

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.13'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
