source "https://github.com/CocoaPods/Specs.git"

platform :ios, '15.0'

project 'OsmAnd'
workspace 'OsmAnd'

def defaultPods
    pod 'AFNetworking', '~> 2.7.0', :subspecs => ['Reachability', 'Serialization', 'Security', 'NSURLSession']
    pod 'JASidePanels', '~> 1.3.2'
    pod 'DACircularProgress', '~> 2.2.0'
    pod 'FFCircularProgressView', '~> 0.4'
    pod 'FormatterKit', '~> 1.8.0'
    pod 'SWTableViewCell', '~> 0.3.7'
    pod 'MBProgressHUD', '~> 0.9.1'
    pod 'CocoaSecurity', '~> 1.2.4'
    pod 'TPKeyboardAvoiding', '~> 1.2.6'
    pod 'HTAutocompleteTextField', '~> 1.3.1'
    pod 'MaterialComponents/TextFields', '~> 120.0.0'
    pod 'BRCybertron', '~> 1.1.1'
    pod 'MCBinaryHeap', '~> 0.1'
    pod 'TTRangeSlider', '~> 1.0.6'
    pod 'SwiftLint', '~> 0.52.4'
end

target 'OsmAnd Maps' do
    defaultPods
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |configuration|
            configuration.build_settings['ARCHS'] = '$(ARCHS_STANDARD)'
            configuration.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
            configuration.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
            #configuration.build_settings['CONFIGURATION_BUILD_DIR'] = '${PROJECT_DIR}/../../binaries/ios.clang${EFFECTIVE_PLATFORM_NAME}/$(CONFIGURATION)'
        end
    end
end

