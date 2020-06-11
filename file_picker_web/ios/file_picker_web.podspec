#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
    s.name             = 'file_picker_web'
    s.version          = '0.0.1'
    s.summary          = 'No-op implementation of file_picker_web web plugin to avoid build issues on iOS'
    s.description      = <<-DESC
  temp fake video_player_web plugin
                         DESC
    s.homepage         = 'https://github.com/miguelpruivo/plugins_flutter_file_picker/file_picker_web'
    s.license          = { :file => '../LICENSE' }
    s.author           = { 'Miguel Ruivo' => 'miguel@miguelruivo.com' }
    s.source           = { :path => '.' }
    s.source_files = 'Classes/**/*'
    s.public_header_files = 'Classes/**/*.h'
    s.dependency 'Flutter'
  
    s.ios.deployment_target = '8.0'
  end