/'* \file track_store.bi
\brief Header for tree store of tracks handling

This header file deals with stuff to handle the GtkTreeStore for the
tracks data.

\since 0.0
'/

TYPE AS SINGLE float ' !!

#INCLUDE ONCE "Gir/Gtk-3.0.bi"
#INCLUDE ONCE "track_loader.bi"

ENUM TSTracksColumns
  COL__SELECT = 0
  COL__ENABLE
  COL_VISIBLE
  COL____PATH
  COL____NAME
  COL_P_WIDTH
  COL_L_WIDTH
  COL_P_COLOR
  COL_L_COLOR
  COL__LOADER
END ENUM


/'* \brief Class adding a new entry to the list of tracks

This class (UDT) is designed to add a new file to the tracks tree
store. It checks if the file is allready loaded, and does nothing in
that case.

Otherwise it loads the file and creates a new row in the tree store,
and additionally a new folder entry if neccesary.

It's a 'flying' class, designed for temporary instances only.

\since 0.0
'/
TYPE TS_add
  AS STRING _
    Nam _ '*< The name to search
  , Fol   '*< The folder to search
  AS gboolean Got = FALSE '*< Got a match?
  AS GtkTreeIter PTR Par = NULL '*< The parent folder iter
  AS gpointer Loa '*< Pointer for TrackLoader instance
  DECLARE CONSTRUCTOR(BYVAL AS CONST gchar PTR)
  DECLARE STATIC FUNCTION _find CDECL( _
    BYVAL AS GtkTreeModel PTR _
  , BYVAL AS GtkTreePath PTR _
  , BYVAL AS GtkTreeIter PTR _
  , BYVAL AS gpointer) AS gboolean
END TYPE


/'* \brief UDT holding search result

In order to find a point nearest to a given location the search process
uses this UDT to store the track results.

\since 0.0
'/
TYPE UDTnearest_result
  AS float Dist
  AS TrackLoader PTR Loa
END TYPE


/'* \brief Class finding the nearest track point

The constructor searches all active tracks for the point nearest to the
given location. In case of more than four active tracks, the most
nearest for loaders remain in the #TS_nearest.Res array.

\since 0.0
'/
TYPE TS_nearest
  AS UDTnearest_result Res(3)
  AS float Lat, Lon
  DECLARE CONSTRUCTOR(BYVAL AS float, BYVAL AS float)
  DECLARE STATIC FUNCTION _dist CDECL( _
    BYVAL AS GtkTreeModel PTR _
  , BYVAL AS GtkTreePath PTR _
  , BYVAL AS GtkTreeIter PTR _
  , BYVAL AS gpointer) AS gboolean
END TYPE


/'* \brief Class finding the nearest track point

The constructor searches all active tracks for the point nearest to the
given location. In case of more than four active tracks, the most
nearest for loaders remain in the #TS_nearest.Res array.

\since 0.0
'/
TYPE TS_bbox
  AS float La0 = PI, La1 = -PI, Lo0 = PI, Lo1 = -PI
  AS LONG Mode, Cnt = 0
  DECLARE CONSTRUCTOR(BYVAL AS gboolean)
  DECLARE STATIC FUNCTION _bounds CDECL( _
    BYVAL AS GtkTreeModel PTR _
  , BYVAL AS GtkTreePath PTR _
  , BYVAL AS GtkTreeIter PTR _
  , BYVAL AS gpointer) AS gboolean
END TYPE


DECLARE SUB TS_finalize()
DECLARE SUB TS_remove(BYVAL AS GtkTreeIter PTR)
DECLARE SUB TS_select(BYVAL AS STRING)
DECLARE SUB TS_preference(BYVAL AS TrackLoader PTR)
