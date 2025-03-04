source 'https://gitlab.linphone.org/BC/public/podspec.git'
platform :ios, '15.0'

target 'Voip' do
  use_frameworks!
  pod 'linphone-sdk'
end


post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS[sdk=iphonesimulator*]"] = "arm64"
  end
end
