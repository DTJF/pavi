/'* \file gui.bi
\brief Header containing COMMON classes

This header declares the COMMON classes for user interface and
parameters data.

\since 0.0
'/

'* \brief Macro testing if (only) a bit is set in mask
#DEFINE MASK_IN(_M_,_V_) (_V_) = (_V_ AND (_M_))


/'* \brief Class holding data for the user interface

FIXME

\since 0.0
'/
TYPE GUIclass
  AS gboolean _
    TSnoPref = FALSE '*< handle preference dialog
  AS GObject PTR _
    APP _ '*< main GtkApplicationWindow
  , WIN _ '*< main GtkApplicationWindow
  , ScrollMaps _ '*< maps GtkScrolledWindow
  , ScrollTracks _ '*< tracks GtkScrolledWindow
  , STO _ '*< track GtkTreeStore
  , TVT _ '*< track GtkTreeView
  , TVC _ '*< column track GtkTreeView
  , DTL _ '*< dialog track load
  , DTP _ '*< dialog track preference
  , TSM _ '*< dialog map preference
  , DMP _ '*< dialog map preference
  , AMN _ '*< adjustment minimum zoom
  , AMX _ '*< adjustment maximum zoom
  , LTD _ '*< label track description
  , LTE _ '*< label track extrem
  , APW _ '*< points GtkAdjustment
  , BPC _ '*< points GtkColorChooser
  , CPD _ '*< points diameter GtkComboBoxText
  , CPC _ '*< points color GtkComboBoxText
  , ALW _ '*< lines GtkAdjustment
  , BLC _ '*< lines GtkColorChooser
  , EMT _ '*< entry title in map preference
  , EMU _ '*< entry uri in map preference
  , CMT _ '*< combo map tile type
  , TBL _ '*< toggle button layer
  , MAP _ '*< map widget
  , OSD   '*< map layer for controls (on screen display)
  AS TrackLayer PTR _
    TRL '*< map layer for tracks
  AS GdkWindowState _
    WIN_state '*< current toplevel window state
  DECLARE CONSTRUCTOR(BYREF AS STRING, BYVAL AS GApplication PTR)
  DECLARE DESTRUCTOR()
END TYPE
COMMON SHARED AS GUIclass PTR GUI


/'* \brief Class holding the bounding box for a map segment

FIXME

\since 0.0
'/
TYPE MapSeg
  AS float La0 = PI, Lo0, La1, Lo1
END TYPE


/'* \brief Class holding the user definded parameters

FIXME

\since 0.0
'/
TYPE PARclass
  AS gint _
    Version = &h00000000 _ '*< Version of this parameter file
  , Size = SIZEOF(PARclass) '*< Size in bytes
  AS MapSeg MapSlots(9)
  AS gboolean _
    LayOn _          '*< user enabled the layer
  , LayResurf = TRUE '*< create new surface in #TrackLayer
  AS gint _
    MapW = 450 _ '*< initial map widget width
  , MapH = 300 _ '*< initial map widget height
  , Zoom _       '*< map zoom level (fe!!)
  , SkipFact = 15 _    '*< factor to skip out of a points cloud
  , NearDist = 15 _    '*< factor to search for closest distance
  , InfoFontSize = 12 _'*< font size for point info
  , LatLonTyp = 1 '*< format for coordinate string
  AS STRING _
    InfoFontType = "Sans" _ '*< font for info pad
  , DaTiFormat = "yymmdd-hh:mm:ss" '*< format for data/time as of https://www.freebasic.net/wiki/KeyPgFormat
  DECLARE SUB Map_store(BYVAL AS gint)
  DECLARE SUB Map_restore(BYVAL AS gint)
  DECLARE function lat2str(BYVAL V AS float) AS STRING
  DECLARE function lon2str(BYVAL V AS float) AS STRING
  DECLARE function TimStr(BYVAL AS double) AS STRING
END TYPE
COMMON SHARED AS PARclass PTR PAR

