\ ******************************************************************************
\
\ ELITE-A SHIP BLUEPRINTS FILE H
\
\ Elite-A is an extended version of BBC Micro Elite by Angus Duggan
\
\ The original Elite was written by Ian Bell and David Braben and is copyright
\ Acornsoft 1984, and the extra code in Elite-A is copyright Angus Duggan
\
\ The code on this site is identical to Angus Duggan's source discs (it's just
\ been reformatted and variable names changed to be more readable)
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology and notations used in this commentary are explained at
\ https://www.bbcelite.com/about_site/terminology_used_in_this_commentary.html
\
\ The deep dive articles referred to in this commentary can be found at
\ https://www.bbcelite.com/deep_dives
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * output/S.H.bin
\
\ ******************************************************************************

INCLUDE "sources/elite-header.h.asm"

_RELEASED               = (_RELEASE = 1)
_SOURCE_DISC            = (_RELEASE = 2)

\ ******************************************************************************
\
\ Configuration variables
\
\ ******************************************************************************

SHIP_MISSILE = &7F00    \ The address of the missile ship blueprint

CODE% = &5600           \ The flight code loads this file at address &5600, at
LOAD% = &5600           \ label XX21

ORG CODE%

\ ******************************************************************************
\
\       Name: XX21
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprints lookup table for the S.H file
\  Deep dive: Ship blueprints in the disc version
\
\ ******************************************************************************

.XX21

 EQUW SHIP_MISSILE      \ MSL  =  1 = Missile
 EQUW SHIP_DODO         \         2 = Dodecahedron ("Dodo") space station
 EQUW SHIP_ESCAPE_POD   \ ESC  =  3 = Escape pod
 EQUW SHIP_PLATE        \ PLT  =  4 = Alloy plate
 EQUW SHIP_CANISTER     \ OIL  =  5 = Cargo canister
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW ship_ghavial      \        11 = Ghavial
 EQUW ship_rattler      \        12 = Rattler
 EQUW SHIP_COBRA_MK_1   \        13 = Cobra Mk I
 EQUW SHIP_ANACONDA     \ ANA  = 14 = Anaconda
 EQUW SHIP_WORM         \        15 = Worm
 EQUW SHIP_VIPER        \ COPS = 16 = Viper
 EQUW SHIP_COBRA_MK_1   \        17 = Cobra Mk I
 EQUW 0
 EQUW SHIP_ADDER        \        19 = Adder
 EQUW 0
 EQUW 0
 EQUW SHIP_WORM         \        22 = Worm
 EQUW ship_rattler      \        23 = Rattler
 EQUW 0
 EQUW 0
 EQUW 0
 EQUW SHIP_COBRA_MK_1   \        27 = Cobra Mk I
 EQUW ship_rattler      \        28 = Rattler
 EQUW 0
 EQUW 0
 EQUW 0

\ ******************************************************************************
\
\       Name: E%
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprints default NEWB flags for the S.H file
\  Deep dive: Ship blueprints
\             Advanced tactics with the NEWB flags
\
\ ******************************************************************************

.E%

 EQUB %00000000         \ Missile
 EQUB %01000000         \ Dodo space station                                 Cop
 EQUB %01000001         \ Escape pod                                 Trader, cop
 EQUB %00000000         \ Alloy plate
 EQUB %00000000         \ Cargo canister
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB %10100000         \ Ghavial                           Innocent, escape pod
 EQUB %10100001         \ Rattler                   Trader, innocent, escape pod
 EQUB %10100000         \ Cobra Mk I                        Innocent, escape pod
 EQUB %10100001         \ Anaconda                  Trader, innocent, escape pod
 EQUB %00001100         \ Worm                                   Hostile, pirate
 EQUB %11000010         \ Viper                   Bounty hunter, cop, escape pod
 EQUB %10001100         \ Cobra Mk I                 Hostile, pirate, escape pod
 EQUB 0
 EQUB %10000100         \ Adder                              Hostile, escape pod
 EQUB 0
 EQUB 0
 EQUB %00001100         \ Worm                                   Hostile, pirate
 EQUB %10000100         \ Rattler                            Hostile, escape pod
 EQUB 0
 EQUB 0
 EQUB 0
 EQUB %10000010         \ Cobra Mk I                   Bounty hunter, escape pod
 EQUB %10100010         \ Rattler            Bounty hunter, innocent, escape pod
 EQUB 0
 EQUB 0
 EQUB 0

\ ******************************************************************************
\
\       Name: VERTEX
\       Type: Macro
\   Category: Drawing ships
\    Summary: Macro definition for adding vertices to ship blueprints
\  Deep dive: Ship blueprints
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used to build the ship blueprints:
\
\   VERTEX x, y, z, face1, face2, face3, face4, visibility
\
\ See the deep dive on "Ship blueprints" for details of how vertices are stored
\ in the ship blueprints, and the deep dive on "Drawing ships" for information
\ on how vertices are used to draw 3D wiremesh ships.
\
\ Arguments:
\
\   x                   The vertex's x-coordinate
\
\   y                   The vertex's y-coordinate
\
\   z                   The vertex's z-coordinate
\
\   face1               The number of face 1 associated with this vertex
\
\   face2               The number of face 2 associated with this vertex
\
\   face3               The number of face 3 associated with this vertex
\
\   face4               The number of face 4 associated with this vertex
\
\   visibility          The visibility distance, beyond which the vertex is not
\                       shown
\
\ ******************************************************************************

MACRO VERTEX x, y, z, face1, face2, face3, face4, visibility

  IF x < 0
    s_x = 1 << 7
  ELSE
    s_x = 0
  ENDIF

  IF y < 0
    s_y = 1 << 6
  ELSE
    s_y = 0
  ENDIF

  IF z < 0
    s_z = 1 << 5
  ELSE
    s_z = 0
  ENDIF

  s = s_x + s_y + s_z + visibility
  f1 = face1 + (face2 << 4)
  f2 = face3 + (face4 << 4)
  ax = ABS(x)
  ay = ABS(y)
  az = ABS(z)

  EQUB ax, ay, az, s, f1, f2

ENDMACRO

\ ******************************************************************************
\
\       Name: EDGE
\       Type: Macro
\   Category: Drawing ships
\    Summary: Macro definition for adding edges to ship blueprints
\  Deep dive: Ship blueprints
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used to build the ship blueprints:
\
\   EDGE vertex1, vertex2, face1, face2, visibility
\
\ See the deep dive on "Ship blueprints" for details of how edges are stored
\ in the ship blueprints, and the deep dive on "Drawing ships" for information
\ on how edges are used to draw 3D wiremesh ships.
\
\ Arguments:
\
\   vertex1             The number of the vertex at the start of the edge
\
\   vertex1             The number of the vertex at the end of the edge
\
\   face1               The number of face 1 associated with this edge
\
\   face2               The number of face 2 associated with this edge
\
\   visibility          The visibility distance, beyond which the edge is not
\                       shown
\
\ ******************************************************************************

MACRO EDGE vertex1, vertex2, face1, face2, visibility

  f = face1 + (face2 << 4)
  EQUB visibility, f, vertex1 << 2, vertex2 << 2

ENDMACRO

\ ******************************************************************************
\
\       Name: FACE
\       Type: Macro
\   Category: Drawing ships
\    Summary: Macro definition for adding faces to ship blueprints
\  Deep dive: Ship blueprints
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used to build the ship blueprints:
\
\   FACE normal_x, normal_y, normal_z, visibility
\
\ See the deep dive on "Ship blueprints" for details of how faces are stored
\ in the ship blueprints, and the deep dive on "Drawing ships" for information
\ on how faces are used to draw 3D wiremesh ships.
\
\ Arguments:
\
\   normal_x            The face normal's x-coordinate
\
\   normal_y            The face normal's y-coordinate
\
\   normal_z            The face normal's z-coordinate
\
\   visibility          The visibility distance, beyond which the edge is always
\                       shown
\
\ ******************************************************************************

