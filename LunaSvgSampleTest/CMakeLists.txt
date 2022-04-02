cmake_minimum_required(VERSION 3.4)

project(LunaSvgTest VERSION 1.0.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_C_STANDARD 11)

set(BUILD_SHARED_LIBS OFF)

set(PLUTOVG_BGRA_PIXEL_ORDER ON CACHE BOOL "Use BGRA order instead of RGBA, useful for Windows GDI." FORCE)
add_subdirectory(external/lunasvg)

add_executable(LunaSvgTest source/LunaSvgTest.cpp source/LunaSvgTest.h resources/LunaSvgTest.rc resources/LunaSvgTest.manifest)
add_dependencies(LunaSvgTest lunasvg)
target_link_libraries(LunaSvgTest lunasvg)
set_target_properties(LunaSvgTest PROPERTIES WIN32_EXECUTABLE TRUE)
set_property(TARGET LunaSvgTest PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
target_include_directories(LunaSvgTest PRIVATE resources)

if(WIN32)
    set(CMAKE_SHARED_LINKER_FLAGS /MANIFEST:NO)
endif(WIN32)

# This arcanery is not intuitive at all.
add_custom_command(
    TARGET
        LunaSvgTest
    POST_BUILD
    COMMAND
        "mt.exe" -manifest \"${CMAKE_CURRENT_SOURCE_DIR}\\resources\\LunaSvgTest.manifest\" -outputresource:\"${CMAKE_CURRENT_BINARY_DIR}\\LunaSvgTest.exe\"\;\#2
    COMMENT
        "Adding custom manifest containing MSVCRT80 dependency..." 
)
