/'* \file track_store.bas
\brief Source handling the tree store of tracks

The track data is stored in a GtkTreeStore. The source in this file
handles the tree store operations.

\since 0.0
'/

#INCLUDE ONCE "Gir/Gtk-3.0.bi"
#INCLUDE ONCE "track_layer.bi"
#INCLUDE ONCE "track_store.bi"
#INCLUDE ONCE "gui.bi"
#INCLUDE ONCE "string.bi"


/'* \brief Callback for finding folders/file entries
\param Model tree model
\param Path line in Model
\param Iter iter in Model
\param UserData the calling #TS_add instance
\returns TRUE when matching, otherwise FALSE

This function is designed as a gtk_tree_model_foreach callback. It
checks if the tree store line contains an entry with equal entry
(folder and file name), or at least an equal folder parent.

\since 0.0
'/
FUNCTION TS_add._find CDECL( _
    BYVAL Model AS GtkTreeModel PTR _
  , BYVAL Path AS GtkTreePath PTR _
  , BYVAL Iter AS GtkTreeIter PTR _
  , BYVAL UserData AS gpointer) AS gboolean
WITH *CAST(TS_add PTR, UserData)
  DIM AS gchar PTR n, p
  gtk_tree_model_get(Model, Iter _
    , TST____NAME, @n _
    , TST____PATH, @p _
    , TST__LOADER, @.Loa _
    , -1)
  IF .Loa THEN
    ' check if file (path+name) is present
    IF .Nam = *n ANDALSO .Fol = *p THEN .Got = TRUE
  ELSE
    ' check if folder is present -> get iter
    IF NULL = p  ANDALSO .Fol = *n THEN .Par = gtk_tree_iter_copy(Iter)
  END IF : g_free(p) : g_free(n) : RETURN .Got
END WITH
END FUNCTION


/'* \brief CTOR for adding a further track
\param N The path/name to load

This constructor is designed to add a further file to the tree store in
GUI.STO, applying standard parameters from the TrackLayer. It separates
path and file name and checks if that file is already in the store,
doing nothing in that case.

Otherwise it loads the track. In case of success it creates a new
folder entry (if neccesary) and a new file entry, and selects that new
entry in the tree view.

\since 0.0
'/
CONSTRUCTOR TS_add(BYVAL N AS CONST gchar PTR)
WITH *GUI
  VAR p = INSTRREV(*N, *G_DIR_SEPARATOR_S)
  Nam = MID(*N, p+1)
  Fol = LEFT(*N, p)
  VAR model = GTK_TREE_MODEL(.STO)
  gtk_tree_model_foreach(model _
    , @TS_add._find(), CAST(gpointer, @THIS))
  IF Got THEN EXIT CONSTRUCTOR

  VAR tl = NEW TrackLoader(N)
  IF tl->Az >= 0 THEN Loa = CAST(gpointer, tl) _
                 ELSE ?"**load error: ";*tl->Errr;" in file ";*N : DELETE(tl) : EXIT CONSTRUCTOR

  DIM AS GtkTreeIter new_par, iter
  VAR sto = GTK_TREE_STORE(.STO)
  IF NULL = Par THEN
    gtk_tree_store_insert_with_values(sto, @new_par, NULL, -1 _
      , TST__ENABLE, FALSE _
      , TST__SELECT, FALSE _
      , TST_VISIBLE, FALSE _
      , TST____NAME, Fol _
      , TST____PATH, NULL _
      , TST__LOADER, NULL _
      ,-1)
  END IF

  VAR def = track_layer_get_default(TRACK_LAYER(.TRL))
  IF def THEN
    gtk_tree_store_insert_with_values(sto, @iter, IIF(Par, Par, @new_par), -1 _
      , TST__ENABLE, TRUE _
      , TST__SELECT, FALSE _
      , TST_VISIBLE, TRUE _
      , TST____PATH, Fol _
      , TST____NAME, Nam _
      , TST_P_WIDTH, PEEK(UBYTE, def->P) _
      , TST_L_WIDTH, PEEK(UBYTE, def->L) _
      , TST_P_COLOR, def->P[1] _
      , TST_L_COLOR, def->L[1] _
      , TST__LOADER, Loa _
      ,-1)
    VAR s = gtk_tree_model_get_string_from_iter(model, @iter)
    PEEK(TrackLoader, Loa).Path = *s
    g_free(s)
  END IF
  IF Par THEN gtk_tree_iter_free(Par) : EXIT CONSTRUCTOR
  ' expand new folder row
  VAR path = gtk_tree_model_get_path(model, @new_par)
  gtk_tree_view_expand_row(GTK_TREE_VIEW(.TVT), path, FALSE)
  gtk_tree_path_free(path)
