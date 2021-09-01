/'* \file callbacks.bas
\brief Source for callbacks

The callbacks in this source file handle user actions on the grafical
user interface (mouse and keyboard).

\since 0.0
'/

#INCLUDE ONCE "Gir/OsmGpsMap-1.0.bi"
#INCLUDE ONCE "track_store.bi"
#INCLUDE ONCE "track_layer.bi"
#INCLUDE ONCE "gui.bi"
#INCLUDE ONCE "debug.bi"


/'* \brief Callback handling the enable button in the track view
\param Cell Cell renderer emitting the signal
\param Path Path (row) in tree store
\param UDat Tree store to manipulate

FIXME

\since 0.0
'/
SUB on_TrackEnable_toggled CDECL ALIAS "on_TrackEnable_toggled"( _
  BYVAL Cell AS GtkCellRendererToggle PTR _
, BYVAL Path AS gchar PTR _
, BYVAL UDat AS gpointer) EXPORT
  GUI->TSnoPref = TRUE
  DIM AS GtkTreeIter iter
  gtk_tree_model_get_iter_from_string(GTK_TREE_MODEL(UDat), @iter, Path)

  VAR x = IIF(gtk_cell_renderer_toggle_get_active(Cell), FALSE, TRUE)
  gtk_tree_store_set(GTK_TREE_STORE(UDat), @iter, COL__ENABLE, x, -1)
END SUB


/'* \brief Callback handling the track selection
\param Cell FIXME
\param Path FIXME
\param UserData FIXME

FIXME

\since 0.0
'/
SUB on_TrackSel_clicked CDECL ALIAS "on_TrackSel_clicked"( _
  BYVAL Cell AS GtkCellRendererToggle PTR _
, BYVAL Path AS gchar PTR _
, BYVAL UserData AS gpointer) EXPORT
  GUI->TSnoPref = TRUE
  TS_select(*Path)
END SUB


/'* \brief Call back handling the load action
\param Butt Button emitting the signal
\param UserData Unused

SUB handling track loading when user clicks on load button. It opens
the file load dialog and loads the file[s] selected by the user.

\since 0.0
'/
SUB on_Load_clicked CDECL ALIAS "on_Load_clicked"( _
  BYVAL Butt AS GtkButton PTR _
, BYVAL UserData AS gpointer) EXPORT
WITH *GUI
  IF GTK_RESPONSE_OK = gtk_dialog_run(GTK_DIALOG(.DTL)) THEN
    DIM AS TrackLoader PTR last
    VAR list = gtk_file_chooser_get_filenames(GTK_FILE_CHOOSER(.DTL))
    WHILE list
      WITH TYPE<TS_add>(list->data)
        IF .Got THEN ?"  old entry: ",.Nam,.Fol,.Loa
        last = .Loa
      END WITH

      g_free(list->data)
      list = list->next
    WEND : TS_select(last->Path)
    g_slist_free(list)
  END IF
  gtk_widget_hide(GTK_WIDGET(.DTL))
END WITH
END SUB


/'* \brief Callback fetching a new map source selection
\param Tree Tree view emitting the signal
\param Path Path (row) of new selection
\param Clmn Column (unused)
\param UserData Popover widget to close

FIXME

\since 0.0
'/
SUB on_Map_selected CDECL ALIAS "on_Map_selected"( _
  BYVAL Tree AS GtkTreeView PTR _
, BYVAL Path AS GtkTreePath PTR _
, BYVAL Clmn AS GtkTreeViewColumn PTR _
, BYVAL UserData AS gpointer) EXPORT
WITH *GUI
  osm_gps_map_download_cancel_all(OSM_GPS_MAP(.MAP))

  VAR model = gtk_tree_view_get_model(Tree)
  DIM AS GtkTreeIter iter
  DIM AS gchar PTR nam, id
  gtk_tree_model_get_iter(model, @iter, Path)
  gtk_tree_model_get(model, @iter, 0, @nam, 1, @id, -1)

  g_object_set(.MAP, "map-source", VALINT(*id), NULL)
  gtk_window_set_title(GTK_WINDOW(.WIN), nam)
  g_free(nam) : g_free(id)
  gtk_popover_popdown(GTK_POPOVER(UserData))
END WITH
END SUB


/'* \brief FIXME
\param Cont Container emitting the signal
\param UserData FIXME

FIXME

\since 0.0
'/
SUB on_Poov_limit_size CDECL ALIAS "on_Poov_limit_size"( _
  BYVAL Cont AS GtkContainer PTR _
, BYVAL UserData AS gpointer) EXPORT
WITH *GUI
  VAR adj = gtk_scrolled_window_get_hadjustment(GTK_SCROLLED_WINDOW(UserData))
  VAR upp = gtk_adjustment_get_upper(adj)

  VAR w = gtk_widget_get_allocated_width(GTK_WIDGET(.MAP))
  VAR h = gtk_widget_get_allocated_height(GTK_WIDGET(.MAP))
  gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(UserData) _
    , IIF(upp < w, GTK_POLICY_NEVER, GTK_POLICY_ALWAYS), GTK_POLICY_AUTOMATIC)
  g_object_set(G_OBJECT(UserData) _
    , "max_content_height", (h - 25) _
    , "max_content_width", (w - 25), NULL)
  gtk_widget_queue_draw(GTK_WIDGET(UserData))
