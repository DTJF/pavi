# Use the package PkgConfig to detect library files
FIND_PACKAGE(PkgConfig REQUIRED)
PKG_CHECK_MODULES(GTK REQUIRED IMPORTED_TARGET gtk+-3.0>=3.22)
PKG_CHECK_MODULES(OSM REQUIRED IMPORTED_TARGET osmgpsmap-1.0>=1.0)

IF(NOT(GTK_FOUND AND OSM_FOUND))
  IF(NOT GTK_FOUND)
    MSG_LOG("!! Gtk library missing -> no executable")
  ENDIF()
  IF(NOT OSM_FOUND)
    MSG_LOG("!! OsmGpsMap library missing -> no executable")
  ENDIF()
  RETURN()
ENDIF()
MSG_LOG(">> target <all> OK (found Gtk-${GTK_VERSION}/OsmGpsMap-${OSM_VERSION})")


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

SET(ui_src "${CMAKE_CURRENT_SOURCE_DIR}/pavi.ui")
SET(gui_tar "${CMAKE_CURRENT_BINARY_DIR}/pavi.gui")
EXECUTE_PROCESS(
  COMMAND sed --version
  OUTPUT_VARIABLE sedout
  )

IF(sedout)
  ADD_CUSTOM_COMMAND(OUTPUT ${gui_tar}
    COMMAND sed 's/^\\s\\+<*/</' ${ui_src} > ${gui_tar}
    DEPENDS ${ui_src}
    ) # compress UI (remove trailing white spaces)
ELSE()
  FILE(CREATE_LINK
    ${ui_src}
    ${gui_tar}
    SYMBOLIC
    )
# for cmake < 3.14
  #EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND}
    #-E create_symlink
    #${ui_src}
    #${gui_tar}
    #)
ENDIF()

IF(NOT(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_CURRENT_BINARY_DIR)) # out-of-source build
  SET(png_src "${CMAKE_SOURCE_DIR}/img/pavi.png")
  SET(png_tar "${CMAKE_CURRENT_BINARY_DIR}/pavi.png")
# for cmake >= 3.14
  FILE(CREATE_LINK
    ${png_src}
    ${png_tar}
    SYMBOLIC
    )
# for cmake < 3.14
  #EXECUTE_PROCESS(COMMAND ${CMAKE_COMMAND} # for cmake < 3.14
    #-E create_symlink
    #${png_src}
    #${png_tar}
    #)
ENDIF()

# pavi[.exe]: compile and link the final executable
ADD_EXECUTABLE(${PROJ_NAME} ${SRC_BAS})

#SET(CMAKE_EXE_LINKER_FLAGS "-Wl -z,relro") # must override global flags
SET_TARGET_PROPERTIES(${PROJ_NAME} PROPERTIES
  COMPILE_FLAGS "-m pavi -exx -w all"
  #COMPILE_FLAGS "-m pavi -O 3 -d G_DISABLE_CAST_CHECKS"
  LINK_FLAGS "-export"
  )

ADD_Fbc_SRC_DEPS(${PROJ_NAME})

INSTALL(TARGETS ${PROJ_NAME}
  DESTINATION bin
  )
INSTALL(FILES ${gui_tar} ${png_src}
  DESTINATION bin
  )

