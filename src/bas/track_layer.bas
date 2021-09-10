/'* \file track_layer.bas
\brief Source for advanced tracks layer

FIXME

\since 0.0
'/

#INCLUDE ONCE "cairo/cairo.bi"
#INCLUDE ONCE "Gir/OsmGpsMap-1.0.bi"
#INCLUDE ONCE "Gir/_GLibMacros-2.0.bi"
#INCLUDE ONCE "Gir/_GObjectMacros-2.0.bi"
#INCLUDE ONCE "track_layer.bi"
#INCLUDE ONCE "track_store.bi"
#INCLUDE ONCE "gui.bi"
'#INCLUDE ONCE "debug.bi"
#INCLUDE ONCE "string.bi"

TYPE as single float '!! FIXME


DECLARE SUB track_layer_interface_init CDECL(BYVAL AS OsmGpsMapLayerIface PTR)

'* \brief Array of default setting for loaded tracks
STATIC SHARED AS TrackLayerDefault DEFAULT_ENTRIES(...) = { _
  TYPE(@!"\&b00100111" "rgba(0xA4,0x00,0x00,1)", @!"\1" "#EF2929") _
, TYPE(@!"\&b01000111" "rgba(0xCE,0x5C,0x00,1)", @!"\1" "#FCAF3E") _
, TYPE(@!"\&b10010111" "rgba(0xC4,0xA0,0x00,1)", @!"\1" "#FCE94F") _
, TYPE(@!"\&h34" "rgba(0x4E,0x9A,0x06,1)", @!"\4" "#8AE234") _
, TYPE(@!"\&h35" "rgba(0x20,0x4A,0x87,1)", @!"\5" "#729FCF") _
, TYPE(@!"\&h35" "rgba(0x5C,0x35,0x66,1)", @!"\4" "#AD7FA8") _
, TYPE(@!"\&h35" "rgba(0x8F,0x59,0x02,1)", @!"\5" "#E9B96E") _
, TYPE(@!"\&h34" "rgba(0x2E,0x34,0x36,1)", @!"\4" "#888A85") _
, TYPE(@!"\&h34" "rgba(0xBA,0xBD,0xB6,1)", @!"\4" "#EEEEEC") _
, TYPE(NULL, NULL)}


'* \brief Enumerators for property IDs
ENUM
  PROP_0
  PROP_TL_W
  PROP_TL_H
  PROP__MAP
  PROP_PREF
  PROP_LOAD
  PROP_FSIZ
  PROP_FTYP
END ENUM


/'* \brief TrackLayers private data

This structure holds the private (internal) data for the #TrackLayer
GObject.

\since 0.0
'/
TYPE _TrackLayerPrivate
  AS OsmGpsMap PTR _
    Map     ' the corresponding map (prop "map")
  AS TrackLoader PTR _
    Loader  ' the active track (prop "loader")
  AS TrackLayerDefault PTR _
    Default '*< default values width/color (prop "defaults")
  AS cairo_t PTR _
    Cr      '*< layer
  AS cairo_surface_t PTR _
    Surface _   '*< layer surface (track background)
  , InfoSurface '*< surface for info pad
  AS gchar PTR _
    FTyp  '*< font family (prop "font-type")
  AS gint _
    Nxt _ '*< next index (defaults)
  , TIx _ '*< info surface x position
  , TIy _ '*< info surface y position
  , TIw _ '*< info surface width
  , TIh _ '*< info surface height
  , TLz _ '*< map zoom
  , TLx _ '*< map X
  , TLy _ '*< map Y
  , TLw _ '*< map width (prop "width")
  , TLh _ '*< map height (prop "height")
  , FSiz  '*< font size (prop "font-size")
  AS gboolean _
    LayReSurf '*< flag for layer surface redo
END TYPE

' ?? G_ADD_PRIVATE doesn't work (memory conflict) -> classic style
'G_DEFINE_TYPE_WITH_CODE(TrackLayer, track_layer, G_TYPE_OBJECT _
   ', G_ADD_PRIVATE(TrackLayer) _
   ': G_IMPLEMENT_INTERFACE(OSM_TYPE_GPS_MAP_LAYER, track_layer_interface_init))
G_DEFINE_TYPE_WITH_CODE(TrackLayer, track_layer, G_TYPE_OBJECT _
   , G_IMPLEMENT_INTERFACE(OSM_TYPE_GPS_MAP_LAYER, track_layer_interface_init))


DECLARE SUB render_info CDECL(BYVAL AS TrackLayer PTR, BYVAL AS OsmGpsMap PTR)
DECLARE SUB track_layer_render CDECL(BYVAL AS OsmGpsMapLayer PTR, BYVAL AS OsmGpsMap PTR)
DECLARE SUB track_layer_draw CDECL(BYVAL AS OsmGpsMapLayer PTR, BYVAL AS OsmGpsMap PTR, BYVAL AS cairo_t PTR)
DECLARE FUNCTION track_layer_busy CDECL(BYVAL AS OsmGpsMapLayer PTR) AS gboolean
DECLARE FUNCTION track_layer_button_press CDECL(BYVAL AS OsmGpsMapLayer PTR, BYVAL AS OsmGpsMap PTR, BYVAL AS GdkEventButton PTR) AS gboolean


/'* \brief Initialise the interface functions
\param Iface The interface to modify

