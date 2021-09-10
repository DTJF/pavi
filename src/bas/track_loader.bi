/'* \file track_loader.bi
\brief Header for loading track files

The #TrackLoader class (UDT) is designed to load and analyse track
files (`*.NMEA` and `*.GPX`, generated by MapFactor Navigator
software). Individual parsers can get invoked in order to load
different file formats.

\since 0.0
'/

type as single float '!!

CONST AS DOUBLE _
  NaN = 0.0/0.0 _      '*< Not a number (error value)
, LN2 = LOG(2) _       '*< natural logarythm 2.0
, PI = 4 * atn(1) _    '*< PI = 3.14...
, PIx2 = PI * 2 _      '*< PI * 2
, PId2 = PI / 2 _      '*< PI * 2
, Deg2Rad = PI / 180 _ '*< transform degree in radians
, Rad2Deg = 180 / PI _ '*< transform radians in degree
, ERA = 3443.89849 * 1852 '*< earth radius [m]

/'* \brief Data for a single track point

UDT used to store the point data graped from the file. Undefined values
get stored as NaN entries. The LONG values `[XY]pix` gets computed
later for the current map zoom level.

\since 0.0
'/
TYPE TrP
  AS DOUBLE _
    Tim   '*< Date / Time
  AS float _
    Lat _ '*< Latitude
  , Lon _ '*< Longitude
  , Ele _ '*< Elevation [m]
  , Spd _ '*< Speed over ground [km/h]
  , Ang   '*< Direction Angle
  AS LONG _
    Xpix _ '*< world X pixel for ploting
  , Ypix   '*< world Y pixel for ploting
END TYPE


/'* \brief UDT collecting and holding the track data

This class (UDT) is designed to load track data from files and store
the track points in memory. Currently it supports `*.NMEA` and `*.GPX`
file formats, but can get easily extended for further formats in
future (see #NMEA and #GPX classes).

It's a grounded class, designed to hold one instance per track in
memory.

\since 0.0
'/
TYPE TrackLoader
  AS ZSTRING PTR _
    Errr   '*< error message
  AS TrP PTR _
    V      '*< array of data
  AS TrP _
    Mx _   '*< maximum values
  , Mn     '*< minimum values
  AS INTEGER _
    Byt _      '*< bytes read from file (buffer length)
  , Siz = 0    '*< byte size of #TrackLoader.V array
  AS LONG _
    Tmp  _     '*< temp counter
  , Cur _      '*< last track position in map plot
  , Az  = -1 _ '*< number of entries in array TrackLoader.V
  , UsZo =-1 _ '*< users zoom level in map
  , CoZo     _ '*< computed zoom level in map
  , Co_X _     '*< map-X for computed pixels
  , Co_Y       '*< map-Y for computed pixels
  AS float _
    UsLo _      '*< users map center latitude (degree)
  , UsLa _      '*< users map center longitude (degree)
  , CoLo _      '*< computed map center latitude (degree)
  , CoLa        '*< computed map center longitude (degree)
  AS STRING _
    Path _     '*< path in TVT tree store
  , Desc       '*< desciption
  AS UBYTE PTR _
    Buff       '*< buffer for input, and (later) points array
  DECLARE CONSTRUCTOR(BYVAL AS CONST ZSTRING PTR = 0)
  DECLARE DESTRUCTOR()
  DECLARE FUNCTION Dist(BYVAL AS ULONG, BYVAL AS ULONG) AS DOUBLE
  DECLARE PROPERTY LTrk() AS float
  DECLARE PROPERTY ASpd() AS float
  DECLARE FUNCTION Pixel(BYVAL AS LONG, BYVAL AS LONG, BYVAL AS LONG)AS BYTE
  DECLARE FUNCTION SkipOut(BYVAL Typ AS LONG, BYVAL Di AS float)AS LONG
  DECLARE      SUB MapCenter(BYVAL W AS LONG, BYVAL H AS LONG)
  DECLARE FUNCTION Nearest(BYVAL AS float, BYVAL AS float)AS float
END TYPE

DECLARE FUNCTION latlon2zoom( _
  BYVAL AS LONG _
, BYVAL AS LONG _
, BYVAL AS float _
, BYVAL AS float _
, BYVAL AS float _
, BYVAL AS float) AS LONG
