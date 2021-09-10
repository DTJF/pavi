/'* \file track_layer.bi
\brief Header for advanced tracks layer

FIXME

\since 0.0
'/
'#INCLUDE ONCE "Gir/OsmGpsMap-1.0.bi"
'#INCLUDE ONCE "Gir/_GLibMacros-2.0.bi"
'#INCLUDE ONCE "Gir/_GObjectMacros-2.0.bi"
#INCLUDE ONCE "track_loader.bi"

#DEFINE TRACK_TYPE_LAYER (track_layer_get_type())
#DEFINE TRACK_LAYER(obj) (G_TYPE_CHECK_INSTANCE_CAST((obj), TRACK_TYPE_LAYER, TrackLayer))
#DEFINE TRACK_LAYER_CLASS(obj) (G_TYPE_CHECK_CLASS_CAST((obj), TRACK_TYPE_LAYER, TrackLayerClass))
#DEFINE TRACK_IS_LAYER(obj) (G_TYPE_CHECK_INSTANCE_TYPE((obj), TRACK_TYPE_LAYER))
#DEFINE TRACK_IS_CLASS_LAYER(obj) (G_TYPE_CHECK_CLASS_TYPE((obj), TRACK_TYPE_LAYER))
#DEFINE TRACK_LAYER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS((obj), TRACK_TYPE_LAYER, TrackLayerClass))


/'* \brief Default setup for loaded tracks

In order to plot a newly loaded track on the map, it needs an initial
setup (points/lines colors/width). This class holds initial values for
one track in P (points) and L (lines) member variables. Both are of
type gchar PTR holding the line width / point radius in the first byte,
and the color string in the rest of the string.

\since 0.0
'/
TYPE TrackLayerDefault
  AS gchar PTR _ ' (first char width + color string)
    P _ '*< point default
  , L   '*< line default
END TYPE

TYPE AS _TrackLayer TrackLayer
TYPE AS _TrackLayerClass TrackLayerClass
TYPE AS _TrackLayerPrivate TrackLayerPrivate


/'* \brief GObject for ploting tracks

Structure holding the GObject for the new OsmGpsMapLayer that plots
tracks on the map widget.

\since 0.0
'/
TYPE _TrackLayer
  AS GObject Parent
  AS TrackLayerPrivate PTR Priv
END TYPE


/'* \brief GObjectClass for ploting tracks

Structure holding the GObjectClass (interface) for the new
OsmGpsMapLayer that plots tracks on the map widget.

\since 0.0
'/
TYPE _TrackLayerClass
  AS GObjectClass Parent_Class
END TYPE

DECLARE FUNCTION track_layer_new(BYVAL AS GObject PTR) AS TrackLayer PTR
DECLARE FUNCTION track_layer_get_type() AS GType
DECLARE FUNCTION track_layer_get_default CDECL(BYVAL AS TrackLayer PTR) AS TrackLayerDefault PTR
'DECLARE      SUB track_layer_set_default cdecl(BYVAL AS TrackLayer PTR, AS TrackLayerDefault PTR)
DECLARE FUNCTION track_layer_get_loader CDECL(BYVAL AS TrackLayer PTR) AS TrackLoader PTR
DECLARE      SUB track_layer_set_loader CDECL(BYVAL AS TrackLayer PTR, BYVAL AS TrackLoader PTR)
DECLARE      SUB track_layer_redraw CDECL(BYVAL AS TrackLayer PTR)
DECLARE      SUB track_layer_center_track CDECL(BYVAL AS TrackLayer PTR)
DECLARE FUNCTION track_layer_get_point CDECL(BYVAL AS TrackLayer PTR) AS gint
DECLARE      SUB track_layer_set_point CDECL(BYVAL AS TrackLayer PTR, BYVAL AS gint)
DECLARE      SUB track_layer_point_move CDECL(BYVAL AS TrackLayer PTR, BYVAL AS gchar PTR)
DECLARE      SUB track_layer_set_bbox CDECL(BYVAL AS TrackLayer PTR _
                 , BYVAL AS float, BYVAL AS float, BYVAL AS float, BYVAL AS float)
