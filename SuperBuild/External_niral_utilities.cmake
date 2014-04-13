# Make sure this file is included only once by creating globally unique varibles
# based on the name of this included file.
# get_filename_component(CMAKE_CURRENT_LIST_FILENAME ${CMAKE_CURRENT_LIST_FILE} NAME_WE)
# if(${CMAKE_CURRENT_LIST_FILENAME}_FILE_INCLUDED)
#   return()
# endif()
# set(${CMAKE_CURRENT_LIST_FILENAME}_FILE_INCLUDED 1)

## External_${extProjName}.cmake files can be recurisvely included,
## and cmake variables are global, so when including sub projects it
## is important make the extProjName and proj variables
## appear to stay constant in one of these files.
## Store global variables before overwriting (then restore at end of this file.)
ProjectDependancyPush(CACHED_extProjName ${extProjName})
ProjectDependancyPush(CACHED_proj ${proj})

# Make sure that the ExtProjName/IntProjName variables are unique globally
# even if other External_${ExtProjName}.cmake files are sourced by
# SlicerMacroCheckExternalProjectDependency
set(extProjName niral_utilities) #The find_package known name
set(proj        ${extProjName}) #This local name
set(${extProjName}_REQUIRED_VERSION ITKv4 VTK SlicerExecutionModel)

#if(${USE_SYSTEM_${extProjName}})
#  unset(${extProjName}_DIR CACHE)
#endif()

# Sanity checks
if(DEFINED ${extProjName}_DIR AND NOT EXISTS ${${extProjName}_DIR})
  message(FATAL_ERROR "${extProjName}_DIR variable is defined but corresponds to non-existing directory (${${extProjName}_DIR})")
endif()

# Set dependency list
set(${proj}_DEPENDENCIES ITKv4)
#if(${PROJECT_NAME}_BUILD_DICOM_SUPPORT)
#  list(APPEND ${proj}_DEPENDENCIES DCMTK)
#endif()

# Include dependent projects if any
SlicerMacroCheckExternalProjectDependency(${proj})

if(NOT ( DEFINED "USE_SYSTEM_${extProjName}" AND "${USE_SYSTEM_${extProjName}}" ) )
  #message(STATUS "${__indent}Adding project ${proj}")

  # Set CMake OSX variable to pass down the external project
  set(CMAKE_OSX_EXTERNAL_PROJECT_ARGS)
  if(APPLE)
    list(APPEND CMAKE_OSX_EXTERNAL_PROJECT_ARGS
      -DCMAKE_OSX_ARCHITECTURES:STRING=${CMAKE_OSX_ARCHITECTURES}
      -DCMAKE_OSX_SYSROOT:STRING=${CMAKE_OSX_SYSROOT}
      -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=${CMAKE_OSX_DEPLOYMENT_TARGET})
  endif()

  ### --- Project specific additions here
  set(${proj}_CMAKE_OPTIONS
    -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_CURRENT_BINARY_DIR}/${proj}-install
    -DCOMPILE_CONVERTITKFORMATS:BOOL=ON
    -DCOMPILE_CROPTOOLS:BOOL=OFF
    -DCOMPILE_CURVECOMPARE:BOOL=OFF
    -DCOMPILE_DTIAtlasBuilder:BOOL=OFF
    -DCOMPILE_DWI_NIFTINRRDCONVERSION:BOOL=OFF
    -DCOMPILE_IMAGEMATH:BOOL=ON
    -DCOMPILE_IMAGESTAT:BOOL=OFF
    -DCOMPILE_POLYDATAMERGE:BOOL=OFF
    -DCOMPILE_POLYDATATRANSFORM:BOOL=OFF
    -DCOMPILE_TRANSFORMDEFORMATIONFIELD:BOOL=OFF
    -DUSE_SYSTEM_SlicerExecutionModel:BOOL=ON
    -DUSE_SYSTEM_ITK:BOOL=ON
    -DUSE_SYSTEM_VTK:BOOL=ON
    -DITK_VERSION_MAJOR:STRING=${ITK_VERSION_MAJOR}
    -DITK_DIR:PATH=${ITK_DIR}
    -DGenerateCLP_DIR:PATH=${GenerateCLP_DIR}
    -DVTK_DIR:PATH=${VTK_DIR}
    )

  ### --- End Project specific additions
  set(${proj}_REPOSITORY "https://www.nitrc.org/svn/niral_utilities/trunk")
  set(${proj}_SVN_REVISION -r "56")
  ExternalProject_Add(${proj}
    SVN_REPOSITORY ${${proj}_REPOSITORY}
    SVN_REVISION ${${proj}_SVN_REVISION}
    SVN_USERNAME slicerbot
    SVN_PASSWORD slicer
    SOURCE_DIR ${SOURCE_DOWNLOAD_CACHE}/${proj}
    BINARY_DIR ${proj}-build
    LOG_CONFIGURE 0  # Wrap configure in script to ignore log output from dashboards
    LOG_BUILD     0  # Wrap build in script to to ignore log output from dashboards
    LOG_TEST      0  # Wrap test in script to to ignore log output from dashboards
    LOG_INSTALL   0  # Wrap install in script to to ignore log output from dashboards
    INSTALL_COMMAND ""
    ${cmakeversion_external_update} "${cmakeversion_external_update_value}"
    CMAKE_GENERATOR ${gen}
    CMAKE_ARGS -Wno-dev --no-warn-unused-cli
    CMAKE_CACHE_ARGS
      ${CMAKE_OSX_EXTERNAL_PROJECT_ARGS}
      ${COMMON_EXTERNAL_PROJECT_ARGS}
      ${${proj}_CMAKE_OPTIONS}
## We really do want to install in order to limit # of include paths INSTALL_COMMAND ""
    DEPENDS
      ${${proj}_DEPENDENCIES}
  )
  set(${extProjName}_DIR ${CMAKE_BINARY_DIR}/${proj}-build)
else()
  if(${USE_SYSTEM_${extProjName}})
    find_package(${extProjName} ${${extProjName}_REQUIRED_VERSION} REQUIRED)
    message("USING the system ${extProjName}, set ${extProjName}_DIR=${${extProjName}_DIR}")
  endif()
  # The project is provided using ${extProjName}_DIR, nevertheless since other
  # project may depend on ${extProjName}, let's add an 'empty' one
  SlicerMacroEmptyExternalProject(${proj} "${${proj}_DEPENDENCIES}")
endif()

list(APPEND ${CMAKE_PROJECT_NAME}_SUPERBUILD_EP_VARS ${extProjName}_DIR:PATH)

ProjectDependancyPop(CACHED_extProjName extProjName)
ProjectDependancyPop(CACHED_proj proj)
