# ANGLE headers

Khronos EGL/GLES headers plus ANGLE's own extension header, taken verbatim from an ANGLE
checkout (`include/` — EGL, GLES2, GLES3, KHR).

They are used only when `OSMAND_USE_ANGLE` is defined, which is currently limited to the
iOS Simulator SDK — see `GCC_PREPROCESSOR_DEFINITIONS[sdk=iphonesimulator*]`. The Simulator
serves native GLES through a software rasteriser ("Apple Software Renderer"), so the map runs
at about 1 fps there; ANGLE routes the same GLES calls to Metal, which the Simulator does
accelerate. Device builds keep using EAGL and never include these.

The matching binaries (libEGL/libGLESv2 XCFrameworks) are built separately from the same
ANGLE checkout and are not part of this directory.
