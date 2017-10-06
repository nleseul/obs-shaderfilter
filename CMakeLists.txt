cmake_minimum_required (VERSION 2.8.12)
project (obs-shaderfilter)

if (OBSSourcePath OR DEFINED ENV{OBSSourcePath})
    # Set already
else()
    set(OBSSourcePath "" CACHE PATH "Path to OBS source code (e.g., C:/Dev/obs-studio/libobs/)")
    message("OBSSourcePath is missing. Please set this variable to the location of the OBS source (e.g., C:/Dev/obs-studio/libobs/).")
endif()

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
	set(_lib_suffix 64)
else()
	set(_lib_suffix 32)
endif()

find_path(OBS_LIB_DIR
    NAMES obs.dll obs.lib
    HINTS
        ${OBSSourcePath}/../build${_lib_suffix}/libobs/Release/
        ${OBSSourcePath}/../build/libobs/Release/
        ${OBSSourcePath}/../build${_lib_suffix}/libobs/Debug/
        ${OBSSourcePath}/../build/libobs/Debug/
    PATHS
		/usr/lib /usr/local/lib /opt/local/lib /sw/lib)
        
# Source
file (GLOB SOURCES ${CMAKE_SOURCE_DIR}/src/*.c)

include_directories (include ${CMAKE_BINARY_DIR}/config)
add_library (${PROJECT_NAME} SHARED
	${SOURCES}
	${HEADER_FILES}
)

# libobs
include_directories(${OBSSourcePath})
add_library (libobs SHARED IMPORTED)
set_property (TARGET libobs PROPERTY IMPORTED_LOCATION ${OBS_LIB_DIR}/obs.dll)
set_property (TARGET libobs PROPERTY IMPORTED_IMPLIB ${OBS_LIB_DIR}/obs.lib)
target_link_libraries (${PROJECT_NAME} libobs)

install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION obs-plugins/${_lib_suffix}bit)
install(FILES ${CMAKE_BINARY_DIR}/Debug/${PROJECT_NAME}.pdb DESTINATION obs-plugins/${_lib_suffix}bit CONFIGURATIONS Debug)
install(DIRECTORY data/ DESTINATION data/obs-plugins/${PROJECT_NAME}/)