END WITH
END CONSTRUCTOR


/'* \brief Callback for unloading all tracks
\param Model tree model
\param Path line in Model
\param Iter iter in Model
\param UserData unused
\returns FALSE (in order to continue)

This function is designed as a gtk_tree_model_foreach callback. It
checks if the tree store line contains a #TrackLoader (DELETEing that
instance) or gchararray pointers (g_free() that memory).

\since 0.0
'/
FUNCTION track_store_remove CDECL( _
    BYVAL Model AS GtkTreeModel PTR _
  , BYVAL Path AS GtkTreePath PTR _
  , BYVAL Iter AS GtkTreeIter PTR _
  , BYVAL UserData AS gpointer) AS gboolean
  DIM AS TrackLoader PTR loa
  DIM AS gchar PTR pcs, lcs, nam, fol
  gtk_tree_model_get(Model, Iter _
    , TST____PATH, @fol _
    , TST____NAME, @nam _
    , TST_P_COLOR, @pcs _
    , TST_L_COLOR, @lcs _
    , TST__LOADER, @loa _
    , -1)
  IF pcs THEN g_free(pcs)
  IF lcs THEN g_free(lcs)
  IF fol THEN g_free(fol)
  IF nam THEN g_free(nam)
  IF loa THEN DELETE(loa)
  RETURN FALSE
END FUNCTION


/'* \brief Remove all tracks from store

Function checking each store row: in case of a track (no folder) it
DELETEs the #TrackLoader instance and frees the gchararray memory.
Finally it clears the remaining folder entries.

\since 0.0
'/
SUB TS_finalize()
WITH *.GUI
  gtk_tree_model_foreach(GTK_TREE_MODEL(.STO) _
    , @track_store_remove(), NULL)
  gtk_tree_store_clear(GTK_TREE_STORE(.STO))
END WITH
END SUB


/'* \brief Remove a track from store
\param Child The iter where to find the track

Procedure to remove a single track from the store, DELETEing the
#TrackLoader structure.

\since 0.0
'/
SUB TS_remove(BYVAL Child AS GtkTreeIter PTR)
WITH *.GUI
  VAR model = GTK_TREE_MODEL(.STO)
  DIM AS GtkTreeIter parent
  gtk_tree_model_iter_parent(model, @parent, Child)
  track_store_remove(model, NULL, Child, NULL)
  gtk_tree_store_remove(GTK_TREE_STORE(.STO), Child)
  IF FALSE = gtk_tree_model_iter_has_child(model, @parent) _
    THEN gtk_tree_store_remove(GTK_TREE_STORE(.STO), @parent)
END WITH
END SUB


/'* \brief Callback for search nearest point
\param Model tree model
\param Path line in Model
\param Iter iter in Model
\param UserData unused
\returns FALSE (in order to continue)

This function is designed as a gtk_tree_model_foreach callback. It
searchesn (2d) in all enabled tracks for the nearest point to a given
location and stores the distance and the track in a free slot in the
result array #TS_nearest.Res. Whenn all slots are used, a slot with
bigger distance gets replaced (if any).

\since 0.0
'/
FUNCTION TS_nearest._dist CDECL( _
    BYVAL Model AS GtkTreeModel PTR _
  , BYVAL Path AS GtkTreePath PTR _
  , BYVAL Iter AS GtkTreeIter PTR _
  , BYVAL UserData AS gpointer) AS gboolean
  DIM AS TrackLoader PTR loa
  DIM AS gboolean en
  gtk_tree_model_get(Model, Iter _
    , TST__ENABLE, @en _
    , TST__LOADER, @loa _
    , -1)
  IF FALSE = en ORELSE NULL = loa THEN RETURN FALSE
  WITH PEEK(TS_nearest, UserData)
    VAR d = loa->Nearest(.Lat, .Lon) _
     , d0 = .Res(0).Dist - d, ii = -1L
    FOR i AS LONG = 0 TO UBOUND(.Res)
    WITH .Res(i)
      IF 0 = .Loa THEN .Dist = d : .Loa = loa : RETURN FALSE ' fill empty slot
      IF .Dist <= d THEN CONTINUE FOR
      VAR di = .Dist - d
      IF di < d0 THEN ii = i : d0 = di
    END WITH
    NEXT
    IF ii >= 0 THEN .Res(ii).Dist = d : .Res(ii).Loa = loa
  END WITH
  RETURN FALSE
END FUNCTION


/'* \brief Find the point nearest to a location
\param La Latiture [radians]
\param Lo Longiture [radians]