MACRO FACE normal_x, normal_y, normal_z, visibility

  IF normal_x < 0
    s_x = 1 << 7
  ELSE
    s_x = 0
  ENDIF

  IF normal_y < 0
    s_y = 1 << 6
  ELSE
    s_y = 0
  ENDIF

  IF normal_z < 0
    s_z = 1 << 5
  ELSE
    s_z = 0
  ENDIF

  s = s_x + s_y + s_z + visibility
  ax = ABS(normal_x)
  ay = ABS(normal_y)
  az = ABS(normal_z)

  EQUB s, ax, ay, az

ENDMACRO

\ ******************************************************************************
\
\       Name: SHIP_DODO
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Dodecahedron ("Dodo") space station
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_DODO

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 180 * 180         \ Targetable area          = 180 * 180
 EQUB &A4               \ Edges data offset (low)  = &00A4
 EQUB &2C               \ Faces data offset (low)  = &012C
 EQUB 97                \ Max. edge count          = (97 - 1) / 4 = 24
 EQUB 0                 \ Gun vertex               = 0
 EQUB 54                \ Explosion count          = 12, as (4 * n) + 6 = 54
 EQUB 144               \ Number of vertices       = 144 / 6 = 24
 EQUB 34                \ Number of edges          = 34
 EQUW 0                 \ Bounty                   = 0
 EQUB 48                \ Number of faces          = 48 / 4 = 12
 EQUB 125               \ Visibility distance      = 125
 EQUB 240               \ Max. energy              = 240
 EQUB 0                 \ Max. speed               = 0
 EQUB &00               \ Edges data offset (high) = &00A4
 EQUB &01               \ Faces data offset (high) = &012C
 EQUB 0                 \ Normals are scaled by    = 2^0 = 1
 EQUB %00000000         \ Laser power              = 0
                        \ Missiles                 = 0

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX    0,  150,  196,     1,      0,    5,     5,         31    \ Vertex 0
 VERTEX  143,   46,  196,     1,      0,    2,     2,         31    \ Vertex 1
 VERTEX   88, -121,  196,     2,      0,    3,     3,         31    \ Vertex 2
 VERTEX  -88, -121,  196,     3,      0,    4,     4,         31    \ Vertex 3
 VERTEX -143,   46,  196,     4,      0,    5,     5,         31    \ Vertex 4
 VERTEX    0,  243,   46,     5,      1,    6,     6,         31    \ Vertex 5
 VERTEX  231,   75,   46,     2,      1,    7,     7,         31    \ Vertex 6
 VERTEX  143, -196,   46,     3,      2,    8,     8,         31    \ Vertex 7
 VERTEX -143, -196,   46,     4,      3,    9,     9,         31    \ Vertex 8
 VERTEX -231,   75,   46,     5,      4,   10,    10,         31    \ Vertex 9
 VERTEX  143,  196,  -46,     6,      1,    7,     7,         31    \ Vertex 10
 VERTEX  231,  -75,  -46,     7,      2,    8,     8,         31    \ Vertex 11
 VERTEX    0, -243,  -46,     8,      3,    9,     9,         31    \ Vertex 12
 VERTEX -231,  -75,  -46,     9,      4,   10,    10,         31    \ Vertex 13
 VERTEX -143,  196,  -46,     6,      5,   10,    10,         31    \ Vertex 14
 VERTEX   88,  121, -196,     7,      6,   11,    11,         31    \ Vertex 15
 VERTEX  143,  -46, -196,     8,      7,   11,    11,         31    \ Vertex 16
 VERTEX    0, -150, -196,     9,      8,   11,    11,         31    \ Vertex 17
 VERTEX -143,  -46, -196,    10,      9,   11,    11,         31    \ Vertex 18
 VERTEX  -88,  121, -196,    10,      6,   11,    11,         31    \ Vertex 19
 VERTEX  -16,   32,  196,     0,      0,    0,     0,         30    \ Vertex 20
 VERTEX  -16,  -32,  196,     0,      0,    0,     0,         30    \ Vertex 21
 VERTEX   16,   32,  196,     0,      0,    0,     0,         23    \ Vertex 22
 VERTEX   16,  -32,  196,     0,      0,    0,     0,         23    \ Vertex 23

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     1,     0,         31    \ Edge 0
 EDGE       1,       2,     2,     0,         31    \ Edge 1
 EDGE       2,       3,     3,     0,         31    \ Edge 2
 EDGE       3,       4,     4,     0,         31    \ Edge 3
 EDGE       4,       0,     5,     0,         31    \ Edge 4
 EDGE       5,      10,     6,     1,         31    \ Edge 5
 EDGE      10,       6,     7,     1,         31    \ Edge 6
 EDGE       6,      11,     7,     2,         31    \ Edge 7
 EDGE      11,       7,     8,     2,         31    \ Edge 8
 EDGE       7,      12,     8,     3,         31    \ Edge 9
 EDGE      12,       8,     9,     3,         31    \ Edge 10
 EDGE       8,      13,     9,     4,         31    \ Edge 11
 EDGE      13,       9,    10,     4,         31    \ Edge 12
 EDGE       9,      14,    10,     5,         31    \ Edge 13
 EDGE      14,       5,     6,     5,         31    \ Edge 14
 EDGE      15,      16,    11,     7,         31    \ Edge 15
 EDGE      16,      17,    11,     8,         31    \ Edge 16
 EDGE      17,      18,    11,     9,         31    \ Edge 17
 EDGE      18,      19,    11,    10,         31    \ Edge 18
 EDGE      19,      15,    11,     6,         31    \ Edge 19
 EDGE       0,       5,     5,     1,         31    \ Edge 20
 EDGE       1,       6,     2,     1,         31    \ Edge 21
 EDGE       2,       7,     3,     2,         31    \ Edge 22
 EDGE       3,       8,     4,     3,         31    \ Edge 23
 EDGE       4,       9,     5,     4,         31    \ Edge 24
 EDGE      10,      15,     7,     6,         31    \ Edge 25
 EDGE      11,      16,     8,     7,         31    \ Edge 26
 EDGE      12,      17,     9,     8,         31    \ Edge 27
 EDGE      13,      18,    10,     9,         31    \ Edge 28
 EDGE      14,      19,    10,     6,         31    \ Edge 29
 EDGE      20,      21,     0,     0,         30    \ Edge 30
 EDGE      21,      23,     0,     0,         20    \ Edge 31
 EDGE      23,      22,     0,     0,         23    \ Edge 32
 EDGE      22,      20,     0,     0,         20    \ Edge 33

\FACE normal_x, normal_y, normal_z, visibility
 FACE        0,        0,      196,         31    \ Face 0
 FACE      103,      142,       88,         31    \ Face 1
 FACE      169,      -55,       89,         31    \ Face 2
 FACE        0,     -176,       88,         31    \ Face 3
 FACE     -169,      -55,       89,         31    \ Face 4
 FACE     -103,      142,       88,         31    \ Face 5
 FACE        0,      176,      -88,         31    \ Face 6
 FACE      169,       55,      -89,         31    \ Face 7
 FACE      103,     -142,      -88,         31    \ Face 8
 FACE     -103,     -142,      -88,         31    \ Face 9
 FACE     -169,       55,      -89,         31    \ Face 10
 FACE        0,        0,     -196,         31    \ Face 11

