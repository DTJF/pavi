/'* \file parser_gpx.bas
\brief Source for parser reading `*.GPX` file context

Code for a TYPE (class/UDT) that evaluates the context of a `*.GPX`
file, creating an array of #TrP entries.

\since 0.0
'/

#INCLUDE ONCE "Gir/GLib-2.0.bi"
#INCLUDE ONCE "parser_gpx.bi"
#INCLUDE ONCE "datetime.bi"

#IFDEF __FB_UNIX__
 '* The new line charater[s]
 #DEFINE NL !"\n" &
#ELSE
 #DEFINE NL !"\r\n" &
'&*/
#ENDIF


/'* \brief Check if floating point number is valid
\param N Number to check
\returns TRUE if valid, FALSE when invalid

The file content parser marks missing or error entries as NaN. This
function identifies an input failure.

\since 0.0
'/
FUNCTION isnum(BYVAL N AS DOUBLE) AS INTEGER
	SELECT CASE CAST(ULONG PTR, @N)[1]
  CASE &h7FF00000UL, &hFFF00000UL : RETURN 0 ' +/- INF
  CASE &h7FF80000UL, &hFFF80000UL : RETURN 0 ' +/- NaN
  END SELECT : RETURN -1
END FUNCTION


/'* \brief Macro to read data from parser context

This is an essential macro to find and read data in the parser #GPX
data.

\since 0.0
'/
#DEFINE fetch(_T_) find_value(_T_, AttNams, AttVals)

/'* \brief Macro to start a parser

Each parser uses the same parameter list for the start function.
This macro generates the code for such a procedure (SUB) and opens a
WITH block to support access to the #GPX data.

It's designed to be used in combination with the _END_PARSER() macro.

'/
#MACRO _START_PARSER(_N_)
 SUB start_##_N_ CDECL( _
  BYVAL ctx AS GMarkupParseContext PTR, _
  BYVAL element_name AS CONST gchar PTR, _
  BYVAL AttNams AS CONST gchar PTR PTR, _
  BYVAL AttVals AS CONST gchar PTR PTR, _
  BYVAL UserData AS gpointer, _
  BYVAL error_ AS GError PTR PTR)
   WITH PEEK(GPX, UserData)
#ENDMACRO

/'* \brief Macro to complete a start parser and open an end parser

Each parser uses the same code for ending a start function and the
same parameter list for the end function. This macro generates the
code to finish the start procedure (END WITH/END SUB), open an end
procedure (SUB with constant parameter list) and opens a WITH block
to support access to the #GPX data.

It's designed to be used after the _START_PARSER() macro and in combination
with the _NEW_PARSER() macro.

'/
#MACRO _END_PARSER(_N_)
  CASE ELSE
    'PRINT NL "--> " & __FUNCTION__ & " Skipping " & *element_name
    g_markup_parse_context_push(ctx, @Skip_parser, UserData) '& skip_parser();
  END SELECT
  END WITH
 END SUB
 SUB end_##_N_ CDECL( _
  BYVAL ctx AS GMarkupParseContext PTR, _
  BYVAL element_name AS CONST gchar PTR, _
  BYVAL UserData AS gpointer, _
  BYVAL error_ AS GError PTR PTR)
   WITH PEEK(GPX, UserData)
#ENDMACRO

/'* \brief Macro to complete an end parser and initialize the \GMP UDT

Each parser uses the same code for ending an end procedure. This macro
generates the code to finish the end procedure and generates a
structure (TYPE) to use the parser. This TYPE contains two functions
(procedures for start and end of a XML tag).

The second argument is used for the `text` function, called for
character data. Pass `NULL` if you don't need any text from tags, or a
function to fetch the text.

It's designed to be used after the _END_PARSER() macro.

'/
#MACRO _NEW_PARSER(_N_,_T_)
  CASE ELSE
    g_markup_parse_context_pop(ctx)
  END SELECT
  END WITH
 END SUB
 STATIC SHARED AS GMarkupParser _N_##_parser = TYPE(@start_##_N_, @end_##_N_, _T_, NULL, NULL)
#ENDMACRO


