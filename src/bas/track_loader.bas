/'* \file track_loader.bas
\brief Source for loading MapFactor Navigator track files

A UDT to load and analyse track files (`*.NMEA` and `*.GPX`) generated
by the MapFactor Navigator software.

\since 0.0
'/

DECLARE FUNCTION atanh CDECL ALIAS"atanh"(BYVAL AS DOUBLE) AS DOUBLE
DECLARE FUNCTION tanh CDECL ALIAS"tanh"(BYVAL AS DOUBLE) AS DOUBLE
CONST AS LONG _
  TILESIZE = 256 _ '*< size of tile used in osm_gps_map
, TILESIZEd2 = 128 '*< half size

#INCLUDE ONCE "parser_gpx.bi"
#INCLUDE ONCE "parser_nmea.bi"
#INCLUDE ONCE "datetime.bi"


/'* \brief Macro to check extrema

This macro creates code to check a value in TrackLoader.V() against the
extrema in TrackLoader.Mn and TrackLoader.Mx. Used at the end of a line
(no code behind)!

\since 0.0
'/
#DEFINE EXTREM(_V_) _
  IF _V_ > Mx##_V_ THEN Mx##_V_ = _V_ ELSE IF _V_ < Mn##_V_ THEN Mn##_V_ = _V_


/'* \brief Transform world latitude to map Y-pixel
\param V Worlds latitude in radians
\param Z Zoom level
\returns Map Y in pixels

This function transforms from worlds latitude coordinate (in radians)
to map widget Y pixels.

\since 0.0
'/
FUNCTION lat2pixel(BYVAL V AS float, BYVAL Z AS LONG) AS LONG
  VAR y = atanh(SIN(V)) * TILESIZE * (1 SHL Z) / PIx2
  RETURN -INT(y) + ((1 SHL Z) * TILESIZEd2)
END FUNCTION


/'* \brief Transform world longitude to map X-pixel
\param V Worlds latitude in radians
\param Z Zoom level
\returns Map X in pixels

This function transforms from worlds longitude coordinate (in radians)
to map widget X pixels.

\since 0.0
'/
FUNCTION lon2pixel(BYVAL V AS float, BYVAL Z AS LONG) AS LONG
  VAR x = V * TILESIZE * (1 SHL Z) / PIx2
  RETURN  INT(x) + ((1 SHL Z) * TILESIZEd2)
END FUNCTION


/'* \brief Transform map X-pixel to world longitude
\param Z Zoom level
\param X Map x in pixel
\returns Worlds longitude in radians

This function transforms from map widget X pixels to worlds longitude
coordinate (in radians).

\since 0.0
'/
FUNCTION pixel2lon(BYVAL Z AS long, BYVAL X AS LONG) AS float
  RETURN ((X - (EXP(LN2 * Z) * TILESIZEd2)) * PIx2) _
       / (TILESIZE * EXP(LN2 * Z))
END FUNCTION


/'* \brief Transform map Y-pixel to world latitude
\param Z Zoom level
\param Y Map y in pixel
\returns Worlds latitude in radians

This function transforms from map widget Y pixel to worlds latitude
coordinate (in radians).

\since 0.0
'/
FUNCTION pixel2lat(BYVAL Z AS long, BYVAL Y AS LONG) AS float
  VAR lat_m = ((EXP(LN2 * Z) * TILESIZEd2 - Y) * PIx2) _
            / (TILESIZE * EXP(LN2 * Z))
  RETURN ASIN(tanh(lat_m))
END FUNCTION

'* \brief Macro computing the base 2 logarythm
#DEFINE LOG2(_X_) LOG(_X_) / LN2
'* \brief Macro finding the minimum
#DEFINE MIN(V1, V2) IIF(V1 > V2, V2, V1)


/'* \brief Evaluate the matching zoom level for BBox
\param W Width of map widget
\param H Height of map widget
\param La0 Minimum latitude
\param La1 Maximum latitude
\param Lo0 Minimum longitude
\param Lo1 Maximum longitude
\returns Matching zoom level

This function evaluates the zoom level for the map in order to show a
bounding box completely on the map.

\since 0.0
'/
FUNCTION latlon2zoom CDECL( _
  BYVAL W AS LONG _
, BYVAL H AS LONG _
, BYVAL La0 AS float _
, BYVAL La1 AS float _
, BYVAL Lo0 AS float _
, BYVAL Lo1 AS float) AS LONG
  DIM AS DOUBLE dlon = Lo1 - Lo0
  dlon = IIF(dlon, ABS(W * PIx2 / TILESIZE / dlon), 20.)
  DIM AS DOUBLE dlat = atanh(SIN(La1)) - atanh(SIN(La0))
  dlat = IIF(dlat, ABS(H * PIx2 / TILESIZE / dlat), 20.)
  RETURN MIN(INT(LOG2(dlon)), INT(LOG2(dlat)))