This procedure is part of the OsmGpsMapLayer implementation. It
initialises the interface functions.

\since 0.0
'/
SUB track_layer_interface_init CDECL(BYVAL Iface AS OsmGpsMapLayerIface PTR)
  Iface->render = @track_layer_render()
  Iface->draw   = @track_layer_draw()
  Iface->busy   = @track_layer_busy()
  Iface->button_press = @track_layer_button_press()
END SUB


/'* \brief Handling property fetching
\param Obj GObject instance
\param Property_id Registration number
\param Value The value to fetch
\param Pspec Specification (for warning message)

This procedure is part of the GObject implementation. It gets a value
from a certain property.

\since 0.0
'/
SUB track_layer_get_property CDECL( _
    BYVAL Obj AS Gobject PTR _
  , BYVAL Property_id AS guint _
  , BYVAL Value AS GValue PTR _
  , BYVAL Pspec AS GParamSpec PTR)
WITH *TRACK_LAYER(Obj)->Priv
  SELECT CASE AS CONST Property_id
  CASE PROP_TL_W : g_value_set_int(Value, .TLw)
  CASE PROP_TL_H : g_value_set_int(Value, .TLh)
  CASE PROP__MAP : g_value_set_pointer(Value, .Map)
  CASE PROP_PREF : g_value_set_pointer(Value, .Default)
  CASE PROP_LOAD : g_value_set_pointer(Value, .Loader)
  CASE PROP_FSIZ : g_value_set_int(Value, .FSiz)
  CASE PROP_FTYP : g_value_set_string(Value, .FTyp)
  CASE ELSE
    G_OBJECT_WARN_INVALID_PROPERTY_ID(Obj, Property_id, Pspec)
  END SELECT
END WITH
END SUB


/'* \brief Callback fetching map size
\param Wid Widget getting configured (=MAP, unused)
\param Event The new data
\param UDat Unused here
\returns FALSE to propagate the event further

Callback to hook into the configure event for the map widget. When the
map width or height changes due to a user action (ie. full screen), the
layer needs an adapted surface.

\since 0.0
'/
FUNCTION on_MAP_configure_event CDECL( _
  BYVAL Wid AS GtkWidget PTR _
, BYVAL Event AS GdkEventConfigure PTR _
, BYVAL UDat AS GPOINTER) AS gboolean
WITH Peek(TrackLayerPrivate, UDat)
  IF .TLw <> Event->width  THEN .TLw = Event->width  : .LayReSurf = TRUE
  IF .TLh <> Event->height THEN .TLh = Event->height : .LayReSurf = TRUE
END WITH : RETURN FALSE
END FUNCTION


/'* \brief Handling property setting
\param Obj GObject instance
\param Property_id Registration number
\param Value The new value
\param Pspec Specification (for warning message)

This procedure is part of the GObject implementation. It sets a new
value for a certain property.

\since 0.0
'/
SUB track_layer_set_property CDECL( _
    BYVAL Obj AS Gobject PTR _
  , BYVAL Property_id AS guint _
  , BYVAL Value AS CONST GValue PTR _
  , BYVAL Pspec AS GParamSpec PTR)
WITH *TRACK_LAYER(Obj)->Priv
  SELECT CASE AS CONST Property_id
  CASE PROP_TL_W : .TLw = g_value_get_int(Value)
  CASE PROP_TL_H : .TLh = g_value_get_int(Value)
  CASE PROP__MAP
    if .Map then
      osm_gps_map_layer_remove(OSM_GPS_MAP(.Map), OSM_GPS_MAP_LAYER(Obj))
      g_object_unref(.Map)
    end if
    .Map = g_value_get_pointer(Value)
    g_object_ref(.Map)
    VAR osm = GTK_WIDGET(.Map)
    .TLw = gtk_widget_get_allocated_width(osm)
    .TLh = gtk_widget_get_allocated_height(osm)
    osm_gps_map_layer_add(OSM_GPS_MAP(.Map), OSM_GPS_MAP_LAYER(Obj))
    g_signal_connect(.Map, "configure_event" _
      , G_CALLBACK(@on_MAP_configure_event()), TRACK_LAYER(Obj)->Priv)
  CASE PROP_PREF
    .Default = g_value_get_pointer(Value)
    .Nxt = -1
    IF NULL = .Default THEN .Default = @DEFAULT_ENTRIES(0)
  CASE PROP_LOAD : .Default = g_value_get_pointer(Value)
  CASE PROP_FSIZ : .FSiz = g_value_get_int(Value)
  CASE PROP_FTYP : g_free(.FTyp) : .FTyp = g_value_dup_string(Value)
    IF 0 = .FTyp ORELSE 0 = .FTyp[0] THEN .FTyp = g_strdup(@"Sans")
  CASE ELSE
    G_OBJECT_WARN_INVALID_PROPERTY_ID(Obj, Property_id, Pspec)
  END SELECT
END WITH
END SUB


/'* \brief GObjectClass CTOR
\param Typ Objects GType
\param N_prop Number of properties
\param Prop Construction parameters
\returns The constructed GObject

This function is part of the GObject implementation. That constructor
is setting the start values in the _TrackLayerPrivate structure, after
chaining up to the parents constructor.

