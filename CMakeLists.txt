cmake_minimum_required(VERSION 3.10)

if(NOT SMOKE_QT_VERSION)
   project(commonqt LANGUAGES CXX)
   set(COMMONQT commonqt)
   set(SMOKE_QT_VERSION 5)
elseif (${SMOKE_QT_VERSION} EQUAL 6)
   project(commonqt6 LANGUAGES CXX)
   set(COMMONQT commonqt6)
endif()

set(CMAKE_INCLUDE_CURRENT_DIR OFF)
set(CMAKE_AUTOMOC OFF)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(QT_VERSION Qt${SMOKE_QT_VERSION})

if (NOT DEFINED Qt_ROOT_DIR)
   if (Qt5_DIR)
      string(REPLACE "/lib/cmake/Qt5" "" Qt_ROOT_DIR ${Qt5_DIR})
      string(REPLACE "\\lib\\cmake\\Qt5" "" Qt_ROOT_DIR ${Qt_ROOT_DIR})
   elseif(Qt6_DIR)
      string(REPLACE "/lib/cmake/Qt6" "" Qt_ROOT_DIR ${Qt6_DIR})
      string(REPLACE "\\lib\\cmake\\Qt6" "" Qt_ROOT_DIR ${Qt_ROOT_DIR})
   else()
      message(FATAL_ERROR "Qt_ROOT_DIR not defined and could not be determined from Qt6_DIR or Qt5_DIR")
   endif()
endif()

message(STATUS "Qt_ROOT_DIR = ${Qt_ROOT_DIR}")

find_package(${QT_VERSION} COMPONENTS Core REQUIRED)
find_package(${QT_VERSION}
   COMPONENTS
   Gui
   Widgets
   REQUIRED
)
find_package(${QT_VERSION}PrintSupport REQUIRED)

if(NOT DEFINED SMOKE_BASE)
   message(FATAL_ERROR "SMOKE_BASE not defined. Please pass -DSMOKE_BASE=<path> to CMake")
endif()

if(NOT DEFINED SMOKE_QT)
   message(FATAL_ERROR "SMOKE_QT not defined. Please pass -DSMOKE_QT=<path> to CMake")
endif()

if (Qt6_FOUND)
   set(QT_CORE_VERSION ${Qt6Core_VERSION})
else()
   set(QT_CORE_VERSION ${Qt5Core_VERSION})
endif()

message(STATUS "Found ${QT_VERSION}: version ${QT_CORE_VERSION}")

message(STATUS "Found Smoke base at: ${SMOKE_BASE}")
message(STATUS "Found SmokeQt at: ${SMOKE_QT}")

include_directories(${Qt_ROOT_DIR}/include/QtCore/${QT_CORE_VERSION}
                    ${Qt_ROOT_DIR}/include/QtCore/${QT_CORE_VERSION}/QtCore
                    ${Qt_ROOT_DIR}/include/QtCore/${QT_CORE_VERSION}/QtCore/private
                    ${SMOKE_BASE}/include
	            ${SMOKE_QT}/include)

link_directories(${SMOKE_BASE}/lib ${SMOKE_QT}/lib)

# Qt6: also compile std::function bridge code into the main library
set(COMMONQT_SOURCES commonqt.cpp)
if (Qt6_FOUND)
   list(APPEND COMMONQT_SOURCES qwebengine-std-function.cpp)
endif()

add_library(${COMMONQT} SHARED ${COMMONQT_SOURCES})

target_include_directories(${COMMONQT} BEFORE PRIVATE ${Qt_ROOT_DIR}/include/QtCore/${QT_CORE_VERSION}/QtCore/private)

if (Qt6_FOUND)
   # Ensure WebEngineCore target is available
   find_package(${QT_VERSION} COMPONENTS WebEngineCore REQUIRED)
   target_link_libraries(${COMMONQT} smokeqt6core smokebase ${QT_VERSION}::Widgets ${QT_VERSION}::PrintSupport ${QT_VERSION}::WebEngineCore)
else()
   target_link_libraries(${COMMONQT} smokeqtcore smokebase ${QT_VERSION}::Widgets ${QT_VERSION}::PrintSupport)
endif()

string(REPLACE "." ";" VERSION_LIST ${QT_CORE_VERSION})
list(GET VERSION_LIST 0 VERSION_MAJOR)
list(GET VERSION_LIST 1 VERSION_MINOR)
list(GET VERSION_LIST 2 VERSION_PATCH)

set_target_properties(${COMMONQT}
    PROPERTIES
    VERSION ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}
    SOVERSION ${VERSION_MAJOR}
    CXX_STANDARD 17
)

if(WIN32)
   install( TARGETS ${COMMONQT} RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
else()
   install( TARGETS ${COMMONQT} RUNTIME DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
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

