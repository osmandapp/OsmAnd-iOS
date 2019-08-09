source "https://github.com/CocoaPods/Specs.git"

platform :ios, '9.3'

project   'OsmAnd'
workspace 'OsmAnd'

def defaultPods
    pod 'AFNetworking', '~> 2.5.1'
    pod 'AFDownloadRequestOperation', '~> 2.0.1'
    pod 'JASidePanels', '~> 1.3.2'
    pod 'Reachability', '~> 3.1.1'
    pod 'UIAlertView-Blocks', '~> 1.0'
    pod 'UIActionSheet-Blocks', '~> 1.0.1'
    pod 'DACircularProgress', '~> 2.2.0'
    pod 'FFCircularProgressView', '~> 0.4'
    pod 'QuickDialog', :subspecs => ["Core", "Extras"], :git => 'https://github.com/escoz/QuickDialog.git'
    pod 'FormatterKit', '~> 1.8.0'
    pod 'SWTableViewCell', '~> 0.3.7'
    pod 'RegexKitLite', '~> 4.0'
    pod 'MBProgressHUD', '~> 0.9.1'
    pod 'CocoaSecurity', '~> 1.2.4'
    pod 'TPKeyboardAvoiding', '~> 1.2.6'
    pod 'HTAutocompleteTextField', '~> 1.3.1'
    pod 'Firebase/Core', '~> 4.0.0'
    pod 'MaterialComponents/TextFields', '~> 84.0.0'
    pod 'BRCybertron', '~> 1.1.1'
end

target 'OsmAnd Maps' do
    defaultPods
end

target 'OsmAnd Maps DEV' do
    defaultPods
end

# Make changes to Pods.xcconfig: 
#  - HEADER_SEARCH_PATHS need to inherit project settings
#  - 'libPods.a' needs $(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)
#  - Force architectures to '$(ARCHS_STANDARD)'
#  - Build all architectures for Pods
post_install do |installer|
    workDir = Dir.pwd

    # CocoaPods pre-0.34
    if File.exist?("#{workDir}/Pods/Pods.xcconfig")
        adjustConfigFile("#{workDir}/Pods/Pods.xcconfig")
    end
    if File.exist?("#{workDir}/Pods/Pods-dev.xcconfig")
        adjustConfigFile("#{workDir}/Pods/Pods-dev.xcconfig")
    end

    # CocoaPods pre-0.34+
    if File.exist?("#{workDir}/Pods/Target Support Files/Pods")
        adjustConfigFile("#{workDir}/Pods/Target Support Files/Pods/Pods.debug.xcconfig")
        adjustConfigFile("#{workDir}/Pods/Target Support Files/Pods/Pods.release.xcconfig")
    end
    if File.exist?("#{workDir}/Pods/Target Support Files/Pods-dev")
        adjustConfigFile("#{workDir}/Pods/Target Support Files/Pods-dev/Pods-dev.debug.xcconfig")
        adjustConfigFile("#{workDir}/Pods/Target Support Files/Pods-dev/Pods-dev.release.xcconfig")
    end

    #installer.project.targets.each do |target|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |configuration|
            configuration.build_settings['ARCHS'] = '$(ARCHS_STANDARD)'
            configuration.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
            configuration.build_settings['CONFIGURATION_BUILD_DIR'] = '${PROJECT_DIR}/../../binaries/ios.clang${EFFECTIVE_PLATFORM_NAME}/$(CONFIGURATION)'
        end
    end
end
def adjustConfigFile(xcconfigFilename)
    xcconfig = File.read(xcconfigFilename)
    xcconfig = xcconfig.gsub(/HEADER_SEARCH_PATHS = "/, "HEADER_SEARCH_PATHS = $(inherited) \"")
    xcconfig = xcconfig.gsub(/LIBRARY_SEARCH_PATHS = "/, "LIBRARY_SEARCH_PATHS = $(inherited) \"")
    xcconfig = xcconfig.gsub(/FRAMEWORK_SEARCH_PATHS = "/, "FRAMEWORK_SEARCH_PATHS = $(inherited) \"")
    xcconfig = xcconfig.gsub(/OTHER_CFLAGS = "/, "OTHER_CFLAGS = $(inherited) \"")
    xcconfig = xcconfig.gsub(/OTHER_LDFLAGS = "/, "OTHER_LDFLAGS = $(inherited) \"")
    File.open(xcconfigFilename, "w") { |file| file << xcconfig }
end
