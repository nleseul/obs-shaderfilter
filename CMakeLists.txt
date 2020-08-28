if (NOT WIN32)
	return()
endif()

project(obs-shaderfilter)

if(WIN32)
	set(MODULE_DESCRIPTION "OBS HLSL shader module")
	set(obs-shaderfilter_PLATFORM_SOURCES
		src/obs-shaderfilter.c)
endif()

add_library(obs-shaderfilter MODULE
	${obs-shaderfilter_PLATFORM_SOURCES})
target_link_libraries(obs-shaderfilter
	libobs)
set_target_properties(obs-shaderfilter PROPERTIES FOLDER "plugins")

install_obs_plugin_with_data(obs-shaderfilter data)
