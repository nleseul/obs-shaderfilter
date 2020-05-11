project(obs-shaderfilter)

set(obs-shaderfilter_SOURCES
	src/obs-shaderfilter.c
	)

if(WIN32)
	set(MODULE_DESCRIPTION "OBS shaderfilter module")
	configure_file(${CMAKE_SOURCE_DIR}/cmake/winrc/obs-module.rc.in obs-shaderfilter.rc)
	list(APPEND obs-shaderfilter_SOURCES
		obs-shaderfilter.rc)
endif()

add_library(obs-shaderfilter MODULE
	${obs-shaderfilter_SOURCES})
target_link_libraries(obs-shaderfilter
	libobs)

install_obs_plugin_with_data(obs-shaderfilter data)
