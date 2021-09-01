/'* \file gui.bas
\brief Source handling the user interface and parameters

The source code in this file is designed for loading the Glade ui file,
creating the user interface, and handle the parameters.

\since 0.0
'/

#INCLUDE ONCE "Gir/OsmGpsMap-1.0.bi"
#INCLUDE ONCE "Gir/_GLibMacros-2.0.bi"
#INCLUDE ONCE "track_layer.bi"
#INCLUDE ONCE "track_store.bi"
#INCLUDE ONCE "gui.bi"
#INCLUDE ONCE "debug.bi"


FUNCTION TVT_select( _
  BYVAL Sel AS GtkTreeSelection PTR _
, BYVAL Model AS GtkTreeModel PTR _
, BYVAL Path AS GtkTreePath PTR _
, BYVAL Mode AS gboolean _
, BYVAL Ud AS gpointer) AS gboolean

WITH *GUI
  IF .TSnoPref THEN .TSnoPref = FALSE : RETURN FALSE ' button clicked
  track_layer_redraw(TRACK_LAYER(GUI->TRL))
  DIM AS GtkTreeIter iter
  DIM AS TrackLoader PTR loa
  gtk_tree_model_get_iter(Model, @iter, Path)
  gtk_tree_model_get(Model, @iter _
    , COL__LOADER, @loa _
    , -1)
  IF loa THEN TS_preference(loa)
  RETURN FALSE
END WITH
END FUNCTION


CONSTRUCTOR GUIdata(BYREF Fnam AS STRING, BYVAL Appli AS GApplication PTR)
  VAR er = gtk_check_version(3, 22, 0)
  IF er THEN g_error("failed: " & *er) : g_application_quit(Appli)

  DIM AS GError PTR errr
  VAR xml = gtk_builder_new()
  IF 0 = gtk_builder_add_from_file(xml, FNam, @errr) THEN
    g_error("GTK-Builder: " & *errr->message)
    g_object_unref(xml)
    g_error_free(errr)
    g_application_quit(Appli)
  END IF

  APP = G_OBJECT(Appli)
  WIN = gtk_builder_get_object(xml, "WinMain")
  ScrollMaps = gtk_builder_get_object(xml, "ScrollMaps")
  ScrollTracks = gtk_builder_get_object(xml, "ScrollTracks")
  STO = gtk_builder_get_object(xml, "TSTracks")
  TVT = gtk_builder_get_object(xml, "TVTracks")
  DTL = gtk_builder_get_object(xml, "DialogTrackLoad")
  DTP = gtk_builder_get_object(xml, "DialogTrackPref")
  LTD = gtk_builder_get_object(xml, "LabelDesc")
  LTE = gtk_builder_get_object(xml, "LabelExtrema")
  APW = gtk_builder_get_object(xml, "AdjTrackPoint")
  BPC = gtk_builder_get_object(xml, "ColorTrackPoint")
  CPD = gtk_builder_get_object(xml, "ComboDiameter")
  CPC = gtk_builder_get_object(xml, "ComboColor")
  ALW = gtk_builder_get_object(xml, "AdjTrackLine")
  BLC = gtk_builder_get_object(xml, "ColorTrackLine")
  TBL = gtk_builder_get_object(xml, "TBLayer")
  MAP = g_object_new(OSM_TYPE_GPS_MAP _
  , "tile-cache", OSM_GPS_MAP_CACHE_AUTO _
  , "expand", TRUE _
  , NULL)
  OSD = g_object_new(OSM_TYPE_GPS_MAP_OSD _
  , "show-scale", TRUE _
  , "show-crosshair", TRUE _
  , "show-dpad", TRUE _
  , "show-zoom", TRUE _
  , "dpad-radius", 30 _
  , "show-gps-in-dpad", TRUE _
  , "show-gps-in-zoom", FALSE _
  , "show-coordinates", FALSE _
  , NULL)

  VAR mawi = GTK_WIDGET(MAP)
  gtk_widget_set_size_request(mawi, PAR->MapW, PAR->MapH)
  gtk_widget_set_can_focus(mawi, TRUE)
  gtk_widget_add_events(mawi _
  ,  GDK_BUTTON_PRESS_MASK + GDK_BUTTON_RELEASE_MASK _
  + GDK_POINTER_MOTION_MASK + GDK_SCROLL_MASK _
  + GDK_KEY_PRESS_MASK + GDK_KEY_RELEASE_MASK)
  'gtk_widget_add_events (GTK_WIDGET (object), GDK_SMOOTH_SCROLL_MASK)
  gtk_container_add(GTK_CONTAINER(gtk_builder_get_object(xml, "BoxMain")), mawi)
  gtk_widget_show_all(mawi)
  osm_gps_map_layer_render(OSM_GPS_MAP_LAYER(OSD), OSM_GPS_MAP(MAP))

  TRL = track_layer_new(MAP)
  g_object_set(TRL _
  , "font-type", PAR->InfoFontType _
  , "font-size", PAR->InfoFontSize _
  , NULL)

  VAR src1 = OSM_GPS_MAP_SOURCE_NULL
  VAR listo = GTK_LIST_STORE(gtk_builder_get_object(xml, "LSMaps"))
  FOR i AS INTEGER = 1 TO OSM_GPS_MAP_SOURCE_LAST - 1
    IF 0 = osm_gps_map_source_is_valid(i) THEN CONTINUE FOR
    gtk_list_store_insert_with_values(listo, NULL, -1 _
    , 0, osm_gps_map_source_get_friendly_name(i) _
    , 1, STR(i) _
    ,-1)
    IF 0 = src1 THEN src1 = i
  NEXT
  g_object_set(MAP _
    , "map-source", src1 _
    , NULL)
  gtk_window_set_title(GTK_WINDOW(WIN), osm_gps_map_source_get_friendly_name(src1))

  VAR sel = gtk_tree_view_get_selection(GTK_TREE_VIEW(TVT))
  gtk_tree_selection_set_select_function(sel, @TVT_select(), NULL, NULL)
  gtk_builder_connect_signals(xml, NULL)

  g_object_ref(STO)
  g_object_unref(xml)
  gtk_application_add_window(GTK_APPLICATION(App), GTK_WINDOW(WIN))
END CONSTRUCTOR


/'* \brief DTOR to free memory

Destructor freeing the allocated memory for the UDTs created in the
constructor #GUIdata::GUIdata.

\since 0.0
'/
DESTRUCTOR GUIdata()
  TS_finalize()
  g_object_unref(TRL)
  g_object_unref(STO)
  g_object_unref(OSD)
END DESTRUCTOR
