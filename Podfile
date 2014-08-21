platform :ios, '6.0'

xcodeproj 'OsmAnd'
workspace 'OsmAnd'

link_with 'OsmAnd'
pod 'AFNetworking', '~> 2.3.1'
pod 'AFDownloadRequestOperation', '~> 2.0.1'
pod 'JASidePanels', '~> 1.3.2'
pod 'Reachability', '~> 3.1.1'
pod 'UIAlertView-Blocks', '~> 1.0'
pod 'UIActionSheet-Blocks', '~> 1.0.1'
pod 'DACircularProgress', '~> 2.2.0'
pod 'FFCircularProgressView', '~> 0.4'
pod 'QuickDialog/Core', '~> 1.0'
pod 'QuickDialog/Extras', '~> 1.0'
pod 'FormatterKit', '~> 1.5.3'
pod 'SWTableViewCell', '~> 0.3.0'
pod 'RegexKitLite', '~> 4.0'
pod 'MBProgressHUD', '~> 0.9'
pod 'CocoaSecurity', '~> 1.2.4'

# Development-only dependencies
target :dev do
    link_with 'OsmAnd DEV', 'OsmAnd DEV (prebuilt Core)'

    pod 'TestFlightSDK', '~> 3.0.2'
end

# Make changes to Pods.xcconfig: 
#  - HEADER_SEARCH_PATHS need to inherit project settings
#  - 'libPods.a' needs $(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)
#  - Force architectures to '$(ARCHS_STANDARD_32_BIT)'
#  - Build all architectures for Pods
post_install do |installer_representation|
    workDir = Dir.pwd
    adjustConfigFile("#{workDir}/Pods/Pods.xcconfig")
    adjustConfigFile("#{workDir}/Pods/Pods-dev.xcconfig")

    installer_representation.project.targets.each do |target|
        target.build_configurations.each do |configuration|
            configuration.build_settings['ARCHS'] = '$(ARCHS_STANDARD_32_BIT)'
            configuration.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        end
    end
end
def adjustConfigFile(xcconfigFilename)
    xcconfig = File.read(xcconfigFilename)
    xcconfig = xcconfig.gsub(/HEADER_SEARCH_PATHS = "/, "HEADER_SEARCH_PATHS = $(inherited) \"")
    xcconfig = xcconfig.gsub(/LIBRARY_SEARCH_PATHS = "/, "LIBRARY_SEARCH_PATHS = $(inherited) \"$(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)\" \"")
    File.open(xcconfigFilename, "w") { |file| file << xcconfig }
end