\ ******************************************************************************
\
\       Name: SHIP_ESCAPE_POD
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for an escape pod
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_ESCAPE_POD

 EQUB 0 + (2 << 4)      \ Max. canisters on demise = 0
                        \ Market item when scooped = 2 + 1 = 3 (Slaves)
 EQUW 16 * 16           \ Targetable area          = 16 * 16
 EQUB &2C               \ Edges data offset (low)  = &002C
 EQUB &44               \ Faces data offset (low)  = &0044
 EQUB 25                \ Max. edge count          = (25 - 1) / 4 = 6
 EQUB 0                 \ Gun vertex               = 0
 EQUB 22                \ Explosion count          = 4, as (4 * n) + 6 = 22
 EQUB 24                \ Number of vertices       = 24 / 6 = 4
 EQUB 6                 \ Number of edges          = 6
 EQUW 0                 \ Bounty                   = 0
 EQUB 16                \ Number of faces          = 16 / 4 = 4
 EQUB 8                 \ Visibility distance      = 8

\ <----------------------------- Code deleted from the original disc version -->
\
\  EQUB 17              \ Max. energy              = 17
\
\ <----------------------------------------------------- End of deleted code -->

\ <-------------------------------------------------- Code added for Elite-A -->

 EQUB 8                 \ Max. energy              = 8

\ <------------------------------------------------------- End of added code -->

 EQUB 8                 \ Max. speed               = 8
 EQUB &00               \ Edges data offset (high) = &002C
 EQUB &00               \ Faces data offset (high) = &0044
 EQUB 4                 \ Normals are scaled by    =  2^4 = 16
 EQUB %00000000         \ Laser power              = 0
                        \ Missiles                 = 0

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX   -7,    0,   36,     2,      1,    3,     3,         31    \ Vertex 0
 VERTEX   -7,  -14,  -12,     2,      0,    3,     3,         31    \ Vertex 1
 VERTEX   -7,   14,  -12,     1,      0,    3,     3,         31    \ Vertex 2
 VERTEX   21,    0,    0,     1,      0,    2,     2,         31    \ Vertex 3

.SHIP_ESCAPE_POD_EDGES

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     3,     2,         31    \ Edge 0
 EDGE       1,       2,     3,     0,         31    \ Edge 1
 EDGE       2,       3,     1,     0,         31    \ Edge 2
 EDGE       3,       0,     2,     1,         31    \ Edge 3
 EDGE       0,       2,     3,     1,         31    \ Edge 4
 EDGE       3,       1,     2,     0,         31    \ Edge 5

\FACE normal_x, normal_y, normal_z, visibility
 FACE       52,        0,     -122,         31    \ Face 0
 FACE       39,      103,       30,         31    \ Face 1
 FACE       39,     -103,       30,         31    \ Face 2
 FACE     -112,        0,        0,         31    \ Face 3

\ ******************************************************************************
\
\       Name: SHIP_CANISTER
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a cargo canister
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_CANISTER

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 20 * 20           \ Targetable area          = 20 * 20
 EQUB &50               \ Edges data offset (low)  = &0050
 EQUB &8C               \ Faces data offset (low)  = &008C
 EQUB 49                \ Max. edge count          = (49 - 1) / 4 = 12
 EQUB 0                 \ Gun vertex               = 0
 EQUB 18                \ Explosion count          = 3, as (4 * n) + 6 = 18
 EQUB 60                \ Number of vertices       = 60 / 6 = 10
 EQUB 15                \ Number of edges          = 15

\ <----------------------------- Code deleted from the original disc version -->
\
\  EQUW 0               \ Bounty                   = 0
\
\ <----------------------------------------------------- End of deleted code -->

\ <-------------------------------------------------- Code added for Elite-A -->

 EQUW 1                 \ Bounty                   = 1

\ <------------------------------------------------------- End of added code -->

 EQUB 28                \ Number of faces          = 28 / 4 = 7
 EQUB 12                \ Visibility distance      = 12

\ <----------------------------- Code deleted from the original disc version -->
\
\  EQUB 17              \ Max. energy              = 17
\
\ <----------------------------------------------------- End of deleted code -->

\ <-------------------------------------------------- Code added for Elite-A -->

 EQUB 8                 \ Max. energy              = 8

\ <------------------------------------------------------- End of added code -->

 EQUB 15                \ Max. speed               = 15
 EQUB &00               \ Edges data offset (high) = &0050
 EQUB &00               \ Faces data offset (high) = &008C
 EQUB 2                 \ Normals are scaled by    = 2^2 = 4
 EQUB %00000000         \ Laser power              = 0
                        \ Missiles                 = 0

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX   24,   16,    0,     0,      1,    5,     5,         31    \ Vertex 0
 VERTEX   24,    5,   15,     0,      1,    2,     2,         31    \ Vertex 1
 VERTEX   24,  -13,    9,     0,      2,    3,     3,         31    \ Vertex 2
 VERTEX   24,  -13,   -9,     0,      3,    4,     4,         31    \ Vertex 3
 VERTEX   24,    5,  -15,     0,      4,    5,     5,         31    \ Vertex 4
 VERTEX  -24,   16,    0,     1,      5,    6,     6,         31    \ Vertex 5
 VERTEX  -24,    5,   15,     1,      2,    6,     6,         31    \ Vertex 6
 VERTEX  -24,  -13,    9,     2,      3,    6,     6,         31    \ Vertex 7
 VERTEX  -24,  -13,   -9,     3,      4,    6,     6,         31    \ Vertex 8
 VERTEX  -24,    5,  -15,     4,      5,    6,     6,         31    \ Vertex 9

.SHIP_CANISTER_EDGES

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     0,     1,         31    \ Edge 0
 EDGE       1,       2,     0,     2,         31    \ Edge 1
 EDGE       2,       3,     0,     3,         31    \ Edge 2
 EDGE       3,       4,     0,     4,         31    \ Edge 3
 EDGE       0,       4,     0,     5,         31    \ Edge 4
 EDGE       0,       5,     1,     5,         31    \ Edge 5
 EDGE       1,       6,     1,     2,         31    \ Edge 6
 EDGE       2,       7,     2,     3,         31    \ Edge 7
 EDGE       3,       8,     3,     4,         31    \ Edge 8
 EDGE       4,       9,     4,     5,         31    \ Edge 9
 EDGE       5,       6,     1,     6,         31    \ Edge 10
 EDGE       6,       7,     2,     6,         31    \ Edge 11
 EDGE       7,       8,     3,     6,         31    \ Edge 12
 EDGE       8,       9,     4,     6,         31    \ Edge 13
 EDGE       9,       5,     5,     6,         31    \ Edge 14

\FACE normal_x, normal_y, normal_z, visibility
 FACE       96,        0,        0,         31    \ Face 0
 FACE        0,       41,       30,         31    \ Face 1
 FACE        0,      -18,       48,         31    \ Face 2
 FACE        0,      -51,        0,         31    \ Face 3
 FACE        0,      -18,      -48,         31    \ Face 4
 FACE        0,       41,      -30,         31    \ Face 5
 FACE      -96,        0,        0,         31    \ Face 6

\ ******************************************************************************
\
\       Name: SHIP_VIPER
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Viper
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_VIPER

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 75 * 75           \ Targetable area          = 75 * 75
 EQUB &6E               \ Edges data offset (low)  = &006E
 EQUB &BE               \ Faces data offset (low)  = &00BE
 EQUB 77                \ Max. edge count          = (77 - 1) / 4 = 19
 EQUB 0                 \ Gun vertex               = 0
 EQUB 42                \ Explosion count          = 9, as (4 * n) + 6 = 42
 EQUB 90                \ Number of vertices       = 90 / 6 = 15
 EQUB 20                \ Number of edges          = 20

 EQUW 0                 \ Bounty                   = 0

 EQUB 28                \ Number of faces          = 28 / 4 = 7
 EQUB 23                \ Visibility distance      = 23

\ <----------------------------- Code deleted from the original disc version -->
\
\  EQUB 100             \ Max. energy              = 100
\
\ <----------------------------------------------------- End of deleted code -->

\ <-------------------------------------------------- Code added for Elite-A -->

 EQUB 91                \ Max. energy              = 91

