cmake_minimum_required(VERSION 3.3)

project(lunasvgtest VERSION 1.0.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_C_STANDARD 11)

#set(BUILD_SHARED_LIBS ON)

add_executable(lunasvgtest LunaSvgTest.cpp LunaSvgTest.h LunaSvgTest.rc)
add_dependencies(lunasvgtest lunasvg)
target_link_libraries(lunasvgtest lunasvg)
##set_target_properties(${BINARY_NAME} PROPERTY WIN32_EXECUTABLE TRUE)
set_target_properties(lunasvgtest PROPERTIES WIN32_EXECUTABLE TRUE)