'* This \GMP parser does nothing, used for skipping unused XML-tags
'& SUB_CDECL skip_parser(){}; /*
STATIC SHARED AS GMarkupParser Skip_parser = TYPE(NULL, NULL, NULL, NULL, NULL)
'& */

/'* \brief Find an attribute by its name
\param Nam The attribute name
\param AttNams The GLib array of attribute names (zero terminated)
\param AttVals The GLib array of attribute values
\returns A pointer to the attribute value (or zero)

The GLib XML parser lists all attributes found in a tag and their
values in the arrays AttNams and AttVals. This function finds an
attribute by its name and returns its value. Otherwise it returns
zero if the specified attribute isn't present.

'/
FUNCTION find_value( _
  BYVAL Nam AS CONST gchar PTR, _
  BYVAL AttNams AS CONST gchar PTR PTR, _
  BYVAL AttVals AS CONST gchar PTR PTR) AS CONST gchar PTR

  VAR i = 0
  WHILE AttNams[i]
    IF *AttNams[i] = *Nam THEN RETURN AttVals[i]
    i += 1
  WEND : RETURN NULL
END FUNCTION


/'* \brief Grep content between start and end tag
\param Ctx the parser context
\param Text text read from tag
\param Size text length (not null terminated)
\param UserData our instance
\param Error_ pointer for error message

If there's text between the opening and closing tag like `<a>text</a>`,
this function greps the context in member variable GPX.Cont.

\since 0.0
'/
SUB text_content CDECL( _
 BYVAL Ctx AS GMarkupParseContext PTR, _
 BYVAL Text AS CONST gchar PTR, _
 BYVAL Size AS gsize, _
 BYVAL UserData AS gpointer, _
 BYVAL Error_ AS GError PTR PTR)

 CAST(GPX PTR, UserData)->Cont = LEFT(*Text, Size)
END SUB

'* The \GMP for `<extension>` tags.
'& SUB_CDECL EXT_parser(){
'& find_value();
EXT_parser:
_START_PARSER(EXT)

  SELECT CASE *element_name
  CASE "dir", "g_spd"

_END_PARSER(EXT)

  SELECT CASE *element_name
'<dir>139</dir>
  CASE "dir"
    .Ang = g_ascii_strtod(.Cont, NULL)
'<g_spd>5.02999877929688</g_spd>
  CASE "g_spd"
    .Spd = g_ascii_strtod(.Cont, NULL) * 1.852 '[km/mile]

_NEW_PARSER(EXT,@text_content)
'& };


'* The \GMP for `<trkpt>` tags.
'& SUB_CDECL PNT_parser(){
'& find_value();
PNT_parser:
_START_PARSER(PNT)

  SELECT CASE *element_name
  CASE "ele", "time"
  CASE "extensions"
    g_markup_parse_context_push(ctx, @EXT_parser, UserData)

_END_PARSER(PNT)

  SELECT CASE *element_name
'<ele>460.00</ele>
  CASE "ele"
    .Ele = g_ascii_strtod(.Cont, NULL)
'<time>2020-07-10T18:31:57Z</time>
  CASE "time"
    .Tim = _
      DATESERIAL( _
        VALINT(MID(.Cont, 1, 4)) _
      , VALINT(MID(.Cont, 6, 2)) _
      , VALINT(MID(.Cont, 9, 2)) ) _
    + TIMESERIAL( _
        VALINT(MID(.Cont, 12, 2)) _
      , VALINT(MID(.Cont, 15, 2)) _
      , VALINT(MID(.Cont, 18, 2)) )
  CASE "extensions"
    g_markup_parse_context_pop(ctx)
    .Ext += 1

_NEW_PARSER(PNT,@text_content)
'& };


'* The \GMP for `<trkseg>` tags.
'& SUB_CDECL SEG_parser(){
'& find_value();
SEG_parser:
_START_PARSER(SEG)

  SELECT CASE *element_name
