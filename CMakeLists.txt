cmake_minimum_required(VERSION 3.13...4.2)

project(commonqt6 LANGUAGES CXX)
set(CMAKE_INCLUDE_CURRENT_DIR OFF)
set(CMAKE_AUTOMOC OFF)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(QT_NO_PRIVATE_MODULE_WARNING ON)

find_package(Qt6 COMPONENTS Core CorePrivate Gui Widgets REQUIRED)
find_package(Qt6PrintSupport REQUIRED )
find_package(Smoke REQUIRED)

message(STATUS "Found Qt6 ${Qt6_FOUND}: version ${Qt6Core_VERSION}") 

include_directories(${SMOKE_INCLUDE_DIR} ${CMAKE_INSTALL_PREFIX}/include)
link_directories(${SMOKE_INSTALL_PREFIX}/lib ${CMAKE_INSTALL_PREFIX}/lib)
add_library(commonqt6 SHARED commonqt.cpp)
target_link_libraries(commonqt6 smokeqt6core smokebase Qt6::Widgets Qt6::PrintSupport Qt6::CorePrivate)

string(REPLACE "." ";" VERSION_LIST ${Qt6Core_VERSION})
list(GET VERSION_LIST 0 VERSION_MAJOR)
list(GET VERSION_LIST 1 VERSION_MINOR)
list(GET VERSION_LIST 2 VERSION_PATCH)

set_target_properties(commonqt6
    PROPERTIES
    VERSION ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}
    SOVERSION ${VERSION_MAJOR}
    CXX_STANDARD 17
)

if(WIN32)
   install( TARGETS commonqt6 RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
else()
   install( TARGETS commonqt6 RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
endif()

# Taken from https://gitlab.kitware.com/cmake/community/-/wikis/FAQ#can-i-do-make-uninstall-with-cmake
# uninstall target
if(NOT TARGET uninstall)
  configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    IMMEDIATE @ONLY)

  add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
endif()
