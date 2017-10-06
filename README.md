# obs-shaderfilter

## Introduction

OBS Studio filter for applying an arbitrary shader to a source.

## Installation

The binary package mirrors the structure of the OBS Studio installation directory, so you should be able to
just drop its contents alongside an OBS Studio install (usually at C:\Program Files (x86)\obs-studio\). The 
necessary files should look like this: 

    obs-studio
    |---data
    |   |---obs-plugins
    |       |---obs-shaderfilter
    |           |---examples
    |               |---blink.shader
    |               |---border.shader
    |               |---drop_shadow.shader
    |               |---filter-template.effect
    |               |---multiply.shader
    |               |---pulse.effect
    |               |---rectangular_drop_shadow.shader
    |               |---rounded_rect.shader
    |           |---locale
    |               |---en-US.ini
    |---obs-plugins
        |---32bit
        |   |---obs-shaderfilter.dll
        |---64bit
            |---obs-shaderfilter.dll

## Usage

## Building

If you wish to build the obs-shaderfilter plugin from source, you should just need [CMake](https://cmake.org/) 
and the OBS Studio libraries and headers.

* [obs-ghostscript source repository](https://github.com/nleseul/obs-ghostscript)
* [OBS studio source repository](https://github.com/jp9000/obs-studio)

I don't believe that the OBS project provides prebuilt libraries; you're probably going to have the best luck
building your own OBS binaries from the source. Refer to the OBS repository for more information on that.

When building in CMake, the OBSSourcePath configuration value should refer to the libobs subfolder 
in the OBS source release. The build pipeline will look for headers in this location, and for libraries
in a "build" folder relative to that path (where the OBS build process puts them). 

Installation logic is provided through CMake as well; you can set the CMAKE_INSTALL_PREFIX configuration value
to choose the folder to which the files will be copied. You can also manually copy all files to the locations
described above.

## License

This project is licensed under the "[Unlicense](http://unlicense.org/)", because copy[right|left] is a hideous
mess to deal with and I don't like it. 