END WITH
END SUB


/'* \brief Callback fetching the tracks PopOver mapping
\param Cont Container emitting the signal
\param UserData Unused

SUB handling the ???

\since 0.0
'/
SUB on_PoovTracks_map CDECL ALIAS "on_PoovTracks_map"( _
  BYVAL Cont AS GtkContainer PTR _
, BYVAL UserData AS gpointer) EXPORT
WITH *GUI
  IF 0 = gtk_tree_model_iter_n_children(GTK_TREE_MODEL(.STO), NULL) _
    THEN  on_Load_clicked(NULL, NULL)

  on_Poov_limit_size(Cont, .ScrollTracks)
END WITH
END SUB


/'* \brief Callback fetching the layer state
\param Butt Button emiting the signal
\param UserData Unused

SUB handling the map layer. The original OsmGpsMapLayer gets added or
removed from the map widget. And the internal coordinates display get a
note by setting the #PARdata.LayOn flag.

\since 0.0
'/
SUB on_Layer_toggled CDECL ALIAS "on_Layer_toggled"( _
  BYVAL Butt AS GtkToggleButton PTR _
, BYVAL UserData AS gpointer) EXPORT
WITH *GUI
  IF gtk_toggle_button_get_active(Butt) THEN
    PAR->LayOn = TRUE
    osm_gps_map_layer_add(OSM_GPS_MAP(.MAP), OSM_GPS_MAP_LAYER(.OSD))
  ELSE
    PAR->LayOn = FALSE
    osm_gps_map_layer_remove(OSM_GPS_MAP(.MAP), OSM_GPS_MAP_LAYER(.OSD))
  END IF
  gtk_widget_queue_draw(GTK_WIDGET(.MAP))
END WITH
END SUB


/'* \brief Callback fetching state changes
\param Wid Widget (WinMain)
\param Event Event window state
\param Ud User data
\returns FALSE to continue event handling

Function to monitor the state of the main window, in order to fetch the
full screen property.

\since 0.0
'/
FUNCTION on_WIN_state CDECL ALIAS "on_WIN_state"( _
  BYVAL Wid AS GtkWidget PTR _
, BYVAL Event AS GdkEventWindowState PTR _
, BYVAL Ud AS gpointer) AS gboolean EXPORT
  GUI->WIN_state = Event->new_window_state
  RETURN FALSE
END FUNCTION



#MACRO GENERAL_KEYS()
_0_GENERAL:
WITH *GUI
  SELECT CASE Event->keyval
  CASE GDK_KEY_Plus, GDK_KEY_asterisk, GDK_KEY_KP_Add
    osm_gps_map_zoom_in(OSM_GPS_MAP(GUI->MAP))             : RETURN TRUE
  CASE GDK_KEY_minus, GDK_KEY_underscore, GDK_KEY_KP_Subtract
    osm_gps_map_zoom_out(OSM_GPS_MAP(GUI->MAP))            : RETURN TRUE
  CASE GDK_KEY_l, GDK_KEY_L_
    VAR tb = GTK_TOGGLE_BUTTON(.TBL)
    gtk_toggle_button_set_active(tb, _
      IIF(gtk_toggle_button_get_active(tb), FALSE, TRUE))  : RETURN TRUE
  END SELECT
END WITH
#ENDMACRO
#MACRO BLANK_KEYS()
_1_BLANK:
WITH *PAR
  VAR osm = OSM_GPS_MAP(GUI->MAP)
  SELECT CASE Event->keyval
  CASE GDK_KEY_space : DIM AS TS_bbox x = (FALSE) : RETURN TRUE
  CASE GDK_KEY_KP_6, GDK_KEY_Right : osm_gps_map_scroll(osm, .MapW \ 4, 0)
  CASE GDK_KEY_KP_4, GDK_KEY_Left  : osm_gps_map_scroll(osm,-.MapW \ 4, 0)
  CASE GDK_KEY_KP_8, GDK_KEY_Up    : osm_gps_map_scroll(osm, 0,-.MapH \ 4)
  CASE GDK_KEY_KP_2, GDK_KEY_Down  : osm_gps_map_scroll(osm, 0, .MapH \ 4)
  CASE GDK_KEY_KP_9  : osm_gps_map_scroll(osm, .MapW \ 4,-.MapH \ 4)
  CASE GDK_KEY_KP_3  : osm_gps_map_scroll(osm, .MapW \ 4, .MapH \ 4)
  CASE GDK_KEY_KP_1  : osm_gps_map_scroll(osm,-.MapW \ 4, .MapH \ 4)
  CASE GDK_KEY_KP_7  : osm_gps_map_scroll(osm,-.MapW \ 4,-.MapH \ 4)
  CASE GDK_KEY_F11
    IF MASK_IN(GDK_WINDOW_STATE_FULLSCREEN, GUI->WIN_state) _
      THEN gtk_window_unfullscreen(GTK_WINDOW(GUI->WIN)) _
      ELSE gtk_window_fullscreen(GTK_WINDOW(GUI->WIN))
  CASE ELSE : RETURN FALSE
  END SELECT : RETURN TRUE
