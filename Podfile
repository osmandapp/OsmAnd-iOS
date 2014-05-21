platform :ios, '6.0'

xcodeproj 'OsmAnd'
workspace 'OsmAnd'

link_with 'OsmAnd', 'OsmAnd (prebuilt Core)'

pod 'AFNetworking', '~> 2.2.3'
pod 'AFDownloadRequestOperation', '~> 2.0.1'
pod 'JASidePanels', '~> 1.3.2'
pod 'Reachability', '~> 3.1.1'
pod 'TestFlightSDK', '~> 3.0.2'
pod 'UIAlertView-Blocks', '~> 1.0'
pod 'DACircularProgress', '~> 2.2.0'
pod 'FFCircularProgressView', '~> 0.4'
pod 'QuickDialog', '~> 1.0'

# Make changes to Pods.xcconfig : 
#  - HEADER_SEARCH_PATHS need to inherit project settings
# - 'libPods.a' needs $(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)
post_install do |installer_representation|
    workDir = Dir.pwd
    xcconfigFilename = "#{workDir}/Pods/Pods.xcconfig"
    xcconfig = File.read(xcconfigFilename)
    xcconfig = xcconfig.gsub(/HEADER_SEARCH_PATHS = "/, "HEADER_SEARCH_PATHS = $(inherited) \"")
    xcconfig = xcconfig.gsub(/LIBRARY_SEARCH_PATHS = "/, "LIBRARY_SEARCH_PATHS = $(inherited) \"$(BUILD_DIR)/$(CONFIGURATION)$(EFFECTIVE_PLATFORM_NAME)\" \"")
    File.open(xcconfigFilename, "w") { |file| file << xcconfig }
end
