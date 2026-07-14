source "https://github.com/CocoaPods/Specs.git"

platform :ios, '15.0'

project 'OsmAnd'
workspace 'OsmAnd'

def defaultPods
end


target 'OsmAnd Maps' do
    defaultPods
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |configuration|
            configuration.build_settings['ARCHS'] = '$(ARCHS_STANDARD)'
            configuration.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
            configuration.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
        end
    end
end
