/'* \file parser_nmea.bas
\brief Source for parser reading `*.NMEA` file context

Code for a TYPE (class/UDT) that evaluates the context of a `*.NMEA`
file, creating an array of #TrP entries.

\since 0.0
'/

#INCLUDE ONCE "Gir/GLib-2.0.bi"
#INCLUDE ONCE "parser_nmea.bi"
#INCLUDE ONCE "track_loader.bi"
#INCLUDE ONCE "datetime.bi"


/'* \brief CTOR parsing the context of a `*.NMEA` file
\param Par Pointer to parent instance

This constructor gets an input buffer (UBYTE PTR) containing the
context of an `*.NMEA` file, and parses it, creating an array of #TrP
points if

* a `$GPRMC` line follows a `$GPGGA` data line
* both lines contain the same timestamp and position
* both lines have a valid checksum

If a single `$GPGGA` line or a pair of `$GPGGA` and `$GPRMC` lines
doesn't match this requiaries, they get skipped.

Otherwise a new #TrP gets created for the pair of lines, and that #TrP
gets stored in the resulting #TrP array, located at (and overriding)
the beginning of the input buffer.

Invalid or missing numbers get filled by `NaN` entries.

Find the data field description at https://de.wikipedia.org/wiki/NMEA_0183

\since 0.0
'/
CONSTRUCTOR NMEA(BYVAL Par AS TrackLoader PTR)
WITH *Par
  VAR i = 0, tind = 28, t = @.Buff[0], s = CAST(ZSTRING PTR, t), check = 0
  Dat = t
  DO
    SELECT CASE AS CONST t[i]
    CASE 0 : EXIT DO
    CASE 1 TO 31  : t[i] = 0
    CASE ASC(",") : t[i] = 0 : Tok(tind) = @t[i+1] : tind += 1
    CASE ASC("*")
      IF check <> VALINT("&h" & LEFT(S[i+1], 2)) _
        THEN Enr += 1 : ?"invalid checksum (" & Lin & "): &h";HEX(check, 2);" <> &h";LEFT(S[i+1], 2)
      i += 2
    CASE ASC("$")
      check = 0 ' reset checksum
      FOR j AS INTEGER = i+1 TO i+72
        SELECT CASE AS CONST t[j]
        CASE 0, 42 : EXIT FOR ' exit on end of buffer or asterix character
        END SELECT : check XOR= t[j]
      NEXT
      IF t[i+3] = ASC("G") THEN
        IF tind <> 28 THEN Enr += 1 : ?"RMC check failed (" & Lin & ") " & tind
        tind = 0
        IF Lin THEN Eval(@Tok(0)) ':        ?hey(DaTi(@Tok(0))),hey(LaLo(@Tok(2))),hey(LaLo(@Tok(4)))
      ELSE
        IF tind <> 15 THEN tind = 15 : Enr += 1 : ?"GGA check failed (" & Lin & ") " & tind
      END IF : Lin += 1
      Tok(tind) = @t[i]
      tind += 1
      i += 5
    END SELECT : i += 1
  LOOP : .Byt = i : IF Lin THEN Eval(@Tok(0))
  .Siz = Dat - CAST(ANY PTR, .Buff)
END WITH
END CONSTRUCTOR


/'* \brief Evaluate a number from a string
\param S The string context
\returns The number (float)

Function to read a float number from a string. Independant from the
locale setting it always uses the `.` character as decimal separator
(unlike the FB `VAL` function).

\since 0.0
'/
FUNCTION NMEA.Val_(BYVAL S AS ZSTRING PTR) AS float
  IF S[0] = 0 THEN Enr += 1 : ?"missing number (" & Lin & ")" : RETURN NaN
  RETURN g_ascii_strtod(*S, NULL)
END FUNCTION


/'* \brief Evaluate the date and time for input lines
\param S The array all parameters
\returns A FreeBASIC DATE_TIME_SERIAL (DOUBLE)

Function that checks the time in both lines, returning a `NaN` in case
of a mismatch. Otherwise it returns a DOUBLE containing an FB
DATE_TIME_SERIAL.

\since 0.0
'/
FUNCTION NMEA.DaTi(BYVAL S AS ZSTRING PTR PTR) AS DOUBLE
  IF 6 <> LEN(*S[1]) ORELSE _
     6 <> LEN(*S[24]) THEN Enr += 1 : ?"invalid date/time (" & Lin & ")" : RETURN NaN
  RETURN _
    DATESERIAL( _
      VALINT(MID(*S[24], 5, 2)) + 2000 _
    , VALINT(MID(*S[24], 3, 2)) _
    , VALINT(MID(*S[24], 1, 2)) ) _
  + TIMESERIAL( _
      VALINT(MID(*S[1], 1, 2)) _
    , VALINT(MID(*S[1], 3, 2)) _
    , VALINT(MID(*S[1], 5, 2)) )
END FUNCTION


/'* \brief Evaluate longitude or latitude from text
\param S Start of number, followed by direction (N, W, S, E)
\returns The world angle in radians (or NaN)

Function to evaluate an longitude or latitude entry. It gets a first
ZSTRING PTR pointing to the number (like `01821.7380`), and a second
pointing to the direction (like `E`). Both are concidered to compute
the matching world angle in radians, returning `NaN` in case of invalid
direction.

\since 0.0
'/
FUNCTION NMEA.LaLo(BYVAL S AS ZSTRING PTR PTR) AS DOUBLE
  VAR p = INSTR(*S[0], ".") - 2, f = NaN
  SELECT CASE AS CONST PEEK(UBYTE, S[1])
  CASE ASC("N"), ASC("E") : IF p > 1 THEN f =  Deg2Rad
  CASE ASC("S"), ASC("W") : IF p > 1 THEN f = -Deg2Rad
  END SELECT
  RETURN f * (g_ascii_strtod(MID(*S[0], p), NULL) / 60 + VALINT(LEFT(*S[0], p-1)))
END FUNCTION


/'* \brief Evaluate the lines data
\param S start of entry strings (array of ZSTRING PTR)
\returns location of new result (#TrP array) entry

This function checks the location in both lines. In case of a mismatch
it skips the lines (a point). Otherwise it creates a further entry in
the output array.

\since 0.0
'/
FUNCTION NMEA.Eval(BYVAL S AS ZSTRING PTR PTR) AS TrP PTR
  IF *S[2] <> *S[18] ORELSE _
     *S[3] <> *S[19] ORELSE _
     *S[4] <> *S[20] ORELSE _
     *S[5] <> *S[21] THEN Enr += 1 : ?"location mismatch (" & Lin & ")" : RETURN Dat
  VAR r = NEW(Dat) TrP ( _
    DaTi(S) _              '*< Date / Time
  , LaLo(@S[2]) _          '*< Latitude [radians]
  , LaLo(@S[4]) _          '*< Longitude [radians]
  , Val_(*S[9]) _          '*< Elevation [m]
  , Val_(*S[22]) * 1.852 _ '*< Speed over ground [km/h]
  , Val_(*S[23]) _         '*< Direction Angle [degree]
  , 0 ,0)
  Dat += SIZEOF(TrP)
  RETURN r
END FUNCTION