END FUNCTION


/'* \brief CTOR preparing data
\param Fnam The name of the file to operate

??
???They contain equal timed data
lines in `$GPGGA` and `$GPRMV` format, generated once a second. For
each track point the data in UDT TrP get extracted from both lines and
get stored in the array TrackLoader.V, extrema (minimum and maximum) stored in
TrackLoader.Mn and TrackLoader.Mx. Equal track points (no movement) get skipped.



The CTOR opens the data file and greps data if

* a `$GPRMC` line follows a `$GPGGA` line
* both lines have a checksum and it's valid
* both lines represent the same timestamp and position

If a single `$GPGGA` line or a pair of `$GPGGA` and `$GPRMC` lines
doesn't match this requisites, they get skipped.

Otherwise a new entry in the data array TrackLoader.V gets created for each
pair of lines, and the values get checked against the maximum and
minimum values in TrackLoader.Mx and TrackLoader.Mn.

Find the data field description at https://de.wikipedia.org/wiki/NMEA_0183
??

\since 0.0
'/
CONSTRUCTOR TrackLoader(BYVAL Fnam AS CONST ZSTRING PTR)
  STATIC AS UINTEGER dile = CAST(UINTEGER, -1) SHR 1
  IF 0 = Fnam ORELSE Fnam[0] = 0 THEN Errr = @"no file name" : EXIT CONSTRUCTOR
  VAR fnr = FREEFILE
  IF OPEN(*Fnam FOR INPUT AS fnr) THEN Errr = @"open failed" : EXIT CONSTRUCTOR

  VAR want = LOF(fnr) : IF 0 = want THEN CLOSE #fnr : Errr = @"no contents" : EXIT CONSTRUCTOR
  IF want = dile THEN CLOSE #fnr : Errr = @"directory" : EXIT CONSTRUCTOR
  Buff = ALLOCATE(want+1) : IF 0 = Buff THEN CLOSE #fnr : Errr = @"out of memory" : EXIT CONSTRUCTOR
  GET #fnr, ,*Buff, want, Byt
  CLOSE #fnr
  Buff[Byt + 1] = 0 ' terminate

  IF UCASE(RIGHT(*Fnam, 4)) = ".GPX" THEN
    WITH TYPE<GPX>(@THIS)
      Desc = _
         Byt & " bytes: " _
      & .Trk & " track[s] (" & .Seg &  " segments[s]), " _
      & .Pnt & " point[s] (" & .Ext & !" extension[s])\n\n" _
      & .TiX + .LoX + .LaX + .ElX + .SpX + .AnX & " err/miss: " _
      & .TiX & " <time>, " _
      & .LoX & " <lon>, " _
      & .LaX & " <lat>, " _
      & .ElX & " <ele>, " _
      & .SpX & " <g_spd>, " _
      & .AnX & " <dir>"
    END WITH
  ELSE
    WITH TYPE<NMEA>(@THIS)
      Desc = _
         " bytes (file/mem): " & Byt & "/" & Siz & ": " _
      & .Lin & " lines, " & (Siz \ SIZEOF(TrP)) & " points (" _
      & .Enr & " error[s])"
    END WITH
  END IF
  IF Siz <= 0 THEN Errr = @"no track points" : EXIT CONSTRUCTOR
  VAR x = REALLOCATE(Buff, Siz) : IF x THEN Buff = x

  Az = Siz \ SIZEOF(TrP) - 1
  V = CAST(TrP PTR, Buff)

  Mn = V[0]
  Mx = V[0] : Mx.Tim = V[Az].Tim
  FOR i AS INTEGER = 1 TO Az
  WITH V[i]
    EXTREM(.Lat)
    EXTREM(.Lon)
    EXTREM(.Ele)
    EXTREM(.Spd)
    EXTREM(.Ang)
  END WITH
  NEXT
END CONSTRUCTOR

DESTRUCTOR TrackLoader()
  DEALLOCATE(Buff)
END DESTRUCTOR


/'* \brief Compute pixel values for given center and zoom
\param X parents max-x property
\param Y parents max-y property
\param Z parents zoom property
\returns 0 (zero) on success, 1 in case of an error

FIXME

\since 0.0
'/
FUNCTION TrackLoader.Pixel(BYVAL X AS LONG, BYVAL Y AS LONG, BYVAL Z AS LONG)AS BYTE
  IF 0 = Az THEN RETURN 1
  IF Z = CoZo THEN ' simple integer movement
    IF Co_X = X ANDALSO Co_Y = Y THEN RETURN 0
    VAR dx = Co_X - X, dy = Co_Y - Y
    FOR i AS INTEGER = 0 TO Az
      V[i].Xpix += dx
      V[i].Ypix += dy
    NEXT
  ELSE ' complex transformation for new zoom
    CoZo = Z
    FOR i AS INTEGER = 0 TO Az
      V[i].Xpix = lon2pixel(V[i].Lon, Z) - X
      V[i].Ypix = lat2pixel(V[i].Lat, Z) - Y
    NEXT
  END IF
  Co_X = X
  Co_Y = Y
  RETURN 0
