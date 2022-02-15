cmake_minimum_required(VERSION 3.3)

project(lunasvgtest VERSION 1.0.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_C_STANDARD 11)

#set(BUILD_SHARED_LIBS ON)

add_subdirectory(source)
add_subdirectory(lunasvg)
