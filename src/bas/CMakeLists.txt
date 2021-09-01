# transfer constants to FB source
#SET(fnam ${CMAKE_CURRENT_SOURCE_DIR}/pavi_version.bi)
#CONFIGURE_FILE(${fnam}.in ${fnam} @ONLY)

SET(SRC_BAS
  "pavi.bas"
  "gui.bas"
  "callbacks.bas"
  "track_layer.bas"
  "track_loader.bas"
  "track_store.bas"
  "parser_gpx.bas"
  "parser_nmea.bas"
  CACHE FILEPATH "BASIC source files" FORCE
  )

SET(SRC_BI
  "gui.bi"
  "track_layer.bi"
  "track_loader.bi"
  "track_store.bi"
  "parser_gpx.bi"
  "parser_nmea.bi"
  )

IF(NOT(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)) # out-of-source build
  SET(ui "pavi.ui")
  SET(png "pavi.png")
# for cmake >= 3.14
  FILE(CREATE_LINK
    ${CMAKE_CURRENT_SOURCE_DIR}/${ui}
    ${CMAKE_CURRENT_BINARY_DIR}/${ui}
    SYMBOLIC
    )
  FILE(CREATE_LINK
    ${CMAKE_CURRENT_SOURCE_DIR}/${png}
    ${CMAKE_CURRENT_BINARY_DIR}/${png}
    SYMBOLIC
    )
# for cmake < 3.14
  #EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND}
    #-E create_symlink
    #${CMAKE_CURRENT_SOURCE_DIR}/${ui}
    #${CMAKE_CURRENT_BINARY_DIR}/${ui}
    #)
  #EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND} # for cmake < 3.14
    #-E create_symlink
    #${CMAKE_CURRENT_SOURCE_DIR}/${png}
    #${CMAKE_CURRENT_BINARY_DIR}/${png}
    #)
ENDIF()

# pavi[.exe]: compile and link the final executable
ADD_EXECUTABLE(${PROJ_NAME} ${SRC_BAS})
#SET(CMAKE_EXE_LINKER_FLAGS "-Wl -z,relro") # must override global flags
SET_TARGET_PROPERTIES(${PROJ_NAME} PROPERTIES
  #COMPILE_FLAGS "-m pavi -exx -w all"
  COMPILE_FLAGS "-m pavi -d G_DISABLE_CAST_CHECKS"
  LINK_FLAGS "-export"
  )

ADD_Fbc_SRC_DEPS(${PROJ_NAME})

INSTALL(TARGETS ${PROJ_NAME} #!!"pavi.ui" "logo.png"
  DESTINATION bin
  )