END FUNCTION


/'* \brief Compute exit of cloud
\param Typ Type of skipping
\param Di Distance to skip in [m]
\returns The next track point out of a certain radius

The property evaluates the avarage speed by adding all speed
meansurements and dividing by the number of entries.

\since 0.0
'/
FUNCTION TrackLoader.SkipOut(BYVAL Typ AS LONG, BYVAL Di AS float) AS LONG
  VAR st = -1L, e = 0L
  SELECT CASE AS CONST Typ
  CASE -2 : Di *= 5
  CASE -1
  CASE  1           : st =  1 : e = Az
  CASE  2 : Di *= 5 : st =  1 : e = Az
  CASE ELSE : RETURN Cur
  END SELECT
  FOR i AS LONG = Cur + st TO e STEP st
    IF Dist(Cur, i) > Di THEN RETURN i
  NEXT
  RETURN e
END FUNCTION


/'* \brief Compute the speed avarage
\returns The avarage speed

The property evaluates the avarage speed by adding all speed
meansurements and dividing by the number of entries.

\since 0.0
'/
PROPERTY TrackLoader.ASpd() AS float
  VAR a = CAST(DOUBLE, V[0].Spd)
  FOR i AS INTEGER = 1 TO Az
    a += V[i].Spd
  NEXT : RETURN a / Az
END PROPERTY


/'* \brief Compute track length
\returns The summ of the distances between the track points [m]

Property returning the overall track length. All three dimentional
(incl. elevation) point distances get added.

If there is no distance (less than two points), NaN gets returned.

\since 0.0
'/
PROPERTY TrackLoader.LTrk() AS float
  IF Az < 1 THEN RETURN NaN
  VAR l = Dist(0, 1)
  FOR i AS INTEGER = 2 TO Az
    l += Dist(i, i-1)
  NEXT : RETURN l
END PROPERTY


/'* \brief Compute distance between two points
\param P0 The first index in array TrackLoader.V()
\param P1 The second index in array TrackLoader.V()
\returns The distance between both points in meters

After track points were graped from file, this function computes the
distance between two points, given by the index in array TrackLoader.V.

\since 0.0
'/
FUNCTION TrackLoader.Dist(BYVAL P0 AS ULONG, BYVAL P1 AS ULONG) AS DOUBLE
  IF P0 > Az ORELSE P1 > Az THEN RETURN NaN
  VAR r0 = V[P0].Ele + ERA    , r1 = V[P1].Ele + ERA _
    , a0 = COS(V[P0].Lat) * r0, a1 = COS(V[P1].Lat) * r1 _
    , dx = COS(V[P0].Lon) * a0   -   COS(V[P1].Lon) * a1 _
    , dy = SIN(V[P0].Lon) * a0   -   SIN(V[P1].Lon) * a1 _
    , dz = SIN(V[P0].Lat) * r0   -   SIN(V[P1].Lat) * r1
    RETURN SQR(dx*dx + dy*dy + dz*dz)
END FUNCTION


/'* \brief Find point nearest to the given [radians] position
\param Lon positions latitude
\param Lat positions longitude
\returns Distance (2D in [radians])

Function to search the track points for the smallest distance to a
given position, input and output in radians. Elevation gets not
considered.

\since 0.0
'/
FUNCTION TrackLoader.Nearest(BYVAL Lon AS float, BYVAL Lat AS float)AS float
  VAR a = V[0].Lat - Lat, o = V[0].Lon - Lon, d = SQR(a*a + o*o)
  Tmp = 0
  FOR i AS LONG = 1 TO Az
    a = V[i].Lat - Lat : o = V[i].Lon - Lon : VAR x = SQR(a*a + o*o)
    IF x < d THEN d = x : Tmp = i
  NEXT : RETURN d
END FUNCTION


/'* \brief Compute center and zoom to plot complete track
\param W Width of map
\param H Height of map

Evaluates user settings (from minimum and maximum longitude and
latitute) for the track center and the zoom level in order to plot the
complete track in the map widget.

\since 0.0
'/
SUB TrackLoader.MapCenter(BYVAL W AS LONG, BYVAL H AS LONG)
  UsLo = .5 * (Mx.Lon + Mn.Lon)
  UsLa = .5 * (Mx.Lat + Mn.Lat)
  UsZo = latlon2zoom(W, H, Mn.Lat, Mx.Lat, Mn.Lon, Mx.Lon)
  UsLo *= Rad2Deg
  UsLa *= Rad2Deg
END SUB