\since 0.0
'/
FUNCTION track_layer_constructor CDECL( _
    BYVAL Typ AS GType _
  , BYVAL N_prop AS guint _
  , BYVAL Prop AS GObjectConstructParam PTR) AS Gobject PTR
  ' chain up to the parent constructor */
  VAR obj = G_OBJECT_CLASS(track_layer_parent_class)->constructor(Typ, N_prop, Prop)

  WITH *TRACK_LAYER(obj)->Priv
    .Loader = NULL

    .Default = @DEFAULT_ENTRIES(0)
    .Nxt = -1

    .Surface = NULL
    .LayReSurf = TRUE

    .TIw = PAR->InfoFontSize * 10
    .TIh = PAR->InfoFontSize * 7
    .InfoSurface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, .TIw, .TIh)
  END WITH
  RETURN obj
END FUNCTION


/'* \brief GObjectClass finalisation
\param Obj The instance to work on

This procedure is part of the GObject implementation. It handles the
freeing of the used surfaces in this case, chaining up to the parents
finalisation.

\since 0.0
'/
SUB track_layer_finalize CDECL(BYVAL Obj AS Gobject PTR)
WITH *TRACK_LAYER(Obj)->Priv
  IF .Surface THEN cairo_surface_destroy(.Surface)
  cairo_surface_destroy(.InfoSurface)
END WITH
  G_OBJECT_CLASS(track_layer_parent_class)->finalize(Obj)
END SUB


/'* \brief GObjectClass initialization
\param klass Class to initiate

This procedure is part of the GObjectClass implementation. It handles
the interface setting and the properties in this case.

\since 0.0
'/
SUB track_layer_class_init CDECL(BYVAL klass AS TrackLayerClass PTR)
  g_type_class_add_private(klass, SIZEOF(TrackLayerPrivate))
  VAR object_class = G_OBJECT_CLASS(klass)

  object_class->get_property = @track_layer_get_property()
  object_class->set_property = @track_layer_set_property()
  object_class->constructor  = @track_layer_constructor()
  object_class->finalize     = @track_layer_finalize()

  '* The width property.
  g_object_class_install_property( _
      object_class _
    , PROP_TL_W _
    , g_param_spec_int("width" _
      , "width" _
      , "map width" _
      , G_MININT _
      , G_MAXINT _
      , 450 _
      , G_PARAM_READWRITE OR G_PARAM_CONSTRUCT_ONLY))

  '* The height property.
  g_object_class_install_property( _
      object_class _
    , PROP_TL_H _
    , g_param_spec_int("height" _
      , "height" _
      , "map height" _
      , G_MININT _
      , G_MAXINT _
      , 300 _
      , G_PARAM_READWRITE OR G_PARAM_CONSTRUCT_ONLY))

  '* The map property.
  g_object_class_install_property( _
      object_class _
    , PROP__MAP _
    , g_param_spec_pointer("map" _
      , "map" _
      , "the corresponding map widget" _
      , G_PARAM_READWRITE OR G_PARAM_CONSTRUCT))

  '* The defaults property.
  g_object_class_install_property( _
      object_class _
    , PROP_PREF _
    , g_param_spec_pointer("defaults" _
      , "defaults" _
      , "array of default parameters" _
      , G_PARAM_READWRITE OR G_PARAM_CONSTRUCT))

  '* The loader property.
  g_object_class_install_property( _
      object_class _
    , PROP_LOAD _
    , g_param_spec_pointer("loader" _
      , "loader" _
      , "the active track loader" _
      , G_PARAM_READWRITE OR G_PARAM_CONSTRUCT))

  '* The font-size property.
  g_object_class_install_property( _
      object_class _
    , PROP_FSIZ _
    , g_param_spec_int("font-size" _
      , "FontSize" _
      , "font size for info pad" _
      , 6 _
      , 24 _
      , 12 _
      , G_PARAM_READWRITE OR G_PARAM_CONSTRUCT))

  '* The font-type property.
  g_object_class_install_property( _
      object_class _
    , PROP_FTYP _
    , g_param_spec_string("font-type" _
      , "InfoPadFontType" _
      , "font family for info pad" _
      , @"Sans" _
      , G_PARAM_READWRITE OR G_PARAM_CONSTRUCT))
END SUB


/'* \brief GObject init procedure
\param Self Object to initiate

This procedure is part of the GObject implementation. It sets the
pointer to the _TrackLayerPrivate structure in this case.

\since 0.0
'/
SUB track_layer_init CDECL(BYVAL Self AS TrackLayer PTR)
  Self->Priv = _
    G_TYPE_INSTANCE_GET_PRIVATE(Self, TRACK_TYPE_LAYER, TrackLayerPrivate)
END SUB


/'* \brief Callback for drawing the layer surfaces
\param Lay Layer instance
\param Map Map widget sending the signal
\param Cr Cairl contents to draw on

This function is part of the OsmGpsMapLayer implementation. It handles
the (re)drawing of the layer surface, ie when a part of the widget gets
covered by another widget.

\since 0.0
'/
SUB track_layer_draw cdecl( _
    BYVAL Lay AS OsmGpsMapLayer PTR _
  , BYVAL Map AS OsmGpsMap PTR _
  , BYVAL Cr AS cairo_t PTR)

  g_return_if_fail(TRACK_IS_LAYER(Lay))