\ <------------------------------------------------------- End of added code -->

 EQUB 32                \ Max. speed               = 32
 EQUB &00               \ Edges data offset (high) = &006E
 EQUB &00               \ Faces data offset (high) = &00BE
 EQUB 1                 \ Normals are scaled by    = 2^1 = 2

\ <----------------------------- Code deleted from the original disc version -->
\
\  EQUB %00010001       \ Laser power              = 2
\                       \ Missiles                 = 1
\
\ <----------------------------------------------------- End of deleted code -->

\ <-------------------------------------------------- Code added for Elite-A -->

 EQUB %00101001         \ Laser power              = 5
                        \ Missiles                 = 1

\ <------------------------------------------------------- End of added code -->

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX    0,    0,   72,     1,      2,    3,     4,         31    \ Vertex 0
 VERTEX    0,   16,   24,     0,      1,    2,     2,         30    \ Vertex 1
 VERTEX    0,  -16,   24,     3,      4,    5,     5,         30    \ Vertex 2
 VERTEX   48,    0,  -24,     2,      4,    6,     6,         31    \ Vertex 3
 VERTEX  -48,    0,  -24,     1,      3,    6,     6,         31    \ Vertex 4
 VERTEX   24,  -16,  -24,     4,      5,    6,     6,         30    \ Vertex 5
 VERTEX  -24,  -16,  -24,     5,      3,    6,     6,         30    \ Vertex 6
 VERTEX   24,   16,  -24,     0,      2,    6,     6,         31    \ Vertex 7
 VERTEX  -24,   16,  -24,     0,      1,    6,     6,         31    \ Vertex 8
 VERTEX  -32,    0,  -24,     6,      6,    6,     6,         19    \ Vertex 9
 VERTEX   32,    0,  -24,     6,      6,    6,     6,         19    \ Vertex 10
 VERTEX    8,    8,  -24,     6,      6,    6,     6,         19    \ Vertex 11
 VERTEX   -8,    8,  -24,     6,      6,    6,     6,         19    \ Vertex 12
 VERTEX   -8,   -8,  -24,     6,      6,    6,     6,         18    \ Vertex 13
 VERTEX    8,   -8,  -24,     6,      6,    6,     6,         18    \ Vertex 14

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       3,     2,     4,         31    \ Edge 0
 EDGE       0,       1,     1,     2,         30    \ Edge 1
 EDGE       0,       2,     3,     4,         30    \ Edge 2
 EDGE       0,       4,     1,     3,         31    \ Edge 3
 EDGE       1,       7,     0,     2,         30    \ Edge 4
 EDGE       1,       8,     0,     1,         30    \ Edge 5
 EDGE       2,       5,     4,     5,         30    \ Edge 6
 EDGE       2,       6,     3,     5,         30    \ Edge 7
 EDGE       7,       8,     0,     6,         31    \ Edge 8
 EDGE       5,       6,     5,     6,         30    \ Edge 9
 EDGE       4,       8,     1,     6,         31    \ Edge 10
 EDGE       4,       6,     3,     6,         30    \ Edge 11
 EDGE       3,       7,     2,     6,         31    \ Edge 12
 EDGE       3,       5,     6,     4,         30    \ Edge 13
 EDGE       9,      12,     6,     6,         19    \ Edge 14
 EDGE       9,      13,     6,     6,         18    \ Edge 15
 EDGE      10,      11,     6,     6,         19    \ Edge 16
 EDGE      10,      14,     6,     6,         18    \ Edge 17
 EDGE      11,      14,     6,     6,         16    \ Edge 18
 EDGE      12,      13,     6,     6,         16    \ Edge 19

\FACE normal_x, normal_y, normal_z, visibility
 FACE        0,       32,        0,         31    \ Face 0
 FACE      -22,       33,       11,         31    \ Face 1
 FACE       22,       33,       11,         31    \ Face 2
 FACE      -22,      -33,       11,         31    \ Face 3
 FACE       22,      -33,       11,         31    \ Face 4
 FACE        0,      -32,        0,         31    \ Face 5
 FACE        0,        0,      -48,         31    \ Face 6

\ ******************************************************************************
\
\       Name: SHIP_ANACONDA
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for an Anaconda
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_ANACONDA

 EQUB 7                 \ Max. canisters on demise = 7
 EQUW 100 * 100         \ Targetable area          = 100 * 100
 EQUB &6E               \ Edges data offset (low)  = &006E
 EQUB &D2               \ Faces data offset (low)  = &00D2
 EQUB 89                \ Max. edge count          = (89 - 1) / 4 = 22
 EQUB 48                \ Gun vertex               = 48
 EQUB 46                \ Explosion count          = 10, as (4 * n) + 6 = 46
 EQUB 90                \ Number of vertices       = 90 / 6 = 15
 EQUB 25                \ Number of edges          = 25

\ <----------------------------- Code deleted from the original disc version -->
\
\  EQUW 0               \ Bounty                   = 0
\
\ <----------------------------------------------------- End of deleted code -->

\ <-------------------------------------------------- Code added for Elite-A -->

 EQUW 350               \ Bounty                   = 350

\ <------------------------------------------------------- End of added code -->

 EQUB 48                \ Number of faces          = 48 / 4 = 12
 EQUB 50                \ Visibility distance      = 50
 EQUB 252               \ Max. energy              = 252
 EQUB 14                \ Max. speed               = 14
 EQUB &00               \ Edges data offset (high) = &006E
 EQUB &00               \ Faces data offset (high) = &00D2
 EQUB 1                 \ Normals are scaled by    = 2^1 = 2

\ <----------------------------- Code deleted from the original disc version -->
\
\  EQUB %00111111       \ Laser power              = 7
\                       \ Missiles                 = 7
\
\ <----------------------------------------------------- End of deleted code -->

\ <-------------------------------------------------- Code added for Elite-A -->

 EQUB %01001111         \ Laser power              = 9
                        \ Missiles                 = 7

\ <------------------------------------------------------- End of added code -->

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX    0,    7,  -58,     1,      0,    5,     5,         30    \ Vertex 0
 VERTEX  -43,  -13,  -37,     1,      0,    2,     2,         30    \ Vertex 1
 VERTEX  -26,  -47,   -3,     2,      0,    3,     3,         30    \ Vertex 2
 VERTEX   26,  -47,   -3,     3,      0,    4,     4,         30    \ Vertex 3
 VERTEX   43,  -13,  -37,     4,      0,    5,     5,         30    \ Vertex 4
 VERTEX    0,   48,  -49,     5,      1,    6,     6,         30    \ Vertex 5
 VERTEX  -69,   15,  -15,     2,      1,    7,     7,         30    \ Vertex 6
 VERTEX  -43,  -39,   40,     3,      2,    8,     8,         31    \ Vertex 7
 VERTEX   43,  -39,   40,     4,      3,    9,     9,         31    \ Vertex 8
 VERTEX   69,   15,  -15,     5,      4,   10,    10,         30    \ Vertex 9
 VERTEX  -43,   53,  -23,    15,     15,   15,    15,         31    \ Vertex 10
 VERTEX  -69,   -1,   32,     7,      2,    8,     8,         31    \ Vertex 11
 VERTEX    0,    0,  254,    15,     15,   15,    15,         31    \ Vertex 12
 VERTEX   69,   -1,   32,     9,      4,   10,    10,         31    \ Vertex 13
 VERTEX   43,   53,  -23,    15,     15,   15,    15,         31    \ Vertex 14

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     1,     0,         30    \ Edge 0
 EDGE       1,       2,     2,     0,         30    \ Edge 1
 EDGE       2,       3,     3,     0,         30    \ Edge 2
 EDGE       3,       4,     4,     0,         30    \ Edge 3
 EDGE       0,       4,     5,     0,         30    \ Edge 4
 EDGE       0,       5,     5,     1,         29    \ Edge 5
 EDGE       1,       6,     2,     1,         29    \ Edge 6
 EDGE       2,       7,     3,     2,         29    \ Edge 7
 EDGE       3,       8,     4,     3,         29    \ Edge 8
 EDGE       4,       9,     5,     4,         29    \ Edge 9
 EDGE       5,      10,     6,     1,         30    \ Edge 10
 EDGE       6,      10,     7,     1,         30    \ Edge 11
 EDGE       6,      11,     7,     2,         30    \ Edge 12
 EDGE       7,      11,     8,     2,         30    \ Edge 13
 EDGE       7,      12,     8,     3,         31    \ Edge 14
 EDGE       8,      12,     9,     3,         31    \ Edge 15
 EDGE       8,      13,     9,     4,         30    \ Edge 16
 EDGE       9,      13,    10,     4,         30    \ Edge 17
 EDGE       9,      14,    10,     5,         30    \ Edge 18
 EDGE       5,      14,     6,     5,         30    \ Edge 19
 EDGE      10,      14,    11,     6,         30    \ Edge 20
 EDGE      10,      12,    11,     7,         31    \ Edge 21
 EDGE      11,      12,     8,     7,         31    \ Edge 22
 EDGE      12,      13,    10,     9,         31    \ Edge 23
 EDGE      12,      14,    11,    10,         31    \ Edge 24

