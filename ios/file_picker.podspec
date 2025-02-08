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
  s.source_files          = 'file_picker/Sources/**/*.{m,h}'
  s.public_header_files   = 'file_picker/Sources/file_picker/include/**/*.h'
  s.module_map            = 'file_picker/Sources/file_picker/include/file_picker.modulemap'
  
  s.ios.deployment_target = '12.0'

  s.dependency 'Flutter'

  preprocess_definitions=[]
  if !Pod.const_defined?(:PICKER_MEDIA) || PICKER_MEDIA
    preprocess_definitions << "PICKER_MEDIA=1"
    s.dependency 'DKImagePickerController/PhotoGallery'
  end
  if !Pod.const_defined?(:PICKER_AUDIO) || PICKER_AUDIO
    preprocess_definitions << "PICKER_AUDIO=1"
  end
  if !Pod.const_defined?(:PICKER_DOCUMENT) || PICKER_DOCUMENT
    preprocess_definitions << "PICKER_DOCUMENT=1"
  end
  s.pod_target_xcconfig = { "GCC_PREPROCESSOR_DEFINITIONS" => preprocess_definitions.join(' ') }
  s.resource_bundles = {'file_picker_ios_privacy' => ['file_picker/Sources/file_picker/PrivacyInfo.xcprivacy']}

end