WITH *TRACK_LAYER(Lay)->Priv
  IF .Surface THEN
    cairo_set_source_surface(Cr, .Surface, 0, 0)
    cairo_paint(Cr)
  END IF

  IF PAR->LayOn ANDALSO .InfoSurface THEN
    cairo_set_source_surface(Cr, .InfoSurface, .TIx, .TIy)
    cairo_paint(Cr)
  END IF
END WITH
END SUB


/'* \brief Callback for busy layer
\param Lay Layer instance
\returns FALSE

This function is part of the OsmGpsMapLayer implementation. It returns
if there're pending operations on the layer, ie like unfinished
animations. Here it returns always FALSE.

\since 0.0
'/
FUNCTION track_layer_busy CDECL(BYVAL Lay AS OsmGpsMapLayer PTR) AS gboolean
  RETURN FALSE
END FUNCTION


/'* \brief Callback for button event
\param Lay Layer receiving the event
\param Map Map widget propagating the event
\param Event Event sended
\returns FALSE to propagate event further, TRUE when handled

This function is part of the OsmGpsMapLayer implementation. It handles
button events (mouse clicks) on the map, only clicks with `<shift>` or
`<control>` keys pressed in this case.

A `<shift>` click searches in the active track for the point nearest to
the click poisition. If the distance is below a certain value, that
nearest point gets the current point in the active track.

In case of a `<shift><control>` click not only the active, but all
tracks are searched for the nearest point. When that nearest point is
in another track, this track gets the active track.

\since 0.0
'/
FUNCTION track_layer_button_press CDECL( _
    BYVAL Lay AS OsmGpsMapLayer PTR _
  , BYVAL Map AS OsmGpsMap PTR _
  , BYVAL Event AS GdkEventButton PTR) AS gboolean
  g_return_val_if_fail(TRACK_IS_LAYER(Lay), FALSE)

  VAR state = Event->state XOR GDK_MOD2_MASK
  IF NOT((GDK_CONTROL_MASK + GDK_SHIFT_MASK + GDK_LOCK_MASK) AND state) THEN RETURN FALSE

  DIM AS float lat, lon
  VAR osm = OSM_GPS_MAP(GUI->MAP) _
     , pt = osm_gps_map_get_event_location(osm, Event)
  osm_gps_map_point_get_radians(pt, @lat, @lon)
  osm_gps_map_point_free(pt)
  VAR sc = osm_gps_map_get_scale(osm) _
    , d = osm_gps_map_get_scale(osm) * PAR->NearDist / ERA

  IF GDK_CONTROL_MASK AND Event->state THEN '          search all tracks
    WITH TYPE<TS_nearest>(lat, lon)
      VAR ii = -1L, ni = 0L
      FOR i AS LONG = 0 TO UBOUND(.Res)
        IF NULL = .Res(i).Loa THEN EXIT FOR
        IF .Res(i).Dist < d THEN ni += 1 : ii = i : d = .Res(i).Dist
      NEXT
      IF 0 = ni THEN RETURN TRUE
      'if ni > 1 then '?? handle multiple tracks
      WITH *.Res(ii).Loa
        lat = .V[.Tmp].Lat
        lon = .V[.Tmp].Lon
        .Cur = .Tmp
      END WITH
      TS_select(.Res(ii).Loa->Path)
    END WITH
  ELSE '                                        search only active track
    WITH *TRACK_LAYER(Lay)->Priv
      IF 0 = .Loader THEN RETURN FALSE
      IF d < .Loader->Nearest(lon, lat) THEN RETURN FALSE
      WITH *.Loader
        lat = .V[.Tmp].Lat
        lon = .V[.Tmp].Lon
        .Cur = .Tmp
      END WITH
    END WITH
    osm_gps_map_set_center(OSM_GPS_MAP(GUI->MAP), Rad2Deg*lat, Rad2Deg*lon)
  END IF
  RETURN TRUE
END FUNCTION


/'* \brief Creates a new instance of TrackLayer.
\param Map Map object to connect to
\returns The newly created TrackLayer instance (transfer full)

A new #TrackLayer instance gets created and added to the \osm
given as parameter. Also a callback gets connected in order to track
any configure changes of the map window.

\note Use g_object_unref() to finalize the instance.

\since 0.0
'/
FUNCTION track_layer_new(BYVAL Map AS GObject PTR) AS TrackLayer PTR
  g_return_val_if_fail(OSM_IS_GPS_MAP(Map), NULL)
  'VAR osm = GTK_WIDGET(Map) _
      ', w = gtk_widget_get_allocated_width(osm) _
      ', h = gtk_widget_get_allocated_height(osm)
  'VAR r = g_object_new(TRACK_TYPE_LAYER _
            ', "map", Map _
            ', "width", w _
            ', "height", h _
            ', NULL)
  'osm_gps_map_layer_add(OSM_GPS_MAP(Map), OSM_GPS_MAP_LAYER(r))
  'g_signal_connect(Map, "configure_event" _
    ', G_CALLBACK(@on_MAP_configure_event()), TRACK_LAYER(r)->Priv)
  'RETURN r
  RETURN g_object_new(TRACK_TYPE_LAYER, "map", Map, NULL)
END FUNCTION


/'* \brief Render right alligned text, bottom up
\param Cr Cairo context to work on
\param Y Vertical position (line)
\param W Width of the surface
\param S String to render

Procedure to render a right alligned text in to the
_TrackLayerPrivate.InfoSurface. The black text gets a white border, in
order to be readable on dark backgrounds. The next line position gets
returned in parameter Y.