\FACE normal_x, normal_y, normal_z, visibility
 FACE        0,      -51,      -49,         30    \ Face 0
 FACE      -51,       18,      -87,         30    \ Face 1
 FACE      -77,      -57,      -19,         30    \ Face 2
 FACE        0,      -90,       16,         31    \ Face 3
 FACE       77,      -57,      -19,         30    \ Face 4
 FACE       51,       18,      -87,         30    \ Face 5
 FACE        0,      111,      -20,         30    \ Face 6
 FACE      -97,       72,       24,         31    \ Face 7
 FACE     -108,      -68,       34,         31    \ Face 8
 FACE      108,      -68,       34,         31    \ Face 9
 FACE       97,       72,       24,         31    \ Face 10
 FACE        0,       94,       18,         31    \ Face 11

\ ******************************************************************************
\
\       Name: SHIP_WORM
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Worm
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_WORM

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 99 * 99           \ Targetable area          = 99 * 99
 EQUB &50               \ Edges data offset (low)  = &0050
 EQUB &90               \ Faces data offset (low)  = &0090
 EQUB 73                \ Max. edge count          = (73 - 1) / 4 = 18
 EQUB 0                 \ Gun vertex               = 0
 EQUB 18                \ Explosion count          = 3, as (4 * n) + 6 = 18
 EQUB 60                \ Number of vertices       = 60 / 6 = 10
 EQUB 16                \ Number of edges          = 16
 EQUW 0                 \ Bounty                   = 0
 EQUB 32                \ Number of faces          = 32 / 4 = 8
 EQUB 19                \ Visibility distance      = 19

\ <----------------------------- Code deleted from the original disc version -->
\
\  EQUB 30              \ Max. energy              = 30
\
\ <----------------------------------------------------- End of deleted code -->

\ <-------------------------------------------------- Code added for Elite-A -->

 EQUB 32                \ Max. energy              = 32

\ <------------------------------------------------------- End of added code -->

 EQUB 23                \ Max. speed               = 23
 EQUB &00               \ Edges data offset (high) = &0050
 EQUB &00               \ Faces data offset (high) = &0090
 EQUB 3                 \ Normals are scaled by    = 2^3 = 8

\ <----------------------------- Code deleted from the original disc version -->
\
\  EQUB %00001000       \ Laser power              = 1
\                       \ Missiles                 = 0
\
\ <----------------------------------------------------- End of deleted code -->

\ <-------------------------------------------------- Code added for Elite-A -->

 EQUB %00011000         \ Laser power              = 3
                        \ Missiles                 = 0

\ <------------------------------------------------------- End of added code -->

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX   10,  -10,   35,     2,      0,    7,     7,         31    \ Vertex 0
 VERTEX  -10,  -10,   35,     3,      0,    7,     7,         31    \ Vertex 1
 VERTEX    5,    6,   15,     1,      0,    4,     2,         31    \ Vertex 2
 VERTEX   -5,    6,   15,     1,      0,    5,     3,         31    \ Vertex 3
 VERTEX   15,  -10,   25,     4,      2,    7,     7,         31    \ Vertex 4
 VERTEX  -15,  -10,   25,     5,      3,    7,     7,         31    \ Vertex 5
 VERTEX   26,  -10,  -25,     6,      4,    7,     7,         31    \ Vertex 6
 VERTEX  -26,  -10,  -25,     6,      5,    7,     7,         31    \ Vertex 7
 VERTEX    8,   14,  -25,     4,      1,    6,     6,         31    \ Vertex 8
 VERTEX   -8,   14,  -25,     5,      1,    6,     6,         31    \ Vertex 9

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     7,     0,         31    \ Edge 0
 EDGE       1,       5,     7,     3,         31    \ Edge 1
 EDGE       5,       7,     7,     5,         31    \ Edge 2
 EDGE       7,       6,     7,     6,         31    \ Edge 3
 EDGE       6,       4,     7,     4,         31    \ Edge 4
 EDGE       4,       0,     7,     2,         31    \ Edge 5
 EDGE       0,       2,     2,     0,         31    \ Edge 6
 EDGE       1,       3,     3,     0,         31    \ Edge 7
 EDGE       4,       2,     4,     2,         31    \ Edge 8
 EDGE       5,       3,     5,     3,         31    \ Edge 9
 EDGE       2,       8,     4,     1,         31    \ Edge 10
 EDGE       8,       6,     6,     4,         31    \ Edge 11
 EDGE       3,       9,     5,     1,         31    \ Edge 12
 EDGE       9,       7,     6,     5,         31    \ Edge 13
 EDGE       2,       3,     1,     0,         31    \ Edge 14
 EDGE       8,       9,     6,     1,         31    \ Edge 15

\FACE normal_x, normal_y, normal_z, visibility
 FACE        0,       88,       70,         31    \ Face 0
 FACE        0,       69,       14,         31    \ Face 1
 FACE       70,       66,       35,         31    \ Face 2
 FACE      -70,       66,       35,         31    \ Face 3
 FACE       64,       49,       14,         31    \ Face 4
 FACE      -64,       49,       14,         31    \ Face 5
 FACE        0,        0,     -200,         31    \ Face 6
 FACE        0,      -80,        0,         31    \ Face 7

\ ******************************************************************************
\
\       Name: SHIP_COBRA_MK_1
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Cobra Mk I
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_COBRA_MK_1

 EQUB 3                 \ Max. canisters on demise = 3
 EQUW 99 * 99           \ Targetable area          = 99 * 99
 EQUB &56               \ Edges data offset (low)  = &0056
 EQUB &9E               \ Faces data offset (low)  = &009E
 EQUB 69                \ Max. edge count          = (69 - 1) / 4 = 17
 EQUB 40                \ Gun vertex               = 40
 EQUB 26                \ Explosion count          = 5, as (4 * n) + 6 = 26
 EQUB 66                \ Number of vertices       = 66 / 6 = 11
 EQUB 18                \ Number of edges          = 18
 EQUW 75                \ Bounty                   = 75
 EQUB 40                \ Number of faces          = 40 / 4 = 10
 EQUB 19                \ Visibility distance      = 19

\ <----------------------------- Code deleted from the original disc version -->
\
\  EQUB 90              \ Max. energy              = 90
\
\ <----------------------------------------------------- End of deleted code -->

\ <-------------------------------------------------- Code added for Elite-A -->

 EQUB 81                \ Max. energy              = 81

\ <------------------------------------------------------- End of added code -->

 EQUB 26                \ Max. speed               = 26
 EQUB &00               \ Edges data offset (high) = &0056
 EQUB &00               \ Faces data offset (high) = &009E
 EQUB 2                 \ Normals are scaled by    = 2^2 = 4