This constructor searches in all enabled tracks the point nearest to
the given location. In the result array #TS_nearest.Res the four most
nearest point/tracks get collected, if there're more than four tracks
enabled.

\since 0.0
'/
CONSTRUCTOR TS_nearest( _
    BYVAL La AS float _
  , BYVAL Lo AS float)
  Lat = La
  Lon = Lo

  gtk_tree_model_foreach(GTK_TREE_MODEL(GUI->STO) _
    , @TS_nearest._dist(), CAST(gpointer, @THIS))

END CONSTRUCTOR


/'* \brief Callback for computing bounds
\param Model tree model
\param Path line in Model
\param Iter iter in Model
\param UserData unused
\returns FALSE (in order to continue)

This function is designed as a gtk_tree_model_foreach callback. It
computes the bounding box for all tracks.

\since 0.0
'/
FUNCTION TS_bbox._bounds CDECL( _
    BYVAL Model AS GtkTreeModel PTR _
  , BYVAL Path AS GtkTreePath PTR _
  , BYVAL Iter AS GtkTreeIter PTR _
  , BYVAL UserData AS gpointer) AS gboolean
  DIM AS TrackLoader PTR loa
  DIM AS gboolean en
  gtk_tree_model_get(Model, Iter _
    , TST__ENABLE, @en _
    , TST__LOADER, @loa _
    , -1)
  IF NULL = loa THEN RETURN FALSE ' folder row

  WITH PEEK(TS_bbox, UserData)
    IF en OR .Mode THEN
      IF .La0 > loa->Mn.Lat THEN .La0 = loa->Mn.Lat
      IF .La1 < loa->Mx.Lat THEN .La1 = loa->Mx.Lat
      IF .Lo0 > loa->Mn.Lon THEN .Lo0 = loa->Mn.Lon
      IF .Lo1 < loa->Mx.Lon THEN .Lo1 = loa->Mx.Lon
      .Cnt += 1
    END IF
  END WITH
  RETURN FALSE
END FUNCTION


/'* \brief Conpute the bounding box for all tracks
\param Mo Mode of operation (1 = enabled tracks only, 0 = all)

This constructor evaluates the minimum and maximum longitude and
latitude for tracks in the tree store.

\since 0.0
'/
CONSTRUCTOR TS_bbox(BYVAL Mo AS gboolean)
  Mode = Mo

  gtk_tree_model_foreach(GTK_TREE_MODEL(GUI->STO) _
    , @TS_bbox._bounds(), CAST(gpointer, @THIS))

  IF Cnt THEN _
    track_layer_set_bbox(TRACK_LAYER(GUI->TRL), La0, La1, Lo0, Lo1)

END CONSTRUCTOR


/'* \brief Handle new selection
\param Path The path in the tree model as STRING

This procedure handles a selection change in the tree model. The
priviously seleted radio button (if any) gets inactive, and the new one
gets active.

\note We don't use the GtkTreeSelection since it marks the selected row
with a blue bar, overriding the bachground color we want to see.

\since 0.0
'/
SUB TS_select(BYVAL Path AS STRING)
  STATIC AS STRING last
  IF 0 = LEN(Path) THEN EXIT SUB
WITH *GUI
  DIM AS GtkTreeIter iter
  VAR store = GTK_TREE_STORE(.STO) _
    , model = GTK_TREE_MODEL(.STO)
  IF LEN(last) THEN
    gtk_tree_model_get_iter_from_string(model, @iter, last)
    gtk_tree_store_set(store, @iter, TST__SELECT, FALSE, -1)
  END IF
  last = Path
  gtk_tree_model_get_iter_from_string(model, @iter, last)
  gtk_tree_store_set(store, @iter, TST__SELECT, TRUE, -1)
  DIM AS TrackLoader PTR loa
  gtk_tree_model_get(model, @iter, TST__LOADER, @loa, -1)

  VAR p = gtk_tree_path_new_from_string(last)
  gtk_tree_view_expand_to_path(GTK_TREE_VIEW(.TVT), p)
  gtk_tree_path_free(p)
  track_layer_set_loader(TRACK_LAYER(.TRL), loa)
END WITH
END SUB



/'* \brief Open the preference dialog
\param Loa The track to open for

This procedure handles the preference dialog for a track, loading its
parameters in the user interface and providing the dialog to the user.
On `OK` button it reads the new values from the user interface mask and
stores them in the track store model.

