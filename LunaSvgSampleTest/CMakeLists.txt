cmake_minimum_required(VERSION 3.6)

set(CMAKE_SUPPRESS_REGENERATION ON BOOL)
set(CMAKE_SKIP_INSTALL_ALL_DEPENDENCY ON BOOL)
set(CMAKE_SKIP_PACKAGE_ALL_DEPENDENCY ON BOOL)

# CMake appends the configurationType (e.g. MinSizeRel) as a folder suffix to the output path
# when using the VS generator (not Ninja), which is silly and redundant, because the configuration
# type is already an implicit part of the given configuration in CMakeSettings.json. However,
# passing an empty string will not defeat this behavior, but passing a genenarator that yields
# an empty string works. Sigh, Cmake. This is problematic because ${CMAKE_CURRENT_BINARY_DIR}
# doesn't properly resolve to the correct location. I'm unsure if it's a bug in CMake or bad
# design or I'm supposed to be using a different one of thirty possible magic variables, but
# I don't have time to waste on bad build systems. So, here...
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "$<0:DummyString>")
set(CMAKE_RUNTIME_ARCHIVE_DIRECTORY "$<0:DummyString>")
set(CMAKE_RUNTIME_LIBRARY_DIRECTORY "$<0:DummyString>")

project(LunaSvgTest VERSION 1.0.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_C_STANDARD 11)

set(BUILD_SHARED_LIBS OFF)

set(PLUTOVG_BGRA_PIXEL_ORDER ON CACHE BOOL "Use BGRA order instead of RGBA, useful for Windows GDI." FORCE)
add_subdirectory(external/lunasvg)

add_executable(LunaSvgTest
    source/precomp.h
    source/Common.h
    source/Common.cpp
    #source/RenderView.h
    #source/RenderView.cpp
    source/LunaSvgTest.h
    source/LunaSvgTest.cpp
    #source/EditingWindow.h
    #source/EditingWindow.cpp
    resources/LunaSvgTest.rc
    resources/LunaSvgTest.manifest
)
add_dependencies(LunaSvgTest lunasvg)
target_link_libraries(LunaSvgTest lunasvg gdiplus.lib windowscodecs.lib)
target_include_directories(LunaSvgTest PRIVATE resources)
target_precompile_headers(LunaSvgTest PRIVATE source/precomp.h)
set_target_properties(
    LunaSvgTest
    PROPERTIES
        WIN32_EXECUTABLE TRUE
        MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"
)

message(PROJECT_SOURCE_DIR="${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
message(CMAKE_CURRENT_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}")
message(CMAKE_CURRENT_BINARY_DIR="${CMAKE_CURRENT_BINARY_DIR}")
message(RUNTIME_OUTPUT_DIRECTORY="${RUNTIME_OUTPUT_DIRECTORY}")

#set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT LunaSvgTest)

if(WIN32)
    set(CMAKE_SHARED_LINKER_FLAGS /MANIFEST:NO)
endif(WIN32)

# This is needed for the Ninja generator for some reason (shrug), but using MS Build instead doesn't need it.
# Also, this arcanery is not intuitive at all.
#add_custom_command(
#    TARGET
#        LunaSvgTest
#    POST_BUILD
#    COMMAND
#        "mt.exe" -manifest \"${CMAKE_CURRENT_SOURCE_DIR}\\resources\\LunaSvgTest.manifest\" -outputresource:\"${CMAKE_CURRENT_BINARY_DIR}\\LunaSvgTest.exe\"\;\#2
#    COMMENT
#        "Adding custom manifest containing MSVCRT80 dependency..." 
#)
