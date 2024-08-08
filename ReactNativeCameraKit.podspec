require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = "ReactNativeCameraKit"
  s.version      = package["version"]
  s.summary      = "Advanced native camera and gallery controls and device photos API"
  s.license      = "MIT"

  s.authors      = "CameraKit"
  s.homepage     = "https://github.com/teslamotors/react-native-camera-kit"
  s.platform     = :ios, "11.0"

  s.source       = { :git => "https://github.com/teslamotors/react-native-camera-kit.git", :tag => "v#{s.version}" }
  s.source_files  = "ios/**/*.{h,m,mm,swift}"
  s.private_header_files = 'ios/ReactNativeCameraKit/ReactNativeCameraKit-Swift.pre.h'

  if ENV['USE_FRAMEWORKS']
    exisiting_flags = s.attributes_hash["compiler_flags"]
      if exisiting_flags.present?
        s.compiler_flags = exisiting_flags + "-DCK_USE_FRAMEWORKS=1"
      else
        s.compiler_flags = "-DCK_USE_FRAMEWORKS=1"
      end
  end

  if defined?(install_modules_dependencies()) != nil
    install_modules_dependencies(s)
  else
    s.dependency 'React-Core'
  end

end
