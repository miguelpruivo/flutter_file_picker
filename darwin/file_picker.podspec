#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name                  = 'file_picker'
  s.version               = '0.0.1'
  s.summary               = 'A flutter plugin to show native file picker dialogs'
  s.description           = <<-DESC
A flutter plugin to show native file picker dialogs.
                       DESC
  s.homepage              = 'https://github.com/miguelpruivo/plugins_flutter_file_picker'
  s.license               = { :file => '../LICENSE' }
  s.author                = 'Miguel Ruivo'
  s.source                = { :path => '.' }
  s.source_files = 'file_picker/Sources/file_picker/**/*.swift'
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '14.0'
  s.osx.deployment_target = '10.13'
  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  s.resource_bundles = {'file_picker_privacy' => ['file_picker/Sources/file_picker/PrivacyInfo.xcprivacy']}
end