\ <----------------------------- Code deleted from the original disc version -->
\
\  EQUB %00010010       \ Laser power              = 2
\                       \ Missiles                 = 2
\
\ <----------------------------------------------------- End of deleted code -->

\ <-------------------------------------------------- Code added for Elite-A -->

 EQUB %00100010         \ Laser power              = 4
                        \ Missiles                 = 2

\ <------------------------------------------------------- End of added code -->

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX  -18,   -1,   50,     1,      0,    3,     2,         31    \ Vertex 0
 VERTEX   18,   -1,   50,     1,      0,    5,     4,         31    \ Vertex 1
 VERTEX  -66,    0,    7,     3,      2,    8,     8,         31    \ Vertex 2
 VERTEX   66,    0,    7,     5,      4,    9,     9,         31    \ Vertex 3
 VERTEX  -32,   12,  -38,     6,      2,    8,     7,         31    \ Vertex 4
 VERTEX   32,   12,  -38,     6,      4,    9,     7,         31    \ Vertex 5
 VERTEX  -54,  -12,  -38,     3,      1,    8,     7,         31    \ Vertex 6
 VERTEX   54,  -12,  -38,     5,      1,    9,     7,         31    \ Vertex 7
 VERTEX    0,   12,   -6,     2,      0,    6,     4,         20    \ Vertex 8
 VERTEX    0,   -1,   50,     1,      0,    1,     1,          2    \ Vertex 9
 VERTEX    0,   -1,   60,     1,      0,    1,     1,         31    \ Vertex 10

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       1,       0,     1,     0,         31    \ Edge 0
 EDGE       0,       2,     3,     2,         31    \ Edge 1
 EDGE       2,       6,     8,     3,         31    \ Edge 2
 EDGE       6,       7,     7,     1,         31    \ Edge 3
 EDGE       7,       3,     9,     5,         31    \ Edge 4
 EDGE       3,       1,     5,     4,         31    \ Edge 5
 EDGE       2,       4,     8,     2,         31    \ Edge 6
 EDGE       4,       5,     7,     6,         31    \ Edge 7
 EDGE       5,       3,     9,     4,         31    \ Edge 8
 EDGE       0,       8,     2,     0,         20    \ Edge 9
 EDGE       8,       1,     4,     0,         20    \ Edge 10
 EDGE       4,       8,     6,     2,         16    \ Edge 11
 EDGE       8,       5,     6,     4,         16    \ Edge 12
 EDGE       4,       6,     8,     7,         31    \ Edge 13
 EDGE       5,       7,     9,     7,         31    \ Edge 14
 EDGE       0,       6,     3,     1,         20    \ Edge 15
 EDGE       1,       7,     5,     1,         20    \ Edge 16
 EDGE      10,       9,     1,     0,          2    \ Edge 17

\FACE normal_x, normal_y, normal_z, visibility
 FACE        0,       41,       10,         31    \ Face 0
 FACE        0,      -27,        3,         31    \ Face 1
 FACE       -8,       46,        8,         31    \ Face 2
 FACE      -12,      -57,       12,         31    \ Face 3
 FACE        8,       46,        8,         31    \ Face 4
 FACE       12,      -57,       12,         31    \ Face 5
 FACE        0,       49,        0,         31    \ Face 6
 FACE        0,        0,     -154,         31    \ Face 7
 FACE     -121,      111,      -62,         31    \ Face 8
 FACE      121,      111,      -62,         31    \ Face 9

\ ******************************************************************************
\
\       Name: ship_rattler
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Rattler
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.ship_rattler

 EQUB 2                 \ Max. canisters on demise = 2
 EQUW 6000              \ Targetable area          = 77.46 * 77.46
 EQUB &6E               \ Edges data offset (low)  = &006E
 EQUB &D6               \ Faces data offset (low)  = &00D6
 EQUB 89                \ Max. edge count          = (89 - 1) / 4 = 22
 EQUB 0                 \ Gun vertex               = 0
 EQUB 42                \ Explosion count          = 9, as (4 * n) + 6 = 42
 EQUB 90                \ Number of vertices       = 90 / 6 = 15
 EQUB 26                \ Number of edges          = 26
 EQUW 150               \ Bounty                   = 150
 EQUB 52                \ Number of faces          = 52 / 4 = 13
 EQUB 10                \ Visibility distance      = 10
 EQUB 113               \ Max. energy              = 113
 EQUB 31                \ Max. speed               = 31
 EQUB &00               \ Edges data offset (high) = &006E
 EQUB &00               \ Faces data offset (high) = &00D6
 EQUB 1                 \ Normals are scaled by    = 2^1 = 2
 EQUB %00100010         \ Laser power              = 4
                        \ Missiles                 = 2

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX    0,    0,   60,     9,     8,     3,     2,         31     \ Vertex 0
 VERTEX   40,    0,   40,    10,     9,     4,     3,         31     \ Vertex 1
 VERTEX  -40,    0,   40,     8,     7,     2,     1,         31     \ Vertex 2
 VERTEX   60,    0,    0,    11,    10,     5,     4,         31     \ Vertex 3
 VERTEX  -60,    0,    0,     7,     6,     1,     0,         31     \ Vertex 4
 VERTEX   70,    0,  -40,    12,    12,    11,     5,         31     \ Vertex 5
 VERTEX  -70,    0,  -40,    12,    12,     6,     0,         31     \ Vertex 6
 VERTEX    0,   20,  -40,    15,    15,    15,    15,         31     \ Vertex 7
 VERTEX    0,  -20,  -40,    15,    15,    15,    15,         31     \ Vertex 8
 VERTEX  -10,    6,  -40,    12,    12,    12,    12,         10     \ Vertex 9
 VERTEX  -10,   -6,  -40,    12,    12,    12,    12,         10     \ Vertex 10
 VERTEX  -20,    0,  -40,    12,    12,    12,    12,         10     \ Vertex 11
 VERTEX   10,    6,  -40,    12,    12,    12,    12,         10     \ Vertex 12
 VERTEX   10,   -6,  -40,    12,    12,    12,    12,         10     \ Vertex 13
 VERTEX   20,    0,  -40,    12,    12,    12,    12,         10     \ Vertex 14

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       4,       6,     6,     0,         31    \ Edge 0
 EDGE       2,       4,     7,     1,         31    \ Edge 1
 EDGE       0,       2,     8,     2,         31    \ Edge 2
 EDGE       0,       1,     9,     3,         31    \ Edge 3
 EDGE       1,       3,    10,     4,         31    \ Edge 4
 EDGE       3,       5,    11,     5,         31    \ Edge 5
 EDGE       6,       7,    12,     0,         31    \ Edge 6
 EDGE       6,       8,    12,     6,         31    \ Edge 7
 EDGE       4,       7,     1,     0,         31    \ Edge 8
 EDGE       4,       8,     7,     6,         31    \ Edge 9
 EDGE       2,       7,     2,     1,         31    \ Edge 10
 EDGE       2,       8,     8,     7,         31    \ Edge 11
 EDGE       0,       7,     3,     2,         31    \ Edge 12
 EDGE       0,       8,     9,     8,         31    \ Edge 13
 EDGE       1,       7,     4,     3,         31    \ Edge 14
 EDGE       1,       8,    10,     9,         31    \ Edge 15
 EDGE       3,       7,     5,     4,         31    \ Edge 16
 EDGE       3,       8,    11,    10,         31    \ Edge 17
 EDGE       5,       7,    12,     5,         31    \ Edge 18
 EDGE       5,       8,    12,    11,         31    \ Edge 19
 EDGE       9,      10,    12,    12,         10    \ Edge 20
 EDGE      10,      11,    12,    12,         10    \ Edge 21
 EDGE      11,       9,    12,    12,         10    \ Edge 22
 EDGE      12,      13,    12,    12,         10    \ Edge 23
 EDGE      13,      14,    12,    12,         10    \ Edge 24
 EDGE      14,      12,    12,    12,         10    \ Edge 25

