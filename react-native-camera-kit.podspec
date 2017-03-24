require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name           = 'react-native-camera-kit'
  s.version        = package['version']
  s.summary        = package['description']
  s.description    = package['description']
  s.license        = package['license']
  s.author         = package['author']
  s.homepage       = package['homepage']
  s.source         = { :git => 'https://github.com/wix/react-native-camera-kit', :tag => s.version }

  s.requires_arc   = true
  s.platform       = :ios, '8.0'

  s.preserve_paths = 'LICENSE', 'README.md', 'package.json', 'CameraKitCamera.android.js', 'CameraKitCamera.ios.js', 'CameraKitGallery.android.js', 'CameraKitGallery.ios.js', 'CameraKitGalleryView.android.js', 'CameraKitGalleryView.ios.js'

  s.source_files   = 'ios/lib/ReactNativeCameraKit/*.{h,m}'

  s.dependency 'React'
end