\since 0.0
'/
SUB render_rtext(BYVAL Cr AS cairo_t PTR, BYREF Y AS LONG, BYREF W AS LONG, BYREF S AS STRING)
  IF 0 = LEN(S) THEN EXIT SUB

  DIM AS cairo_text_extents_t extents
  cairo_text_extents(Cr, S, @extents)
  g_assert(extents.width <> 0.0)

  VAR xt = W - extents.width - 2 _
    , yt = Y - extents.y_bearing
  cairo_set_source_rgb(Cr, 1.0, 1.0, 1.0)
  cairo_set_line_width(Cr, PAR->InfoFontSize/6)
  cairo_move_to(Cr, xt, yt)
  cairo_text_path(Cr, S)
  cairo_stroke(Cr)

  cairo_set_source_rgb(Cr, 0.0, 0.0, 0.0)
  cairo_move_to(Cr, xt, yt)
  cairo_show_text(Cr, S)
    '/* skip + 1/5 line */
  y -= PAR->InfoFontSize*6\5
END SUB


/'* \brief Render the info pad
\param Lay The layer instance
\param Map Map instance calling

Procedure renders new values in to the info pad (in the right bottom
corner when Layer enabled). On a transparent background either only the
coordinates of the map center, or - when a track is active -
additionaly the current track point details get rendered to the
TrackLayerPrivate.InfoSurface, to be shown in the next call to
track_layer_draw().

\since 0.0
'/
SUB render_info( _
    BYVAL Lay AS TrackLayer PTR _
  , BYVAL Map AS OsmGpsMap PTR)
WITH *Lay->Priv
  IF 0 = .InfoSurface THEN EXIT SUB

  '/* first fill with transparency */
  VAR cr = cairo_create(.InfoSurface)
  cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE)
  '~ cairo_set_source_rgba(cr, 1.0, 1.0, 1.0, 0.5)
  cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 0.0)
  cairo_paint(cr)
  cairo_set_operator(cr, CAIRO_OPERATOR_OVER)

  cairo_select_font_face(cr _
    , .FTyp _
    , CAIRO_FONT_SLANT_NORMAL _
    , CAIRO_FONT_WEIGHT_BOLD)
  cairo_set_font_size(cr, .FSiz)

  DIM AS LONG y = .TIh - PAR->InfoFontSize, w = .TIw
  IF .Loader ANDALSO .Loader->Cur >= 0 THEN
WITH .Loader->V[.Loader->Cur]
    'render_rtext(cr, y, w, FORMAT(.Tim, ""yymmdd-hh:mm:ss"))
    'render_rtext(cr, y, w, PAR->TimStr(@Lay->Priv->Loader->V[Lay->Priv->Loader->Cur]))
    render_rtext(cr, y, w, PAR->TimStr(.Tim))
    render_rtext(cr, y, w, PAR->lon2str(.Lon * Rad2Deg))
    'render_rtext(cr, y, w, PAR->lon2str(@Lay->Priv->Loader->V[.Loader->Cur]))
    render_rtext(cr, y, w, PAR->lat2str(.Lat * Rad2Deg))
    render_rtext(cr, y, w, FORMAT(.Ele, "##### \m") & FORMAT(.Ang, " ###\°"))
    render_rtext(cr, y, w, FORMAT(.Spd, "##### ""km/h"""))
END WITH
    render_rtext(cr, y, w, FORMAT(.Loader->Cur, "###### \(") & FORMAT(.Loader->Az, "###### \)"))
  ELSE
    DIM AS gfloat lat, lon
    g_object_get(Map, "latitude", @lat, "longitude", @lon, NULL)
    render_rtext(cr, y, w, PAR->lon2str(lon))
    render_rtext(cr, y, w, PAR->lat2str(lat))
  END IF
END WITH
END SUB



/'* \brief Render an enabled track
\param Model GtkTreeModel to work on
\param Path Line in model (unused here)
\param Iter Data Position
\param TLPriv TrackLayerPriv pointer
\returns FALSE to continue foreach calls

Callback designed as a GtkTreeModelForeachFunc. It greps the track data
from the model at iter position, doing nothing when that track is
disabled. Otherwise, when enabled, it renders line and points to the
TrackLayerPriv.Surface to be shown in the next call to
track_layer_draw().

\since 0.0
'/
FUNCTION render_track CDECL( _
    BYVAL Model AS GtkTreeModel PTR _
  , BYVAL Path AS GtkTreePath PTR _
  , BYVAL Iter AS GtkTreeIter PTR _
  , BYVAL TLPriv AS gpointer) AS gboolean
  DIM AS gboolean en
  gtk_tree_model_get(Model, Iter _
    , TST__ENABLE, @en _
    , -1)
  IF FALSE = en THEN RETURN FALSE

  DIM AS gint lw, pw
  DIM AS gchar PTR lcs, pcs
  DIM AS TrackLoader PTR loa
  gtk_tree_model_get(Model, Iter _
    , TST_P_WIDTH, @pw _
    , TST_L_WIDTH, @lw _
    , TST_P_COLOR, @pcs _
    , TST_L_COLOR, @lcs _
    , TST__LOADER, @loa _
    , -1)
  DIM AS GdkRGBA lc, pc
  gdk_rgba_parse(@pc, pcs) : g_free(pcs)
  gdk_rgba_parse(@lc, lcs) : g_free(lcs)
  IF NULL = loa THEN RETURN false