'<trkpt lat="47.243324" lon="15.310627">
  CASE "trkpt"
    var _
    p = fetch("lat") : if p then .Lat = g_ascii_strtod(p, NULL) * Deg2Rad
    p = fetch("lon") : if p then .Lon = g_ascii_strtod(p, NULL) * Deg2Rad
    g_markup_parse_context_push(ctx, @PNT_parser, UserData)

_END_PARSER(SEG)

  SELECT CASE *element_name
  CASE "trkpt"
    g_markup_parse_context_pop(ctx)
    VAR x = NEW(.Dat) TrP ( _
      .Tim _ '*< Date / Time
    , .Lat _ '*< Latitude
    , .Lon _ '*< Longitude
    , .Ele _ '*< Elevation [m]
    , .Spd _ '*< Speed over ground [km/h]
    , .Ang _ '*< Direction Angle
    , 0 ,0)
    .Dat += SIZEOF(TrP)
    IF isnum(.Tim) THEN .Tim = NaN ELSE .TiX += 1
    IF isnum(.Lon) THEN .Lon = NaN ELSE .LoX += 1
    IF isnum(.Lat) THEN .Lat = NaN ELSE .LaX += 1
    IF isnum(.Ele) THEN .Ele = NaN ELSE .ElX += 1
    IF isnum(.Spd) THEN .Spd = NaN ELSE .SpX += 1
    IF isnum(.Ang) THEN .Ang = NaN ELSE .AnX += 1
    .Pnt += 1

_NEW_PARSER(SEG,NULL)
'& };


'* The \GMP for `<trk>` tags.
'& SUB_CDECL TRK_parser(){
'& find_value();
TRK_parser:
_START_PARSER(TRK)

  SELECT CASE *element_name
'<name>2020-07-10_20-32-00.gpx</name>
  CASE "name"
'<trkseg>
  CASE "trkseg"
    g_markup_parse_context_push(ctx, @SEG_parser, UserData)

_END_PARSER(TRK)

  SELECT CASE *element_name
  CASE "name"
  CASE "trkseg"
    g_markup_parse_context_pop(ctx)
    .Seg += 1

_NEW_PARSER(TRK,@text_content)
'& };

'* The \GMP for `*.GPX` files.
'& SUB_CDECL GPX_parser(){
'& find_value();
GPX_parser:
_START_PARSER(GPX)

  SELECT CASE *element_name
'<gpx xmlns="http://www.topografix.com/GPX/1/1" version="1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd" creator="com.mapfactor.navigator">
  CASE "gpx"
    '?NL "  " & *fetch("xmlns");
    '?NL "  " & *fetch("version");
    '?NL "  " & *fetch("xmlns:xsi");
    '?NL "  " & *fetch("xsi:schemaLocation");
    '?NL "  " & *fetch("creator");
'<trk>
  CASE "trk"
    g_markup_parse_context_push(ctx, @TRK_parser, UserData)

_END_PARSER(GPX)

  SELECT CASE *element_name
  CASE "gpx"
  CASE "trk"
    g_markup_parse_context_pop(ctx)
    .Trk += 1

_NEW_PARSER(GPX,NULL)
'& };


/'* \brief CTOR parsing the context of a `*.GPX` file
\param Parent Pointer to parent instance

This constructor gets an input buffer (UBYTE PTR) containing the
context of an `*.GPX` file, and parses it, creating an array of #TrP
points. That array is located at (and overriding) the beginning of the
input buffer, and finally the buffer gets reduced (REALLOCATE) in size
to the binary data.

\since 0.0
'/
CONSTRUCTOR GPX(BYVAL Parent AS TrackLoader PTR)
WITH *Parent
  Dat = .Buff
  DIM AS GError PTR er_r = NULL ' *< location for GLib errors
  VAR ctx = g_markup_parse_context_new(@GPX_parser, 0, @THIS, NULL)
  IF g_markup_parse_context_parse(ctx, .Buff, .Byt, @er_r) THEN _
    IF 0 = g_markup_parse_context_end_parse(ctx, @er_r) THEN _
      Tix += 1 : .Errr = @"cannot parse (invalid content)"
  g_markup_parse_context_free(ctx)
  .Siz = Dat - CAST(ANY PTR, .Buff)
END WITH
END CONSTRUCTOR
