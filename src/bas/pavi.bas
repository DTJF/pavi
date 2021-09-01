/'* \file pavi.bas
\brief Source of the main module

Code to handle the application.

\since 0.0
'/

#INCLUDE ONCE "Gir/OsmGpsMap-1.0.bi"
#INCLUDE ONCE "Gir/_GLibMacros-2.0.bi"
#INCLUDE ONCE "Gir/_GObjectMacros-2.0.bi"
#INCLUDE ONCE "track_store.bi"
#INCLUDE ONCE "track_layer.bi"
#INCLUDE ONCE "gui.bi"
#INCLUDE ONCE "debug.bi"

TYPE AS GtkApplication Pavi
TYPE AS GtkApplicationClass PaviClass

G_DEFINE_TYPE(Pavi, pavi, GTK_TYPE_APPLICATION)

SUB pavi_init CDECL(BYVAL App AS Pavi PTR)
END SUB

SUB pavi_startup CDECL(BYVAL App AS GApplication PTR)
  G_APPLICATION_CLASS(pavi_parent_class)->startup(App)
  PAR = NEW PARdata
  GUI = NEW GUIdata("pavi.ui", App)
END SUB

SUB pavi_activate CDECL(BYVAL App AS GApplication PTR)
END SUB

SUB pavi_open CDECL( _
    BYVAL App AS GApplication PTR _
  , BYVAL Files AS GFile PTR PTR _
  , BYVAL N_files AS gint _
  , BYVAL Hint AS CONST gchar PTR)
  DIM AS TrackLoader PTR last
  FOR i AS gint = 0 TO N_files - 1
    WITH TYPE<TS_add>(g_file_peek_path(Files[i]))
      IF .Got THEN ?"old entry: ",.Nam,.Fol,.Loa
      last = .Loa
    END WITH
  NEXT : TS_select(last->Path)
  gtk_widget_queue_draw(GTK_WIDGET(GUI->TVT))
END SUB

SUB pavi_finalize CDECL(BYVAL Obj AS GObject PTR)
  G_OBJECT_CLASS(pavi_parent_class)->finalize(Obj)
END SUB

SUB pavi_shutdown CDECL(BYVAL App AS GApplication PTR)
  DELETE(GUI)
  DELETE(PAR)
  G_APPLICATION_CLASS(pavi_parent_class)->shutdown(App)
END SUB


SUB pavi_class_init CDECL(BYVAL Clas AS PaviClass PTR)
WITH *G_APPLICATION_CLASS(Clas)
   .startup = @pavi_startup()
  .activate = @pavi_activate()
      .open = @pavi_open()
  .shutdown = @pavi_shutdown()
END WITH
  G_OBJECT_CLASS(Clas)->finalize = @pavi_finalize
END SUB


VAR pavi = g_object_new( _
    pavi_get_type() _
  , @"application-id", @"com.github.dtjf.pavi" _
  , "flags", G_APPLICATION_HANDLES_OPEN _
  , NULL)
VAR status = g_application_run(G_APPLICATION(pavi), __FB_ARGC__, __FB_ARGV__)
g_object_unref(pavi)

END status