WITH PEEK(TrackLayerPrivate, TLPriv)
  IF loa->Pixel(.TLx, .TLy, .TLz) THEN RETURN false
  ' lines
  IF lw THEN
    cairo_set_line_width(.Cr, lw)
    cairo_set_source_rgba(.Cr, lc.red, lc.green, lc.blue, lc.alpha)
    cairo_set_line_cap(.Cr, CAIRO_LINE_CAP_ROUND)
    cairo_set_line_join(.Cr, CAIRO_LINE_JOIN_ROUND)
    cairo_move_to(.Cr, loa->V[0].Xpix, loa->V[0].Ypix)
    FOR i AS INTEGER = 1 TO loa->Az
      cairo_line_to(.Cr, loa->V[i].Xpix, loa->V[i].Ypix)
    NEXT
    cairo_stroke(.Cr)
  END IF
  ' points
  IF pw AND &b1111 THEN
    cairo_set_source_rgba(.Cr, pc.red, pc.green, pc.blue, pc.alpha)
    SELECT CASE AS CONST pw
    CASE &b0001 TO &b1111 ' fast simple
      FOR i AS INTEGER = 0 TO loa->Az
        cairo_new_sub_path(.Cr)
        cairo_arc(.Cr, loa->V[i].Xpix, loa->V[i].Ypix, pw, 0.0, PIx2)
      NEXT : cairo_fill(.Cr)
    CASE ELSE ' complex
      DIM AS INTEGER p4, p6
      DIM AS float up_4, up_6, low4, low6
      IF pw AND &b00110000 THEN
        SELECT CASE AS CONST (pw SHR 4) AND &b11
        CASE 1 : p4 = OFFSETOF(TrP, Ele) : low4 = loa->Mn.Ele : up_4 = loa->Mx.Ele
        CASE 2 : p4 = OFFSETOF(TrP, Spd) : low4 = loa->Mn.Spd : up_4 = loa->Mx.Spd
        CASE 3 : p4 = OFFSETOF(TrP, Ang) : low4 = loa->Mn.Ang : up_4 = loa->Mx.Ang
        END SELECT
      END IF
      IF pw AND &b11000000 THEN
        SELECT CASE AS CONST (pw SHR 6) AND &b11
        CASE 1 : p6 = OFFSETOF(TrP, Ele) : low6 = loa->Mn.Ele : up_6 = loa->Mx.Ele
        CASE 2 : p6 = OFFSETOF(TrP, Spd) : low6 = loa->Mn.Spd : up_6 = loa->Mx.Spd
        CASE 3 : p6 = OFFSETOF(TrP, Ang) : low6 = loa->Mn.Ang : up_6 = loa->Mx.Ang
        END SELECT
      END IF

      IF p4 ANDALSO p6 THEN '                variable diameter and alpha
        VAR fac4 = IIF(up_4 <> low4, ((pw AND &b1111) - 1) / (up_4 - low4), 1.) _
          , fac6 = IIF(up_6 <> low6, .9 / (up_6 - low6), 1.)
        FOR i AS INTEGER = 0 TO loa->Az
          VAR a = .1 + (PEEK(float, CAST(ANY PTR, @loa->V[i]) + p6) - low6) * fac6 _
            , r = 1. + (PEEK(float, CAST(ANY PTR, @loa->V[i]) + p4) - low4) * fac4
          cairo_set_source_rgba(.Cr, pc.red, pc.green, pc.blue, a)
          cairo_arc(.Cr, loa->V[i].Xpix, loa->V[i].Ypix, r, 0.0, PIx2)
          cairo_fill(.Cr)
        NEXT
      ELSEIF p4 THEN '                                 variable diameter
        VAR fac = IIF(up_4 <> low4, ((pw AND &b1111) - 1) / (up_4 - low4), 1.)
        FOR i AS INTEGER = 0 TO loa->Az
          VAR r = 1. + (PEEK(float, CAST(ANY PTR, @loa->V[i]) + p4) - low4) * fac
          cairo_new_sub_path(.Cr)
          cairo_arc(.Cr, loa->V[i].Xpix, loa->V[i].Ypix, r, 0.0, PIx2)
        NEXT : cairo_fill(.Cr)
      ELSE '                                              variable alpha
        VAR r = pw AND &b1111 _
        , fac = IIF(up_6 <> low6, .9 / (up_6 - low6), 1.)
        FOR i AS INTEGER = 0 TO loa->Az
          VAR a = .1 + (PEEK(float, CAST(ANY PTR, @loa->V[i]) + p6) - low6) * fac
          cairo_set_source_rgba(.Cr, pc.red, pc.green, pc.blue, a)
          cairo_arc(.Cr, loa->V[i].Xpix, loa->V[i].Ypix, r, 0.0, PIx2)
          cairo_fill(.Cr)
        NEXT
      END IF
    END SELECT
  END IF
END WITH
END FUNCTION


/'* \brief Render enabled tracks and info pad
\param Lay The layer we're working for
\param Map The parent map widget

This procedure is part of the OsmGpsMapLayer implementation. It takes
care that the TrackLayerPriv.Surface matches the map size
(width/height) and renders all enabled tracks (line/points) to that
surface. Additionaly it renders the info pad, when enabled.

