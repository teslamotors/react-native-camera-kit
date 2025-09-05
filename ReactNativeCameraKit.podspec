require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = "ReactNativeCameraKit"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.license      = "MIT"

  s.authors      = "CameraKit"
  s.homepage     = "https://github.com/teslamotors/react-native-camera-kit"
  s.platform     = :ios, "15.0"

  s.source       = { :git => "https://github.com/teslamotors/react-native-camera-kit.git", :tag => "v#{s.version}" }
  s.source_files = [
    # Exclude .h files as they cause Swift compiler to treat them as C files, but they are C++
    # See https://github.com/facebook/react-native/issues/45424#issuecomment-2354737063
    "ios/ReactNativeCameraKit/*.{m,swift,mm}",
    "ios/generated/rncamerakit_specs/*.{m,mm,cpp}",
  ]

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
