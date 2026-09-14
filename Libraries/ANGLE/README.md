# ANGLE headers

`include/` holds the Khronos EGL/GLES headers plus ANGLE's own extension headers, taken
verbatim from an ANGLE checkout (EGL, GLES2, GLES3, KHR). Like the externals under `core`,
they are upstream files and are **not** kept in the repository - `prepare.sh` downloads them
together with the prebuilt frameworks, and `.gitignore` excludes them. Only this README and
`patches/` are tracked here.

They are used only when `OSMAND_USE_ANGLE` is defined, which is currently limited to the
iOS Simulator SDK — see `GCC_PREPROCESSOR_DEFINITIONS[sdk=iphonesimulator*]`. The Simulator
serves native GLES through a software rasteriser ("Apple Software Renderer"), so the map runs
at about 1 fps there; ANGLE routes the same GLES calls to Metal, which the Simulator does
accelerate. Device builds keep using EAGL and never include these.

The matching binaries (libEGL/libGLESv2 XCFrameworks) are built separately from the same
ANGLE checkout and are not part of this directory.

## Patches

`patches/simulator-uniform-alignment.patch` must be applied to the ANGLE checkout before
building the binaries. Without it the Simulator aborts on the first draw whose uniform offset
grows past a multiple of 256:

    -[MTLDebugRenderCommandEncoder validateCommonDrawErrors:] failed assertion
    Vertex Function(main0): the offset into the buffer ANGLE_userUniforms that is bound at
    Buffer index 19 must be a multiple of 256 but was set to 9840.

ANGLE picks the constant buffer offset alignment from `TARGET_OS_OSX || TARGET_OS_MACCATALYST`.
The iOS Simulator is neither, so it takes the 4-byte iOS value - but it runs on the macOS Metal
driver, which enforces 256. The patch adds `TARGET_OS_SIMULATOR` to that condition.

This is an upstream bug and has not been reported; the patch is kept here so a rebuild does not
silently lose it.

## Rebuilding the binaries

    git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
    export PATH="$PWD/depot_tools:$PATH"
    mkdir angle && cd angle && fetch --no-history angle    # ~13 GB
    git apply .../patches/simulator-uniform-alignment.patch

Then, per platform, with `target_environment = "simulator"` or `"device"`:

    gn gen out/ios-sim --args='target_os="ios" target_cpu="arm64"
        target_environment="simulator" is_debug=false ios_enable_code_signing=false
        angle_enable_metal=true angle_enable_vulkan=false angle_enable_null=false
        angle_enable_cl=false angle_build_tests=false ios_deployment_target="15.0"'
    autoninja -C out/ios-sim libEGL libGLESv2

Combine the two into XCFrameworks with `xcodebuild -create-xcframework`, zip them, and upload
as `builder.osmand.net/binaries/ios/angle-ios-prebuilt.zip`.