\since 0.0
'/
SUB track_layer_render CDECL( _
    BYVAL Lay AS OsmGpsMapLayer PTR _
  , BYVAL Map AS OsmGpsMap PTR)

  g_return_if_fail(TRACK_IS_LAYER(Lay))

WITH *TRACK_LAYER(Lay)->Priv
  IF .LayReSurf THEN
    IF .Surface THEN cairo_surface_destroy(.Surface)
    .TIx = .TLw - .TIw - 5
    .TIy = .TLh - .TIh - 5
    render_info(TRACK_LAYER(Lay), Map)
    .Surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, .TLw, .TLh)
    .LayResurf = FALSE
  END IF
  .Cr = cairo_create(.Surface)

  g_object_get(GUI->MAP _
  , "map-x", @.TLx _
  , "map-y", @.TLy _
  , "zoom" , @.TLz _
  , NULL)

  '/* first fill with transparency */
  cairo_set_operator(.Cr, CAIRO_OPERATOR_SOURCE)
  cairo_set_source_rgba(.Cr, 1.0, 0.0, 0.0, 0.0)
  cairo_paint(.Cr)
  cairo_set_operator(.Cr, CAIRO_OPERATOR_OVER)

  gtk_tree_model_foreach(GTK_TREE_MODEL(GUI->STO) _
    , @render_track(), CAST(gpointer, TRACK_LAYER(Lay)->Priv))

  IF PAR->LayOn THEN render_info(TRACK_LAYER(Lay), Map)
  cairo_destroy(.Cr)
END WITH
END SUB


/'* \brief Provide the next default setting
\param Lay Layer instance
\returns Pointer to default setting for the next track

The #TrackLayer instance holds a number of default settings for line
and point color and width, used as start values when loading a new
track. This function returns a pointer to the next setting, reseting to
the first when all defaults were used.

\since 0.0
'/
FUNCTION track_layer_get_default CDECL( _
  BYVAL Lay AS TrackLayer PTR) AS TrackLayerDefault PTR

  g_return_val_if_fail(TRACK_IS_LAYER(Lay), NULL)

  WITH *Lay->Priv
    .Nxt += 1 : IF NULL = .Default[.Nxt].P THEN .Nxt = 0
    RETURN @.Default[.Nxt]
  END WITH
END FUNCTION


/'* \brief Provide pointer to the active track
\param Lay Layer instance
\returns Pointer to currently active track

In the #TrackLayer instance one of the loaded tracks is the active
track. This function returns the pointer to that track.

\since 0.0
'/
FUNCTION track_layer_get_loader CDECL( _
  BYVAL Lay AS TrackLayer PTR) AS TrackLoader PTR

  g_return_val_if_fail(TRACK_IS_LAYER(Lay), NULL)

  RETURN Lay->Priv->Loader
END FUNCTION


/'* \brief Show complete track
\param Lay Layer instance

Procedure setting map position (center) and zoom to show the active
track completely on the map.

\since 0.0
'/
SUB track_layer_center_track CDECL( _
  BYVAL Lay AS TrackLayer PTR)

  g_return_if_fail(TRACK_IS_LAYER(Lay))

  IF 0 = Lay->Priv->Loader THEN EXIT SUB
WITH *Lay->Priv->Loader
  .MapCenter(Lay->Priv->TLw, Lay->Priv->TLh)
  osm_gps_map_set_center_and_zoom(OSM_GPS_MAP(GUI->MAP), .UsLa, .UsLo, .UsZo)
END WITH
END SUB


/'* \brief Set active track
\param Lay Layer instance
\param Loa Track to activate (or NULL)

Procedure receiving a track to make it the active one. When Loa is
NULL, no track is active.

\since 0.0
'/
SUB track_layer_set_loader CDECL( _
  BYVAL Lay AS TrackLayer PTR _
, BYVAL Loa AS TrackLoader PTR)

  g_return_if_fail(TRACK_IS_LAYER(Lay))

  Lay->Priv->Loader = Loa : IF 0 = Loa THEN EXIT SUB
WITH *Loa
  IF .UsZo < 0 THEN .MapCenter(Lay->Priv->TLw, Lay->Priv->TLh)
  osm_gps_map_set_center_and_zoom(OSM_GPS_MAP(GUI->MAP), .UsLa, .UsLo, .UsZo)
END WITH
END SUB


/'* \brief Redraw surface
\param Lay Layer instance

Procedure forcing a redraw of the TrackLayerPriv.Surface, ie to show
adapted track settings.

\since 0.0
'/
SUB track_layer_redraw CDECL(BYVAL Lay AS TrackLayer PTR)

  g_return_if_fail(TRACK_IS_LAYER(Lay))

WITH *Lay->Priv
  track_layer_render(OSM_GPS_MAP_LAYER(Lay), .Map)
  gtk_widget_queue_draw(GTK_WIDGET(.Map))
END WITH
END SUB


/'* \brief Get current point in active track
\param Lay Layer instance
\returns The point number (or -1)