\FACE normal_x, normal_y, normal_z, visibility
 FACE      -26,       92,        6,         31    \ Face 0
 FACE      -23,       92,       11,         31    \ Face 1
 FACE       -9,       93,       18,         31    \ Face 2
 FACE        9,       93,       18,         31    \ Face 3
 FACE       23,       92,       11,         31    \ Face 4
 FACE       26,       92,        6,         31    \ Face 5
 FACE      -26,      -92,        6,         31    \ Face 6
 FACE      -23,      -92,       11,         31    \ Face 7
 FACE       -9,      -93,       18,         31    \ Face 8
 FACE        9,      -93,       18,         31    \ Face 9
 FACE       23,      -92,       11,         31    \ Face 10
 FACE       26,      -92,        6,         31    \ Face 11
 FACE        0,        0,      -96,         31    \ Face 12

\ ******************************************************************************
\
\       Name: SHIP_ADDER
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for an Adder
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_ADDER

 EQUB 0                 \ Max. canisters on demise = 0
 EQUW 50 * 50           \ Targetable area          = 50 * 50
 EQUB &80               \ Edges data offset (low)  = &0080
 EQUB &F4               \ Faces data offset (low)  = &00F4
 EQUB 97                \ Max. edge count          = (97 - 1) / 4 = 24
 EQUB 0                 \ Gun vertex               = 0
 EQUB 22                \ Explosion count          = 4, as (4 * n) + 6 = 22
 EQUB 108               \ Number of vertices       = 108 / 6 = 18
 EQUB 29                \ Number of edges          = 29
 EQUW 40                \ Bounty                   = 40
 EQUB 60                \ Number of faces          = 60 / 4 = 15
 EQUB 23                \ Visibility distance      = 23

\ <----------------------------- Code deleted from the original disc version -->
\
\  EQUB 85              \ Max. energy              = 85
\
\ <----------------------------------------------------- End of deleted code -->

\ <-------------------------------------------------- Code added for Elite-A -->

 EQUB 72                \ Max. energy              = 72

\ <------------------------------------------------------- End of added code -->

 EQUB 24                \ Max. speed               = 24
 EQUB &00               \ Edges data offset (high) = &0080
 EQUB &00               \ Faces data offset (high) = &00F4
 EQUB 2                 \ Normals are scaled by    = 2^2 = 4

\ <----------------------------- Code deleted from the original disc version -->
\
\  EQUB %00010000       \ Laser power              = 2
\                       \ Missiles                 = 0
\
\ <----------------------------------------------------- End of deleted code -->

\ <-------------------------------------------------- Code added for Elite-A -->

 EQUB %00100001         \ Laser power              = 4
                        \ Missiles                 = 1

\ <------------------------------------------------------- End of added code -->

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX  -18,    0,   40,     1,      0,   12,    11,         31    \ Vertex 0
 VERTEX   18,    0,   40,     1,      0,    3,     2,         31    \ Vertex 1
 VERTEX   30,    0,  -24,     3,      2,    5,     4,         31    \ Vertex 2
 VERTEX   30,    0,  -40,     5,      4,    6,     6,         31    \ Vertex 3
 VERTEX   18,   -7,  -40,     6,      5,   14,     7,         31    \ Vertex 4
 VERTEX  -18,   -7,  -40,     8,      7,   14,    10,         31    \ Vertex 5
 VERTEX  -30,    0,  -40,     9,      8,   10,    10,         31    \ Vertex 6
 VERTEX  -30,    0,  -24,    10,      9,   12,    11,         31    \ Vertex 7
 VERTEX  -18,    7,  -40,     8,      7,   13,     9,         31    \ Vertex 8
 VERTEX   18,    7,  -40,     6,      4,   13,     7,         31    \ Vertex 9
 VERTEX  -18,    7,   13,     9,      0,   13,    11,         31    \ Vertex 10
 VERTEX   18,    7,   13,     2,      0,   13,     4,         31    \ Vertex 11
 VERTEX  -18,   -7,   13,    10,      1,   14,    12,         31    \ Vertex 12
 VERTEX   18,   -7,   13,     3,      1,   14,     5,         31    \ Vertex 13
 VERTEX  -11,    3,   29,     0,      0,    0,     0,          5    \ Vertex 14
 VERTEX   11,    3,   29,     0,      0,    0,     0,          5    \ Vertex 15
 VERTEX   11,    4,   24,     0,      0,    0,     0,          4    \ Vertex 16
 VERTEX  -11,    4,   24,     0,      0,    0,     0,          4    \ Vertex 17

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,     1,     0,         31    \ Edge 0
 EDGE       1,       2,     3,     2,          7    \ Edge 1
 EDGE       2,       3,     5,     4,         31    \ Edge 2
 EDGE       3,       4,     6,     5,         31    \ Edge 3
 EDGE       4,       5,    14,     7,         31    \ Edge 4
 EDGE       5,       6,    10,     8,         31    \ Edge 5
 EDGE       6,       7,    10,     9,         31    \ Edge 6
 EDGE       7,       0,    12,    11,          7    \ Edge 7
 EDGE       3,       9,     6,     4,         31    \ Edge 8
 EDGE       9,       8,    13,     7,         31    \ Edge 9
 EDGE       8,       6,     9,     8,         31    \ Edge 10
 EDGE       0,      10,    11,     0,         31    \ Edge 11
 EDGE       7,      10,    11,     9,         31    \ Edge 12
 EDGE       1,      11,     2,     0,         31    \ Edge 13
 EDGE       2,      11,     4,     2,         31    \ Edge 14
 EDGE       0,      12,    12,     1,         31    \ Edge 15
 EDGE       7,      12,    12,    10,         31    \ Edge 16
 EDGE       1,      13,     3,     1,         31    \ Edge 17
 EDGE       2,      13,     5,     3,         31    \ Edge 18
 EDGE      10,      11,    13,     0,         31    \ Edge 19
 EDGE      12,      13,    14,     1,         31    \ Edge 20
 EDGE       8,      10,    13,     9,         31    \ Edge 21
 EDGE       9,      11,    13,     4,         31    \ Edge 22
 EDGE       5,      12,    14,    10,         31    \ Edge 23
 EDGE       4,      13,    14,     5,         31    \ Edge 24
 EDGE      14,      15,     0,     0,          5    \ Edge 25
 EDGE      15,      16,     0,     0,          3    \ Edge 26
 EDGE      16,      17,     0,     0,          4    \ Edge 27
 EDGE      17,      14,     0,     0,          3    \ Edge 28

\FACE normal_x, normal_y, normal_z, visibility
 FACE        0,       39,       10,         31    \ Face 0
 FACE        0,      -39,       10,         31    \ Face 1
 FACE       69,       50,       13,         31    \ Face 2
 FACE       69,      -50,       13,         31    \ Face 3
 FACE       30,       52,        0,         31    \ Face 4
 FACE       30,      -52,        0,         31    \ Face 5
 FACE        0,        0,     -160,         31    \ Face 6
 FACE        0,        0,     -160,         31    \ Face 7
 FACE        0,        0,     -160,         31    \ Face 8
 FACE      -30,       52,        0,         31    \ Face 9
 FACE      -30,      -52,        0,         31    \ Face 10
 FACE      -69,       50,       13,         31    \ Face 11
 FACE      -69,      -50,       13,         31    \ Face 12
 FACE        0,       28,        0,         31    \ Face 13
 FACE        0,      -28,        0,         31    \ Face 14

