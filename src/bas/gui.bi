/'* \file gui.bi
\brief Header containing Glade ui file pointers

FIXME

\since 0.0
'/

#DEFINE MASK_IN(_M_,_V_) (_V_) = (_V_ AND (_M_))

TYPE GUIdata
  AS gboolean _
    TSnoPref = FALSE '*< handle preference dialog
  AS GObject PTR _
    APP _ '*< main GtkApplicationWindow
  , WIN _ '*< main GtkApplicationWindow
  , ScrollMaps _ '*< maps GtkScrolledWindow
  , ScrollTracks _ '*< tracks GtkScrolledWindow
  , STO _ '*< track GtkTreeStore
  , TVT _ '*< track GtkTreeView
  , DTL _ '*< dialog track load
  , DTP _ '*< dialog track preference
  , LTD _ '*< label track description
  , LTE _ '*< label track extrem
  , APW _ '*< points GtkAdjustment
  , BPC _ '*< points GtkColorChooser
  , CPD _ '*< points diameter GtkComboBoxText
  , CPC _ '*< points color GtkComboBoxText
  , ALW _ '*< lines GtkAdjustment
  , BLC _ '*< lines GtkColorChooser
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
COMMON SHARED AS GUIdata PTR GUI

TYPE MapSeg
  AS float La0 = PI, Lo0, La1, Lo1
END TYPE

TYPE PARdata
  AS gint _
    Version = &h00000000 _ '*< Version of this parameter file
  , Size = SIZEOF(PARdata) '*< Size in bytes
  AS MapSeg MapSlots(9)
  AS gboolean _
    LayOn _          '*< user enabled the layer
  , LayResurf = TRUE '*< create new surface in #TrackLayer
  AS gint _
    MapW = 450 _ '*< initial map widget width
  , MapH = 300 _ '*< initial map widget height
  , Zoom         '*< map zoom level (fe!!)
  AS LONG _
    SkipFact = 15 _   '*< factor to skip out of a points cloud
  , NearDist = 15 _   '*< factor to search for closest distance
  , InfoFontSize = 12 '*< font size for point info
  AS STRING _
    InfoFontType = "Sans" '*< factor to skip out of a points cloud
  DECLARE SUB Map_store(BYVAL AS gint)
  DECLARE SUB Map_restore(BYVAL AS gint)
END TYPE
COMMON SHARED AS PARdata PTR PAR