END WITH
#ENDMACRO
#MACRO SHIFT_CONTROL_KEYS()
_2_SHIFT_CONTROL:
  VAR trl = TRACK_LAYER(GUI->TRL)
  IF GDK_CONTROL_MASK AND state THEN
    SELECT CASE AS CONST Event->keyval
    CASE GDK_KEY_Right : track_layer_point_move(trl, @">")
    CASE GDK_KEY_Left  : track_layer_point_move(trl, @"<")
    CASE GDK_KEY_Up    : track_layer_point_move(trl, @"}")
    CASE GDK_KEY_Down  : track_layer_point_move(trl, @"{")
    CASE ELSE : RETURN FALSE
    END SELECT : RETURN TRUE
  END IF

  SELECT CASE Event->keyval
  CASE GDK_KEY_I_ : TS_preference(track_layer_get_loader(trl))
  CASE GDK_KEY_space : track_layer_center_track(trl)
  CASE GDK_KEY_Right     : track_layer_point_move(trl, @"+")
  CASE GDK_KEY_Left      : track_layer_point_move(trl, @"-")
  CASE GDK_KEY_Up        : track_layer_point_move(trl, @"f")
  CASE GDK_KEY_Down      : track_layer_point_move(trl, @"b")
  CASE GDK_KEY_Page_Up   : track_layer_point_move(trl, @"F")
  CASE GDK_KEY_Page_Down : track_layer_point_move(trl, @"B")
  CASE GDK_KEY_Home      : track_layer_point_move(trl, @"H")
  CASE GDK_KEY_End       : track_layer_point_move(trl, @"E")
  CASE GDK_KEY_M_        : track_layer_point_move(trl, @"M")
  CASE GDK_KEY_KP_1, GDK_KEY_KP_End   : track_layer_point_move(trl, @"1")
  CASE GDK_KEY_KP_2, GDK_KEY_KP_Down  : track_layer_point_move(trl, @"2")
  CASE GDK_KEY_KP_3, GDK_KEY_KP_Next  : track_layer_point_move(trl, @"3")
  CASE GDK_KEY_KP_4, GDK_KEY_KP_Left  : track_layer_point_move(trl, @"4")
  CASE GDK_KEY_KP_5, GDK_KEY_KP_Begin : track_layer_point_move(trl, @"5")
  CASE GDK_KEY_KP_6, GDK_KEY_KP_Right : track_layer_point_move(trl, @"6")
  CASE GDK_KEY_KP_7, GDK_KEY_KP_Home  : track_layer_point_move(trl, @"7")
  CASE GDK_KEY_KP_8, GDK_KEY_KP_Up    : track_layer_point_move(trl, @"8")
  CASE GDK_KEY_KP_9, GDK_KEY_KP_Prior : track_layer_point_move(trl, @"9")
  CASE ELSE : RETURN FALSE
  END SELECT : RETURN TRUE
#ENDMACRO
#MACRO CONTROL_KEYS()
_1_CONTROL:
WITH *GUI
  SELECT CASE AS CONST Event->keyval
  CASE GDK_KEY_o : on_Load_clicked(NULL, NULL) : RETURN TRUE
  'CASE GDK_KEY_p : '!! print / pref
  'CASE GDK_KEY_s : '!! save
  CASE GDK_KEY_q : g_application_quit(G_APPLICATION(.APP))
  CASE GDK_KEY_space : DIM AS TS_bbox x = (TRUE) : RETURN TRUE
  END SELECT
END WITH
#ENDMACRO
#MACRO ALT_KEYS()
_1_ALTERNATE:
WITH *GUI
  SELECT CASE AS CONST Event->keyval
  CASE GDK_KEY_o : on_Load_clicked(NULL, NULL) : return TRUE
  CASE GDK_KEY_q : g_application_quit(G_APPLICATION(.APP)) ': return TRUE
  END SELECT
END WITH
#ENDMACRO

FUNCTION on_Map_keypress CDECL ALIAS "on_Map_keypress"( _
  BYVAL Wid AS GtkWidget PTR _
, BYVAL Event AS GdkEventKey PTR _
, BYVAL UserData AS gpointer) AS gboolean EXPORT

  VAR state = Event->state XOR GDK_MOD2_MASK
  GENERAL_KEYS()
  SELECT CASE AS CONST state
  CASE 0
    BLANK_KEYS()
  CASE GDK_CONTROL_MASK
    CONTROL_KEYS()
  CASE GDK_MOD1_MASK
    ALT_KEYS()
  CASE ELSE
    IF NOT(GDK_CONTROL_MASK + GDK_SHIFT_MASK + GDK_LOCK_MASK) AND state THEN RETURN FALSE
    SHIFT_CONTROL_KEYS()
  END SELECT : RETURN FALSE
END FUNCTION
