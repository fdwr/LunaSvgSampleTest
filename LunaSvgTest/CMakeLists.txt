cmake_minimum_required(VERSION 3.3)

project(LunaSvgTest VERSION 1.0.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)

#set(BUILD_SHARED_LIBS ON)

set(PLUTOVG_BGRA_PIXEL_ORDER ON CACHE BOOL "Use BGRA order instead of RGBA, useful for Windows GDI." FORCE)
add_subdirectory(external/lunasvg)

add_executable(LunaSvgTest source/LunaSvgTest.cpp source/LunaSvgTest.h resources/LunaSvgTest.rc)
add_dependencies(LunaSvgTest lunasvg)
target_link_libraries(LunaSvgTest lunasvg)
set_target_properties(LunaSvgTest PROPERTIES WIN32_EXECUTABLE TRUE)
target_include_directories(LunaSvgTest PRIVATE resources)