\since 0.0
'/
SUB TS_preference(BYVAL Loa AS TrackLoader PTR)
WITH *GUI
  IF NULL = Loa THEN EXIT SUB
  DIM AS gint lw, pw
  DIM AS gchar PTR lc, pc, nam
  DIM AS GtkTreeIter iter
  DIM AS GdkRGBA x
  VAR model = GTK_TREE_MODEL(.STO)

  gtk_tree_model_get_iter_from_string(model, @iter, Loa->Path)
  gtk_tree_model_get(model, @iter _
    , TST____NAME, @nam _
    , TST_P_WIDTH, @pw _
    , TST_L_WIDTH, @lw _
    , TST_P_COLOR, @pc _
    , TST_L_COLOR, @lc _
    , -1)

  IF gdk_rgba_parse(@x, pc) THEN _
    gtk_color_chooser_set_rgba(GTK_COLOR_CHOOSER(.BPC), @x)
  g_free(pc)
  IF gdk_rgba_parse(@x, lc) THEN _
    gtk_color_chooser_set_rgba(GTK_COLOR_CHOOSER(.BLC), @x)
  g_free(lc)
  gtk_adjustment_set_value(GTK_ADJUSTMENT(.APW), (pw AND &b1111) SHL 1)
  gtk_combo_box_set_active( GTK_COMBO_BOX(.CPD), (pw SHR 4) AND &b11)
  gtk_combo_box_set_active( GTK_COMBO_BOX(.CPC), (pw SHR 6) AND &b11)
  gtk_adjustment_set_value(GTK_ADJUSTMENT(.ALW), lw)
  gtk_window_set_title(GTK_WINDOW(.DTP), nam)
  g_free(nam)
WITH *Loa
  gtk_label_set_text(GTK_LABEL(GUI->LTD), .Desc) '?? markup
  VAR la0 = .Mn.Lat * Rad2Deg, la1 = .Mx.Lat * Rad2Deg
  VAR lo0 = .Mn.Lon * Rad2Deg, lo1 = .Mx.Lon * Rad2Deg
  VAR dti = FORMAT(.Mx.Tim - .Mn.Tim, "ttttt")
  gtk_label_set_text(GTK_LABEL(GUI->LTE) _
    , PAR->TimStr(.Mn.Tim) & " (Δ " & dti & ") " & PAR->TimStr(.Mx.Tim) & !"\n" _
    & PAR->lat2str(la0) & " (Δ " & mid(PAR->lat2str(la1-la0), 3) & ") " & PAR->lat2str(la1) & !"\n" _
    & PAR->lon2str(lo0) & " (Δ " & mid(PAR->lon2str(lo1-lo0), 3) & ") " & PAR->lon2str(lo1) & !"\n" _
    & "Ele: " & .Mn.Ele & " (Δ " & (.Mx.Ele-.Mn.Ele) & ") " & .Mx.Ele & !" [m]\n" _
    & "Spd: " & .Mn.Spd & " (Δ " & (.Mx.Spd-.Mn.Spd) & ") " & .Mx.Spd & !" [km/h]\n" _
    & "Dir: " & .Mn.Ang & " (Δ " & (.Mx.Ang-.Mn.Ang) & ") " & .Mx.Ang & " [°]"_
    )
END WITH

  SELECT CASE AS CONST gtk_dialog_run(GTK_DIALOG(.DTP))
  CASE GTK_RESPONSE_OK
    lw = CAST(gint,  gtk_adjustment_get_value(GTK_ADJUSTMENT(.ALW)))
    pw = CAST(gint,  gtk_adjustment_get_value(GTK_ADJUSTMENT(.APW))) SHR 1 _
       + CAST(gint, *gtk_combo_box_get_active_id(GTK_COMBO_BOX(.CPD))) SHL 4 _
       + CAST(gint, *gtk_combo_box_get_active_id(GTK_COMBO_BOX(.CPC))) SHL 6
    gtk_color_chooser_get_rgba(GTK_COLOR_CHOOSER(.BLC), @x)
    lc = gdk_rgba_to_string(@x)
    gtk_color_chooser_get_rgba(GTK_COLOR_CHOOSER(.BPC), @x)
    pc = gdk_rgba_to_string(@x)
    gtk_tree_store_set(GTK_TREE_STORE(.STO), @iter _
      , TST_P_WIDTH, pw _
      , TST_L_WIDTH, lw _
      , TST_P_COLOR, pc _
      , TST_L_COLOR, lc _
      , -1)
    g_free(pc)
    g_free(lc)
    track_layer_redraw(TRACK_LAYER(.TRL))
  CASE 1
    TS_remove(@iter)
  CASE 2 '!! for testing: center track on map
    track_layer_set_loader(TRACK_LAYER(.TRL), Loa)
  END SELECT
  gtk_widget_hide(GTK_WIDGET(.DTP))
END WITH
END SUB