\ ******************************************************************************
\
\       Name: ship_ghavial
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for a Ghavial
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.ship_ghavial

 EQUB 3                 \ Max. canisters on demise = 3
 EQUW 9728              \ Targetable area          = 98.63 * 98.63
 EQUB &5C               \ Edges data offset (low)  = &005C
 EQUB &B4               \ Faces data offset (low)  = &00B4
 EQUB 97                \ Max. edge count          = (97 - 1) / 4 = 24
 EQUB 0                 \ Gun vertex               = 0
 EQUB 34                \ Explosion count          = 7, as (4 * n) + 6 = 34
 EQUB 72                \ Number of vertices       = 72 / 6 = 12
 EQUB 22                \ Number of edges          = 22
 EQUW 100               \ Bounty                   = 100
 EQUB 48                \ Number of faces          = 48 / 4 = 12
 EQUB 10                \ Visibility distance      = 10
 EQUB 114               \ Max. energy              = 114
 EQUB 16                \ Max. speed               = 16
 EQUB &00               \ Edges data offset (high) = &005C
 EQUB &00               \ Faces data offset (high) = &00B4
 EQUB 0                 \ Normals are scaled by    = 2^0 = 1
 EQUB %00100111         \ Laser power              = 4
                        \ Missiles                 = 7

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX   30,    0,  100,     7,     6,     1,     0,         31     \ Vertex 0
 VERTEX  -30,    0,  100,    11,     6,     5,     0,         31     \ Vertex 1
 VERTEX   40,   30,  -26,     3,     2,     1,     0,         31     \ Vertex 2
 VERTEX  -40,   30,  -26,     5,     4,     3,     0,         31     \ Vertex 3
 VERTEX   60,    0,  -20,     8,     7,     2,     1,         31     \ Vertex 4
 VERTEX   40,    0,  -60,     9,     8,     3,     2,         31     \ Vertex 5
 VERTEX  -60,    0,  -20,    11,    10,     5,     4,         31     \ Vertex 6
 VERTEX  -40,    0,  -60,    10,     9,     4,     3,         31     \ Vertex 7
 VERTEX    0,  -30,  -20,    15,    15,    15,    15,         31     \ Vertex 8
 VERTEX   10,   24,    0,     0,     0,     0,     0,          9     \ Vertex 9
 VERTEX  -10,   24,    0,     0,     0,     0,     0,          9     \ Vertex 10
 VERTEX    0,   22,   10,     0,     0,     0,     0,          9     \ Vertex 11

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       2,     1,     0,         31    \ Edge 0
 EDGE       4,       2,     2,     1,         31    \ Edge 1
 EDGE       5,       2,     3,     2,         31    \ Edge 2
 EDGE       3,       2,     0,     3,         31    \ Edge 3
 EDGE       7,       3,     4,     3,         31    \ Edge 4
 EDGE       6,       3,     5,     4,         31    \ Edge 5
 EDGE       3,       1,     0,     5,         31    \ Edge 6
 EDGE       0,       8,     7,     6,         31    \ Edge 7
 EDGE       4,       8,     8,     7,         31    \ Edge 8
 EDGE       5,       8,     9,     8,         31    \ Edge 9
 EDGE       7,       8,    10,     9,         31    \ Edge 10
 EDGE       6,       8,    11,    10,         31    \ Edge 11
 EDGE       1,       8,     6,    11,         31    \ Edge 12
 EDGE       1,       0,     6,     0,         31    \ Edge 13
 EDGE       0,       4,     7,     1,         31    \ Edge 14
 EDGE       4,       5,     8,     2,         31    \ Edge 15
 EDGE       5,       7,     9,     3,         31    \ Edge 16
 EDGE       7,       6,    10,     4,         31    \ Edge 17
 EDGE       6,       1,    11,     5,         31    \ Edge 18
 EDGE       9,      10,     0,     0,          9    \ Edge 19
 EDGE      10,      11,     0,     0,          9    \ Edge 20
 EDGE      11,       9,     0,     0,          9    \ Edge 21

\FACE normal_x, normal_y, normal_z, visibility
 FACE        0,       62,       14,         31    \ Face 0
 FACE       51,       36,       12,         31    \ Face 1
 FACE       51,       28,      -25,         31    \ Face 2
 FACE        0,       48,      -42,         31    \ Face 3
 FACE      -51,       28,      -25,         31    \ Face 4
 FACE      -51,       36,       12,         31    \ Face 5
 FACE        0,      -62,       15,         31    \ Face 6
 FACE       28,      -56,        7,         31    \ Face 7
 FACE       27,      -55,      -13,         31    \ Face 8
 FACE        0,      -51,      -38,         31    \ Face 9
 FACE      -27,      -55,      -13,         31    \ Face 10
 FACE      -28,      -56,        7,         31    \ Face 11

\ ******************************************************************************
\
\       Name: SHIP_PLATE
\       Type: Variable
\   Category: Drawing ships
\    Summary: Ship blueprint for an alloy plate
\  Deep dive: Ship blueprints
\
\ ******************************************************************************

.SHIP_PLATE

 EQUB 0 + (8 << 4)      \ Max. canisters on demise = 0
                        \ Market item when scooped = 8 + 1 = 9 (Alloys)
 EQUW 10 * 10           \ Targetable area          = 10 * 10
 EQUB &2C               \ Edges data offset (low)  = &002C
 EQUB &3C               \ Faces data offset (low)  = &003C
 EQUB 17                \ Max. edge count          = (17 - 1) / 4 = 4
 EQUB 0                 \ Gun vertex               = 0
 EQUB 10                \ Explosion count          = 1, as (4 * n) + 6 = 10
 EQUB 24                \ Number of vertices       = 24 / 6 = 4
 EQUB 4                 \ Number of edges          = 4

\ <----------------------------- Code deleted from the original disc version -->
\
\  EQUW 0               \ Bounty                   = 0
\
\ <----------------------------------------------------- End of deleted code -->

\ <-------------------------------------------------- Code added for Elite-A -->

 EQUW 1                 \ Bounty                   = 1

\ <------------------------------------------------------- End of added code -->

 EQUB 4                 \ Number of faces          = 4 / 4 = 1
 EQUB 5                 \ Visibility distance      = 5

\ <----------------------------- Code deleted from the original disc version -->
\
\  EQUB 16              \ Max. energy              = 16
\
\ <----------------------------------------------------- End of deleted code -->

\ <-------------------------------------------------- Code added for Elite-A -->

 EQUB 8                 \ Max. energy              = 8

\ <------------------------------------------------------- End of added code -->

 EQUB 16                \ Max. speed               = 16
 EQUB &00               \ Edges data offset (high) = &002C
 EQUB &00               \ Faces data offset (high) = &003C
 EQUB 3                 \ Normals are scaled by    = 2^3 = 8
 EQUB %00000000         \ Laser power              = 0
                        \ Missiles                 = 0

\VERTEX    x,    y,    z, face1, face2, face3, face4, visibility
 VERTEX  -15,  -22,   -9,    15,     15,   15,    15,         31    \ Vertex 0
 VERTEX  -15,   38,   -9,    15,     15,   15,    15,         31    \ Vertex 1
 VERTEX   19,   32,   11,    15,     15,   15,    15,         20    \ Vertex 2
 VERTEX   10,  -46,    6,    15,     15,   15,    15,         20    \ Vertex 3

\EDGE vertex1, vertex2, face1, face2, visibility
 EDGE       0,       1,    15,    15,         31    \ Edge 0
 EDGE       1,       2,    15,    15,         16    \ Edge 1
 EDGE       2,       3,    15,    15,         20    \ Edge 2
 EDGE       3,       0,    15,    15,         16    \ Edge 3

\FACE normal_x, normal_y, normal_z, visibility
 FACE        0,        0,        0,          0    \ Face 0

 EQUB 6                 \ AJD

\ ******************************************************************************
\
\ Save output/S.H.bin
\
\ ******************************************************************************

PRINT "S.S.H ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD%
SAVE "output/S.H.bin", CODE%, CODE% + &0A00
