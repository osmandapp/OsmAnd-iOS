set -eo pipefail

xcodebuild -workspace OsmAnd.xcworkspace \
            -scheme OsmAnd\ iOS \
            -destination platform=iOS\ Simulator,OS=13.3,name=iPhone\ 11 \
            clean test | xcpretty