When the #TrackLayer holds an active track, a current point in that
track can get centered on the map. This function provides the point
index (0 <= p\# <= AZ).

\since 0.0
'/
FUNCTION track_layer_get_point CDECL(BYVAL Lay AS TrackLayer PTR) AS gint

  g_return_val_if_fail(TRACK_IS_LAYER(Lay), -1)
  IF NULL = Lay->Priv->Loader THEN RETURN -1
  RETURN Lay->Priv->Loader->Cur

END FUNCTION


/'* \brief Set current point in active track
\param Lay Layer instance
\param N New current point index

When the #TrackLayer holds an active track, a current point in that
track can get centered on the map. This function sets a point index to
for the next current point. The N parameter gets clamped to the allowed
range (0 <= N <= AZ).

\since 0.0
'/
SUB track_layer_set_point CDECL(BYVAL Lay AS TrackLayer PTR, BYVAL N AS gint)

  g_return_if_fail(TRACK_IS_LAYER(Lay))
  IF NULL = Lay->Priv->Loader THEN EXIT SUB

WITH *Lay->Priv->Loader
  .Cur = IIF(N > .Az, .Az, IIF(N < 0, 0, N))
  .UsLa = Rad2Deg * .V[.Cur].Lat
  .UsLo = Rad2Deg * .V[.Cur].Lon
  .UsZo = .CoZo
  osm_gps_map_set_center_and_zoom(OSM_GPS_MAP(GUI->MAP), .UsLa, .UsLo, .UsZo)
END WITH
END SUB


/'* \brief Set map segment to the given bounding box
\param Lay Layer instance
\param La0 Top latitude [radians]
\param La1 Bottom latitude [radians]
\param Lo0 Left longitude [radians]
\param Lo1 Right longitude [radians]

Procedure setting the map center and zoom in order to show a given
rectangle.

\note Coordinates in radians here!

\since 0.0
'/
SUB track_layer_set_bbox CDECL(BYVAL Lay AS TrackLayer PTR _
  , BYVAL La0 AS float, BYVAL La1 AS float _
  , BYVAL Lo0 AS float, BYVAL Lo1 AS float)

  g_return_if_fail(TRACK_IS_LAYER(Lay))

WITH *Lay->Priv
  osm_gps_map_set_center_and_zoom(OSM_GPS_MAP(GUI->MAP) _
  , Rad2Deg * (La0 + La1) * .5 _
  , Rad2Deg * (Lo0 + Lo1) * .5 _
  , latlon2zoom(.TLw, .TLh, La0, La1, Lo0, Lo1))
END WITH
END SUB


/'* \brief Move current point
\param Lay Layer instance
\param S Movement type

Procedure adapting the index of the current point, showing that new
current point centered on the map (at current zoom level).

\since 0.0
'/
SUB track_layer_point_move CDECL(BYVAL Lay AS TrackLayer PTR, BYVAL S AS gchar PTR)

  g_return_if_fail(TRACK_IS_LAYER(Lay))
  IF NULL = Lay->Priv->Loader THEN EXIT SUB

WITH *Lay->Priv->Loader
  SELECT CASE AS CONST S[0]
  CASE ASC("+") : .Cur += 1         : IF .Cur > .Az THEN .Cur = .Az
  CASE ASC("-") : .Cur -= 1         : IF .Cur < 0   THEN .Cur = 0
  CASE ASC("f") : .Cur += .Az SHR 5 : IF .Cur > .Az THEN .Cur = .Az
  CASE ASC("b") : .Cur -= .Az SHR 5 : IF .Cur < 0   THEN .Cur = 0
  CASE ASC("F") : .Cur += .Az SHR 3 : IF .Cur > .Az THEN .Cur = .Az
  CASE ASC("B") : .Cur -= .Az SHR 3 : IF .Cur < 0   THEN .Cur = 0
  CASE ASC("H") : .Cur = 0
  CASE ASC("E") : .Cur = .Az
  CASE ASC("M") : .Cur = .Az SHR 1
  CASE ASC("1") : .Cur = CINT(.1 * .Az)
  CASE ASC("2") : .Cur = CINT(.2 * .Az)
  CASE ASC("3") : .Cur = CINT(.3 * .Az)
  CASE ASC("4") : .Cur = CINT(.4 * .Az)
  CASE ASC("5") : .Cur = CINT(.5 * .Az)
  CASE ASC("6") : .Cur = CINT(.6 * .Az)
  CASE ASC("7") : .Cur = CINT(.7 * .Az)
  CASE ASC("8") : .Cur = CINT(.8 * .Az)
  CASE ASC("9") : .Cur = CINT(.9 * .Az)
  CASE ASC("}") : .Cur = .SkipOut( 2, PAR->SkipFact * osm_gps_map_get_scale(Lay->Priv->Map))
  CASE ASC(">") : .Cur = .SkipOut( 1, PAR->SkipFact * osm_gps_map_get_scale(Lay->Priv->Map))
  CASE ASC("<") : .Cur = .SkipOut(-1, PAR->SkipFact * osm_gps_map_get_scale(Lay->Priv->Map))
  CASE ASC("{") : .Cur = .SkipOut(-2, PAR->SkipFact * osm_gps_map_get_scale(Lay->Priv->Map))
  CASE ELSE : EXIT SUB
  END SELECT
  .UsLa = Rad2Deg * .V[.Cur].Lat
  .UsLo = Rad2Deg * .V[.Cur].Lon
  .UsZo = .CoZo
  osm_gps_map_set_center_and_zoom(OSM_GPS_MAP(GUI->MAP), .UsLa, .UsLo, .UsZo)
END WITH
END SUB
