\ ******************************************************************************
\
\ ELITE-A ENCYCLOPEDIA SOURCE
\
\ Elite-A is an extended version of BBC Micro Elite by Angus Duggan
\
\ The original Elite was written by Ian Bell and David Braben and is copyright
\ Acornsoft 1984, and the extra code in Elite-A is copyright Angus Duggan
\
\ The code on this site is identical to Angus Duggan's source discs (it's just
\ been reformatted, and the label names have been changed to be consistent with
\ the sources for the original BBC Micro disc version on which it is based)
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
\   * output/1.E.bin
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

LS% = &0CFF             \ The start of the descending ship line heap

NOST = 18               \ The number of stardust particles in normal space (this
                        \ goes down to 3 in witchspace)

NOSH = 12               \ The maximum number of ships in our local bubble of
                        \ universe

NTY = 31                \ The number of different ship types

MSL = 1                 \ Ship type for a missile
SST = 2                 \ Ship type for a Coriolis space station
ESC = 3                 \ Ship type for an escape pod
PLT = 4                 \ Ship type for an alloy plate
OIL = 5                 \ Ship type for a cargo canister
AST = 7                 \ Ship type for an asteroid
SPL = 8                 \ Ship type for a splinter
SHU = 9                 \ Ship type for a Shuttle
CYL = 11                \ Ship type for a Cobra Mk III
ANA = 14                \ Ship type for an Anaconda
COPS = 16               \ Ship type for a Viper
SH3 = 17                \ Ship type for a Sidewinder
KRA = 19                \ Ship type for a Krait
ADA = 20                \ Ship type for a Adder
WRM = 23                \ Ship type for a Worm
CYL2 = 24               \ Ship type for a Cobra Mk III (pirate)
ASP = 25                \ Ship type for an Asp Mk II
THG = 29                \ Ship type for a Thargoid
TGL = 30                \ Ship type for a Thargon
CON = 31                \ Ship type for a Constrictor

NI% = 37                \ The number of bytes in each ship's data block (as
                        \ stored in INWK and K%)

OSBYTE = &FFF4          \ The address for the OSBYTE routine
OSWORD = &FFF1          \ The address for the OSWORD routine
OSCLI = &FFF7           \ The address for the OSCLI routine

VIA = &FE00             \ Memory-mapped space for accessing internal hardware,
                        \ such as the video ULA, 6845 CRTC and 6522 VIAs (also
                        \ known as SHEILA)

X = 128                 \ The centre x-coordinate of the 256 x 192 space view
Y = 96                  \ The centre y-coordinate of the 256 x 192 space view

f0 = &20                \ Internal key number for red key f0 (Launch, Front)
f1 = &71                \ Internal key number for red key f1 (Buy Cargo, Rear)
f2 = &72                \ Internal key number for red key f2 (Sell Cargo, Left)
f3 = &73                \ Internal key number for red key f3 (Equip Ship, Right)
f4 = &14                \ Internal key number for red key f4 (Long-range Chart)
f5 = &74                \ Internal key number for red key f5 (Short-range Chart)
f6 = &75                \ Internal key number for red key f6 (Data on System)
f7 = &16                \ Internal key number for red key f7 (Market Price)
f8 = &76                \ Internal key number for red key f8 (Status Mode)
f9 = &77                \ Internal key number for red key f9 (Inventory)

NRU% = 25               \ The number of planetary systems with extended system
                        \ description overrides in the RUTOK table

VE = 0                  \ The obfuscation byte used to hide the extended tokens
                        \ table from crackers viewing the binary code, which is
                        \ zero in Elite-A as the token table is not obfuscated

LL = 30                 \ The length of lines (in characters) of justified text
                        \ in the extended tokens system

QQ18 = &0400            \ The address of the text token table, as set in
                        \ elite-loader.asm

SNE = &07C0             \ The address of the sine lookup table, as set in
                        \ elite-loader.asm

QQ16_FLIGHT = &0880     \ The address of the two-letter text token table in the
                        \ flight code (this gets populated by the docked code at
                        \ the start of the game)

IRQ1 = &114B            \ The address of the IRQ1 routine that implements the
                        \ split screen interrupt handler, as set in
                        \ elite-loader.asm

NA% = &1181             \ The address of the data block for the last saved
                        \ commander, as set in elite-loader.asm

CHK2 = &11D3            \ The address of the second checksum byte for the saved
                        \ commander data file, as set in elite-loader.asm

CHK = &11D4             \ The address of the first checksum byte for the saved
                        \ commander data file, as set in elite-loader.asm

XX21 = &5600            \ The address of the ship blueprints lookup table, where
                        \ the chosen ship blueprints file is loaded

E% = &563E              \ The address of the default NEWB ship bytes within the
                        \ loaded ship blueprints file

SHIP_MISSILE = &7F00    \ The address of the missile ship blueprint, as set in
                        \ elite-loader.asm

save_lock = &0233       \ AJD, shares location with IND2V+1

new_name = &074D        \ AJD

\ ******************************************************************************
\
\       Name: ZP
\       Type: Workspace
\    Address: &0000 to &00B0
\   Category: Workspaces
\    Summary: Lots of important variables are stored in the zero page workspace
\             as it is quicker and more space-efficient to access memory here
\
\ ******************************************************************************

ORG &0000

.ZP

 SKIP 0                 \ The start of the zero page workspace

.RAND

 SKIP 4                 \ Four 8-bit seeds for the random number generation
                        \ system implemented in the DORND routine

.TRTB%

 SKIP 2                 \ TRTB%(1 0) points to the keyboard translation table,
                        \ which is used to translate internal key numbers to
                        \ ASCII

.T1

 SKIP 1                 \ Temporary storage, used in a number of places

.SC

 SKIP 1                 \ Screen address (low byte)
                        \
                        \ Elite draws on-screen by poking bytes directly into
                        \ screen memory, and SC(1 0) is typically set to the
                        \ address of the character block containing the pixel
                        \ we want to draw (see the deep dives on "Drawing
                        \ monochrome pixels in mode 4" and "Drawing colour
                        \ pixels in mode 5" for more details)

.SCH

 SKIP 1                 \ Screen address (high byte)

.XX16

 SKIP 18                \ Temporary storage for a block of values, used in a
                        \ number of places

.P

 SKIP 3                 \ Temporary storage, used in a number of places

.XX0

 SKIP 2                 \ Temporary storage, used to store the address of a ship
                        \ blueprint. For example, it is used when we add a new
                        \ ship to the local bubble in routine NWSHP, and it
                        \ contains the address of the current ship's blueprint
                        \ as we loop through all the nearby ships in the main
                        \ flight loop

.INF

 SKIP 2                 \ Temporary storage, typically used for storing the
                        \ address of a ship's data block, so it can be copied
                        \ to and from the internal workspace at INWK

.V

 SKIP 2                 \ Temporary storage, typically used for storing an
                        \ address pointer

.XX

 SKIP 2                 \ Temporary storage, typically used for storing a 16-bit
                        \ x-coordinate

.YY

 SKIP 2                 \ Temporary storage, typically used for storing a 16-bit
                        \ y-coordinate

.SUNX

 SKIP 2                 \ The 16-bit x-coordinate of the vertical centre axis
                        \ of the sun (which might be off-screen)

.BETA

 SKIP 1                 \ The current pitch angle beta, which is reduced from
                        \ JSTY to a sign-magnitude value between -8 and +8
                        \
                        \ This describes how fast we are pitching our ship, and
                        \ determines how fast the universe pitches around us
                        \
                        \ The sign bit is also stored in BET2, while the
                        \ opposite sign is stored in BET2+1

.BET1

 SKIP 1                 \ The magnitude of the pitch angle beta, i.e. |beta|,
                        \ which is a positive value between 0 and 8

.XC

 SKIP 1                 \ The x-coordinate of the text cursor (i.e. the text
                        \ column), which can be from 0 to 32
                        \
                        \ A value of 0 denotes the leftmost column and 32 the
                        \ rightmost column, but because the top part of the
                        \ screen (the space view) has a white border that
                        \ clashes with columns 0 and 32, text is only shown
                        \ in columns 1-31

.YC

 SKIP 1                 \ The y-coordinate of the text cursor (i.e. the text
                        \ row), which can be from 0 to 23
                        \
                        \ The screen actually has 31 character rows if you
                        \ include the dashboard, but the text printing routines
                        \ only work on the top part (the space view), so the
                        \ text cursor only goes up to a maximum of 23, the row
                        \ just before the screen splits
                        \
                        \ A value of 0 denotes the top row, but because the
                        \ top part of the screen has a white border that clashes
                        \ with row 0, text is always shown at row 1 or greater

.QQ22

 SKIP 2                 \ The two hyperspace countdown counters
                        \
                        \ Before a hyperspace jump, both QQ22 and QQ22+1 are
                        \ set to 15
                        \
                        \ QQ22 is an internal counter that counts down by 1
                        \ each time TT102 is called, which happens every
                        \ iteration of the main game loop. When it reaches
                        \ zero, the on-screen counter in QQ22+1 gets
                        \ decremented, and QQ22 gets set to 5 and the countdown
                        \ continues (so the first tick of the hyperspace counter
                        \ takes 15 iterations to happen, but subsequent ticks
                        \ take 5 iterations each)
                        \
                        \ QQ22+1 contains the number that's shown on-screen
                        \ during the countdown. It counts down from 15 to 1, and
                        \ when it hits 0, the hyperspace engines kick in

.ECMA

 SKIP 1                 \ The E.C.M. countdown timer, which determines whether
                        \ an E.C.M. system is currently operating:
                        \
                        \   * 0 = E.C.M. is off
                        \
                        \   * Non-zero = E.C.M. is on and is counting down
                        \
                        \ The counter starts at 32 when an E.C.M. is activated,
                        \ either by us or by an opponent, and it decreases by 1
                        \ in each iteration of the main flight loop until it
                        \ reaches zero, at which point the E.C.M. switches off.
                        \ Only one E.C.M. can be active at any one time, so
                        \ there is only one counter

.ALP1

 SKIP 1                 \ Magnitude of the roll angle alpha, i.e. |alpha|,
                        \ which is a positive value between 0 and 31

.ALP2

 SKIP 2                 \ Bit 7 of ALP2 = sign of the roll angle in ALPHA
                        \
                        \ Bit 7 of ALP2+1 = opposite sign to ALP2 and ALPHA

.XX15

 SKIP 0                 \ Temporary storage, typically used for storing screen
                        \ coordinates in line-drawing routines
                        \
                        \ There are six bytes of storage, from XX15 TO XX15+5.
                        \ The first four bytes have the following aliases:
                        \
                        \   X1 = XX15
                        \   Y1 = XX15+1
                        \   X2 = XX15+2
                        \   Y2 = XX15+3
                        \
                        \ These are typically used for describing lines in terms
                        \ of screen coordinates, i.e. (X1, Y1) to (X2, Y2)
                        \
                        \ The last two bytes of XX15 do not have aliases

.X1

 SKIP 1                 \ Temporary storage, typically used for x-coordinates in
                        \ line-drawing routines

.Y1

 SKIP 1                 \ Temporary storage, typically used for y-coordinates in
                        \ line-drawing routines

.X2

 SKIP 1                 \ Temporary storage, typically used for x-coordinates in
                        \ line-drawing routines

.Y2

 SKIP 1                 \ Temporary storage, typically used for y-coordinates in
                        \ line-drawing routines

 SKIP 2                 \ The last two bytes of the XX15 block

.XX12

 SKIP 6                 \ Temporary storage for a block of values, used in a
                        \ number of places

.K

 SKIP 4                 \ Temporary storage, used in a number of places

.LAS

 SKIP 1                 \ Contains the laser power of the laser fitted to the
                        \ current space view (or 0 if there is no laser fitted
                        \ to the current view)
                        \
                        \ This gets set to bits 0-6 of the laser power byte from
                        \ the commander data block, which contains the laser's
                        \ power (bit 7 doesn't denote laser power, just whether
                        \ or not the laser pulses, so that is not stored here)

.MSTG

 SKIP 1                 \ The current missile lock target
                        \
                        \   * &FF = no target
                        \
                        \   * 1-13 = the slot number of the ship that our
                        \            missile is locked onto

.XX1

 SKIP 0                 \ This is an alias for INWK that is used in the main
                        \ ship-drawing routine at LL9

.INWK

 SKIP 33                \ The zero-page internal workspace for the current ship
                        \ data block
                        \
                        \ As operations on zero page locations are faster and
                        \ have smaller opcodes than operations on the rest of
                        \ the addressable memory, Elite tends to store oft-used
                        \ data here. A lot of the routines in Elite need to
                        \ access and manipulate ship data, so to make this an
                        \ efficient exercise, the ship data is first copied from
                        \ the ship data blocks at K% into INWK (or, when new
                        \ ships are spawned, from the blueprints at XX21). See
                        \ the deep dive on "Ship data blocks" for details of
                        \ what each of the bytes in the INWK data block
                        \ represents

.XX19

 SKIP NI% - 34          \ XX19(1 0) shares its location with INWK(34 33), which
                        \ contains the address of the ship line heap

.NEWB

 SKIP 1                 \ The ship's "new byte flags" (or NEWB flags)
                        \
                        \ Contains details about the ship's type and associated
                        \ behaviour, such as whether they are a trader, a bounty
                        \ hunter, a pirate, currently hostile, in the process of
                        \ docking, inside the hold having been scooped, and so
                        \ on. The default values for each ship type are taken
                        \ from the table at E%, and you can find out more detail
                        \ in the deep dive on "Advanced tactics with the NEWB
                        \ flags"

.LSP

 SKIP 1                 \ The ball line heap pointer, which contains the number
                        \ of the first free byte after the end of the LSX2 and
                        \ LSY2 heaps (see the deep dive on "The ball line heap"
                        \ for details)

.QQ15

 SKIP 6                 \ The three 16-bit seeds for the selected system, i.e.
                        \ the one in the crosshairs in the Short-range Chart
                        \
                        \ See the deep dives on "Galaxy and system seeds" and
                        \ "Twisting the system seeds" for more details

.K5

 SKIP 0                 \ Temporary storage used to store segment coordinates
                        \ across successive calls to BLINE, the ball line
                        \ routine

.XX18

 SKIP 0                 \ Temporary storage used to store coordinates in the
                        \ LL9 ship-drawing routine

.QQ17

 SKIP 1                 \ Contains a number of flags that affect how text tokens
                        \ are printed, particularly capitalisation:
                        \
                        \   * If all bits are set (255) then text printing is
                        \     disabled
                        \
                        \   * Bit 7: 0 = ALL CAPS
                        \            1 = Sentence Case, bit 6 determines the
                        \                case of the next letter to print
                        \
                        \   * Bit 6: 0 = print the next letter in upper case
                        \            1 = print the next letter in lower case
                        \
                        \   * Bits 0-5: If any of bits 0-5 are set, print in
                        \               lower case
                        \
                        \ So:
                        \
                        \   * QQ17 = 0 means case is set to ALL CAPS
                        \
                        \   * QQ17 = %10000000 means Sentence Case, currently
                        \            printing upper case
                        \
                        \   * QQ17 = %11000000 means Sentence Case, currently
                        \            printing lower case
                        \
                        \   * QQ17 = %11111111 means printing is disabled

.QQ19

 SKIP 3                 \ Temporary storage, used in a number of places

.K6

 SKIP 5                 \ Temporary storage, typically used for storing
                        \ coordinates during vector calculations

.BET2

 SKIP 2                 \ Bit 7 of BET2 = sign of the pitch angle in BETA
                        \
                        \ Bit 7 of BET2+1 = opposite sign to BET2 and BETA

.DELTA

 SKIP 1                 \ Our current speed, in the range 1-40

.DELT4

 SKIP 2                 \ Our current speed * 64 as a 16-bit value
                        \
                        \ This is stored as DELT4(1 0), so the high byte in
                        \ DELT4+1 therefore contains our current speed / 4

.U

 SKIP 1                 \ Temporary storage, used in a number of places

.Q

 SKIP 1                 \ Temporary storage, used in a number of places

.R

 SKIP 1                 \ Temporary storage, used in a number of places

.S

 SKIP 1                 \ Temporary storage, used in a number of places

.XSAV

 SKIP 1                 \ Temporary storage for saving the value of the X
                        \ register, used in a number of places

.YSAV

 SKIP 1                 \ Temporary storage for saving the value of the Y
                        \ register, used in a number of places

.XX17

 SKIP 1                 \ Temporary storage, used in BPRNT to store the number
                        \ of characters to print, and as the edge counter in the
                        \ main ship-drawing routine

.QQ11

 SKIP 1                 \ The number of the current view:
                        \
                        \   0   = Space view
                        \   1   = Title screen
                        \         Get commander name ("@", save/load commander)
                        \         In-system jump just arrived ("J")
                        \         Data on System screen (red key f6)
                        \         Buy Cargo screen (red key f1)
                        \         Mis-jump just arrived (witchspace)
                        \   4   = Sell Cargo screen (red key f2)
                        \   6   = Death screen
                        \   8   = Status Mode screen (red key f8)
                        \         Inventory screen (red key f9)
                        \   16  = Market Price screen (red key f7)
                        \   32  = Equip Ship screen (red key f3)
                        \   64  = Long-range Chart (red key f4)
                        \   128 = Short-range Chart (red key f5)
                        \   255 = Launch view
                        \
                        \ This value is typically set by calling routine TT66

.ZZ

 SKIP 1                 \ Temporary storage, typically used for distance values

.XX13

 SKIP 1                 \ Temporary storage, typically used in the line-drawing
                        \ routines

.MCNT

 SKIP 1                 \ The main loop counter
                        \
                        \ This counter determines how often certain actions are
                        \ performed within the main loop. See the deep dive on
                        \ "Scheduling tasks with the main loop counter" for more
                        \ details

.DL

 SKIP 1                 \ Vertical sync flag
                        \
                        \ DL gets set to 30 every time we reach vertical sync on
                        \ the video system, which happens 50 times a second
                        \ (50Hz). The WSCAN routine uses this to pause until the
                        \ vertical sync, by setting DL to 0 and then monitoring
                        \ its value until it changes to 30

.TYPE

 SKIP 1                 \ The current ship type
                        \
                        \ This is where we store the current ship type for when
                        \ we are iterating through the ships in the local bubble
                        \ as part of the main flight loop. See the table at XX21
                        \ for information about ship types

.ALPHA

 SKIP 1                 \ The current roll angle alpha, which is reduced from
                        \ JSTX to a sign-magnitude value between -31 and +31
                        \
                        \ This describes how fast we are rolling our ship, and
                        \ determines how fast the universe rolls around us
                        \
                        \ The sign bit is also stored in ALP2, while the
                        \ opposite sign is stored in ALP2+1

.QQ12

 SKIP 1                 \ Our "docked" status
                        \
                        \   * 0 = we are not docked
                        \
                        \   * &FF = we are docked

.TGT

 SKIP 1                 \ Temporary storage, typically used as a target value
                        \ for counters when drawing explosion clouds and partial
                        \ circles

.SWAP

 SKIP 1                 \ Temporary storage, used to store a flag that records
                        \ whether or not we had to swap a line's start and end
                        \ coordinates around when clipping the line in routine
                        \ LL145 (the flag is used in places like BLINE to swap
                        \ them back)

.COL

 SKIP 1                 \ Temporary storage, used to store colour information
                        \ when drawing pixels in the dashboard

.FLAG

 SKIP 1                 \ A flag that's used to define whether this is the first
                        \ call to the ball line routine in BLINE, so it knows
                        \ whether to wait for the second call before storing
                        \ segment data in the ball line heap

.CNT

 SKIP 1                 \ Temporary storage, typically used for storing the
                        \ number of iterations required when looping

.CNT2

 SKIP 1                 \ Temporary storage, used in the planet-drawing routine
                        \ to store the segment number where the arc of a partial
                        \ circle should start

.STP

 SKIP 1                 \ The step size for drawing circles
                        \
                        \ Circles in Elite are split up into 64 points, and the
                        \ step size determines how many points to skip with each
                        \ straight-line segment, so the smaller the step size,
                        \ the smoother the circle. The values used are:
                        \
                        \   * 2 for big planets and the circles on the charts
                        \   * 4 for medium planets and the launch tunnel
                        \   * 8 for small planets and the hyperspace tunnel
                        \
                        \ As the step size increases we move from smoother
                        \ circles at the top to more polygonal at the bottom.
                        \ See the CIRCLE2 routine for more details

.XX4

 SKIP 1                 \ Temporary storage, used in a number of places

.XX20

 SKIP 1                 \ Temporary storage, used in a number of places

.XX14

 SKIP 1                 \ This byte appears to be unused

.RAT

 SKIP 1                 \ Used to store different signs depending on the current
                        \ space view, for use in calculating stardust movement

.RAT2

 SKIP 1                 \ Temporary storage, used to store the pitch and roll
                        \ signs when moving objects and stardust

.K2

 SKIP 4                 \ Temporary storage, used in a number of places

                        \ --- Code added for Elite-A: ------------------------->

.finder

 SKIP 1                 \ AJD

                        \ --- End of added code ------------------------------->

ORG &00D1

.T

 SKIP 1                 \ Temporary storage, used in a number of places

.K3

 SKIP 0                 \ Temporary storage, used in a number of places

.XX2

 SKIP 14                \ Temporary storage, used to store the visibility of the
                        \ ship's faces during the ship-drawing routine at LL9

.K4

 SKIP 2                 \ Temporary storage, used in a number of places

PRINT "Zero page variables from ", ~ZP, " to ", ~P%

\ ******************************************************************************
\
\       Name: XX3
\       Type: Workspace
\    Address: &0100 to the top of the descending stack
\   Category: Workspaces
\    Summary: Temporary storage space for complex calculations
\
\ ------------------------------------------------------------------------------
\
\ Used as heap space for storing temporary data during calculations. Shared with
\ the descending 6502 stack, which works down from &01FF.
\
\ ******************************************************************************

ORG &0100

.XX3

 SKIP 0                 \ Temporary storage, typically used for storing tables
                        \ of values such as screen coordinates or ship data

\ ******************************************************************************
\
\       Name: UP
\       Type: Workspace
\    Address: &0300 to &03CF
\   Category: Workspaces
\    Summary: Ship slots, variables
\
\ ******************************************************************************

ORG &0300

.KL

 SKIP 1                 \ The following bytes implement a key logger that
                        \ enables Elite to scan for concurrent key presses of
                        \ the primary flight keys, plus a secondary flight key
                        \
                        \ See the deep dive on "The key logger" for more details
                        \
                        \ If a key is being pressed that is not in the keyboard
                        \ table at KYTB, it can be stored here (as seen in
                        \ routine DK4, for example)

.KY1

 SKIP 1                 \ "?" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY2

 SKIP 1                 \ Space is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY3

 SKIP 1                 \ "<" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY4

 SKIP 1                 \ ">" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY5

 SKIP 1                 \ "X" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY6

 SKIP 1                 \ "S" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY7

 SKIP 1                 \ "A" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes
                        \
                        \ This is also set when the joystick fire button has
                        \ been pressed

.KY12

 SKIP 1                 \ TAB is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY13

 SKIP 1                 \ ESCAPE is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY14

 SKIP 1                 \ "T" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY15

 SKIP 1                 \ "U" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY16

 SKIP 1                 \ "M" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY17

 SKIP 1                 \ "E" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY18

 SKIP 1                 \ "J" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY19

 SKIP 1                 \ "C" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.KY20

 SKIP 1                 \ "P" is being pressed
                        \
                        \   * 0 = no
                        \
                        \   * Non-zero = yes

.FRIN

 SKIP NOSH + 1          \ Slots for the ships in the local bubble of universe
                        \
                        \ There are #NOSH + 1 slots, but the ship-spawning
                        \ routine at NWSHP only populates #NOSH of them, so
                        \ there are 13 slots but only 12 are used for ships
                        \ (the last slot is effectively used as a null
                        \ terminator when shuffling the slots down in the
                        \ KILLSHP routine)
                        \
                        \ See the deep dive on "The local bubble of universe"
                        \ for details of how Elite stores the local universe in
                        \ FRIN, UNIV and K%

.MANY

 SKIP SST               \ The number of ships of each type in the local bubble
                        \ of universe
                        \
                        \ The number of ships of type X in the local bubble is
                        \ stored at MANY+X, so the number of Sidewinders is at
                        \ MANY+1, the number of Mambas is at MANY+2, and so on
                        \
                        \ See the deep dive on "Ship blueprints" for a list of
                        \ ship types

.SSPR

 SKIP NTY + 1 - SST     \ "Space station present" flag
                        \
                        \   * Non-zero if we are inside the space station's safe
                        \     zone
                        \
                        \   * 0 if we aren't (in which case we can show the sun)
                        \
                        \ This flag is at MANY+SST, which is no coincidence, as
                        \ MANY+SST is a count of how many space stations there
                        \ are in our local bubble, which is the same as saying
                        \ "space station present"

.JUNK

 SKIP 1                 \ The amount of junk in the local bubble
                        \
                        \ "Junk" is defined as being one of these:
                        \
                        \   * Escape pod
                        \   * Alloy plate
                        \   * Cargo canister
                        \   * Asteroid
                        \   * Splinter
                        \   * Shuttle
                        \   * Transporter
                        \
                        \ Junk is the range of ship types from #JL to #JH - 1

.auto

 SKIP 1                 \ Docking computer activation status
                        \
                        \   * 0 = Docking computer is off
                        \
                        \   * Non-zero = Docking computer is running

.ECMP

 SKIP 1                 \ Our E.C.M. status
                        \
                        \   * 0 = E.C.M. is off
                        \
                        \   * Non-zero = E.C.M. is on

.MJ

 SKIP 1                 \ Are we in witchspace (i.e. have we mis-jumped)?
                        \
                        \   * 0 = no, we are in normal space
                        \
                        \   * &FF = yes, we are in witchspace

.CABTMP

 SKIP 1                 \ Cabin temperature
                        \
                        \ The ambient cabin temperature in deep space is 30,
                        \ which is displayed as one notch on the dashboard bar
                        \
                        \ We get higher temperatures closer to the sun
                        \
                        \ CABTMP shares a location with MANY, but that's OK as
                        \ MANY+0 would contain the number of ships of type 0,
                        \ and as there is no ship type 0 (they start at 1), the
                        \ byte at MANY+0 is not used for storing a ship type
                        \ and can be used for the cabin temperature instead

.LAS2

 SKIP 1                 \ Laser power for the current laser
                        \
                        \   * Bits 0-6 contain the laser power of the current
                        \     space view
                        \
                        \   * Bit 7 denotes whether or not the laser pulses:
                        \
                        \     * 0 = pulsing laser
                        \
                        \     * 1 = beam laser (i.e. always on)

.MSAR

 SKIP 1                 \ The targeting state of our leftmost missile
                        \
                        \   * 0 = missile is not looking for a target, or it
                        \     already has a target lock (indicator is not
                        \     yellow/white)
                        \
                        \   * Non-zero = missile is currently looking for a
                        \     target (indicator is yellow/white)

.VIEW

 SKIP 1                 \ The number of the current space view
                        \
                        \   * 0 = front
                        \   * 1 = rear
                        \   * 2 = left
                        \   * 3 = right

.LASCT

 SKIP 1                 \ The laser pulse count for the current laser
                        \
                        \ This is a counter that defines the gap between the
                        \ pulses of a pulse laser. It is set as follows:
                        \
                        \   * 0 for a beam laser
                        \
                        \   * 10 for a pulse laser
                        \
                        \ It gets decremented every vertical sync (in the LINSCN
                        \ routine, which is called 50 times a second) and is set
                        \ to a non-zero value for pulse lasers only
                        \
                        \ The laser only fires when the value of LASCT hits
                        \ zero, so for pulse lasers with a value of 10, that
                        \ means the laser fires once every 10 vertical syncs (or
                        \ 5 times a second)
                        \
                        \ In comparison, beam lasers fire continuously as the
                        \ value of LASCT is always 0

.GNTMP

 SKIP 1                 \ Laser temperature (or "gun temperature")
                        \
                        \ If the laser temperature exceeds 242 then the laser
                        \ overheats and cannot be fired again until it has
                        \ cooled down

.HFX

 SKIP 1                 \ A flag that toggles the hyperspace colour effect
                        \
                        \   * 0 = no colour effect
                        \
                        \   * Non-zero = hyperspace colour effect enabled
                        \
                        \ When HFX is set to 1, the mode 4 screen that makes
                        \ up the top part of the display is temporarily switched
                        \ to mode 5 (the same screen mode as the dashboard),
                        \ which has the effect of blurring and colouring the
                        \ hyperspace rings in the top part of the screen. The
                        \ code to do this is in the LINSCN routine, which is
                        \ called as part of the screen mode routine at IRQ1.
                        \ It's in LINSCN that HFX is checked, and if it is
                        \ non-zero, the top part of the screen is not switched
                        \ to mode 4, thus leaving the top part of the screen in
                        \ the more colourful mode 5

.EV

 SKIP 1                 \ The "extra vessels" spawning counter
                        \
                        \ This counter is set to 0 on arrival in a system and
                        \ following an in-system jump, and is bumped up when we
                        \ spawn bounty hunters or pirates (i.e. "extra vessels")
                        \
                        \ It decreases by 1 each time we consider spawning more
                        \ "extra vessels" in part 4 of the main game loop, so
                        \ increasing the value of EV has the effect of delaying
                        \ the spawning of more vessels
                        \
                        \ In other words, this counter stops bounty hunters and
                        \ pirates from continually appearing, and ensures that
                        \ there's a delay between spawnings

.DLY

 SKIP 1                 \ In-flight message delay
                        \
                        \ This counter is used to keep an in-flight message up
                        \ for a specified time before it gets removed. The value
                        \ in DLY is decremented each time we start another
                        \ iteration of the main game loop at TT100

.de

 SKIP 1                 \ Equipment destruction flag
                        \
                        \   * Bit 1 denotes whether or not the in-flight message
                        \     about to be shown by the MESS routine is about
                        \     destroyed equipment:
                        \
                        \     * 0 = the message is shown normally
                        \
                        \     * 1 = the string " DESTROYED" gets added to the
                        \       end of the message

.JSTX

 SKIP 1                 \ Our current roll rate
                        \
                        \ This value is shown in the dashboard's RL indicator,
                        \ and determines the rate at which we are rolling
                        \
                        \ The value ranges from from 1 to 255 with 128 as the
                        \ centre point, so 1 means roll is decreasing at the
                        \ maximum rate, 128 means roll is not changing, and
                        \ 255 means roll is increasing at the maximum rate
                        \
                        \ This value is updated by "<" and ">" key presses, or
                        \ if joysticks are enabled, from the joystick. If
                        \ keyboard damping is enabled (which it is by default),
                        \ the value is slowly moved towards the centre value of
                        \ 128 (no roll) if there are no key presses or joystick
                        \ movement

.JSTY

 SKIP 1                 \ Our current pitch rate
                        \
                        \ This value is shown in the dashboard's DC indicator,
                        \ and determines the rate at which we are pitching
                        \
                        \ The value ranges from from 1 to 255 with 128 as the
                        \ centre point, so 1 means pitch is decreasing at the
                        \ maximum rate, 128 means pitch is not changing, and
                        \ 255 means pitch is increasing at the maximum rate
                        \
                        \ This value is updated by "S" and "X" key presses, or
                        \ if joysticks are enabled, from the joystick. If
                        \ keyboard damping is enabled (which it is by default),
                        \ the value is slowly moved towards the centre value of
                        \ 128 (no pitch) if there are no key presses or joystick
                        \ movement
.XSAV2

 SKIP 1                 \ Temporary storage, used for storing the value of the X
                        \ register in the TT26 routine

.YSAV2

 SKIP 1                 \ Temporary storage, used for storing the value of the Y
                        \ register in the TT26 routine

.NAME

 SKIP 8                 \ The current commander name
                        \
                        \ The commander name can be up to 7 characters (the DFS
                        \ limit for file names), and is terminated by a carriage
                        \ return

.TP

 SKIP 1                 \ The current mission status
                        \
                        \   * Bits 0-1 = Mission 1 status
                        \
                        \     * %00 = Mission not started
                        \     * %01 = Mission in progress, hunting for ship
                        \     * %11 = Constrictor killed, not debriefed yet
                        \     * %10 = Mission and debrief complete
                        \
                        \   * Bits 2-3 = Mission 2 status
                        \
                        \     * %00 = Mission not started
                        \     * %01 = Mission in progress, plans not picked up
                        \     * %10 = Mission in progress, plans picked up
                        \     * %11 = Mission complete

.QQ0

 SKIP 1                 \ The current system's galactic x-coordinate (0-256)

.QQ1

 SKIP 1                 \ The current system's galactic y-coordinate (0-256)

.QQ21

 SKIP 6                 \ The three 16-bit seeds for the current galaxy
                        \
                        \ These seeds define system 0 in the current galaxy, so
                        \ they can be used as a starting point to generate all
                        \ 256 systems in the galaxy
                        \
                        \ Using a galactic hyperdrive rotates each byte to the
                        \ left (rolling each byte within itself) to get the
                        \ seeds for the next galaxy, so after eight galactic
                        \ jumps, the seeds roll around to the first galaxy again
                        \
                        \ See the deep dives on "Galaxy and system seeds" and
                        \ "Twisting the system seeds" for more details
.CASH

 SKIP 4                 \ Our current cash pot
                        \
                        \ The cash stash is stored as a 32-bit unsigned integer,
                        \ with the most significant byte in CASH and the least
                        \ significant in CASH+3. This is big-endian, which is
                        \ the opposite way round to most of the numbers used in
                        \ Elite - to use our notation for multi-byte numbers,
                        \ the amount of cash is CASH(0 1 2 3)

.QQ14

 SKIP 1                 \ Our current fuel level (0-70)
                        \
                        \ The fuel level is stored as the number of light years
                        \ multiplied by 10, so QQ14 = 1 represents 0.1 light
                        \ years, and the maximum possible value is 70, for 7.0
                        \ light years

.COK

 SKIP 1                 \ Flags used to generate the competition code
                        \
                        \ See the deep dive on "The competition code" for
                        \ details of these flags and how they are used in
                        \ generating and decoding the competition code

.GCNT

 SKIP 1                 \ The number of the current galaxy (0-7)
                        \
                        \ When this is displayed in-game, 1 is added to the
                        \ number, so we start in galaxy 1 in-game, but it's
                        \ stored as galaxy 0 internally
                        \
                        \ The galaxy number increases by one every time a
                        \ galactic hyperdrive is used, and wraps back round to
                        \ the start after eight galaxies

.LASER

 SKIP 4                 \ The specifications of the lasers fitted to each of the
                        \ four space views:
                        \
                        \   * Byte #0 = front view (red key f0)
                        \   * Byte #1 = rear view (red key f1)
                        \   * Byte #2 = left view (red key f2)
                        \   * Byte #3 = right view (red key f3)
                        \
                        \ For each of the views:
                        \
                        \   * 0 = no laser is fitted to this view
                        \
                        \   * Non-zero = a laser is fitted to this view, with
                        \     the following specification:
                        \
                        \     * Bits 0-6 contain the laser's power
                        \
                        \     * Bit 7 determines whether or not the laser pulses
                        \       (0 = pulse or mining laser) or is always on
                        \       (1 = beam or military laser)

                        \ --- Original Acornsoft code removed: ---------------->

\ SKIP 2                \ These bytes appear to be unused (they were originally
\                       \ used for up/down lasers, but they were dropped)

                        \ --- And replaced by: -------------------------------->

 SKIP 1                 \ This byte appears to be unused

.new_type
.cmdr_ship

 SKIP 1                 \ AJD

                        \ --- End of replacement ------------------------------>

.CRGO

 SKIP 1                 \ Our ship's cargo capacity
                        \
                        \   * 22 = standard cargo bay of 20 tonnes
                        \
                        \   * 37 = large cargo bay of 35 tonnes
                        \
                        \ The value is two greater than the actual capacity to
                        \ male the maths in tnpr slightly more efficient

.QQ20

 SKIP 17                \ The contents of our cargo hold
                        \
                        \ The amount of market item X that we have in our hold
                        \ can be found in the X-th byte of QQ20. For example:
                        \
                        \   * QQ20 contains the amount of food (item 0)
                        \
                        \   * QQ20+7 contains the amount of computers (item 7)
                        \
                        \ See QQ23 for a list of market item numbers and their
                        \ storage units

.ECM

 SKIP 1                 \ E.C.M. system
                        \
                        \   * 0 = not fitted
                        \
                        \   * &FF = fitted

.BST

 SKIP 1                 \ Fuel scoops (BST stands for "barrel status")
                        \
                        \   * 0 = not fitted
                        \
                        \   * &FF = fitted

.BOMB

 SKIP 1                 \ Energy bomb
                        \
                        \   * 0 = not fitted
                        \
                        \   * &7F = fitted

.ENGY

 SKIP 1                 \ Energy unit
                        \
                        \   * 0 = not fitted
                        \
                        \   * 1 = fitted

.DKCMP

 SKIP 1                 \ Docking computer
                        \
                        \   * 0 = not fitted
                        \
                        \   * &FF = fitted

.GHYP

 SKIP 1                 \ Galactic hyperdrive
                        \
                        \   * 0 = not fitted
                        \
                        \   * &FF = fitted

.ESCP

 SKIP 1                 \ Escape pod
                        \
                        \   * 0 = not fitted
                        \
                        \   * &FF = fitted

                        \ --- Original Acornsoft code removed: ---------------->

\ SKIP 4                \ These bytes appear to be unused

                        \ --- And replaced by: -------------------------------->

.cmdr_cour

 SKIP 2                 \ AJD

.cmdr_courx

 SKIP 1                 \ AJD

.cmdr_coury

 SKIP 1                 \ AJD

                        \ --- End of replacement ------------------------------>

.NOMSL

 SKIP 1                 \ The number of missiles we have fitted (0-4)

.FIST

 SKIP 1                 \ Our legal status (FIST stands for "fugitive/innocent
                        \ status"):
                        \
                        \   * 0 = Clean
                        \
                        \   * 1-49 = Offender
                        \
                        \   * 50+ = Fugitive
                        \
                        \ You get 64 points if you kill a cop, so that's a fast
                        \ ticket to fugitive status

.AVL

 SKIP 17                \ Market availability in the current system
                        \
                        \ The available amount of market item X is stored in
                        \ the X-th byte of AVL, so for example:
                        \
                        \   * AVL contains the amount of food (item 0)
                        \
                        \   * AVL+7 contains the amount of computers (item 7)
                        \
                        \ See QQ23 for a list of market item numbers and their
                        \ storage units, and the deep dive on "Market item
                        \ prices and availability" for details of the algorithm
                        \ used for calculating each item's availability

.QQ26

 SKIP 1                 \ A random value used to randomise market data
                        \
                        \ This value is set to a new random number for each
                        \ change of system, so we can add a random factor into
                        \ the calculations for market prices (for details of how
                        \ this is used, see the deep dive on "Market prices")

.TALLY

 SKIP 2                 \ Our combat rank
                        \
                        \ The combat rank is stored as the number of kills, in a
                        \ 16-bit number TALLY(1 0) - so the high byte is in
                        \ TALLY+1 and the low byte in TALLY
                        \
                        \ If the high byte in TALLY+1 is 0 then we have between
                        \ 0 and 255 kills, so our rank is Harmless, Mostly
                        \ Harmless, Poor, Average or Above Average, according to
                        \ the value of the low byte in TALLY:
                        \
                        \   Harmless        = %00000000 to %00000011 = 0 to 3
                        \   Mostly Harmless = %00000100 to %00000111 = 4 to 7
                        \   Poor            = %00001000 to %00001111 = 8 to 15
                        \   Average         = %00010000 to %00011111 = 16 to 31
                        \   Above Average   = %00100000 to %11111111 = 32 to 255
                        \
                        \ If the high byte in TALLY+1 is non-zero then we are
                        \ Competent, Dangerous, Deadly or Elite, according to
                        \ the high byte in TALLY+1:
                        \
                        \   Competent       = 1           = 256 to 511 kills
                        \   Dangerous       = 2 to 9      = 512 to 2559 kills
                        \   Deadly          = 10 to 24    = 2560 to 6399 kills
                        \   Elite           = 25 and up   = 6400 kills and up
                        \
                        \ You can see the rating calculation in STATUS

.SVC

 SKIP 1                 \ The save count
                        \
                        \ When a new commander is created, the save count gets
                        \ set to 128. This value gets halved each time the
                        \ commander file is saved, but it is otherwise unused.
                        \ It is presumably part of the security system for the
                        \ competition, possibly another flag to catch out
                        \ entries with manually altered commander files

 SKIP 2                 \ The commander file checksum
                        \
                        \ These two bytes are reserved for the commander file
                        \ checksum, so when the current commander block is
                        \ copied from here to the last saved commander block at
                        \ NA%, CHK and CHK2 get overwritten

NT% = SVC + 2 - TP      \ This sets the variable NT% to the size of the current
                        \ commander data block, which starts at TP and ends at
                        \ SVC+2 (inclusive)

.MCH

 SKIP 1                 \ The text token number of the in-flight message that is
                        \ currently being shown, and which will be removed by
                        \ the me2 routine when the counter in DLY reaches zero

.FSH

 SKIP 1                 \ Forward shield status
                        \
                        \   * 0 = empty
                        \
                        \   * &FF = full

.ASH

 SKIP 1                 \ Aft shield status
                        \
                        \   * 0 = empty
                        \
                        \   * &FF = full

.ENERGY

 SKIP 1                 \ Energy bank status
                        \
                        \   * 0 = empty
                        \
                        \   * &FF = full

.COMX

 SKIP 1                 \ The x-coordinate of the compass dot

.COMY

 SKIP 1                 \ The y-coordinate of the compass dot

.QQ24

 SKIP 1                 \ Temporary storage, used to store the current market
                        \ item's price in routine TT151

.QQ25

 SKIP 1                 \ Temporary storage, used to store the current market
                        \ item's availability in routine TT151

.QQ28

 SKIP 1                 \ Temporary storage, used to store the economy byte of
                        \ the current system in routine var

.QQ29

 SKIP 1                 \ Temporary storage, used in a number of places

.gov

 SKIP 1                 \ The current system's government type (0-7)
                        \
                        \ See the deep dive on "Generating system data" for
                        \ details of the various government types

.tek

 SKIP 1                 \ The current system's tech level (0-14)
                        \
                        \ See the deep dive on "Generating system data" for more
                        \ information on tech levels

.SLSP

 SKIP 2                 \ The address of the bottom of the ship line heap
                        \
                        \ The ship line heap is a descending block of memory
                        \ that starts at WP and descends down to SLSP. It can be
                        \ extended downwards by the NWSHP routine when adding
                        \ new ships (and their associated ship line heaps), in
                        \ which case SLSP is lowered to provide more heap space,
                        \ assuming there is enough free memory to do so

.QQ2

 SKIP 6                 \ The three 16-bit seeds for the current system, i.e.
                        \ the one we are currently in
                        \
                        \ See the deep dives on "Galaxy and system seeds" and
                        \ "Twisting the system seeds" for more details

.QQ3

 SKIP 1                 \ The selected system's economy (0-7)
                        \
                        \ See the deep dive on "Generating system data" for more
                        \ information on economies

.QQ4

 SKIP 1                 \ The selected system's government (0-7)
                        \
                        \ See the deep dive on "Generating system data" for more
                        \ details of the various government types

.QQ5

 SKIP 1                 \ The selected system's tech level (0-14)
                        \
                        \ See the deep dive on "Generating system data" for more
                        \ information on tech levels

.QQ6

 SKIP 2                 \ The selected system's population in billions * 10
                        \ (1-71), so the maximum population is 7.1 billion
                        \
                        \ See the deep dive on "Generating system data" for more
                        \ details on population levels

.QQ7

 SKIP 2                 \ The selected system's productivity in M CR (96-62480)
                        \
                        \ See the deep dive on "Generating system data" for more
                        \ details about productivity levels

.QQ8

 SKIP 2                 \ The distance from the current system to the selected
                        \ system in light years * 10, stored as a 16-bit number
                        \
                        \ The distance will be 0 if the selected sysyem is the
                        \ current system
                        \
                        \ The galaxy chart is 102.4 light years wide and 51.2
                        \ light years tall (see the intra-system distance
                        \ calculations in routine TT111 for details), which
                        \ equates to 1024 x 512 in terms of QQ8

.QQ9

 SKIP 1                 \ The galactic x-coordinate of the crosshairs in the
                        \ galaxy chart (and, most of the time, the selected
                        \ system's galactic x-coordinate)

.QQ10

 SKIP 1                 \ The galactic y-coordinate of the crosshairs in the
                        \ galaxy chart (and, most of the time, the selected
                        \ system's galactic y-coordinate)

.NOSTM

 SKIP 1                 \ The number of stardust particles shown on screen,
                        \ which is 18 (#NOST) for normal space, and 3 for
                        \ witchspace

 SKIP 1                 \ This byte appears to be unused

.COMC

 SKIP 1                 \ The colour of the dot on the compass
                        \
                        \   * &F0 = the object in the compass is in front of us,
                        \     so the dot is yellow/white
                        \
                        \   * &FF = the object in the compass is behind us, so
                        \     the dot is green/cyan

.DNOIZ

 SKIP 1                 \ Sound on/off configuration setting
                        \
                        \   * 0 = sound is on (default)
                        \
                        \   * Non-zero = sound is off
                        \
                        \ Toggled by pressing "S" when paused, see the DK4
                        \ routine for details

.DAMP

 SKIP 1                 \ Keyboard damping configuration setting
                        \
                        \   * 0 = damping is enabled (default)
                        \
                        \   * &FF = damping is disabled
                        \
                        \ Toggled by pressing CAPS LOCK when paused, see the
                        \ DKS3 routine for details

.DJD

 SKIP 1                 \ Keyboard auto-recentre configuration setting
                        \
                        \   * 0 = auto-recentre is enabled (default)
                        \
                        \   * &FF = auto-recentre is disabled
                        \
                        \ Toggled by pressing "A" when paused, see the DKS3
                        \ routine for details

.PATG

 SKIP 1                 \ Configuration setting to show the author names on the
                        \ start-up screen and enable manual hyperspace mis-jumps
                        \
                        \   * 0 = no author names or manual mis-jumps (default)
                        \
                        \   * &FF = show author names and allow manual mis-jumps
                        \
                        \ Toggled by pressing "X" when paused, see the DKS3
                        \ routine for details
                        \
                        \ This needs to be turned on for manual mis-jumps to be
                        \ possible. To do a manual mis-jump, first toggle the
                        \ author display by pausing the game (COPY) and pressing
                        \ "X", and during the next hyperspace, hold down CTRL to
                        \ force a mis-jump. See routine ee5 for the "AND PATG"
                        \ instruction that implements this logic

.FLH

 SKIP 1                 \ Flashing console bars configuration setting
                        \
                        \   * 0 = static bars (default)
                        \
                        \   * &FF = flashing bars
                        \
                        \ Toggled by pressing "F" when paused, see the DKS3
                        \ routine for details

.JSTGY

 SKIP 1                 \ Reverse joystick Y-channel configuration setting
                        \
                        \   * 0 = standard Y-channel (default)
                        \
                        \   * &FF = reversed Y-channel
                        \
                        \ Toggled by pressing "Y" when paused, see the DKS3
                        \ routine for details

.JSTE

 SKIP 1                 \ Reverse both joystick channels configuration setting
                        \
                        \   * 0 = standard channels (default)
                        \
                        \   * &FF = reversed channels
                        \
                        \ Toggled by pressing "J" when paused, see the DKS3
                        \ routine for details

.JSTK

 SKIP 1                 \ Keyboard or joystick configuration setting
                        \
                        \   * 0 = keyboard (default)
                        \
                        \   * &FF = joystick
                        \
                        \ Toggled by pressing "K" when paused, see the DKS3
                        \ routine for details

.BSTK

 SKIP 1                 \ Bitstik configuration setting
                        \
                        \   * 0 = keyboard or joystick (default)
                        \
                        \   * &FF = Bitstik
                        \
                        \ Toggled by pressing "B" when paused, see the DKS3
                        \ routine for details

.CATF

 SKIP 1                 \ The disc catalogue flag
                        \
                        \ Determines whether a disc catalogue is currently in
                        \ progress, so the TT26 print routine can format the
                        \ output correctly:
                        \
                        \   * 0 = disc is not currently being catalogued
                        \
                        \   * 1 = disc is currently being catalogued
                        \
                        \ Specifically, when CATF is non-zero, TT26 will omit
                        \ column 17 from the catalogue so that it will fit
                        \ on-screen (column 17 is blank column in the middle
                        \ of the catalogue, between the two lists of filenames,
                        \ so it can be dropped without affecting the layout)

                        \ --- Code added for Elite-A: ------------------------->

.new_pulse

 SKIP 1                 \ AJD

.new_beam

 SKIP 1                 \ AJD

.new_military

 SKIP 1                 \ AJD

.new_mining

 SKIP 1                 \ AJD

.new_mounts

 SKIP 1                 \ AJD

.new_missiles

 SKIP 1                 \ AJD

.new_shields

 SKIP 1                 \ AJD

.new_energy

 SKIP 1                 \ AJD

.new_speed

 SKIP 1                 \ AJD

.new_hold

 SKIP 1                 \ AJD

.new_range

 SKIP 1                 \ AJD

.new_costs

 SKIP 1                 \ AJD

.new_max

 SKIP 1                 \ AJD

.new_min

 SKIP 1                 \ AJD

.new_space

 SKIP 1                 \ AJD

                        \ --- End of added code ------------------------------->

\ ******************************************************************************
\
\       Name: K%
\       Type: Workspace
\    Address: &0900 to &0D3F
\   Category: Workspaces
\    Summary: Ship data blocks and ship line heaps
\  Deep dive: Ship data blocks
\             The local bubble of universe
\
\ ------------------------------------------------------------------------------
\
\ Contains ship data for all the ships, planets, suns and space stations in our
\ local bubble of universe, along with their corresponding ship line heaps.
\
\ The blocks are pointed to by the lookup table at location UNIV. The first 444
\ bytes of the K% workspace hold ship data on up to 12 ships, with 37 (NI%)
\ bytes per ship, and the ship line heap grows downwards from WP at the end of
\ the K% workspace.
\
\ See the deep dive on "Ship data blocks" for details on ship data blocks, and
\ the deep dive on "The local bubble of universe" for details of how Elite
\ stores the local universe in K%, FRIN and UNIV.
\
\ ******************************************************************************

ORG &0900

.K%

 SKIP 0                 \ Ship data blocks and ship line heap

\ ******************************************************************************
\
\       Name: WP
\       Type: Workspace
\    Address: &0E00 to &0E3B
\   Category: Workspaces
\    Summary: Variables
\
\ ******************************************************************************

ORG &0E00

.WP

 SKIP 0                 \ The start of the WP workspace

.LSX

 SKIP 0                 \ LSX is an alias that points to the first byte of the
                        \ sun line heap at LSO
                        \
                        \   * &FF indicates the sun line heap is empty
                        \
                        \   * Otherwise the LSO heap contains the line data for
                        \     the sun

.LSO

 SKIP 1                 \ This space has three uses:
                        \
.BUF                    \   * The ship line heap for the space station (see
                        \     NWSPS for details)
 SKIP 191               \
                        \   * The sun line heap (see SUN for details)
                        \
                        \   * The line buffer used by DASC to print justified
                        \     text (BUF = LSO + 1)
                        \
                        \ The spaces can be shared as our local bubble of
                        \ universe can support either the sun or a space
                        \ station, but not both

.LSX2

 SKIP 78                \ The ball line heap for storing x-coordinates (see the
                        \ deep dive on "The ball line heap" for details)

.LSY2

 SKIP 78                \ The ball line heap for storing y-coordinates (see the
                        \ deep dive on "The ball line heap" for details)

.SX

 SKIP NOST + 1          \ This is where we store the x_hi coordinates for all
                        \ the stardust particles

.SXL

 SKIP NOST + 1          \ This is where we store the x_lo coordinates for all
                        \ the stardust particles

.SY

 SKIP NOST + 1          \ This is where we store the y_hi coordinates for all
                        \ the stardust particles

.SYL

 SKIP NOST + 1          \ This is where we store the y_lo coordinates for all
                        \ the stardust particles

.SZ

 SKIP NOST + 1          \ This is where we store the z_hi coordinates for all
                        \ the stardust particles

.SZL

 SKIP NOST + 1          \ This is where we store the z_lo coordinates for all
                        \ the stardust particles

.LASX

 SKIP 1                 \ The x-coordinate of the tip of the laser line

.LASY

 SKIP 1                 \ The y-coordinate of the tip of the laser line

.XX24

 SKIP 1                 \ This byte appears to be unused

.ALTIT

 SKIP 1                 \ Our altitude above the surface of the planet or sun
                        \
                        \   * 255 = we are a long way above the surface
                        \
                        \   * 1-254 = our altitude as the square root of:
                        \
                        \       x_hi^2 + y_hi^2 + z_hi^2 - 6^2
                        \
                        \     where our ship is at the origin, the centre of the
                        \     planet/sun is at (x_hi, y_hi, z_hi), and the
                        \     radius of the planet/sun is 6
                        \
                        \   * 0 = we have crashed into the surface

.CPIR

 SKIP 1                 \ A counter used when spawning pirates, to work our way
                        \ through the list of pirate ship blueprints until we
                        \ find one that has been loaded

PRINT "WP workspace from  ", ~WP," to ", ~P%

\ ******************************************************************************
\
\ ELITE A FILE
\
\ ******************************************************************************

CODE% = &11E3
LOAD% = &11E3

ORG CODE%

LOAD_A% = LOAD%

\ ******************************************************************************
\
\       Name: S%
\       Type: Workspace
\    Address: &11E3 to &11F0
\   Category: Workspaces
\    Summary: Entry points and vector addresses in the main docked code
\
\ ******************************************************************************

.S%

 JMP DOENTRY            \ Decrypt the main docked code and dock at the station

                        \ --- Original Acornsoft code removed: ---------------->

\ JMP DOBEGIN           \ Decrypt the main docked code and start a new game

                        \ --- And replaced by: -------------------------------->

 JMP DOENTRY            \ Decrypt the main docked code and dock at the station

                        \ --- End of replacement ------------------------------>

 JMP CHPR               \ WRCHV is set to point here by elite-loader3.asm

 EQUW IRQ1              \ IRQ1V is set to point here by elite-loader3.asm

                        \ --- Original Acornsoft code removed: ---------------->

\ JMP BRBR1             \ BRKV is set to point here by elite-loader3.asm

                        \ --- And replaced by: -------------------------------->

 JMP BRBR               \ AJD

                        \ --- End of replacement ------------------------------>

BRKV = P% - 2           \ The address of the destination address in the above
                        \ JMP BRBR1 instruction. This ensures that any code that
                        \ updates BRKV will update this instruction instead of
                        \ the actual vector

\ ******************************************************************************
\
\       Name: INBAY
\       Type: Subroutine
\   Category: Loader
\    Summary: Load and run the main docked code in T.CODE
\
\ ******************************************************************************

.INBAY

 LDX #LO(LTLI)          \ Set (Y X) to point to LTLI ("L.T.CODE", which gets
 LDY #HI(LTLI)          \ modified to "R.T.CODE" in the DOENTRY routine)

 JSR OSCLI              \ Call OSCLI to run the OS command in LTLI, which *RUNs
                        \ the main docked code in T.CODE

\ ******************************************************************************
\
\       Name: LTLI
\       Type: Variable
\   Category: Loader
\    Summary: The OS command string for loading the docked code file 1.D
\
\ ******************************************************************************

.LTLI

                        \ --- Original Acornsoft code removed: ---------------->

\ EQUS "L.T.CODE"
\ EQUB 13

                        \ --- And replaced by: -------------------------------->

 EQUS "L.1.D"
 EQUB 13

                        \ --- End of replacement ------------------------------>

\ ******************************************************************************
\
\       Name: launch
\       Type: Subroutine
\   Category: Loader
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.launch

 LDA #'R'
 STA LTLI

 EQUB &2C

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: escape
\       Type: Subroutine
\   Category: Start and end
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.escape

 LDA #0
 STA KL+1
 JMP INBAY

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: DOENTRY
\       Type: Subroutine
\   Category: Loader
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.DOENTRY

 JSR BRKBK
 JSR RES2
 JMP BAY

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: BRKBK
\       Type: Subroutine
\   Category: Save and load
\    Summary: Set the standard BRKV handler for the game
\
\ ******************************************************************************

.BRKBK

 LDA #LO(BRBR)          \ Set BRKV to point to the BRBR routine
 STA BRKV
 LDA #HI(BRBR)
 STA BRKV+1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: write_msg3
\       Type: Subroutine
\   Category: Text
\    Summary: Print an extended recursive token from the msg_3 token table
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The recursive token to be printed, in the range 0-255
\
\ Returns:
\
\   A                   A is preserved
\
\   Y                   Y is preserved
\
\   V(1 0)              V(1 0) is preserved
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.write_msg3

 PHA                    \ Store A on the stack, so we can retrieve it later

 TAX                    \ Copy the token number from A into X

 TYA                    \ Store Y on the stack
 PHA

 LDA V                  \ Store V(1 0) on the stack
 PHA
 LDA V+1
 PHA

 LDA #LO(msg_3)         \ Set V to the low byte of RUTOK
 STA V

 LDA #HI(msg_3)         \ Set A to the high byte of RUTOK

 BNE DTEN               \ Call DTEN to print token number X from the RUTOK
                        \ table and restore the values of A, Y and V(1 0) from
                        \ the stack, returning from the subroutine using a tail
                        \ call (this BNE is effectively a JMP as A is never
                        \ zero)

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: MT27
\       Type: Subroutine
\   Category: Text
\    Summary: Print the captain's name during mission briefings
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine prints the following tokens, depending on the galaxy number:
\
\   * Token 217 ("CURRUTHERS") in galaxy 0
\
\   * Token 218 ("FOSDYKE SMYTHE") in galaxy 1
\
\   * Token 219 ("FORTESQUE") in galaxy 2
\
\ This is used when printing extended token 213 as part of the mission
\ briefings, which looks like this when printed:
\
\   Commander {commander name}, I am Captain {mission captain's name} of Her
\   Majesty's Space Navy
\
\ where {mission captain's name} is replaced by one of the names above.
\
\ ******************************************************************************

.MT27

 LDA #217               \ Set A = 217, so when we fall through into MT28, the
                        \ 217 gets added to the current galaxy number, so the
                        \ extended token that is printed is 217-219 (as this is
                        \ only called in galaxies 0 through 2)

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &DC, or BIT &DCA9, which does nothing apart
                        \ from affect the flags

\ ******************************************************************************
\
\       Name: MT28
\       Type: Subroutine
\   Category: Text
\    Summary: Print the location hint during the mission 1 briefing
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine prints the following tokens, depending on the galaxy number:
\
\   * Token 220 ("WAS LAST SEEN AT {single cap}REESDICE") in galaxy 0
\
\   * Token 221 ("IS BELIEVED TO HAVE JUMPED TO THIS GALAXY") in galaxy 1
\
\ This is used when printing extended token 10 as part of the mission 1
\ briefing, which looks like this when printed:
\
\   It went missing from our ship yard on Xeer five months ago and {mission 1
\   location hint}
\
\ where {mission 1 location hint} is replaced by one of the names above.
\
\ ******************************************************************************

.MT28

 LDA #220               \ Set A = galaxy number in GCNT + 220, which is in the
 CLC                    \ range 220-221, as this is only called in galaxies 0
 ADC GCNT               \ and 1

                        \ --- Original Acornsoft code removed: ---------------->

\ BNE DETOK             \ Jump to DETOK to print extended token 220-221,
\                       \ returning from the subroutine using a tail call (this
\                       \ BNE is effectively a JMP as A is never zero)

                        \ --- End of removed code ----------------------------->

\ ******************************************************************************
\
\       Name: DETOK
\       Type: Subroutine
\   Category: Text
\    Summary: Print an extended recursive token from the TKN1 token table
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The recursive token to be printed, in the range 1-255
\
\ Returns:
\
\   A                   A is preserved
\
\   Y                   Y is preserved
\
\   V(1 0)              V(1 0) is preserved
\
\ Other entry points:
\
\   DTEN                Print recursive token number X from the token table
\                       pointed to by (A V), used to print tokens from the RUTOK
\                       table via calls to DETOK3
\
\ ******************************************************************************

.DETOK

 PHA                    \ Store A on the stack, so we can retrieve it later

 TAX                    \ Copy the token number from A into X

 TYA                    \ Store Y on the stack
 PHA

 LDA V                  \ Store V(1 0) on the stack
 PHA
 LDA V+1
 PHA

 LDA #LO(TKN1)          \ Set V to the low byte of TKN1
 STA V

 LDA #HI(TKN1)          \ Set A to the high byte of TKN1, so when we fall
                        \ through into DTEN, V(1 0) gets set to the address of
                        \ the TKN1 token table

.DTEN

 STA V+1                \ Set the high byte of V(1 0) to A, so V(1 0) now points
                        \ to the start of the token table to use

 LDY #0                 \ First, we need to work our way through the table until
                        \ we get to the token that we want to print. Tokens are
                        \ delimited by #VE, and VE EOR VE = 0, so we work our
                        \ way through the table in, counting #VE delimiters
                        \ until we have passed X of them, at which point we jump
                        \ down to DTL2 to do the actual printing. So first, we
                        \ set a counter Y to point to the character offset as we
                        \ scan through the table
.DTL1

 LDA (V),Y              \ Load the character at offset Y in the token table,
                        \ which is the next character from the token table

                        \ --- Original Acornsoft code removed: ---------------->

\ EOR #VE               \ Tokens are stored in memory having been EOR'd with
\                       \ #VE, so we repeat the EOR to get the actual character
\                       \ in this token

                        \ --- End of removed code ----------------------------->

 BNE DT1                \ If the result is non-zero, then this is a character
                        \ in a token rather than the delimiter (which is #VE),
                        \ so jump to DT1

 DEX                    \ We have just scanned the end of a token, so decrement
                        \ X, which contains the token number we are looking for

 BEQ DTL2               \ If X has now reached zero then we have found the token
                        \ we are looking for, so jump down to DTL2 to print it

.DT1

 INY                    \ Otherwise this isn't the token we are looking for, so
                        \ increment the character pointer

 BNE DTL1               \ If Y hasn't just wrapped around to 0, loop back to
                        \ DTL1 to process the next character

 INC V+1                \ We have just crossed into a new page, so increment
                        \ V+1 so that V points to the start of the new page

 BNE DTL1               \ Jump back to DTL1 to process the next character (this
                        \ BNE is effectively a JMP as V+1 won't reach zero
                        \ before we reach the end of the token table)

.DTL2

 INY                    \ We just detected the delimiter byte before the token
                        \ that we want to print, so increment the character
                        \ pointer to point to the first character of the token,
                        \ rather than the delimiter

 BNE P%+4               \ If Y hasn't just wrapped around to 0, skip the next
                        \ instruction

 INC V+1                \ We have just crossed into a new page, so increment
                        \ V+1 so that V points to the start of the new page

 LDA (V),Y              \ Load the character at offset Y in the token table,
                        \ which is the next character from the token we want to
                        \ print

                        \ --- Original Acornsoft code removed: ---------------->

\ EOR #VE               \ Tokens are stored in memory having been EOR'd with
\                       \ #VE, so we repeat the EOR to get the actual character
\                       \ in this token

                        \ --- End of removed code ----------------------------->

 BEQ DTEX               \ If the result is zero, then this is the delimiter at
                        \ the end of the token to print (which is #VE), so jump
                        \ to DTEX to return from the subroutine, as we are done
                        \ printing

 JSR DETOK2             \ Otherwise call DETOK2 to print this part of the token

 JMP DTL2               \ Jump back to DTL2 to process the next character

.DTEX

 PLA                    \ Restore V(1 0) from the stack, so it is preserved
 STA V+1                \ through calls to this routine
 PLA
 STA V

 PLA                    \ Restore Y from the stack, so it is preserved through
 TAY                    \ calls to this routine

 PLA                    \ Restore A from the stack, so it is preserved through
                        \ calls to this routine

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DETOK2
\       Type: Subroutine
\   Category: Text
\    Summary: Print an extended text token (1-255)
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The token to be printed (1-255)
\
\ Returns:
\
\   A                   A is preserved
\
\   Y                   Y is preserved
\
\   V(1 0)              V(1 0) is preserved
\
\ Other entry points:
\
\   DTS                 Print the single letter pointed to by A, where A is an
\                       address within the extended two-letter token tables of
\                       TKN2 and QQ16
\
\   msg_pairs           AJD
\
\ ******************************************************************************

.DETOK2

 CMP #32                \ If A < 32 then this is a jump token, so skip to DT3 to
 BCC DT3                \ process it

 BIT DTW3               \ If bit 7 of DTW3 is clear, then extended tokens are
 BPL DT8                \ enabled, so jump to DT8 to process them

                        \ If we get there then this is not a jump token and
                        \ extended tokens are not enabled, so we can call the
                        \ standard text token routine at TT27 to print the token

 TAX                    \ Copy the token number from A into X

 TYA                    \ Store Y on the stack
 PHA

 LDA V                  \ Store V(1 0) on the stack
 PHA
 LDA V+1
 PHA

 TXA                    \ Copy the token number from X back into A

 JSR TT27               \ Call TT27 to print the text token

 JMP DT7                \ Jump to DT7 to restore V(1 0) and Y from the stack and
                        \ return from the subroutine

.DT8

                        \ If we get here then this is not a jump token and
                        \ extended tokens are enabled

 CMP #'['               \ If A < ASCII "[" (i.e. A <= ASCII "Z", or 90) then
 BCC DTS                \ this is a printable ASCII character, so jump down to
                        \ DTS to print it

 CMP #129               \ If A < 129, so A is in the range 91-128, jump down to
 BCC DT6                \ DT6 to print a randomised token from the MTIN table

 CMP #215               \ If A < 215, so A is in the range 129-214, jump to
 BCC DETOK              \ DETOK as this is a recursive token, returning from the
                        \ subroutine using a tail call

                        \ If we get here then A >= 215, so this is a two-letter
                        \ token from the extended TKN2/QQ16 table

                        \ --- Code added for Elite-A: ------------------------->

.msg_pairs

                        \ --- End of added code ------------------------------->

 SBC #215               \ Subtract 215 to get a token number in the range 0-12
                        \ (the C flag is set as we passed through the BCC above,
                        \ so this subtraction is correct)

 ASL A                  \ Set A = A * 2, so it can be used as a pointer into the
                        \ two-letter token tables at TKN2 and QQ16

 PHA                    \ Store A on the stack, so we can restore it for the
                        \ second letter below

 TAX                    \ Fetch the first letter of the two-letter token from
 LDA TKN2,X             \ TKN2, which is at TKN2 + X

 JSR DTS                \ Call DTS to print it

 PLA                    \ Restore A from the stack and transfer it into X
 TAX

 LDA TKN2+1,X           \ Fetch the second letter of the two-letter token from
                        \ TKN2, which is at TKN2 + X + 1, and fall through into
                        \ DTS to print it

.DTS

 CMP #'A'               \ If A < ASCII "A", jump to DT9 to print this as ASCII
 BCC DT9

 BIT DTW6               \ If bit 7 of DTW6 is set, then lower case has been
 BMI DT10               \ enabled by jump token 13, {lower case}, so jump to
                        \ DT10 to apply the lower case and single cap masks

 BIT DTW2               \ If bit 7 of DTW2 is set, then we are not currently
 BMI DT5                \ printing a word, so jump to DT5 so we skip the setting
                        \ of lower case in Sentence Case (which we only want to
                        \ do when we are already printing a word)

.DT10

 ORA DTW1               \ Convert the character to lower case if DTW1 is
                        \ %00100000 (i.e. if we are in {sentence case} mode)

.DT5

 AND DTW8               \ Convert the character to upper case if DTW8 is
                        \ %11011111 (i.e. after a {single cap} token)

.DT9

 JMP DASC               \ Jump to DASC to print the ASCII character in A,
                        \ returning from the routine using a tail call

.DT3

                        \ If we get here then the token number in A is in the
                        \ range 1 to 32, so this is a jump token that should
                        \ call the corresponding address in the jump table at
                        \ JMTB

 TAX                    \ Copy the token number from A into X

 TYA                    \ Store Y on the stack
 PHA

 LDA V                  \ Store V(1 0) on the stack
 PHA
 LDA V+1
 PHA

 TXA                    \ Copy the token number from X back into A

 ASL A                  \ Set A = A * 2, so it can be used as a pointer into the
                        \ jump table at JMTB, though because the original range
                        \ of values is 1-32, so the doubled range is 2-64, we
                        \ need to take the offset into the jump table from
                        \ JMTB-2 rather than JMTB

 TAX                    \ Copy the doubled token number from A into X

 LDA JMTB-2,X           \ Set DTM(2 1) to the X-th address from the table at
 STA DTM+1              \ JTM-2, which modifies the JSR DASC instruction at
 LDA JMTB-1,X           \ label DTM below so that it calls the subroutine at the
 STA DTM+2              \ relevant address from the JMTB table

 TXA                    \ Copy the doubled token number from X back into A

 LSR A                  \ Halve A to get the original token number

.DTM

 JSR DASC               \ Call the relevant JMTB subroutine, as this instruction
                        \ will have been modified by the above to point to the
                        \ relevant address

.DT7

 PLA                    \ Restore V(1 0) from the stack, so it is preserved
 STA V+1                \ through calls to this routine
 PLA
 STA V

 PLA                    \ Restore Y from the stack, so it is preserved through
 TAY                    \ calls to this routine

 RTS                    \ Return from the subroutine

.DT6

                        \ If we get here then the token number in A is in the
                        \ range 91-128, which means we print a randomly picked
                        \ token from the token range given in the corresponding
                        \ entry in the MTIN table

 STA SC                 \ Store the token number in SC

 TYA                    \ Store Y on the stack
 PHA

 LDA V                  \ Store V(1 0) on the stack
 PHA
 LDA V+1
 PHA

 JSR DORND              \ Set X to a random number
 TAX

 LDA #0                 \ Set A to 0, so we can build a random number from 0 to
                        \ 4 in A plus the C flag, with each number being equally
                        \ likely

 CPX #51                \ Add 1 to A if X >= 51
 ADC #0

 CPX #102               \ Add 1 to A if X >= 102
 ADC #0

 CPX #153               \ Add 1 to A if X >= 153
 ADC #0

 CPX #204               \ Set the C flag if X >= 204

 LDX SC                 \ Fetch the token number from SC into X, so X is now in
                        \ the range 91-128

 ADC MTIN-91,X          \ Set A = MTIN-91 + token number (91-128) + random (0-4)
                        \       = MTIN + token number (0-37) + random (0-4)

 JSR DETOK              \ Call DETOK to print the extended recursive token in A

 JMP DT7                \ Jump to DT7 to restore V(1 0) and Y from the stack and
                        \ return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: MT1
\       Type: Subroutine
\   Category: Text
\    Summary: Switch to ALL CAPS when printing extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * DTW1 = %00000000 (do not change case to lower case)
\
\   * DTW6 = %00000000 (lower case is not enabled)
\
\ ******************************************************************************

.MT1

 LDA #%00000000         \ Set A = %00000000, so when we fall through into MT2,
                        \ both DTW1 and DTW6 get set to %00000000

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &20, or BIT &20A9, which does nothing apart
                        \ from affect the flags

\ ******************************************************************************
\
\       Name: MT2
\       Type: Subroutine
\   Category: Text
\    Summary: Switch to Sentence Case when printing extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * DTW1 = %00100000 (apply lower case to the second letter of a word onwards)
\
\   * DTW6 = %00000000 (lower case is not enabled)
\
\ ******************************************************************************

.MT2

 LDA #%00100000         \ Set DTW1 = %00100000
 STA DTW1

 LDA #00000000          \ Set DTW6 = %00000000
 STA DTW6

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: column_16
\       Type: Subroutine
\   Category: Text
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.column_16

 LDA #&10
 EQUB &2C

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: MT8
\       Type: Subroutine
\   Category: Text
\    Summary: Tab to column 6 and start a new word when printing extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * XC = 6 (tab to column 6)
\
\   * DTW2 = %11111111 (we are not currently printing a word)
\
\ Other entry points:
\
\   set_token           AJD
\
\ ******************************************************************************

.MT8

 LDA #6                 \ Move the text cursor to column 6
 STA XC

                        \ --- Code added for Elite-A: ------------------------->

.set_token

                        \ --- End of added code ------------------------------->

 LDA #%11111111         \ Set all the bits in DTW2
 STA DTW2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MT9
\       Type: Subroutine
\   Category: Text
\    Summary: Clear the screen and set the current view type to 1
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * XC = 1 (tab to column 1)
\
\ before calling TT66 to clear the screen and set the view type to 1.
\
\ ******************************************************************************

.MT9

 LDA #1                 \ Move the text cursor to column 1
 STA XC

 JMP TT66               \ Jump to TT66 to clear the screen and set the current
                        \ view type to 1, returning from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: MT13
\       Type: Subroutine
\   Category: Text
\    Summary: Switch to lower case when printing extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * DTW1 = %00100000 (apply lower case to the second letter of a word onwards)
\
\   * DTW6 = %10000000 (lower case is enabled)
\
\ ******************************************************************************

.MT13

 LDA #%10000000         \ Set DTW6 = %10000000
 STA DTW6

 LDA #%00100000         \ Set DTW1 = %00100000
 STA DTW1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: clr_vdustat
\       Type: Subroutine
\   Category: Text
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.clr_vdustat

 LDA #&01
 EQUB &2C

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: MT6
\       Type: Subroutine
\   Category: Text
\    Summary: Switch to standard tokens in Sentence Case
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * QQ17 = %10000000 (set Sentence Case for standard tokens)
\
\   * DTW3 = %11111111 (print standard tokens)
\
\ ******************************************************************************

.MT6

 LDA #%10000000         \ Set bit 7 of QQ17 to switch standard tokens to
 STA QQ17               \ Sentence Case

 LDA #%11111111         \ Set A = %11111111, so when we fall through into MT5,
                        \ DTW3 gets set to %11111111 and calls to DETOK print
                        \ standard tokens

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &00, or BIT &00A9, which does nothing apart
                        \ from affect the flags

\ ******************************************************************************
\
\       Name: MT5
\       Type: Subroutine
\   Category: Text
\    Summary: Switch to extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * DTW3 = %00000000 (print extended tokens)
\
\ ******************************************************************************

.MT5

 LDA #%00000000         \ Set DTW3 = %00000000, so that calls to DETOK print
 STA DTW3               \ extended tokens

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MT14
\       Type: Subroutine
\   Category: Text
\    Summary: Switch to justified text when printing extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * DTW4 = %10000000 (justify text, print buffer on carriage return)
\
\   * DTW5 = 0 (reset line buffer size)
\
\ ******************************************************************************

.MT14

 LDA #%10000000         \ Set A = %10000000, so when we fall through into MT15,
                        \ DTW4 gets set to %10000000

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &00, or BIT &00A9, which does nothing apart
                        \ from affect the flags

\ ******************************************************************************
\
\       Name: MT15
\       Type: Subroutine
\   Category: Text
\    Summary: Switch to left-aligned text when printing extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * DTW4 = %00000000 (do not justify text, print buffer on carriage return)
\
\   * DTW5 = 0 (reset line buffer size)
\
\ ******************************************************************************

.MT15

 LDA #0                 \ Set DTW4 = %00000000
 STA DTW4

 ASL A                  \ Set DTW5 = 0 (even when we fall through from MT14 with
 STA DTW5               \ A set to %10000000)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MT17
\       Type: Subroutine
\   Category: Text
\    Summary: Print the selected system's adjective, e.g. Lavian for Lave
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ The adjective for the current system is generated by taking the system name,
\ removing the last character if it is a vowel, and adding "-ian" to the end,
\ so:
\
\   * Lave gives Lavian (as in "Lavian tree grub")
\
\   * Leesti gives Leestian (as in "Leestian Evil Juice")
\
\ This routine is called by jump token 17, {system name adjective}, and it can
\ only be used when justified text is being printed - i.e. following jump token
\ 14, {justify} - because the routine needs to use the line buffer to work.
\
\ ******************************************************************************

.MT17

 LDA QQ17               \ Set QQ17 = %10111111 to switch to Sentence Case
 AND #%10111111
 STA QQ17

 LDA #3                 \ Print control code 3 (selected system name) into the
 JSR TT27               \ line buffer

 LDX DTW5               \ Load the last character of the line buffer BUF into A
 LDA BUF-1,X            \ (as DTW5 contains the buffer size, so character DTW5-1
                        \ is the last character in the buffer BUF)

 JSR VOWEL              \ Test whether the character is a vowel, in which case
                        \ this will set the C flag

 BCC MT171              \ If the character is not a vowel, skip the following
                        \ instruction

 DEC DTW5               \ The character is a vowel, so decrement DTW5, which
                        \ removes the last character from the line buffer (i.e.
                        \ it removes the trailing vowel from the system name)

.MT171

 LDA #153               \ Print extended token 153 ("IAN"), returning from the
 JMP DETOK              \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: MT18
\       Type: Subroutine
\   Category: Text
\    Summary: Print a random 1-8 letter word in Sentence Case
\  Deep dive: Extended text tokens
\
\ ******************************************************************************

.MT18

 JSR MT19               \ Call MT19 to capitalise the next letter (i.e. set
                        \ Sentence Case for this word only)

 JSR DORND              \ Set A and X to random numbers and reduce A to a
 AND #3                 \ random number in the range 0-3

 TAY                    \ Copy the random number into Y, so we can use Y as a
                        \ loop counter to print 1-4 words (i.e. Y+1 words)

.MT18L

 JSR DORND              \ Set A and X to random numbers and reduce A to an even
 AND #62                \ random number in the range 0-62 (as bit 0 of 62 is 0)

 TAX                    \ Copy the random number into X, so X contains the table
                        \ offset of a random extended two-letter token from 0-31
                        \ which we can now use to pick a token from the combined
                        \ tables at TKN2+2 and QQ16 (we intentionally exclude
                        \ the first token in TKN2, which contains a newline)

 LDA TKN2+2,X           \ Print the first letter of the token at TKN2+2 + X
 JSR DTS

 LDA TKN2+3,X           \ Print the second letter of the token at TKN2+2 + X
 JSR DTS

 DEY                    \ Decrement the loop counter

 BPL MT18L              \ Loop back to MT18L to print another two-letter token
                        \ until we have printed Y+1 of them

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MT19
\       Type: Subroutine
\   Category: Text
\    Summary: Capitalise the next letter
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * DTW8 = %11011111 (capitalise the next letter)
\
\ ******************************************************************************

.MT19

 LDA #%11011111         \ Set DTW8 = %11011111
 STA DTW8

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: VOWEL
\       Type: Subroutine
\   Category: Text
\    Summary: Test whether a character is a vowel
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The character to be tested
\
\ Returns:
\
\   C flag              The C flag is set if the character is a vowel, otherwise
\                       it is clear
\
\ ******************************************************************************

.VOWEL

 ORA #%00100000         \ Set bit 5 of the character to make it lower case

 CMP #'a'               \ If the letter is a vowel, jump to VRTS to return from
 BEQ VRTS               \ the subroutine with the C flag set (as the CMP will
 CMP #'e'               \ set the C flag if the comparison is equal)
 BEQ VRTS
 CMP #'i'
 BEQ VRTS
 CMP #'o'
 BEQ VRTS
 CMP #'u'
 BEQ VRTS

 CLC                    \ The character is not a vowel, so clear the C flag

.VRTS

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: JMTB
\       Type: Variable
\   Category: Text
\    Summary: The extended token table for jump tokens 1-32 (DETOK)
\  Deep dive: Extended text tokens
\
\ ******************************************************************************

.JMTB

 EQUW MT1               \ Token  1: Switch to ALL CAPS
 EQUW MT2               \ Token  2: Switch to Sentence Case
 EQUW TT27              \ Token  3: Print the selected system name

                        \ --- Original Acornsoft code removed: ---------------->

\ EQUW TT27             \ Token  4: Print the commander's name

                        \ --- And replaced by: -------------------------------->

 EQUW MT6               \ Token  4: Switch to standard tokens, in Sentence Case

                        \ --- End of replacement ------------------------------>

 EQUW MT5               \ Token  5: Switch to extended tokens

                        \ --- Original Acornsoft code removed: ---------------->

\ EQUW MT6              \ Token  6: Switch to standard tokens, in Sentence Case

                        \ --- And replaced by: -------------------------------->

 EQUW set_token         \ Token  6: AJD

                        \ --- End of replacement ------------------------------>

 EQUW DASC              \ Token  7: Beep
 EQUW MT8               \ Token  8: Tab to column 6
 EQUW MT9               \ Token  9: Clear screen, tab to column 1, view type = 1
 EQUW DASC              \ Token 10: Line feed
 EQUW NLIN4             \ Token 11: Draw box around title (line at pixel row 19)
 EQUW DASC              \ Token 12: Carriage return
 EQUW MT13              \ Token 13: Switch to lower case
 EQUW MT14              \ Token 14: Switch to justified text
 EQUW MT15              \ Token 15: Switch to left-aligned text
 EQUW MT16              \ Token 16: Print the character in DTW7 (drive number)
 EQUW MT17              \ Token 17: Print system name adjective in Sentence Case
 EQUW MT18              \ Token 18: Randomly print 1 to 4 two-letter tokens
 EQUW MT19              \ Token 19: Capitalise first letter of next word only
 EQUW DASC              \ Token 20: Unused
 EQUW CLYNS             \ Token 21: Clear the bottom few lines of the space view

                        \ --- Original Acornsoft code removed: ---------------->

\ EQUW PAUSE            \ Token 22: Display ship and wait for key press

                        \ --- And replaced by: -------------------------------->

 EQUW column_16         \ Token 22: Tab to column 16

                        \ --- End of replacement ------------------------------>

 EQUW MT23              \ Token 23: Move to row 10, white text, set lower case

                        \ --- Original Acornsoft code removed: ---------------->

\ EQUW PAUSE2           \ Token 24: Wait for a key press
\ EQUW BRIS             \ Token 25: Show incoming message screen, wait 2 seconds

                        \ --- And replaced by: -------------------------------->

 EQUW clr_vdustat       \ Token 24: AJD
 EQUW DASC              \ Token 25: Unused

                        \ --- End of replacement ------------------------------>

 EQUW MT26              \ Token 26: Fetch line input from keyboard (filename)
 EQUW MT27              \ Token 27: Print mission captain's name (217-219)
 EQUW MT28              \ Token 28: Print mission 1 location hint (220-221)
 EQUW MT29              \ Token 29: Column 6, white text, lower case in words
 EQUW DASC              \ Token 30: Unused
 EQUW DASC              \ Token 31: Unused
 EQUW DASC              \ Token 32: Unused

\ ******************************************************************************
\
\       Name: TKN2
\       Type: Variable
\   Category: Text
\    Summary: The extended two-letter token lookup table
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ Two-letter token lookup table for extended tokens 215-227.
\
\ ******************************************************************************

.TKN2

 EQUB 12, 10            \ Token 215 = {crlf}
 EQUS "AB"              \ Token 216
 EQUS "OU"              \ Token 217
 EQUS "SE"              \ Token 218
 EQUS "IT"              \ Token 219
 EQUS "IL"              \ Token 220
 EQUS "ET"              \ Token 221
 EQUS "ST"              \ Token 222
 EQUS "ON"              \ Token 223
 EQUS "LO"              \ Token 224
 EQUS "NU"              \ Token 225
 EQUS "TH"              \ Token 226
 EQUS "NO"              \ Token 227

\ ******************************************************************************
\
\       Name: QQ16
\       Type: Variable
\   Category: Text
\    Summary: The two-letter token lookup table
\  Deep dive: Printing text tokens
\
\ ------------------------------------------------------------------------------
\
\ Two-letter token lookup table for tokens 128-159. See the deep dive on
\ "Printing text tokens" for details of how the two-letter token system works.
\
\ ******************************************************************************

.QQ16

 EQUS "AL"              \ Token 128
 EQUS "LE"              \ Token 129
 EQUS "XE"              \ Token 130
 EQUS "GE"              \ Token 131
 EQUS "ZA"              \ Token 132
 EQUS "CE"              \ Token 133
 EQUS "BI"              \ Token 134
 EQUS "SO"              \ Token 135
 EQUS "US"              \ Token 136
 EQUS "ES"              \ Token 137
 EQUS "AR"              \ Token 138
 EQUS "MA"              \ Token 139
 EQUS "IN"              \ Token 140
 EQUS "DI"              \ Token 141
 EQUS "RE"              \ Token 142
 EQUS "A?"              \ Token 143
 EQUS "ER"              \ Token 144
 EQUS "AT"              \ Token 145
 EQUS "EN"              \ Token 146
 EQUS "BE"              \ Token 147
 EQUS "RA"              \ Token 148
 EQUS "LA"              \ Token 149
 EQUS "VE"              \ Token 150
 EQUS "TI"              \ Token 151
 EQUS "ED"              \ Token 152
 EQUS "OR"              \ Token 153
 EQUS "QU"              \ Token 154
 EQUS "AN"              \ Token 155
 EQUS "TE"              \ Token 156
 EQUS "IS"              \ Token 157
 EQUS "RI"              \ Token 158
 EQUS "ON"              \ Token 159

\ ******************************************************************************
\
\       Name: MVEIT (Part 1 of 9)
\       Type: Subroutine
\   Category: Moving
\    Summary: Move current ship: Tidy the orientation vectors
\  Deep dive: Program flow of the ship-moving routine
\             Scheduling tasks with the main loop counter
\
\ ------------------------------------------------------------------------------
\
\ This routine has multiple stages. This stage does the following:
\
\   * Tidy the orientation vectors for one of the ship slots
\
\ Arguments:
\
\   INWK                The current ship/planet/sun's data block
\
\   XSAV                The slot number of the current ship/planet/sun
\
\   TYPE                The type of the current ship/planet/sun
\
\ ******************************************************************************

.MVEIT

 LDA INWK+31            \ If bit 5 of ship byte #31 is set, jump to MV3 as the
 AND #%00100000         \ ship is exploding, so we don't need to tidy its
 BNE MV3                \ orientation vectors

 LDA MCNT               \ Fetch the main loop counter

 EOR XSAV               \ Fetch the slot number of the ship we are moving, EOR
 AND #15                \ with the loop counter and apply mod 15 to the result.
 BNE MV3                \ The result will be zero when "counter mod 15" matches
                        \ the slot number, so this makes sure we call TIDY 12
                        \ times every 16 main loop iterations, like this:
                        \
                        \   Iteration 0, tidy the ship in slot 0
                        \   Iteration 1, tidy the ship in slot 1
                        \   Iteration 2, tidy the ship in slot 2
                        \     ...
                        \   Iteration 11, tidy the ship in slot 11
                        \   Iteration 12, do nothing
                        \   Iteration 13, do nothing
                        \   Iteration 14, do nothing
                        \   Iteration 15, do nothing
                        \   Iteration 16, tidy the ship in slot 0
                        \     ...
                        \
                        \ and so on

 JSR TIDY               \ Call TIDY to tidy up the orientation vectors, to
                        \ prevent the ship from getting elongated and out of
                        \ shape due to the imprecise nature of trigonometry
                        \ in assembly language

.MV3

                        \ Fall through into part 7 (parts 2-6 are not required
                        \ when we are docked)

\ ******************************************************************************
\
\       Name: MVEIT (Part 7 of 9)
\       Type: Subroutine
\   Category: Moving
\    Summary: Move current ship: Rotate ship's orientation vectors by pitch/roll
\  Deep dive: Orientation vectors
\             Pitching and rolling
\
\ ------------------------------------------------------------------------------
\
\ This routine has multiple stages. This stage does the following:
\
\   * Rotate the ship's orientation vectors according to our pitch and roll
\
\ As with the previous step, this is all about moving the other ships rather
\ than us (even though we are the one doing the moving). So we rotate the
\ current ship's orientation vectors (which defines its orientation in space),
\ by the angles we are "moving" the rest of the sky through (alpha and beta, our
\ roll and pitch), so the ship appears to us to be stationary while we rotate.
\
\ ******************************************************************************

 LDY #9                 \ Apply our pitch and roll rotations to the current
 JSR MVS4               \ ship's nosev vector

 LDY #15                \ Apply our pitch and roll rotations to the current
 JSR MVS4               \ ship's roofv vector

 LDY #21                \ Apply our pitch and roll rotations to the current
 JSR MVS4               \ ship's sidev vector

\ ******************************************************************************
\
\       Name: MVEIT (Part 8 of 9)
\       Type: Subroutine
\   Category: Moving
\    Summary: Move current ship: Rotate ship about itself by its own pitch/roll
\  Deep dive: Orientation vectors
\             Pitching and rolling by a fixed angle
\
\ ------------------------------------------------------------------------------
\
\ This routine has multiple stages. This stage does the following:
\
\   * If the ship we are processing is rolling or pitching itself, rotate it and
\     apply damping if required
\
\ ******************************************************************************

 LDA INWK+30            \ Fetch the ship's pitch counter and extract the sign
 AND #%10000000         \ into RAT2
 STA RAT2

 LDA INWK+30            \ Fetch the ship's pitch counter and extract the value
 AND #%01111111         \ without the sign bit into A

 BEQ MV8                \ If the pitch counter is 0, then jump to MV8 to skip
                        \ the following, as the ship is not pitching

 CMP #%01111111         \ If bits 0-6 are set in the pitch counter (i.e. the
                        \ ship's pitch is not damping down), then the C flag
                        \ will be set by this instruction

 SBC #0                 \ Set A = A - 0 - (1 - C), so if we are damping then we
                        \ reduce A by 1, otherwise it is unchanged

 ORA RAT2               \ Change bit 7 of A to the sign we saved in RAT2, so
                        \ the updated pitch counter in A retains its sign

 STA INWK+30            \ Store the updated pitch counter in byte #30

 LDX #15                \ Rotate (roofv_x, nosev_x) by a small angle (pitch)
 LDY #9
 JSR MVS5

 LDX #17                \ Rotate (roofv_y, nosev_y) by a small angle (pitch)
 LDY #11
 JSR MVS5

 LDX #19                \ Rotate (roofv_z, nosev_z) by a small angle (pitch)
 LDY #13
 JSR MVS5

.MV8

 LDA INWK+29            \ Fetch the ship's roll counter and extract the sign
 AND #%10000000         \ into RAT2
 STA RAT2

 LDA INWK+29            \ Fetch the ship's roll counter and extract the value
 AND #%01111111         \ without the sign bit into A

 BEQ MV5                \ If the roll counter is 0, then jump to MV5 to skip the
                        \ following, as the ship is not rolling

 CMP #%01111111         \ If bits 0-6 are set in the roll counter (i.e. the
                        \ ship's roll is not damping down), then the C flag
                        \ will be set by this instruction

 SBC #0                 \ Set A = A - 0 - (1 - C), so if we are damping then we
                        \ reduce A by 1, otherwise it is unchanged

 ORA RAT2               \ Change bit 7 of A to the sign we saved in RAT2, so
                        \ the updated roll counter in A retains its sign

 STA INWK+29            \ Store the updated pitch counter in byte #29

 LDX #15                \ Rotate (roofv_x, sidev_x) by a small angle (roll)
 LDY #21
 JSR MVS5

 LDX #17                \ Rotate (roofv_y, sidev_y) by a small angle (roll)
 LDY #23
 JSR MVS5

 LDX #19                \ Rotate (roofv_z, sidev_z) by a small angle (roll)
 LDY #25
 JSR MVS5

\ ******************************************************************************
\
\       Name: MVEIT (Part 9 of 9)
\       Type: Subroutine
\   Category: Moving
\    Summary: Move current ship: Redraw on scanner, if it hasn't been destroyed
\
\ ------------------------------------------------------------------------------
\
\ This routine has multiple stages. This stage does the following:
\
\   * If the ship is exploding or being removed, hide it on the scanner
\
\   * Otherwise redraw the ship on the scanner, now that it's been moved
\
\ ******************************************************************************

.MV5

 LDA INWK+31            \ Fetch the ship's exploding/killed state from byte #31

 AND #%00100000         \ If we are exploding then jump to MVD1 to remove it
 BNE MVD1               \ from the scanner permanently

 LDA INWK+31            \ Set bit 4 to keep the ship visible on the scanner
 ORA #%00010000
 STA INWK+31

.MVD1

 LDA INWK+31            \ Clear bit 4 to hide the ship on the scanner
 AND #%11101111
 STA INWK+31

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MVS4
\       Type: Subroutine
\   Category: Moving
\    Summary: Apply pitch and roll to an orientation vector
\  Deep dive: Orientation vectors
\             Pitching and rolling
\
\ ------------------------------------------------------------------------------
\
\ Apply pitch and roll angles alpha and beta to the orientation vector in Y.
\
\ Specifically, this routine rotates a point (x, y, z) around the origin by
\ pitch alpha and roll beta, using the small angle approximation to make the
\ maths easier, and incorporating the Minsky circle algorithm to make the
\ rotation more stable (though more elliptic).
\
\ If that paragraph makes sense to you, then you should probably be writing
\ this commentary! For the rest of us, there's a detailed explanation of all
\ this in the deep dive on "Pitching and rolling".
\
\ Arguments:
\
\   Y                   Determines which of the INWK orientation vectors to
\                       transform:
\
\                         * Y = 9 rotates nosev: (nosev_x, nosev_y, nosev_z)
\
\                         * Y = 15 rotates roofv: (roofv_x, roofv_y, roofv_z)
\
\                         * Y = 21 rotates sidev: (sidev_x, sidev_y, sidev_z)
\
\ ******************************************************************************

.MVS4

 LDA ALPHA              \ Set Q = alpha (the roll angle to rotate through)
 STA Q

 LDX INWK+2,Y           \ Set (S R) = nosev_y
 STX R
 LDX INWK+3,Y
 STX S

 LDX INWK,Y             \ These instructions have no effect as MAD overwrites
 STX P                  \ X and P when called, but they set X = P = nosev_x_lo

 LDA INWK+1,Y           \ Set A = -nosev_x_hi
 EOR #%10000000

 JSR MAD                \ Set (A X) = Q * A + (S R)
 STA INWK+3,Y           \           = alpha * -nosev_x_hi + nosev_y
 STX INWK+2,Y           \
                        \ and store (A X) in nosev_y, so this does:
                        \
                        \ nosev_y = nosev_y - alpha * nosev_x_hi

 STX P                  \ This instruction has no effect as MAD overwrites P,
                        \ but it sets P = nosev_y_lo

 LDX INWK,Y             \ Set (S R) = nosev_x
 STX R
 LDX INWK+1,Y
 STX S

 LDA INWK+3,Y           \ Set A = nosev_y_hi

 JSR MAD                \ Set (A X) = Q * A + (S R)
 STA INWK+1,Y           \           = alpha * nosev_y_hi + nosev_x
 STX INWK,Y             \
                        \ and store (A X) in nosev_x, so this does:
                        \
                        \ nosev_x = nosev_x + alpha * nosev_y_hi

 STX P                  \ This instruction has no effect as MAD overwrites P,
                        \ but it sets P = nosev_x_lo

 LDA BETA               \ Set Q = beta (the pitch angle to rotate through)
 STA Q

 LDX INWK+2,Y           \ Set (S R) = nosev_y
 STX R
 LDX INWK+3,Y
 STX S
 LDX INWK+4,Y

 STX P                  \ This instruction has no effect as MAD overwrites P,
                        \ but it sets P = nosev_y

 LDA INWK+5,Y           \ Set A = -nosev_z_hi
 EOR #%10000000

 JSR MAD                \ Set (A X) = Q * A + (S R)
 STA INWK+3,Y           \           = beta * -nosev_z_hi + nosev_y
 STX INWK+2,Y           \
                        \ and store (A X) in nosev_y, so this does:
                        \
                        \ nosev_y = nosev_y - beta * nosev_z_hi

 STX P                  \ This instruction has no effect as MAD overwrites P,
                        \ but it sets P = nosev_y_lo

 LDX INWK+4,Y           \ Set (S R) = nosev_z
 STX R
 LDX INWK+5,Y
 STX S

 LDA INWK+3,Y           \ Set A = nosev_y_hi

 JSR MAD                \ Set (A X) = Q * A + (S R)
 STA INWK+5,Y           \           = beta * nosev_y_hi + nosev_z
 STX INWK+4,Y           \
                        \ and store (A X) in nosev_z, so this does:
                        \
                        \ nosev_z = nosev_z + beta * nosev_y_hi

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MVS5
\       Type: Subroutine
\   Category: Moving
\    Summary: Apply a 3.6 degree pitch or roll to an orientation vector
\  Deep dive: Orientation vectors
\             Pitching and rolling by a fixed angle
\
\ ------------------------------------------------------------------------------
\
\ Pitch or roll a ship by a small, fixed amount (1/16 radians, or 3.6 degrees),
\ in a specified direction, by rotating the orientation vectors. The vectors to
\ rotate are given in X and Y, and the direction of the rotation is given in
\ RAT2. The calculation is as follows:
\
\   * If the direction is positive:
\
\     X = X * (1 - 1/512) + Y / 16
\     Y = Y * (1 - 1/512) - X / 16
\
\   * If the direction is negative:
\
\     X = X * (1 - 1/512) - Y / 16
\     Y = Y * (1 - 1/512) + X / 16
\
\ So if X = 15 (roofv_x), Y = 21 (sidev_x) and RAT2 is positive, it does this:
\
\   roofv_x = roofv_x * (1 - 1/512)  + sidev_x / 16
\   sidev_x = sidev_x * (1 - 1/512)  - roofv_x / 16
\
\ Arguments:
\
\   X                   The first vector to rotate:
\
\                         * If X = 15, rotate roofv_x
\
\                         * If X = 17, rotate roofv_y
\
\                         * If X = 19, rotate roofv_z
\
\                         * If X = 21, rotate sidev_x
\
\                         * If X = 23, rotate sidev_y
\
\                         * If X = 25, rotate sidev_z
\
\   Y                   The second vector to rotate:
\
\                         * If Y = 9,  rotate nosev_x
\
\                         * If Y = 11, rotate nosev_y
\
\                         * If Y = 13, rotate nosev_z
\
\                         * If Y = 21, rotate sidev_x
\
\                         * If Y = 23, rotate sidev_y
\
\                         * If Y = 25, rotate sidev_z
\
\   RAT2                The direction of the pitch or roll to perform, positive
\                       or negative (i.e. the sign of the roll or pitch counter
\                       in bit 7)
\
\ ******************************************************************************

.MVS5

 LDA INWK+1,X           \ Fetch roofv_x_hi, clear the sign bit, divide by 2 and
 AND #%01111111         \ store in T, so:
 LSR A                  \
 STA T                  \ T = |roofv_x_hi| / 2
                        \   = |roofv_x| / 512
                        \
                        \ The above is true because:
                        \
                        \ |roofv_x| = |roofv_x_hi| * 256 + roofv_x_lo
                        \
                        \ so:
                        \
                        \ |roofv_x| / 512 = |roofv_x_hi| * 256 / 512
                        \                    + roofv_x_lo / 512
                        \                  = |roofv_x_hi| / 2

 LDA INWK,X             \ Now we do the following subtraction:
 SEC                    \
 SBC T                  \ (S R) = (roofv_x_hi roofv_x_lo) - |roofv_x| / 512
 STA R                  \       = (1 - 1/512) * roofv_x
                        \
                        \ by doing the low bytes first

 LDA INWK+1,X           \ And then the high bytes (the high byte of the right
 SBC #0                 \ side of the subtraction being 0)
 STA S

 LDA INWK,Y             \ Set P = nosev_x_lo
 STA P

 LDA INWK+1,Y           \ Fetch the sign of nosev_x_hi (bit 7) and store in T
 AND #%10000000
 STA T

 LDA INWK+1,Y           \ Fetch nosev_x_hi into A and clear the sign bit, so
 AND #%01111111         \ A = |nosev_x_hi|

 LSR A                  \ Set (A P) = (A P) / 16
 ROR P                  \           = |nosev_x_hi nosev_x_lo| / 16
 LSR A                  \           = |nosev_x| / 16
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P

 ORA T                  \ Set the sign of A to the sign in T (i.e. the sign of
                        \ the original nosev_x), so now:
                        \
                        \ (A P) = nosev_x / 16

 EOR RAT2               \ Give it the sign as if we multiplied by the direction
                        \ by the pitch or roll direction

 STX Q                  \ Store the value of X so it can be restored after the
                        \ call to ADD

 JSR ADD                \ (A X) = (A P) + (S R)
                        \       = +/-nosev_x / 16 + (1 - 1/512) * roofv_x

 STA K+1                \ Set K(1 0) = (1 - 1/512) * roofv_x +/- nosev_x / 16
 STX K

 LDX Q                  \ Restore the value of X from before the call to ADD

 LDA INWK+1,Y           \ Fetch nosev_x_hi, clear the sign bit, divide by 2 and
 AND #%01111111         \ store in T, so:
 LSR A                  \
 STA T                  \ T = |nosev_x_hi| / 2
                        \   = |nosev_x| / 512

 LDA INWK,Y             \ Now we do the following subtraction:
 SEC                    \
 SBC T                  \ (S R) = (nosev_x_hi nosev_x_lo) - |nosev_x| / 512
 STA R                  \       = (1 - 1/512) * nosev_x
                        \
                        \ by doing the low bytes first

 LDA INWK+1,Y           \ And then the high bytes (the high byte of the right
 SBC #0                 \ side of the subtraction being 0)
 STA S

 LDA INWK,X             \ Set P = roofv_x_lo
 STA P

 LDA INWK+1,X           \ Fetch the sign of roofv_x_hi (bit 7) and store in T
 AND #%10000000
 STA T

 LDA INWK+1,X           \ Fetch roofv_x_hi into A and clear the sign bit, so
 AND #%01111111         \ A = |roofv_x_hi|

 LSR A                  \ Set (A P) = (A P) / 16
 ROR P                  \           = |roofv_x_hi roofv_x_lo| / 16
 LSR A                  \           = |roofv_x| / 16
 ROR P
 LSR A
 ROR P
 LSR A
 ROR P

 ORA T                  \ Set the sign of A to the opposite sign to T (i.e. the
 EOR #%10000000         \ sign of the original -roofv_x), so now:
                        \
                        \ (A P) = -roofv_x / 16

 EOR RAT2               \ Give it the sign as if we multiplied by the direction
                        \ by the pitch or roll direction

 STX Q                  \ Store the value of X so it can be restored after the
                        \ call to ADD

 JSR ADD                \ (A X) = (A P) + (S R)
                        \       = -/+roofv_x / 16 + (1 - 1/512) * nosev_x

 STA INWK+1,Y           \ Set nosev_x = (1-1/512) * nosev_x -/+ roofv_x / 16
 STX INWK,Y

 LDX Q                  \ Restore the value of X from before the call to ADD

 LDA K                  \ Set roofv_x = K(1 0)
 STA INWK,X             \              = (1-1/512) * roofv_x +/- nosev_x / 16
 LDA K+1
 STA INWK+1,X

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: UNIV
\       Type: Variable
\   Category: Universe
\    Summary: Table of pointers to the local universe's ship data blocks
\  Deep dive: The local bubble of universe
\
\ ------------------------------------------------------------------------------
\
\ See the deep dive on "Ship data blocks" for details on ship data blocks, and
\ the deep dive on "The local bubble of universe" for details of how Elite
\ stores the local universe in K%, FRIN and UNIV.
\
\ ******************************************************************************

.UNIV

FOR I%, 0, NOSH
  EQUW K% + I% * NI%    \ Address of block no. I%, of size NI%, in workspace K%
NEXT

\ ******************************************************************************
\
\ Save output/ELTA.bin
\
\ ******************************************************************************

PRINT "ELITE A"
PRINT "Assembled at ", ~CODE%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_A%

PRINT "S.F.ELTA ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_A%
\SAVE "output/F.ELTA.bin", CODE%, P%, LOAD%

\ ******************************************************************************
\
\ ELITE B FILE
\
\ ******************************************************************************

CODE_B% = P%
LOAD_B% = LOAD% + P% - CODE%

\ ******************************************************************************
\
\       Name: TWOS
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Ready-made single-pixel character row bytes for mode 4
\  Deep dive: Drawing monochrome pixels in mode 4
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting one-pixel points in mode 4 (the top part of the
\ split screen). See the PIXEL routine for details.
\
\ ******************************************************************************

.TWOS

 EQUB %10000000
 EQUB %01000000
 EQUB %00100000
 EQUB %00010000
 EQUB %00001000
 EQUB %00000100
 EQUB %00000010
 EQUB %00000001

\ ******************************************************************************
\
\       Name: TWOS2
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Ready-made double-pixel character row bytes for mode 4
\  Deep dive: Drawing monochrome pixels in mode 4
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting two-pixel dashes in mode 4 (the top part of the
\ split screen). See the PIXEL routine for details.
\
\ ******************************************************************************

.TWOS2

 EQUB %11000000
 EQUB %01100000
 EQUB %00110000
 EQUB %00011000
 EQUB %00001100
 EQUB %00000110
 EQUB %00000011
 EQUB %00000011

\ ******************************************************************************
\
\       Name: CTWOS
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Ready-made single-pixel character row bytes for mode 5
\  Deep dive: Drawing colour pixels in mode 5
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting one-pixel points in mode 5 (the bottom part of
\ the split screen). See the dashboard routines SCAN, DIL2 and CPIX2 for
\ details.
\
\ ******************************************************************************

.CTWOS

 EQUB %10001000
 EQUB %01000100
 EQUB %00100010
 EQUB %00010001

\ ******************************************************************************
\
\       Name: LOIN (Part 1 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a line: Calculate the line gradient in the form of deltas
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ This stage calculates the line deltas.
\
\ Arguments:
\
\   X1                  The screen x-coordinate of the start of the line
\
\   Y1                  The screen y-coordinate of the start of the line
\
\   X2                  The screen x-coordinate of the end of the line
\
\   Y2                  The screen y-coordinate of the end of the line
\
\ Returns:
\
\   Y                   Y is preserved
\
\ Other entry points:
\
\   LL30                LL30 is a synonym for LOIN and draws a line from
\                       (X1, Y1) to (X2, Y2)
\
\   HL6                 Contains an RTS
\
\ ******************************************************************************

.LL30

 SKIP 0                 \ LL30 is a synomym for LOIN
                        \
                        \ In the cassette and disc versions of Elite, LL30 and
                        \ LOIN are synonyms for the same routine, presumably
                        \ because the two developers each had their own line
                        \ routines to start with, and then chose one of them for
                        \ the final game

.LOIN

 STY YSAV               \ Store Y into YSAV, so we can preserve it across the
                        \ call to this subroutine

 LDA #128               \ Set S = 128, which is the starting point for the
 STA S                  \ slope error (representing half a pixel)

 ASL A                  \ Set SWAP = 0, as %10000000 << 1 = 0
 STA SWAP

 LDA X2                 \ Set A = X2 - X1
 SBC X1                 \       = delta_x
                        \
                        \ This subtraction works as the ASL A above sets the C
                        \ flag

 BCS LI1                \ If X2 > X1 then A is already positive and we can skip
                        \ the next three instructions

 EOR #%11111111         \ Negate the result in A by flipping all the bits and
 ADC #1                 \ adding 1, i.e. using two's complement to make it
                        \ positive

 SEC                    \ Set the C flag, ready for the subtraction below

.LI1

 STA P                  \ Store A in P, so P = |X2 - X1|, or |delta_x|

 LDA Y2                 \ Set A = Y2 - Y1
 SBC Y1                 \       = delta_y
                        \
                        \ This subtraction works as we either set the C flag
                        \ above, or we skipped that SEC instruction with a BCS

 BCS LI2                \ If Y2 > Y1 then A is already positive and we can skip
                        \ the next two instructions

 EOR #%11111111         \ Negate the result in A by flipping all the bits and
 ADC #1                 \ adding 1, i.e. using two's complement to make it
                        \ positive

.LI2

 STA Q                  \ Store A in Q, so Q = |Y2 - Y1|, or |delta_y|

 CMP P                  \ If Q < P, jump to STPX to step along the x-axis, as
 BCC STPX               \ the line is closer to being horizontal than vertical

 JMP STPY               \ Otherwise Q >= P so jump to STPY to step along the
                        \ y-axis, as the line is closer to being vertical than
                        \ horizontal

\ ******************************************************************************
\
\       Name: LOIN (Part 2 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a line: Line has a shallow gradient, step right along x-axis
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * |delta_y| < |delta_x|
\
\   * The line is closer to being horizontal than vertical
\
\   * We are going to step right along the x-axis
\
\   * We potentially swap coordinates to make sure X1 < X2
\
\ ******************************************************************************

.STPX

 LDX X1                 \ Set X = X1

 CPX X2                 \ If X1 < X2, jump down to LI3, as the coordinates are
 BCC LI3                \ already in the order that we want

 DEC SWAP               \ Otherwise decrement SWAP from 0 to &FF, to denote that
                        \ we are swapping the coordinates around

 LDA X2                 \ Swap the values of X1 and X2
 STA X1
 STX X2

 TAX                    \ Set X = X1

 LDA Y2                 \ Swap the values of Y1 and Y2
 LDY Y1
 STA Y1
 STY Y2

.LI3

                        \ By this point we know the line is horizontal-ish and
                        \ X1 < X2, so we're going from left to right as we go
                        \ from X1 to X2

 LDA Y1                 \ Set A = Y1 / 8, so A now contains the character row
 LSR A                  \ that will contain our horizontal line
 LSR A
 LSR A

 ORA #&60               \ As A < 32, this effectively adds &60 to A, which gives
                        \ us the screen address of the character row (as each
                        \ character row takes up 256 bytes, and the first
                        \ character row is at screen address &6000, or page &60)

 STA SCH                \ Store the page number of the character row in SCH, so
                        \ the high byte of SC is set correctly for drawing the
                        \ start of our line

 LDA Y1                 \ Set Y = Y1 mod 8, which is the pixel row within the
 AND #7                 \ character block at which we want to draw the start of
 TAY                    \ our line (as each character block has 8 rows)

 TXA                    \ Set A = bits 3-7 of X1
 AND #%11111000

 STA SC                 \ Store this value in SC, so SC(1 0) now contains the
                        \ screen address of the far left end (x-coordinate = 0)
                        \ of the horizontal pixel row that we want to draw the
                        \ start of our line on

 TXA                    \ Set X = X1 mod 8, which is the horizontal pixel number
 AND #7                 \ within the character block where the line starts (as
 TAX                    \ each pixel line in the character block is 8 pixels
                        \ wide)

 LDA TWOS,X             \ Fetch a 1-pixel byte from TWOS where pixel X is set,
 STA R                  \ and store it in R

                        \ The following calculates:
                        \
                        \   Q = Q / P
                        \     = |delta_y| / |delta_x|
                        \
                        \ using the same shift-and-subtract algorithm that's
                        \ documented in TIS2

 LDA Q                  \ Set A = |delta_y|

 LDX #%11111110         \ Set Q to have bits 1-7 set, so we can rotate through 7
 STX Q                  \ loop iterations, getting a 1 each time, and then
                        \ getting a 0 on the 8th iteration... and we can also
                        \ use Q to catch our result bits into bit 0 each time

.LIL1

 ASL A                  \ Shift A to the left

 BCS LI4                \ If bit 7 of A was set, then jump straight to the
                        \ subtraction

 CMP P                  \ If A < P, skip the following subtraction
 BCC LI5

.LI4

 SBC P                  \ A >= P, so set A = A - P

 SEC                    \ Set the C flag to rotate into the result in Q

.LI5

 ROL Q                  \ Rotate the counter in Q to the left, and catch the
                        \ result bit into bit 0 (which will be a 0 if we didn't
                        \ do the subtraction, or 1 if we did)

 BCS LIL1               \ If we still have set bits in Q, loop back to TIL2 to
                        \ do the next iteration of 7

                        \ We now have:
                        \
                        \   Q = A / P
                        \     = |delta_y| / |delta_x|
                        \
                        \ and the C flag is clear

 LDX P                  \ Set X = P + 1
 INX                    \       = |delta_x| + 1
                        \
                        \ We add 1 so we can skip the first pixel plot if the
                        \ line is being drawn with swapped coordinates

 LDA Y2                 \ Set A = Y2 - Y1 - 1 (as the C flag is clear following
 SBC Y1                 \ the above division)

 BCS DOWN               \ If Y2 >= Y1 - 1 then jump to DOWN, as we need to draw
                        \ the line to the right and down

\ ******************************************************************************
\
\       Name: LOIN (Part 3 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a shallow line going right and up or left and down
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * The line is going right and up (no swap) or left and down (swap)
\
\   * X1 < X2 and Y1-1 > Y2
\
\   * Draw from (X1, Y1) at bottom left to (X2, Y2) at top right
\
\ ******************************************************************************

 LDA SWAP               \ If SWAP > 0 then we swapped the coordinates above, so
 BNE LI6                \ jump down to LI6 to skip plotting the first pixel

 DEX                    \ Decrement the counter in X because we're about to plot
                        \ the first pixel

.LIL2

                        \ We now loop along the line from left to right, using X
                        \ as a decreasing counter, and at each count we plot a
                        \ single pixel using the pixel mask in R

 LDA R                  \ Fetch the pixel byte from R

 EOR (SC),Y             \ Store R into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

.LI6

 LSR R                  \ Shift the single pixel in R to the right to step along
                        \ the x-axis, so the next pixel we plot will be at the
                        \ next x-coordinate along

 BCC LI7                \ If the pixel didn't fall out of the right end of R
                        \ into the C flag, then jump to LI7

 ROR R                  \ Otherwise we need to move over to the next character
                        \ block, so first rotate R right so the set C flag goes
                        \ back into the left end, giving %10000000

 LDA SC                 \ Add 8 to SC, so SC(1 0) now points to the next
 ADC #8                 \ character along to the right
 STA SC

.LI7

 LDA S                  \ Set S = S + Q to update the slope error
 ADC Q
 STA S

 BCC LIC2               \ If the addition didn't overflow, jump to LIC2

 DEY                    \ Otherwise we just overflowed, so decrement Y to move
                        \ to the pixel line above

 BPL LIC2               \ If Y is positive we are still within the same
                        \ character block, so skip to LIC2

 DEC SCH                \ Otherwise we need to move up into the character block
 LDY #7                 \ above, so decrement the high byte of the screen
                        \ address and set the pixel line to the last line in
                        \ that character block

.LIC2

 DEX                    \ Decrement the counter in X

 BNE LIL2               \ If we haven't yet reached the right end of the line,
                        \ loop back to LIL2 to plot the next pixel along

 LDY YSAV               \ Restore Y from YSAV, so that it's preserved

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LOIN (Part 4 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a shallow line going right and down or left and up
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * The line is going right and down (no swap) or left and up (swap)
\
\   * X1 < X2 and Y1-1 <= Y2
\
\   * Draw from (X1, Y1) at top left to (X2, Y2) at bottom right
\
\ ******************************************************************************

.DOWN

 LDA SWAP               \ If SWAP = 0 then we didn't swap the coordinates above,
 BEQ LI9                \ so jump down to LI9 to skip plotting the first pixel

 DEX                    \ Decrement the counter in X because we're about to plot
                        \ the first pixel

.LIL3

                        \ We now loop along the line from left to right, using X
                        \ as a decreasing counter, and at each count we plot a
                        \ single pixel using the pixel mask in R

 LDA R                  \ Fetch the pixel byte from R

 EOR (SC),Y             \ Store R into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

.LI9

 LSR R                  \ Shift the single pixel in R to the right to step along
                        \ the x-axis, so the next pixel we plot will be at the
                        \ next x-coordinate along

 BCC LI10               \ If the pixel didn't fall out of the right end of R
                        \ into the C flag, then jump to LI10

 ROR R                  \ Otherwise we need to move over to the next character
                        \ block, so first rotate R right so the set C flag goes
                        \ back into the left end, giving %10000000

 LDA SC                 \ Add 8 to SC, so SC(1 0) now points to the next
 ADC #8                 \ character along to the right
 STA SC

.LI10

 LDA S                  \ Set S = S + Q to update the slope error
 ADC Q
 STA S

 BCC LIC3               \ If the addition didn't overflow, jump to LIC3

 INY                    \ Otherwise we just overflowed, so increment Y to move
                        \ to the pixel line below

 CPY #8                 \ If Y < 8 we are still within the same character block,
 BNE LIC3               \ so skip to LIC3

 INC SCH                \ Otherwise we need to move down into the character
 LDY #0                 \ block below, so increment the high byte of the screen
                        \ address and set the pixel line to the first line in
                        \ that character block

.LIC3

 DEX                    \ Decrement the counter in X

 BNE LIL3               \ If we haven't yet reached the right end of the line,
                        \ loop back to LIL3 to plot the next pixel along

 LDY YSAV               \ Restore Y from YSAV, so that it's preserved

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LOIN (Part 5 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a line: Line has a steep gradient, step up along y-axis
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * |delta_y| >= |delta_x|
\
\   * The line is closer to being vertical than horizontal
\
\   * We are going to step up along the y-axis
\
\   * We potentially swap coordinates to make sure Y1 >= Y2
\
\ ******************************************************************************

.STPY

 LDY Y1                 \ Set A = Y = Y1
 TYA

 LDX X1                 \ Set X = X1

 CPY Y2                 \ If Y1 >= Y2, jump down to LI15, as the coordinates are
 BCS LI15               \ already in the order that we want

 DEC SWAP               \ Otherwise decrement SWAP from 0 to &FF, to denote that
                        \ we are swapping the coordinates around

 LDA X2                 \ Swap the values of X1 and X2
 STA X1
 STX X2

 TAX                    \ Set X = X1

 LDA Y2                 \ Swap the values of Y1 and Y2
 STA Y1
 STY Y2

 TAY                    \ Set Y = A = Y1

.LI15

                        \ By this point we know the line is vertical-ish and
                        \ Y1 >= Y2, so we're going from top to bottom as we go
                        \ from Y1 to Y2

 LSR A                  \ Set A = Y1 / 8, so A now contains the character row
 LSR A                  \ that will contain our horizontal line
 LSR A

 ORA #&60               \ As A < 32, this effectively adds &60 to A, which gives
                        \ us the screen address of the character row (as each
                        \ character row takes up 256 bytes, and the first
                        \ character row is at screen address &6000, or page &60)

 STA SCH                \ Store the page number of the character row in SCH, so
                        \ the high byte of SC is set correctly for drawing the
                        \ start of our line

 TXA                    \ Set A = bits 3-7 of X1
 AND #%11111000

 STA SC                 \ Store this value in SC, so SC(1 0) now contains the
                        \ screen address of the far left end (x-coordinate = 0)
                        \ of the horizontal pixel row that we want to draw the
                        \ start of our line on

 TXA                    \ Set X = X1 mod 8, which is the horizontal pixel number
 AND #7                 \ within the character block where the line starts (as
 TAX                    \ each pixel line in the character block is 8 pixels
                        \ wide)

 LDA TWOS,X             \ Fetch a 1-pixel byte from TWOS where pixel X is set,
 STA R                  \ and store it in R

 LDA Y1                 \ Set Y = Y1 mod 8, which is the pixel row within the
 AND #7                 \ character block at which we want to draw the start of
 TAY                    \ our line (as each character block has 8 rows)

                        \ The following calculates:
                        \
                        \   P = P / Q
                        \     = |delta_x| / |delta_y|
                        \
                        \ using the same shift-and-subtract algorithm
                        \ documented in TIS2

 LDA P                  \ Set A = |delta_x|

 LDX #1                 \ Set Q to have bits 1-7 clear, so we can rotate through
 STX P                  \ 7 loop iterations, getting a 1 each time, and then
                        \ getting a 1 on the 8th iteration... and we can also
                        \ use P to catch our result bits into bit 0 each time

.LIL4

 ASL A                  \ Shift A to the left

 BCS LI13               \ If bit 7 of A was set, then jump straight to the
                        \ subtraction

 CMP Q                  \ If A < Q, skip the following subtraction
 BCC LI14

.LI13

 SBC Q                  \ A >= Q, so set A = A - Q

 SEC                    \ Set the C flag to rotate into the result in Q

.LI14

 ROL P                  \ Rotate the counter in P to the left, and catch the
                        \ result bit into bit 0 (which will be a 0 if we didn't
                        \ do the subtraction, or 1 if we did)

 BCC LIL4               \ If we still have set bits in P, loop back to TIL2 to
                        \ do the next iteration of 7

                        \ We now have:
                        \
                        \   P = A / Q
                        \     = |delta_x| / |delta_y|
                        \
                        \ and the C flag is set

 LDX Q                  \ Set X = Q + 1
 INX                    \       = |delta_y| + 1
                        \
                        \ We add 1 so we can skip the first pixel plot if the
                        \ line is being drawn with swapped coordinates

 LDA X2                 \ Set A = X2 - X1 (the C flag is set as we didn't take
 SBC X1                 \ the above BCC)

 BCC LFT                \ If X2 < X1 then jump to LFT, as we need to draw the
                        \ line to the left and down

\ ******************************************************************************
\
\       Name: LOIN (Part 6 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a steep line going up and left or down and right
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * The line is going up and left (no swap) or down and right (swap)
\
\   * X1 < X2 and Y1 >= Y2
\
\   * Draw from (X1, Y1) at top left to (X2, Y2) at bottom right
\
\ ******************************************************************************

 CLC                    \ Clear the C flag

 LDA SWAP               \ If SWAP = 0 then we didn't swap the coordinates above,
 BEQ LI17               \ so jump down to LI17 to skip plotting the first pixel

 DEX                    \ Decrement the counter in X because we're about to plot
                        \ the first pixel

.LIL5

                        \ We now loop along the line from left to right, using X
                        \ as a decreasing counter, and at each count we plot a
                        \ single pixel using the pixel mask in R

 LDA R                  \ Fetch the pixel byte from R

 EOR (SC),Y             \ Store R into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

.LI17

 DEY                    \ Decrement Y to step up along the y-axis

 BPL LI16               \ If Y is positive we are still within the same
                        \ character block, so skip to LI16

 DEC SCH                \ Otherwise we need to move up into the character block
 LDY #7                 \ above, so decrement the high byte of the screen
                        \ address and set the pixel line to the last line in
                        \ that character block

.LI16

 LDA S                  \ Set S = S + Q to update the slope error
 ADC P
 STA S

 BCC LIC5               \ If the addition didn't overflow, jump to LIC5

 LSR R                  \ Otherwise we just overflowed, so shift the single
                        \ pixel in R to the right, so the next pixel we plot
                        \ will be at the next x-coordinate along

 BCC LIC5               \ If the pixel didn't fall out of the right end of R
                        \ into the C flag, then jump to LIC5

 ROR R                  \ Otherwise we need to move over to the next character
                        \ block, so first rotate R right so the set C flag goes
                        \ back into the left end, giving %10000000

 LDA SC                 \ Add 8 to SC, so SC(1 0) now points to the next
 ADC #8                 \ character along to the right
 STA SC

.LIC5

 DEX                    \ Decrement the counter in X

 BNE LIL5               \ If we haven't yet reached the right end of the line,
                        \ loop back to LIL5 to plot the next pixel along

 LDY YSAV               \ Restore Y from YSAV, so that it's preserved

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LOIN (Part 7 of 7)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a steep line going up and right or down and left
\  Deep dive: Bresenham's line algorithm
\
\ ------------------------------------------------------------------------------
\
\ This routine draws a line from (X1, Y1) to (X2, Y2). It has multiple stages.
\ If we get here, then:
\
\   * The line is going up and right (no swap) or down and left (swap)
\
\   * X1 >= X2 and Y1 >= Y2
\
\   * Draw from (X1, Y1) at bottom left to (X2, Y2) at top right
\
\ ******************************************************************************

.LFT

 LDA SWAP               \ If SWAP = 0 then we didn't swap the coordinates above,
 BEQ LI18               \ jump down to LI18 to skip plotting the first pixel

 DEX                    \ Decrement the counter in X because we're about to plot
                        \ the first pixel

.LIL6

 LDA R                  \ Fetch the pixel byte from R

 EOR (SC),Y             \ Store R into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen

.LI18

 DEY                    \ Decrement Y to step up along the y-axis

 BPL LI19               \ If Y is positive we are still within the same
                        \ character block, so skip to LI19

 DEC SCH                \ Otherwise we need to move up into the character block
 LDY #7                 \ above, so decrement the high byte of the screen
                        \ address and set the pixel line to the last line in
                        \ that character block

.LI19

 LDA S                  \ Set S = S + P to update the slope error
 ADC P
 STA S

 BCC LIC6               \ If the addition didn't overflow, jump to LIC6

 ASL R                  \ Otherwise we just overflowed, so shift the single
                        \ pixel in R to the left, so the next pixel we plot
                        \ will be at the previous x-coordinate

 BCC LIC6               \ If the pixel didn't fall out of the left end of R
                        \ into the C flag, then jump to LIC6

 ROL R                  \ Otherwise we need to move over to the next character
                        \ block, so first rotate R left so the set C flag goes
                        \ back into the right end, giving %0000001

 LDA SC                 \ Subtract 7 from SC, so SC(1 0) now points to the
 SBC #7                 \ previous character along to the left
 STA SC

 CLC                    \ Clear the C flag so it doesn't affect the additions
                        \ below

.LIC6

 DEX                    \ Decrement the counter in X

 BNE LIL6               \ If we haven't yet reached the left end of the line,
                        \ loop back to LIL6 to plot the next pixel along

 LDY YSAV               \ Restore Y from YSAV, so that it's preserved

.HL6

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: FLKB
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Flush the keyboard buffer
\
\ ******************************************************************************

.FLKB

 LDA #15                \ Call OSBYTE with A = 15 and Y <> 0 to flush the input
 TAX                    \ buffers (i.e. flush the operating system's keyboard
 JMP OSBYTE             \ buffer) and return from the subroutine using a tail
                        \ call

\ ******************************************************************************
\
\       Name: NLIN3
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Print a title and a horizontal line at row 19 to box it in
\
\ ------------------------------------------------------------------------------
\
\ This routine print a text token at the cursor position and draws a horizontal
\ line at pixel row 19. It is used for the Status Mode screen, the Short-range
\ Chart, the Market Price screen and the Equip Ship screen.
\
\ ******************************************************************************

.NLIN3

 JSR TT27               \ Print the text token in A

                        \ Fall through into NLIN4 to draw a horizontal line at
                        \ pixel row 19

\ ******************************************************************************
\
\       Name: NLIN4
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a horizontal line at pixel row 19 to box in a title
\
\ ------------------------------------------------------------------------------
\
\ This routine is used on the Inventory screen to draw a horizontal line at
\ pixel row 19 to box in the title.
\
\ ******************************************************************************

.NLIN4

 LDA #19                \ Jump to NLIN2 to draw a horizontal line at pixel row
 BNE NLIN2              \ 19, returning from the subroutine with using a tail
                        \ call (this BNE is effectively a JMP as A will never
                        \ be zero)

\ ******************************************************************************
\
\       Name: NLIN
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a horizontal line at pixel row 23 to box in a title
\
\ ------------------------------------------------------------------------------
\
\ Draw a horizontal line at pixel row 23 and move the text cursor down one
\ line.
\
\ ******************************************************************************

.NLIN

 LDA #23                \ Set A = 23 so NLIN2 below draws a horizontal line at
                        \ pixel row 23

 INC YC                 \ Move the text cursor down one line

                        \ Fall through into NLIN2 to draw the horizontal line
                        \ at row 23

\ ******************************************************************************
\
\       Name: NLIN2
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a screen-wide horizontal line at the pixel row in A
\
\ ------------------------------------------------------------------------------
\
\ This draws a line from (2, A) to (254, A), which is almost screen-wide and
\ fits in nicely between the white borders without clashing with it.
\
\ Arguments:
\
\   A                   The pixel row on which to draw the horizontal line
\
\ ******************************************************************************

.NLIN2

 STA Y1                 \ Set Y1 = A

 LDX #2                 \ Set X1 = 2, so (X1, Y1) = (2, A)
 STX X1

 LDX #254               \ Set X2 = 254, so (X2, Y2) = (254, A)
 STX X2

 BNE HLOIN              \ Call HLOIN to draw a horizontal line from (2, A) to
                        \ (254, A) and return from the subroutine (this BNE is
                        \ effectively a JMP as A will never be zero)

\ ******************************************************************************
\
\       Name: HLOIN2
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Remove a line from the sun line heap and draw it on-screen
\
\ ------------------------------------------------------------------------------
\
\ Specifically, this does the following:
\
\   * Set X1 and X2 to the x-coordinates of the ends of the horizontal line with
\     centre YY(1 0) and length A to the left and right
\
\   * Set the Y-th byte of the LSO block to 0 (i.e. remove this line from the
\     sun line heap)
\
\   * Draw a horizontal line from (X1, Y) to (X2, Y)
\
\ Arguments:
\
\   YY(1 0)             The x-coordinate of the centre point of the line
\
\   A                   The half-width of the line, i.e. the contents of the
\                       Y-th byte of the sun line heap
\
\   Y                   The number of the entry in the sun line heap (which is
\                       also the y-coordinate of the line)
\
\ Returns:
\
\   Y                   Y is preserved
\
\ ******************************************************************************

.HLOIN2

 JSR EDGES              \ Call EDGES to calculate X1 and X2 for the horizontal
                        \ line centred on YY(1 0) and with half-width A

 STY Y1                 \ Set Y1 = Y

 LDA #0                 \ Set the Y-th byte of the LSO block to 0
 STA LSO,Y

                        \ Fall through into HLOIN to draw a horizontal line from
                        \ (X1, Y) to (X2, Y)

\ ******************************************************************************
\
\       Name: HLOIN
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a horizontal line from (X1, Y1) to (X2, Y1)
\
\ ------------------------------------------------------------------------------
\
\ We do not draw a pixel at the end point (X2, X1).
\
\ To understand how this routine works, you might find it helpful to read the
\ deep dive on "Drawing monochrome pixels in mode 4".
\
\ Returns:
\
\   Y                   Y is preserved
\
\ ******************************************************************************

.HLOIN

 STY YSAV               \ Store Y into YSAV, so we can preserve it across the
                        \ call to this subroutine

 LDX X1                 \ Set X = X1

 CPX X2                 \ If X1 = X2 then the start and end points are the same,
 BEQ HL6                \ so return from the subroutine (as HL6 contains an RTS)

 BCC HL5                \ If X1 < X2, jump to HL5 to skip the following code, as
                        \ (X1, Y1) is already the left point

 LDA X2                 \ Swap the values of X1 and X2, so we know that (X1, Y1)
 STA X1                 \ is on the left and (X2, Y1) is on the right
 STX X2

 TAX                    \ Set X = X1

.HL5

 DEC X2                 \ Decrement X2 so we do not draw a pixel at the end
                        \ point

 LDA Y1                 \ Set A = Y1 / 8, so A now contains the character row
 LSR A                  \ that will contain our horizontal line
 LSR A
 LSR A

 ORA #&60               \ As A < 32, this effectively adds &60 to A, which gives
                        \ us the screen address of the character row (as each
                        \ character row takes up 256 bytes, and the first
                        \ character row is at screen address &6000, or page &60)

 STA SCH                \ Store the page number of the character row in SCH, so
                        \ the high byte of SC is set correctly for drawing our
                        \ line

 LDA Y1                 \ Set A = Y1 mod 8, which is the pixel row within the
 AND #7                 \ character block at which we want to draw our line (as
                        \ each character block has 8 rows)

 STA SC                 \ Store this value in SC, so SC(1 0) now contains the
                        \ screen address of the far left end (x-coordinate = 0)
                        \ of the horizontal pixel row that we want to draw our
                        \ horizontal line on

 TXA                    \ Set Y = bits 3-7 of X1
 AND #%11111000
 TAY

.HL1

 TXA                    \ Set T = bits 3-7 of X1, which will contain the
 AND #%11111000         \ the character number of the start of the line * 8
 STA T

 LDA X2                 \ Set A = bits 3-7 of X2, which will contain the
 AND #%11111000         \ the character number of the end of the line * 8

 SEC                    \ Set A = A - T, which will contain the number of
 SBC T                  \ character blocks we need to fill - 1 * 8

 BEQ HL2                \ If A = 0 then the start and end character blocks are
                        \ the same, so the whole line fits within one block, so
                        \ jump down to HL2 to draw the line

                        \ Otherwise the line spans multiple characters, so we
                        \ start with the left character, then do any characters
                        \ in the middle, and finish with the right character

 LSR A                  \ Set R = A / 8, so R now contains the number of
 LSR A                  \ character blocks we need to fill - 1
 LSR A
 STA R

 LDA X1                 \ Set X = X1 mod 8, which is the horizontal pixel number
 AND #7                 \ within the character block where the line starts (as
 TAX                    \ each pixel line in the character block is 8 pixels
                        \ wide)

 LDA TWFR,X             \ Fetch a ready-made byte with X pixels filled in at the
                        \ right end of the byte (so the filled pixels start at
                        \ point X and go all the way to the end of the byte),
                        \ which is the shape we want for the left end of the
                        \ line

 EOR (SC),Y             \ Store this into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen,
                        \ so we have now drawn the line's left cap

 TYA                    \ Set Y = Y + 8 so (SC),Y points to the next character
 ADC #8                 \ block along, on the same pixel row as before
 TAY

 LDX R                  \ Fetch the number of character blocks we need to fill
                        \ from R

 DEX                    \ Decrement the number of character blocks in X

 BEQ HL3                \ If X = 0 then we only have the last block to do (i.e.
                        \ the right cap), so jump down to HL3 to draw it

 CLC                    \ Otherwise clear the C flag so we can do some additions
                        \ while we draw the character blocks with full-width
                        \ lines in them

.HLL1

 LDA #%11111111         \ Store a full-width 8-pixel horizontal line in SC(1 0)
 EOR (SC),Y             \ so that it draws the line on-screen, using EOR logic
 STA (SC),Y             \ so it merges with whatever is already on-screen

 TYA                    \ Set Y = Y + 8 so (SC),Y points to the next character
 ADC #8                 \ block along, on the same pixel row as before
 TAY

 DEX                    \ Decrement the number of character blocks in X

 BNE HLL1               \ Loop back to draw more full-width lines, if we have
                        \ any more to draw

.HL3

 LDA X2                 \ Now to draw the last character block at the right end
 AND #7                 \ of the line, so set X = X2 mod 8, which is the
 TAX                    \ horizontal pixel number where the line ends

 LDA TWFL,X             \ Fetch a ready-made byte with X pixels filled in at the
                        \ left end of the byte (so the filled pixels start at
                        \ the left edge and go up to point X), which is the
                        \ shape we want for the right end of the line

 EOR (SC),Y             \ Store this into screen memory at SC(1 0), using EOR
 STA (SC),Y             \ logic so it merges with whatever is already on-screen,
                        \ so we have now drawn the line's right cap

 LDY YSAV               \ Restore Y from YSAV, so that it's preserved across the
                        \ call to this subroutine

 RTS                    \ Return from the subroutine

.HL2

                        \ If we get here then the entire horizontal line fits
                        \ into one character block

 LDA X1                 \ Set X = X1 mod 8, which is the horizontal pixel number
 AND #7                 \ within the character block where the line starts (as
 TAX                    \ each pixel line in the character block is 8 pixels
                        \ wide)

 LDA TWFR,X             \ Fetch a ready-made byte with X pixels filled in at the
 STA T                  \ right end of the byte (so the filled pixels start at
                        \ point X and go all the way to the end of the byte)

 LDA X2                 \ Set X = X2 mod 8, which is the horizontal pixel number
 AND #7                 \ where the line ends
 TAX

 LDA TWFL,X             \ Fetch a ready-made byte with X pixels filled in at the
                        \ left end of the byte (so the filled pixels start at
                        \ the left edge and go up to point X)

 AND T                  \ We now have two bytes, one (T) containing pixels from
                        \ the starting point X1 onwards, and the other (A)
                        \ containing pixels up to the end point at X2, so we can
                        \ get the actual line we want to draw by AND'ing them
                        \ together. For example, if we want to draw a line from
                        \ point 2 to point 5 (within the row of 8 pixels
                        \ numbered from 0 to 7), we would have this:
                        \
                        \   T       = %00111111
                        \   A       = %11111100
                        \   T AND A = %00111100
                        \
                        \ so if we stick T AND A in screen memory, that's what
                        \ we do here, setting A = A AND T

 EOR (SC),Y             \ Store our horizontal line byte into screen memory at
 STA (SC),Y             \ SC(1 0), using EOR logic so it merges with whatever is
                        \ already on-screen

 LDY YSAV               \ Restore Y from YSAV, so that it's preserved

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TWFL
\       Type: Variable
\   Category: Drawing lines
\    Summary: Ready-made character rows for the left end of a horizontal line in
\             mode 4
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting horizontal line end caps in mode 4 (the top part
\ of the split screen). This table provides a byte with pixels at the left end,
\ which is used for the right end of the line.
\
\ See the HLOIN routine for details.
\
\ ******************************************************************************

.TWFL

 EQUB %10000000
 EQUB %11000000
 EQUB %11100000
 EQUB %11110000
 EQUB %11111000
 EQUB %11111100
 EQUB %11111110

\ ******************************************************************************
\
\       Name: TWFR
\       Type: Variable
\   Category: Drawing lines
\    Summary: Ready-made character rows for the right end of a horizontal line
\             in mode 4
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting horizontal line end caps in mode 4 (the top part
\ of the split screen). This table provides a byte with pixels at the right end,
\ which is used for the left end of the line.
\
\ See the HLOIN routine for details.
\
\ ******************************************************************************

.TWFR

 EQUB %11111111
 EQUB %01111111
 EQUB %00111111
 EQUB %00011111
 EQUB %00001111
 EQUB %00000111
 EQUB %00000011
 EQUB %00000001

\ ******************************************************************************
\
\       Name: PX3
\       Type: Subroutine
\   Category: Drawing pixels
\    Summary: Plot a single pixel at (X, Y) within a character block
\
\ ------------------------------------------------------------------------------
\
\ This routine is called from PIXEL to set 1 pixel within a character block for
\ a distant point (i.e. where the distance ZZ >= &90). See the PIXEL routine for
\ details, as this routine is effectively part of PIXEL.
\
\ Arguments:
\
\   X                   The x-coordinate of the pixel within the character block
\
\   Y                   The y-coordinate of the pixel within the character block
\
\   SC(1 0)             The screen address of the character block
\
\   T1                  The value of Y to restore on exit, so Y is preserved by
\                       the call to PIXEL
\
\ ******************************************************************************

.PX3

 LDA TWOS,X             \ Fetch a 1-pixel byte from TWOS and EOR it into SC+Y
 EOR (SC),Y
 STA (SC),Y

 LDY T1                 \ Restore Y from T1, so Y is preserved by the routine

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PIXEL
\       Type: Subroutine
\   Category: Drawing pixels
\    Summary: Draw a 1-pixel dot, 2-pixel dash or 4-pixel square
\  Deep dive: Drawing monochrome pixels in mode 4
\
\ ------------------------------------------------------------------------------
\
\ Draw a point at screen coordinate (X, A) with the point size determined by the
\ distance in ZZ. This applies to the top part of the screen (the monochrome
\ mode 4 portion).
\
\ Arguments:
\
\   X                   The screen x-coordinate of the point to draw
\
\   A                   The screen y-coordinate of the point to draw
\
\   ZZ                  The distance of the point (further away = smaller point)
\
\ Returns:
\
\   Y                   Y is preserved
\
\ Other entry points:
\
\   PX4                 Contains an RTS
\
\ ******************************************************************************

.PIXEL

 STY T1                 \ Store Y in T1

 TAY                    \ Copy A into Y, for use later

 LSR A                  \ Set SCH = &60 + A >> 3
 LSR A
 LSR A
 ORA #&60
 STA SCH

 TXA                    \ Set SC = (X >> 3) * 8
 AND #%11111000
 STA SC

 TYA                    \ Set Y = Y AND %111
 AND #%00000111
 TAY

 TXA                    \ Set X = X AND %111
 AND #%00000111
 TAX

 LDA ZZ                 \ If distance in ZZ >= 144, then this point is a very
 CMP #144               \ long way away, so jump to PX3 to fetch a 1-pixel point
 BCS PX3                \ from TWOS and EOR it into SC+Y

 LDA TWOS2,X            \ Otherwise fetch a 2-pixel dash from TWOS2 and EOR it
 EOR (SC),Y             \ into SC+Y
 STA (SC),Y

 LDA ZZ                 \ If distance in ZZ >= 80, then this point is a medium
 CMP #80                \ distance away, so jump to PX13 to stop drawing, as a
 BCS PX13               \ 2-pixel dash is enough

                        \ Otherwise we keep going to draw another 2 pixel point
                        \ either above or below the one we just drew, to make a
                        \ 4-pixel square

 DEY                    \ Reduce Y by 1 to point to the pixel row above the one
 BPL PX14               \ we just plotted, and if it is still positive, jump to
                        \ PX14 to draw our second 2-pixel dash

 LDY #1                 \ Reducing Y by 1 made it negative, which means Y was
                        \ 0 before we did the DEY above, so set Y to 1 to point
                        \ to the pixel row after the one we just plotted

.PX14

 LDA TWOS2,X            \ Fetch a 2-pixel dash from TWOS2 and EOR it into this
 EOR (SC),Y             \ second row to make a 4-pixel square
 STA (SC),Y

.PX13

 LDY T1                 \ Restore Y from T1, so Y is preserved by the routine

.PX4

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: BLINE
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Draw a circle segment and add it to the ball line heap
\  Deep dive: The ball line heap
\             Drawing circles
\
\ ------------------------------------------------------------------------------
\
\ Draw a single segment of a circle, adding the point to the ball line heap.
\
\ Arguments:
\
\   CNT                 The number of this segment
\
\   STP                 The step size for the circle
\
\   K6(1 0)             The x-coordinate of the new point on the circle, as
\                       a screen coordinate
\
\   (T X)               The y-coordinate of the new point on the circle, as
\                       an offset from the centre of the circle
\
\   FLAG                Set to &FF for the first call, so it sets up the first
\                       point in the heap but waits until the second call before
\                       drawing anything (as we need two points, i.e. two calls,
\                       before we can draw a line)
\
\   K                   The circle's radius
\
\   K3(1 0)             Pixel x-coordinate of the centre of the circle
\
\   K4(1 0)             Pixel y-coordinate of the centre of the circle
\
\   SWAP                If non-zero, we swap (X1, Y1) and (X2, Y2)
\
\ Returns:
\
\   CNT                 CNT is updated to CNT + STP
\
\   A                   The new value of CNT
\
\   FLAG                Set to 0
\
\ ******************************************************************************

.BLINE

 TXA                    \ Set K6(3 2) = (T X) + K4(1 0)
 ADC K4                 \             = y-coord of centre + y-coord of new point
 STA K6+2               \
 LDA K4+1               \ so K6(3 2) now contains the y-coordinate of the new
 ADC T                  \ point on the circle but as a screen coordinate, to go
 STA K6+3               \ along with the screen y-coordinate in K6(1 0)

 LDA FLAG               \ If FLAG = 0, jump down to BL1
 BEQ BL1

 INC FLAG               \ Flag is &FF so this is the first call to BLINE, so
                        \ increment FLAG to set it to 0, as then the next time
                        \ we call BLINE it can draw the first line, from this
                        \ point to the next

.BL5

                        \ The following inserts a &FF marker into the LSY2 line
                        \ heap to indicate that the next call to BLINE should
                        \ store both the (X1, Y1) and (X2, Y2) points. We do
                        \ this on the very first call to BLINE (when FLAG is
                        \ &FF), and on subsequent calls if the segment does not
                        \ fit on-screen, in which case we don't draw or store
                        \ that segment, and we start a new segment with the next
                        \ call to BLINE that does fit on-screen

 LDY LSP                \ If byte LSP-1 of LSY2 = &FF, jump to BL7 to tidy up
 LDA #&FF               \ and return from the subroutine, as the point that has
 CMP LSY2-1,Y           \ been passed to BLINE is the start of a segment, so all
 BEQ BL7                \ we need to do is save the coordinate in K5, without
                        \ moving the pointer in LSP

 STA LSY2,Y             \ Otherwise we just tried to plot a segment but it
                        \ didn't fit on-screen, so put the &FF marker into the
                        \ heap for this point, so the next call to BLINE starts
                        \ a new segment

 INC LSP                \ Increment LSP to point to the next point in the heap

 BNE BL7                \ Jump to BL7 to tidy up and return from the subroutine
                        \ (this BNE is effectively a JMP, as LSP will never be
                        \ zero)

.BL1

 LDA K5                 \ Set XX15 = K5 = x_lo of previous point
 STA XX15

 LDA K5+1               \ Set XX15+1 = K5+1 = x_hi of previous point
 STA XX15+1

 LDA K5+2               \ Set XX15+2 = K5+2 = y_lo of previous point
 STA XX15+2

 LDA K5+3               \ Set XX15+3 = K5+3 = y_hi of previous point
 STA XX15+3

 LDA K6                 \ Set XX15+4 = x_lo of new point
 STA XX15+4

 LDA K6+1               \ Set XX15+5 = x_hi of new point
 STA XX15+5

 LDA K6+2               \ Set XX12 = y_lo of new point
 STA XX12

 LDA K6+3               \ Set XX12+1 = y_hi of new point
 STA XX12+1

 JSR LL145              \ Call LL145 to see if the new line segment needs to be
                        \ clipped to fit on-screen, returning the clipped line's
                        \ end-points in (X1, Y1) and (X2, Y2)

 BCS BL5                \ If the C flag is set then the line is not visible on
                        \ screen anyway, so jump to BL5, to avoid drawing and
                        \ storing this line

 LDA SWAP               \ If SWAP = 0, then we didn't have to swap the line
 BEQ BL9                \ coordinates around during the clipping process, so
                        \ jump to BL9 to skip the following swap

 LDA X1                 \ Otherwise the coordinates were swapped by the call to
 LDY X2                 \ LL145 above, so we swap (X1, Y1) and (X2, Y2) back
 STA X2                 \ again
 STY X1
 LDA Y1
 LDY Y2
 STA Y2
 STY Y1

.BL9

 LDY LSP                \ Set Y = LSP

 LDA LSY2-1,Y           \ If byte LSP-1 of LSY2 is not &FF, jump down to BL8
 CMP #&FF               \ to skip the following (X1, Y1) code
 BNE BL8

                        \ Byte LSP-1 of LSY2 is &FF, which indicates that we
                        \ need to store (X1, Y1) in the heap

 LDA X1                 \ Store X1 in the LSP-th byte of LSX2
 STA LSX2,Y

 LDA Y1                 \ Store Y1 in the LSP-th byte of LSY2
 STA LSY2,Y

 INY                    \ Increment Y to point to the next byte in LSX2/LSY2

.BL8

 LDA X2                 \ Store X2 in the LSP-th byte of LSX2
 STA LSX2,Y

 LDA Y2                 \ Store Y2 in the LSP-th byte of LSX2
 STA LSY2,Y

 INY                    \ Increment Y to point to the next byte in LSX2/LSY2

 STY LSP                \ Update LSP to point to the same as Y

 JSR LOIN               \ Draw a line from (X1, Y1) to (X2, Y2)

 LDA XX13               \ If XX13 is non-zero, jump up to BL5 to add a &FF
 BNE BL5                \ marker to the end of the line heap. XX13 is non-zero
                        \ after the call to the clipping routine LL145 above if
                        \ the end of the line was clipped, meaning the next line
                        \ sent to BLINE can't join onto the end but has to start
                        \ a new segment, and that's what inserting the &FF
                        \ marker does

.BL7

 LDA K6                 \ Copy the data for this step point from K6(3 2 1 0)
 STA K5                 \ into K5(3 2 1 0), for use in the next call to BLINE:
 LDA K6+1               \
 STA K5+1               \   * K5(1 0) = screen x-coordinate of this point
 LDA K6+2               \
 STA K5+2               \   * K5(3 2) = screen y-coordinate of this point
 LDA K6+3               \
 STA K5+3               \ They now become the "previous point" in the next call

 LDA CNT                \ Set CNT = CNT + STP
 CLC
 ADC STP
 STA CNT

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TENS
\       Type: Variable
\   Category: Text
\    Summary: A constant used when printing large numbers in BPRNT
\  Deep dive: Printing decimal numbers
\
\ ------------------------------------------------------------------------------
\
\ Contains the four low bytes of the value 100,000,000,000 (100 billion).
\
\ The maximum number of digits that we can print with the BPRNT routine is 11,
\ so the biggest number we can print is 99,999,999,999. This maximum number
\ plus 1 is 100,000,000,000, which in hexadecimal is:
\
\   & 17 48 76 E8 00
\
\ The TENS variable contains the lowest four bytes in this number, with the
\ most significant byte first, i.e. 48 76 E8 00. This value is used in the
\ BPRNT routine when working out which decimal digits to print when printing a
\ number.
\
\ ******************************************************************************

.TENS

 EQUD &00E87648

\ ******************************************************************************
\
\       Name: pr2
\       Type: Subroutine
\   Category: Text
\    Summary: Print an 8-bit number, left-padded to 3 digits, and optional point
\
\ ------------------------------------------------------------------------------
\
\ Print the 8-bit number in X to 3 digits, left-padding with spaces for numbers
\ with fewer than 3 digits (so numbers < 100 are right-aligned). Optionally
\ include a decimal point.
\
\ Arguments:
\
\   X                   The number to print
\
\   C flag              If set, include a decimal point
\
\ Other entry points:
\
\   pr2+2               Print the 8-bit number in X to the number of digits in A
\
\ ******************************************************************************

.pr2

 LDA #3                 \ Set A to the number of digits (3)

 LDY #0                 \ Zero the Y register, so we can fall through into TT11
                        \ to print the 16-bit number (Y X) to 3 digits, which
                        \ effectively prints X to 3 digits as the high byte is
                        \ zero

\ ******************************************************************************
\
\       Name: TT11
\       Type: Subroutine
\   Category: Text
\    Summary: Print a 16-bit number, left-padded to n digits, and optional point
\
\ ------------------------------------------------------------------------------
\
\ Print the 16-bit number in (Y X) to a specific number of digits, left-padding
\ with spaces for numbers with fewer digits (so lower numbers will be right-
\ aligned). Optionally include a decimal point.
\
\ Arguments:
\
\   X                   The low byte of the number to print
\
\   Y                   The high byte of the number to print
\
\   A                   The number of digits
\
\   C flag              If set, include a decimal point
\
\ ******************************************************************************

.TT11

 STA U                  \ We are going to use the BPRNT routine (below) to
                        \ print this number, so we store the number of digits
                        \ in U, as that's what BPRNT takes as an argument

 LDA #0                 \ BPRNT takes a 32-bit number in K to K+3, with the
 STA K                  \ most significant byte first (big-endian), so we set
 STA K+1                \ the two most significant bytes to zero (K and K+1)
 STY K+2                \ and store (Y X) in the least two significant bytes
 STX K+3                \ (K+2 and K+3), so we are going to print the 32-bit
                        \ number (0 0 Y X)

                        \ Finally we fall through into BPRNT to print out the
                        \ number in K to K+3, which now contains (Y X), to 3
                        \ digits (as U = 3), using the same C flag as when pr2
                        \ was called to control the decimal point

\ ******************************************************************************
\
\       Name: BPRNT
\       Type: Subroutine
\   Category: Text
\    Summary: Print a 32-bit number, left-padded to a specific number of digits,
\             with an optional decimal point
\  Deep dive: Printing decimal numbers
\
\ ------------------------------------------------------------------------------
\
\ Print the 32-bit number stored in K(0 1 2 3) to a specific number of digits,
\ left-padding with spaces for numbers with fewer digits (so lower numbers are
\ right-aligned). Optionally include a decimal point.
\
\ See the deep dive on "Printing decimal numbers" for details of the algorithm
\ used in this routine.
\
\ Arguments:
\
\   K(0 1 2 3)          The number to print, stored with the most significant
\                       byte in K and the least significant in K+3 (i.e. as a
\                       big-endian number, which is the opposite way to how the
\                       6502 assembler stores addresses, for example)
\
\   U                   The maximum number of digits to print, including the
\                       decimal point (spaces will be used on the left to pad
\                       out the result to this width, so the number is right-
\                       aligned to this width). U must be 11 or less
\
\   C flag              If set, include a decimal point followed by one
\                       fractional digit (i.e. show the number to 1 decimal
\                       place). In this case, the number in K(0 1 2 3) contains
\                       10 * the number we end up printing, so to print 123.4,
\                       we would pass 1234 in K(0 1 2 3) and would set the C
\                       flag to include the decimal point
\
\ ******************************************************************************

.BPRNT

 LDX #11                \ Set T to the maximum number of digits allowed (11
 STX T                  \ characters, which is the number of digits in 10
                        \ billion). We will use this as a flag when printing
                        \ characters in TT37 below

 PHP                    \ Make a copy of the status register (in particular
                        \ the C flag) so we can retrieve it later

 BCC TT30               \ If the C flag is clear, we do not want to print a
                        \ decimal point, so skip the next two instructions

 DEC T                  \ As we are going to show a decimal point, decrement
 DEC U                  \ both the number of characters and the number of
                        \ digits (as one of them is now a decimal point)

.TT30

 LDA #11                \ Set A to 11, the maximum number of digits allowed

 SEC                    \ Set the C flag so we can do subtraction without the
                        \ C flag affecting the result

 STA XX17               \ Store the maximum number of digits allowed (11) in
                        \ XX17

 SBC U                  \ Set U = 11 - U + 1, so U now contains the maximum
 STA U                  \ number of digits minus the number of digits we want
 INC U                  \ to display, plus 1 (so this is the number of digits
                        \ we should skip before starting to print the number
                        \ itself, and the plus 1 is there to ensure we print at
                        \ least one digit)

 LDY #0                 \ In the main loop below, we use Y to count the number
                        \ of times we subtract 10 billion to get the leftmost
                        \ digit, so set this to zero

 STY S                  \ In the main loop below, we use location S as an
                        \ 8-bit overflow for the 32-bit calculations, so
                        \ we need to set this to 0 before joining the loop

 JMP TT36               \ Jump to TT36 to start the process of printing this
                        \ number's digits

.TT35

                        \ This subroutine multiplies K(S 0 1 2 3) by 10 and
                        \ stores the result back in K(S 0 1 2 3), using the fact
                        \ that K * 10 = (K * 2) + (K * 2 * 2 * 2)

 ASL K+3                \ Set K(S 0 1 2 3) = K(S 0 1 2 3) * 2 by rotating left
 ROL K+2
 ROL K+1
 ROL K
 ROL S

 LDX #3                 \ Now we want to make a copy of the newly doubled K in
                        \ XX15, so we can use it for the first (K * 2) in the
                        \ equation above, so set up a counter in X for copying
                        \ four bytes, starting with the last byte in memory
                        \ (i.e. the least significant)

.tt35

 LDA K,X                \ Copy the X-th byte of K(0 1 2 3) to the X-th byte of
 STA XX15,X             \ XX15(0 1 2 3), so that XX15 will contain a copy of
                        \ K(0 1 2 3) once we've copied all four bytes

 DEX                    \ Decrement the loop counter

 BPL tt35               \ Loop back to copy the next byte until we have copied
                        \ all four

 LDA S                  \ Store the value of location S, our overflow byte, in
 STA XX15+4             \ XX15+4, so now XX15(4 0 1 2 3) contains a copy of
                        \ K(S 0 1 2 3), which is the value of (K * 2) that we
                        \ want to use in our calculation

 ASL K+3                \ Now to calculate the (K * 2 * 2 * 2) part. We still
 ROL K+2                \ have (K * 2) in K(S 0 1 2 3), so we just need to shift
 ROL K+1                \ it twice. This is the first one, so we do this:
 ROL K                  \
 ROL S                  \   K(S 0 1 2 3) = K(S 0 1 2 3) * 2 = K * 4

 ASL K+3                \ And then we do it again, so that means:
 ROL K+2                \
 ROL K+1                \   K(S 0 1 2 3) = K(S 0 1 2 3) * 2 = K * 8
 ROL K
 ROL S

 CLC                    \ Clear the C flag so we can do addition without the
                        \ C flag affecting the result

 LDX #3                 \ By now we've got (K * 2) in XX15(4 0 1 2 3) and
                        \ (K * 8) in K(S 0 1 2 3), so the final step is to add
                        \ these two 32-bit numbers together to get K * 10.
                        \ So we set a counter in X for four bytes, starting
                        \ with the last byte in memory (i.e. the least
                        \ significant)

.tt36

 LDA K,X                \ Fetch the X-th byte of K into A

 ADC XX15,X             \ Add the X-th byte of XX15 to A, with carry

 STA K,X                \ Store the result in the X-th byte of K

 DEX                    \ Decrement the loop counter

 BPL tt36               \ Loop back to add the next byte, moving from the least
                        \ significant byte to the most significant, until we
                        \ have added all four

 LDA XX15+4             \ Finally, fetch the overflow byte from XX15(4 0 1 2 3)

 ADC S                  \ And add it to the overflow byte from K(S 0 1 2 3),
                        \ with carry

 STA S                  \ And store the result in the overflow byte from
                        \ K(S 0 1 2 3), so now we have our desired result, i.e.
                        \
                        \   K(S 0 1 2 3) = K(S 0 1 2 3) * 10

 LDY #0                 \ In the main loop below, we use Y to count the number
                        \ of times we subtract 10 billion to get the leftmost
                        \ digit, so set this to zero so we can rejoin the main
                        \ loop for another subtraction process

.TT36

                        \ This is the main loop of our digit-printing routine.
                        \ In the following loop, we are going to count the
                        \ number of times that we can subtract 10 million and
                        \ store that count in Y, which we have already set to 0

 LDX #3                 \ Our first calculation concerns 32-bit numbers, so
                        \ set up a counter for a four-byte loop

 SEC                    \ Set the C flag so we can do subtraction without the
                        \ C flag affecting the result

.tt37

                        \ We now loop through each byte in turn to do this:
                        \
                        \   XX15(4 0 1 2 3) = K(S 0 1 2 3) - 100,000,000,000

 LDA K,X                \ Subtract the X-th byte of TENS (i.e. 10 billion) from
 SBC TENS,X             \ the X-th byte of K

 STA XX15,X             \ Store the result in the X-th byte of XX15

 DEX                    \ Decrement the loop counter

 BPL tt37               \ Loop back to subtract the next byte, moving from the
                        \ least significant byte to the most significant, until
                        \ we have subtracted all four

 LDA S                  \ Subtract the fifth byte of 10 billion (i.e. &17) from
 SBC #&17               \ the fifth (overflow) byte of K, which is S

 STA XX15+4             \ Store the result in the overflow byte of XX15

 BCC TT37               \ If subtracting 10 billion took us below zero, jump to
                        \ TT37 to print out this digit, which is now in Y

 LDX #3                 \ We now want to copy XX15(4 0 1 2 3) back into
                        \ K(S 0 1 2 3), so we can loop back up to do the next
                        \ subtraction, so set up a counter for a four-byte loop

.tt38

 LDA XX15,X             \ Copy the X-th byte of XX15(0 1 2 3) to the X-th byte
 STA K,X                \ of K(0 1 2 3), so that K(0 1 2 3) will contain a copy
                        \ of XX15(0 1 2 3) once we've copied all four bytes

 DEX                    \ Decrement the loop counter

 BPL tt38               \ Loop back to copy the next byte, until we have copied
                        \ all four

 LDA XX15+4             \ Store the value of location XX15+4, our overflow
 STA S                  \ byte in S, so now K(S 0 1 2 3) contains a copy of
                        \ XX15(4 0 1 2 3)

 INY                    \ We have now managed to subtract 10 billion from our
                        \ number, so increment Y, which is where we are keeping
                        \ a count of the number of subtractions so far

 JMP TT36               \ Jump back to TT36 to subtract the next 10 billion

.TT37

 TYA                    \ If we get here then Y contains the digit that we want
                        \ to print (as Y has now counted the total number of
                        \ subtractions of 10 billion), so transfer Y into A

 BNE TT32               \ If the digit is non-zero, jump to TT32 to print it

 LDA T                  \ Otherwise the digit is zero. If we are already
                        \ printing the number then we will want to print a 0,
                        \ but if we haven't started printing the number yet,
                        \ then we probably don't, as we don't want to print
                        \ leading zeroes unless this is the only digit before
                        \ the decimal point
                        \
                        \ To help with this, we are going to use T as a flag
                        \ that tells us whether we have already started
                        \ printing digits:
                        \
                        \   * If T <> 0 we haven't printed anything yet
                        \
                        \   * If T = 0 then we have started printing digits
                        \
                        \ We initially set T above to the maximum number of
                        \ characters allowed, less 1 if we are printing a
                        \ decimal point, so the first time we enter the digit
                        \ printing routine at TT37, it is definitely non-zero

 BEQ TT32               \ If T = 0, jump straight to the print routine at TT32,
                        \ as we have already started printing the number, so we
                        \ definitely want to print this digit too

 DEC U                  \ We initially set U to the number of digits we want to
 BPL TT34               \ skip before starting to print the number. If we get
                        \ here then we haven't printed any digits yet, so
                        \ decrement U to see if we have reached the point where
                        \ we should start printing the number, and if not, jump
                        \ to TT34 to set up things for the next digit

 LDA #' '               \ We haven't started printing any digits yet, but we
 BNE tt34               \ have reached the point where we should start printing
                        \ our number, so call TT26 (via tt34) to print a space
                        \ so that the number is left-padded with spaces (this
                        \ BNE is effectively a JMP as A will never be zero)

.TT32

 LDY #0                 \ We are printing an actual digit, so first set T to 0,
 STY T                  \ to denote that we have now started printing digits as
                        \ opposed to spaces

 CLC                    \ The digit value is in A, so add ASCII "0" to get the
 ADC #'0'               \ ASCII character number to print

.tt34

 JSR TT26               \ Call TT26 to print the character in A and fall through
                        \ into TT34 to get things ready for the next digit

.TT34

 DEC T                  \ Decrement T but keep T >= 0 (by incrementing it
 BPL P%+4               \ again if the above decrement made T negative)
 INC T

 DEC XX17               \ Decrement the total number of characters left to
                        \ print, which we stored in XX17

 BMI rT10               \ If the result is negative, we have printed all the
                        \ characters, so jump down to rT10 to return from the
                        \ subroutine

 BNE P%+10              \ If the result is positive (> 0) then we still have
                        \ characters left to print, so loop back to TT35 (via
                        \ the JMP TT35 instruction below) to print the next
                        \ digit

 PLP                    \ If we get here then we have printed the exact number
                        \ of digits that we wanted to, so restore the C flag
                        \ that we stored at the start of the routine

 BCC P%+7               \ If the C flag is clear, we don't want a decimal point,
                        \ so loop back to TT35 (via the JMP TT35 instruction
                        \ below) to print the next digit

 LDA #'.'               \ Otherwise the C flag is set, so print the decimal
 JSR TT26               \ point

 JMP TT35               \ Loop back to TT35 to print the next digit

.rT10

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DTW1
\       Type: Variable
\   Category: Text
\    Summary: A mask for applying the lower case part of Sentence Case to
\             extended text tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This variable is used to change characters to lower case as part of applying
\ Sentence Case to extended text tokens. It has two values:
\
\   * %00100000 = apply lower case to the second letter of a word onwards
\
\   * %00000000 = do not change case to lower case
\
\ The default value is %00100000 (apply lower case).
\
\ The flag is set to %00100000 (apply lower case) by jump token 2, {sentence
\ case}, which calls routine MT2 to change the value of DTW1.
\
\ The flag is set to %00000000 (do not change case to lower case) by jump token
\ 1, {all caps}, which calls routine MT1 to change the value of DTW1.
\
\ The letter to print is OR'd with DTW1 in DETOK2, which lower-cases the letter
\ by setting bit 5 (if DTW1 is %00100000). However, this OR is only done if bit
\ 7 of DTW2 is clear, i.e. we are printing a word, so this doesn't affect the
\ first letter of the word, which remains capitalised.
\
\ ******************************************************************************

.DTW1

 EQUB %00100000

\ ******************************************************************************
\
\       Name: DTW2
\       Type: Variable
\   Category: Text
\    Summary: A flag that indicates whether we are currently printing a word
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This variable is used to indicate whether we are currently printing a word. It
\ has two values:
\
\   * 0 = we are currently printing a word
\
\   * Non-zero = we are not currently printing a word
\
\ The default value is %11111111 (we are not currently printing a word).
\
\ The flag is set to %00000000 (we are currently printing a word) whenever a
\ non-terminator character is passed to DASC for printing.
\
\ The flag is set to %11111111 (we are not currently printing a word) whenever a
\ terminator character (full stop, colon, carriage return, line feed, space) is
\ passed to DASC for printing. It is also set to %11111111 by jump token 8,
\ {tab 6}, which calls routine MT8 to change the value of DTW2, and to %10000000
\ by TTX66 when we clear the screen.
\
\ ******************************************************************************

.DTW2

 EQUB %11111111

\ ******************************************************************************
\
\       Name: DTW3
\       Type: Variable
\   Category: Text
\    Summary: A flag for switching between standard and extended text tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This variable is used to indicate whether standard or extended text tokens
\ should be printed by calls to DETOK. It allows us to mix standard tokens in
\ with extended tokens. It has two values:
\
\   * %00000000 = print extended tokens (i.e. those in TKN1 and RUTOK)
\
\   * %11111111 = print standard tokens (i.e. those in QQ18)
\
\ The default value is %00000000 (extended tokens).
\
\ Standard tokens are set by jump token {6}, which calls routine MT6 to change
\ the value of DTW3 to %11111111.
\
\ Extended tokens are set by jump token {5}, which calls routine MT5 to change
\ the value of DTW3 to %00000000.
\
\ ******************************************************************************

.DTW3

 EQUB %00000000

\ ******************************************************************************
\
\       Name: DTW4
\       Type: Variable
\   Category: Text
\    Summary: Flags that govern how justified extended text tokens are printed
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This variable is used to control how justified text tokens are printed as part
\ of the extended text token system. There are two bits that affect justified
\ text:
\
\   * Bit 7: 1 = justify text
\            0 = do not justify text
\
\   * Bit 6: 1 = buffer the entire token before printing, including carriage
\                returns (used for in-flight messages only)
\            0 = print the contents of the buffer whenever a carriage return
\                appears in the token
\
\ The default value is %00000000 (do not justify text, print buffer on carriage
\ return).
\
\ The flag is set to %10000000 (justify text, print buffer on carriage return)
\ by jump token 14, {justify}, which calls routine MT14 to change the value of
\ DTW4.
\
\ The flag is set to %11000000 (justify text, buffer entire token) by routine
\ MESS, which printe in-flight messages.
\
\ The flag is set to %00000000 (do not justify text, print buffer on carriage
\ return) by jump token 15, {left align}, which calls routine MT1 to change the
\ value of DTW4.
\
\ ******************************************************************************

.DTW4

 EQUB 0

\ ******************************************************************************
\
\       Name: DTW5
\       Type: Variable
\   Category: Text
\    Summary: The size of the justified text buffer at BUF
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ When justified text is enabled by jump token 14, {justify}, during printing of
\ extended text tokens, text is fed into a buffer at BUF instead of being
\ printed straight away, so it can be padded out with spaces to justify the
\ text. DTW5 contains the size of the buffer, so BUF + DTW5 points to the first
\ free byte after the end of the buffer.
\
\ ******************************************************************************

.DTW5

 EQUB 0

\ ******************************************************************************
\
\       Name: DTW6
\       Type: Variable
\   Category: Text
\    Summary: A flag to denote whether printing in lower case is enabled for
\             extended text tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This variable is used to indicate whether lower case is currently enabled. It
\ has two values:
\
\   * %10000000 = lower case is enabled
\
\   * %00000000 = lower case is not enabled
\
\ The default value is %00000000 (lower case is not enabled).
\
\ The flag is set to %10000000 (lower case is enabled) by jump token 13 {lower
\ case}, which calls routine MT10 to change the value of DTW6.
\
\ The flag is set to %00000000 (lower case is not enabled) by jump token 1, {all
\ caps}, and jump token 1, {sentence case}, which call routines MT1 and MT2 to
\ change the value of DTW6.
\
\ ******************************************************************************

.DTW6

 EQUB %00000000

\ ******************************************************************************
\
\       Name: DTW8
\       Type: Variable
\   Category: Text
\    Summary: A mask for capitalising the next letter in an extended text token
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This variable is only used by one specific extended token, the {single cap}
\ jump token, which capitalises the next letter only. It has two values:
\
\   * %11011111 = capitalise the next letter
\
\   * %11111111 = do not change case
\
\ The default value is %11111111 (do not change case).
\
\ The flag is set to %11011111 (capitalise the next letter) by jump token 19,
\ {single cap}, which calls routine MT19 to change the value of DTW.
\
\ The flag is set to %11111111 (do not change case) at the start of DASC, after
\ the letter has been capitalised in DETOK2, so the effect is to capitalise one
\ letter only.
\
\ The letter to print is AND'd with DTW8 in DETOK2, which capitalises the letter
\ by clearing bit 5 (if DTW8 is %11011111). However, this AND is only done if at
\ least one of the following is true:
\
\   * Bit 7 of DTW2 is set (we are not currently printing a word)
\
\   * Bit 7 of DTW6 is set (lower case has been enabled by jump token 13, {lower
\     case}
\
\ In other words, we only capitalise the next letter if it's the first letter in
\ a word, or we are printing in lower case.
\
\ ******************************************************************************

.DTW8

 EQUB %11111111

\ ******************************************************************************
\
\       Name: FEED
\       Type: Subroutine
\   Category: Text
\    Summary: Print a newline
\
\ ******************************************************************************

.FEED

 LDA #12                \ Set A = 12, so when we skip MT16 and fall through into
                        \ TT26, we print character 12, which is a newline

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &41, or BIT &41A9, which does nothing apart
                        \ from affect the flags

                        \ Fall through into TT26 (skipping MT16) to print the
                        \ newline character

\ ******************************************************************************
\
\       Name: MT16
\       Type: Subroutine
\   Category: Text
\    Summary: Print the character in variable DTW7
\  Deep dive: Extended text tokens
\
\ ******************************************************************************

.MT16

 LDA #'A'               \ Set A to the contents of DTW7, as DTW7 points to the
                        \ second byte of this instruction, so updating DTW7 will
                        \ modify this instruction (the default value of DTW7 is
                        \ an "A")

DTW7 = MT16 + 1         \ Point DTW7 to the second byte of the instruction above
                        \ so that modifying DTW7 changes the value loaded into A

                        \ Fall through into TT26 to print the character in A

\ ******************************************************************************
\
\       Name: TT26
\       Type: Subroutine
\   Category: Text
\    Summary: Print a character at the text cursor, with support for verified
\             text in extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The character to print
\
\ Returns:
\
\   X                   X is preserved
\
\   C flag              The C flag is cleared
\
\ Other entry points:
\
\   DASC                DASC does exactly the same as TT26 and prints a
\                       character at the text cursor, with support for verified
\                       text in extended tokens
\
\   rT9                 Contains an RTS
\
\ ******************************************************************************

.DASC

.TT26

 STX SC                 \ Store X in SC, so we can retrieve it below

 LDX #%11111111         \ Set DTW8 = %11111111, to disable the effect of {19} if
 STX DTW8               \ it was set (as {19} capitalises one character only)

 CMP #'.'               \ If the character in A is a word terminator:
 BEQ DA8                \
 CMP #':'               \   * Full stop
 BEQ DA8                \   * Colon
 CMP #10                \   * Line feed
 BEQ DA8                \   * Carriage return
 CMP #12                \   * Space
 BEQ DA8                \
 CMP #' '               \ then skip the following instruction
 BEQ DA8

 INX                    \ Increment X to 0, so DTW2 gets set to %00000000 below

.DA8

 STX DTW2               \ Store X in DTW2, so DTW2 is now:
                        \
                        \   * %00000000 if this character is a word terminator
                        \
                        \   * %11111111 if it isn't
                        \
                        \ so DTW2 indicates whether or not we are currently
                        \ printing a word

 LDX SC                 \ Retrieve the original value of X from SC

 BIT DTW4               \ If bit 7 of DTW4 is set then we are currently printing
 BMI P%+5               \ justified text, so skip the next instruction

 JMP CHPR               \ Bit 7 of DTW4 is clear, so jump down to CHPR to print
                        \ this character, as we are not printing justified text

                        \ If we get here then we are printing justified text, so
                        \ we need to buffer the text until we reach the end of
                        \ the paragraph, so we can then pad it out with spaces

 CMP #12                \ If the character in A is a carriage return, then we
 BEQ DA1                \ have reached the end of the paragraph, so jump down to
                        \ DA1 to print out the contents of the buffer,
                        \ justifying it as we go

                        \ If we get here then we need to buffer this character
                        \ in the line buffer at BUF

 LDX DTW5               \ DTW5 contains the current size of the buffer, so this
 STA BUF,X              \ stores the character in A at BUF + DTW5, the next free
                        \ space in the buffer

 LDX SC                 \ Retrieve the original value of X from SC so we can
                        \ preserve it through this subroutine call

 INC DTW5               \ Increment the size of the BUF buffer that is stored in
                        \ DTW5

 CLC                    \ Clear the C flag

 RTS                    \ Return from the subroutine

.DA1

                        \ If we get here then we are justifying text and we have
                        \ reached the end of the paragraph, so we need to print
                        \ out the contents of the buffer, justifying it as we go

 TXA                    \ Store X and Y on the stack
 PHA
 TYA
 PHA

.DA5

 LDX DTW5               \ Set X = DTW5, which contains the size of the buffer

 BEQ DA6+3              \ If X = 0 then the buffer is empty, so jump down to
                        \ DA6+3 to print a newline

 CPX #(LL+1)            \ If X < LL+1, i.e. X <= LL, then the buffer contains
 BCC DA6                \ fewer than LL characters, which is less then a line
                        \ length, so jump down to DA6 to print the contents of
                        \ BUF followed by a newline, as we don't justify the
                        \ last line of the paragraph

                        \ Otherwise X > LL, so the buffer does not fit into one
                        \ line, and we therefore need to justify the text, which
                        \ we do one line at a time

 LSR SC+1               \ Shift SC+1 to the right, which clears bit 7 of SC+1,
                        \ so we pass through the following comparison on the
                        \ first iteration of the loop and set SC+1 to %01000000

.DA11

 LDA SC+1               \ If bit 7 of SC+1 is set, skip the following two
 BMI P%+6               \ instructions

 LDA #%01000000         \ Set SC+1 = %01000000
 STA SC+1

 LDY #(LL-1)            \ Set Y = line length, so we can loop backwards from the
                        \ end of the first line in the buffer using Y as the
                        \ loop counter

.DAL1

 LDA BUF+LL             \ If the LL-th byte in BUF is a space, jump down to DA2
 CMP #' '               \ to print out the first line from the buffer, as it
 BEQ DA2                \ fits the line width exactly (i.e. it's justified)

                        \ We now want to find the last space character in the
                        \ first line in the buffer, so we loop through the line
                        \ using Y as a counter

.DAL2

 DEY                    \ Decrement the loop counter in Y

 BMI DA11               \ If Y <= 0, loop back to DA11, as we have now looped
 BEQ DA11               \ through the whole line

 LDA BUF,Y              \ If the Y-th byte in BUF is not a space, loop back up
 CMP #' '               \ to DAL2 to check the next character
 BNE DAL2

                        \ Y now points to a space character in the line buffer

 ASL SC+1               \ Shift SC+1 to the left

 BMI DAL2               \ If bit 7 of SC+1 is set, jump to DAL2 to find the next
                        \ space character

                        \ We now want to insert a space into the line buffer at
                        \ position Y, which we do by shifting every character
                        \ after position Y along by 1, and then inserting the
                        \ space

 STY SC                 \ Store Y in SC, so we want to insert the space at
                        \ position SC

 LDY DTW5               \ Fetch the buffer size from DTW5 into Y, to act as a
                        \ loop counter for moving the line buffer along by 1

.DAL6

 LDA BUF,Y              \ Copy the Y-th character from BUF into the Y+1-th
 STA BUF+1,Y            \ position

 DEY                    \ Decrement the loop counter in Y

 CPY SC                 \ Loop back to shift the next character along, until we
 BCS DAL6               \ have moved the SC-th character (i.e. Y < SC)

 INC DTW5               \ Increment the buffer size in DTW5

\LDA #' '               \ This instruction is commented out in the original
                        \ source, as it has no effect because A already contains
                        \ ASCII " ". This is because the last character that is
                        \ tested in the above loop is at position SC, which we
                        \ know contains a space, so we know A contains a space
                        \ character when the loop finishes

                        \ We've now shifted the line to the right by 1 from
                        \ position SC onwards, so SC and SC+1 both contain
                        \ spaces, and Y is now SC-1 as we did a DEY just before
                        \ the end of the loop - in other words, we have inserted
                        \ a space at position SC, and Y points to the character
                        \ before the newly inserted space

                        \ We now want to move the pointer Y left to find the
                        \ next space in the line buffer, before looping back to
                        \ check whether we are done, and if not, insert another
                        \ space

.DAL3

 CMP BUF,Y              \ If the character at position Y is not a space, jump to
 BNE DAL1               \ DAL1 to see whether we have now justified the line

 DEY                    \ Decrement the loop counter in Y

 BPL DAL3               \ Loop back to check the next character to the left,
                        \ until we have found a space

 BMI DA11               \ Jump back to DA11 (this BMI is effectively a JMP as
                        \ we already passed through a BPL to get here)

.DA2

                        \ This subroutine prints out a full line of characters
                        \ from the start of the line buffer in BUF, followed by
                        \ a newline. It then removes that line from the buffer,
                        \ shuffling the rest of the buffer contents down

 LDX #LL                \ Call DAS1 to print out the first LL characters from
 JSR DAS1               \ the line buffer in BUF

 LDA #12                \ Print a newline
 JSR CHPR

 LDA DTW5               \ Subtract #LL from the end-of-buffer pointer in DTW5
\CLC                    \
 SBC #LL                \ The CLC instruction is commented out in the original
 STA DTW5               \ source. It isn't needed as CHPR clears the C flag

 TAX                    \ Copy the new value of DTW5 into X

 BEQ DA6+3              \ If DTW5 = 0 then jump down to DA6+3 to print a newline
                        \ as the buffer is now empty

                        \ If we get here then we have printed our line but there
                        \ is more in the buffer, so we now want to remove the
                        \ line we just printed from the start of BUF

 LDY #0                 \ Set Y = 0 to count through the characters in BUF

 INX                    \ Increment X, so it now contains the number of
                        \ characters in the buffer (as DTW5 is a zero-based
                        \ pointer and is therefore equal to the number of
                        \ characters minus 1)

.DAL4

 LDA BUF+LL+1,Y         \ Copy the Y-th character from BUF+LL to BUF
 STA BUF,Y

 INY                    \ Increment the character pointer

 DEX                    \ Decrement the character count

 BNE DAL4               \ Loop back to copy the next character until we have
                        \ shuffled down the whole buffer

 BEQ DA5                \ Jump back to DA5 (this BEQ is effectively a JMP as we
                        \ have already passed through the BNE above)

.DAS1

                        \ This subroutine prints out X characters from BUF,
                        \ returning with X = 0

 LDY #0                 \ Set Y = 0 to point to the first character in BUF

.DAL5

 LDA BUF,Y              \ Print the Y-th character in BUF using CHPR, which also
 JSR CHPR               \ clears the C flag for when we return from the
                        \ subroutine below

 INY                    \ Increment Y to point to the next character

 DEX                    \ Decrement the loop counter

 BNE DAL5               \ Loop back for the next character until we have printed
                        \ X characters from BUF

.rT9

 RTS                    \ Return from the subroutine

.DA6

 JSR DAS1               \ Call DAS1 to print X characters from BUF, returning
                        \ with X = 0

 STX DTW5               \ Set the buffer size in DTW5 to 0, as the buffer is now
                        \ empty

 PLA                    \ Restore Y and X from the stack
 TAY
 PLA
 TAX

 LDA #12                \ Set A = 12, so when we skip BELL and fall through into
                        \ CHPR, we print character 12, which is a newline

.DA7

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &07, or BIT &07A9, which does nothing apart
                        \ from affect the flags

                        \ Fall through into CHPR (skipping BELL) to print the
                        \ character and return with the C flag cleared

\ ******************************************************************************
\
\       Name: BELL
\       Type: Subroutine
\   Category: Sound
\    Summary: Make a standard system beep
\
\ ------------------------------------------------------------------------------
\
\ This is the standard system beep as made by the VDU 7 statement in BBC BASIC.
\
\ ******************************************************************************

.BELL

 LDA #7                 \ Control code 7 makes a beep, so load this into A

                        \ Fall through into the TT26 print routine to
                        \ actually make the sound

\ ******************************************************************************
\
\       Name: CHPR
\       Type: Subroutine
\   Category: Text
\    Summary: Print a character at the text cursor by poking into screen memory
\  Deep dive: Drawing text
\
\ ------------------------------------------------------------------------------
\
\ Print a character at the text cursor (XC, YC), do a beep, print a newline,
\ or delete left (backspace).
\
\ WRCHV is set to point here by the loading process.
\
\ Arguments:
\
\   A                   The character to be printed. Can be one of the
\                       following:
\
\                         * 7 (beep)
\
\                         * 10-13 (line feeds and carriage returns)
\
\                         * 32-95 (ASCII capital letters, numbers and
\                           punctuation)
\
\                         * 127 (delete the character to the left of the text
\                           cursor and move the cursor to the left)
\
\   XC                  Contains the text column to print at (the x-coordinate)
\
\   YC                  Contains the line number to print on (the y-coordinate)
\
\ Returns:
\
\   A                   A is preserved
\
\   X                   X is preserved
\
\   Y                   Y is preserved
\
\   C flag              The C flag is cleared
\
\ Other entry points:
\
\   RR3+1               Contains an RTS
\
\   RREN                Prints the character definition pointed to by P(2 1) at
\                       the screen address pointed to by (A SC). Used by the
\                       BULB routine
\
\ ******************************************************************************

.CHPR

 STA K3                 \ Store the A, X and Y registers, so we can restore
 STY YSAV2              \ them at the end (so they don't get changed by this
 STX XSAV2              \ routine)

.RRNEW

 LDY QQ17               \ Load the QQ17 flag, which contains the text printing
                        \ flags

 INY                    \ If QQ17 = 255 then printing is disabled, so jump to
 BEQ RR4                \ RR4, which doesn't print anything, it just restores
                        \ the registers and returns from the subroutine

 TAY                    \ Set Y = the character to be printed

 BEQ RR4                \ If the character is zero, which is typically a string
                        \ terminator character, jump down to RR4 to restore the
                        \ registers and return from the subroutine

 BMI RR4                \ If A > 127 then there is nothing to print, so jump to
                        \ RR4 to restore the registers and return from the
                        \ subroutine

 CMP #7                 \ If this is a beep character (A = 7), jump to R5,
 BEQ R5                 \ which will emit the beep, restore the registers and
                        \ return from the subroutine

 CMP #32                \ If this is an ASCII character (A >= 32), jump to RR1
 BCS RR1                \ below, which will print the character, restore the
                        \ registers and return from the subroutine

 CMP #10                \ If this is control code 10 (line feed) then jump to
 BEQ RRX1               \ RRX1, which will move down a line, restore the
                        \ registers and return from the subroutine

 LDX #1                 \ If we get here, then this is control code 11-13, of
 STX XC                 \ which only 13 is used. This code prints a newline,
                        \ which we can achieve by moving the text cursor
                        \ to the start of the line (carriage return) and down
                        \ one line (line feed). These two lines do the first
                        \ bit by setting XC = 1, and we then fall through into
                        \ the line feed routine that's used by control code 10

 CMP #13                \ If this is control code 13 (carriage return) then jump
 BEQ RR4                \ RR4 to restore the registers and return from the
                        \ subroutine

.RRX1

 INC YC                 \ Print a line feed, simply by incrementing the row
                        \ number (y-coordinate) of the text cursor, which is
                        \ stored in YC

 BNE RR4                \ Jump to RR4 to restore the registers and return from
                        \ the subroutine (this BNE is effectively a JMP as Y
                        \ will never be zero)

.RR1

                        \ If we get here, then the character to print is an
                        \ ASCII character in the range 32-95. The quickest way
                        \ to display text on-screen is to poke the character
                        \ pixel by pixel, directly into screen memory, so
                        \ that's what the rest of this routine does
                        \
                        \ The first step, then, is to get hold of the bitmap
                        \ definition for the character we want to draw on the
                        \ screen (i.e. we need the pixel shape of this
                        \ character). The MOS ROM contains bitmap definitions
                        \ of the system's ASCII characters, starting from &C000
                        \ for space (ASCII 32) and ending with the £ symbol
                        \ (ASCII 126)
                        \
                        \ There are definitions for 32 characters in each of the
                        \ three pages of MOS memory, as each definition takes up
                        \ 8 bytes (8 rows of 8 pixels) and 32 * 8 = 256 bytes =
                        \ 1 page. So:
                        \
                        \   ASCII 32-63  are defined in &C000-&C0FF (page 0)
                        \   ASCII 64-95  are defined in &C100-&C1FF (page 1)
                        \   ASCII 96-126 are defined in &C200-&C2F0 (page 2)
                        \
                        \ The following code reads the relevant character
                        \ bitmap from the above locations in ROM and pokes
                        \ those values into the correct position in screen
                        \ memory, thus printing the character on-screen
                        \
                        \ It's a long way from 10 PRINT "Hello world!":GOTO 10

                        \ Now we want to set X to point to the relevant page
                        \ number for this character - i.e. &C0, &C1 or &C2.

                        \ The following logic is easier to follow if we look
                        \ at the three character number ranges in binary:
                        \
                        \   Bit #  76543210
                        \
                        \   32  = %00100000     Page 0 of bitmap definitions
                        \   63  = %00111111
                        \
                        \   64  = %01000000     Page 1 of bitmap definitions
                        \   95  = %01011111
                        \
                        \   96  = %01100000     Page 2 of bitmap definitions
                        \   125 = %01111101
                        \
                        \ We'll refer to this below

 LDX #&BF               \ Set X to point to the first font page in ROM minus 1,
                        \ which is &C0 - 1, or &BF

 ASL A                  \ If bit 6 of the character is clear (A is 32-63)
 ASL A                  \ then skip the following instruction
 BCC P%+4

 LDX #&C1               \ A is 64-126, so set X to point to page &C1

 ASL A                  \ If bit 5 of the character is clear (A is 64-95)
 BCC P%+3               \ then skip the following instruction

 INX                    \ Increment X
                        \
                        \ By this point, we started with X = &BF, and then
                        \ we did the following:
                        \
                        \   If A = 32-63:   skip    then INX  so X = &C0
                        \   If A = 64-95:   X = &C1 then skip so X = &C1
                        \   If A = 96-126:  X = &C1 then INX  so X = &C2
                        \
                        \ In other words, X points to the relevant page. But
                        \ what about the value of A? That gets shifted to the
                        \ left three times during the above code, which
                        \ multiplies the number by 8 but also drops bits 7, 6
                        \ and 5 in the process. Look at the above binary
                        \ figures and you can see that if we cleared bits 5-7,
                        \ then that would change 32-53 to 0-31... but it would
                        \ do exactly the same to 64-95 and 96-125. And because
                        \ we also multiply this figure by 8, A now points to
                        \ the start of the character's definition within its
                        \ page (because there are 8 bytes per character
                        \ definition)
                        \
                        \ Or, to put it another way, X contains the high byte
                        \ (the page) of the address of the definition that we
                        \ want, while A contains the low byte (the offset into
                        \ the page) of the address

 STA P+1                \ Store the address of this character's definition in
 STX P+2                \ P(2 1)

 LDA XC                 \ Fetch XC, the x-coordinate (column) of the text cursor
                        \ into A

 LDX CATF               \ If CATF = 0, jump to RR5, otherwise we are printing a
 BEQ RR5                \ disc catalogue

 CPY #' '               \ If the character we want to print in Y is a space,
 BNE RR5                \ jump to RR5

                        \ If we get here, then CATF is non-zero, so we are
                        \ printing a disc catalogue and we are not printing a
                        \ space, so we drop column 17 from the output so the
                        \ catalogue will fit on-screen (column 17 is a blank
                        \ column in the middle of the catalogue, between the
                        \ two lists of filenames, so it can be dropped without
                        \ affecting the layout). Without this, the catalogue
                        \ would be one character too wide for the square screen
                        \ mode (it's 34 characters wide, while the screen mode
                        \ is only 33 characters across)

 CMP #17                \ If A = 17, i.e. the text cursor is in column 17, jump
 BEQ RR4                \ to RR4 to restore the registers and return from the
                        \ subroutine, thus omitting this column

.RR5

 ASL A                  \ Multiply A by 8, and store in SC. As each character is
 ASL A                  \ 8 pixels wide, and the special screen mode Elite uses
 ASL A                  \ for the top part of the screen is 256 pixels across
 STA SC                 \ with one bit per pixel, this value is not only the
                        \ screen address offset of the text cursor from the left
                        \ side of the screen, it's also the least significant
                        \ byte of the screen address where we want to print this
                        \ character, as each row of on-screen pixels corresponds
                        \ to one page. To put this more explicitly, the screen
                        \ starts at &6000, so the text rows are stored in screen
                        \ memory like this:
                        \
                        \   Row 1: &6000 - &60FF    YC = 1, XC = 0 to 31
                        \   Row 2: &6100 - &61FF    YC = 2, XC = 0 to 31
                        \   Row 3: &6200 - &62FF    YC = 3, XC = 0 to 31
                        \
                        \ and so on

 LDA YC                 \ Fetch YC, the y-coordinate (row) of the text cursor

 CPY #127               \ If the character number (which is in Y) <> 127, then
 BNE RR2                \ skip to RR2 to print that character, otherwise this is
                        \ the delete character, so continue on

 DEC XC                 \ We want to delete the character to the left of the
                        \ text cursor and move the cursor back one, so let's
                        \ do that by decrementing YC. Note that this doesn't
                        \ have anything to do with the actual deletion below,
                        \ we're just updating the cursor so it's in the right
                        \ position following the deletion

 ADC #&5E               \ A contains YC (from above) and the C flag is set (from
 TAX                    \ the CPY #127 above), so these instructions do this:
                        \
                        \   X = YC + &5E + 1
                        \     = YC + &5F

                        \ Because YC starts at 0 for the first text row, this
                        \ means that X will be &5F for row 0, &60 for row 1 and
                        \ so on. In other words, X is now set to the page number
                        \ for the row before the one containing the text cursor,
                        \ and given that we set SC above to point to the offset
                        \ in memory of the text cursor within the row's page,
                        \ this means that (X SC) now points to the character
                        \ above the text cursor

 LDY #&F8               \ Set Y = &F8, so the following call to ZES2 will count
                        \ Y upwards from &F8 to &FF

 JSR ZES2               \ Call ZES2, which zero-fills from address (X SC) + Y to
                        \ (X SC) + &FF. (X SC) points to the character above the
                        \ text cursor, and adding &FF to this would point to the
                        \ cursor, so adding &F8 points to the character before
                        \ the cursor, which is the one we want to delete. So
                        \ this call zero-fills the character to the left of the
                        \ cursor, which erases it from the screen

 BEQ RR4                \ We are done deleting, so restore the registers and
                        \ return from the subroutine (this BNE is effectively
                        \ a JMP as ZES2 always returns with the Z flag set)

.RR2

                        \ Now to actually print the character

 INC XC                 \ Once we print the character, we want to move the text
                        \ cursor to the right, so we do this by incrementing
                        \ XC. Note that this doesn't have anything to do
                        \ with the actual printing below, we're just updating
                        \ the cursor so it's in the right position following
                        \ the print

 CMP #24                \ If the text cursor is on the screen (i.e. YC < 24, so
 BCC RR3                \ we are on rows 1-23), then jump to RR3 to print the
                        \ character

 PHA                    \ Store A on the stack so we can retrieve it below

 JSR TTX66              \ Otherwise we are off the bottom of the screen, so
                        \ clear the screen and draw a white border

 PLA                    \ Retrieve A from the stack... only to overwrite it with
                        \ the next instruction, so presumably we didn't need to
                        \ preserve it and this and the PHA above have no effect

 LDA K3                 \ Set A to the character to be printed

 JMP RRNEW              \ Jump back to RRNEW to print the character

.RR3

                        \ A contains the value of YC - the screen row where we
                        \ want to print this character - so now we need to
                        \ convert this into a screen address, so we can poke
                        \ the character data to the right place in screen
                        \ memory

 ORA #&60               \ We already stored the least significant byte
                        \ of this screen address in SC above (see the STA SC
                        \ instruction above), so all we need is the most
                        \ significant byte. As mentioned above, in Elite's
                        \ square mode 4 screen, each row of text on-screen
                        \ takes up exactly one page, so the first row is page
                        \ &60xx, the second row is page &61xx, so we can get
                        \ the page for character (XC, YC) by OR'ing with &60.
                        \ To see this in action, consider that our two values
                        \ are, in binary:
                        \
                        \   YC is between:  %00000000
                        \             and:  %00010111
                        \          &60 is:  %01100000
                        \
                        \ so YC OR &60 effectively adds &60 to YC, giving us
                        \ the page number that we want

.RREN

 STA SC+1               \ Store the page number of the destination screen
                        \ location in SC+1, so SC now points to the full screen
                        \ location where this character should go

 LDY #7                 \ We want to print the 8 bytes of character data to the
                        \ screen (one byte per row), so set up a counter in Y
                        \ to count these bytes

.RRL1

 LDA (P+1),Y            \ The character definition is at P(2 1) - we set this up
                        \ above - so load the Y-th byte from P(2 1), which will
                        \ contain the bitmap for the Y-th row of the character

 ORA (SC),Y             \ OR this value with the current contents of screen
                        \ memory, so the pixels we want to draw are set

 STA (SC),Y             \ Store the Y-th byte at the screen address for this
                        \ character location

 DEY                    \ Decrement the loop counter

 BPL RRL1               \ Loop back for the next byte to print to the screen

.RR4

 LDY YSAV2              \ We're done printing, so restore the values of the
 LDX XSAV2              \ A, X and Y registers that we saved above and clear
 LDA K3                 \ the C flag, so everything is back to how it was
 CLC

 RTS                    \ Return from the subroutine

.R5

 JSR BEEP               \ Call the BEEP subroutine to make a short, high beep

 JMP RR4                \ Jump to RR4 to restore the registers and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: HME2
\       Type: Subroutine
\   Category: Charts
\    Summary: Search the galaxy for a system
\
\ ******************************************************************************

.HME2

 LDA #14                \ Print extended token 14 ("{clear bottom of screen}
 JSR DETOK              \ PLANET NAME?{fetch line input from keyboard}"). The
                        \ last token calls MT26, which puts the entered search
                        \ term in INWK+5 and the term length in Y

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10),
                        \ which will erase the crosshairs currently there

 JSR TT81               \ Set the seeds in QQ15 (the selected system) to those
                        \ of system 0 in the current galaxy (i.e. copy the seeds
                        \ from QQ21 to QQ15)

 LDA #0                 \ We now loop through the galaxy's systems in order,
 STA XX20               \ until we find a match, so set XX20 to act as a system
                        \ counter, starting with system 0

.HME3

 JSR MT14               \ Switch to justified text when printing extended
                        \ tokens, so the call to cpl prints into the justified
                        \ text buffer at BUF instead of the screen, and DTW5
                        \ gets set to the length of the system name

 JSR cpl                \ Print the selected system name into the justified text
                        \ buffer

 LDX DTW5               \ Fetch DTW5 into X, so X is now equal to the length of
                        \ the selected system name

 LDA INWK+5,X           \ Fetch the X-th character from the entered search term

 CMP #13                \ If the X-th character is not a carriage return, then
 BNE HME6               \ the selected system name and the entered search term
                        \ are different lengths, so jump to HME6 to move on to
                        \ the next system

.HME4

 DEX                    \ Decrement X so it points to the last letter of the
                        \ selected system name (and, when we loop back here, it
                        \ points to the next letter to the left)

 LDA INWK+5,X           \ Set A to the X-th character of the entered search term

 ORA #%00100000         \ Set bit 5 of the character to make it lower case

 CMP BUF,X              \ If the character in A matches the X-th character of
 BEQ HME4               \ the selected system name in BUF, loop back to HME4 to
                        \ check the next letter to the left

 TXA                    \ The last comparison didn't match, so copy the letter
 BMI HME5               \ number into A, and if it's negative, that means we
                        \ managed to go past the first letters of each term
                        \ before we failed to get a match, so the terms are the
                        \ same, so jump to HME5 to process a successful search

.HME6

                        \ If we get here then the selected system name and the
                        \ entered search term did not match

 JSR TT20               \ We want to move on to the next system, so call TT20
                        \ to twist the three 16-bit seeds in QQ15

 INC XX20               \ Incrememt the system counter in XX20

 BNE HME3               \ If we haven't yet checked all 256 systems in the
                        \ current galaxy, loop back to HME3 to check the next
                        \ system

                        \ If we get here then the entered search term did not
                        \ match any systems in the current galaxy

 JSR TT111              \ Select the system closest to galactic coordinates
                        \ (QQ9, QQ10), so we can put the crosshairs back where
                        \ they were before the search

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10)

 LDA #40                \ Call the NOISE routine with A = 40 to make a low,
 JSR NOISE              \ long beep to indicate a failed search

 LDA #215               \ Print extended token 215 ("{left align} UNKNOWN
 JMP DETOK              \ PLANET"), which will print on-screem as the left align
                        \ code disables justified text, and return from the
                        \ subroutine using a tail call

.HME5

                        \ If we get here then we have found a match for the
                        \ entered search

 LDA QQ15+3             \ The x-coordinate of the system described by the seeds
 STA QQ9                \ in QQ15 is in QQ15+3 (s1_hi), so we copy this to QQ9
                        \ as the x-coordinate of the search result

 LDA QQ15+1             \ The y-coordinate of the system described by the seeds
 STA QQ10               \ in QQ15 is in QQ15+1 (s0_hi), so we copy this to QQ10
                        \ as the y-coordinate of the search result

 JSR TT111              \ Select the system closest to galactic coordinates
                        \ (QQ9, QQ10)

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10)

 JSR MT15               \ Switch to left-aligned text when printing extended
                        \ tokens so future tokens will print to the screen (as
                        \ this disables justified text)

 JMP T95                \ Jump to T95 to print the distance to the selected
                        \ system and return from the subroutine using a tail
                        \ call

\ ******************************************************************************
\
\ Save output/ELTB.bin
\
\ ******************************************************************************

PRINT "ELITE B"
PRINT "Assembled at ", ~CODE_B%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_B%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_B%

PRINT "S.F.ELTB ", ~CODE_B%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_B%
\SAVE "output/F.ELTB.bin", CODE_B%, P%, LOAD%

\ ******************************************************************************
\
\ ELITE C FILE
\
\ ******************************************************************************

CODE_C% = P%
LOAD_C% = LOAD% +P% - CODE%

\ ******************************************************************************
\
\       Name: SQUA
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Clear bit 7 of A and calculate (A P) = A * A
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of unsigned 8-bit numbers, after first
\ clearing bit 7 of A:
\
\   (A P) = A * A
\
\ ******************************************************************************

.SQUA

 AND #%01111111         \ Clear bit 7 of A and fall through into SQUA2 to set
                        \ (A P) = A * A

\ ******************************************************************************
\
\       Name: SQUA2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = A * A
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of unsigned 8-bit numbers:
\
\   (A P) = A * A
\
\ ******************************************************************************

.SQUA2

 STA P                  \ Copy A into P and X
 TAX

 BNE MU11               \ If X = 0 fall through into MU1 to return a 0,
                        \ otherwise jump to MU11 to return P * X

\ ******************************************************************************
\
\       Name: MU1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Copy X into P and A, and clear the C flag
\
\ ------------------------------------------------------------------------------
\
\ Used to return a 0 result quickly from MULTU below.
\
\ ******************************************************************************

.MU1

 CLC                    \ Clear the C flag

 STX P                  \ Copy X into P and A
 TXA

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MULTU
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = P * Q
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of unsigned 8-bit numbers:
\
\   (A P) = P * Q
\
\ ******************************************************************************

.MULTU

 LDX Q                  \ Set X = Q

 BEQ MU1                \ If X = Q = 0, jump to MU1 to copy X into P and A,
                        \ clear the C flag and return from the subroutine using
                        \ a tail call

                        \ Otherwise fall through into MU11 to set (A P) = P * X

\ ******************************************************************************
\
\       Name: MU11
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = P * X
\  Deep dive: Shift-and-add multiplication
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of two unsigned 8-bit numbers:
\
\   (A P) = P * X
\
\ This uses the same shift-and-add approach as MULT1, but it's simpler as we
\ are dealing with unsigned numbers in P and X. See the deep dive on
\ "Shift-and-add multiplication" for a discussion of how this algorithm works.
\
\ ******************************************************************************

.MU11

 DEX                    \ Set T = X - 1
 STX T                  \
                        \ We subtract 1 as the C flag will be set when we want
                        \ to do an addition in the loop below

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 LDX #8                 \ Set up a counter in X to count the 8 bits in P

 LSR P                  \ Set P = P >> 1
                        \ and C flag = bit 0 of P

                        \ We are now going to work our way through the bits of
                        \ P, and do a shift-add for any bits that are set,
                        \ keeping the running total in A. We just did the first
                        \ shift right, so we now need to do the first add and
                        \ loop through the other bits in P

.MUL6

 BCC P%+4               \ If C (i.e. the next bit from P) is set, do the
 ADC T                  \ addition for this bit of P:
                        \
                        \   A = A + T + C
                        \     = A + X - 1 + 1
                        \     = A + X

 ROR A                  \ Shift A right to catch the next digit of our result,
                        \ which the next ROR sticks into the left end of P while
                        \ also extracting the next bit of P

 ROR P                  \ Add the overspill from shifting A to the right onto
                        \ the start of P, and shift P right to fetch the next
                        \ bit for the calculation into the C flag

 DEX                    \ Decrement the loop counter

 BNE MUL6               \ Loop back for the next bit until P has been rotated
                        \ all the way

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: FMLTU2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate A = K * sin(A)
\  Deep dive: The sine, cosine and arctan tables
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   A = K * sin(A)
\
\ Because this routine uses the sine lookup table SNE, we can also call this
\ routine to calculate cosine multiplication. To calculate the following:
\
\   A = K * cos(B)
\
\ call this routine with B + 16 in the accumulator, as sin(B + 16) = cos(B).
\
\ ******************************************************************************

.FMLTU2

 AND #%00011111         \ Restrict A to bits 0-5 (so it's in the range 0-31)

 TAX                    \ Set Q = sin(A) * 256
 LDA SNE,X
 STA Q

 LDA K                  \ Set A to the radius in K

                        \ Fall through into FMLTU to do the following:
                        \
                        \   (A ?) = A * Q
                        \         = K * sin(A) * 256
                        \
                        \ which is equivalent to:
                        \
                        \   A = K * sin(A)

\ ******************************************************************************
\
\       Name: FMLTU
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate A = A * Q / 256
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of two unsigned 8-bit numbers, returning only
\ the high byte of the result:
\
\   (A ?) = A * Q
\
\ or, to put it another way:
\
\   A = A * Q / 256
\
\ ******************************************************************************

.FMLTU

 EOR #%11111111         \ Flip the bits in A, set the C flag and rotate right,
 SEC                    \ so the C flag now contains bit 0 of A inverted, and P
 ROR A                  \ contains A inverted and shifted right by one, with bit
 STA P                  \ 7 set to a 1. We can now use P as our source of bits
                        \ to shift right, just as in MU11, just with the logic
                        \ reversed

 LDA #0                 \ Set A = 0 so we can start building the answer in A

.MUL3

 BCS MU7                \ If C (i.e. the next bit from P) is set, do not do the
                        \ addition for this bit of P, and instead skip to MU7
                        \ to just do the shifts

 ADC Q                  \ Do the addition for this bit of P:
                        \
                        \   A = A + Q + C
                        \     = A + Q

 ROR A                  \ Shift A right to catch the next digit of our result.
                        \ If we were interested in the low byte of the result we
                        \ would want to save the bit that falls off the end, but
                        \ we aren't, so we can ignore it

 LSR P                  \ Shift P right to fetch the next bit for the
                        \ calculation into the C flag

 BNE MUL3               \ Loop back to MUL3 if P still contains some set bits
                        \ (so we loop through the bits of P until we get to the
                        \ 1 we inserted before the loop, and then we stop)

 RTS                    \ Return from the subroutine

.MU7

 LSR A                  \ Shift A right to catch the next digit of our result,
                        \ pushing a 0 into bit 7 as we aren't adding anything
                        \ here (we can't use a ROR here as the C flag is set, so
                        \ a ROR would push a 1 into bit 7)

 LSR P                  \ Fetch the next bit from P into the C flag

 BNE MUL3               \ Loop back to MUL3 if P still contains some set bits
                        \ (so we loop through the bits of P until we get to the
                        \ 1 we inserted before the loop, and then we stop)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MULT1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = Q * A
\  Deep dive: Shift-and-add multiplication
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of two 8-bit sign-magnitude numbers:
\
\   (A P) = Q * A
\
\ ******************************************************************************

.MULT1

 TAX                    \ Store A in X

 AND #%01111111         \ Set P = |A| >> 1
 LSR A                  \ and C flag = bit 0 of A
 STA P

 TXA                    \ Restore argument A

 EOR Q                  \ Set bit 7 of A and T if Q and A have different signs,
 AND #%10000000         \ clear bit 7 if they have the same signs, 0 all other
 STA T                  \ bits, i.e. T contains the sign bit of Q * A

 LDA Q                  \ Set A = |Q|
 AND #%01111111

 BEQ mu10               \ If |Q| = 0 jump to mu10 (with A set to 0)

 TAX                    \ Set T1 = |Q| - 1
 DEX                    \
 STX T1                 \ We subtract 1 as the C flag will be set when we want
                        \ to do an addition in the loop below

                        \ We are now going to work our way through the bits of
                        \ P, and do a shift-add for any bits that are set,
                        \ keeping the running total in A. We already set up
                        \ the first shift at the start of this routine, as
                        \ P = |A| >> 1 and C = bit 0 of A, so we now need to set
                        \ up a loop to sift through the other 7 bits in P

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 LDX #7                 \ Set up a counter in X to count the 7 bits remaining
                        \ in P

.MUL4

 BCC P%+4               \ If C (i.e. the next bit from P) is set, do the
 ADC T1                 \ addition for this bit of P:
                        \
                        \   A = A + T1 + C
                        \     = A + |Q| - 1 + 1
                        \     = A + |Q|

 ROR A                  \ As mentioned above, this ROR shifts A right and
                        \ catches bit 0 in C - giving another digit for our
                        \ result - and the next ROR sticks that bit into the
                        \ left end of P while also extracting the next bit of P
                        \ for the next addition

 ROR P                  \ Add the overspill from shifting A to the right onto
                        \ the start of P, and shift P right to fetch the next
                        \ bit for the calculation

 DEX                    \ Decrement the loop counter

 BNE MUL4               \ Loop back for the next bit until P has been rotated
                        \ all the way

 LSR A                  \ Rotate (A P) once more to get the final result, as
 ROR P                  \ we only pushed 7 bits through the above process

 ORA T                  \ Set the sign bit of the result that we stored in T

 RTS                    \ Return from the subroutine

.mu10

 STA P                  \ If we get here, the result is 0 and A = 0, so set
                        \ P = 0 so (A P) = 0

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MULT12
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (S R) = Q * A
\
\ ------------------------------------------------------------------------------
\
\ Calculate:
\
\   (S R) = Q * A
\
\ ******************************************************************************

.MULT12

 JSR MULT1              \ Set (A P) = Q * A

 STA S                  \ Set (S R) = (A P)
 LDA P
 STA R

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MAD
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A X) = Q * A + (S R)
\
\ ------------------------------------------------------------------------------
\
\ Calculate
\
\   (A X) = Q * A + (S R)
\
\ ******************************************************************************

.MAD

 JSR MULT1              \ Call MULT1 to set (A P) = Q * A

                        \ Fall through into ADD to do:
                        \
                        \   (A X) = (A P) + (S R)
                        \         = Q * A + (S R)

\ ******************************************************************************
\
\       Name: ADD
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A X) = (A P) + (S R)
\  Deep dive: Adding sign-magnitude numbers
\
\ ------------------------------------------------------------------------------
\
\ Add two 16-bit sign-magnitude numbers together, calculating:
\
\   (A X) = (A P) + (S R)
\
\ ******************************************************************************

.ADD

 STA T1                 \ Store argument A in T1

 AND #%10000000         \ Extract the sign (bit 7) of A and store it in T
 STA T

 EOR S                  \ EOR bit 7 of A with S. If they have different bit 7s
 BMI MU8                \ (i.e. they have different signs) then bit 7 in the
                        \ EOR result will be 1, which means the EOR result is
                        \ negative. So the AND, EOR and BMI together mean "jump
                        \ to MU8 if A and S have different signs"

                        \ If we reach here, then A and S have the same sign, so
                        \ we can add them and set the sign to get the result

 LDA R                  \ Add the least significant bytes together into X:
 CLC                    \
 ADC P                  \   X = P + R
 TAX

 LDA S                  \ Add the most significant bytes together into A. We
 ADC T1                 \ stored the original argument A in T1 earlier, so we
                        \ can do this with:
                        \
                        \   A = A  + S + C
                        \     = T1 + S + C

 ORA T                  \ If argument A was negative (and therefore S was also
                        \ negative) then make sure result A is negative by
                        \ OR-ing the result with the sign bit from argument A
                        \ (which we stored in T)

 RTS                    \ Return from the subroutine

.MU8

                        \ If we reach here, then A and S have different signs,
                        \ so we can subtract their absolute values and set the
                        \ sign to get the result

 LDA S                  \ Clear the sign (bit 7) in S and store the result in
 AND #%01111111         \ U, so U now contains |S|
 STA U

 LDA P                  \ Subtract the least significant bytes into X:
 SEC                    \
 SBC R                  \   X = P - R
 TAX

 LDA T1                 \ Restore the A of the argument (A P) from T1 and
 AND #%01111111         \ clear the sign (bit 7), so A now contains |A|

 SBC U                  \ Set A = |A| - |S|

                        \ At this point we have |A P| - |S R| in (A X), so we
                        \ need to check whether the subtraction above was the
                        \ the right way round (i.e. that we subtracted the
                        \ smaller absolute value from the larger absolute
                        \ value)

 BCS MU9                \ If |A| >= |S|, our subtraction was the right way
                        \ round, so jump to MU9 to set the sign

                        \ If we get here, then |A| < |S|, so our subtraction
                        \ above was the wrong way round (we actually subtracted
                        \ the larger absolute value from the smaller absolute
                        \ value). So let's subtract the result we have in (A X)
                        \ from zero, so that the subtraction is the right way
                        \ round

 STA U                  \ Store A in U

 TXA                    \ Set X = 0 - X using two's complement (to negate a
 EOR #&FF               \ number in two's complement, you can invert the bits
 ADC #1                 \ and add one - and we know the C flag is clear as we
 TAX                    \ didn't take the BCS branch above, so the ADC will do
                        \ the correct addition)

 LDA #0                 \ Set A = 0 - A, which we can do this time using a
 SBC U                  \ a subtraction with the C flag clear

 ORA #%10000000         \ We now set the sign bit of A, so that the EOR on the
                        \ next line will give the result the opposite sign to
                        \ argument A (as T contains the sign bit of argument
                        \ A). This is the same as giving the result the same
                        \ sign as argument S (as A and S have different signs),
                        \ which is what we want, as S has the larger absolute
                        \ value

.MU9

 EOR T                  \ If we get here from the BCS above, then |A| >= |S|,
                        \ so we want to give the result the same sign as
                        \ argument A, so if argument A was negative, we flip
                        \ the sign of the result with an EOR (to make it
                        \ negative)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TIS1
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A ?) = (-X * A + (S R)) / 96
\  Deep dive: Shift-and-subtract division
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following expression between sign-magnitude numbers, ignoring
\ the low byte of the result:
\
\   (A ?) = (-X * A + (S R)) / 96
\
\ This uses the same shift-and-subtract algorithm as TIS2, just with the
\ quotient A hard-coded to 96.
\
\ Returns:
\
\   Q                   Gets set to the value of argument X
\
\ ******************************************************************************

.TIS1

 STX Q                  \ Set Q = X

 EOR #%10000000         \ Flip the sign bit in A

 JSR MAD                \ Set (A X) = Q * A + (S R)
                        \           = X * -A + (S R)

.DVID96

 TAX                    \ Set T to the sign bit of the result
 AND #%10000000
 STA T

 TXA                    \ Set A to the high byte of the result with the sign bit
 AND #%01111111         \ cleared, so (A ?) = |X * A + (S R)|

                        \ The following is identical to TIS2, except Q is
                        \ hard-coded to 96, so this does A = A / 96

 LDX #254               \ Set T1 to have bits 1-7 set, so we can rotate through
 STX T1                 \ 7 loop iterations, getting a 1 each time, and then
                        \ getting a 0 on the 8th iteration... and we can also
                        \ use T1 to catch our result bits into bit 0 each time

.DVL3

 ASL A                  \ Shift A to the left

 CMP #96                \ If A < 96 skip the following subtraction
 BCC DV4

 SBC #96                \ Set A = A - 96
                        \
                        \ Going into this subtraction we know the C flag is
                        \ set as we passed through the BCC above, and we also
                        \ know that A >= 96, so the C flag will still be set
                        \ once we are done

.DV4

 ROL T1                 \ Rotate the counter in T1 to the left, and catch the
                        \ result bit into bit 0 (which will be a 0 if we didn't
                        \ do the subtraction, or 1 if we did)

 BCS DVL3               \ If we still have set bits in T1, loop back to DVL3 to
                        \ do the next iteration of 7

 LDA T1                 \ Fetch the result from T1 into A

 ORA T                  \ Give A the sign of the result that we stored above

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PDESC
\       Type: Subroutine
\   Category: Text
\    Summary: Print the system's extended description or a mission 1 directive
\  Deep dive: Extended system descriptions
\             Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This prints a specific system's extended description. This is called the "pink
\ volcanoes string" in a comment in the original source, and the "goat soup"
\ recipe by Ian Bell on his website (where he also refers to the species string
\ as the "pink felines" string).
\
\ For some special systems, when you are docked at them, the procedurally
\ generated extended description is overridden and a text token from the RUTOK
\ table is shown instead. If mission 1 is in progress, then a number of systems
\ along the route of that mission's story will show custom mission-related
\ directives in place of that system's normal "goat soup" phrase.
\
\ Arguments:
\
\   ZZ                  The system number (0-255)
\
\ Other entry points:
\
\   PD1                 Print the standard "goat soup" description without
\                       checking for overrides
\
\ ******************************************************************************

.PDESC

                        \ --- Original Acornsoft code removed: ---------------->

\ LDA QQ8               \ If either byte in QQ18(1 0) is non-zero, meaning that
\ ORA QQ8+1             \ the distance from the current system to the selected
\ BNE PD1               \ is non-zero, jump to PD1 to show the standard "goat
\                       \ soup" description
\
\                       \ If we get here, then the current system is the same as
\                       \ the selected system and we are docked, so now to check
\                       \ whether there is a special override token for this
\                       \ system
\
\ LDY #NRU%             \ Set Y as a loop counter as we work our way through the
\                       \ system numbers in RUPLA, starting at NRU% (which is
\                       \ the number of entries in RUPLA, 26) and working our
\                       \ way down to 1
\
\.PDL1
\
\ LDA RUPLA-1,Y         \ Fetch the Y-th byte from RUPLA-1 into A (we use
\                       \ RUPLA-1 because Y is looping from 26 to 1
\
\ CMP ZZ                \ If A doesn't match the system whose description we
\ BNE PD2               \ are printing (in ZZ), junp to PD2 to keep looping
\                       \ through the system numbers in RUPLA
\
\                       \ If we get here we have found a match for this system
\                       \ number in RUPLA
\
\ LDA RUGAL-1,Y         \ Fetch the Y-th byte from RUGAL-1 into A
\
\ AND #%01111111        \ Extract bits 0-6 of A
\
\ CMP GCNT              \ If the result does not equal the current galaxy
\ BNE PD2               \ number, jump to PD2 to keep looping through the system
\                       \ numbers in RUPLA
\
\ LDA RUGAL-1,Y         \ Fetch the Y-th byte from RUGAL-1 into A, once again
\
\ BMI PD3               \ If bit 7 is set, jump to PD3 to print the extended
\                       \ token in A from the second table in RUTOK
\
\ LDA TP                \ Fetch bit 0 of TP into the C flag, and skip to PD1 if
\ LSR A                 \ it is clear (i.e. if mission 1 is not in progress) to
\ BCC PD1               \ print the "goat soup" extended description
\
\                       \ If we get here then mission 1 is in progress, so we
\                       \ print out the corresponding token from RUTOK
\
\ JSR MT14              \ Call MT14 to switch to justified text
\
\ LDA #1                \ Set A = 1 so that extended token 1 (an empty string)
\                       \ gets printed below instead of token 176, followed by
\                       \ the Y-th token in RUTOK
\
\ EQUB &2C              \ Skip the next instruction by turning it into
\                       \ &2C &A9 &B0, or BIT &B0A9, which does nothing apart
\                       \ from affect the flags
\
\.PD3
\
\ LDA #176              \ Print extended token 176 ("{lower case}{justify}
\ JSR DETOK2            \ {single cap}")
\
\ TYA                   \ Print the extended token in Y from the second table
\ JSR DETOK3            \ in RUTOK
\
\ LDA #177              \ Set A = 177 so when we jump to PD4 in the next
\                       \ instruction, we print token 177 (".{cr}{left align}")
\
\ BNE PD4               \ Jump to PD4 to print the extended token in A and
\                       \ return from the subroutine using a tail call
\
\.PD2
\
\ DEY                   \ Decrement the byte counter in Y
\
\ BNE PDL1              \ Loop back to check the next byte in RUPLA until we
\                       \ either find a match for the system in ZZ, or we fall
\                       \ through into the "goat soup" extended description
\                       \ routine

                        \ --- End of removed code ----------------------------->

.PD1

                        \ We now print the "goat soup" extended description

 LDX #3                 \ We now want to seed the random number generator with
                        \ the s1 and s2 16-bit seeds from the current system, so
                        \ we get the same extended description for each system
                        \ every time we call PDESC, so set a counter in X for
                        \ copying 4 bytes

{
.PDL1                   \ This label is a duplicate of the label above (which is
                        \ why we need to surround it with braces, as BeebAsm
                        \ doesn't allow us to redefine labels, unlike BBC BASIC)

 LDA QQ15+2,X           \ Copy QQ15+2 to QQ15+5 (s1 and s2) to RAND to RAND+3
 STA RAND,X

 DEX                    \ Decrement the loop counter

 BPL PDL1               \ Loop back to PDL1 until we have copied all

 LDA #5                 \ Set A = 5, so we print extended token 5 in the next
                        \ instruction ("{lower case}{justify}{single cap}[86-90]
                        \ IS [140-144].{cr}{left align}"
}

.PD4

 JMP DETOK              \ Print the extended token given in A, and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: MT23
\       Type: Subroutine
\   Category: Text
\    Summary: Move to row 10, switch to white text, and switch to lower case
\             when printing extended tokens
\  Deep dive: Extended text tokens
\
\ ******************************************************************************

.MT23

 LDA #10                \ Set A = 10, so when we fall through into MT29, the
                        \ text cursor gets moved to row 10

 EQUB &2C               \ Skip the next instruction by turning it into
                        \ &2C &A9 &06, or BIT &06A9, which does nothing apart
                        \ from affect the flags

                        \ Fall through into MT29 to move to the row in A, switch
                        \ to white text, and switch to lower case

\ ******************************************************************************
\
\       Name: MT29
\       Type: Subroutine
\   Category: Text
\    Summary: Move to row 6, switch to white text, and switch to lower case when
\             printing extended tokens
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ This routine sets the following:
\
\   * YC = 6 (move to row 6)
\
\ Then it calls WHITETEXT to switch to white text, before jumping to MT13 to
\ switch to lower case when printing extended tokens.
\
\ ******************************************************************************

.MT29

 LDA #6                 \ Move the text cursor to row 6
 STA YC

 JMP MT13               \ Jump to MT13 to set bit 7 of DTW6 and bit 5 of DTW1,
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: PAUSE2
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Wait until a key is pressed, ignoring any existing key press
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   X                   The internal key number of the key that was pressed
\
\ ******************************************************************************

.PAUSE2

 JSR RDKEY              \ Scan the keyboard for a key press and return the
                        \ internal key number in X (or 0 for no key press)

 BNE PAUSE2             \ If a key was already being held down when we entered
                        \ this routine, keep looping back up to PAUSE2, until
                        \ the key is released

                        \ --- Code added for Elite-A: ------------------------->

.l_out

                        \ --- End of added code ------------------------------->

 JSR RDKEY              \ Any pre-existing key press is now gone, so we can
                        \ start scanning the keyboard again, returning the
                        \ internal key number in X (or 0 for no key press)

                        \ --- Original Acornsoft code removed: ---------------->

\ BEQ PAUSE2            \ Keep looping up to PAUSE2 until a key is pressed

                        \ --- And replaced by: -------------------------------->

 BEQ l_out              \ AJD

                        \ --- End of replacement ------------------------------>

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT66
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Clear the screen and set the current view type
\
\ ------------------------------------------------------------------------------
\
\ Clear the top part of the screen, draw a white border, and set the current
\ view type in QQ11 to A.
\
\ Arguments:
\
\   A                   The type of the new current view (see QQ11 for a list of
\                       view types)
\
\ ******************************************************************************

.TT66

 STA QQ11               \ Set the current view type in QQ11 to A

                        \ Fall through into TTX66 to clear the screen and draw a
                        \ white border

\ ******************************************************************************
\
\       Name: TTX66
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Clear the top part of the screen and draw a white border
\
\ ------------------------------------------------------------------------------
\
\ Clear the top part of the screen (the space view) and draw a white border
\ along the top and sides.
\
\ Other entry points:
\
\   BOL1-1              Contains an RTS
\
\ ******************************************************************************

.TTX66

 JSR MT2                \ Switch to Sentence Case when printing extended tokens

 LDA #%10000000         \ Set bit 7 of QQ17 to switch to Sentence Case
 STA QQ17

 STA DTW2               \ Set bit 7 of DTW2 to indicate we are not currently
                        \ printing a word

 ASL A                  \ Set LASCT to 0, as 128 << 1 = %10000000 << 1 = 0. This
 STA LASCT              \ stops any laser pulsing

 STA DLY                \ Set the delay in DLY to 0, to indicate that we are
                        \ no longer showing an in-flight message, so any new
                        \ in-flight messages will be shown instantly

 STA de                 \ Clear de, the flag that appends " DESTROYED" to the
                        \ end of the next text token, so that it doesn't

 LDX #&60               \ Set X to the screen memory page for the top row of the
                        \ screen (as screen memory starts at &6000)

.BOL1

 JSR ZES1               \ Call ZES1 to zero-fill the page in X, which clears
                        \ that character row on the screen

 INX                    \ Increment X to point to the next page, i.e. the next
                        \ character row

 CPX #&78               \ Loop back to BOL1 until we have cleared page &7700,
 BNE BOL1               \ the last character row in the space view part of the
                        \ screen (the space view)

 LDY #1                 \ Move the text cursor to row 1
 STY YC

 LDA QQ11               \ If this is not a space view, jump to tt66 to skip
 BNE tt66               \ displaying the view name

 LDY #11                \ Move the text cursor to row 11
 STY XC

 LDA VIEW               \ Load the current view into A:
                        \
                        \   0 = front
                        \   1 = rear
                        \   2 = left
                        \   3 = right

 ORA #&60               \ OR with &60 so we get a value of &60 to &63 (96 to 99)

 JSR TT27               \ Print recursive token 96 to 99, which will be in the
                        \ range "FRONT" to "RIGHT"

 JSR TT162              \ Print a space

 LDA #175               \ Print recursive token 15 ("VIEW ")
 JSR TT27

.tt66

 LDX #0                 \ Set (X1, Y1) to (0, 0)
 STX X1
 STX Y1

 STX QQ17               \ Set QQ17 = 0 to switch to ALL CAPS

 DEX                    \ Set X2 = 255
 STX X2

 JSR HLOIN              \ Draw a horizontal line from (X1, Y1) to (X2, Y1), so
                        \ that's (0, 0) to (255, 0), along the very top of the
                        \ screen

 LDA #2                 \ Set X1 = X2 = 2
 STA X1
 STA X2

 JSR BOS2               \ Call BOS2 below, which will call BOS1 twice, and then
                        \ fall through into BOS2 again, so we effectively do
                        \ BOS1 four times, decrementing X1 and X2 each time
                        \ before calling LOIN, so this whole loop-within-a-loop
                        \ mind-bender ends up drawing these four lines:
                        \
                        \   (1, 0)   to (1, 191)
                        \   (0, 0)   to (0, 191)
                        \   (255, 0) to (255, 191)
                        \   (254, 0) to (254, 191)
                        \
                        \ So that's a 2-pixel wide vertical border along the
                        \ left edge of the upper part of the screen, and a
                        \ 2-pixel wide vertical border along the right edge

.BOS2

 JSR BOS1               \ Call BOS1 below and then fall through into it, which
                        \ ends up running BOS1 twice. This is all part of the
                        \ loop-the-loop border-drawing mind-bender explained
                        \ above

.BOS1

 LDA #0                 \ Set Y1 = 0
 STA Y1

 LDA #2*Y-1             \ Set Y2 = 2 * #Y - 1. The constant #Y is 96, the
 STA Y2                 \ y-coordinate of the mid-point of the space view, so
                        \ this sets Y2 to 191, the y-coordinate of the bottom
                        \ pixel row of the space view

 DEC X1                 \ Decrement X1 and X2
 DEC X2

 JMP LOIN               \ Draw a line from (X1, Y1) to (X2, Y2), and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: DELAY
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Wait for a specified time, in 1/50s of a second
\
\ ------------------------------------------------------------------------------
\
\ Wait for the number of vertical syncs given in Y, so this effectively waits
\ for Y/50 of a second (as the vertical sync occurs 50 times a second).
\
\ Arguments:
\
\   Y                   The number of vertical sync events to wait for
\
\ ******************************************************************************

.DELAY

 JSR WSCAN              \ Call WSCAN to wait for the vertical sync, so the whole
                        \ screen gets drawn

 DEY                    \ Decrement the counter in Y

 BNE DELAY              \ If Y isn't yet at zero, jump back to DELAY to wait
                        \ for another vertical sync

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: CLYNS
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Clear the bottom three text rows of the mode 4 screen
\
\ ------------------------------------------------------------------------------
\
\ Clear some space at the bottom of the screen and move the text cursor to
\ column 1, row 21. Specifically, this zeroes the following screen locations:
\
\   &7507 to &75F0
\   &7607 to &76F0
\   &7707 to &77F0
\
\ which clears the three bottom text rows of the mode 4 screen (rows 21 to 23),
\ clearing each row from text column 1 to 30 (so it doesn't overwrite the box
\ border in columns 0 and 32, or the last usable column in column 31).
\
\ Returns:
\
\   A                   A is set to 0
\
\   Y                   Y is set to 0
\
\ ******************************************************************************

.CLYNS

 LDA #%11111111         \ Set DTW2 = %11111111 to denote that we are not
 STA DTW2               \ currently printing a word

 LDA #20                \ Move the text cursor to row 20, near the bottom of
 STA YC                 \ the screen

 JSR TT67               \ Print a newline, which will move the text cursor down
                        \ a line (to row 21) and back to column 1

 LDA #&75               \ Set the two-byte value in SC to &7507
 STA SC+1
 LDA #7
 STA SC

 LDA #0                 \ Call LYN to clear the pixels from &7507 to &75F0
 JSR LYN

 INC SC+1               \ Increment SC+1 so SC points to &7607

 JSR LYN                \ Call LYN to clear the pixels from &7607 to &76F0

 INC SC+1               \ Increment SC+1 so SC points to &7707

 INY                    \ Move the text cursor to column 1 (as LYN sets Y to 0)
 STY XC

                        \ Fall through into LYN to clear the pixels from &7707
                        \ to &77F0

\ ******************************************************************************
\
\       Name: LYN
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Clear most of a row of pixels
\
\ ------------------------------------------------------------------------------
\
\ Set pixels 0-233 to the value in A, starting at the pixel pointed to by SC.
\
\ Arguments:
\
\   A                   The value to store in pixels 1-233 (the only value that
\                       is actually used is A = 0, which clears those pixels)
\
\ Returns:
\
\   Y                   Y is set to 0
\
\ Other entry points:
\
\   SC5                 Contains an RTS
\
\ ******************************************************************************

.LYN

 LDY #233               \ Set up a counter in Y to count down from pixel 233

.EE2

 STA (SC),Y             \ Store A in the Y-th byte after the address pointed to
                        \ by SC

 DEY                    \ Decrement Y

 BNE EE2                \ Loop back until Y is zero

.SC5

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: WSCAN
\       Type: Subroutine
\   Category: Screen mode
\    Summary: Wait for the vertical sync
\
\ ------------------------------------------------------------------------------
\
\ Wait for vertical sync to occur on the video system - in other words, wait
\ for the screen to start its refresh cycle, which it does 50 times a second
\ (50Hz).
\
\ ******************************************************************************

.WSCAN

 LDA #0                 \ Set DL to 0
 STA DL

 LDA DL                 \ Loop round these two instructions until DL is no
 BEQ P%-2               \ longer 0 (DL gets set to 30 in the LINSCN routine,
                        \ which is run when vertical sync has occurred on the
                        \ video system, so DL will change to a non-zero value
                        \ at the start of each screen refresh)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\ Save output/ELTC.bin
\
\ ******************************************************************************

PRINT "ELITE C"
PRINT "Assembled at ", ~CODE_C%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_C%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_C%

PRINT "S.F.ELTC ", ~CODE_C%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_C%
\SAVE "output/F.ELTC.bin", CODE_C%, P%, LOAD%

\ ******************************************************************************
\
\ ELITE D FILE
\
\ ******************************************************************************

CODE_D% = P%
LOAD_D% = LOAD% + P% - CODE%

\ ******************************************************************************
\
\       Name: TT20
\       Type: Subroutine
\   Category: Universe
\    Summary: Twist the selected system's seeds four times
\  Deep dive: Twisting the system seeds
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Twist the three 16-bit seeds in QQ15 (selected system) four times, to
\ generate the next system.
\
\ ******************************************************************************

.TT20

 JSR P%+3               \ This line calls the line below as a subroutine, which
                        \ does two twists before returning here, and then we
                        \ fall through to the line below for another two
                        \ twists, so the net effect of these two consecutive
                        \ JSR calls is four twists, not counting the ones
                        \ inside your head as you try to follow this process

 JSR P%+3               \ This line calls TT54 as a subroutine to do a twist,
                        \ and then falls through into TT54 to do another twist
                        \ before returning from the subroutine

\ ******************************************************************************
\
\       Name: TT54
\       Type: Subroutine
\   Category: Universe
\    Summary: Twist the selected system's seeds
\  Deep dive: Twisting the system seeds
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ This routine twists the three 16-bit seeds in QQ15 once.
\
\ ******************************************************************************

.TT54

 LDA QQ15               \ X = tmp_lo = s0_lo + s1_lo
 CLC
 ADC QQ15+2
 TAX

 LDA QQ15+1             \ Y = tmp_hi = s1_hi + s1_hi + C
 ADC QQ15+3
 TAY

 LDA QQ15+2             \ s0_lo = s1_lo
 STA QQ15

 LDA QQ15+3             \ s0_hi = s1_hi
 STA QQ15+1

 LDA QQ15+5             \ s1_hi = s2_hi
 STA QQ15+3

 LDA QQ15+4             \ s1_lo = s2_lo
 STA QQ15+2

 CLC                    \ s2_lo = X + s1_lo
 TXA
 ADC QQ15+2
 STA QQ15+4

 TYA                    \ s2_hi = Y + s1_hi + C
 ADC QQ15+3
 STA QQ15+5

 RTS                    \ The twist is complete so return from the subroutine

\ ******************************************************************************
\
\       Name: TT146
\       Type: Subroutine
\   Category: Text
\    Summary: Print the distance to the selected system in light years
\
\ ------------------------------------------------------------------------------
\
\ If it is non-zero, print the distance to the selected system in light years.
\ If it is zero, just move the text cursor down a line.
\
\ Specifically, if the distance in QQ8 is non-zero, print token 31 ("DISTANCE"),
\ then a colon, then the distance to one decimal place, then token 35 ("LIGHT
\ YEARS"). If the distance is zero, move the cursor down one line.
\
\ ******************************************************************************

.TT146

 LDA QQ8                \ Take the two bytes of the 16-bit value in QQ8 and
 ORA QQ8+1              \ OR them together to check whether there are any
 BNE TT63               \ non-zero bits, and if so, jump to TT63 to print the
                        \ distance

 INC YC                 \ The distance is zero, so we just move the text cursor
 RTS                    \ in YC down by one line and return from the subroutine

.TT63

 LDA #191               \ Print recursive token 31 ("DISTANCE") followed by
 JSR TT68               \ a colon

 LDX QQ8                \ Load (Y X) from QQ8, which contains the 16-bit
 LDY QQ8+1              \ distance we want to show

 SEC                    \ Set the C flag so that the call to pr5 will include a
                        \ decimal point, and display the value as (Y X) / 10

 JSR pr5                \ Print (Y X) to 5 digits, including a decimal point

 LDA #195               \ Set A to the recursive token 35 (" LIGHT YEARS") and
                        \ fall through into TT60 to print the token followed
                        \ by a paragraph break

\ ******************************************************************************
\
\       Name: TT60
\       Type: Subroutine
\   Category: Text
\    Summary: Print a text token and a paragraph break
\
\ ------------------------------------------------------------------------------
\
\ Print a text token (i.e. a character, control code, two-letter token or
\ recursive token). Then print a paragraph break (a blank line between
\ paragraphs) by moving the cursor down a line, setting Sentence Case, and then
\ printing a newline.
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.TT60

 JSR TT27               \ Print the text token in A and fall through into TTX69
                        \ to print the paragraph break

\ ******************************************************************************
\
\       Name: TTX69
\       Type: Subroutine
\   Category: Text
\    Summary: Print a paragraph break
\
\ ------------------------------------------------------------------------------
\
\ Print a paragraph break (a blank line between paragraphs) by moving the cursor
\ down a line, and then printing a newline.
\
\ ******************************************************************************

.TTX69

 INC YC                 \ Move the text cursor down a line

                        \ Fall through into TT67 to print a newline

\ ******************************************************************************
\
\       Name: TT67
\       Type: Subroutine
\   Category: Text
\    Summary: Print a newline
\
\ ******************************************************************************

.TT67

 LDA #12                \ Load a newline character into A

 JMP TT27               \ Print the text token in A and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT70
\       Type: Subroutine
\   Category: Text
\    Summary: Display "MAINLY " and jump to TT72
\
\ ------------------------------------------------------------------------------
\
\ This subroutine is called by TT25 when displaying a system's economy.
\
\ ******************************************************************************

.TT70

 LDA #173               \ Print recursive token 13 ("MAINLY ")
 JSR TT27

 JMP TT72               \ Jump to TT72 to continue printing system data as part
                        \ of routine TT25

\ ******************************************************************************
\
\       Name: spc
\       Type: Subroutine
\   Category: Text
\    Summary: Print a text token followed by a space
\
\ ------------------------------------------------------------------------------
\
\ Print a text token (i.e. a character, control code, two-letter token or
\ recursive token) followed by a space.
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.spc

 JSR TT27               \ Print the text token in A

 JMP TT162              \ Print a space and return from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: TT25
\       Type: Subroutine
\   Category: Universe
\    Summary: Show the Data on System screen (red key f6)
\  Deep dive: Generating system data
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   TT72                Used by TT70 to re-enter the routine after displaying
\                       "MAINLY" for the economy type
\
\ ******************************************************************************

.TT25

 LDA #1                 \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 1

 LDA #9                 \ Move the text cursor to column 9
 STA XC

 LDA #163               \ Print recursive token 3 ("DATA ON {selected system
 JSR NLIN3              \ name}" and draw a horizontal line at pixel row 19
                        \ to box in the title

 JSR TTX69              \ Print a paragraph break and set Sentence Case

 JSR TT146              \ If the distance to this system is non-zero, print
                        \ "DISTANCE", then the distance, "LIGHT YEARS" and a
                        \ paragraph break, otherwise just move the cursor down
                        \ a line

 LDA #194               \ Print recursive token 34 ("ECONOMY") followed by
 JSR TT68               \ a colon

 LDA QQ3                \ The system economy is determined by the value in QQ3,
                        \ so fetch it into A. First we work out the system's
                        \ prosperity as follows:
                        \
                        \   QQ3 = 0 or 5 = %000 or %101 = Rich
                        \   QQ3 = 1 or 6 = %001 or %110 = Average
                        \   QQ3 = 2 or 7 = %010 or %111 = Poor
                        \   QQ3 = 3 or 4 = %011 or %100 = Mainly

 CLC                    \ If (QQ3 + 1) >> 1 = %10, i.e. if QQ3 = %011 or %100
 ADC #1                 \ (3 or 4), then call TT70, which prints "MAINLY " and
 LSR A                  \ jumps down to TT72 to print the type of economy
 CMP #%00000010
 BEQ TT70

 LDA QQ3                \ The LSR A above shifted bit 0 of QQ3 into the C flag,
 BCC TT71               \ so this jumps to TT71 if bit 0 of QQ3 is 0, in other
                        \ words if QQ3 = %000, %001 or %010 (0, 1 or 2)

 SBC #5                 \ Here QQ3 = %101, %110 or %111 (5, 6 or 7), so subtract
 CLC                    \ 5 to bring it down to 0, 1 or 2 (the C flag is already
                        \ set so the SBC will be correct)

.TT71

 ADC #170               \ A is now 0, 1 or 2, so print recursive token 10 + A.
 JSR TT27               \ This means that:
                        \
                        \   QQ3 = 0 or 5 prints token 10 ("RICH ")
                        \   QQ3 = 1 or 6 prints token 11 ("AVERAGE ")
                        \   QQ3 = 2 or 7 prints token 12 ("POOR ")

.TT72

 LDA QQ3                \ Now to work out the type of economy, which is
 LSR A                  \ determined by bit 2 of QQ3, as follows:
 LSR A                  \
                        \   QQ3 bit 2 = 0 = Industrial
                        \   QQ3 bit 2 = 1 = Agricultural
                        \
                        \ So we fetch QQ3 into A and set A = bit 2 of QQ3 using
                        \ two right shifts (which will work as QQ3 is only a
                        \ 3-bit number)

 CLC                    \ Print recursive token 8 + A, followed by a paragraph
 ADC #168               \ break and Sentence Case, so:
 JSR TT60               \
                        \   QQ3 bit 2 = 0 prints token 8 ("INDUSTRIAL")
                        \   QQ3 bit 2 = 1 prints token 9 ("AGRICULTURAL")

 LDA #162               \ Print recursive token 2 ("GOVERNMENT") followed by
 JSR TT68               \ a colon

 LDA QQ4                \ The system economy is determined by the value in QQ4,
                        \ so fetch it into A

 CLC                    \ Print recursive token 17 + A, followed by a paragraph
 ADC #177               \ break and Sentence Case, so:
 JSR TT60               \
                        \   QQ4 = 0 prints token 17 ("ANARCHY")
                        \   QQ4 = 1 prints token 18 ("FEUDAL")
                        \   QQ4 = 2 prints token 19 ("MULTI-GOVERNMENT")
                        \   QQ4 = 3 prints token 20 ("DICTATORSHIP")
                        \   QQ4 = 4 prints token 21 ("COMMUNIST")
                        \   QQ4 = 5 prints token 22 ("CONFEDERACY")
                        \   QQ4 = 6 prints token 23 ("DEMOCRACY")
                        \   QQ4 = 7 prints token 24 ("CORPORATE STATE")

 LDA #196               \ Print recursive token 36 ("TECH.LEVEL") followed by a
 JSR TT68               \ colon

 LDX QQ5                \ Fetch the tech level from QQ5 and increment it, as it
 INX                    \ is stored in the range 0-14 but the displayed range
                        \ should be 1-15

 CLC                    \ Call pr2 to print the technology level as a 3-digit
 JSR pr2                \ number without a decimal point (by clearing the C
                        \ flag)

 JSR TTX69              \ Print a paragraph break and set Sentence Case

 LDA #192               \ Print recursive token 32 ("POPULATION") followed by a
 JSR TT68               \ colon

 SEC                    \ Call pr2 to print the population as a 3-digit number
 LDX QQ6                \ with a decimal point (by setting the C flag), so the
 JSR pr2                \ number printed will be population / 10

 LDA #198               \ Print recursive token 38 (" BILLION"), followed by a
 JSR TT60               \ paragraph break and Sentence Case

 LDA #'('               \ Print an opening bracket
 JSR TT27

 LDA QQ15+4             \ Now to calculate the species, so first check bit 7 of
 BMI TT75               \ s2_lo, and if it is set, jump to TT75 as this is an
                        \ alien species

 LDA #188               \ Bit 7 of s2_lo is clear, so print recursive token 28
 JSR TT27               \ ("HUMAN COLONIAL")

 JMP TT76               \ Jump to TT76 to print "S)" and a paragraph break, so
                        \ the whole species string is "(HUMAN COLONIALS)"

.TT75

 LDA QQ15+5             \ This is an alien species, and we start with the first
 LSR A                  \ adjective, so fetch bits 2-7 of s2_hi into A and push
 LSR A                  \ onto the stack so we can use this later
 PHA

 AND #%00000111         \ Set A = bits 0-2 of A (so that's bits 2-4 of s2_hi)

 CMP #3                 \ If A >= 3, jump to TT205 to skip the first adjective,
 BCS TT205

 ADC #227               \ Otherwise A = 0, 1 or 2, so print recursive token
 JSR spc                \ 67 + A, followed by a space, so:
                        \
                        \   A = 0 prints token 67 ("LARGE") and a space
                        \   A = 1 prints token 67 ("FIERCE") and a space
                        \   A = 2 prints token 67 ("SMALL") and a space

.TT205

 PLA                    \ Now for the second adjective, so restore A to bits
 LSR A                  \ 2-7 of s2_hi, and throw away bits 2-4 to leave
 LSR A                  \ A = bits 5-7 of s2_hi
 LSR A

 CMP #6                 \ If A >= 6, jump to TT206 to skip the second adjective
 BCS TT206

 ADC #230               \ Otherwise A = 0 to 5, so print recursive token
 JSR spc                \ 70 + A, followed by a space, so:
                        \
                        \   A = 0 prints token 70 ("GREEN") and a space
                        \   A = 1 prints token 71 ("RED") and a space
                        \   A = 2 prints token 72 ("YELLOW") and a space
                        \   A = 3 prints token 73 ("BLUE") and a space
                        \   A = 4 prints token 74 ("BLACK") and a space
                        \   A = 5 prints token 75 ("HARMLESS") and a space

.TT206

 LDA QQ15+3             \ Now for the third adjective, so EOR the high bytes of
 EOR QQ15+1             \ s0 and s1 and extract bits 0-2 of the result:
 AND #%00000111         \
 STA QQ19               \   A = (s0_hi EOR s1_hi) AND %111
                        \
                        \ storing the result in QQ19 so we can use it later

 CMP #6                 \ If A >= 6, jump to TT207 to skip the third adjective
 BCS TT207

 ADC #236               \ Otherwise A = 0 to 5, so print recursive token
 JSR spc                \ 76 + A, followed by a space, so:
                        \
                        \   A = 0 prints token 76 ("SLIMY") and a space
                        \   A = 1 prints token 77 ("BUG-EYED") and a space
                        \   A = 2 prints token 78 ("HORNED") and a space
                        \   A = 3 prints token 79 ("BONY") and a space
                        \   A = 4 prints token 80 ("FAT") and a space
                        \   A = 5 prints token 81 ("FURRY") and a space

.TT207

 LDA QQ15+5             \ Now for the actual species, so take bits 0-1 of
 AND #%00000011         \ s2_hi, add this to the value of A that we used for
 CLC                    \ the third adjective, and take bits 0-2 of the result
 ADC QQ19
 AND #%00000111

 ADC #242               \ A = 0 to 7, so print recursive token 82 + A, so:
 JSR TT27               \
                        \   A = 0 prints token 76 ("RODENT")
                        \   A = 1 prints token 76 ("FROG")
                        \   A = 2 prints token 76 ("LIZARD")
                        \   A = 3 prints token 76 ("LOBSTER")
                        \   A = 4 prints token 76 ("BIRD")
                        \   A = 5 prints token 76 ("HUMANOID")
                        \   A = 6 prints token 76 ("FELINE")
                        \   A = 7 prints token 76 ("INSECT")

.TT76

 LDA #'S'               \ Print an "S" to pluralise the species
 JSR TT27

 LDA #')'               \ And finally, print a closing bracket, followed by a
 JSR TT60               \ paragraph break and Sentence Case, to end the species
                        \ section

 LDA #193               \ Print recursive token 33 ("GROSS PRODUCTIVITY"),
 JSR TT68               \ followed by colon

 LDX QQ7                \ Fetch the 16-bit productivity value from QQ7 into
 LDY QQ7+1              \ (Y X)

 JSR pr6                \ Print (Y X) to 5 digits with no decimal point

 JSR TT162              \ Print a space

 LDA #0                 \ Set QQ17 = 0 to switch to ALL CAPS
 STA QQ17

 LDA #'M'               \ Print "M"
 JSR TT27

 LDA #226               \ Print recursive token 66 (" CR"), followed by a
 JSR TT60               \ paragraph break and Sentence Case

 LDA #250               \ Print recursive token 90 ("AVERAGE RADIUS"), followed
 JSR TT68               \ by a colon

                        \ The average radius is calculated like this:
                        \
                        \   ((s2_hi AND %1111) + 11) * 256 + s1_hi
                        \
                        \ or, in terms of memory locations:
                        \
                        \   ((QQ15+5 AND %1111) + 11) * 256 + QQ15+3
                        \
                        \ Because the multiplication is by 256, this is the
                        \ same as saying a 16-bit number, with high byte:
                        \
                        \   (QQ15+5 AND %1111) + 11
                        \
                        \ and low byte:
                        \
                        \   QQ15+3
                        \
                        \ so we can set this up in (Y X) and call the pr5
                        \ routine to print it out

 LDA QQ15+5             \ Set A = QQ15+5
 LDX QQ15+3             \ Set X = QQ15+3

 AND #%00001111         \ Set Y = (A AND %1111) + 11
 CLC
 ADC #11
 TAY

 JSR pr5                \ Print (Y X) to 5 digits, not including a decimal
                        \ point, as the C flag will be clear (as the maximum
                        \ radius will always fit into 16 bits)

 JSR TT162              \ Print a space

 LDA #'k'               \ Print "km"
 JSR TT26
 LDA #'m'
 JSR TT26

 JSR TTX69              \ Print a paragraph break and set Sentence Case

                        \ By this point, ZZ contains the current system number
                        \ which PDESC requires. It gets put there in the TT102
                        \ routine, which calls TT111 to populate ZZ before
                        \ calling TT25 (this routine)

                        \ --- Original Acornsoft code removed: ---------------->

\ JMP PDESC             \ Jump to PDESC to print the system's extended
\                       \ description, returning from the subroutine using a
\                       \ tail call
\
\                       \ The following code doesn't appear to be called from
\                       \ anywhere, so it's presumably a remnant of code from
\                       \ an earlier version of the extended description code
\
\ LDX ZZ                \ Fetch the system number from ZZ into X
\
\\LDY #LO(PTEXT)        \ These instructions are commented out in the original
\\STY INWK              \ source. The variable PTEXT doesn't exist, so it isn't
\\LDY #HI(PTEXT)-1      \ entirely obvious what this code does, though it looks
\\STY INWK+1            \ like it loops through a table of text tokens in PTEXT
\\LDY #&FF              \ until we get to the entry for the current system,
\\.PDT1                 \ which it prints out as text tokens (so perhaps PTEXT
\\INY                   \ used to be a token table for the system's extended
\\BNE P%+4              \ descriptions before PDESC took over)
\\INC INWK+1
\\LDA (INWK),Y
\\BNE PDT1
\\DEX
\\BNE PDT1
\\.PDT2
\\INY
\\BNE P%+4
\\INC INWK+1
\\STY INWK+2
\\LDA (INWK),Y
\\BEQ TT24-1
\\JSR TT27
\\LDY INWK+2
\\JMP PDT2
\
\ RTS                   \ Return from the subroutine

                        \ --- And replaced by: -------------------------------->

 JMP PD1                \ AJD

                        \ --- End of replacement ------------------------------>

\ ******************************************************************************
\
\       Name: TT24
\       Type: Subroutine
\   Category: Universe
\    Summary: Calculate system data from the system seeds
\  Deep dive: Generating system data
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Calculate system data from the seeds in QQ15 and store them in the relevant
\ locations. Specifically, this routine calculates the following from the three
\ 16-bit seeds in QQ15 (using only s0_hi, s1_hi and s1_lo):
\
\   QQ3 = economy (0-7)
\   QQ4 = government (0-7)
\   QQ5 = technology level (0-14)
\   QQ6 = population * 10 (1-71)
\   QQ7 = productivity (96-62480)
\
\ The ranges of the various values are shown in brackets. Note that the radius
\ and type of inhabitant are calculated on-the-fly in the TT25 routine when
\ the system data gets displayed, so they aren't calculated here.
\
\ ******************************************************************************

.TT24

 LDA QQ15+1             \ Fetch s0_hi and extract bits 0-2 to determine the
 AND #%00000111         \ system's economy, and store in QQ3
 STA QQ3

 LDA QQ15+2             \ Fetch s1_lo and extract bits 3-5 to determine the
 LSR A                  \ system's government, and store in QQ4
 LSR A
 LSR A
 AND #%00000111
 STA QQ4

 LSR A                  \ If government isn't anarchy or feudal, skip to TT77,
 BNE TT77               \ as we need to fix the economy of anarchy and feudal
                        \ systems so they can't be rich

 LDA QQ3                \ Set bit 1 of the economy in QQ3 to fix the economy
 ORA #%00000010         \ for anarchy and feudal governments
 STA QQ3

.TT77

 LDA QQ3                \ Now to work out the tech level, which we do like this:
 EOR #%00000111         \
 CLC                    \   flipped_economy + (s1_hi AND %11) + (government / 2)
 STA QQ5                \
                        \ or, in terms of memory locations:
                        \
                        \   QQ5 = (QQ3 EOR %111) + (QQ15+3 AND %11) + (QQ4 / 2)
                        \
                        \ We start by setting QQ5 = QQ3 EOR %111

 LDA QQ15+3             \ We then take the first 2 bits of s1_hi (QQ15+3) and
 AND #%00000011         \ add it into QQ5
 ADC QQ5
 STA QQ5

 LDA QQ4                \ And finally we add QQ4 / 2 and store the result in
 LSR A                  \ QQ5, using LSR then ADC to divide by 2, which rounds
 ADC QQ5                \ up the result for odd-numbered government types
 STA QQ5

 ASL A                  \ Now to work out the population, like so:
 ASL A                  \
 ADC QQ3                \   (tech level * 4) + economy + government + 1
 ADC QQ4                \
 ADC #1                 \ or, in terms of memory locations:
 STA QQ6                \
                        \   QQ6 = (QQ5 * 4) + QQ3 + QQ4 + 1

 LDA QQ3                \ Finally, we work out productivity, like this:
 EOR #%00000111         \
 ADC #3                 \  (flipped_economy + 3) * (government + 4)
 STA P                  \                        * population
 LDA QQ4                \                        * 8
 ADC #4                 \
 STA Q                  \ or, in terms of memory locations:
 JSR MULTU              \
                        \   QQ7 = (QQ3 EOR %111 + 3) * (QQ4 + 4) * QQ6 * 8
                        \
                        \ We do the first step by setting P to the first
                        \ expression in brackets and Q to the second, and
                        \ calling MULTU, so now (A P) = P * Q. The highest this
                        \ can be is 10 * 11 (as the maximum values of economy
                        \ and government are 7), so the high byte of the result
                        \ will always be 0, so we actually have:
                        \
                        \   P = P * Q
                        \     = (flipped_economy + 3) * (government + 4)

 LDA QQ6                \ We now take the result in P and multiply by the
 STA Q                  \ population to get the productivity, by setting Q to
 JSR MULTU              \ the population from QQ6 and calling MULTU again, so
                        \ now we have:
                        \
                        \   (A P) = P * population

 ASL P                  \ Next we multiply the result by 8, as a 16-bit number,
 ROL A                  \ so we shift both bytes to the left three times, using
 ASL P                  \ the C flag to carry bits from bit 7 of the low byte
 ROL A                  \ into bit 0 of the high byte
 ASL P
 ROL A

 STA QQ7+1              \ Finally, we store the productivity in two bytes, with
 LDA P                  \ the low byte in QQ7 and the high byte in QQ7+1
 STA QQ7

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT22
\       Type: Subroutine
\   Category: Charts
\    Summary: Show the Long-range Chart (red key f4)
\
\ ******************************************************************************

.TT22

 LDA #64                \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 32 (Long-
                        \ range Chart)

 LDA #7                 \ Move the text cursor to column 7
 STA XC

 JSR TT81               \ Set the seeds in QQ15 to those of system 0 in the
                        \ current galaxy (i.e. copy the seeds from QQ21 to QQ15)

 LDA #199               \ Print recursive token 39 ("GALACTIC CHART{galaxy
 JSR TT27               \ number right-aligned to width 3}")

 JSR NLIN               \ Draw a horizontal line at pixel row 23 to box in the
                        \ title and act as the top frame of the chart, and move
                        \ the text cursor down one line

 LDA #152               \ Draw a screen-wide horizontal line at pixel row 152
 JSR NLIN2              \ for the bottom edge of the chart, so the chart itself
                        \ is 128 pixels high, starting on row 24 and ending on
                        \ row 151

 JSR TT14               \ Call TT14 to draw a circle with crosshairs at the
                        \ current system's galactic coordinates

 LDX #0                 \ We're now going to plot each of the galaxy's systems,
                        \ so set up a counter in X for each system, starting at
                        \ 0 and looping through to 255

.TT83

 STX XSAV               \ Store the counter in XSAV

 LDX QQ15+3             \ Fetch the s1_hi seed into X, which gives us the
                        \ galactic x-coordinate of this system

 LDY QQ15+4             \ Fetch the s2_lo seed and set bits 4 and 6, storing the
 TYA                    \ result in ZZ to give a random number between 80 and
 ORA #%01010000         \ (but which will always be the same for this system).
 STA ZZ                 \ We use this value to determine the size of the point
                        \ for this system on the chart by passing it as the
                        \ distance argument to the PIXEL routine below

 LDA QQ15+1             \ Fetch the s0_hi seed into A, which gives us the
                        \ galactic y-coordinate of this system

 LSR A                  \ We halve the y-coordinate because the galaxy in
                        \ in Elite is rectangular rather than square, and is
                        \ twice as wide (x-axis) as it is high (y-axis), so the
                        \ chart is 256 pixels wide and 128 high

 CLC                    \ Add 24 to the halved y-coordinate and store in XX15+1
 ADC #24                \ (as the top of the chart is on pixel row 24, just
 STA XX15+1             \ below the line we drew on row 23 above)

 JSR PIXEL              \ Call PIXEL to draw a point at (X, A), with the size of
                        \ the point dependent on the distance specified in ZZ
                        \ (so a high value of ZZ will produce a 1-pixel point,
                        \ a medium value will produce a 2-pixel dash, and a
                        \ small value will produce a 4-pixel square)

 JSR TT20               \ We want to move on to the next system, so call TT20
                        \ to twist the three 16-bit seeds in QQ15

 LDX XSAV               \ Restore the loop counter from XSAV

 INX                    \ Increment the counter

 BNE TT83               \ If X > 0 then we haven't done all 256 systems yet, so
                        \ loop back up to TT83

 LDA QQ9                \ Set QQ19 to the selected system's x-coordinate
 STA QQ19

 LDA QQ10               \ Set QQ19+1 to the selected system's y-coordinate,
 LSR A                  \ halved to fit it into the chart
 STA QQ19+1

 LDA #4                 \ Set QQ19+2 to size 4 for the crosshairs size
 STA QQ19+2

                        \ Fall through into TT15 to draw crosshairs of size 4 at
                        \ the selected system's coordinates

\ ******************************************************************************
\
\       Name: TT15
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a set of crosshairs
\
\ ------------------------------------------------------------------------------
\
\ For all views except the Short-range Chart, the centre is drawn 24 pixels to
\ the right of the y-coordinate given.
\
\ Arguments:
\
\   QQ19                The pixel x-coordinate of the centre of the crosshairs
\
\   QQ19+1              The pixel y-coordinate of the centre of the crosshairs
\
\   QQ19+2              The size of the crosshairs
\
\ ******************************************************************************

.TT15

 LDA #24                \ Set A to 24, which we will use as the minimum
                        \ screen indent for the crosshairs (i.e. the minimum
                        \ distance from the top-left corner of the screen)

 LDX QQ11               \ If the current view is not the Short-range Chart,
 BPL P%+4               \ which is the only view with bit 7 set, then skip the
                        \ following instruction

 LDA #0                 \ This is the Short-range Chart, so set A to 0, so the
                        \ crosshairs can go right up against the screen edges

 STA QQ19+5             \ Set QQ19+5 to A, which now contains the correct indent
                        \ for this view

 LDA QQ19               \ Set A = crosshairs x-coordinate - crosshairs size
 SEC                    \ to get the x-coordinate of the left edge of the
 SBC QQ19+2             \ crosshairs

 BCS TT84               \ If the above subtraction didn't underflow, then A is
                        \ positive, so skip the next instruction

 LDA #0                 \ The subtraction underflowed, so set A to 0 so the
                        \ crosshairs don't spill out of the left of the screen

.TT84

                        \ In the following, the authors have used XX15 for
                        \ temporary storage. XX15 shares location with X1, Y1,
                        \ X2 and Y2, so in the following, you can consider
                        \ the variables like this:
                        \
                        \   XX15   is the same as X1
                        \   XX15+1 is the same as Y1
                        \   XX15+2 is the same as X2
                        \   XX15+3 is the same as Y2
                        \
                        \ Presumably this routine was written at a different
                        \ time to the line-drawing routine, before the two
                        \ workspaces were merged to save space

 STA XX15               \ Set XX15 (X1) = A (the x-coordinate of the left edge
                        \ of the crosshairs)

 LDA QQ19               \ Set A = crosshairs x-coordinate + crosshairs size
 CLC                    \ to get the x-coordinate of the right edge of the
 ADC QQ19+2             \ crosshairs

 BCC P%+4               \ If the above addition didn't overflow, then A is
                        \ correct, so skip the next instruction

 LDA #255               \ The addition overflowed, so set A to 255 so the
                        \ crosshairs don't spill out of the right of the screen
                        \ (as 255 is the x-coordinate of the rightmost pixel
                        \ on-screen)

 STA XX15+2             \ Set XX15+2 (X2) = A (the x-coordinate of the right
                        \ edge of the crosshairs)

 LDA QQ19+1             \ Set XX15+1 (Y1) = crosshairs y-coordinate + indent
 CLC                    \ to get the y-coordinate of the centre of the
 ADC QQ19+5             \ crosshairs
 STA XX15+1

 JSR HLOIN              \ Draw a horizontal line from (X1, Y1) to (X2, Y1),
                        \ which will draw from the left edge of the crosshairs
                        \ to the right edge, through the centre of the
                        \ crosshairs

 LDA QQ19+1             \ Set A = crosshairs y-coordinate - crosshairs size
 SEC                    \ to get the y-coordinate of the top edge of the
 SBC QQ19+2             \ crosshairs

 BCS TT86               \ If the above subtraction didn't underflow, then A is
                        \ correct, so skip the next instruction

 LDA #0                 \ The subtraction underflowed, so set A to 0 so the
                        \ crosshairs don't spill out of the top of the screen

.TT86

 CLC                    \ Set XX15+1 (Y1) = A + indent to get the y-coordinate
 ADC QQ19+5             \ of the top edge of the indented crosshairs
 STA XX15+1

 LDA QQ19+1             \ Set A = crosshairs y-coordinate + crosshairs size
 CLC                    \ + indent to get the y-coordinate of the bottom edge
 ADC QQ19+2             \ of the indented crosshairs
 ADC QQ19+5

 CMP #152               \ If A < 152 then skip the following, as the crosshairs
 BCC TT87               \ won't spill out of the bottom of the screen

 LDX QQ11               \ A >= 152, so we need to check whether this will fit in
                        \ this view, so fetch the view number

 BMI TT87               \ If this is the Short-range Chart then the y-coordinate
                        \ is fine, so skip to TT87

 LDA #151               \ Otherwise this is the Long-range Chart, so we need to
                        \ clip the crosshairs at a maximum y-coordinate of 151

.TT87

 STA XX15+3             \ Set XX15+3 (Y2) = A (the y-coordinate of the bottom
                        \ edge of the crosshairs)

 LDA QQ19               \ Set XX15 (X1) = the x-coordinate of the centre of the
 STA XX15               \ crosshairs

 STA XX15+2             \ Set XX15+2 (X2) = the x-coordinate of the centre of
                        \ the crosshairs

 JMP LL30               \ Draw a vertical line (X1, Y1) to (X2, Y2), which will
                        \ draw from the top edge of the crosshairs to the bottom
                        \ edge, through the centre of the crosshairs, returning
                        \ from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT14
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Draw a circle with crosshairs on a chart
\
\ ------------------------------------------------------------------------------
\
\ Draw a circle with crosshairs at the current system's galactic coordinates.
\
\ ******************************************************************************

.TT126

 LDA #104               \ Set QQ19 = 104, for the x-coordinate of the centre of
 STA QQ19               \ the fixed circle on the Short-range Chart

 LDA #90                \ Set QQ19+1 = 90, for the y-coordinate of the centre of
 STA QQ19+1             \ the fixed circle on the Short-range Chart

 LDA #16                \ Set QQ19+2 = 16, the size of the crosshairs on the
 STA QQ19+2             \ Short-range Chart

 JSR TT15               \ Draw the set of crosshairs defined in QQ19, at the
                        \ exact coordinates as this is the Short-range Chart

 LDA QQ14               \ Set K to the fuel level from QQ14, so this can act as
 STA K                  \ the circle's radius (70 being a full tank)

 JMP TT128              \ Jump to TT128 to draw a circle with the centre at the
                        \ same coordinates as the crosshairs, (QQ19, QQ19+1),
                        \ and radius K that reflects the current fuel levels,
                        \ returning from the subroutine using a tail call

.TT14

 LDA QQ11               \ If the current view is the Short-range Chart, which
 BMI TT126              \ is the only view with bit 7 set, then jump up to TT126
                        \ to draw the crosshairs and circle for that view

                        \ Otherwise this is the Long-range Chart, so we draw the
                        \ crosshairs and circle for that view instead

 LDA QQ14               \ Set K to the fuel level from QQ14 divided by 4, so
 LSR A                  \ this can act as the circle's radius (70 being a full
 LSR A                  \ tank, which divides down to a radius of 17)
 STA K

 LDA QQ0                \ Set QQ19 to the x-coordinate of the current system,
 STA QQ19               \ which will be the centre of the circle and crosshairs
                        \ we draw

 LDA QQ1                \ Set QQ19+1 to the y-coordinate of the current system,
 LSR A                  \ halved because the galactic chart is half as high as
 STA QQ19+1             \ it is wide, which will again be the centre of the
                        \ circle and crosshairs we draw

 LDA #7                 \ Set QQ19+2 = 7, the size of the crosshairs on the
 STA QQ19+2             \ Long-range Chart

 JSR TT15               \ Draw the set of crosshairs defined in QQ19, which will
                        \ be drawn 24 pixels to the right of QQ19+1

 LDA QQ19+1             \ Add 24 to the y-coordinate of the crosshairs in QQ19+1
 CLC                    \ so that the centre of the circle matches the centre
 ADC #24                \ of the crosshairs
 STA QQ19+1

                        \ Fall through into TT128 to draw a circle with the
                        \ centre at the same coordinates as the crosshairs,
                        \ (QQ19, QQ19+1), and radius K that reflects the
                        \ current fuel levels

\ ******************************************************************************
\
\       Name: TT128
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Draw a circle on a chart
\  Deep dive: Drawing circles
\
\ ------------------------------------------------------------------------------
\
\ Draw a circle with the centre at (QQ19, QQ19+1) and radius K.
\
\ Arguments:
\
\   QQ19                The x-coordinate of the centre of the circle
\
\   QQ19+1              The y-coordinate of the centre of the circle
\
\   K                   The radius of the circle
\
\ ******************************************************************************

.TT128

 LDA QQ19               \ Set K3 = the x-coordinate of the centre
 STA K3

 LDA QQ19+1             \ Set K4 = the y-coordinate of the centre
 STA K4

 LDX #0                 \ Set the high bytes of K3(1 0) and K4(1 0) to 0
 STX K4+1
 STX K3+1

 INX                    \ Set LSP = 1 to reset the ball line heap
 STX LSP

 LDX #2                 \ Set STP = 2, the step size for the circle
 STX STP

 JMP CIRCLE2            \ Jump to CIRCLE2 to draw a circle with the centre at
                        \ (K3(1 0), K4(1 0)) and radius K, returning from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT16
\       Type: Subroutine
\   Category: Charts
\    Summary: Move the crosshairs on a chart
\
\ ------------------------------------------------------------------------------
\
\ Move the chart crosshairs by the amount in X and Y.
\
\ Arguments:
\
\   X                   The amount to move the crosshairs in the x-axis
\
\   Y                   The amount to move the crosshairs in the y-axis
\
\ ******************************************************************************

.TT16

 TXA                    \ Push the change in X onto the stack (let's call this
 PHA                    \ the x-delta)

 DEY                    \ Negate the change in Y and push it onto the stack
 TYA                    \ (let's call this the y-delta)
 EOR #&FF
 PHA

 JSR WSCAN              \ Call WSCAN to wait for the vertical sync, so the whole
                        \ screen gets drawn and we can move the crosshairs with
                        \ no screen flicker

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10),
                        \ which will erase the crosshairs currently there

 PLA                    \ Store the y-delta in QQ19+3 and fetch the current
 STA QQ19+3             \ y-coordinate of the crosshairs from QQ10 into A, ready
 LDA QQ10               \ for the call to TT123

 JSR TT123              \ Call TT123 to move the selected system's galactic
                        \ y-coordinate by the y-delta, putting the new value in
                        \ QQ19+4

 LDA QQ19+4             \ Store the updated y-coordinate in QQ10 (the current
 STA QQ10               \ y-coordinate of the crosshairs)

 STA QQ19+1             \ This instruction has no effect, as QQ19+1 is
                        \ overwritten below, both in TT103 and TT105

 PLA                    \ Store the x-delta in QQ19+3 and fetch the current
 STA QQ19+3             \ x-coordinate of the crosshairs from QQ10 into A, ready
 LDA QQ9                \ for the call to TT123

 JSR TT123              \ Call TT123 to move the selected system's galactic
                        \ x-coordinate by the x-delta, putting the new value in
                        \ QQ19+4

 LDA QQ19+4             \ Store the updated x-coordinate in QQ9 (the current
 STA QQ9                \ x-coordinate of the crosshairs)

 STA QQ19               \ This instruction has no effect, as QQ19 is overwritten
                        \ below, both in TT103 and TT105

                        \ Now we've updated the coordinates of the crosshairs,
                        \ fall through into TT103 to redraw them at their new
                        \ location

\ ******************************************************************************
\
\       Name: TT103
\       Type: Subroutine
\   Category: Charts
\    Summary: Draw a small set of crosshairs on a chart
\
\ ------------------------------------------------------------------------------
\
\ Draw a small set of crosshairs on a galactic chart at the coordinates in
\ (QQ9, QQ10).
\
\ ******************************************************************************

.TT103

 LDA QQ11               \ Fetch the current view type into A

 BMI TT105              \ If this is the Short-range Chart screen, jump to TT105

 LDA QQ9                \ Store the crosshairs x-coordinate in QQ19
 STA QQ19

 LDA QQ10               \ Halve the crosshairs y-coordinate and store it in QQ19
 LSR A                  \ (we halve it because the Long-range Chart is half as
 STA QQ19+1             \ high as it is wide)

 LDA #4                 \ Set QQ19+2 to 4 denote crosshairs of size 4
 STA QQ19+2

 JMP TT15               \ Jump to TT15 to draw crosshairs of size 4 at the
                        \ crosshairs coordinates, returning from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: TT123
\       Type: Subroutine
\   Category: Charts
\    Summary: Move galactic coordinates by a signed delta
\
\ ------------------------------------------------------------------------------
\
\ Move an 8-bit galactic coordinate by a certain distance in either direction
\ (i.e. a signed 8-bit delta), but only if it doesn't cause the coordinate to
\ overflow. The coordinate is in a single axis, so it's either an x-coordinate
\ or a y-coordinate.
\
\ Arguments:
\
\   A                   The galactic coordinate to update
\
\   QQ19+3              The delta (can be positive or negative)
\
\ Returns:
\
\   QQ19+4              The updated coordinate after moving by the delta (this
\                       will be the same as A if moving by the delta overflows)
\
\ Other entry points:
\
\   TT180               Contains an RTS
\
\ ******************************************************************************

.TT123

 STA QQ19+4             \ Store the original coordinate in temporary storage at
                        \ QQ19+4

 CLC                    \ Set A = A + QQ19+3, so A now contains the original
 ADC QQ19+3             \ coordinate, moved by the delta

 LDX QQ19+3             \ If the delta is negative, jump to TT124
 BMI TT124

 BCC TT125              \ If the C flag is clear, then the above addition didn't
                        \ overflow, so jump to TT125 to return the updated value

 RTS                    \ Otherwise the C flag is set and the above addition
                        \ overflowed, so do not update the return value

.TT124

 BCC TT180              \ If the C flag is clear, then because the delta is
                        \ negative, this indicates the addition (which is
                        \ effectively a subtraction) underflowed, so jump to
                        \ TT180 to return from the subroutine without updating
                        \ the return value

.TT125

 STA QQ19+4             \ Store the updated coordinate in QQ19+4

.TT180

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT105
\       Type: Subroutine
\   Category: Charts
\    Summary: Draw crosshairs on the Short-range Chart, with clipping
\
\ ------------------------------------------------------------------------------
\
\ Check whether the crosshairs are close enough to the current system to appear
\ on the Short-range Chart, and if so, draw them.
\
\ ******************************************************************************

.TT105

 LDA QQ9                \ Set A = QQ9 - QQ0, the horizontal distance between the
 SEC                    \ crosshairs (QQ9) and the current system (QQ0)
 SBC QQ0

 CMP #38                \ If the horizontal distance in A < 38, then the
 BCC TT179              \ crosshairs are close enough to the current system to
                        \ appear in the Short-range Chart, so jump to TT179 to
                        \ check the vertical distance

 CMP #230               \ If the horizontal distance in A < -26, then the
 BCC TT180              \ crosshairs are too far from the current system to
                        \ appear in the Short-range Chart, so jump to TT180 to
                        \ return from the subroutine (as TT180 contains an RTS)

.TT179

 ASL A                  \ Set QQ19 = 104 + A * 4
 ASL A                  \
 CLC                    \ 104 is the x-coordinate of the centre of the chart,
 ADC #104               \ so this sets QQ19 to the screen pixel x-coordinate
 STA QQ19               \ of the crosshairs

 LDA QQ10               \ Set A = QQ10 - QQ1, the vertical distance between the
 SEC                    \ crosshairs (QQ10) and the current system (QQ1)
 SBC QQ1

 CMP #38                \ If the vertical distance in A is < 38, then the
 BCC P%+6               \ crosshairs are close enough to the current system to
                        \ appear in the Short-range Chart, so skip the next two
                        \ instructions

 CMP #220               \ If the horizontal distance in A is < -36, then the
 BCC TT180              \ crosshairs are too far from the current system to
                        \ appear in the Short-range Chart, so jump to TT180 to
                        \ return from the subroutine (as TT180 contains an RTS)

 ASL A                  \ Set QQ19+1 = 90 + A * 2
 CLC                    \
 ADC #90                \ 90 is the y-coordinate of the centre of the chart,
 STA QQ19+1             \ so this sets QQ19+1 to the screen pixel x-coordinate
                        \ of the crosshairs

 LDA #8                 \ Set QQ19+2 to 8 denote crosshairs of size 8
 STA QQ19+2

 JMP TT15               \ Jump to TT15 to draw crosshairs of size 8 at the
                        \ crosshairs coordinates, returning from the subroutine
                        \ using a tail call

\ ******************************************************************************
\
\       Name: TT23
\       Type: Subroutine
\   Category: Charts
\    Summary: Show the Short-range Chart (red key f5)
\
\ ******************************************************************************

.TT23

 LDA #128               \ Clear the top part of the screen, draw a white border,
 JSR TT66               \ and set the current view type in QQ11 to 128 (Short-
                        \ range Chart)

 LDA #7                 \ Move the text cursor to column 7
 STA XC

 LDA #190               \ Print recursive token 30 ("SHORT RANGE CHART") and
 JSR NLIN3              \ draw a horizontal line at pixel row 19 to box in the
                        \ title

 JSR TT14               \ Call TT14 to draw a circle with crosshairs at the
                        \ current system's galactic coordinates

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10),
                        \ i.e. at the selected system

 JSR TT81               \ Set the seeds in QQ15 to those of system 0 in the
                        \ current galaxy (i.e. copy the seeds from QQ21 to QQ15)

 LDA #0                 \ Set A = 0, which we'll use below to zero out the INWK
                        \ workspace

 STA XX20               \ We're about to start working our way through each of
                        \ the galaxy's systems, so set up a counter in XX20 for
                        \ each system, starting at 0 and looping through to 255

 LDX #24                \ First, though, we need to zero out the 25 bytes at
                        \ INWK so we can use them to work out which systems have
                        \ room for a label, so set a counter in X for 25 bytes

.EE3

 STA INWK,X             \ Set the X-th byte of INWK to zero

 DEX                    \ Decrement the counter

 BPL EE3                \ Loop back to EE3 for the next byte until we've zeroed
                        \ all 25 bytes

                        \ We now loop through every single system in the galaxy
                        \ and check the distance from the current system whose
                        \ coordinates are in (QQ0, QQ1). We get the galactic
                        \ coordinates of each system from the system's seeds,
                        \ like this:
                        \
                        \   x = s1_hi (which is stored in QQ15+3)
                        \   y = s0_hi (which is stored in QQ15+1)
                        \
                        \ so the following loops through each system in the
                        \ galaxy in turn and calculates the distance between
                        \ (QQ0, QQ1) and (s1_hi, s0_hi) to find the closest one

.TT182

 LDA QQ15+3             \ Set A = s1_hi - QQ0, the horizontal distance between
 SEC                    \ (s1_hi, s0_hi) and (QQ0, QQ1)
 SBC QQ0

 BCS TT184              \ If a borrow didn't occur, i.e. s1_hi >= QQ0, then the
                        \ result is positive, so jump to TT184 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |s1_hi - QQ0|)

.TT184

 CMP #20                \ If the horizontal distance in A is >= 20, then this
 BCS TT187              \ system is too far away from the current system to
                        \ appear in the Short-range Chart, so jump to TT187 to
                        \ move on to the next system

 LDA QQ15+1             \ Set A = s0_hi - QQ1, the vertical distance between
 SEC                    \ (s1_hi, s0_hi) and (QQ0, QQ1)
 SBC QQ1

 BCS TT186              \ If a borrow didn't occur, i.e. s0_hi >= QQ1, then the
                        \ result is positive, so jump to TT186 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |s0_hi - QQ1|)

.TT186

 CMP #38                \ If the vertical distance in A is >= 38, then this
 BCS TT187              \ system is too far away from the current system to
                        \ appear in the Short-range Chart, so jump to TT187 to
                        \ move on to the next system

                        \ This system should be shown on the Short-range Chart,
                        \ so now we need to work out where the label should go,
                        \ and set up the various variables we need to draw the
                        \ system's filled circle on the chart

 LDA QQ15+3             \ Set A = s1_hi - QQ0, the horizontal distance between
 SEC                    \ this system and the current system, where |A| < 20.
 SBC QQ0                \ Let's call this the x-delta, as it's the horizontal
                        \ difference between the current system at the centre of
                        \ the chart, and this system (and this time we keep the
                        \ sign of A, so it can be negative if it's to the left
                        \ of the chart's centre, or positive if it's to the
                        \ right)

 ASL A                  \ Set XX12 = 104 + x-delta * 4
 ASL A                  \
 ADC #104               \ 104 is the x-coordinate of the centre of the chart,
 STA XX12               \ so this sets XX12 to the centre 104 +/- 76, the pixel
                        \ x-coordinate of this system

 LSR A                  \ Move the text cursor to column x-delta / 2 + 1
 LSR A                  \ which will be in the range 1-10
 LSR A
 STA XC
 INC XC

 LDA QQ15+1             \ Set A = s0_hi - QQ1, the vertical distance between
 SEC                    \ this system and the current system, where |A| < 38.
 SBC QQ1                \ Let's call this the y-delta, as it's the vertical
                        \ difference between the current system at the centre of
                        \ the chart, and this system (and this time we keep the
                        \ sign of A, so it can be negative if it's above the
                        \ chart's centre, or positive if it's below)

 ASL A                  \ Set K4 = 90 + y-delta * 2
 ADC #90                \
 STA K4                 \ 90 is the y-coordinate of the centre of the chart,
                        \ so this sets K4 to the centre 90 +/- 74, the pixel
                        \ y-coordinate of this system

 LSR A                  \ Set Y = K4 / 8, so Y contains the number of the text
 LSR A                  \ row that contains this system
 LSR A
 TAY

                        \ Now to see if there is room for this system's label.
                        \ Ideally we would print the system name on the same
                        \ text row as the system, but we only want to print one
                        \ label per row, to prevent overlap, so now we check
                        \ this system's row, and if that's already occupied,
                        \ the row above, and if that's already occupied, the
                        \ row below... and if that's already occupied, we give
                        \ up and don't print a label for this system

 LDX INWK,Y             \ If the value in INWK+Y is 0 (i.e. the text row
 BEQ EE4                \ containing this system does not already have another
                        \ system's label on it), jump to EE4 to store this
                        \ system's label on this row

 INY                    \ If the value in INWK+Y+1 is 0 (i.e. the text row below
 LDX INWK,Y             \ the one containing this system does not already have
 BEQ EE4                \ another system's label on it), jump to EE4 to store
                        \ this system's label on this row

 DEY                    \ If the value in INWK+Y-1 is 0 (i.e. the text row above
 DEY                    \ the one containing this system does not already have
 LDX INWK,Y             \ another system's label on it), fall through into to
 BNE ee1                \ EE4 to store this system's label on this row,
                        \ otherwise jump to ee1 to skip printing a label for
                        \ this system (as there simply isn't room)

.EE4

 STY YC                 \ Now to print the label, so move the text cursor to row
                        \ Y (which contains the row where we can print this
                        \ system's label)

 CPY #3                 \ If Y < 3, then the system would clash with the chart
 BCC TT187              \ title, so jump to TT187 to skip showing the system

 LDA #&FF               \ Store &FF in INWK+Y, to denote that this row is now
 STA INWK,Y             \ occupied so we don't try to print another system's
                        \ label on this row

 LDA #%10000000         \ Set bit 7 of QQ17 to switch to Sentence Case
 STA QQ17

 JSR cpl                \ Call cpl to print out the system name for the seeds
                        \ in QQ15 (which now contains the seeds for the current
                        \ system)

.ee1

 LDA #0                 \ Now to plot the star, so set the high bytes of K, K3
 STA K3+1               \ and K4 to 0
 STA K4+1
 STA K+1

 LDA XX12               \ Set the low byte of K3 to XX12, the pixel x-coordinate
 STA K3                 \ of this system

 LDA QQ15+5             \ Fetch s2_hi for this system from QQ15+5, extract bit 0
 AND #1                 \ and add 2 to get the size of the star, which we store
 ADC #2                 \ in K. This will be either 2, 3 or 4, depending on the
 STA K                  \ value of bit 0, and whether the C flag is set (which
                        \ will vary depending on what happens in the above call
                        \ to cpl). Incidentally, the planet's average radius
                        \ also uses s2_hi, bits 0-3 to be precise, but that
                        \ doesn't mean the two sizes affect each other

                        \ We now have the following:
                        \
                        \   K(1 0)  = radius of star (2, 3 or 4)
                        \
                        \   K3(1 0) = pixel x-coordinate of system
                        \
                        \   K4(1 0) = pixel y-coordinate of system
                        \
                        \ which we can now pass to the SUN routine to draw a
                        \ small "sun" on the Short-range Chart for this system

 JSR FLFLLS             \ Call FLFLLS to reset the LSO block

 JSR SUN                \ Call SUN to plot a sun with radius K at pixel
                        \ coordinate (K3, K4)

 JSR FLFLLS             \ Call FLFLLS to reset the LSO block

.TT187

 JSR TT20               \ We want to move on to the next system, so call TT20
                        \ to twist the three 16-bit seeds in QQ15

 INC XX20               \ Increment the counter

 BEQ TT111-1            \ If X = 0 then we have done all 256 systems, so return
                        \ from the subroutine (as TT111-1 contains an RTS)

 JMP TT182              \ Otherwise jump back up to TT182 to process the next
                        \ system

\ ******************************************************************************
\
\       Name: TT81
\       Type: Subroutine
\   Category: Universe
\    Summary: Set the selected system's seeds to those of system 0
\
\ ------------------------------------------------------------------------------
\
\ Copy the three 16-bit seeds for the current galaxy's system 0 (QQ21) into the
\ seeds for the selected system (QQ15) - in other words, set the selected
\ system's seeds to those of system 0.
\
\ ******************************************************************************

.TT81

 LDX #5                 \ Set up a counter in X to copy six bytes (for three
                        \ 16-bit numbers)

 LDA QQ21,X             \ Copy the X-th byte in QQ21 to the X-th byte in QQ15
 STA QQ15,X

 DEX                    \ Decrement the counter

 BPL TT81+2             \ Loop back up to the LDA instruction if we still have
                        \ more bytes to copy

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT111
\       Type: Subroutine
\   Category: Universe
\    Summary: Set the current system to the nearest system to a point
\
\ ------------------------------------------------------------------------------
\
\ Given a set of galactic coordinates in (QQ9, QQ10), find the nearest system
\ to this point in the galaxy, and set this as the currently selected system.
\
\ Arguments:
\
\   QQ9                 The x-coordinate near which we want to find a system
\
\   QQ10                The y-coordinate near which we want to find a system
\
\ Returns:
\
\   QQ8(1 0)            The distance from the current system to the nearest
\                       system to the original coordinates
\
\   QQ9                 The x-coordinate of the nearest system to the original
\                       coordinates
\
\   QQ10                The y-coordinate of the nearest system to the original
\                       coordinates
\
\   QQ15 to QQ15+5      The three 16-bit seeds of the nearest system to the
\                       original coordinates
\
\   ZZ                  The system number of the nearest system
\
\ Other entry points:
\
\   TT111-1             Contains an RTS
\
\ ******************************************************************************

.TT111

 JSR TT81               \ Set the seeds in QQ15 to those of system 0 in the
                        \ current galaxy (i.e. copy the seeds from QQ21 to QQ15)

                        \ We now loop through every single system in the galaxy
                        \ and check the distance from (QQ9, QQ10). We get the
                        \ galactic coordinates of each system from the system's
                        \ seeds, like this:
                        \
                        \   x = s1_hi (which is stored in QQ15+3)
                        \   y = s0_hi (which is stored in QQ15+1)
                        \
                        \ so the following loops through each system in the
                        \ galaxy in turn and calculates the distance between
                        \ (QQ9, QQ10) and (s1_hi, s0_hi) to find the closest one

 LDY #127               \ Set Y = T = 127 to hold the shortest distance we've
 STY T                  \ found so far, which we initially set to half the
                        \ distance across the galaxy, or 127, as our coordinate
                        \ system ranges from (0,0) to (255, 255)

 LDA #0                 \ Set A = U = 0 to act as a counter for each system in
 STA U                  \ the current galaxy, which we start at system 0 and
                        \ loop through to 255, the last system

.TT130

 LDA QQ15+3             \ Set A = s1_hi - QQ9, the horizontal distance between
 SEC                    \ (s1_hi, s0_hi) and (QQ9, QQ10)
 SBC QQ9

 BCS TT132              \ If a borrow didn't occur, i.e. s1_hi >= QQ9, then the
                        \ result is positive, so jump to TT132 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |s1_hi - QQ9|)

.TT132

 LSR A                  \ Set S = A / 2
 STA S                  \       = |s1_hi - QQ9| / 2

 LDA QQ15+1             \ Set A = s0_hi - QQ10, the vertical distance between
 SEC                    \ (s1_hi, s0_hi) and (QQ9, QQ10)
 SBC QQ10

 BCS TT134              \ If a borrow didn't occur, i.e. s0_hi >= QQ10, then the
                        \ result is positive, so jump to TT134 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |s0_hi - QQ10|)

.TT134

 LSR A                  \ Set A = S + A / 2
 CLC                    \       = |s1_hi - QQ9| / 2 + |s0_hi - QQ10| / 2
 ADC S                  \
                        \ So A now contains the sum of the horizontal and
                        \ vertical distances, both divided by 2 so the result
                        \ fits into one byte, and although this doesn't contain
                        \ the actual distance between the systems, it's a good
                        \ enough approximation to use for comparing distances

 CMP T                  \ If A >= T, then this system's distance is bigger than
 BCS TT135              \ our "minimum distance so far" stored in T, so it's no
                        \ closer than the systems we have already found, so
                        \ skip to TT135 to move on to the next system

 STA T                  \ This system is the closest to (QQ9, QQ10) so far, so
                        \ update T with the new "distance" approximation

 LDX #5                 \ As this system is the closest we have found yet, we
                        \ want to store the system's seeds in case it ends up
                        \ being the closest of all, so we set up a counter in X
                        \ to copy six bytes (for three 16-bit numbers)

.TT136

 LDA QQ15,X             \ Copy the X-th byte in QQ15 to the X-th byte in QQ19,
 STA QQ19,X             \ where QQ15 contains the seeds for the system we just
                        \ found to be the closest so far, and QQ19 is temporary
                        \ storage

 DEX                    \ Decrement the counter

 BPL TT136              \ Loop back to TT136 if we still have more bytes to
                        \ copy

 LDA U                  \ Store the system number U in ZZ, so when we are done
 STA ZZ                 \ looping through all the candidates, the winner's
                        \ number will be in ZZ

.TT135

 JSR TT20               \ We want to move on to the next system, so call TT20
                        \ to twist the three 16-bit seeds in QQ15

 INC U                  \ Increment the system counter in U

 BNE TT130              \ If U > 0 then we haven't done all 256 systems yet, so
                        \ loop back up to TT130

                        \ We have now finished checking all the systems in the
                        \ galaxy, and the seeds for the closest system are in
                        \ QQ19, so now we want to copy these seeds to QQ15,
                        \ to set the selected system to this closest system

 LDX #5                 \ So we set up a counter in X to copy six bytes (for
                        \ three 16-bit numbers)

.TT137

 LDA QQ19,X             \ Copy the X-th byte in QQ19 to the X-th byte in QQ15,
 STA QQ15,X

 DEX                    \ Decrement the counter

 BPL TT137              \ Loop back to TT137 if we still have more bytes to
                        \ copy

 LDA QQ15+1             \ The y-coordinate of the system described by the seeds
 STA QQ10               \ in QQ15 is in QQ15+1 (s0_hi), so we copy this to QQ10
                        \ as this is where we store the selected system's
                        \ y-coordinate

 LDA QQ15+3             \ The x-coordinate of the system described by the seeds
 STA QQ9                \ in QQ15 is in QQ15+3 (s1_hi), so we copy this to QQ9
                        \ as this is where we store the selected system's
                        \ x-coordinate

                        \ We have now found the closest system to (QQ9, QQ10)
                        \ and have set it as the selected system, so now we
                        \ need to work out the distance between the selected
                        \ system and the current system

 SEC                    \ Set A = QQ9 - QQ0, the horizontal distance between
 SBC QQ0                \ the selected system's x-coordinate (QQ9) and the
                        \ current system's x-coordinate (QQ0)

 BCS TT139              \ If a borrow didn't occur, i.e. QQ9 >= QQ0, then the
                        \ result is positive, so jump to TT139 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |QQ9 - QQ0|)

                        \ A now contains the difference between the two
                        \ systems' x-coordinates, with the sign removed. We
                        \ will refer to this as the x-delta ("delta" means
                        \ change or difference in maths)

.TT139

 JSR SQUA2              \ Set (A P) = A * A
                        \           = |QQ9 - QQ0| ^ 2
                        \           = x_delta ^ 2

 STA K+1                \ Store (A P) in K(1 0)
 LDA P
 STA K

 LDA QQ10               \ Set A = QQ10 - QQ1, the vertical distance between the
 SEC                    \ selected system's y-coordinate (QQ10) and the current
 SBC QQ1                \ system's y-coordinate (QQ1)

 BCS TT141              \ If a borrow didn't occur, i.e. QQ10 >= QQ1, then the
                        \ result is positive, so jump to TT141 and skip the
                        \ following two instructions

 EOR #&FF               \ Otherwise negate the result in A, so A is always
 ADC #1                 \ positive (i.e. A = |QQ10 - QQ1|)

.TT141

 LSR A                  \ Set A = A / 2

                        \ A now contains the difference between the two
                        \ systems' y-coordinates, with the sign removed, and
                        \ halved. We halve the value because the galaxy in
                        \ in Elite is rectangular rather than square, and is
                        \ twice as wide (x-axis) as it is high (y-axis), so to
                        \ get a distance that matches the shape of the
                        \ long-range galaxy chart, we need to halve the
                        \ distance between the vertical y-coordinates. We will
                        \ refer to this as the y-delta

 JSR SQUA2              \ Set (A P) = A * A
                        \           = (|QQ10 - QQ1| / 2) ^ 2
                        \           = y_delta ^ 2

                        \ By this point we have the following results:
                        \
                        \   K(1 0) = x_delta ^ 2
                        \    (A P) = y_delta ^ 2
                        \
                        \ so to find the distance between the two points, we
                        \ can use Pythagoras - so first we need to add the two
                        \ results together, and then take the square root

 PHA                    \ Store the high byte of the y-axis value on the stack,
                        \ so we can use A for another purpose

 LDA P                  \ Set Q = P + K, which adds the low bytes of the two
 CLC                    \ calculated values
 ADC K
 STA Q

 PLA                    \ Restore the high byte of the y-axis value from the
                        \ stack into A again

 ADC K+1                \ Set R = A + K+1, which adds the high bytes of the two
 STA R                  \ calculated values, so we now have:
                        \
                        \   (R Q) = K(1 0) + (A P)
                        \         = (x_delta ^ 2) + (y_delta ^ 2)

 JSR LL5                \ Set Q = SQRT(R Q), so Q now contains the distance
                        \ between the two systems, in terms of coordinates

                        \ We now store the distance to the selected system * 4
                        \ in the two-byte location QQ8, by taking (0 Q) and
                        \ shifting it left twice, storing it in QQ8(1 0)

 LDA Q                  \ First we shift the low byte left by setting
 ASL A                  \ A = Q * 2, with bit 7 of A going into the C flag

 LDX #0                 \ Now we set the high byte in QQ8+1 to 0 and rotate
 STX QQ8+1              \ the C flag into bit 0 of QQ8+1
 ROL QQ8+1

 ASL A                  \ And then we repeat the shift left of (QQ8+1 A)
 ROL QQ8+1

 STA QQ8                \ And store A in the low byte, QQ8, so QQ8(1 0) now
                        \ contains Q * 4. Given that the width of the galaxy is
                        \ 256 in coordinate terms, the width of the galaxy
                        \ would be 1024 in the units we store in QQ8

 JMP TT24               \ Call TT24 to calculate system data from the seeds in
                        \ QQ15 and store them in the relevant locations, so our
                        \ new selected system is fully set up, and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: pr6
\       Type: Subroutine
\   Category: Text
\    Summary: Print 16-bit number, left-padded to 5 digits, no point
\
\ ------------------------------------------------------------------------------
\
\ Print the 16-bit number in (Y X) to 5 digits, left-padding with spaces for
\ numbers with fewer than 3 digits (so numbers < 10000 are right-aligned),
\ with no decimal point.
\
\ Arguments:
\
\   X                   The low byte of the number to print
\
\   Y                   The high byte of the number to print
\
\ ******************************************************************************

.pr6

 CLC                    \ Do not display a decimal point when printing

                        \ Fall through into pr5 to print X to 5 digits

\ ******************************************************************************
\
\       Name: pr5
\       Type: Subroutine
\   Category: Text
\    Summary: Print a 16-bit number, left-padded to 5 digits, and optional point
\
\ ------------------------------------------------------------------------------
\
\ Print the 16-bit number in (Y X) to 5 digits, left-padding with spaces for
\ numbers with fewer than 3 digits (so numbers < 10000 are right-aligned).
\ Optionally include a decimal point.
\
\ Arguments:
\
\   X                   The low byte of the number to print
\
\   Y                   The high byte of the number to print
\
\   C flag              If set, include a decimal point
\
\ ******************************************************************************

.pr5

 LDA #5                 \ Set the number of digits to print to 5

 JMP TT11               \ Call TT11 to print (Y X) to 5 digits and return from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT162
\       Type: Subroutine
\   Category: Text
\    Summary: Print a space
\
\ Other entry points:
\
\   TT162+2             Jump to TT27 to print the text token in A
\
\ ******************************************************************************

.TT162

 LDA #' '               \ Load a space character into A

 JMP TT27               \ Print the text token in A and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: func_tab
\       Type: Variable
\   Category: Keyboard
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.func_tab

 EQUB f0, f1, f2, f3, f4, f5, f6, f7, f8, f9

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: buy_invnt
\       Type: Subroutine
\   Category: Buying ships
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.buy_invnt

 SBC #&50
 BCC buy_top
 CMP #&0A
 BCC buy_func

.buy_top

 LDA #&01

.buy_func

 TAX
 LDA func_tab,X
 JMP FRCE

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: gnum
\       Type: Subroutine
\   Category: Market
\    Summary: Get a number from the keyboard
\
\ ------------------------------------------------------------------------------
\
\ Get a number from the keyboard, up to the maximum number in QQ25, for the
\ buying and selling of cargo and equipment.
\
\ Pressing "Y" will return the maximum number (i.e. buy/sell all items), while
\ pressing "N" will abort the sale and return a 0.
\
\ Pressing a key with an ASCII code less than ASCII "0" will return a 0 in A (so
\ that includes pressing Space or Return), while pressing a key with an ASCII
\ code greater than ASCII "9" will jump to the Inventory screen (so that
\ includes all letters and most punctuation).
\
\ Arguments:
\
\   QQ25                The maximum number allowed
\
\ Returns:
\
\   A                   The number entered
\
\   R                   Also contains the number entered
\
\   C flag              Set if the number is too large (> QQ25), clear otherwise
\
\ ******************************************************************************

.gnum

 LDX #0                 \ We will build the number entered in R, so initialise
 STX R                  \ it with 0

 LDX #12                \ We will check for up to 12 key presses, so set a
 STX T1                 \ counter in T1

.TT223

 JSR TT217              \ Scan the keyboard until a key is pressed, and return
                        \ the key's ASCII code in A (and X)

 LDX R                  \ If R is non-zero then skip to NWDAV2, as we are
 BNE NWDAV2             \ already building a number

                        \ --- Original Acornsoft code removed: ---------------->

\ CMP #'y'              \ If "Y" was pressed, jump to NWDAV1 to return the
\ BEQ NWDAV1            \ maximum number allowed (i.e. buy/sell the whole stock)
\
\ CMP #'n'              \ If "N" was pressed, jump to NWDAV3 to return from the
\ BEQ NWDAV3            \ subroutine with a result of 0 (i.e. abort transaction)

                        \ --- End of removed code ----------------------------->

.NWDAV2

 STA Q                  \ Store the key pressed in Q

 SEC                    \ Subtract ASCII '0' from the key pressed, to leave the
 SBC #'0'               \ numeric value of the key in A (if it was a number key)

 BCC OUT                \ If A < 0, jump to OUT to return from the subroutine
                        \ with a result of 0, as the key pressed was not a
                        \ number or letter and is less than ASCII "0"

                        \ --- Original Acornsoft code removed: ---------------->

\ CMP #10               \ If A >= 10, jump to BAY2 to display the Inventory
\ BCS BAY2              \ screen, as the key pressed was a letter or other
\                       \ non-digit and is greater than ASCII "9"

                        \ --- And replaced by: -------------------------------->

 CMP #10                \ If A >= 10, jump to buy_invnt to AJD
 BCS buy_invnt

                        \ --- End of replacement ------------------------------>

 STA S                  \ Store the numeric value of the key pressed in S

 LDA R                  \ Fetch the result so far into A

 CMP #26                \ If A >= 26, where A is the number entered so far, then
 BCS OUT                \ adding a further digit will make it bigger than 256,
                        \ so jump to OUT to return from the subroutine with the
                        \ result in R (i.e. ignore the last key press)

 ASL A                  \ Set A = (A * 2) + (A * 8) = A * 10
 STA T
 ASL A
 ASL A
 ADC T

 ADC S                  \ Add the pressed digit to A and store in R, so R now
 STA R                  \ contains its previous value with the new key press
                        \ tacked onto the end

 CMP QQ25               \ If the result in R = the maximum allowed in QQ25, jump
 BEQ TT226              \ to TT226 to print the key press and keep looping (the
                        \ BEQ is needed because the BCS below would jump to OUT
                        \ if R >= QQ25, which we don't want)

 BCS OUT                \ If the result in R > QQ25, jump to OUT to return from
                        \ the subroutine with the result in R

.TT226

 LDA Q                  \ Print the character in Q (i.e. the key that was
 JSR TT26               \ pressed, as we stored the ASCII value in Q earlier)

 DEC T1                 \ Decrement the loop counter

 BNE TT223              \ Loop back to TT223 until we have checked for 12 digits

.OUT

 LDA R                  \ Set A to the result we have been building in R

 RTS                    \ Return from the subroutine

                        \ --- Original Acornsoft code removed: ---------------->

\.NWDAV1
\
\                       \ If we get here then "Y" was pressed, so we return the
\                       \ maximum number allowed, which is in QQ25
\
\ JSR TT26              \ Print the character for the key that was pressed
\
\ LDA QQ25              \ Set R = QQ25, so we return the maximum value allowed
\ STA R
\
\ RTS                   \ Return from the subroutine
\
\.NWDAV3
\
\                       \ If we get here then "N" was pressed, so we return 0
\
\ JSR TT26              \ Print the character for the key that was pressed
\
\ LDA #0                \ Set R = 0, so we return 0
\ STA R
\
\ RTS                   \ Return from the subroutine

                        \ --- End of removed code ----------------------------->

\ ******************************************************************************
\
\       Name: dn2
\       Type: Subroutine
\   Category: Text
\    Summary: Make a short, high beep and delay for 1 second
\
\ ******************************************************************************

.dn2

 JSR BEEP               \ Call the BEEP subroutine to make a short, high beep

 LDY #50                \ Delay for 50 vertical syncs (50/50 = 1 second) and
 JMP DELAY              \ return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: hm
\       Type: Subroutine
\   Category: Charts
\    Summary: Select the closest system and redraw the chart crosshairs
\
\ ------------------------------------------------------------------------------
\
\ Set the system closest to galactic coordinates (QQ9, QQ10) as the selected
\ system, redraw the crosshairs on the chart accordingly (if they are being
\ shown), and, if this is not a space view, clear the bottom three text rows of
\ the screen.
\
\ ******************************************************************************

.hm

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10),
                        \ which will erase the crosshairs currently there

 JSR TT111              \ Select the system closest to galactic coordinates
                        \ (QQ9, QQ10)

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10),
                        \ which will draw the crosshairs at our current home
                        \ system

 JMP CLYNS              \ Clear the bottom three text rows of the upper screen,
                        \ and move the text cursor to column 1 on row 21, i.e.
                        \ the start of the top row of the three bottom rows

                        \ Return from the subroutine using a tail call

\ ******************************************************************************
\
\ Save output/ELTD.bin
\
\ ******************************************************************************

PRINT "ELITE D"
PRINT "Assembled at ", ~CODE_D%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_D%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_D%

PRINT "S.F.ELTD ", ~CODE_D%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_D%
\SAVE "output/F.ELTD.bin", CODE_D%, P%, LOAD%

\ ******************************************************************************
\
\ ELITE E FILE
\
\ ******************************************************************************

CODE_E% = P%
LOAD_E% = LOAD% + P% - CODE%

\ ******************************************************************************
\
\       Name: cpl
\       Type: Subroutine
\   Category: Text
\    Summary: Print the selected system name
\  Deep dive: Generating system names
\             Galaxy and system seeds
\
\ ------------------------------------------------------------------------------
\
\ Print control code 3 (the selected system name, i.e. the one in the crosshairs
\ in the Short-range Chart).
\
\ Other entry points:
\
\   cmn-1               Contains an RTS
\
\ ******************************************************************************

.cpl

 LDX #5                 \ First we need to backup the seeds in QQ15, so set up
                        \ a counter in X to cover three 16-bit seeds (i.e.
                        \ 6 bytes)

.TT53

 LDA QQ15,X             \ Copy byte X from QQ15 to QQ19
 STA QQ19,X

 DEX                    \ Decrement the loop counter

 BPL TT53               \ Loop back for the next byte to backup

 LDY #3                 \ Step 1: Now that the seeds are backed up, we can
                        \ start the name-generation process. We will either
                        \ need to loop three or four times, so for now set
                        \ up a counter in Y to loop four times

 BIT QQ15               \ Check bit 6 of s0_lo, which is stored in QQ15

 BVS P%+3               \ If bit 6 is set then skip over the next instruction

 DEY                    \ Bit 6 is clear, so we only want to loop three times,
                        \ so decrement the loop counter in Y

 STY T                  \ Store the loop counter in T

.TT55

 LDA QQ15+5             \ Step 2: Load s2_hi, which is stored in QQ15+5, and
 AND #%00011111         \ extract bits 0-4 by AND'ing with %11111

 BEQ P%+7               \ If all those bits are zero, then skip the following
                        \ 2 instructions to go to step 3

 ORA #%10000000         \ We now have a number in the range 1-31, which we can
                        \ easily convert into a two-letter token, but first we
                        \ need to add 128 (or set bit 7) to get a range of
                        \ 129-159

 JSR TT27               \ Print the two-letter token in A

 JSR TT54               \ Step 3: twist the seeds in QQ15

 DEC T                  \ Decrement the loop counter

 BPL TT55               \ Loop back for the next two letters

 LDX #5                 \ We have printed the system name, so we can now
                        \ restore the seeds we backed up earlier. Set up a
                        \ counter in X to cover three 16-bit seeds (i.e. 6
                        \ bytes)

.TT56

 LDA QQ19,X             \ Copy byte X from QQ19 to QQ15
 STA QQ15,X

 DEX                    \ Decrement the loop counter

 BPL TT56               \ Loop back for the next byte to restore

 RTS                    \ Once all the seeds are restored, return from the
                        \ subroutine

\ ******************************************************************************
\
\       Name: cmn
\       Type: Subroutine
\   Category: Text
\    Summary: Print the commander's name
\
\ ------------------------------------------------------------------------------
\
\ Print control code 4 (the commander's name).
\
\ Other entry points:
\
\   ypl-1               Contains an RTS
\
\ ******************************************************************************

.cmn

 JSR MT19               \ Call MT19 to capitalise the next letter (i.e. set
                        \ Sentence Case for this word only)

 LDY #0                 \ Set up a counter in Y, starting from 0

.QUL4

 LDA NA%,Y              \ The commander's name is stored at NA%, so load the
                        \ Y-th character from NA%

 CMP #13                \ If we have reached the end of the name, return from
 BEQ ypl-1              \ the subroutine (ypl-1 points to the RTS below)

 JSR TT26               \ Print the character we just loaded

 INY                    \ Increment the loop counter

 BNE QUL4               \ Loop back for the next character

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ypl
\       Type: Subroutine
\   Category: Text
\    Summary: Print the current system name
\
\ ------------------------------------------------------------------------------
\
\ Print control code 2 (the current system name).
\
\ ******************************************************************************

.ypl

 JSR TT62               \ Call TT62 below to swap the three 16-bit seeds in
                        \ QQ2 and QQ15 (before the swap, QQ2 contains the seeds
                        \ for the current system, while QQ15 contains the seeds
                        \ for the selected system)

 JSR cpl                \ Call cpl to print out the system name for the seeds
                        \ in QQ15 (which now contains the seeds for the current
                        \ system)

                        \ Now we fall through into the TT62 subroutine, which
                        \ will swap QQ2 and QQ15 once again, so everything goes
                        \ back into the right place, and the RTS at the end of
                        \ TT62 will return from the subroutine

.TT62

 LDX #5                 \ Set up a counter in X for the three 16-bit seeds we
                        \ want to swap (i.e. 6 bytes)

.TT78

 LDA QQ15,X             \ Swap byte X between QQ2 and QQ15
 LDY QQ2,X
 STA QQ2,X
 STY QQ15,X

 DEX                    \ Decrement the loop counter

 BPL TT78               \ Loop back for the next byte to swap

 RTS                    \ Once all bytes are swapped, return from the
                        \ subroutine

\ ******************************************************************************
\
\       Name: tal
\       Type: Subroutine
\   Category: Text
\    Summary: Print the current galaxy numbe
\
\ ------------------------------------------------------------------------------
\
\ Print control code 1 (the current galaxy number, right-aligned to width 3).
\
\ ******************************************************************************

.tal

 CLC                    \ We don't want to print the galaxy number with a
                        \ decimal point, so clear the C flag for pr2 to take as
                        \ an argument

 LDX GCNT               \ Load the current galaxy number from GCNT into X

 INX                    \ Add 1 to the galaxy number, as the galaxy numbers
                        \ are 0-7 internally, but we want to display them as
                        \ galaxy 1 through 8

 JMP pr2                \ Jump to pr2, which prints the number in X to a width
                        \ of 3 figures, left-padding with spaces to a width of
                        \ 3, and once done, return from the subroutine (as pr2
                        \ ends with an RTS)

\ ******************************************************************************
\
\       Name: fwl
\       Type: Subroutine
\   Category: Text
\    Summary: Print fuel and cash levels
\
\ ------------------------------------------------------------------------------
\
\ Print control code 5 ("FUEL: ", fuel level, " LIGHT YEARS", newline, "CASH:",
\ control code 0).
\
\ ******************************************************************************

.fwl

 LDA #105               \ Print recursive token 105 ("FUEL") followed by a
 JSR TT68               \ colon

 LDX QQ14               \ Load the current fuel level from QQ14

 SEC                    \ We want to print the fuel level with a decimal point,
                        \ so set the C flag for pr2 to take as an argument

 JSR pr2                \ Call pr2, which prints the number in X to a width of
                        \ 3 figures (i.e. in the format x.x, which will always
                        \ be exactly 3 characters as the maximum fuel is 7.0)

 LDA #195               \ Print recursive token 35 ("LIGHT YEARS") followed by
 JSR plf                \ a newline

.PCASH                  \ This label is not used but is in the original source

 LDA #119               \ Print recursive token 119 ("CASH:" then control code
 BNE TT27               \ 0, which prints cash levels, then " CR" and newline)

\ ******************************************************************************
\
\       Name: csh
\       Type: Subroutine
\   Category: Text
\    Summary: Print the current amount of cash
\
\ ------------------------------------------------------------------------------
\
\ Print control code 0 (the current amount of cash, right-aligned to width 9,
\ followed by " CR" and a newline).
\
\ ******************************************************************************

.csh

 LDX #3                 \ We are going to use the BPRNT routine to print out
                        \ the current amount of cash, which is stored as a
                        \ 32-bit number at location CASH. BPRNT prints out
                        \ the 32-bit number stored in K, so before we call
                        \ BPRNT, we need to copy the four bytes from CASH into
                        \ K, so first we set up a counter in X for the 4 bytes

.pc1

 LDA CASH,X             \ Copy byte X from CASH to K
 STA K,X

 DEX                    \ Decrement the loop counter

 BPL pc1                \ Loop back for the next byte to copy

 LDA #9                 \ We want to print the cash using up to 9 digits
 STA U                  \ (including the decimal point), so store this in U
                        \ for BRPNT to take as an argument

 SEC                    \ We want to print the fuel level with a decimal point,
                        \ so set the C flag for BRPNT to take as an argument

 JSR BPRNT              \ Print the amount of cash to 9 digits with a decimal
                        \ point

 LDA #226               \ Print recursive token 66 (" CR") followed by a
                        \ newline by falling through into plf

\ ******************************************************************************
\
\       Name: plf
\       Type: Subroutine
\   Category: Text
\    Summary: Print a text token followed by a newline
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.plf

 JSR TT27               \ Print the text token in A

 JMP TT67               \ Jump to TT67 to print a newline and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: TT68
\       Type: Subroutine
\   Category: Text
\    Summary: Print a text token followed by a colon
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.TT68

 JSR TT27               \ Print the text token in A and fall through into TT73
                        \ to print a colon

\ ******************************************************************************
\
\       Name: TT73
\       Type: Subroutine
\   Category: Text
\    Summary: Print a colon
\
\ ******************************************************************************

.TT73

 LDA #':'               \ Set A to ASCII ":" and fall through into TT27 to
                        \ actually print the colon

\ ******************************************************************************
\
\       Name: TT27
\       Type: Subroutine
\   Category: Text
\    Summary: Print a text token
\  Deep dive: Printing text tokens
\
\ ------------------------------------------------------------------------------
\
\ Print a text token (i.e. a character, control code, two-letter token or
\ recursive token). See variable QQ18 for a discussion of the token system
\ used in Elite.
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.TT27

 TAX                    \ Copy the token number from A to X. We can then keep
                        \ decrementing X and testing it against zero, while
                        \ keeping the original token number intact in A; this
                        \ effectively implements a switch statement on the
                        \ value of the token

 BEQ csh                \ If token = 0, this is control code 0 (current amount
                        \ of cash and newline), so jump to csh

 BMI TT43               \ If token > 127, this is either a two-letter token
                        \ (128-159) or a recursive token (160-255), so jump
                        \ to TT43 to process tokens

 DEX                    \ If token = 1, this is control code 1 (current galaxy
 BEQ tal                \ number), so jump to tal

 DEX                    \ If token = 2, this is control code 2 (current system
 BEQ ypl                \ name), so jump to ypl

 DEX                    \ If token > 3, skip the following instruction
 BNE P%+5

 JMP cpl                \ This token is control code 3 (selected system name)
                        \ so jump to cpl

 DEX                    \ If token = 4, this is control code 4 (commander
 BEQ cmn                \ name), so jump to cmm

 DEX                    \ If token = 5, this is control code 5 (fuel, newline,
 BEQ fwl                \ cash, newline), so jump to fwl

 DEX                    \ If token > 6, skip the following 3 instructions
 BNE P%+7

 LDA #%10000000         \ This token is control code 6 (switch to Sentence
 STA QQ17               \ Case), so set bit 7 of QQ17 to switch to Sentence Case
 RTS                    \ and return from the subroutine as we are done

 DEX                    \ If token > 8, skip the following 2 instructions
 DEX
 BNE P%+5

 STX QQ17               \ This token is control code 8 (switch to ALL CAPS), so
 RTS                    \ set QQ17 to 0 to switch to ALL CAPS and return from
                        \ the subroutine as we are done

 DEX                    \ If token = 9, this is control code 9 (tab to column
 BEQ crlf               \ 21 and print a colon), so jump to crlf

 CMP #96                \ By this point, token is either 7, or in 10-127.
 BCS ex                 \ Check token number in A and if token >= 96, then the
                        \ token is in 96-127, which is a recursive token, so
                        \ jump to ex, which prints recursive tokens in this
                        \ range (i.e. where the recursive token number is
                        \ correct and doesn't need correcting)

 CMP #14                \ If token < 14, skip the following 2 instructions
 BCC P%+6

 CMP #32                \ If token < 32, then this means token is in 14-31, so
 BCC qw                 \ this is a recursive token that needs 114 adding to it
                        \ to get the recursive token number, so jump to qw
                        \ which will do this

                        \ By this point, token is either 7 (beep) or in 10-13
                        \ (line feeds and carriage returns), or in 32-95
                        \ (ASCII letters, numbers and punctuation)

 LDX QQ17               \ Fetch QQ17, which controls letter case, into X

 BEQ TT74               \ If QQ17 = 0, then ALL CAPS is set, so jump to TT27
                        \ to print this character as is (i.e. as a capital)

 BMI TT41               \ If QQ17 has bit 7 set, then we are using Sentence
                        \ Case, so jump to TT41, which will print the
                        \ character in upper or lower case, depending on
                        \ whether this is the first letter in a word

 BIT QQ17               \ If we get here, QQ17 is not 0 and bit 7 is clear, so
 BVS TT46               \ either it is bit 6 that is set, or some other flag in
                        \ QQ17 is set (bits 0-5). So check whether bit 6 is set.
                        \ If it is, then ALL CAPS has been set (as bit 7 is
                        \ clear) but bit 6 is still indicating that the next
                        \ character should be printed in lower case, so we need
                        \ to fix this. We do this with a jump to TT46, which
                        \ will print this character in upper case and clear bit
                        \ 6, so the flags are consistent with ALL CAPS going
                        \ forward

                        \ If we get here, some other flag is set in QQ17 (one
                        \ of bits 0-5 is set), which shouldn't happen in this
                        \ version of Elite. If this were the case, then we
                        \ would fall through into TT42 to print in lower case,
                        \ which is how printing all words in lower case could
                        \ be supported (by setting QQ17 to 1, say)

\ ******************************************************************************
\
\       Name: TT42
\       Type: Subroutine
\   Category: Text
\    Summary: Print a letter in lower case
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The character to be printed. Can be one of the
\                       following:
\
\                         * 7 (beep)
\
\                         * 10-13 (line feeds and carriage returns)
\
\                         * 32-95 (ASCII capital letters, numbers and
\                           punctuation)
\
\ Other entry points:
\
\   TT44                Jumps to TT26 to print the character in A (used to
\                       enable us to use a branch instruction to jump to TT26)
\
\ ******************************************************************************

.TT42

 CMP #'A'               \ If A < ASCII "A", then this is punctuation, so jump
 BCC TT44               \ to TT26 (via TT44) to print the character as is, as
                        \ we don't care about the character's case

 CMP #'Z'+1             \ If A >= (ASCII "Z" + 1), then this is also
 BCS TT44               \ punctuation, so jump to TT26 (via TT44) to print the
                        \ character as is, as we don't care about the
                        \ character's case

 ADC #32                \ Add 32 to the character, to convert it from upper to
                        \ to lower case

.TT44

 JMP TT26               \ Print the character in A

\ ******************************************************************************
\
\       Name: TT41
\       Type: Subroutine
\   Category: Text
\    Summary: Print a letter according to Sentence Case
\
\ ------------------------------------------------------------------------------
\
\ The rules for printing in Sentence Case are as follows:
\
\   * If QQ17 bit 6 is set, print lower case (via TT45)
\
\   * If QQ17 bit 6 clear, then:
\
\       * If character is punctuation, just print it
\
\       * If character is a letter, set QQ17 bit 6 and print letter as a capital
\
\ Arguments:
\
\   A                   The character to be printed. Can be one of the
\                       following:
\
\                         * 7 (beep)
\
\                         * 10-13 (line feeds and carriage returns)
\
\                         * 32-95 (ASCII capital letters, numbers and
\                           punctuation)
\
\   X                   Contains the current value of QQ17
\
\   QQ17                Bit 7 is set
\
\ ******************************************************************************

.TT41

                        \ If we get here, then QQ17 has bit 7 set, so we are in
                        \ Sentence Case

 BIT QQ17               \ If QQ17 also has bit 6 set, jump to TT45 to print
 BVS TT45               \ this character in lower case

                        \ If we get here, then QQ17 has bit 6 clear and bit 7
                        \ set, so we are in Sentence Case and we need to print
                        \ the next letter in upper case

 CMP #'A'               \ If A < ASCII "A", then this is punctuation, so jump
 BCC TT74               \ to TT26 (via TT44) to print the character as is, as
                        \ we don't care about the character's case

 PHA                    \ Otherwise this is a letter, so store the token number

 TXA                    \ Set bit 6 in QQ17 (X contains the current QQ17)
 ORA #%1000000          \ so the next letter after this one is printed in lower
 STA QQ17               \ case

 PLA                    \ Restore the token number into A

 BNE TT44               \ Jump to TT26 (via TT44) to print the character in A
                        \ (this BNE is effectively a JMP as A will never be
                        \ zero)

\ ******************************************************************************
\
\       Name: qw
\       Type: Subroutine
\   Category: Text
\    Summary: Print a recursive token in the range 128-145
\
\ ------------------------------------------------------------------------------
\
\ Print a recursive token where the token number is in 128-145 (so the value
\ passed to TT27 is in the range 14-31).
\
\ Arguments:
\
\   A                   A value from 128-145, which refers to a recursive token
\                       in the range 14-31
\
\ ******************************************************************************

.qw

 ADC #114               \ This is a recursive token in the range 0-95, so add
 BNE ex                 \ 114 to the argument to get the token number 128-145
                        \ and jump to ex to print it

\ ******************************************************************************
\
\       Name: crlf
\       Type: Subroutine
\   Category: Text
\    Summary: Tab to column 21 and print a colon
\
\ ------------------------------------------------------------------------------
\
\ Print control code 9 (tab to column 21 and print a colon). The subroutine
\ name is pretty misleading, as it doesn't have anything to do with carriage
\ returns or line feeds.
\
\ ******************************************************************************

.crlf

 LDA #21                \ Set the X-column in XC to 21
 STA XC

 BNE TT73               \ Jump to TT73, which prints a colon (this BNE is
                        \ effectively a JMP as A will never be zero)

\ ******************************************************************************
\
\       Name: TT45
\       Type: Subroutine
\   Category: Text
\    Summary: Print a letter in lower case
\
\ ------------------------------------------------------------------------------
\
\ This routine prints a letter in lower case. Specifically:
\
\   * If QQ17 = 255, abort printing this character as printing is disabled
\
\   * If this is a letter then print in lower case
\
\   * Otherwise this is punctuation, so clear bit 6 in QQ17 and print
\
\ Arguments:
\
\   A                   The character to be printed. Can be one of the
\                       following:
\
\                         * 7 (beep)
\
\                         * 10-13 (line feeds and carriage returns)
\
\                         * 32-95 (ASCII capital letters, numbers and
\                           punctuation)
\
\   X                   Contains the current value of QQ17
\
\   QQ17                Bits 6 and 7 are set
\
\ ******************************************************************************

.TT45

                        \ If we get here, then QQ17 has bit 6 and 7 set, so we
                        \ are in Sentence Case and we need to print the next
                        \ letter in lower case

 CPX #255               \ If QQ17 = 255 then printing is disabled, so return
 BEQ TT48               \ from the subroutine (as TT48 contains an RTS)

 CMP #'A'               \ If A >= ASCII "A", then jump to TT42, which will
 BCS TT42               \ print the letter in lowercase

                        \ Otherwise this is not a letter, it's punctuation, so
                        \ this is effectively a word break. We therefore fall
                        \ through to TT46 to print the character and set QQ17
                        \ to ensure the next word starts with a capital letter

\ ******************************************************************************
\
\       Name: TT46
\       Type: Subroutine
\   Category: Text
\    Summary: Print a character and switch to capitals
\
\ ------------------------------------------------------------------------------
\
\ Print a character and clear bit 6 in QQ17, so that the next letter that gets
\ printed after this will start with a capital letter.
\
\ Arguments:
\
\   A                   The character to be printed. Can be one of the
\                       following:
\
\                         * 7 (beep)
\
\                         * 10-13 (line feeds and carriage returns)
\
\                         * 32-95 (ASCII capital letters, numbers and
\                           punctuation)
\
\   X                   Contains the current value of QQ17
\
\   QQ17                Bits 6 and 7 are set
\
\ ******************************************************************************

.TT46

 PHA                    \ Store the token number

 TXA                    \ Clear bit 6 in QQ17 (X contains the current QQ17) so
 AND #%10111111         \ the next letter after this one is printed in upper
 STA QQ17               \ case

 PLA                    \ Restore the token number into A

                        \ Now fall through into TT74 to print the character

\ ******************************************************************************
\
\       Name: TT74
\       Type: Subroutine
\   Category: Text
\    Summary: Print a character
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The character to be printed
\
\ ******************************************************************************

.TT74

 JMP TT26               \ Print the character in A

\ ******************************************************************************
\
\       Name: TT43
\       Type: Subroutine
\   Category: Text
\    Summary: Print a two-letter token or recursive token 0-95
\
\ ------------------------------------------------------------------------------
\
\ Print a two-letter token, or a recursive token where the token number is in
\ 0-95 (so the value passed to TT27 is in the range 160-255).
\
\ Arguments:
\
\   A                   One of the following:
\
\                         * 128-159 (two-letter token)
\
\                         * 160-255 (the argument to TT27 that refers to a
\                           recursive token in the range 0-95)
\
\ ******************************************************************************

.TT43

 CMP #160               \ If token >= 160, then this is a recursive token, so
 BCS TT47               \ jump to TT47 below to process it

 AND #127               \ This is a two-letter token with number 128-159. The
 ASL A                  \ set of two-letter tokens is stored in a lookup table
                        \ at QQ16, with each token taking up two bytes, so to
                        \ convert this into the token's position in the table,
                        \ we subtract 128 (or just clear bit 7) and multiply
                        \ by 2 (or shift left)

 TAY                    \ Transfer the token's position into Y so we can look
                        \ up the token using absolute indexed mode

 LDA QQ16,Y             \ Get the first letter of the token and print it
 JSR TT27

 LDA QQ16+1,Y           \ Get the second letter of the token

 CMP #'?'               \ If the second letter of the token is a question mark
 BEQ TT48               \ then this is a one-letter token, so just return from
                        \ the subroutine without printing (as TT48 contains an
                        \ RTS)

 JMP TT27               \ Print the second letter and return from the
                        \ subroutine

.TT47

 SBC #160               \ This is a recursive token in the range 160-255, so
                        \ subtract 160 from the argument to get the token
                        \ number 0-95 and fall through into ex to print it

\ ******************************************************************************
\
\       Name: ex
\       Type: Subroutine
\   Category: Text
\    Summary: Print a recursive token
\
\ ------------------------------------------------------------------------------
\
\ This routine works its way through the recursive tokens that are stored in
\ tokenised form in memory at &0400 to &06FF, and when it finds token number A,
\ it prints it. Tokens are null-terminated in memory and fill three pages,
\ but there is no lookup table as that would consume too much memory, so the
\ only way to find the correct token is to start at the beginning and look
\ through the table byte by byte, counting tokens as we go until we are in the
\ right place. This approach might not be terribly speed efficient, but it is
\ certainly memory-efficient.
\
\ For details of the tokenisation system, see variable QQ18.
\
\ Arguments:
\
\   A                   The recursive token to be printed, in the range 0-148
\
\ Other entry points:
\
\   TT48                Contains an RTS
\
\ ******************************************************************************

.ex

 TAX                    \ Copy the token number into X

 LDA #LO(QQ18)          \ Set V, V+1 to point to the recursive token table at
 STA V                  \ location QQ18
 LDA #HI(QQ18)
 STA V+1

 LDY #0                 \ Set a counter Y to point to the character offset
                        \ as we scan through the table

 TXA                    \ Copy the token number back into A, so both A and X
                        \ now contain the token number we want to print

 BEQ TT50               \ If the token number we want is 0, then we have
                        \ already found the token we are looking for, so jump
                        \ to TT50, otherwise start working our way through the
                        \ null-terminated token table until we find the X-th
                        \ token

.TT51

 LDA (V),Y              \ Fetch the Y-th character from the token table page
                        \ we are currently scanning

 BEQ TT49               \ If the character is null, we've reached the end of
                        \ this token, so jump to TT49

 INY                    \ Increment character pointer and loop back round for
 BNE TT51               \ the next character in this token, assuming Y hasn't
                        \ yet wrapped around to 0

 INC V+1                \ If it has wrapped round to 0, we have just crossed
 BNE TT51               \ into a new page, so increment V+1 so that V points
                        \ to the start of the new page

.TT49

 INY                    \ Increment the character pointer

 BNE TT59               \ If Y hasn't just wrapped around to 0, skip the next
                        \ instruction

 INC V+1                \ We have just crossed into a new page, so increment
                        \ V+1 so that V points to the start of the new page

.TT59

 DEX                    \ We have just reached a new token, so decrement the
                        \ token number we are looking for

 BNE TT51               \ Assuming we haven't yet reached the token number in
                        \ X, look back up to keep fetching characters

.TT50

                        \ We have now reached the correct token in the token
                        \ table, with Y pointing to the start of the token as
                        \ an offset within the page pointed to by V, so let's
                        \ print the recursive token. Because recursive tokens
                        \ can contain other recursive tokens, we need to store
                        \ our current state on the stack, so we can retrieve
                        \ it after printing each character in this token

 TYA                    \ Store the offset in Y on the stack
 PHA

 LDA V+1                \ Store the high byte of V (the page containing the
 PHA                    \ token we have found) on the stack, so the stack now
                        \ contains the address of the start of this token

 LDA (V),Y              \ Load the character at offset Y in the token table,
                        \ which is the next character of this token that we
                        \ want to print

 EOR #35                \ Tokens are stored in memory having been EOR'd with 35
                        \ (see variable QQ18 for details), so we repeat the
                        \ EOR to get the actual character to print

 JSR TT27               \ Print the text token in A, which could be a letter,
                        \ number, control code, two-letter token or another
                        \ recursive token

 PLA                    \ Restore the high byte of V (the page containing the
 STA V+1                \ token we have found) into V+1

 PLA                    \ Restore the offset into Y
 TAY

 INY                    \ Increment Y to point to the next character in the
                        \ token we are printing

 BNE P%+4               \ If Y is zero then we have just crossed into a new
 INC V+1                \ page, so increment V+1 so that V points to the start
                        \ of the new page

 LDA (V),Y              \ Load the next character we want to print into A

 BNE TT50               \ If this is not the null character at the end of the
                        \ token, jump back up to TT50 to print the next
                        \ character, otherwise we are done printing

.TT48

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: WPSHPS
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Clear the scanner, reset the ball line and sun line heaps
\
\ ------------------------------------------------------------------------------
\
\ Remove all ships from the scanner, reset the sun line heap at LSO, and reset
\ the ball line heap at LSX2 and LSY2.
\
\ ******************************************************************************

.WPSHPS

 LDX #0                 \ Set up a counter in X to work our way through all the
                        \ ship slots in FRIN

.WSL1

 LDA FRIN,X             \ Fetch the ship type in slot X

 BEQ WS2                \ If the slot contains 0 then it is empty and we have
                        \ checked all the slots (as they are always shuffled
                        \ down in the main loop to close up and gaps), so jump
                        \ to WS2 as we are done

 BMI WS1                \ If the slot contains a ship type with bit 7 set, then
                        \ it contains the planet or the sun, so jump down to WS1
                        \ to skip this slot, as the planet and sun don't appear
                        \ on the scanner

 JSR GINF               \ Call GINF to get the address of the data block for
                        \ ship slot X and store it in INF

 LDY #31                \ We now want to copy the first 32 bytes from the ship's
                        \ data block into INWK, so set a counter in Y

.WSL2

 LDA (INF),Y            \ Copy the Y-th byte from the data block pointed to by
 STA INWK,Y             \ INF into the Y-th byte of INWK workspace

 DEY                    \ Decrement the counter to point at the next byte

 BPL WSL2               \ Loop back to WSL2 until we have copied all 32 bytes

 STX XSAV               \ Store the ship slot number in XSAV while we call SCAN

 LDX XSAV               \ Restore the ship slot number from XSAV into X

 LDY #31                \ Clear bits 3, 4 and 6 in the ship's byte #31, which
 LDA (INF),Y            \ stops drawing the ship on-screen (bit 3), hides it
 AND #%10100111         \ from the scanner (bit 4) and stops any lasers firing
 STA (INF),Y            \ at it (bit 6)

.WS1

 INX                    \ Increment X to point to the next ship slot

 BNE WSL1               \ Loop back up to process the next slot (this BNE is
                        \ effectively a JMP as X will never be zero)

.WS2

 LDX #&FF               \ Set LSX2 = LSY2 = &FF to clear the ball line heap
 STX LSX2
 STX LSY2

                        \ Fall through into FLFLLS to reset the LSO block

\ ******************************************************************************
\
\       Name: FLFLLS
\       Type: Subroutine
\   Category: Drawing suns
\    Summary: Reset the sun line heap
\
\ ------------------------------------------------------------------------------
\
\ Reset the sun line heap at LSO by zero-filling it and setting the first byte
\ to &FF.
\
\ Returns:
\
\   A                   A is set to 0
\
\ ******************************************************************************

.FLFLLS

 LDY #2*Y-1             \ #Y is the y-coordinate of the centre of the space
                        \ view, so this sets Y as a counter for the number of
                        \ lines in the space view (i.e. 191), which is also the
                        \ number of lines in the LSO block

 LDA #0                 \ Set A to 0 so we can zero-fill the LSO block

.SAL6

 STA LSO,Y              \ Set the Y-th byte of the LSO block to 0

 DEY                    \ Decrement the counter

 BNE SAL6               \ Loop back until we have filled all the way to LSO+1

 DEY                    \ Decrement Y to value of &FF (as we exit the above loop
                        \ with Y = 0)

 STY LSX                \ Set the first byte of the LSO block, which has its own
                        \ label LSX, to &FF, to indicate that the sun line heap
                        \ is empty

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: GINF
\       Type: Subroutine
\   Category: Universe
\    Summary: Fetch the address of a ship's data block into INF
\
\ ------------------------------------------------------------------------------
\
\ Get the address of the data block for ship slot X and store it in INF. This
\ address is fetched from the UNIV table, which stores the addresses of the 13
\ ship data blocks in workspace K%.
\
\ Arguments:
\
\   X                   The ship slot number for which we want the data block
\                       address
\
\ ******************************************************************************

.GINF

 TXA                    \ Set Y = X * 2
 ASL A
 TAY

 LDA UNIV,Y             \ Get the high byte of the address of the X-th ship
 STA INF                \ from UNIV and store it in INF

 LDA UNIV+1,Y           \ Get the low byte of the address of the X-th ship
 STA INF+1              \ from UNIV and store it in INF

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: NWSHP
\       Type: Subroutine
\   Category: Universe
\    Summary: Add a new ship to our local bubble of universe
\
\ ------------------------------------------------------------------------------
\
\ This creates a new block of ship data in the K% workspace, allocates a new
\ block in the ship line heap at WP, adds the new ship's type into the first
\ empty slot in FRIN, and adds a pointer to the ship data into UNIV. If there
\ isn't enough free memory for the new ship, it isn't added.
\
\ Arguments:
\
\   A                   The type of the ship to add (see variable XX21 for a
\                       list of ship types)
\
\ Returns:
\
\   C flag              Set if the ship was successfully added, clear if it
\                       wasn't (as there wasn't enough free memory)
\
\   INF                 Points to the new ship's data block in K%
\
\ ******************************************************************************

.NWSHP

 STA T                  \ Store the ship type in location T

 LDX #0                 \ Before we can add a new ship, we need to check
                        \ whether we have an empty slot we can put it in. To do
                        \ this, we need to loop through all the slots to look
                        \ for an empty one, so set a counter in X that starts
                        \ from the first slot at 0. When ships are killed, then
                        \ the slots are shuffled down by the KILLSHP routine, so
                        \ the first empty slot will always come after the last
                        \ filled slot. This allows us to tack the new ship's
                        \ data block and ship line heap onto the end of the
                        \ existing ship data and heap, as shown in the memory
                        \ map below

.NWL1

 LDA FRIN,X             \ Load the ship type for the X-th slot

 BEQ NW1                \ If it is zero, then this slot is empty and we can use
                        \ it for our new ship, so jump down to NW1

 INX                    \ Otherwise increment X to point to the next slot

 CPX #NOSH              \ If we haven't reached the last slot yet, loop back up
 BCC NWL1               \ to NWL1 to check the next slot (note that this means
                        \ only slots from 0 to #NOSH - 1 are populated by this
                        \ routine, but there is one more slot reserved in FRIN,
                        \ which is used to identify the end of the slot list
                        \ when shuffling the slots down in the KILLSHP routine)

.NW3

 CLC                    \ Otherwise we don't have an empty slot, so we can't
 RTS                    \ add a new ship, so clear the C flag to indicate that
                        \ we have not managed to create the new ship, and return
                        \ from the subroutine

.NW1

                        \ If we get here, then we have found an empty slot at
                        \ index X, so we can go ahead and create our new ship.
                        \ We do that by creating a ship data block at INWK and,
                        \ when we are done, copying the block from INWK into
                        \ the K% workspace (specifically, to INF)

 JSR GINF               \ Get the address of the data block for ship slot X
                        \ (which is in workspace K%) and store it in INF

 LDA T                  \ If the type of ship that we want to create is
 BMI NW2                \ negative, then this indicates a planet or sun, so
                        \ jump down to NW2, as the next section sets up a ship
                        \ data block, which doesn't apply to planets and suns,
                        \ as they don't have things like shields, missiles,
                        \ vertices and edges

                        \ This is a ship, so first we need to set up various
                        \ pointers to the ship blueprint we will need. The
                        \ blueprints for each ship type in Elite are stored
                        \ in a table at location XX21, so refer to the comments
                        \ on that variable for more details on the data we're
                        \ about to access

 ASL A                  \ Set Y = ship type * 2
 TAY

 LDA XX21-2,Y           \ The ship blueprints at XX21 start with a lookup
 STA XX0                \ table that points to the individual ship blueprints,
                        \ so this fetches the low byte of this particular ship
                        \ type's blueprint and stores it in XX0

 LDA XX21-1,Y           \ Fetch the high byte of this particular ship type's
 STA XX0+1              \ blueprint and store it in XX0+1, so XX0(1 0) now
                        \ contains the address of this ship's blueprint

                        \ --- Original Acornsoft code removed: ---------------->

\ CPY #2*SST            \ If the ship type is a space station (SST), then jump
\ BEQ NW6               \ to NW6, skipping the heap space steps below, as the
\                       \ space station has its own line heap at LSO (which it
\                       \ shares with the sun)

                        \ --- End of removed code ----------------------------->

                        \ We now want to allocate space for a heap that we can
                        \ use to store the lines we draw for our new ship (so it
                        \ can easily be erased from the screen again). SLSP
                        \ points to the start of the current heap space, and we
                        \ can extend it downwards with the heap for our new ship
                        \ (as the heap space always ends just before the WP
                        \ workspace)

 LDY #5                 \ Fetch ship blueprint byte #5, which contains the
 LDA (XX0),Y            \ maximum heap size required for plotting the new ship,
 STA T1                 \ and store it in T1

 LDA SLSP               \ Take the 16-bit address in SLSP and subtract T1,
 SEC                    \ storing the 16-bit result in INWK(34 33), so this now
 SBC T1                 \ points to the start of the line heap for our new ship
 STA INWK+33
 LDA SLSP+1
 SBC #0
 STA INWK+34

                        \ We now need to check that there is enough free space
                        \ for both this new line heap and the new data block
                        \ for our ship. In memory, this is the layout of the
                        \ ship data blocks and ship line heaps:
                        \
                        \   +-----------------------------------+   &0F34
                        \   |                                   |
                        \   | WP workspace                      |
                        \   |                                   |
                        \   +-----------------------------------+   &0D40 = WP
                        \   |                                   |
                        \   | Current ship line heap            |
                        \   |                                   |
                        \   +-----------------------------------+   SLSP
                        \   |                                   |
                        \   | Proposed heap for new ship        |
                        \   |                                   |
                        \   +-----------------------------------+   INWK(34 33)
                        \   |                                   |
                        \   .                                   .
                        \   .                                   .
                        \   .                                   .
                        \   .                                   .
                        \   .                                   .
                        \   |                                   |
                        \   +-----------------------------------+   INF + NI%
                        \   |                                   |
                        \   | Proposed data block for new ship  |
                        \   |                                   |
                        \   +-----------------------------------+   INF
                        \   |                                   |
                        \   | Existing ship data blocks         |
                        \   |                                   |
                        \   +-----------------------------------+   &0900 = K%
                        \
                        \ So, to work out if we have enough space, we have to
                        \ make sure there is room between the end of our new
                        \ ship data block at INF + NI%, and the start of the
                        \ proposed heap for our new ship at the address we
                        \ stored in INWK(34 33). Or, to put it another way, we
                        \ and to make sure that:
                        \
                        \   INWK(34 33) > INF + NI%
                        \
                        \ which is the same as saying:
                        \
                        \   INWK+33 - INF > NI%
                        \
                        \ because INWK is in zero page, so INWK+34 = 0

 LDA INWK+33            \ Calculate INWK+33 - INF, again using 16-bit
\SEC                    \ arithmetic, and put the result in (A Y), so the high
 SBC INF                \ byte is in A and the low byte in Y. The SEC
 TAY                    \ instruction is commented out in the original source;
 LDA INWK+34            \ as the previous subtraction will never underflow, it
 SBC INF+1              \ is superfluous

 BCC NW3+1              \ If we have an underflow from the subtraction, then
                        \ INF > INWK+33 and we definitely don't have enough
                        \ room for this ship, so jump to NW3+1, which returns
                        \ from the subroutine (with the C flag already cleared)

 BNE NW4                \ If the subtraction of the high bytes in A is not
                        \ zero, and we don't have underflow, then we definitely
                        \ have enough space, so jump to NW4 to continue setting
                        \ up the new ship

 CPY #NI%               \ Otherwise the high bytes are the same in our
 BCC NW3+1              \ subtraction, so now we compare the low byte of the
                        \ result (which is in Y) with NI%. This is the same as
                        \ doing INWK+33 - INF > NI% (see above). If this isn't
                        \ true, the C flag will be clear and we don't have
                        \ enough space, so we jump to NW3+1, which returns
                        \ from the subroutine (with the C flag already cleared)

.NW4

 LDA INWK+33            \ If we get here then we do have enough space for our
 STA SLSP               \ new ship, so store the new bottom of the ship line
 LDA INWK+34            \ heap (i.e. INWK+33) in SLSP, doing both the high and
 STA SLSP+1             \ low bytes

.NW6

 LDY #14                \ Fetch ship blueprint byte #14, which contains the
 LDA (XX0),Y            \ ship's energy, and store it in byte #35
 STA INWK+35

 LDY #19                \ Fetch ship blueprint byte #19, which contains the
 LDA (XX0),Y            \ number of missiles and laser power, and AND with %111
 AND #%00000111         \ to extract the number of missiles before storing in
 STA INWK+31            \ byte #31

 LDA T                  \ Restore the ship type we stored above

.NW2

 STA FRIN,X             \ Store the ship type in the X-th byte of FRIN, so the
                        \ this slot is now shown as occupied in the index table

 TAX                    \ Copy the ship type into X

 BMI P%+5               \ If the ship type is negative (planet or sun), then
                        \ skip the following instruction

 INC MANY,X             \ Increment the total number of ships of type X

 LDY #(NI%-1)           \ The final step is to copy the new ship's data block
                        \ from INWK to INF, so set up a counter for NI% bytes
                        \ in Y

.NWL3

 LDA INWK,Y             \ Load the Y-th byte of INWK and store in the Y-th byte
 STA (INF),Y            \ of the workspace pointed to by INF

 DEY                    \ Decrement the loop counter

 BPL NWL3               \ Loop back for the next byte until we have copied them
                        \ all over

 SEC                    \ We have successfully created our new ship, so set the
                        \ C flag to indicate success

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SUN (Part 1 of 4)
\       Type: Subroutine
\   Category: Drawing suns
\    Summary: Draw the sun: Set up all the variables needed
\  Deep dive: Drawing the sun
\
\ ------------------------------------------------------------------------------
\
\ Draw a new sun with radius K at pixel coordinate (K3, K4), removing the old
\ sun if there is one. This routine is used to draw the sun, as well as the
\ star systems on the Short-range Chart.
\
\ The first part sets up all the variables needed to draw the new sun.
\
\ Arguments:
\
\   K                   The new sun's radius
\
\   K3(1 0)             Pixel x-coordinate of the centre of the new sun
\
\   K4(1 0)             Pixel y-coordinate of the centre of the new sun
\
\   SUNX(1 0)           The x-coordinate of the vertical centre axis of the old
\                       sun (the one currently on-screen)
\
\ Other entry points:
\
\   RTS2                Contains an RTS
\
\ ******************************************************************************

.PLF3

                        \ This is called from below to negate X and set A to
                        \ &FF, for when the new sun's centre is off the bottom
                        \ of the screen (so we don't need to draw its bottom
                        \ half)

 TXA                    \ Negate X using two's complement, so X = ~X + 1
 EOR #%11111111         \
 CLC                    \ We do this because X is negative at this point, as it
 ADC #1                 \ is calculated as 191 - the y-coordinate of the sun's
 TAX                    \ centre, and the centre is off the bottom of the
                        \ screen, past 191. So we negate it to make it positive

.PLF17

                        \ This is called from below to set A to &FF, for when
                        \ the new sun's centre is right on the bottom of the
                        \ screen (so we don't need to draw its bottom half)

 LDA #&FF               \ Set A = &FF

 BNE PLF5               \ Jump to PLF5 (this BNE is effectively a JMP as A is
                        \ never zero)

.SUN

 LDA #1                 \ Set LSX = 1 to indicate the sun line heap is about to
 STA LSX                \ be filled up

 JSR CHKON              \ Call CHKON to check whether any part of the new sun's
                        \ circle appears on-screen, and of it does, set P(2 1)
                        \ to the maximum y-coordinate of the new sun on-screen

 LDA #0                 \ Set A = 0

 LDX K                  \ Set X = K = radius of the new sun

 CPX #96                \ If X >= 96, set the C flag and rotate it into bit 0
 ROL A                  \ of A, otherwise rotate a 0 into bit 0

 CPX #40                \ If X >= 40, set the C flag and rotate it into bit 0
 ROL A                  \ of A, otherwise rotate a 0 into bit 0

 CPX #16                \ If X >= 16, set the C flag and rotate it into bit 0
 ROL A                  \ of A, otherwise rotate a 0 into bit 0

                        \ By now, A contains the following:
                        \
                        \   * If radius is 96-255 then A = %111 = 7
                        \
                        \   * If radius is 40-95  then A = %11  = 3
                        \
                        \   * If radius is 16-39  then A = %1   = 1
                        \
                        \   * If radius is 0-15   then A = %0   = 0
                        \
                        \ The value of A determines the size of the new sun's
                        \ ragged fringes - the bigger the sun, the bigger the
                        \ fringes

.PLF18

 STA CNT                \ Store the fringe size in CNT

                        \ We now calculate the highest pixel y-coordinate of the
                        \ new sun, given that P(2 1) contains the 16-bit maximum
                        \ y-coordinate of the new sun on-screen

 LDA #2*Y-1             \ #Y is the y-coordinate of the centre of the space
                        \ view, so this sets Y to the y-coordinate of the bottom
                        \ of the space view, i.e. 191

 LDX P+2                \ If P+2 is non-zero, the maximum y-coordinate is off
 BNE PLF2               \ the bottom of the screen, so skip to PLF2 with A = 191

 CMP P+1                \ If A < P+1, the maximum y-coordinate is underneath the
 BCC PLF2               \ the dashboard, so skip to PLF2 with A = 191

 LDA P+1                \ Set A = P+1, the low byte of the maximum y-coordinate
                        \ of the sun on-screen

 BNE PLF2               \ If A is non-zero, skip to PLF2 as it contains the
                        \ value we are after

 LDA #1                 \ Otherwise set A = 1, the top line of the screen

.PLF2

 STA TGT                \ Set TGT to A, the maximum y-coordinate of the sun on
                        \ screen

                        \ We now calculate the number of lines we need to draw
                        \ and the direction in which we need to draw them, both
                        \ from the centre of the new sun

 LDA #2*Y-1             \ Set (A X) = y-coordinate of bottom of screen - K4(1 0)
 SEC                    \
 SBC K4                 \ Starting with the low bytes
 TAX

 LDA #0                 \ And then doing the high bytes, so (A X) now contains
 SBC K4+1               \ the number of lines between the centre of the sun and
                        \ the bottom of the screen. If it is positive then the
                        \ centre of the sun is above the bottom of the screen,
                        \ if it is negative then the centre of the sun is below
                        \ the bottom of the screen

 BMI PLF3               \ If A < 0, then this means the new sun's centre is off
                        \ the bottom of the screen, so jump up to PLF3 to negate
                        \ the height in X (so it becomes positive), set A to &FF
                        \ and jump down to PLF5

 BNE PLF4               \ If A > 0, then the new sun's centre is at least a full
                        \ screen above the bottom of the space view, so jump
                        \ down to PLF4 to set X = radius and A = 0

 INX                    \ Set the flags depending on the value of X
 DEX

 BEQ PLF17              \ If X = 0 (we already know A = 0 by this point) then
                        \ jump up to PLF17 to set A to &FF before jumping down
                        \ to PLF5

 CPX K                  \ If X < the radius in K, jump down to PLF5, so if
 BCC PLF5               \ X >= the radius in K, we set X = radius and A = 0

.PLF4

 LDX K                  \ Set X to the radius

 LDA #0                 \ Set A = 0

.PLF5

 STX V                  \ Store the height in V

 STA V+1                \ Store the direction in V+1

 LDA K                  \ Set (A P) = K * K
 JSR SQUA2

 STA K2+1               \ Set K2(1 0) = (A P) = K * K
 LDA P
 STA K2

                        \ By the time we get here, the variables should be set
                        \ up as shown in the header for part 3 below

\ ******************************************************************************
\
\       Name: SUN (Part 2 of 4)
\       Type: Subroutine
\   Category: Drawing suns
\    Summary: Draw the sun: Start from bottom of screen and erase the old sun
\  Deep dive: Drawing the sun
\
\ ------------------------------------------------------------------------------
\
\ This part erases the old sun, starting at the bottom of the screen and working
\ upwards until we reach the bottom of the new sun.
\
\ ******************************************************************************

 LDY #2*Y-1             \ Set Y = y-coordinate of the bottom of the screen,
                        \ which we use as a counter in the following routine to
                        \ redraw the old sun

 LDA SUNX               \ Set YY(1 0) = SUNX(1 0), the x-coordinate of the
 STA YY                 \ vertical centre axis of the old sun that's currently
 LDA SUNX+1             \ on-screen
 STA YY+1

.PLFL2

 CPY TGT                \ If Y = TGT, we have reached the line where we will
 BEQ PLFL               \ start drawing the new sun, so there is no need to
                        \ keep erasing the old one, so jump down to PLFL

 LDA LSO,Y              \ Fetch the Y-th point from the sun line heap, which
                        \ gives us the half-width of the old sun's line on this
                        \ line of the screen

 BEQ PLF13              \ If A = 0, skip the following call to HLOIN2 as there
                        \ is no sun line on this line of the screen

 JSR HLOIN2             \ Call HLOIN2 to draw a horizontal line on pixel line Y,
                        \ with centre point YY(1 0) and half-width A, and remove
                        \ the line from the sun line heap once done

.PLF13

 DEY                    \ Decrement the loop counter

 BNE PLFL2              \ Loop back for the next line in the line heap until
                        \ we have either gone through the entire heap, or
                        \ reached the bottom row of the new sun

\ ******************************************************************************
\
\       Name: SUN (Part 3 of 4)
\       Type: Subroutine
\   Category: Drawing suns
\    Summary: Draw the sun: Continue to move up the screen, drawing the new sun
\  Deep dive: Drawing the sun
\
\ ------------------------------------------------------------------------------
\
\ This part draws the new sun. By the time we get to this point, the following
\ variables should have been set up by parts 1 and 2:
\
\   V                   As we draw lines for the new sun, V contains the
\                       vertical distance between the line we're drawing and the
\                       centre of the new sun. As we draw lines and move up the
\                       screen, we either decrement (bottom half) or increment
\                       (top half) this value. See the deep dive on "Drawing the
\                       sun" to see a diagram that shows V in action
\
\   V+1                 This determines which half of the new sun we are drawing
\                       as we work our way up the screen, line by line:
\
\                         * 0 means we are drawing the bottom half, so the lines
\                           get wider as we work our way up towards the centre,
\                           at which point we will move into the top half, and
\                           V+1 will switch to &FF
\
\                         * &FF means we are drawing the top half, so the lines
\                           get smaller as we work our way up, away from the
\                           centre
\
\   TGT                 The maximum y-coordinate of the new sun on-screen (i.e.
\                       the screen y-coordinate of the bottom row of the new
\                       sun)
\
\   CNT                 The fringe size of the new sun
\
\   K2(1 0)             The new sun's radius squared, i.e. K^2
\
\   Y                   The y-coordinate of the bottom row of the new sun
\
\ ******************************************************************************

.PLFL

 LDA V                  \ Set (T P) = V * V
 JSR SQUA2              \           = V^2
 STA T

 LDA K2                 \ Set (R Q) = K^2 - V^2
 SEC                    \
 SBC P                  \ First calculating the low bytes
 STA Q

 LDA K2+1               \ And then doing the high bytes
 SBC T
 STA R

 STY Y1                 \ Store Y in Y1, so we can restore it after the call to
                        \ LL5

 JSR LL5                \ Set Q = SQRT(R Q)
                        \       = SQRT(K^2 - V^2)
                        \
                        \ So Q contains the half-width of the new sun's line at
                        \ height V from the sun's centre - in other words, it
                        \ contains the half-width of the sun's line on the
                        \ current pixel row Y

 LDY Y1                 \ Restore Y from Y1

 JSR DORND              \ Set A and X to random numbers

 AND CNT                \ Reduce A to a random number in the range 0 to CNT,
                        \ where CNT is the fringe size of the new sun

 CLC                    \ Set A = A + Q
 ADC Q                  \
                        \ So A now contains the half-width of the sun on row
                        \ V, plus a random variation based on the fringe size

 BCC PLF44              \ If the above addition did not overflow, skip the
                        \ following instruction

 LDA #255               \ The above overflowed, so set the value of A to 255

                        \ So A contains the half-width of the new sun on pixel
                        \ line Y, changed by a random amount within the size of
                        \ the sun's fringe

.PLF44

 LDX LSO,Y              \ Set X to the line heap value for the old sun's line
                        \ at row Y

 STA LSO,Y              \ Store the half-width of the new row Y line in the line
                        \ heap

 BEQ PLF11              \ If X = 0 then there was no sun line on pixel row Y, so
                        \ jump to PLF11

 LDA SUNX               \ Set YY(1 0) = SUNX(1 0), the x-coordinate of the
 STA YY                 \ vertical centre axis of the old sun that's currently
 LDA SUNX+1             \ on-screen
 STA YY+1

 TXA                    \ Transfer the line heap value for the old sun's line
                        \ from X into A

 JSR EDGES              \ Call EDGES to calculate X1 and X2 for the horizontal
                        \ line centred on YY(1 0) and with half-width A, i.e.
                        \ the line for the old sun

 LDA X1                 \ Store X1 and X2, the ends of the line for the old sun,
 STA XX                 \ in XX and XX+1
 LDA X2
 STA XX+1

 LDA K3                 \ Set YY(1 0) = K3(1 0), the x-coordinate of the centre
 STA YY                 \ of the new sun
 LDA K3+1
 STA YY+1

 LDA LSO,Y              \ Fetch the half-width of the new row Y line from the
                        \ line heap (which we stored above)

 JSR EDGES              \ Call EDGES to calculate X1 and X2 for the horizontal
                        \ line centred on YY(1 0) and with half-width A, i.e.
                        \ the line for the new sun

 BCS PLF23              \ If the C flag is set, the new line doesn't fit on the
                        \ screen, so jump to PLF23 to just draw the old line
                        \ without drawing the new one

                        \ At this point the old line is from XX to XX+1 and the
                        \ new line is from X1 to X2, and both fit on-screen. We
                        \ now want to remove the old line and draw the new one.
                        \ We could do this by simply drawing the old one then
                        \ drawing the new one, but instead Elite does this by
                        \ drawing first from X1 to XX and then from X2 to XX+1,
                        \ which you can see in action by looking at all the
                        \ permutations below of the four points on the line and
                        \ imagining what happens if you draw from X1 to XX and
                        \ X2 to XX+1 using EOR logic. The six possible
                        \ permutations are as follows, along with the result of
                        \ drawing X1 to XX and then X2 to XX+1:
                        \
                        \   X1    X2    XX____XX+1      ->      +__+  +  +
                        \
                        \   X1    XX____X2____XX+1      ->      +__+__+  +
                        \
                        \   X1    XX____XX+1  X2        ->      +__+__+__+
                        \
                        \   XX____X1____XX+1  X2        ->      +  +__+__+
                        \
                        \   XX____XX+1  X1    X2        ->      +  +  +__+
                        \
                        \   XX____X1____X2____XX+1      ->      +  +__+  +
                        \
                        \ They all end up with a line between X1 and Y1, which
                        \ is what we want. There's probably a mathematical proof
                        \ of why this works somewhere, but the above is probably
                        \ easier to follow.
                        \
                        \ We can draw from X1 to XX and X2 to XX+1 by swapping
                        \ XX and X2 and drawing from X1 to X2, and then drawing
                        \ from XX to XX+1, so let's do this now

 LDA X2                 \ Swap XX and X2
 LDX XX
 STX X2
 STA XX

 JSR HLOIN              \ Draw a horizontal line from (X1, Y1) to (X2, Y1)

.PLF23

                        \ If we jump here from the BCS above when there is no
                        \ new line this will just draw the old line

 LDA XX                 \ Set X1 = XX
 STA X1

 LDA XX+1               \ Set X2 = XX+1
 STA X2

.PLF16

 JSR HLOIN              \ Draw a horizontal line from (X1, Y1) to (X2, Y1)

.PLF6

 DEY                    \ Decrement the line number in Y to move to the line
                        \ above

 BEQ PLF8               \ If we have reached the top of the screen, jump to PLF8
                        \ as we are done drawing (the top line of the screen is
                        \ the border, so we don't draw there)

 LDA V+1                \ If V+1 is non-zero then we are doing the top half of
 BNE PLF10              \ the new sun, so jump down to PLF10 to increment V and
                        \ decrease the width of the line we draw

 DEC V                  \ Decrement V, the height of the sun that we use to work
                        \ out the width, so this makes the line get wider, as we
                        \ move up towards the sun's centre

 BNE PLFL               \ If V is non-zero, jump back up to PLFL to do the next
                        \ screen line up

 DEC V+1                \ Otherwise V is 0 and we have reached the centre of the
                        \ sun, so decrement V+1 to -1 so we start incrementing V
                        \ each time, thus doing the top half of the new sun

.PLFLS

 JMP PLFL               \ Jump back up to PLFL to do the next screen line up

.PLF11

                        \ If we get here then there is no old sun line on this
                        \ line, so we can just draw the new sun's line. The new

 LDX K3                 \ Set YY(1 0) = K3(1 0), the x-coordinate of the centre
 STX YY                 \ of the new sun's line
 LDX K3+1
 STX YY+1

 JSR EDGES              \ Call EDGES to calculate X1 and X2 for the horizontal
                        \ line centred on YY(1 0) and with half-width A, i.e.
                        \ the line for the new sun

 BCC PLF16              \ If the line is on-screen, jump up to PLF16 to draw the
                        \ line and loop round for the next line up

 LDA #0                 \ The line is not on-screen, so set the line heap for
 STA LSO,Y              \ line Y to 0, which means there is no sun line here

 BEQ PLF6               \ Jump up to PLF6 to loop round for the next line up
                        \ (this BEQ is effectively a JMP as A is always zero)

.PLF10

 LDX V                  \ Increment V, the height of the sun that we use to work
 INX                    \ out the width, so this makes the line get narrower, as
 STX V                  \ we move up and away from the sun's centre

 CPX K                  \ If V <= the radius of the sun, we still have lines to
 BCC PLFLS              \ draw, so jump up to PLFL (via PLFLS) to do the next
 BEQ PLFLS              \ screen line up

\ ******************************************************************************
\
\       Name: SUN (Part 4 of 4)
\       Type: Subroutine
\   Category: Drawing suns
\    Summary: Draw the sun: Continue to the top of the screen, erasing old sun
\  Deep dive: Drawing the sun
\
\ ------------------------------------------------------------------------------
\
\ This part erases any remaining traces of the old sun, now that we have drawn
\ all the way to the top of the new sun.
\
\ ******************************************************************************

 LDA SUNX               \ Set YY(1 0) = SUNX(1 0), the x-coordinate of the
 STA YY                 \ vertical centre axis of the old sun that's currently
 LDA SUNX+1             \ on-screen
 STA YY+1

.PLFL3

 LDA LSO,Y              \ Fetch the Y-th point from the sun line heap, which
                        \ gives us the half-width of the old sun's line on this
                        \ line of the screen

 BEQ PLF9               \ If A = 0, skip the following call to HLOIN2 as there
                        \ is no sun line on this line of the screen

 JSR HLOIN2             \ Call HLOIN2 to draw a horizontal line on pixel line Y,
                        \ with centre point YY(1 0) and half-width A, and remove
                        \ the line from the sun line heap once done

.PLF9

 DEY                    \ Decrement the line number in Y to move to the line
                        \ above

 BNE PLFL3              \ Jump up to PLFL3 to redraw the next line up, until we
                        \ have reached the top of the screen

.PLF8

                        \ If we get here, we have successfully made it from the
                        \ bottom line of the screen to the top, and the old sun
                        \ has been replaced by the new one

 CLC                    \ Clear the C flag to indicate success in drawing the
                        \ sun

 LDA K3                 \ Set SUNX(1 0) = K3(1 0)
 STA SUNX
 LDA K3+1
 STA SUNX+1

.RTS2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: CIRCLE2
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Draw a circle (for the planet or chart)
\  Deep dive: Drawing circles
\
\ ------------------------------------------------------------------------------
\
\ Draw a circle with the centre at (K3, K4) and radius K. Used to draw the
\ planet and the chart circles.
\
\ Arguments:
\
\   STP                 The step size for the circle
\
\   K                   The circle's radius
\
\   K3(1 0)             Pixel x-coordinate of the centre of the circle
\
\   K4(1 0)             Pixel y-coordinate of the centre of the circle
\
\ Returns:
\
\   C flag              The C flag is cleared
\
\ ******************************************************************************

.CIRCLE2

 LDX #&FF               \ Set FLAG = &FF to reset the ball line heap in the call
 STX FLAG               \ to the BLINE routine below

 INX                    \ Set CNT = 0, our counter that goes up to 64, counting
 STX CNT                \ segments in our circle

.PLL3

 LDA CNT                \ Set A = CNT

 JSR FMLTU2             \ Call FMLTU2 to calculate:
                        \
                        \   A = K * sin(A)
                        \     = K * sin(CNT)

 LDX #0                 \ Set T = 0, so we have the following:
 STX T                  \
                        \   (T A) = K * sin(CNT)
                        \
                        \ which is the x-coordinate of the circle for this count

 LDX CNT                \ If CNT < 33 then jump to PL37, as this is the right
 CPX #33                \ half of the circle and the sign of the x-coordinate is
 BCC PL37               \ correct

 EOR #%11111111         \ This is the left half of the circle, so we want to
 ADC #0                 \ flip the sign of the x-coordinate in (T A) using two's
 TAX                    \ complement, so we start with the low byte and store it
                        \ in X (the ADC adds 1 as we know the C flag is set)

 LDA #&FF               \ And then we flip the high byte in T
 ADC #0
 STA T

 TXA                    \ Finally, we restore the low byte from X, so we have
                        \ now negated the x-coordinate in (T A)

 CLC                    \ Clear the C flag so we can do some more addition below

.PL37

 ADC K3                 \ We now calculate the following:
 STA K6                 \
                        \   K6(1 0) = (T A) + K3(1 0)
                        \
                        \ to add the coordinates of the centre to our circle
                        \ point, starting with the low bytes

 LDA K3+1               \ And then doing the high bytes, so we now have:
 ADC T                  \
 STA K6+1               \   K6(1 0) = K * sin(CNT) + K3(1 0)
                        \
                        \ which is the result we want for the x-coordinate

 LDA CNT                \ Set A = CNT + 16
 CLC
 ADC #16

 JSR FMLTU2             \ Call FMLTU2 to calculate:
                        \
                        \   A = K * sin(A)
                        \     = K * sin(CNT + 16)
                        \     = K * cos(CNT)

 TAX                    \ Set X = A
                        \       = K * cos(CNT)

 LDA #0                 \ Set T = 0, so we have the following:
 STA T                  \
                        \   (T X) = K * cos(CNT)
                        \
                        \ which is the y-coordinate of the circle for this count

 LDA CNT                \ Set A = (CNT + 15) mod 64
 ADC #15
 AND #63

 CMP #33                \ If A < 33 (i.e. CNT is 0-16 or 48-64) then jump to
 BCC PL38               \ PL38, as this is the bottom half of the circle and the
                        \ sign of the y-coordinate is correct

 TXA                    \ This is the top half of the circle, so we want to
 EOR #%11111111         \ flip the sign of the y-coordinate in (T X) using two's
 ADC #0                 \ complement, so we start with the low byte in X (the
 TAX                    \ ADC adds 1 as we know the C flag is set)

 LDA #&FF               \ And then we flip the high byte in T, so we have
 ADC #0                 \ now negated the y-coordinate in (T X)
 STA T

 CLC                    \ Clear the C flag so we can do some more addition below

.PL38

 JSR BLINE              \ Call BLINE to draw this segment, which also increases
                        \ CNT by STP, the step size

 CMP #65                \ If CNT >= 65 then skip the next instruction
 BCS P%+5

 JMP PLL3               \ Jump back for the next segment

 CLC                    \ Clear the C flag to indicate success

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: EDGES
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Draw a horizontal line given a centre and a half-width
\
\ ------------------------------------------------------------------------------
\
\ Set X1 and X2 to the x-coordinates of the ends of the horizontal line with
\ centre x-coordinate YY(1 0), and length A in either direction from the centre
\ (so a total line length of 2 * A). In other words, this line:
\
\   X1             YY(1 0)             X2
\   +-----------------+-----------------+
\         <- A ->           <- A ->
\
\ The resulting line gets clipped to the edges of the screen, if needed. If the
\ calculation doesn't overflow, we return with the C flag clear, otherwise the C
\ flag gets set to indicate failure and the Y-th LSO entry gets set to 0.
\
\ Arguments:
\
\   A                   The half-length of the line
\
\   YY(1 0)             The centre x-coordinate
\
\ Returns:
\
\   C flag              Clear if the line fits on-screen, set if it doesn't
\
\   X1, X2              The x-coordinates of the clipped line
\
\   LSO+Y               If the line doesn't fit, LSO+Y is set to 0
\
\   Y                   Y is preserved
\
\ Other entry points:
\
\   PL44                Clear the C flag and return from the subroutine
\
\ ******************************************************************************

.EDGES

 STA T                  \ Set T to the line's half-length in argument A

 CLC                    \ We now calculate:
 ADC YY                 \
 STA X2                 \  (A X2) = YY(1 0) + A
                        \
                        \ to set X2 to the x-coordinate of the right end of the
                        \ line, starting with the low bytes

 LDA YY+1               \ And then adding the high bytes
 ADC #0

 BMI ED1                \ If the addition is negative then the calculation has
                        \ overflowed, so jump to ED1 to return a failure

 BEQ P%+6               \ If the high byte A from the result is 0, skip the
                        \ next two instructions, as the result already fits on
                        \ the screen

 LDA #254               \ The high byte is positive and non-zero, so we went
 STA X2                 \ past the right edge of the screen, so clip X2 to the
                        \ x-coordinate of the right edge of the screen

 LDA YY                 \ We now calculate:
 SEC                    \
 SBC T                  \   (A X1) = YY(1 0) - argument A
 STA X1                 \
                        \ to set X1 to the x-coordinate of the left end of the
                        \ line, starting with the low bytes

 LDA YY+1               \ And then subtracting the high bytes
 SBC #0

 BNE ED3                \ If the high byte subtraction is non-zero, then skip
                        \ to ED3

 CLC                    \ Otherwise the high byte of the subtraction was zero,
                        \ so the line fits on-screen and we clear the C flag to
                        \ indicate success

 RTS                    \ Return from the subroutine

.ED3

 BPL ED1                \ If the addition is positive then the calculation has
                        \ underflowed, so jump to ED1 to return a failure

 LDA #2                 \ The high byte is negative and non-zero, so we went
 STA X1                 \ past the left edge of the screen, so clip X1 to the
                        \ y-coordinate of the left edge of the screen

.PL44

 CLC                    \ The line does fit on-screen, so clear the C flag to
                        \ indicate success

 RTS                    \ Return from the subroutine

.ED1

 LDA #0                 \ Set the Y-th byte of the LSO block to 0
 STA LSO,Y

                        \ The line does not fit on the screen, so fall through
                        \ into PL21 to set the C flag to indicate this result

\ ******************************************************************************
\
\       Name: PL21
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Return from a planet/sun-drawing routine with a failure flag
\
\ ------------------------------------------------------------------------------
\
\ Set the C flag and return from the subroutine. This is used to return from a
\ planet- or sun-drawing routine with the C flag indicating an overflow in the
\ calculation.
\
\ ******************************************************************************

.PL21

 SEC                    \ Set the C flag to indicate an overflow

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: CHKON
\       Type: Subroutine
\   Category: Drawing circles
\    Summary: Check whether any part of a circle appears on the extended screen
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   K                   The circle's radius
\
\   K3(1 0)             Pixel x-coordinate of the centre of the circle
\
\   K4(1 0)             Pixel y-coordinate of the centre of the circle
\
\ Returns:
\
\   C flag              Clear if any part of the circle appears on-screen, set
\                       if none of the circle appears on-screen
\
\   (A X)               Minimum y-coordinate of the circle on-screen (i.e. the
\                       y-coordinate of the top edge of the circle)
\
\   P(2 1)              Maximum y-coordinate of the circle on-screen (i.e. the
\                       y-coordinate of the bottom edge of the circle)
\
\ ******************************************************************************

.CHKON

 LDA K3                 \ Set A = K3 + K
 CLC
 ADC K

 LDA K3+1               \ Set A = K3+1 + 0 + any carry from above, so this
 ADC #0                 \ effectively sets A to the high byte of K3(1 0) + K:
                        \
                        \   (A ?) = K3(1 0) + K
                        \
                        \ so A is the high byte of the x-coordinate of the right
                        \ edge of the circle

 BMI PL21               \ If A is negative then the right edge of the circle is
                        \ to the left of the screen, so jump to PL21 to set the
                        \ C flag and return from the subroutine, as the whole
                        \ circle is off-screen to the left

 LDA K3                 \ Set A = K3 - K
 SEC
 SBC K

 LDA K3+1               \ Set A = K3+1 - 0 - any carry from above, so this
 SBC #0                 \ effectively sets A to the high byte of K3(1 0) - K:
                        \
                        \   (A ?) = K3(1 0) - K
                        \
                        \ so A is the high byte of the x-coordinate of the left
                        \ edge of the circle

 BMI PL31               \ If A is negative then the left edge of the circle is
                        \ to the left of the screen, and we already know the
                        \ right edge is either on-screen or off-screen to the
                        \ right, so skip to PL31 to move on to the y-coordinate
                        \ checks, as at least part of the circle is on-screen in
                        \ terms of the x-axis

 BNE PL21               \ If A is non-zero, then the left edge of the circle is
                        \ to the right of the screen, so jump to PL21 to set the
                        \ C flag and return from the subroutine, as the whole
                        \ circle is off-screen to the right

.PL31

 LDA K4                 \ Set P+1 = K4 + K
 CLC
 ADC K
 STA P+1

 LDA K4+1               \ Set A = K4+1 + 0 + any carry from above, so this
 ADC #0                 \ does the following:
                        \
                        \   (A P+1) = K4(1 0) + K
                        \
                        \ so A is the high byte of the y-coordinate of the
                        \ bottom edge of the circle

 BMI PL21               \ If A is negative then the bottom edge of the circle is
                        \ above the top of the screen, so jump to PL21 to set
                        \ the C flag and return from the subroutine, as the
                        \ whole circle is off-screen to the top

 STA P+2                \ Store the high byte in P+2, so now we have:
                        \
                        \   P(2 1) = K4(1 0) + K
                        \
                        \ i.e. the maximum y-coordinate of the circle on-screen
                        \ (which we return)

 LDA K4                 \ Set X = K4 - K
 SEC
 SBC K
 TAX

 LDA K4+1               \ Set A = K4+1 - 0 - any carry from above, so this
 SBC #0                 \ does the following:
                        \
                        \   (A X) = K4(1 0) - K
                        \
                        \ so A is the high byte of the y-coordinate of the top
                        \ edge of the circle

 BMI PL44               \ If A is negative then the top edge of the circle is
                        \ above the top of the screen, and we already know the
                        \ bottom edge is either on-screen or below the bottom
                        \ of the screen, so skip to PL44 to clear the C flag and
                        \ return from the subroutine using a tail call, as part
                        \ of the circle definitely appears on-screen

 BNE PL21               \ If A is non-zero, then the top edge of the circle is
                        \ below the bottom of the screen, so jump to PL21 to set
                        \ the C flag and return from the subroutine, as the
                        \ whole circle is off-screen to the bottom

 CPX #2*Y-1             \ If we get here then A is zero, which means the top
                        \ edge of the circle is within the screen boundary, so
                        \ now we need to check whether it is in the space view
                        \ (in which case it is on-screen) or the dashboard (in
                        \ which case the top of the circle is hidden by the
                        \ dashboard, so the circle isn't on-screen). We do this
                        \ by checking the low byte of the result in X against
                        \ 2 * #Y - 1, and returning the C flag from this
                        \ comparison. The constant #Y is the y-coordinate of the
                        \ mid-point of the space view, so 2 * #Y - 1 is 191, the
                        \ y-coordinate of the bottom pixel row of the space
                        \ view. So this does the following:
                        \
                        \   * The C flag is set if coordinate (A X) is below the
                        \     bottom row of the space view, i.e. the top edge of
                        \     the circle is hidden by the dashboard
                        \
                        \   * The C flag is clear if coordinate (A X) is above
                        \     the bottom row of the space view, i.e. the top
                        \     edge of the circle is on-screen

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TT17
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan the keyboard for cursor key or joystick movement
\
\ ------------------------------------------------------------------------------
\
\ Scan the keyboard and joystick for cursor key or stick movement, and return
\ the result as deltas (changes) in x- and y-coordinates as follows:
\
\   * For joystick, X and Y are integers between -2 and +2 depending on how far
\     the stick has moved
\
\   * For keyboard, X and Y are integers between -1 and +1 depending on which
\     keys are pressed
\
\ Returns:
\
\   A                   The key pressed, if the arrow keys were used
\
\   X                   Change in the x-coordinate according to the cursor keys
\                       being pressed or joystick movement, as an integer (see
\                       above)
\
\   Y                   Change in the y-coordinate according to the cursor keys
\                       being pressed or joystick movement, as an integer (see
\                       above)
\
\ ******************************************************************************

.TT17

 JSR DOKEY              \ Scan the keyboard for flight controls and pause keys,
                        \ (or the equivalent on joystick) and update the key
                        \ logger, setting KL to the key pressed

 LDA JSTK               \ If the joystick is not configured, jump down to TJ1,
 BEQ TJ1                \ otherwise we move the cursor with the joystick

 LDA JSTX               \ Fetch the joystick roll, ranging from 1 to 255 with
                        \ 128 as the centre point

 EOR #&FF               \ Flip the sign so A = -JSTX, because the joystick roll
                        \ works in the opposite way to moving a cursor on-screen
                        \ in terms of left and right

 JSR TJS1               \ Call TJS1 just below to set A to a value between -2
                        \ and +2 depending on the joystick roll value (moving
                        \ the stick sideways)

 TYA                    \ Copy Y to A

 TAX                    \ Copy A to X, so X contains the joystick roll value

 LDA JSTY               \ Fetch the joystick pitch, ranging from 1 to 255 with
                        \ 128 as the centre point, and fall through into TJS1 to
                        \ set Y to the joystick pitch value (moving the stick up
                        \ and down)

.TJS1

 TAY                    \ Store A in Y

 LDA #0                 \ Set the result, A = 0

 CPY #16                \ If Y >= 16 set the C flag, so A = A - 1
 SBC #0

\CPY #&20               \ These instructions are commented out in the original
\SBC #0                 \ source, but they would make the joystick move the
                        \ cursor faster by increasing the range of Y by -1 to +1

 CPY #64                \ If Y >= 64 set the C flag, so A = A - 1
 SBC #0

 CPY #192               \ If Y >= 192 set the C flag, so A = A + 1
 ADC #0

 CPY #224               \ If Y >= 224 set the C flag, so A = A + 1
 ADC #0

\CPY #&F0               \ These instructions are commented out in the original
\ADC #0                 \ source, but they would make the joystick move the
                        \ cursor faster by increasing the range of Y by -1 to +1

 TAY                    \ Copy the value of A into Y

 LDA KL                 \ Set A to the value of KL (the key pressed)

 RTS                    \ Return from the subroutine

.TJ1

 LDA KL                 \ Set A to the value of KL (the key pressed)

 LDX #0                 \ Set the initial values for the results, X = Y = 0,
 LDY #0                 \ which we now increase or decrease appropriately

 CMP #&19               \ If left arrow was pressed, set X = X - 1
 BNE P%+3
 DEX

 CMP #&79               \ If right arrow was pressed, set X = X + 1
 BNE P%+3
 INX

 CMP #&39               \ If up arrow was pressed, set Y = Y + 1
 BNE P%+3
 INY

 CMP #&29               \ If down arrow was pressed, set Y = Y - 1
 BNE P%+3
 DEY

 STX T                  \ Set T to the value of X, which contains the joystick
                        \ roll value

 LDX #0                 \ Scan the keyboard to see if the SHIFT key is currently
 JSR DKS4               \ being pressed, returning the result in A and X

 BPL TJe                \ If SHIFT is not being pressed, skip to TJe

 ASL T                  \ SHIFT is being held down, so quadruple the value of T
 ASL T                  \ (i.e. SHIFT moves the cursor at four times the speed
                        \ when using the joystick)

 TYA                    \ Fetch the joystick pitch value from Y into A

 ASL A                  \ SHIFT is being held down, so quadruple the value of A
 ASL A                  \ (i.e. SHIFT moves the cursor at four times the speed
                        \ when using the joystick)

 TAY                    \ Transfer the amended value of A back into Y

.TJe

 LDX T                  \ Fetch the amended value of T back into X

 LDA KL                 \ Set A to the value of KL (the key pressed)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ping
\       Type: Subroutine
\   Category: Universe
\    Summary: Set the selected system to the current system
\
\ ******************************************************************************

.ping

 LDX #1                 \ We want to copy the X- and Y-coordinates of the
                        \ current system in (QQ0, QQ1) to the selected system's
                        \ coordinates in (QQ9, QQ10), so set up a counter to
                        \ copy two bytes

.pl1

 LDA QQ0,X              \ Load byte X from the current system in QQ0/QQ1

 STA QQ9,X              \ Store byte X in the selected system in QQ9/QQ10

 DEX                    \ Decrement the loop counter

 BPL pl1                \ Loop back for the next byte to copy

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\ Save output/ELTE.bin
\
\ ******************************************************************************

PRINT "ELITE E"
PRINT "Assembled at ", ~CODE_E%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_E%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_E%

PRINT "S.F.ELTE ", ~CODE_E%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_E%
\SAVE "output/F.ELTE.bin", CODE_E%, P%, LOAD%

\ ******************************************************************************
\
\ ELITE F FILE
\
\ ******************************************************************************

CODE_F% = P%
LOAD_F% = LOAD% + P% - CODE%

\ ******************************************************************************
\
\       Name: SFX
\       Type: Variable
\   Category: Sound
\    Summary: Sound data
\
\ ------------------------------------------------------------------------------
\
\ Sound data. To make a sound, the NOS1 routine copies the four relevant sound
\ bytes to XX16, and NO3 then makes the sound. The sound numbers are shown in
\ the table, and are always multiples of 8. Generally, sounds are made by
\ calling the NOISE routine with the sound number in A.
\
\ These bytes are passed to OSWORD 7, and are the equivalents to the parameters
\ passed to the SOUND keyword in BASIC. The parameters therefore have these
\ meanings:
\
\   channel/flush, amplitude (or envelope number if 1-4), pitch, duration
\
\ For the channel/flush parameter, the first byte is the channel while the
\ second is the flush control (where a flush control of 0 queues the sound,
\ while a flush control of 1 makes the sound instantly). When written in
\ hexadecimal, the first figure gives the flush control, while the second is
\ the channel (so &13 indicates flush control = 1 and channel = 3).
\
\ So when we call NOISE with A = 40 to make a long, low beep, then this is
\ effectively what the NOISE routine does:
\
\   SOUND &13, &F4, &0C, &08
\
\ which makes a sound with flush control 1 on channel 3, and with amplitude &F4
\ (-12), pitch &0C (2) and duration &08 (8). Meanwhile, to make the hyperspace
\ sound, the NOISE routine does this:
\
\   SOUND &10, &02, &60, &10
\
\ which makes a sound with flush control 1 on channel 0, using envelope 2,
\ and with pitch &60 (96) and duration &10 (16). The four sound envelopes (1-4)
\ are set up by the loading process.
\
\ ******************************************************************************

.SFX

 EQUB &12,&01,&00,&10   \ 0  - Lasers fired by us
 EQUB &12,&02,&2C,&08   \ 8  - We're being hit by lasers
 EQUB &11,&03,&F0,&18   \ 16 - We died 1 / We made a hit or kill 2
 EQUB &10,&F1,&07,&1A   \ 24 - We died 2 / We made a hit or kill 1
 EQUB &03,&F1,&BC,&01   \ 32 - Short, high beep
 EQUB &13,&F4,&0C,&08   \ 40 - Long, low beep
 EQUB &10,&F1,&06,&0C   \ 48 - Missile launched / Ship launched from station
 EQUB &10,&02,&60,&10   \ 56 - Hyperspace drive engaged
 EQUB &13,&04,&C2,&FF   \ 64 - E.C.M. on
 EQUB &13,&00,&00,&00   \ 72 - E.C.M. off

\ ******************************************************************************
\
\       Name: RES2
\       Type: Subroutine
\   Category: Start and end
\    Summary: Reset a number of flight variables and workspaces
\
\ ------------------------------------------------------------------------------
\
\ This is called after we launch from a space station, arrive in a new system
\ after hyperspace, launch an escape pod, or die a cold, lonely death in the
\ depths of space.
\
\ Returns:
\
\   Y                   Y is set to &FF
\
\ ******************************************************************************

.RES2

 LDA #NOST              \ Reset NOSTM, the number of stardust particles, to the
 STA NOSTM              \ maximum allowed (18)

 LDX #&FF               \ Reset LSX2 and LSY2, the ball line heaps used by the
 STX LSX2               \ BLINE routine for drawing circles, to &FF, to set the
 STX LSY2               \ heap to empty

 STX MSTG               \ Reset MSTG, the missile target, to &FF (no target)

 LDA #128               \ Set the current pitch rate to the mid-point, 128
 STA JSTY

 STA ALP2               \ Reset ALP2 (roll sign) and BET2 (pitch sign)
 STA BET2               \ to negative, i.e. pitch and roll negative

 ASL A                  \ This sets A to 0

 STA ALP2+1             \ Reset ALP2+1 (flipped roll sign) and BET2+1 (flipped
 STA BET2+1             \ pitch sign) to positive, i.e. pitch and roll negative

 STA MCNT               \ Reset MCNT (the main loop counter) to 0

                        \ --- Original Acornsoft code removed: ---------------->

\.modify

                        \ --- End of removed code ----------------------------->

 LDA #3                 \ Reset DELTA (speed) to 3
 STA DELTA

 STA ALPHA              \ Reset ALPHA (roll angle alpha) to 3

 STA ALP1               \ Reset ALP1 (magnitude of roll angle alpha) to 3

 LDA ECMA               \ Fetch the E.C.M. status flag, and if E.C.M. is off,
 BEQ yu                 \ skip the next instruction

 JSR ECMOF              \ Turn off the E.C.M. sound

.yu

 JSR WPSHPS             \ Wipe all ships from the scanner

 JSR ZERO               \ Zero-fill pages &9, &A, &B, &C and &D, which clears
                        \ the ship data blocks, the ship line heap, the ship
                        \ slots for the local bubble of universe, and various
                        \ flight and ship status variables

 LDA #LO(LS%)           \ We have reset the ship line heap, so we now point
 STA SLSP               \ SLSP to LS% (the byte below the ship blueprints at D%)
 LDA #HI(LS%)           \ to indicate that the heap is empty
 STA SLSP+1

                        \ --- Original Acornsoft code removed: ---------------->

\ JSR DIALS             \ Update the dashboard

                        \ --- End of removed code ----------------------------->

                        \ Finally, fall through into ZINF to reset the INWK
                        \ ship workspace

\ ******************************************************************************
\
\       Name: ZINF
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Reset the INWK workspace and orientation vectors
\  Deep dive: Orientation vectors
\
\ ------------------------------------------------------------------------------
\
\ Zero-fill the INWK ship workspace and reset the orientation vectors, with
\ nosev pointing out of the screen, towards us.
\
\ Returns:
\
\   Y                   Y is set to &FF
\
\ ******************************************************************************

.ZINF

 LDY #NI%-1             \ There are NI% bytes in the INWK workspace, so set a
                        \ counter in Y so we can loop through them

 LDA #0                 \ Set A to 0 so we can zero-fill the workspace

.ZI1

 STA INWK,Y             \ Zero the Y-th byte of the INWK workspace

 DEY                    \ Decrement the loop counter

 BPL ZI1                \ Loop back for the next byte, ending when we have
                        \ zero-filled the last byte at INWK, which leaves Y
                        \ with a value of &FF

                        \ Finally, we reset the orientation vectors as follows:
                        \
                        \   sidev = (1,  0,  0)
                        \   roofv = (0,  1,  0)
                        \   nosev = (0,  0, -1)
                        \
                        \ 96 * 256 (&6000) represents 1 in the orientation
                        \ vectors, while -96 * 256 (&E000) represents -1. We
                        \ already set the vectors to zero above, so we just
                        \ need to set up the high bytes of the diagonal values
                        \ and we're done. The negative nosev makes the ship
                        \ point towards us, as the z-axis points into the screen

 LDA #96                \ Set A to represent a 1 (in vector terms)

 STA INWK+18            \ Set byte #18 = roofv_y_hi = 96 = 1

 STA INWK+22            \ Set byte #22 = sidev_x_hi = 96 = 1

 ORA #128               \ Flip the sign of A to represent a -1

 STA INWK+14            \ Set byte #14 = nosev_z_hi = -96 = -1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: me2
\       Type: Subroutine
\   Category: Text
\    Summary: Remove an in-flight message from the space view
\
\ ******************************************************************************

.me2

 LDA MCH                \ Fetch the token number of the current message into A

 JSR MESS               \ Call MESS to print the token, which will remove it
                        \ from the screen as printing uses EOR logic

 LDA #0                 \ Set the delay in DLY to 0, so any new in-flight
 STA DLY                \ messages will be shown instantly

 JMP me3                \ Jump back into the main spawning loop at TT100

\ ******************************************************************************
\
\       Name: DORND
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Generate random numbers
\  Deep dive: Generating random numbers
\
\ ------------------------------------------------------------------------------
\
\ Set A and X to random numbers. The C and V flags are also set randomly.
\
\ ******************************************************************************

                        \ --- Original Acornsoft code removed: ---------------->

\.DORND2
\
\ CLC                   \ This ensures that bit 0 of r2 is 0

                        \ --- End of removed code ----------------------------->

.DORND

 LDA RAND               \ r2´ = ((r0 << 1) mod 256) + C
 ROL A                  \ r0´ = r2´ + r2 + bit 7 of r0
 TAX
 ADC RAND+2             \ C = C flag from r0´ calculation
 STA RAND
 STX RAND+2

 LDA RAND+1             \ A = r1´ = r1 + r3 + C
 TAX                    \ X = r3´ = r1
 ADC RAND+3
 STA RAND+1
 STX RAND+3

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: Main game loop (Part 2 of 6)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Update the main loop counters
\  Deep dive: Program flow of the main game loop
\             Ship data blocks
\
\ ------------------------------------------------------------------------------
\
\ In the encyclopedia code, we start the main game loop at part 2 and then jump
\ straight to part 5, as parts 1, 3 and 4 are not required when we are docked.
\
\ This section covers the following:
\
\   * Update the main loop counters
\
\ Other entry points:
\
\   TT100               The entry point for the start of the main game loop,
\                       which calls the main flight loop and the moves into the
\                       spawning routine
\
\   me3                 Used by me2 to jump back into the main game loop after
\                       printing an in-flight message
\
\ ******************************************************************************

.TT100

 DEC DLY                \ Decrement the delay counter in DLY, so any in-flight
                        \ messages get removed once the counter reaches zero

 BEQ me2                \ If DLY is now 0, jump to me2 to remove any in-flight
                        \ message from the space view, and once done, return to
                        \ me3 below, skipping the following two instructions

 BPL me3                \ If DLY is positive, jump to me3 to skip the next
                        \ instruction

 INC DLY                \ If we get here, DLY is negative, so we have gone too
                        \ and need to increment DLY back to 0

.me3

 DEC MCNT               \ Decrement the main loop counter in MCNT

                        \ --- Original Acornsoft code removed: ---------------->

\ BEQ P%+5              \ If the counter has reached zero, which it will do
\                       \ every 256 main loops, skip the next JMP instruction
\                       \ (or to put it another way, if the counter hasn't
\                       \ reached zero, jump down to MLOOP, skipping all the
\                       \ following checks)
\
\.ytq
\
\ JMP MLOOP             \ Jump down to MLOOP to do some end-of-loop tidying and
\                       \ restart the main loop
\
\                       \ We only get here once every 256 iterations of the
\                       \ main loop. If we aren't in witchspace and don't
\                       \ already have 3 or more asteroids in our local bubble,
\                       \ then this section has a 13% chance of spawning
\                       \ something benign (the other 87% of the time we jump
\                       \ down to consider spawning cops, pirates and bounty
\                       \ hunters)
\                       \
\                       \ If we are in that 13%, then 50% of the time this will
\                       \ be a Cobra Mk III trader, and the other 50% of the
\                       \ time it will either be an asteroid (98.5% chance) or,
\                       \ very rarely, a cargo canister (1.5% chance)
\
\ LDA MJ                \ If we are in witchspace following a mis-jump, skip the
\ BNE ytq               \ following by jumping down to MLOOP (via ytq above)
\
\ JSR DORND             \ Set A and X to random numbers
\
\ CMP #35               \ If A >= 35 (87% chance), jump down to MLOOP to skip
\ BCS MLOOP             \ the following
\
\ LDA MANY+AST          \ If we already have 3 or more asteroids in the local
\ CMP #3                \ bubble, jump down to MLOOP to skip the following
\ BCS MLOOP
\
\ JSR ZINF              \ Call ZINF to reset the INWK ship workspace
\
\ LDA #38               \ Set z_hi = 38 (far away)
\ STA INWK+7
\
\ JSR DORND             \ Set A, X and C flag to random numbers
\
\ STA INWK              \ Set x_lo = random
\
\ STX INWK+3            \ Set y_lo = random
\
\ AND #%10000000        \ Set x_sign = bit 7 of x_lo
\ STA INWK+2
\
\ TXA                   \ Set y_sign = bit 7 of y_lo
\ AND #%10000000
\ STA INWK+5
\
\ ROL INWK+1            \ Set bit 2 of x_hi to the C flag, which is random, so
\ ROL INWK+1            \ this randomly moves us slightly off-centre

                        \ --- End of removed code ----------------------------->

                        \ Fall through into part 5 (parts 3 and 4 are not
                        \ required when we are docked)

\ ******************************************************************************
\
\       Name: Main game loop (Part 5 of 6)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Cool down lasers, make calls to update the dashboard
\  Deep dive: Program flow of the main game loop
\             The dashboard indicators
\
\ ------------------------------------------------------------------------------
\
\ This is the first half of the minimal game loop, which we iterate when we are
\ docked. This section covers the following:
\
\   * Cool down lasers
\
\   * Make calls to update the dashboard
\
\ Other entry points:
\
\   MLOOP               The entry point for the main game loop. This entry point
\                       comes after the call to the main flight loop and
\                       spawning routines, so it marks the start of the main
\                       game loop for when we are docked (as we don't need to
\                       call the main flight loop or spawning routines if we
\                       aren't in space)
\
\ ******************************************************************************

.MLOOP

 LDX #&FF               \ Set the stack pointer to &01FF, which is the standard
 TXS                    \ location for the 6502 stack, so this instruction
                        \ effectively resets the stack

                        \ --- Original Acornsoft code removed: ---------------->

\ LDX GNTMP             \ If the laser temperature in GNTMP is non-zero,
\ BEQ EE20              \ decrement it (i.e. cool it down a bit)
\ DEC GNTMP
\
\.EE20
\
\ JSR DIALS             \ Call DIALS to update the dashboard
\
\ LDA QQ11              \ If this is a space view, skip the following two
\ BEQ P%+7              \ instructions (i.e. jump to JSR TT17 below)

                        \ --- End of removed code ----------------------------->

 LDY #2                 \ Wait for 2/50 of a second (0.04 seconds), to slow the
 JSR DELAY              \ main loop down a bit

 JSR TT17               \ Scan the keyboard for the cursor keys or joystick,
                        \ returning the cursor's delta values in X and Y and
                        \ the key pressed in A

\ ******************************************************************************
\
\       Name: Main game loop (Part 6 of 6)
\       Type: Subroutine
\   Category: Main loop
\    Summary: Process non-flight key presses (red function keys, docked keys)
\  Deep dive: Program flow of the main game loop
\
\ ------------------------------------------------------------------------------
\
\ This is the second half of the minimal game loop, which we iterate when we are
\ docked. This section covers the following:
\
\   * Process more key presses (red function keys, docked keys etc.)
\
\ It also support joining the main loop with a key already "pressed", so we can
\ jump into the main game loop to perform a specific action. In practice, this
\ is used when we enter the docking bay in BAY to display Status Mode (red key
\ f8), and when we finish buying or selling cargo in BAY2 to jump to the
\ Inventory (red key f9).
\
\ Other entry points:
\
\   FRCE                The entry point for the main game loop if we want to
\                       jump straight to a specific screen, by pretending to
\                       "press" a key, in which case A contains the internal key
\                       number of the key we want to "press"
\
\ ******************************************************************************

.FRCE

 JSR TT102              \ Call TT102 to process the key pressed in A

 LDA QQ12               \ Fetch the docked flag from QQ12 into A

 BNE MLOOP              \ If we are docked, loop back up to MLOOP just above
                        \ to restart the main loop, but skipping all the flight
                        \ and spawning code in the top part of the main loop

 JMP TT100              \ Otherwise jump to TT100 to restart the main loop from
                        \ the start

\ ******************************************************************************
\
\       Name: TT102
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Process function key, save, hyperspace and chart key presses
\
\ ------------------------------------------------------------------------------
\
\ Process function key presses, plus "@" (save commander), "H" (hyperspace),
\ "D" (show distance to system) and "O" (move chart cursor back to current
\ system). We can also pass cursor position deltas in X and Y to indicate that
\ the cursor keys or joystick have been used (i.e. the values that are returned
\ by routine TT17).
\
\ Arguments:
\
\   A                   The internal key number of the key pressed (see p.142 of
\                       the Advanced User Guide for a list of internal key
\                       numbers)
\
\   X                   The amount to move the crosshairs in the x-axis
\
\   Y                   The amount to move the crosshairs in the y-axis
\
\ Other entry points:
\
\   T95                 Print the distance to the selected system
\
\ ******************************************************************************

.TT102

                        \ --- Original Acornsoft code removed: ---------------->

\ CMP #f8               \ If red key f8 was pressed, jump to STATUS to show the
\ BNE P%+5              \ Status Mode screen, returning from the subroutine
\ JMP STATUS            \ using a tail call
\
\ CMP #f4               \ If red key f4 was pressed, jump to TT22 to show the
\ BNE P%+5              \ Long-range Chart, returning from the subroutine using
\ JMP TT22              \ a tail call
\
\ CMP #f5               \ If red key f5 was pressed, jump to TT23 to show the
\ BNE P%+5              \ Short-range Chart, returning from the subroutine using
\ JMP TT23              \ a tail call
\
\ CMP #f6               \ If red key f6 was pressed, call TT111 to select the
\ BNE TT92              \ system nearest to galactic coordinates (QQ9, QQ10)
\ JSR TT111             \ (the location of the chart crosshairs) and set ZZ to
\ JMP TT25              \ the system number, and then jump to TT25 to show the
\                       \ Data on System screen (along with an extended system
\                       \ description for the system in ZZ if we're docked),
\                       \ returning from the subroutine using a tail call

                        \ --- And replaced by: -------------------------------->

 CMP #f8                \ If red key f8 was pressed, AJD
 BNE P%+5               \ , returning from the subroutine
 JMP info_menu          \ using a tail call

 CMP #f4                \ If red key f4 was pressed, jump to TT22 to show the
 BNE P%+5               \ Long-range Chart, returning from the subroutine using
 JMP TT22               \ a tail call

 CMP #f5                \ If red key f5 was pressed, jump to TT23 to show the
 BNE P%+5               \ Short-range Chart, returning from the subroutine using
 JMP TT23               \ a tail call

 CMP #&75               \ AJD
 BNE TT92
 JSR CTRL
 BPL jump_data
 JMP launch

.jump_data

 JSR TT111
 JMP TT25

                        \ --- End of replacement ------------------------------>

.TT92

                        \ --- Original Acornsoft code removed: ---------------->

\ CMP #f9               \ If red key f9 was pressed, jump to TT213 to show the
\ BNE P%+5              \ Inventory screen, returning from the subroutine
\ JMP TT213             \ using a tail call
\
\ CMP #f7               \ If red key f7 was pressed, jump to TT167 to show the
\ BNE P%+5              \ Market Price screen, returning from the subroutine
\ JMP TT167             \ using a tail call
\
\ CMP #f0               \ If red key f0 was pressed, jump to TT110 to launch our
\ BNE fvw               \ ship (if docked), returning from the subroutine using
\ JMP TT110             \ a tail call

                        \ --- And replaced by: -------------------------------->

 CMP #&77               \ AJD
 BNE not_invnt
 JMP info_menu

.not_invnt

 CMP #&16
 BNE not_price
 JMP info_menu

.not_price

                        \ --- End of replacement ------------------------------>

.fvw

                        \ --- Original Acornsoft code removed: ---------------->

\ CMP #f3               \ If red key f3 was pressed, jump to EQSHP to show the
\ BNE P%+5              \ Equip Ship screen, returning from the subroutine using
\ JMP EQSHP             \ a tail call
\
\ CMP #f1               \ If red key f1 was pressed, jump to TT219 to show the
\ BNE P%+5              \ Buy Cargo screen, returning from the subroutine using
\ JMP TT219             \ a tail call
\
\ CMP #&47              \ If "@" was not pressed, skip to nosave
\ BNE nosave
\
\ JSR SVE               \ "@" was pressed, so call SVE to show the disc access
\                       \ menu
\
\ BCC P%+5              \ If the C flag was set by SVE, then we loaded a new
\ JMP QU5               \ commander file, so jump to QU5 to restart the game
\                       \ with the newly loaded commander
\
\ JMP BAY               \ Otherwise the C flag was clear, so jump to BAY to go
\                       \ to the docking bay (i.e. show the Status Mode screen)
\
\.nosave
\
\ CMP #f2               \ If red key f2 was pressed, jump to TT208 to show the
\ BNE LABEL_3           \ Sell Cargo screen, returning from the subroutine using
\ JMP TT208             \ a tail call
\
\.INSP

                        \ --- And replaced by: -------------------------------->

 CMP #&20               \ AJD
 BEQ jump_menu
 CMP #&71
 BEQ jump_menu
 CMP #&72
 BEQ jump_menu
 CMP #&73
 BNE LABEL_3

.jump_menu

 JMP info_menu

                        \ --- End of replacement ------------------------------>

.LABEL_3

 CMP #&54               \ If "H" was not pressed, jump to NWDAV5 to skip the
 BNE NWDAV5             \ following

 JSR CLYNS              \ "H" was pressed, so clear the bottom three text rows
                        \ of the upper screen, and move the text cursor to
                        \ column 1 on row 21, i.e. the start of the top row of
                        \ the three bottom rows

 LDA #15                \ Move the text cursor to column 15 (the middle of the
 STA XC                 \ screen)

 LDA #205               \ Print extended token 205 ("DOCKED") and return from
 JMP DETOK              \ the subroutine using a tail call

.NWDAV5

 CMP #&32               \ If "D" was pressed, jump to T95 to print the distance
 BEQ T95                \ to a system (if we are in one of the chart screens)

 CMP #&43               \ If "F" was not pressed, jump down to HME1, otherwise
 BNE HME1               \ keep going to process searching for systems

 LDA QQ11               \ If the current view is a chart (QQ11 = 64 or 128),
 AND #%11000000         \ keep going, otherwise return from the subroutine (as
 BEQ t95                \ t95 contains an RTS)

 JMP HME2               \ Jump to HME2 to let us search for a system, returning
                        \ from the subroutine using a tail call

.HME1

 STA T1                 \ Store A (the key that's been pressed) in T1

 LDA QQ11               \ If the current view is a chart (QQ11 = 64 or 128),
 AND #%11000000         \ keep going, otherwise jump down to t95 to return from
 BEQ t95                \ the subroutine

 LDA QQ22+1             \ If the on-screen hyperspace counter is non-zero,
 BNE t95                \ then we are already counting down, so jump down to t95
                        \ to return from the subroutine

 LDA T1                 \ Restore the original value of A (the key that's been
                        \ pressed) from T1

                        \ --- Original Acornsoft code removed: ---------------->

\ CMP #&36              \ If "O" was pressed, do the following three jumps,
\ BNE ee2               \ otherwise skip to ee2 to continue

                        \ --- And replaced by: -------------------------------->

 CMP #&36               \ If "O" was pressed, do the following three jumps,
 BNE not_home           \ otherwise skip to not_home to continue AJD

                        \ --- End of replacement ------------------------------>

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10),
                        \ which will erase the crosshairs currently there

 JSR ping               \ Set the target system to the current system (which
                        \ will move the location in (QQ9, QQ10) to the current
                        \ home system

 JSR TT103              \ Draw small crosshairs at coordinates (QQ9, QQ10),
                        \ which will draw the crosshairs at our current home
                        \ system

.ee2

 JSR TT16               \ Call TT16 to move the crosshairs by the amount in X
                        \ and Y, which were passed to this subroutine as
                        \ arguments

.t95

 RTS                    \ Return from the subroutine

                        \ --- Code added for Elite-A: ------------------------->

.not_home

 CMP #&21               \ AJD
 BNE ee2

 LDA cmdr_cour
 ORA cmdr_cour+1
 BEQ ee2

 JSR TT103              \ AJD
 LDA cmdr_courx
 STA QQ9
 LDA cmdr_coury
 STA QQ10
 JSR TT103

                        \ --- End of added code ------------------------------->

.T95

                        \ If we get here, "D" was pressed, so we need to show
                        \ the distance to the selected system (if we are in a
                        \ chart view)

 LDA QQ11               \ If the current view is a chart (QQ11 = 64 or 128),
 AND #%11000000         \ keep going, otherwise return from the subroutine (as
 BEQ t95                \ t95 contains an RTS)

 JSR hm                 \ Call hm to move the crosshairs to the target system
                        \ in (QQ9, QQ10), returning with A = 0

 STA QQ17               \ Set QQ17 = 0 to switch to ALL CAPS

 JSR cpl                \ Print control code 3 (the selected system name)

 LDA #%10000000         \ Set bit 7 of QQ17 to switch to Sentence Case, with the
 STA QQ17               \ next letter in capitals

 LDA #1                 \ Move the text cursor to column 1 and down one line
 STA XC                 \ (in other words, to the start of the next line)
 INC YC

 JMP TT146              \ Print the distance to the selected system and return
                        \ from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: brkd
\       Type: Variable
\   Category: Utility routines
\    Summary: The brkd counter for error handling
\
\ ------------------------------------------------------------------------------
\
\ This counter starts at zero, and is decremented whenever the BRKV handler at
\ BRBR prints an error message. It is incremented every time an error message
\ is printed out as part of the TITLE routine.
\
\ ******************************************************************************

.brkd

 EQUB 0

\ ******************************************************************************
\
\       Name: BR1
\       Type: Subroutine
\   Category: Start and end
\    Summary: Start or restart the game
\
\ ------------------------------------------------------------------------------
\
\ ******************************************************************************

.BR1

                        \ --- Original Acornsoft code removed: ---------------->

\ LDX #3                \ Set XC = 3 (set text cursor to column 3)
\ STX XC
\
\ JSR FX200             \ Disable the ESCAPE key and clear memory if the BREAK
\                       \ key is pressed (*FX 200,3)
\
\ LDX #CYL              \ Call TITLE to show a rotating Cobra Mk III (#CYL) and
\ LDA #6                \ token 6 ("LOAD NEW {single cap}COMMANDER {all caps}
\ JSR TITLE             \ (Y/N)?{sentence case}{cr}{cr}"), returning with the
\                       \ internal number of the key pressed in A
\
\ CMP #&44              \ Did we press "Y"? If not, jump to QU5, otherwise
\ BNE QU5               \ continue on to load a new commander
\
\ JSR DFAULT            \ Call DFAULT to reset the current commander data block
\                       \ to the last saved commander
\
\ JSR SVE               \ Call SVE to load a new commander into the last saved
\                       \ commander data block
\
\.QU5
\
\ JSR DFAULT            \ Call DFAULT to reset the current commander data block
\                       \ to the last saved commander

                        \ --- And replaced by: -------------------------------->

 JMP escape             \ AJD

                        \ --- End of replacement ------------------------------>

\ ******************************************************************************
\
\       Name: BRBR
\       Type: Subroutine
\   Category: Utility routines
\    Summary: The standard BRKV handler for the game
\
\ ------------------------------------------------------------------------------
\
\ This routine is used to display error messages, before restarting the game.
\ When called, it makes a beep and prints the system error message in the block
\ pointed to by (&FD &FE), which is where the MOS will put any system errors. It
\ then waits for a key press and restarts the game.
\
\ BRKV is set to this routine in the decryption routine at DEEOR just before the
\ game is run for the first time, and at the end of the SVE routine after the
\ disc access menu has been processed. In other words, this is the standard
\ BRKV handler for the game, and it's swapped out to MRBRK for disc access
\ operations only.
\
\ When it is the BRKV handler, the routine can be triggered using a BRK
\ instruction. The main differences between this routine and the MEBRK handler
\ that is used during disc access operations are that this routine restarts the
\ game rather than returning to the disc access menu, and this handler
\ decrements the brkd counter.
\
\ ******************************************************************************

.BRBR

 DEC brkd               \ Decrement the brkd counter

 BNE BR1                \ If the brkd counter is non-zero, jump to BR1 to
                        \ restart the game

\ ******************************************************************************
\
\       Name: DEATH2
\       Type: Subroutine
\   Category: Start and end
\    Summary: Reset most of the game and restart from the title screen
\
\ ------------------------------------------------------------------------------
\
\ This routine is called following death, and when the game is quit by pressing
\ ESCAPE when paused.
\
\ ******************************************************************************

.DEATH2

 JSR RES2               \ Reset a number of flight variables and workspaces
                        \ and fall through into the entry code for the game
                        \ to restart from the title screen

\ ******************************************************************************
\
\       Name: BAY
\       Type: Subroutine
\   Category: Status
\    Summary: Go to the docking bay (i.e. show the Status Mode screen)
\
\ ------------------------------------------------------------------------------
\
\ We end up here after the start-up process (load commander etc.), as well as
\ after a successful save, an escape pod launch, a successful docking, the end
\ of a cargo sell, and various errors (such as not having enough cash, entering
\ too many items when buying, trying to fit an item to your ship when you
\ already have it, running out of cargo space, and so on).
\
\ ******************************************************************************

.BAY

 LDA #&FF               \ Set QQ12 = &FF (the docked flag) to indicate that we
 STA QQ12               \ are docked

                        \ --- Original Acornsoft code removed: ---------------->

\ LDA #f8               \ Jump into the main loop at FRCE, setting the key
\ JMP FRCE              \ that's "pressed" to red key f8 (so we show the Status
\                       \ Mode screen)

                        \ --- And replaced by: -------------------------------->

 LDA #f3                \ AJD
 JMP FRCE

                        \ --- End of replacement ------------------------------>

\ ******************************************************************************
\
\       Name: MT26
\       Type: Subroutine
\   Category: Text
\    Summary: Fetch a line of text from the keyboard
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ If ESCAPE is pressed or a blank name is entered, then an empty string is
\ returned.
\
\ Returns:
\
\   Y                   The size of the entered text, or 0 if none was entered
\                       or if ESCAPE was pressed
\
\   INWK+5              The entered text, terminated by a carriage return
\
\   C flag              Set if ESCAPE was pressed
\
\ ******************************************************************************

.MT26

 LDA #%10000001         \ Clear 6522 System VIA interrupt enable register IER
 STA VIA+&4E            \ (SHEILA &4E) bit 1 (i.e. enable the CA2 interrupt,
                        \ which comes from the keyboard)

 JSR FLKB               \ Call FLKB to flush the keyboard buffer

 LDX #LO(RLINE)         \ Set (Y X) to point to the RLINE parameter block
 LDY #HI(RLINE)

 LDA #0                 \ Call OSWORD with A = 0 to read a line from the current
 JSR OSWORD             \ input stream (i.e. the keyboard)

 BCC P%+4               \ The C flag will be set if we pressed ESCAPE when
                        \ entering the name, otherwise it will be clear, so
                        \ skip the next instruction if ESCAPE is not pressed

 LDY #0                 \ ESCAPE was pressed, so set Y = 0 (as the OSWORD call
                        \ returns the length of the entered string in Y)

 LDA #%00000001         \ Set 6522 System VIA interrupt enable register IER
 STA VIA+&4E            \ (SHEILA &4E) bit 1 (i.e. disable the CA2 interrupt,
                        \ which comes from the keyboard)

 JMP FEED               \ Jump to FEED to print a newline, returning from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: RLINE
\       Type: Variable
\   Category: Text
\    Summary: The OSWORD configuration block used to fetch a line of text from
\             the keyboard
\
\ ******************************************************************************

.RLINE

 EQUW INWK+5            \ The address to store the input, so the text entered
                        \ will be stored in INWK+5 as it is typed

 EQUB 9                 \ Maximum line length = 9, as that's the maximum size
                        \ for a commander's name including a directory name

 EQUB '!'               \ Allow ASCII characters from "!" through to "{" in
 EQUB '{'               \ the input

\ ******************************************************************************
\
\       Name: ZERO
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Zero-fill pages &9, &A, &B, &C and &D
\
\ ------------------------------------------------------------------------------
\
\ This resets the following workspaces to zero:
\
\   * The ship data blocks ascending from K% at &0900
\
\   * The ship line heap descending from WP at &0D40
\
\   * WP workspace variables from FRIN to de, which include the ship slots for
\     the local bubble of universe, and various flight and ship status variables
\     (only a portion of the LSX/LSO sun line heap is cleared)
\
\ ******************************************************************************

.ZERO

 LDX #(de-FRIN)         \ We're going to zero the UP workspace variables from
                        \ FRIN to de, so set a counter in X for the correct
                        \ number of bytes

 LDA #0                 \ Set A = 0 so we can zero the variables

.ZEL2

 STA FRIN,X             \ Zero the X-th byte of FRIN to de

 DEX                    \ Decrement the loop counter

 BPL ZEL2               \ Loop back to zero the next variable until we have done
                        \ them all

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ZES1
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Zero-fill the page whose number is in X
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The page we want to zero-fill
\
\ ******************************************************************************

.ZES1

 LDY #0                 \ If we set Y = SC = 0 and fall through into ZES2
 STY SC                 \ below, then we will zero-fill 255 bytes starting from
                        \ SC - in other words, we will zero-fill the whole of
                        \ page X

\ ******************************************************************************
\
\       Name: ZES2
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Zero-fill a specific page
\
\ ------------------------------------------------------------------------------
\
\ Zero-fill from address (X SC) + Y to (X SC) + &FF.
\
\ Arguments:
\
\   Y                   The offset from (X SC) where we start zeroing, counting
\                       up to to &FF
\
\   SC                  The low byte (i.e. the offset into the page) of the
\                       starting point of the zero-fill
\
\ Returns:
\
\   Z flag              Z flag is set
\
\ ******************************************************************************

.ZES2

 LDA #0                 \ Load A with the byte we want to fill the memory block
                        \ with - i.e. zero

 STX SC+1               \ We want to zero-fill page X, so store this in the
                        \ high byte of SC, so the 16-bit address in SC and
                        \ SC+1 is now pointing to the SC-th byte of page X

.ZEL1

 STA (SC),Y             \ Zero the Y-th byte of the block pointed to by SC,
                        \ so that's effectively the Y-th byte before SC

 INY                    \ Increment the loop counter

 BNE ZEL1               \ Loop back to zero the next byte

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: NORM
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Normalise the three-coordinate vector in XX15
\  Deep dive: Tidying orthonormal vectors
\             Orientation vectors
\
\ ------------------------------------------------------------------------------
\
\ We do this by dividing each of the three coordinates by the length of the
\ vector, which we can calculate using Pythagoras. Once normalised, 96 (&E0) is
\ used to represent a value of 1, and 96 with bit 7 set (&E0) is used to
\ represent -1. This enables us to represent fractional values of less than 1
\ using integers.
\
\ Arguments:
\
\   XX15                The vector to normalise, with:
\
\                         * The x-coordinate in XX15
\
\                         * The y-coordinate in XX15+1
\
\                         * The z-coordinate in XX15+2
\
\ Returns:
\
\   XX15                The normalised vector
\
\   Q                   The length of the original XX15 vector
\
\ Other entry points:
\
\   NO1                 Contains an RTS
\
\ ******************************************************************************

.NORM

 LDA XX15               \ Fetch the x-coordinate into A

 JSR SQUA               \ Set (A P) = A * A = x^2

 STA R                  \ Set (R Q) = (A P) = x^2
 LDA P
 STA Q

 LDA XX15+1             \ Fetch the y-coordinate into A

 JSR SQUA               \ Set (A P) = A * A = y^2

 STA T                  \ Set (T P) = (A P) = y^2

 LDA P                  \ Set (R Q) = (R Q) + (T P) = x^2 + y^2
 ADC Q                  \
 STA Q                  \ First, doing the low bytes, Q = Q + P

 LDA T                  \ And then the high bytes, R = R + T
 ADC R
 STA R

 LDA XX15+2             \ Fetch the z-coordinate into A

 JSR SQUA               \ Set (A P) = A * A = z^2

 STA T                  \ Set (T P) = (A P) = z^2

 LDA P                  \ Set (R Q) = (R Q) + (T P) = x^2 + y^2 + z^2
 ADC Q                  \
 STA Q                  \ First, doing the low bytes, Q = Q + P

 LDA T                  \ And then the high bytes, R = R + T
 ADC R
 STA R

 JSR LL5                \ We now have the following:
                        \
                        \ (R Q) = x^2 + y^2 + z^2
                        \
                        \ so we can call LL5 to use Pythagoras to get:
                        \
                        \ Q = SQRT(R Q)
                        \   = SQRT(x^2 + y^2 + z^2)
                        \
                        \ So Q now contains the length of the vector (x, y, z),
                        \ and we can normalise the vector by dividing each of
                        \ the coordinates by this value, which we do by calling
                        \ routine TIS2. TIS2 returns the divided figure, using
                        \ 96 to represent 1 and 96 with bit 7 set for -1

 LDA XX15               \ Call TIS2 to divide the x-coordinate in XX15 by Q,
 JSR TIS2               \ with 1 being represented by 96
 STA XX15

 LDA XX15+1             \ Call TIS2 to divide the y-coordinate in XX15+1 by Q,
 JSR TIS2               \ with 1 being represented by 96
 STA XX15+1

 LDA XX15+2             \ Call TIS2 to divide the z-coordinate in XX15+2 by Q,
 JSR TIS2               \ with 1 being represented by 96
 STA XX15+2

.NO1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: RDKEY
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan the keyboard for key presses
\
\ ------------------------------------------------------------------------------
\
\ Scan the keyboard, starting with internal key number 16 ("Q") and working
\ through the set of internal key numbers (see p.142 of the Advanced User Guide
\ for a list of internal key numbers).
\
\ This routine is effectively the same as OSBYTE 122, though the OSBYTE call
\ preserves A, unlike this routine.
\
\ Returns:
\
\   X                   If a key is being pressed, X contains the internal key
\                       number, otherwise it contains 0
\
\   A                   Contains the same as X
\
\ ******************************************************************************

.RDKEY

 LDX #16                \ Start the scan with internal key number 16 ("Q")

.Rd1

 JSR DKS4               \ Scan the keyboard to see if the key in X is currently
                        \ being pressed, returning the result in A and X

 BMI Rd2                \ Jump to Rd2 if this key is being pressed (in which
                        \ case DKS4 will have returned the key number with bit
                        \ 7 set, which is negative)

 INX                    \ Increment the key number, which was unchanged by the
                        \ above call to DKS4

 BPL Rd1                \ Loop back to test the next key, ending the loop when
                        \ X is negative (i.e. 128)

 TXA                    \ If we get here, nothing is being pressed, so copy X
                        \ into A so that X = A = 128 = %10000000

.Rd2

 EOR #%10000000         \ EOR A with #%10000000 to flip bit 7, so A now contains
                        \ 0 if no key has been pressed, or the internal key
                        \ number if a key has been pressed

 TAX                    \ Copy A into X

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ECMOF
\       Type: Subroutine
\   Category: Sound
\    Summary: Switch off the E.C.M.
\
\ ------------------------------------------------------------------------------
\
\ Switch the E.C.M. off, turn off the dashboard bulb and make the sound of the
\ E.C.M. switching off).
\
\ ******************************************************************************

.ECMOF

 LDA #0                 \ Set ECMA and ECMB to 0 to indicate that no E.C.M. is
 STA ECMA               \ currently running
 STA ECMP

 LDA #72                \ Call the NOISE routine with A = 72 to make the sound
 BNE NOISE              \ of the E.C.M. being turned off and return from the
                        \ subroutine using a tail call (this BNE is effectively
                        \ a JMP as A will never be zero)

\ ******************************************************************************
\
\       Name: BEEP
\       Type: Subroutine
\   Category: Sound
\    Summary: Make a short, high beep
\
\ ******************************************************************************

.BEEP

                        \ --- Original Acornsoft code removed: ---------------->

\ LDA #32               \ Call the NOISE routine with A = 32 to make a short,
\ BNE NOISE             \ high beep, returning from the subroutine using a tail
\                       \ call (this BNE is effectively a JMP as A will never be
\                       \ zero)

                        \ --- And replaced by: -------------------------------->

 LDA #32                \ Set A = 32 to denote a short, high beep, and fall
                        \ through into the NOISE routine to make the sound

                        \ --- End of replacement ------------------------------>

\ ******************************************************************************
\
\       Name: NOISE
\       Type: Subroutine
\   Category: Sound
\    Summary: Make the sound whose number is in A
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The number of the sound to be made. See the
\                       documentation for variable SFX for a list of sound
\                       numbers
\
\ ******************************************************************************

.NOISE

 JSR NOS1               \ Set up the sound block in XX16 for the sound in A and
                        \ fall through into NO3 to make the sound

\ ******************************************************************************
\
\       Name: NO3
\       Type: Subroutine
\   Category: Sound
\    Summary: Make a sound from a prepared sound block
\
\ ------------------------------------------------------------------------------
\
\ Make a sound from a prepared sound block in XX16 (if sound is enabled). See
\ routine NOS1 for details of preparing the XX16 sound block.
\
\ ******************************************************************************

.NO3

 LDX DNOIZ              \ Set X to the DNOIZ configuration setting

 BNE NO1                \ If DNOIZ is non-zero, then sound is disabled, so
                        \ return from the subroutine (as NO1 contains an RTS)

 LDX #LO(XX16)          \ Otherwise set (Y X) to point to the sound block in
 LDY #HI(XX16)          \ XX16

 LDA #7                 \ Call OSWORD 7 to makes the sound, as described in the
 JMP OSWORD             \ documentation for variable SFX, and return from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: NOS1
\       Type: Subroutine
\   Category: Sound
\    Summary: Prepare a sound block
\
\ ------------------------------------------------------------------------------
\
\ Copy four sound bytes from SFX into XX16, interspersing them with null bytes,
\ with Y indicating the sound number to copy (from the values in the sound
\ table at SFX). So, for example, if we call this routine with A = 40 (long,
\ low beep), the following bytes will be set in XX16 to XX16+7:
\
\   &13 &00 &F4 &00 &0C &00 &08 &00
\
\ This block will be passed to OSWORD 7 to make the sound, which expects the
\ four sound attributes as 16-bit big-endian values - in other words, with the
\ low byte first. So the above block would pass the values &0013, &00F4, &000C
\ and &0008 to the SOUND statement when used with OSWORD 7, or:
\
\   SOUND &13, &F4, &0C, &08
\
\ as the high bytes are always zero.
\
\ Arguments:
\
\   A                   The sound number to copy from SFX to XX16, which is
\                       always a multiple of 8
\
\ ******************************************************************************

.NOS1

 LSR A                  \ Divide A by 2, and also clear the C flag, as bit 0 of
                        \ A is always zero (as A is a multiple of 8)

 ADC #3                 \ Set Y = A + 3, so Y now points to the last byte of
 TAY                    \ four within the block of four-byte values

 LDX #7                 \ We want to copy four bytes, spread out into an 8-byte
                        \ block, so set a counter in Y to cover 8 bytes

.NOL1

 LDA #0                 \ Set the X-th byte of XX16 to 0
 STA XX16,X

 DEX                    \ Decrement the destination byte pointer

 LDA SFX,Y              \ Set the X-th byte of XX16 to the value from SFX+Y
 STA XX16,X

 DEY                    \ Decrement the source byte pointer again

 DEX                    \ Decrement the destination byte pointer again

 BPL NOL1               \ Loop back for the next source byte

                        \ Fall through into KYTB to return from the subroutine,
                        \ as the first byte of KYTB is an RTS

\ ******************************************************************************
\
\       Name: CTRL
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan the keyboard to see if CTRL is currently pressed
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   X                   X = %10000001 (i.e. 129 or -127) if CTRL is being
\                       pressed
\
\                       X = 1 if CTRL is not being pressed
\
\   A                   Contains the same as X
\
\ ******************************************************************************

.CTRL

 LDX #1                 \ Set X to the internal key number for CTRL and fall
                        \ through to DKS4 to scan the keyboard

\ ******************************************************************************
\
\       Name: DKS4
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan the keyboard to see if a specific key is being pressed
\  Deep dive: The key logger
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The internal number of the key to check (see p.142 of
\                       the Advanced User Guide for a list of internal key
\                       numbers)
\
\ Returns:
\
\   A                   If the key in A is being pressed, A contains the
\                       original argument A, but with bit 7 set (i.e. A + 128).
\                       If the key in A is not being pressed, the value in A is
\                       unchanged
\
\   X                   Contains the same as A
\
\ Other entry points:
\
\   DKS2-1              Contains an RTS
\
\ ******************************************************************************

.DKS4

 LDA #%00000011         \ Set A to %00000011, so it's ready to send to SHEILA
                        \ once interrupts have been disabled

 SEI                    \ Disable interrupts so we can scan the keyboard
                        \ without being hijacked

 STA VIA+&40            \ Set 6522 System VIA output register ORB (SHEILA &40)
                        \ to %00000011 to stop auto scan of keyboard

 LDA #%01111111         \ Set 6522 System VIA data direction register DDRA
 STA VIA+&43            \ (SHEILA &43) to %01111111. This sets the A registers
                        \ (IRA and ORA) so that:
                        \
                        \   * Bits 0-6 of ORA will be sent to the keyboard
                        \
                        \   * Bit 7 of IRA will be read from the keyboard

 STX VIA+&4F            \ Set 6522 System VIA output register ORA (SHEILA &4F)
                        \ to X, the key we want to scan for; bits 0-6 will be
                        \ sent to the keyboard, of which bits 0-3 determine the
                        \ keyboard column, and bits 4-6 the keyboard row

 LDX VIA+&4F            \ Read 6522 System VIA output register IRA (SHEILA &4F)
                        \ into X; bit 7 is the only bit that will have changed.
                        \ If the key is pressed, then bit 7 will be set,
                        \ otherwise it will be clear

 LDA #%00001011         \ Set 6522 System VIA output register ORB (SHEILA &40)
 STA VIA+&40            \ to %00001011 to restart auto scan of keyboard

 CLI                    \ Allow interrupts again

 TXA                    \ Transfer X into A

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DKS2
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Read the joystick position
\
\ ------------------------------------------------------------------------------
\
\ Return the value of ADC channel in X (used to read the joystick). The value
\ will be inverted if the game has been configured to reverse both joystick
\ channels (which can be done by pausing the game and pressing J).
\
\ Arguments:
\
\   X                   The ADC channel to read:
\
\                         * 1 = joystick X
\
\                         * 2 = joystick Y
\
\ Returns:
\
\   (A X)               The 16-bit value read from channel X, with the value
\                       inverted if the game has been configured to reverse the
\                       joystick
\
\ ******************************************************************************

.DKS2

 LDA #128               \ Call OSBYTE 128 to fetch the 16-bit value from ADC
 JSR OSBYTE             \ channel X, returning (Y X), i.e. the high byte in Y
                        \ and the low byte in X

 TYA                    \ Copy Y to A, so the result is now in (A X)

 EOR JSTE               \ The high byte A is now EOR'd with the value in
                        \ location JSTE, which contains &FF if both joystick
                        \ channels are reversed and 0 otherwise (so A now
                        \ contains the high byte but inverted, if that's what
                        \ the current settings say)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DKS3
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Toggle a configuration setting and emit a beep
\
\ ------------------------------------------------------------------------------
\
\ This is called when the game is paused and a key is pressed that changes the
\ game's configuration.
\
\ Specifically, this routine toggles the configuration settings for the
\ following keys:
\
\   * CAPS LOCK toggles keyboard flight damping (&40)
\   * A toggles keyboard auto-recentre (&41)
\   * X toggles author names on start-up screen (&42)
\   * F toggles flashing console bars (&43)
\   * Y toggles reverse joystick Y channel (&44)
\   * J toggles reverse both joystick channels (&45)
\   * K toggles keyboard and joystick (&46)
\
\ The numbers in brackets are the internal key numbers (see p.142 of the
\ Advanced User Guide for a list of internal key numbers). We pass the key that
\ has been pressed in X, and the configuration option to check it against in Y,
\ so this routine is typically called in a loop that loops through the various
\ configuration options.
\
\ Arguments:
\
\   X                   The internal number of the key that's been pressed
\
\   Y                   The internal number of the configuration key to check
\                       against, from the list above (i.e. Y must be from &40 to
\                       &46)
\
\ ******************************************************************************

.DKS3

 STY T                  \ Store the configuration key argument in T

 CPX T                  \ If X <> Y, jump to Dk3 to return from the subroutine
 BNE Dk3

                        \ We have a match between X and Y, so now to toggle
                        \ the relevant configuration byte. CAPS LOCK has a key
                        \ value of &40 and has its configuration byte at
                        \ location DAMP, A has a value of &41 and has its byte
                        \ at location DJD, which is DAMP+1, and so on. So we
                        \ can toggle the configuration byte by changing the
                        \ byte at DAMP + (X - &40), or to put it in indexing
                        \ terms, DAMP-&40,X. It's no coincidence that the
                        \ game's configuration bytes are set up in this order
                        \ and with these keys (and this is also why the sound
                        \ on/off keys are dealt with elsewhere, as the internal
                        \ key for S and Q are &51 and &10, which don't fit
                        \ nicely into this approach)

 LDA DAMP-&40,X         \ Fetch the byte from DAMP + (X - &40), invert it and
 EOR #&FF               \ put it back (0 means no and &FF means yes in the
 STA DAMP-&40,X         \ configuration bytes, so this toggles the setting)

 JSR BELL               \ Make a beep sound so we know something has happened

 JSR DELAY              \ Wait for Y vertical syncs (Y is between 64 and 70, so
                        \ this is always a bit longer than a second)

 LDY T                  \ Restore the configuration key argument into Y

.Dk3

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: DOKEY
\       Type: Subroutine
\   Category: Keyboard
\
\ ******************************************************************************

.DOKEY

                        \ --- Original Acornsoft code removed: ---------------->

\ LDA JSTK              \ If JSTK is zero, then we are configured to use the
\ BEQ DK9               \ keyboard rather than the joystick, so jump to DK9 to
\                       \ make sure the Bitstik is disabled as well (DK9 then
\                       \ jumps to DK4 below)

                        \ --- And replaced by: -------------------------------->

 LDA JSTK               \ If JSTK is zero, then we are configured to use the
 BEQ DK4                \ keyboard rather than the joystick, so jump to DK4

                        \ --- End of replacement ------------------------------>

 LDX #1                 \ Call DKS2 to fetch the value of ADC channel 1 (the
 JSR DKS2               \ joystick X value) into (A X), and OR A with 1. This
 ORA #1                 \ ensures that the high byte is at least 1, and then we
 STA JSTX               \ store the result in JSTX

 LDX #2                 \ Call DKS2 to fetch the value of ADC channel 2 (the
 JSR DKS2               \ joystick Y value) into (A X), and EOR A with JSTGY.
 EOR JSTGY              \ JSTGY will be &FF if the game is configured to
 STA JSTY               \ reverse the joystick Y channel, so this EOR does
                        \ exactly that, and then we store the result in JSTY

                        \ Fall through into DK4 to scan for other keys

\ ******************************************************************************
\
\       Name: DK4
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan for pause, configuration and secondary flight keys
\  Deep dive: The key logger
\
\ ------------------------------------------------------------------------------
\
\ Scan for pause and configuration keys, and if this is a space view, also scan
\ for secondary flight controls.
\
\ Specifically:
\
\   * Scan for the pause button (COPY) and if it's pressed, pause the game and
\     process any configuration key presses until the game is unpaused (DELETE)
\
\   * If this is a space view, scan for secondary flight keys and update the
\     relevant bytes in the key logger
\
\ ******************************************************************************

.DK4

 JSR RDKEY              \ Scan the keyboard for a key press and return the
                        \ internal key number in X (or 0 for no key press)

 STX KL                 \ Store X in KL, byte #0 of the key logger

 CPX #&69               \ If COPY is not being pressed, jump to DK2 below,
 BNE DK2                \ otherwise let's process the configuration keys

.FREEZE

                        \ COPY is being pressed, so we enter a loop that
                        \ listens for configuration keys, and we keep looping
                        \ until we detect a DELETE key press. This effectively
                        \ pauses the game when COPY is pressed, and unpauses
                        \ it when DELETE is pressed

 JSR WSCAN              \ Call WSCAN to wait for the vertical sync, so the whole
                        \ screen gets drawn

 JSR RDKEY              \ Scan the keyboard for a key press and return the
                        \ internal key number in X (or 0 for no key press)

 CPX #&51               \ If "S" is not being pressed, skip to DK6
 BNE DK6

 LDA #0                 \ "S" is being pressed, so set DNOIZ to 0 to turn the
 STA DNOIZ              \ sound on

.DK6

 LDY #&40               \ We now want to loop through the keys that toggle
                        \ various settings. These have internal key numbers
                        \ between &40 (CAPS LOCK) and &46 ("K"), so we set up
                        \ the first key number in Y to act as a loop counter.
                        \ See subroutine DKS3 for more details on this

.DKL4

 JSR DKS3               \ Call DKS3 to scan for the key given in Y, and toggle
                        \ the relevant setting if it is pressed

 INY                    \ Increment Y to point to the next toggle key

                        \ --- Original Acornsoft code removed: ---------------->

\ CPY #&47              \ The last toggle key is &46 (K), so check whether we
\                       \ have just done that one

                        \ --- And replaced by: -------------------------------->

 CPY #&48               \ AJD

                        \ --- End of replacement ------------------------------>

 BNE DKL4               \ If not, loop back to check for the next toggle key

.DK55

 CPX #&10               \ If "Q" is not being pressed, skip to DK7
 BNE DK7

 STX DNOIZ              \ "Q" is being pressed, so set DNOIZ to X, which is
                        \ non-zero (&10), so this will turn the sound off

.DK7

 CPX #&70               \ If ESCAPE is not being pressed, skip over the next
 BNE P%+5               \ instruction

                        \ --- Original Acornsoft code removed: ---------------->

\ JMP BR1               \ ESCAPE is being pressed, so jump to BR1 to end the
\                       \ game
\
\ CPX #&64              \ If "B" is not being pressed, skip to DK7
\ BNE nobit
\
\ LDA BSTK              \ Toggle the value of BSTK between 0 and &FF
\ EOR #&FF
\ STA BSTK
\
\ STA JSTK              \ Configure JSTK to the same value, so when the Bitstik
\                       \ is enabled, so is the joystick
\
\ STA JSTE              \ Configure JSTE to the same value, so when the Bitstik
\                       \ is enabled, the joystick is configured with reversed
\                       \ channels
\
\.nobit

                        \ --- And replaced by: -------------------------------->

 JMP escape             \ AJD

                        \ --- End of replacement ------------------------------>

 CPX #&59               \ If DELETE is not being pressed, we are still paused,
 BNE FREEZE             \ so loop back up to keep listening for configuration
                        \ keys, otherwise fall through into the rest of the
                        \ key detection code, which unpauses the game

.DK2

 LDA QQ11               \ If the current view is non-zero (i.e. not a space
 BNE out                \ view), return from the subroutine (as out contains
                        \ an RTS)

 LDY #16                \ This is a space view, so now we want to check for all
                        \ the secondary flight keys. The internal key numbers
                        \ are in the keyboard table KYTB from KYTB+8 to
                        \ KYTB+16, and their key logger locations are from KL+8
                        \ to KL+16. So set a decreasing counter in Y for the
                        \ index, starting at 16, so we can loop through them

 LDA #&FF               \ Set A to &FF so we can store this in the keyboard
                        \ logger for keys that are being pressed

                        \ --- Original Acornsoft code removed: ---------------->

\.DK5

                        \ --- End of removed code ----------------------------->

 RTS                    \ Return from the subroutine

                        \ --- Original Acornsoft code removed: ---------------->

\.DK9
\
\ STA BSTK              \ DK9 is called from DOKEY using a BEQ, so we know A is
\                       \ 0, so this disables the Bitstik and switched to
\                       \ keyboard or joystick
\
\ BEQ DK4               \ Jump back to DK4 in DOKEY (this BEQ is effectively a
\                       \ JMP as A is always zero)

                        \ --- End of removed code ----------------------------->

\ ******************************************************************************
\
\       Name: TT217
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Scan the keyboard until a key is pressed
\
\ ------------------------------------------------------------------------------
\
\ Scan the keyboard until a key is pressed, and return the key's ASCII code.
\ If, on entry, a key is already being held down, then wait until that key is
\ released first (so this routine detects the first key down event following
\ the subroutine call).
\
\ Returns:
\
\   X                   The ASCII code of the key that was pressed
\
\   A                   Contains the same as X
\
\   Y                   Y is preserved
\
\ Other entry points:
\
\   out                 Contains an RTS
\
\ ******************************************************************************

.TT217

 STY YSAV               \ Store Y in temporary storage, so we can restore it
                        \ later

.t

 LDY #2                 \ Delay for 2 vertical syncs (2/50 = 0.04 seconds) so we
 JSR DELAY              \ don't take up too much CPU time while looping round

 JSR RDKEY              \ Scan the keyboard for a key press and return the
                        \ internal key number in X (or 0 for no key press)

 BNE t                  \ If a key was already being held down when we entered
                        \ this routine, keep looping back up to t, until the
                        \ key is released

.t2

 JSR RDKEY              \ Any pre-existing key press is now gone, so we can
                        \ start scanning the keyboard again, returning the
                        \ internal key number in X (or 0 for no key press)

 BEQ t2                 \ Keep looping up to t2 until a key is pressed

 TAY                    \ Copy A to Y, so Y contains the internal key number
                        \ of the key pressed

 LDA (TRTB%),Y          \ The address in TRTB% points to the MOS key
                        \ translation table, which is used to translate
                        \ internal key numbers to ASCII, so this fetches the
                        \ key's ASCII code into A

 LDY YSAV               \ Restore the original value of Y we stored above

 TAX                    \ Copy A into X

.out

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: me1
\       Type: Subroutine
\   Category: Text
\    Summary: Erase an old in-flight message and display a new one
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The text token to be printed
\
\   X                   Must be set to 0
\
\ ******************************************************************************

.me1

 STX DLY                \ Set the message delay in DLY to 0, so any new
                        \ in-flight messages will be shown instantly

 PHA                    \ Store the new message token we want to print

 LDA MCH                \ Set A to the token number of the message that is
 JSR mes9               \ currently on-screen, and call mes9 to print it (which
                        \ will remove it from the screen, as printing is done
                        \ using EOR logic)

 PLA                    \ Restore the new message token

\ ******************************************************************************
\
\       Name: MESS
\       Type: Subroutine
\   Category: Text
\    Summary: Display an in-flight message
\
\ ------------------------------------------------------------------------------
\
\ Display an in-flight message in capitals at the bottom of the space view,
\ erasing any existing in-flight message first.
\
\ Arguments:
\
\   A                   The text token to be printed
\
\ ******************************************************************************

.MESS

 LDX #0                 \ Set QQ17 = 0 to switch to ALL CAPS
 STX QQ17

 LDY #9                 \ Move the text cursor to column 9, row 22, at the
 STY XC                 \ bottom middle of the screen, and set Y = 22
 LDY #22
 STY YC

 CPX DLY                \ If the message delay in DLY is not zero, jump up to
 BNE me1                \ me1 to erase the current message first (whose token
                        \ number will be in MCH)

 STY DLY                \ Set the message delay in DLY to 22

 STA MCH                \ Set MCH to the token we are about to display

                        \ Fall through into mes9 to print the token in A

\ ******************************************************************************
\
\       Name: mes9
\       Type: Subroutine
\   Category: Text
\    Summary: Print a text token, possibly followed by " DESTROYED"
\
\ ------------------------------------------------------------------------------
\
\ Print a text token, followed by " DESTROYED" if the destruction flag is set
\ (for when a piece of equipment is destroyed).
\
\ ******************************************************************************

.mes9

 JSR TT27               \ Call TT27 to print the text token in A

 LSR de                 \ If bits 1-7 of variable de are clear, return from the
 BEQ out                \ subroutine (as out contains an RTS). This means that
                        \ " DESTROYED" is never shown, even if bit 0 of de is
                        \ set, which makes sense as we are docked

 LDA #253               \ Print recursive token 93 (" DESTROYED") and return
 JMP TT27               \ from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: TIDY
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Orthonormalise the orientation vectors for a ship
\  Deep dive: Tidying orthonormal vectors
\             Orientation vectors
\
\ ------------------------------------------------------------------------------
\
\ This routine orthonormalises the orientation vectors for a ship. This means
\ making the three orientation vectors orthogonal (perpendicular to each other),
\ and normal (so each of the vectors has length 1).
\
\ We do this because we use the small angle approximation to rotate these
\ vectors in space. It is not completely accurate, so the three vectors tend
\ to get stretched over time, so periodically we tidy the vectors with this
\ routine to ensure they remain as orthonormal as possible.
\
\ ******************************************************************************

.TI2

                        \ Called from below with A = 0, X = 0, Y = 4 when
                        \ nosev_x and nosev_y are small, so we assume that
                        \ nosev_z is big

 TYA                    \ A = Y = 4
 LDY #2
 JSR TIS3               \ Call TIS3 with X = 0, Y = 2, A = 4, to set roofv_z =
 STA INWK+20            \ -(nosev_x * roofv_x + nosev_y * roofv_y) / nosev_z

 JMP TI3                \ Jump to TI3 to keep tidying

.TI1

                        \ Called from below with A = 0, Y = 4 when nosev_x is
                        \ small

 TAX                    \ Set X = A = 0

 LDA XX15+1             \ Set A = nosev_y, and if the top two magnitude bits
 AND #%01100000         \ are both clear, jump to TI2 with A = 0, X = 0, Y = 4
 BEQ TI2

 LDA #2                 \ Otherwise nosev_y is big, so set up the index values
                        \ to pass to TIS3

 JSR TIS3               \ Call TIS3 with X = 0, Y = 4, A = 2, to set roofv_y =
 STA INWK+18            \ -(nosev_x * roofv_x + nosev_z * roofv_z) / nosev_y

 JMP TI3                \ Jump to TI3 to keep tidying

.TIDY

 LDA INWK+10            \ Set (XX15, XX15+1, XX15+2) = nosev
 STA XX15
 LDA INWK+12
 STA XX15+1
 LDA INWK+14
 STA XX15+2

 JSR NORM               \ Call NORM to normalise the vector in XX15, i.e. nosev

 LDA XX15               \ Set nosev = (XX15, XX15+1, XX15+2)
 STA INWK+10
 LDA XX15+1
 STA INWK+12
 LDA XX15+2
 STA INWK+14

 LDY #4                 \ Set Y = 4

 LDA XX15               \ Set A = nosev_x, and if the top two magnitude bits
 AND #%01100000         \ are both clear, jump to TI1 with A = 0, Y = 4
 BEQ TI1

 LDX #2                 \ Otherwise nosev_x is big, so set up the index values
 LDA #0                 \ to pass to TIS3

 JSR TIS3               \ Call TIS3 with X = 2, Y = 4, A = 0, to set roofv_x =
 STA INWK+16            \ -(nosev_y * roofv_y + nosev_z * roofv_z) / nosev_x

.TI3

 LDA INWK+16            \ Set (XX15, XX15+1, XX15+2) = roofv
 STA XX15
 LDA INWK+18
 STA XX15+1
 LDA INWK+20
 STA XX15+2

 JSR NORM               \ Call NORM to normalise the vector in XX15, i.e. roofv

 LDA XX15               \ Set roofv = (XX15, XX15+1, XX15+2)
 STA INWK+16
 LDA XX15+1
 STA INWK+18
 LDA XX15+2
 STA INWK+20

 LDA INWK+12            \ Set Q = nosev_y
 STA Q

 LDA INWK+20            \ Set A = roofv_z

 JSR MULT12             \ Set (S R) = Q * A = nosev_y * roofv_z

 LDX INWK+14            \ Set X = nosev_z

 LDA INWK+18            \ Set A = roofv_y

 JSR TIS1               \ Set (A ?) = (-X * A + (S R)) / 96
                        \        = (-nosev_z * roofv_y + nosev_y * roofv_z) / 96
                        \
                        \ This also sets Q = nosev_z

 EOR #%10000000         \ Set sidev_x = -A
 STA INWK+22            \        = (nosev_z * roofv_y - nosev_y * roofv_z) / 96

 LDA INWK+16            \ Set A = roofv_x

 JSR MULT12             \ Set (S R) = Q * A = nosev_z * roofv_x

 LDX INWK+10            \ Set X = nosev_x

 LDA INWK+20            \ Set A = roofv_z

 JSR TIS1               \ Set (A ?) = (-X * A + (S R)) / 96
                        \        = (-nosev_x * roofv_z + nosev_z * roofv_x) / 96
                        \
                        \ This also sets Q = nosev_x

 EOR #%10000000         \ Set sidev_y = -A
 STA INWK+24            \        = (nosev_x * roofv_z - nosev_z * roofv_x) / 96

 LDA INWK+18            \ Set A = roofv_y

 JSR MULT12             \ Set (S R) = Q * A = nosev_x * roofv_y

 LDX INWK+12            \ Set X = nosev_y

 LDA INWK+16            \ Set A = roofv_x

 JSR TIS1               \ Set (A ?) = (-X * A + (S R)) / 96
                        \        = (-nosev_y * roofv_x + nosev_x * roofv_y) / 96

 EOR #%10000000         \ Set sidev_z = -A
 STA INWK+26            \        = (nosev_y * roofv_x - nosev_x * roofv_y) / 96

 LDA #0                 \ Set A = 0 so we can clear the low bytes of the
                        \ orientation vectors

 LDX #14                \ We want to clear the low bytes, so start from sidev_y
                        \ at byte #9+14 (we clear all except sidev_z_lo, though
                        \ I suspect this is in error and that X should be 16)

.TIL1

 STA INWK+9,X           \ Set the low byte in byte #9+X to zero

 DEX                    \ Set X = X - 2 to jump down to the next low byte
 DEX

 BPL TIL1               \ Loop back until we have zeroed all the low bytes

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TIS2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate A = A / Q
\  Deep dive: Shift-and-subtract division
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following division, where A is a sign-magnitude number and Q is
\ a positive integer:
\
\   A = A / Q
\
\ The value of A is returned as a sign-magnitude number with 96 representing 1,
\ and the maximum value returned is 1 (i.e. 96). This routine is used when
\ normalising vectors, where we represent fractions using integers, so this
\ gives us an approximation to two decimal places.
\
\ ******************************************************************************

.TIS2

 TAY                    \ Store the argument A in Y

 AND #%01111111         \ Strip the sign bit from the argument, so A = |A|

 CMP Q                  \ If A >= Q then jump to TI4 to return a 1 with the
 BCS TI4                \ correct sign

 LDX #%11111110         \ Set T to have bits 1-7 set, so we can rotate through 7
 STX T                  \ loop iterations, getting a 1 each time, and then
                        \ getting a 0 on the 8th iteration... and we can also
                        \ use T to catch our result bits into bit 0 each time

.TIL2

 ASL A                  \ Shift A to the left

 CMP Q                  \ If A < Q skip the following subtraction
 BCC P%+4

 SBC Q                  \ A >= Q, so set A = A - Q
                        \
                        \ Going into this subtraction we know the C flag is
                        \ set as we passed through the BCC above, and we also
                        \ know that A >= Q, so the C flag will still be set once
                        \ we are done

 ROL T                  \ Rotate the counter in T to the left, and catch the
                        \ result bit into bit 0 (which will be a 0 if we didn't
                        \ do the subtraction, or 1 if we did)

 BCS TIL2               \ If we still have set bits in T, loop back to TIL2 to
                        \ do the next iteration of 7

                        \ We've done the division and now have a result in the
                        \ range 0-255 here, which we need to reduce to the range
                        \ 0-96. We can do that by multiplying the result by 3/8,
                        \ as 256 * 3/8 = 96

 LDA T                  \ Set T = T / 4
 LSR A
 LSR A
 STA T

 LSR A                  \ Set T = T / 8 + T / 4
 ADC T                  \       = 3T / 8
 STA T

 TYA                    \ Fetch the sign bit of the original argument A
 AND #%10000000

 ORA T                  \ Apply the sign bit to T

 RTS                    \ Return from the subroutine

.TI4

 TYA                    \ Fetch the sign bit of the original argument A
 AND #%10000000

 ORA #96                \ Apply the sign bit to 96 (which represents 1)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TIS3
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate -(nosev_1 * roofv_1 + nosev_2 * roofv_2) / nosev_3
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following expression:
\
\   A = -(nosev_1 * roofv_1 + nosev_2 * roofv_2) / nosev_3
\
\ where 1, 2 and 3 are x, y, or z, depending on the values of X, Y and A. This
\ routine is called with the following values:
\
\   X = 0, Y = 2, A = 4 ->
\         A = -(nosev_x * roofv_x + nosev_y * roofv_y) / nosev_z
\
\   X = 0, Y = 4, A = 2 ->
\         A = -(nosev_x * roofv_x + nosev_z * roofv_z) / nosev_y
\
\   X = 2, Y = 4, A = 0 ->
\         A = -(nosev_y * roofv_y + nosev_z * roofv_z) / nosev_x
\
\ Arguments:
\
\   X                   Index 1 (0 = x, 2 = y, 4 = z)
\
\   Y                   Index 2 (0 = x, 2 = y, 4 = z)
\
\   A                   Index 3 (0 = x, 2 = y, 4 = z)
\
\ ******************************************************************************

.TIS3

 STA P+2                \ Store P+2 in A for later

 LDA INWK+10,X          \ Set Q = nosev_x_hi (plus X)
 STA Q

 LDA INWK+16,X          \ Set A = roofv_x_hi (plus X)

 JSR MULT12             \ Set (S R) = Q * A
                        \           = nosev_x_hi * roofv_x_hi

 LDX INWK+10,Y          \ Set Q = nosev_x_hi (plus Y)
 STX Q

 LDA INWK+16,Y          \ Set A = roofv_x_hi (plus Y)

 JSR MAD                \ Set (A X) = Q * A + (S R)
                        \           = (nosev_x,X * roofv_x,X) +
                        \             (nosev_x,Y * roofv_x,Y)

 STX P                  \ Store low byte of result in P, so result is now in
                        \ (A P)

 LDY P+2                \ Set Q = roofv_x_hi (plus argument A)
 LDX INWK+10,Y
 STX Q

 EOR #%10000000         \ Flip the sign of A

                        \ Fall through into DIVDT to do:
                        \
                        \   (P+1 A) = (A P) / Q
                        \
                        \     = -((nosev_x,X * roofv_x,X) +
                        \         (nosev_x,Y * roofv_x,Y))
                        \       / nosev_x,A

\ ******************************************************************************
\
\       Name: DVIDT
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (P+1 A) = (A P) / Q
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following integer division between sign-magnitude numbers:
\
\   (P+1 A) = (A P) / Q
\
\ This uses the same shift-and-subtract algorithm as TIS2.
\
\ ******************************************************************************

.DVIDT

 STA P+1                \ Set P+1 = A, so P(1 0) = (A P)

 EOR Q                  \ Set T = the sign bit of A EOR Q, so it's 1 if A and Q
 AND #%10000000         \ have different signs, i.e. it's the sign of the result
 STA T                  \ of A / Q

 LDA #0                 \ Set A = 0 for us to build a result

 LDX #16                \ Set a counter in X to count the 16 bits in P(1 0)

 ASL P                  \ Shift P(1 0) left
 ROL P+1

 ASL Q                  \ Clear the sign bit of Q the C flag at the same time
 LSR Q

.DVL2

 ROL A                  \ Shift A to the left

 CMP Q                  \ If A < Q skip the following subtraction
 BCC P%+4

 SBC Q                  \ Set A = A - Q
                        \
                        \ Going into this subtraction we know the C flag is
                        \ set as we passed through the BCC above, and we also
                        \ know that A >= Q, so the C flag will still be set once
                        \ we are done

 ROL P                  \ Rotate P(1 0) to the left, and catch the result bit
 ROL P+1                \ into the C flag (which will be a 0 if we didn't
                        \ do the subtraction, or 1 if we did)

 DEX                    \ Decrement the loop counter

 BNE DVL2               \ Loop back for the next bit until we have done all 16
                        \ bits of P(1 0)

 LDA P                  \ Set A = P so the low byte is in the result in A

 ORA T                  \ Set A to the correct sign bit that we set in T above

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\ Save output/ELTF.bin
\
\ ******************************************************************************

PRINT "ELITE F"
PRINT "Assembled at ", ~CODE_F%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_F%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_F%

PRINT "S.F.ELTF ", ~CODE_F%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_F%
\SAVE "output/F.ELTF.bin", CODE_F%, P%, LOAD%

\ ******************************************************************************
\
\ ELITE G FILE
\
\ ******************************************************************************

CODE_G% = P%
LOAD_G% = LOAD% + P% - CODE%

\ ******************************************************************************
\
\       Name: SHPPT
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw a distant ship as a point in the middle of the screen
\
\ ******************************************************************************

.SHPPT

 JSR EE51               \ Call EE51 to remove the ship's wireframe from the
                        \ screen, if there is one

 LDA #Y                 \ Set A = the y-coordinate of a dot halfway down the
                        \ screen

 CMP #Y*2-2             \ If the y-coordinate is bigger than the y-coordinate of
 BCS nono               \ the bottom of the screen, jump to nono as the ship's
                        \ dot is off the bottom of the space view. This will
                        \ never happen, but this code is copied from the flight
                        \ code, where A can contain any y-coordinate

 LDY #2                 \ Call Shpt with Y = 2 to set up bytes 1-4 in the ship
 JSR Shpt               \ lines space, aborting the call to LL9 if the dot is
                        \ off the side of the screen. This call sets up the
                        \ first row of the dot (i.e. a four-pixel dash)

 LDY #6                 \ Set Y to 6 for the next call to Shpt

 LDA #Y                 \ Set A = #Y + 1 (so this is the second row of the
 ADC #1                 \ two-pixel-high dot halfway down the screen)

 JSR Shpt               \ Call Shpt with Y = 6 to set up bytes 5-8 in the ship
                        \ lines space, aborting the call to LL9 if the dot is
                        \ off the side of the screen. This call sets up the
                        \ second row of the dot (i.e. another four-pixel dash,
                        \ on the row below the first one)

 LDA #%00001000         \ Set bit 3 of the ship's byte #31 to record that we
 ORA XX1+31             \ have now drawn something on-screen for this ship
 STA XX1+31

 LDA #8                 \ Set A = 8 so when we call LL18+2 next, byte #0 of the
                        \ heap gets set to 8, for the 8 bytes we just stuck on
                        \ the heap

 JMP LL81+2             \ Call LL81+2 to draw the ship's dot, returning from the
                        \ subroutine using a tail call

 PLA                    \ Pull the return address from the stack, so the RTS
 PLA                    \ below actually returns from the subroutine that called
                        \ LL9 (as we called SHPPT from LL9 with a JMP)

.nono

 LDA #%11110111         \ Clear bit 3 of the ship's byte #31 to record that
 AND XX1+31             \ nothing is being drawn on-screen for this ship
 STA XX1+31

 RTS                    \ Return from the subroutine

.Shpt

                        \ This routine sets up four bytes in the ship line heap,
                        \ from byte Y-1 to byte Y+2. If the ship's screen point
                        \ turns out to be off-screen, then this routine aborts
                        \ the entire call to LL9, exiting via nono. The four
                        \ bytes define a horizontal 4-pixel dash, for either the
                        \ top or the bottom of the ship's dot

 STA (XX19),Y           \ Store A in byte Y of the ship line heap

 INY                    \ Store A in byte Y+2 of the ship line heap
 INY
 STA (XX19),Y

 LDA #X                 \ Set A = x-coordinate of the middle of the screen

 DEY                    \ Store A in byte Y+1 of the ship line heap
 STA (XX19),Y

 ADC #3                 \ Set A = screen x-coordinate of the ship dot + 3

 BCS nono-2             \ If the addition pushed the dot off the right side of
                        \ the screen, jump to nono-2 to return from the parent
                        \ subroutine early (i.e. LL9). This works because we
                        \ called Shpt from above with a JSR, so nono-2 removes
                        \ that return address from the stack, leaving the next
                        \ return address exposed. LL9 called SHPPT with a JMP.
                        \ so the next return address is the one that was put on
                        \ the stack by the original call to LL9. So the RTS in
                        \ nono will actually return us from the original call
                        \ to LL9, thus aborting the entire drawing process

 DEY                    \ Store A in byte Y-1 of the ship line heap
 DEY
 STA (XX19),Y

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL5
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate Q = SQRT(R Q)
\  Deep dive: Calculating square roots
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following square root:
\
\   Q = SQRT(R Q)
\
\ ******************************************************************************

.LL5

 LDY R                  \ Set (Y S) = (R Q)
 LDA Q
 STA S

                        \ So now to calculate Q = SQRT(Y S)

 LDX #0                 \ Set X = 0, to hold the remainder

 STX Q                  \ Set Q = 0, to hold the result

 LDA #8                 \ Set T = 8, to use as a loop counter
 STA T

.LL6

 CPX Q                  \ If X < Q, jump to LL7
 BCC LL7

 BNE LL8                \ If X > Q, jump to LL8

 CPY #64                \ If Y < 64, jump to LL7 with the C flag clear,
 BCC LL7                \ otherwise fall through into LL8 with the C flag set

.LL8

 TYA                    \ Set Y = Y - 64
 SBC #64                \
 TAY                    \ This subtraction will work as we know C is set from
                        \ the BCC above, and the result will not underflow as we
                        \ already checked that Y >= 64, so the C flag is also
                        \ set for the next subtraction

 TXA                    \ Set X = X - Q
 SBC Q
 TAX

.LL7

 ROL Q                  \ Shift the result in Q to the left, shifting the C flag
                        \ into bit 0 and bit 7 into the C flag

 ASL S                  \ Shift the dividend in (Y S) to the left, inserting
 TYA                    \ bit 7 from above into bit 0
 ROL A
 TAY

 TXA                    \ Shift the remainder in X to the left
 ROL A
 TAX

 ASL S                  \ Shift the dividend in (Y S) to the left
 TYA
 ROL A
 TAY

 TXA                    \ Shift the remainder in X to the left
 ROL A
 TAX

 DEC T                  \ Decrement the loop counter

 BNE LL6                \ Loop back to LL6 until we have done 8 loops

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL28
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate R = 256 * A / Q
\  Deep dive: Shift-and-subtract division
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following, where A < Q:
\
\   R = 256 * A / Q
\
\ This is a sister routine to LL61, which does the division when A >= Q.
\
\ If A >= Q then 255 is returned and the C flag is set to indicate an overflow
\ (the C flag is clear if the division was a success).
\
\ The result is returned in one byte as the result of the division multiplied
\ by 256, so we can return fractional results using integers.
\
\ This routine uses the same shift-and-subtract algorithm that's documented in
\ TIS2, but it leaves the fractional result in the integer range 0-255.
\
\ Returns:
\
\   C flag              Set if the answer is too big for one byte, clear if the
\                       division was a success
\
\ Other entry points:
\
\   LL28+4              Skips the A >= Q check and always returns with C flag
\                       cleared, so this can be called if we know the division
\                       will work
\
\   LL31                Skips the A >= Q check and does not set the R counter,
\                       so this can be used for jumping straight into the
\                       division loop if R is already set to 254 and we know the
\                       division will work
\
\ ******************************************************************************

.LL28

 CMP Q                  \ If A >= Q, then the answer will not fit in one byte,
 BCS LL2                \ so jump to LL2 to return 255

 LDX #%11111110         \ Set R to have bits 1-7 set, so we can rotate through 7
 STX R                  \ loop iterations, getting a 1 each time, and then
                        \ getting a 0 on the 8th iteration... and we can also
                        \ use R to catch our result bits into bit 0 each time

.LL31

 ASL A                  \ Shift A to the left

 BCS LL29               \ If bit 7 of A was set, then jump straight to the
                        \ subtraction

 CMP Q                  \ If A < Q, skip the following subtraction
 BCC P%+4

 SBC Q                  \ A >= Q, so set A = A - Q

 ROL R                  \ Rotate the counter in R to the left, and catch the
                        \ result bit into bit 0 (which will be a 0 if we didn't
                        \ do the subtraction, or 1 if we did)

 BCS LL31               \ If we still have set bits in R, loop back to LL31 to
                        \ do the next iteration of 7

 RTS                    \ R left with remainder of division

.LL29

 SBC Q                  \ A >= Q, so set A = A - Q

 SEC                    \ Set the C flag to rotate into the result in R

 ROL R                  \ Rotate the counter in R to the left, and catch the
                        \ result bit into bit 0 (which will be a 0 if we didn't
                        \ do the subtraction, or 1 if we did)

 BCS LL31               \ If we still have set bits in R, loop back to LL31 to
                        \ do the next iteration of 7

 RTS                    \ Return from the subroutine with R containing the
                        \ remainder of the division

.LL2

 LDA #255               \ The division is very close to 1, so return the closest
 STA R                  \ possible answer to 256, i.e. R = 255

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL38
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (S A) = (S R) + (A Q)
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following between sign-magnitude numbers:
\
\   (S A) = (S R) + (A Q)
\
\ where the sign bytes only contain the sign bits, not magnitudes.
\
\ Returns:
\
\   C flag              Set if the addition overflowed, clear otherwise
\
\ ******************************************************************************

.LL38

 EOR S                  \ If the sign of A * S is negative, skip to LL35, as
 BMI LL39               \ A and S have different signs so we need to subtract

 LDA Q                  \ Otherwise set A = R + Q, which is the result we need,
 CLC                    \ as S already contains the correct sign
 ADC R

 RTS                    \ Return from the subroutine

.LL39

 LDA R                  \ Set A = R - Q
 SEC
 SBC Q

 BCC P%+4               \ If the subtraction underflowed, skip the next two
                        \ instructions so we can negate the result

 CLC                    \ Otherwise the result is correct, and S contains the
                        \ correct sign of the result as R is the dominant side
                        \ of the subtraction, so clear the C flag

 RTS                    \ And return from the subroutine

                        \ If we get here we need to negate both the result and
                        \ the sign in S, as both are the wrong sign

 PHA                    \ Store the result of the subtraction on the stack

 LDA S                  \ Flip the sign of S
 EOR #%10000000
 STA S

 PLA                    \ Restore the subtraction result into A

 EOR #%11111111         \ Negate the result in A using two's complement, i.e.
 ADC #1                 \ set A = ~A + 1

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL51
\       Type: Subroutine
\   Category: Maths (Geometry)
\    Summary: Calculate the dot product of XX15 and XX16
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following dot products:
\
\   XX12(1 0) = XX15(5 0) . XX16(5 0)
\   XX12(3 2) = XX15(5 0) . XX16(11 6)
\   XX12(5 4) = XX15(5 0) . XX16(12 17)
\
\ storing the results as sign-magnitude numbers in XX12 through XX12+5.
\
\ When called from part 5 of LL9, XX12 contains the vector [x y z] to the ship
\ we're drawing, and XX16 contains the orientation vectors, so it returns:
\
\   [ x ]   [ sidev_x ]         [ x ]   [ roofv_x ]         [ x ]   [ nosev_x ]
\   [ y ] . [ sidev_y ]         [ y ] . [ roofv_y ]         [ y ] . [ nosev_y ]
\   [ z ]   [ sidev_z ]         [ z ]   [ roofv_z ]         [ z ]   [ nosev_z ]
\
\ When called from part 6 of LL9, XX12 contains the vector [x y z] of the vertex
\ we're analysing, and XX16 contains the transposed orientation vectors with
\ each of them containing the x, y and z elements of the original vectors, so it
\ returns:
\
\   [ x ]   [ sidev_x ]         [ x ]   [ sidev_y ]         [ x ]   [ sidev_z ]
\   [ y ] . [ roofv_x ]         [ y ] . [ roofv_y ]         [ y ] . [ roofv_z ]
\   [ z ]   [ nosev_x ]         [ z ]   [ nosev_y ]         [ z ]   [ nosev_z ]
\
\ Arguments:
\
\   XX15(1 0)           The ship (or vertex)'s x-coordinate as (x_sign x_lo)
\
\   XX15(3 2)           The ship (or vertex)'s y-coordinate as (y_sign y_lo)
\
\   XX15(5 4)           The ship (or vertex)'s z-coordinate as (z_sign z_lo)
\
\   XX16 to XX16+5      The scaled sidev (or _x) vector, with:
\
\                         * x, y, z magnitudes in XX16, XX16+2, XX16+4
\
\                         * x, y, z signs in XX16+1, XX16+3, XX16+5
\
\   XX16+6 to XX16+11   The scaled roofv (or _y) vector, with:
\
\                         * x, y, z magnitudes in XX16+6, XX16+8, XX16+10
\
\                         * x, y, z signs in XX16+7, XX16+9, XX16+11
\
\   XX16+12 to XX16+17  The scaled nosev (or _z) vector, with:
\
\                         * x, y, z magnitudes in XX16+12, XX16+14, XX16+16
\
\                         * x, y, z signs in XX16+13, XX16+15, XX16+17
\
\ Returns:
\
\   XX12(1 0)           The dot product of [x y z] vector with the sidev (or _x)
\                       vector, with the sign in XX12+1 and magnitude in XX12
\
\   XX12(3 2)           The dot product of [x y z] vector with the roofv (or _y)
\                       vector, with the sign in XX12+3 and magnitude in XX12+2
\
\   XX12(5 4)           The dot product of [x y z] vector with the nosev (or _z)
\                       vector, with the sign in XX12+5 and magnitude in XX12+4
\
\ ******************************************************************************

.LL51

 LDX #0                 \ Set X = 0, which will contain the offset of the vector
                        \ to use in the calculation, increasing by 6 for each
                        \ new vector

 LDY #0                 \ Set Y = 0, which will contain the offset of the
                        \ result bytes in XX12, increasing by 2 for each new
                        \ result

.ll51

 LDA XX15               \ Set Q = x_lo
 STA Q

 LDA XX16,X             \ Set A = |sidev_x|

 JSR FMLTU              \ Set T = A * Q / 256
 STA T                  \       = |sidev_x| * x_lo / 256

 LDA XX15+1             \ Set S to the sign of x_sign * sidev_x
 EOR XX16+1,X
 STA S

 LDA XX15+2             \ Set Q = y_lo
 STA Q

 LDA XX16+2,X           \ Set A = |sidev_y|

 JSR FMLTU              \ Set Q = A * Q / 256
 STA Q                  \       = |sidev_y| * y_lo / 256

 LDA T                  \ Set R = T
 STA R                  \       = |sidev_x| * x_lo / 256

 LDA XX15+3             \ Set A to the sign of y_sign * sidev_y
 EOR XX16+3,X

 JSR LL38               \ Set (S T) = (S R) + (A Q)
 STA T                  \           = |sidev_x| * x_lo + |sidev_y| * y_lo

 LDA XX15+4             \ Set Q = z_lo
 STA Q

 LDA XX16+4,X           \ Set A = |sidev_z|

 JSR FMLTU              \ Set Q = A * Q / 256
 STA Q                  \       = |sidev_z| * z_lo / 256

 LDA T                  \ Set R = T
 STA R                  \       = |sidev_x| * x_lo + |sidev_y| * y_lo

 LDA XX15+5             \ Set A to the sign of z_sign * sidev_z
 EOR XX16+5,X

 JSR LL38               \ Set (S A) = (S R) + (A Q)
                        \           = |sidev_x| * x_lo + |sidev_y| * y_lo
                        \             + |sidev_z| * z_lo

 STA XX12,Y             \ Store the result in XX12+Y(1 0)
 LDA S
 STA XX12+1,Y

 INY                    \ Set Y = Y + 2
 INY

 TXA                    \ Set X = X + 6
 CLC
 ADC #6
 TAX

 CMP #17                \ If X < 17, loop back to ll51 for the next vector
 BCC ll51

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL9 (Part 1 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Check if ship is exploding, check if ship is in front
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This routine draws the current ship on the screen. This part checks to see if
\ the ship is exploding, or if it should start exploding, and if it does it sets
\ things up accordingly.
\
\ It also does some basic checks to see if we can see the ship, and if not it
\ removes it from the screen.
\
\ In this code, XX1 is used to point to the current ship's data block at INWK
\ (the two labels are interchangeable).
\
\ Arguments:
\
\   XX1                 XX1 shares its location with INWK, which contains the
\                       zero-page copy of the data block for this ship from the
\                       K% workspace
\
\   INF                 The address of the data block for this ship in workspace
\                       K%
\
\   XX19(1 0)           XX19(1 0) shares its location with INWK(34 33), which
\                       contains the ship line heap address pointer
\
\   XX0                 The address of the blueprint for this ship
\
\ Other entry points:
\
\   EE51                Remove the current ship from the screen, called from
\                       SHPPT before drawing the ship as a point
\
\ ******************************************************************************

.LL9

 LDA #31                \ Set XX4 = 31 to store the ship's distance for later
 STA XX4                \ comparison with the visibility distance. We will
                        \ update this value below with the actual ship's
                        \ distance if it turns out to be visible on-screen

 LDA #%00100000         \ If bit 5 of the ship's byte #31 is set, then the ship
 BIT XX1+31             \ is currently exploding, so jump down to EE28
 BNE EE28

 BPL EE28               \ If bit 7 of the ship's byte #31 is clear then the ship
                        \ has not just been killed, so jump down to EE28

                        \ Otherwise bit 5 is clear and bit 7 is set, so the ship
                        \ is not yet exploding but it has been killed, so we
                        \ need to start an explosion

 ORA XX1+31             \ Clear bits 6 and 7 of the ship's byte #31, to stop the
 AND #%00111111         \ ship from firing its laser and to mark it as no longer
 STA XX1+31             \ having just been killed

 LDA #0                 \ Set the ship's acceleration in byte #31 to 0, updating
 LDY #28                \ the byte in the workspace K% data block so we don't
 STA (INF),Y            \ have to copy it back from INWK later

 LDY #30                \ Set the ship's pitch counter in byte #30 to 0, to stop
 STA (INF),Y            \ the ship from pitching

 JSR EE51               \ Call EE51 to remove the ship from the screen

                        \ We now need to set up a new explosion cloud. We
                        \ initialise it with a size of 18 (which gets increased
                        \ by 4 every time the cloud gets redrawn), and the
                        \ explosion count (i.e. the number of particles in the
                        \ explosion), which go into bytes 1 and 2 of the ship
                        \ line heap. See DOEXP for more details of explosion
                        \ clouds

 LDY #1                 \ Set byte #1 of the ship line heap to 18, the initial
 LDA #18                \ size of the explosion cloud
 STA (XX19),Y

 LDY #7                 \ Fetch byte #7 from the ship's blueprint, which
 LDA (XX0),Y            \ determines the explosion count (i.e. the number of
 LDY #2                 \ vertices used as origins for explosion clouds), and
 STA (XX19),Y           \ store it in byte #2 of the ship line heap

\LDA XX1+32             \ These instructions are commented out in the original
\AND #&7F               \ source

                        \ The following loop sets bytes 3-6 of the of the ship
                        \ line heap to random numbers

.EE55

 INY                    \ Increment Y (so the loop starts at 3)

 JSR DORND              \ Set A and X to random numbers

 STA (XX19),Y           \ Store A in the Y-th byte of the ship line heap

 CPY #6                 \ Loop back until we have randomised the 6th byte
 BNE EE55

.EE28

 LDA XX1+8              \ Set A = z_sign

.EE49

 BPL LL10               \ If A is positive, i.e. the ship is in front of us,
                        \ jump down to LL10

.LL14

                        \ The following removes the ship from the screen by
                        \ redrawing it (or, if it is exploding, by redrawing the
                        \ explosion cloud). We call it when the ship is no
                        \ longer on-screen, is too far away to be fully drawn,
                        \ and so on

 LDA XX1+31             \ If bit 5 of the ship's byte #31 is clear, then the
 AND #%00100000         \ ship is not currently exploding, so jump down to EE51
 BEQ EE51               \ to redraw its wireframe

 LDA XX1+31             \ The ship is exploding, so clear bit 3 of the ship's
 AND #%11110111         \ byte #31 to denote that the ship is no longer being
 STA XX1+31             \ drawn on-screen

                        \ --- Original Acornsoft code removed: ---------------->

\ JMP DOEXP             \ Jump to DOEXP to return from the subroutine using a
\                       \ tail call, as in the docked code DOEXP just contains
\                       \ an RTS

                        \ --- And replaced by: -------------------------------->

 JMP TT48               \ AJD

                        \ --- End of replacement ------------------------------>

.EE51

 LDA #%00001000         \ If bit 3 of the ship's byte #31 is clear, then there
 BIT XX1+31             \ is already nothing being shown for this ship, so
 BEQ LL10-1             \ return from the subroutine (as LL10-1 contains an RTS)

 EOR XX1+31             \ Otherwise flip bit 3 of byte #31 and store it (which
 STA XX1+31             \ clears bit 3 as we know it was set before the EOR), so
                        \ this sets this ship as no longer being drawn on-screen

 JMP LL155              \ Jump to LL155 to draw the ship, which removes it from
                        \ the screen, returning from the subroutine using a
                        \ tail call

\LL24                   \ This label is commented out in the original source,
                        \ and was presumably used to label the RTS which is
                        \ actually called by LL10-1 above, not LL24

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL9 (Part 2 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Check if ship is in field of view, close enough to draw
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This part checks whether the ship is in our field of view, and whether it is
\ close enough to be fully drawn (if not, we jump to SHPPT to draw it as a dot).
\
\ Other entry points:
\
\   LL10-1              Contains an RTS
\
\ ******************************************************************************

.LL10

 LDA XX1+7              \ Set A = z_hi

 CMP #192               \ If A >= 192 then the ship is a long way away, so jump
 BCS LL14               \ to LL14 to remove the ship from the screen

 LDA XX1                \ If x_lo >= z_lo, set the C flag, otherwise clear it
 CMP XX1+6

 LDA XX1+1              \ Set A = x_hi - z_hi using the carry from the low
 SBC XX1+7              \ bytes, which sets the C flag as if we had done a full
                        \ two-byte subtraction (x_hi x_lo) - (z_hi z_lo)

 BCS LL14               \ If the C flag is set then x >= z, so the ship is
                        \ further to the side than it is in front of us, so it's
                        \ outside our viewing angle of 45 degrees, and we jump
                        \ to LL14 to remove it from the screen

 LDA XX1+3              \ If y_lo >= z_lo, set the C flag, otherwise clear it
 CMP XX1+6

 LDA XX1+4              \ Set A = y_hi - z_hi using the carry from the low
 SBC XX1+7              \ bytes, which sets the C flag as if we had done a full
                        \ two-byte subtraction (y_hi y_lo) - (z_hi z_lo)

 BCS LL14               \ If the C flag is set then y >= z, so the ship is
                        \ further above us than it is in front of us, so it's
                        \ outside our viewing angle of 45 degrees, and we jump
                        \ to LL14 to remove it from the screen

 LDY #6                 \ Fetch byte #6 from the ship's blueprint into X, which
 LDA (XX0),Y            \ is the number * 4 of the vertex used for the ship's
 TAX                    \ laser

 LDA #255               \ Set bytes X and X+1 of the XX3 heap to 255. We're
 STA XX3,X              \ going to use XX3 to store the screen coordinates of
 STA XX3+1,X            \ all the visible vertices of this ship, so setting the
                        \ laser vertex to 255 means that if we don't update this
                        \ vertex with its screen coordinates in parts 6 and 7,
                        \ this vertex's entry in the XX3 heap will still be 255,
                        \ which we can check in part 9 to see if the laser
                        \ vertex is visible (and therefore whether we should
                        \ draw laser lines if the ship is firing on us)

 LDA XX1+6              \ Set (A T) = (z_hi z_lo)
 STA T
 LDA XX1+7

 LSR A                  \ Set (A T) = (A T) / 8
 ROR T
 LSR A
 ROR T
 LSR A
 ROR T

 LSR A                  \ If A >> 4 is non-zero, i.e. z_hi >= 16, jump to LL13
 BNE LL13               \ as the ship is possibly far away enough to be shown as
                        \ a dot

 LDA T                  \ Otherwise the C flag contains the previous bit 0 of A,
 ROR A                  \ which could have been set, so rotate A right four
 LSR A                  \ times so it's in the form %000xxxxx, i.e. z_hi reduced
 LSR A                  \ to a maximum value of 31
 LSR A

 STA XX4                \ Store A in XX4, which is now the distance of the ship
                        \ we can use for visibility testing

 BPL LL17               \ Jump down to LL17 (this BPL is effectively a JMP as we
                        \ know bit 7 of A is definitely clear)

.LL13

                        \ If we get here then the ship is possibly far enough
                        \ away to be shown as a dot

 LDY #13                \ Fetch byte #13 from the ship's blueprint, which gives
 LDA (XX0),Y            \ the ship's visibility distance, beyond which we show
                        \ the ship as a dot

 CMP XX1+7              \ If z_hi <= the visibility distance, skip to LL17 to
 BCS LL17               \ draw the ship fully, rather than as a dot, as it is
                        \ closer than the visibility distance

 LDA #%00100000         \ If bit 5 of the ship's byte #31 is set, then the
 AND XX1+31             \ ship is currently exploding, so skip to LL17 to draw
 BNE LL17               \ the ship's explosion cloud

 JMP SHPPT              \ Otherwise jump to SHPPT to draw the ship as a dot,
                        \ returning from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: LL9 (Part 3 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Set up orientation vector, ship coordinate variables
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This part sets up the following variable blocks:
\
\   * XX16 contains the orientation vectors, divided to normalise them
\
\   * XX18 contains the ship's x, y and z coordinates in space
\
\ ******************************************************************************

.LL17

 LDX #5                 \ First we copy the three orientation vectors into XX16,
                        \ so set up a counter in X for the 6 bytes in each
                        \ vector

.LL15

 LDA XX1+21,X           \ Copy the X-th byte of sidev to the X-th byte of XX16
 STA XX16,X

 LDA XX1+15,X           \ Copy the X-th byte of roofv to XX16+6 to the X-th byte
 STA XX16+6,X           \ of XX16+6

 LDA XX1+9,X            \ Copy the X-th byte of nosev to XX16+12 to the X-th
 STA XX16+12,X          \ byte of XX16+12

 DEX                    \ Decrement the counter

 BPL LL15               \ Loop back to copy the next byte of each vector, until
                        \ we have the following:
                        \
                        \   * XX16(1 0) = sidev_x
                        \   * XX16(3 2) = sidev_y
                        \   * XX16(5 4) = sidev_z
                        \
                        \   * XX16(7 6) = roofv_x
                        \   * XX16(9 8) = roofv_y
                        \   * XX16(11 10) = roofv_z
                        \
                        \   * XX16(13 12) = nosev_x
                        \   * XX16(15 14) = nosev_y
                        \   * XX16(17 16) = nosev_z

 LDA #197               \ Set Q = 197
 STA Q

 LDY #16                \ Set Y to be a counter that counts down by 2 each time,
                        \ starting with 16, then 14, 12 and so on. We use this
                        \ to work through each of the coordinates in each of the
                        \ orientation vectors

.LL21

 LDA XX16,Y             \ Set A = the low byte of the vector coordinate, e.g.
                        \ nosev_z_lo when Y = 16

 ASL A                  \ Shift bit 7 into the C flag

 LDA XX16+1,Y           \ Set A = the high byte of the vector coordinate, e.g.
                        \ nosev_z_hi when Y = 16

 ROL A                  \ Rotate A left, incorporating the C flag, so A now
                        \ contains the original high byte, doubled, and without
                        \ a sign bit, e.g. A = |nosev_z_hi| * 2

 JSR LL28               \ Call LL28 to calculate:
                        \
                        \   R = 256 * A / Q
                        \
                        \ so, for nosev, this would be:
                        \
                        \   R = 256 * |nosev_z_hi| * 2 / 197
                        \     = 2.6 * |nosev_z_hi|

 LDX R                  \ Store R in the low byte's location, so we can keep the
 STX XX16,Y             \ old, unscaled high byte intact for the sign

 DEY                    \ Decrement the loop counter twice
 DEY

 BPL LL21               \ Loop back for the next vector coordinate until we have
                        \ divided them all

                        \ By this point, the vectors have been turned into
                        \ scaled magnitudes, so we have the following:
                        \
                        \   * XX16   = scaled |sidev_x|
                        \   * XX16+2 = scaled |sidev_y|
                        \   * XX16+4 = scaled |sidev_z|
                        \
                        \   * XX16+6  = scaled |roofv_x|
                        \   * XX16+8  = scaled |roofv_y|
                        \   * XX16+10 = scaled |roofv_z|
                        \
                        \   * XX16+12 = scaled |nosev_x|
                        \   * XX16+14 = scaled |nosev_y|
                        \   * XX16+16 = scaled |nosev_z|

 LDX #8                 \ Next we copy the ship's coordinates into XX18, so set
                        \ up a counter in X for 9 bytes

.ll91

 LDA XX1,X              \ Copy the X-th byte from XX1 to XX18
 STA XX18,X

 DEX                    \ Decrement the loop counter

 BPL ll91               \ Loop back for the next byte until we have copied all
                        \ three coordinates

                        \ So we now have the following:
                        \
                        \   * XX18(2 1 0) = (x_sign x_hi x_lo)
                        \
                        \   * XX18(5 4 3) = (y_sign y_hi y_lo)
                        \
                        \   * XX18(8 7 6) = (z_sign z_hi z_lo)

 LDA #255               \ Set the 15th byte of XX2 to 255, so that face 15 is
 STA XX2+15             \ always visible. No ship definitions actually have this
                        \ number of faces in the cassette version, but this
                        \ allows us to force a vertex to always be visible by
                        \ associating it with face 15 (see the blueprints for
                        \ the Cobra Mk III at SHIP_COBRA_MK_3 and asteroid at
                        \ SHIP_ASTEROID for examples)

 LDY #12                \ Set Y = 12 to point to the ship blueprint byte #12,

 LDA XX1+31             \ If bit 5 of the ship's byte #31 is clear, then the
 AND #%00100000         \ ship is not currently exploding, so jump down to EE29
 BEQ EE29               \ to skip the following

                        \ Otherwise we fall through to set up the visibility
                        \ block for an exploding ship

\ ******************************************************************************
\
\       Name: LL9 (Part 4 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Set visibility for exploding ship (all faces visible)
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This part sets up the visibility block in XX2 for a ship that is exploding.
\
\ The XX2 block consists of one byte for each face in the ship's blueprint,
\ which holds the visibility of that face. Because the ship is exploding, we
\ want to set all the faces to be visible. A value of 255 in the visibility
\ table means the face is visible, so the following code sets each face to 255
\ and then skips over the face visibility calculations that we would apply to a
\ non-exploding ship.
\
\ ******************************************************************************

 LDA (XX0),Y            \ Fetch byte #12 of the ship's blueprint, which contains
                        \ the number of faces * 4

 LSR A                  \ Set X = A / 4
 LSR A                  \       = the number of faces
 TAX

 LDA #255               \ Set A = 255

.EE30

 STA XX2,X              \ Set the X-th byte of XX2 to 255

 DEX                    \ Decrement the loop counter

 BPL EE30               \ Loop back for the next byte until there is one byte
                        \ set to 255 for each face

 INX                    \ Set XX4 = 0 for the distance value we use to test
 STX XX4                \ for visibility, so we always shows everything

.LL41

 JMP LL42               \ Jump to LL42 to skip the face visibility calculations
                        \ as we don't need to do them now we've set up the XX2
                        \ block for the explosion

\ ******************************************************************************
\
\       Name: LL9 (Part 5 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Calculate the visibility of each of the ship's faces
\  Deep dive: Drawing ships
\             Back-face culling
\
\ ******************************************************************************

.EE29

 LDA (XX0),Y            \ We set Y to 12 above before jumping down to EE29, so
                        \ this fetches byte #12 of the ship's blueprint, which
                        \ contains the number of faces * 4

 BEQ LL41               \ If there are no faces in this ship, jump to LL42 (via
                        \ LL41) to skip the face visibility calculations

 STA XX20               \ Set A = the number of faces * 4

 LDY #18                \ Fetch byte #18 of the ship's blueprint, which contains
 LDA (XX0),Y            \ the factor by which we scale the face normals, into X
 TAX

 LDA XX18+7             \ Set A = z_hi

.LL90

 TAY                    \ Set Y = z_hi

 BEQ LL91               \ If z_hi = 0 then jump to LL91

                        \ The following is a loop that jumps back to LL90+3,
                        \ i.e. here. LL90 is only used for this loop, so it's a
                        \ bit of a strange use of the label here

 INX                    \ Increment the scale factor in X

 LSR XX18+4             \ Divide (y_hi y_lo) by 2
 ROR XX18+3

 LSR XX18+1             \ Divide (x_hi x_lo) by 2
 ROR XX18

 LSR A                  \ Divide (z_hi z_lo) by 2 (as A contains z_hi)
 ROR XX18+6

 TAY                    \ Set Y = z_hi

 BNE LL90+3             \ If Y is non-zero, loop back to LL90+3 to divide the
                        \ three coordinates until z_hi is 0

.LL91

                        \ By this point z_hi is 0 and X contains the number of
                        \ right shifts we had to do, plus the scale factor from
                        \ the blueprint

 STX XX17               \ Store the updated scale factor in XX17

 LDA XX18+8             \ Set XX15+5 = z_sign
 STA XX15+5

 LDA XX18               \ Set XX15(1 0) = (x_sign x_lo)
 STA XX15
 LDA XX18+2
 STA XX15+1

 LDA XX18+3             \ Set XX15(3 2) = (y_sign y_lo)
 STA XX15+2
 LDA XX18+5
 STA XX15+3

 LDA XX18+6             \ Set XX15+4 = z_lo, so now XX15(5 4) = (z_sign z_lo)
 STA XX15+4

 JSR LL51               \ Call LL51 to set XX12 to the dot products of XX15 and
                        \ XX16, which we'll call dot_sidev, dot_roofv and
                        \ dot_nosev:
                        \
                        \   XX12(1 0) = [x y z] . sidev
                        \             = (dot_sidev_sign dot_sidev_lo)
                        \             = dot_sidev
                        \
                        \   XX12(3 2) = [x y z] . roofv
                        \             = (dot_roofv_sign dot_roofv_lo)
                        \             = dot_roofv
                        \
                        \   XX12(5 4) = [x y z] . nosev
                        \             = (dot_nosev_sign dot_nosev_lo)
                        \             = dot_nosev

 LDA XX12               \ Set XX18(2 0) = dot_sidev
 STA XX18
 LDA XX12+1
 STA XX18+2

 LDA XX12+2             \ Set XX18(5 3) = dot_roofv
 STA XX18+3
 LDA XX12+3
 STA XX18+5

 LDA XX12+4             \ Set XX18(8 6) = dot_nosev
 STA XX18+6
 LDA XX12+5
 STA XX18+8

 LDY #4                 \ Fetch byte #4 of the ship's blueprint, which contains
 LDA (XX0),Y            \ the low byte of the offset to the faces data

 CLC                    \ Set V = low byte faces offset + XX0
 ADC XX0
 STA V

 LDY #17                \ Fetch byte #17 of the ship's blueprint, which contains
 LDA (XX0),Y            \ the high byte of the offset to the faces data

 ADC XX0+1              \ Set V+1 = high byte faces offset + XX0+1
 STA V+1                \
                        \ So V(1 0) now points to the start of the faces data
                        \ for this ship

 LDY #0                 \ We're now going to loop through all the faces for this
                        \ ship, so set a counter in Y, starting from 0, which we
                        \ will increment by 4 each loop to step through the
                        \ four bytes of data for each face

.LL86

 LDA (V),Y              \ Fetch byte #0 for this face into A, so:
                        \
                        \   A = %xyz vvvvv, where:
                        \
                        \     * Bits 0-4 = visibility distance, beyond which the
                        \       face is always shown
                        \
                        \     * Bits 7-5 = the sign bits of normal_x, normal_y
                        \       and normal_z

 STA XX12+1             \ Store byte #0 in XX12+1, so XX12+1 now has the sign of
                        \ normal_x

 AND #%00011111         \ Extract bits 0-4 to give the visibility distance

 CMP XX4                \ If XX4 <= the visibility distance, where XX4 contains
 BCS LL87               \ the ship's z-distance reduced to 0-31 (which we set in
                        \ part 2), skip to LL87 as this face is close enough
                        \ that we have to test its visibility using the face
                        \ normals

                        \ Otherwise this face is within range and is therefore
                        \ always shown

 TYA                    \ Set X = Y / 4
 LSR A                  \       = the number of this face * 4 /4
 LSR A                  \       = the number of this face
 TAX

 LDA #255               \ Set the X-th byte of XX2 to 255 to denote that this
 STA XX2,X              \ face is visible

 TYA                    \ Set Y = Y + 4 to point to the next face
 ADC #4
 TAY

 JMP LL88               \ Jump down to LL88 to skip the following, as we don't
                        \ need to test the face normals

.LL87

 LDA XX12+1             \ Fetch byte #0 for this face into A

 ASL A                  \ Shift A left and store it, so XX12+3 now has the sign
 STA XX12+3             \ of normal_y

 ASL A                  \ Shift A left and store it, so XX12+5 now has the sign
 STA XX12+5             \ of normal_z

 INY                    \ Increment Y to point to byte #1

 LDA (V),Y              \ Fetch byte #1 for this face and store in XX12, so
 STA XX12               \ XX12 = normal_x

 INY                    \ Increment Y to point to byte #2

 LDA (V),Y              \ Fetch byte #2 for this face and store in XX12+2, so
 STA XX12+2             \ XX12+2 = normal_y

 INY                    \ Increment Y to point to byte #3

 LDA (V),Y              \ Fetch byte #3 for this face and store in XX12+4, so
 STA XX12+4             \ XX12+4 = normal_z

                        \ So we now have:
                        \
                        \   XX12(1 0) = (normal_x_sign normal_x)
                        \
                        \   XX12(3 2) = (normal_y_sign normal_y)
                        \
                        \   XX12(5 4) = (normal_z_sign normal_z)

 LDX XX17               \ If XX17 < 4 then jump to LL92, otherwise we stored a
 CPX #4                 \ larger scale factor above
 BCC LL92

.LL143

 LDA XX18               \ Set XX15(1 0) = XX18(2 0)
 STA XX15               \               = dot_sidev
 LDA XX18+2
 STA XX15+1

 LDA XX18+3             \ Set XX15(3 2) = XX18(5 3)
 STA XX15+2             \               = dot_roofv
 LDA XX18+5
 STA XX15+3

 LDA XX18+6             \ Set XX15(5 4) = XX18(8 6)
 STA XX15+4             \               = dot_nosev
 LDA XX18+8
 STA XX15+5

 JMP LL89               \ Jump down to LL89

.ovflw

                        \ If we get here then the addition below overflowed, so
                        \ we halve the dot products and normal vector

 LSR XX18               \ Divide dot_sidev_lo by 2, so dot_sidev = dot_sidev / 2

 LSR XX18+6             \ Divide dot_nosev_lo by 2, so dot_nosev = dot_nosev / 2

 LSR XX18+3             \ Divide dot_roofv_lo by 2, so dot_roofv = dot_roofv / 2

 LDX #1                 \ Set X = 1 so when we fall through into LL92, we divide
                        \ the normal vector by 2 as well

.LL92

                        \ We jump here from above with the scale factor in X,
                        \ and now we apply it by scaling the normal vector down
                        \ by a factor of 2^X (i.e. divide by 2^X)

 LDA XX12               \ Set XX15 = normal_x
 STA XX15

 LDA XX12+2             \ Set XX15+2 = normal_y
 STA XX15+2

 LDA XX12+4             \ Set A = normal_z

.LL93

 DEX                    \ Decrement the scale factor in X

 BMI LL94               \ If X was 0 before the decrement, there is no scaling
                        \ to do, so jump to LL94 to exit the loop

 LSR XX15               \ Set XX15 = XX15 / 2
                        \          = normal_x / 2

 LSR XX15+2             \ Set XX15+2 = XX15+2 / 2
                        \            = normal_y / 2

 LSR A                  \ Set A = A / 2
                        \       = normal_z / 2

 DEX                    \ Decrement the scale factor in X

 BPL LL93+3             \ If we have more scaling to do, loop back up to the
                        \ first LSR above until the normal vector is scaled down

.LL94

 STA R                  \ Set R = normal_z

 LDA XX12+5             \ Set S = normal_z_sign
 STA S

 LDA XX18+6             \ Set Q = dot_nosev_lo
 STA Q

 LDA XX18+8             \ Set A = dot_nosev_sign

 JSR LL38               \ Set (S A) = (S R) + (A Q)
                        \           = normal_z + dot_nosev
                        \
                        \ setting the sign of the result in S

 BCS ovflw              \ If the addition overflowed, jump up to ovflw to divide
                        \ both the normal vector and dot products by 2 and try
                        \ again

 STA XX15+4             \ Set XX15(5 4) = (S A)
 LDA S                  \               = normal_z + dot_nosev
 STA XX15+5

 LDA XX15               \ Set R = normal_x
 STA R

 LDA XX12+1             \ Set S = normal_x_sign
 STA S

 LDA XX18               \ Set Q = dot_sidev_lo
 STA Q

 LDA XX18+2             \ Set A = dot_sidev_sign

 JSR LL38               \ Set (S A) = (S R) + (A Q)
                        \           = normal_x + dot_sidev
                        \
                        \ setting the sign of the result in S

 BCS ovflw              \ If the addition overflowed, jump up to ovflw to divide
                        \ both the normal vector and dot products by 2 and try
                        \ again

 STA XX15               \ Set XX15(1 0) = (S A)
 LDA S                  \               = normal_x + dot_sidev
 STA XX15+1

 LDA XX15+2             \ Set R = normal_y
 STA R

 LDA XX12+3             \ Set S = normal_y_sign
 STA S

 LDA XX18+3             \ Set Q = dot_roofv_lo
 STA Q

 LDA XX18+5             \ Set A = dot_roofv_sign

 JSR LL38               \ Set (S A) = (S R) + (A Q)
                        \           = normal_y + dot_roofv

 BCS ovflw              \ If the addition overflowed, jump up to ovflw to divide
                        \ both the normal vector and dot products by 2 and try
                        \ again

 STA XX15+2             \ Set XX15(3 2) = (S A)
 LDA S                  \               = normal_y + dot_roofv
 STA XX15+3

.LL89

                        \ When we get here, we have set up the following:
                        \
                        \   XX15(1 0) = normal_x + dot_sidev
                        \             = normal_x + [x y z] . sidev
                        \
                        \   XX15(3 2) = normal_y + dot_roofv
                        \             = normal_y + [x y z] . roofv
                        \
                        \   XX15(5 4) = normal_z + dot_nosev
                        \             = normal_z + [x y z] . nosev
                        \
                        \ and:
                        \
                        \   XX12(1 0) = (normal_x_sign normal_x)
                        \
                        \   XX12(3 2) = (normal_y_sign normal_y)
                        \
                        \   XX12(5 4) = (normal_z_sign normal_z)
                        \
                        \ We now calculate the dot product XX12 . XX15 to tell
                        \ us whether or not this face is visible

 LDA XX12               \ Set Q = XX12
 STA Q

 LDA XX15               \ Set A = XX15

 JSR FMLTU              \ Set T = A * Q / 256
 STA T                  \       = XX15 * XX12 / 256

 LDA XX12+1             \ Set S = sign of XX15(1 0) * XX12(1 0), so:
 EOR XX15+1             \
 STA S                  \   (S T) = XX15(1 0) * XX12(1 0) / 256

 LDA XX12+2             \ Set Q = XX12+2
 STA Q

 LDA XX15+2             \ Set A = XX15+2

 JSR FMLTU              \ Set Q = A * Q
 STA Q                  \       = XX15+2 * XX12+2 / 256

 LDA T                  \ Set T = R, so now:
 STA R                  \
                        \   (S R) = XX15(1 0) * XX12(1 0) / 256

 LDA XX12+3             \ Set A = sign of XX15+3 * XX12+3, so:
 EOR XX15+3             \
                        \   (A Q) = XX15(3 2) * XX12(3 2) / 256

 JSR LL38               \ Set (S T) = (S R) + (A Q)
 STA T                  \           =   XX15(1 0) * XX12(1 0) / 256
                        \             + XX15(3 2) * XX12(3 2) / 256

 LDA XX12+4             \ Set Q = XX12+4
 STA Q

 LDA XX15+4             \ Set A = XX15+4

 JSR FMLTU              \ Set Q = A * Q
 STA Q                  \       = XX15+4 * XX12+4 / 256

 LDA T                  \ Set T = R, so now:
 STA R                  \
                        \   (S R) =   XX15(1 0) * XX12(1 0) / 256
                        \           + XX15(3 2) * XX12(3 2) / 256

 LDA XX15+5             \ Set A = sign of XX15+5 * XX12+5, so:
 EOR XX12+5             \
                        \   (A Q) = XX15(5 4) * XX12(5 4) / 256

 JSR LL38               \ Set (S A) = (S R) + (A Q)
                        \           =   XX15(1 0) * XX12(1 0) / 256
                        \             + XX15(3 2) * XX12(3 2) / 256
                        \             + XX15(5 4) * XX12(5 4) / 256

 PHA                    \ Push the result A onto the stack, so the stack now
                        \ contains the dot product XX12 . XX15

 TYA                    \ Set X = Y / 4
 LSR A                  \       = the number of this face * 4 /4
 LSR A                  \       = the number of this face
 TAX

 PLA                    \ Pull the dot product off the stack into A

 BIT S                  \ If bit 7 of S is set, i.e. the dot product is
 BMI P%+4               \ negative, then this face is visible as its normal is
                        \ pointing towards us, so skip the following instruction

 LDA #0                 \ Otherwise the face is not visible, so set A = 0 so we
                        \ can store this to mean "not visible"

 STA XX2,X              \ Store the face's visibility in the X-th byte of XX2

 INY                    \ Above we incremented Y to point to byte #3, so this
                        \ increments Y to point to byte #4, i.e. byte #0 of the
                        \ next face

.LL88

 CPY XX20               \ If Y >= XX20, the number of faces * 4, jump down to
 BCS LL42               \ LL42 to move on to the

 JMP LL86               \ Otherwise loop back to LL86 to work out the visibility
                        \ of the next face

\ ******************************************************************************
\
\       Name: LL9 (Part 6 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Calculate the visibility of each of the ship's vertices
\  Deep dive: Drawing ships
\             Calculating vertex coordinates
\
\ ------------------------------------------------------------------------------
\
\ This section calculates the visibility of each of the ship's vertices, and for
\ those that are visible, it starts the process of calculating the screen
\ coordinates of each vertex
\
\ ******************************************************************************

.LL42

                        \ The first task is to set up the inverse matrix, ready
                        \ for us to send to the dot product routine at LL51.
                        \ Back up in part 3, we set up the following variables:
                        \
                        \   * XX16(1 0) = sidev_x
                        \   * XX16(3 2) = sidev_y
                        \   * XX16(5 4) = sidev_z
                        \
                        \   * XX16(7 6) = roofv_x
                        \   * XX16(9 8) = roofv_y
                        \   * XX16(11 10) = roofv_z
                        \
                        \   * XX16(13 12) = nosev_x
                        \   * XX16(15 14) = nosev_y
                        \   * XX16(17 16) = nosev_z
                        \
                        \ and we then scaled the vectors to give the following:
                        \
                        \   * XX16   = scaled |sidev_x|
                        \   * XX16+2 = scaled |sidev_y|
                        \   * XX16+4 = scaled |sidev_z|
                        \
                        \   * XX16+6  = scaled |roofv_x|
                        \   * XX16+8  = scaled |roofv_y|
                        \   * XX16+10 = scaled |roofv_z|
                        \
                        \   * XX16+12 = scaled |nosev_x|
                        \   * XX16+14 = scaled |nosev_y|
                        \   * XX16+16 = scaled |nosev_z|
                        \
                        \ We now need to rearrange these locations so they
                        \ effectively transpose the matrix into its inverse

 LDY XX16+2             \ Set XX16+2 = XX16+6 = scaled |roofv_x|
 LDX XX16+3             \ Set XX16+3 = XX16+7 = roofv_x_hi
 LDA XX16+6             \ Set XX16+6 = XX16+2 = scaled |sidev_y|
 STA XX16+2             \ Set XX16+7 = XX16+3 = sidev_y_hi
 LDA XX16+7
 STA XX16+3
 STY XX16+6
 STX XX16+7

 LDY XX16+4             \ Set XX16+4 = XX16+12 = scaled |nosev_x|
 LDX XX16+5             \ Set XX16+5 = XX16+13 = nosev_x_hi
 LDA XX16+12            \ Set XX16+12 = XX16+4 = scaled |sidev_z|
 STA XX16+4             \ Set XX16+13 = XX16+5 = sidev_z_hi
 LDA XX16+13
 STA XX16+5
 STY XX16+12
 STX XX16+13

 LDY XX16+10            \ Set XX16+10 = XX16+14 = scaled |nosev_y|
 LDX XX16+11            \ Set XX16+11 = XX16+15 = nosev_y_hi
 LDA XX16+14            \ Set XX16+14 = XX16+10 = scaled |roofv_z|
 STA XX16+10            \ Set XX16+15 = XX16+11 = roofv_z
 LDA XX16+15
 STA XX16+11
 STY XX16+14
 STX XX16+15

                        \ So now we have the following sign-magnitude variables
                        \ containing parts of the scaled orientation vectors:
                        \
                        \   XX16(1 0)   = scaled sidev_x
                        \   XX16(3 2)   = scaled roofv_x
                        \   XX16(5 4)   = scaled nosev_x
                        \
                        \   XX16(7 6)   = scaled sidev_y
                        \   XX16(9 8)   = scaled roofv_y
                        \   XX16(11 10) = scaled nosev_y
                        \
                        \   XX16(13 12) = scaled sidev_z
                        \   XX16(15 14) = scaled roofv_z
                        \   XX16(17 16) = scaled nosev_z
                        \
                        \ which is what we want, as the various vectors are now
                        \ arranged so we can use LL51 to multiply by the
                        \ transpose (i.e. the inverse of the matrix)

 LDY #8                 \ Fetch byte #8 of the ship's blueprint, which is the
 LDA (XX0),Y            \ number of vertices * 8, and store it in XX20
 STA XX20

                        \ We now set V(1 0) = XX0(1 0) + 20, so V(1 0) points
                        \ to byte #20 of the ship's blueprint, which is always
                        \ where the vertex data starts (i.e. just after the 20
                        \ byte block that define the ship's characteristics)

 LDA XX0                \ We start with the low bytes
 CLC
 ADC #20
 STA V

 LDA XX0+1              \ And then do the high bytes
 ADC #0
 STA V+1

 LDY #0                 \ We are about to step through all the vertices, using
                        \ Y as a counter. There are six data bytes for each
                        \ vertex, so we will increment Y by 6 for each iteration
                        \ so it can act as an offset from V(1 0) to the current
                        \ vertex's data

 STY CNT                \ Set CNT = 0, which we will use as a pointer to the
                        \ heap at XX3, starting it at zero so the heap starts
                        \ out empty

.LL48

 STY XX17               \ Set XX17 = Y, so XX17 now contains the offset of the
                        \ current vertex's data

 LDA (V),Y              \ Fetch byte #0 for this vertex into XX15, so:
 STA XX15               \
                        \   XX15 = magnitude of the vertex's x-coordinate

 INY                    \ Increment Y to point to byte #1

 LDA (V),Y              \ Fetch byte #1 for this vertex into XX15+2, so:
 STA XX15+2             \
                        \   XX15+2 = magnitude of the vertex's y-coordinate

 INY                    \ Increment Y to point to byte #2

 LDA (V),Y              \ Fetch byte #2 for this vertex into XX15+4, so:
 STA XX15+4             \
                        \   XX15+4 = magnitude of the vertex's z-coordinate

 INY                    \ Increment Y to point to byte #3

 LDA (V),Y              \ Fetch byte #3 for this vertex into T, so:
 STA T                  \
                        \   T = %xyz vvvvv, where:
                        \
                        \     * Bits 0-4 = visibility distance, beyond which the
                        \                  vertex is not shown
                        \
                        \     * Bits 7-5 = the sign bits of x, y and z

 AND #%00011111         \ Extract bits 0-4 to get the visibility distance

 CMP XX4                \ If XX4 > the visibility distance, where XX4 contains
 BCC LL49-3             \ the ship's z-distance reduced to 0-31 (which we set in
                        \ part 2), then this vertex is too far away to be
                        \ visible, so jump down to LL50 (via the JMP instruction
                        \ in LL49-3) to move on to the next vertex

 INY                    \ Increment Y to point to byte #4

 LDA (V),Y              \ Fetch byte #4 for this vertex into P, so:
 STA P                  \
                        \  P = %ffff ffff, where:
                        \
                        \    * Bits 0-3 = the number of face 1
                        \
                        \    * Bits 4-7 = the number of face 2

 AND #%00001111         \ Extract the number of face 1 into X
 TAX

 LDA XX2,X              \ If XX2+X is non-zero then we decided in part 5 that
 BNE LL49               \ face 1 is visible, so jump to LL49

 LDA P                  \ Fetch byte #4 for this vertex into A

 LSR A                  \ Shift right four times to extract the number of face 2
 LSR A                  \ from bits 4-7 into X
 LSR A
 LSR A
 TAX

 LDA XX2,X              \ If XX2+X is non-zero then we decided in part 5 that
 BNE LL49               \ face 2 is visible, so jump to LL49

 INY                    \ Increment Y to point to byte #5

 LDA (V),Y              \ Fetch byte #5 for this vertex into P, so:
 STA P                  \
                        \  P = %ffff ffff, where:
                        \
                        \    * Bits 0-3 = the number of face 3
                        \
                        \    * Bits 4-7 = the number of face 4

 AND #%00001111         \ Extract the number of face 1 into X
 TAX

 LDA XX2,X              \ If XX2+X is non-zero then we decided in part 5 that
 BNE LL49               \ face 3 is visible, so jump to LL49

 LDA P                  \ Fetch byte #5 for this vertex into A

 LSR A                  \ Shift right four times to extract the number of face 4
 LSR A                  \ from bits 4-7 into X
 LSR A
 LSR A
 TAX

 LDA XX2,X              \ If XX2+X is non-zero then we decided in part 5 that
 BNE LL49               \ face 4 is visible, so jump to LL49

 JMP LL50               \ If we get here then none of the four faces associated
                        \ with this vertex are visible, so this vertex is also
                        \ not visible, so jump to LL50 to move on to the next
                        \ vertex

.LL49

 LDA T                  \ Fetch byte #5 for this vertex into A and store it, so
 STA XX15+1             \ XX15+1 now has the sign of the vertex's x-coordinate

 ASL A                  \ Shift A left and store it, so XX15+3 now has the sign
 STA XX15+3             \ of the vertex's y-coordinate

 ASL A                  \ Shift A left and store it, so XX15+5 now has the sign
 STA XX15+5             \ of the vertex's z-coordinate

                        \ By this point we have the following:
                        \
                        \   XX15(1 0) = vertex x-coordinate
                        \   XX15(3 2) = vertex y-coordinate
                        \   XX15(5 4) = vertex z-coordinate
                        \
                        \   XX16(1 0)   = scaled sidev_x
                        \   XX16(3 2)   = scaled roofv_x
                        \   XX16(5 4)   = scaled nosev_x
                        \
                        \   XX16(7 6)   = scaled sidev_y
                        \   XX16(9 8)   = scaled roofv_y
                        \   XX16(11 10) = scaled nosev_y
                        \
                        \   XX16(13 12) = scaled sidev_z
                        \   XX16(15 14) = scaled roofv_z
                        \   XX16(17 16) = scaled nosev_z

 JSR LL51               \ Call LL51 to set XX12 to the dot products of XX15 and
                        \ XX16, as follows:
                        \
                        \   XX12(1 0) = [ x y z ] . [ sidev_x roofv_x nosev_x ]
                        \
                        \   XX12(3 2) = [ x y z ] . [ sidev_y roofv_y nosev_y ]
                        \
                        \   XX12(5 4) = [ x y z ] . [ sidev_z roofv_z nosev_z ]
                        \
                        \ XX12 contains the vector from the ship's centre to
                        \ the vertex, transformed from the orientation vector
                        \ space to the universe orientated around our ship. So
                        \ we can refer to this vector below, let's call it
                        \ vertv, so:
                        \
                        \   vertv_x = [ x y z ] . [ sidev_x roofv_x nosev_x ]
                        \
                        \   vertv_y = [ x y z ] . [ sidev_y roofv_y nosev_y ]
                        \
                        \   vertv_z = [ x y z ] . [ sidev_z roofv_z nosev_z ]
                        \
                        \ To finish the calculation, we now want to calculate:
                        \
                        \   vertv + [ x y z ]
                        \
                        \ So let's start with the vertv_x + x

 LDA XX1+2              \ Set A = x_sign of the ship's location

 STA XX15+2             \ Set XX15+2 = x_sign

 EOR XX12+1             \ If the sign of x_sign * the sign of vertv_x is
 BMI LL52               \ negative (i.e. they have different signs), skip to
                        \ LL52

 CLC                    \ Set XX15(2 1 0) = XX1(2 1 0) + XX12(1 0)
 LDA XX12               \                 = (x_sign x_hi x_lo) + vertv_x
 ADC XX1                \
 STA XX15               \ Starting with the low bytes

 LDA XX1+1              \ And then doing the high bytes (we can add 0 here as
 ADC #0                 \ we know the sign byte of vertv_x is 0)
 STA XX15+1

 JMP LL53               \ We've added the x-coordinates, so jump to LL53 to do
                        \ the y-coordinates

.LL52

                        \ If we get here then x_sign and vertv_x have different
                        \ signs, so we need to subtract them to get the result

 LDA XX1                \ Set XX15(2 1 0) = XX1(2 1 0) - XX12(1 0)
 SEC                    \                 = (x_sign x_hi x_lo) - vertv_x
 SBC XX12               \
 STA XX15               \ Starting with the low bytes

 LDA XX1+1              \ And then doing the high bytes (we can subtract 0 here
 SBC #0                 \ as we know the sign byte of vertv_x is 0)
 STA XX15+1

 BCS LL53               \ If the subtraction didn't underflow, then the sign of
                        \ the result is the same sign as x_sign, and that's what
                        \ we want, so we can jump down to LL53 to do the
                        \ y-coordinates

 EOR #%11111111         \ Otherwise we need to negate the result using two's
 STA XX15+1             \ complement, so first we flip the bits of the high byte

 LDA #1                 \ And then subtract the low byte from 1
 SBC XX15
 STA XX15

 BCC P%+4               \ If the above subtraction underflowed then we need to
 INC XX15+1             \ bump the high byte of the result up by 1

 LDA XX15+2             \ And now we flip the sign of the result to get the
 EOR #%10000000         \ correct result
 STA XX15+2

.LL53

                        \ Now for the y-coordinates, vertv_y + y

 LDA XX1+5              \ Set A = y_sign of the ship's location

 STA XX15+5             \ Set XX15+5 = y_sign

 EOR XX12+3             \ If the sign of y_sign * the sign of vertv_y is
 BMI LL54               \ negative (i.e. they have different signs), skip to
                        \ LL54

 CLC                    \ Set XX15(5 4 3) = XX1(5 4 3) + XX12(3 2)
 LDA XX12+2             \                 = (y_sign y_hi y_lo) + vertv_y
 ADC XX1+3              \
 STA XX15+3             \ Starting with the low bytes

 LDA XX1+4              \ And then doing the high bytes (we can add 0 here as
 ADC #0                 \ we know the sign byte of vertv_y is 0)
 STA XX15+4

 JMP LL55               \ We've added the y-coordinates, so jump to LL55 to do
                        \ the z-coordinates

.LL54

                        \ If we get here then y_sign and vertv_y have different
                        \ signs, so we need to subtract them to get the result

 LDA XX1+3              \ Set XX15(5 4 3) = XX1(5 4 3) - XX12(3 2)
 SEC                    \                 = (y_sign y_hi y_lo) - vertv_y
 SBC XX12+2             \
 STA XX15+3             \ Starting with the low bytes

 LDA XX1+4              \ And then doing the high bytes (we can subtract 0 here
 SBC #0                 \ as we know the sign byte of vertv_z is 0)
 STA XX15+4

 BCS LL55               \ If the subtraction didn't underflow, then the sign of
                        \ the result is the same sign as y_sign, and that's what
                        \ we want, so we can jump down to LL55 to do the
                        \ z-coordinates

 EOR #%11111111         \ Otherwise we need to negate the result using two's
 STA XX15+4             \ complement, so first we flip the bits of the high byte

 LDA XX15+3             \ And then flip the bits of the low byte and add 1
 EOR #%11111111
 ADC #1
 STA XX15+3

 LDA XX15+5             \ And now we flip the sign of the result to get the
 EOR #%10000000         \ correct result
 STA XX15+5

 BCC LL55               \ If the above subtraction underflowed then we need to
 INC XX15+4             \ bump the high byte of the result up by 1

.LL55

                        \ Now for the z-coordinates, vertv_z + z

 LDA XX12+5             \ If vertv_z_hi is negative, jump down to LL56
 BMI LL56

 LDA XX12+4             \ Set (U T) = XX1(7 6) + XX12(5 4)
 CLC                    \           = (z_hi z_lo) + vertv_z
 ADC XX1+6              \
 STA T                  \ Starting with the low bytes

 LDA XX1+7              \ And then doing the high bytes (we can add 0 here as
 ADC #0                 \ we know the sign byte of vertv_y is 0)
 STA U

 JMP LL57               \ We've added the z-coordinates, so jump to LL57

                        \ The adding process is continued in part 7, after a
                        \ couple of subroutines that we don't need quite yet

\ ******************************************************************************
\
\       Name: LL61
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (U R) = 256 * A / Q
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following, where A >= Q:
\
\   (U R) = 256 * A / Q
\
\ This is a sister routine to LL28, which does the division when A < Q.
\
\ ******************************************************************************

.LL61

 LDX Q                  \ If Q = 0, jump down to LL84 to return a division
 BEQ LL84               \ error

                        \ The LL28 routine returns A / Q, but only if A < Q. In
                        \ our case A >= Q, but we still want to use the LL28
                        \ routine, so we halve A until it's less than Q, call
                        \ the division routine, and then double A by the same
                        \ number of times

 LDX #0                 \ Set X = 0 to count the number of times we halve A

.LL63

 LSR A                  \ Halve A by shifting right

 INX                    \ Increment X

 CMP Q                  \ If A >= Q, loop back to LL63 to halve it again
 BCS LL63

 STX S                  \ Otherwise store the number of times we halved A in S

 JSR LL28               \ Call LL28 to calculate:
                        \
                        \   R = 256 * A / Q
                        \
                        \ which we can do now as A < Q

 LDX S                  \ Otherwise restore the number of times we halved A
                        \ above into X

 LDA R                  \ Set A = our division result

.LL64

 ASL A                  \ Double (U A) by shifting left
 ROL U

 BMI LL84               \ If bit 7 of U is set, the doubling has overflowed, so
                        \ jump to LL84 to return a division error

 DEX                    \ Decrement X

 BNE LL64               \ If X is not yet zero then we haven't done as many
                        \ doublings as we did halvings earlier, so loop back for
                        \ another doubling

 STA R                  \ Store the low byte of the division result in R

 RTS                    \ Return from the subroutine

.LL84

 LDA #50                \ If we get here then either we tried to divide by 0, or
 STA R                  \ the result overflowed, so we set U and R to 50
 STA U

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL62
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate 128 - (U R)
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following for a positive sign-magnitude number (U R):
\
\   128 - (U R)
\
\ and then store the result, low byte then high byte, on the end of the heap at
\ XX3, where X points to the first free byte on the heap. Return by jumping down
\ to LL66.
\
\ Returns:
\
\   X                   X is incremented by 1
\
\ ******************************************************************************

.LL62

 LDA #128               \ Calculate 128 - (U R), starting with the low bytes
 SEC
 SBC R

 STA XX3,X              \ Store the low byte of the result in the X-th byte of
                        \ the heap at XX3

 INX                    \ Increment the heap pointer in X to point to the next
                        \ byte

 LDA #0                 \ And then subtract the high bytes
 SBC U

 STA XX3,X              \ Store the low byte of the result in the X-th byte of
                        \ the heap at XX3

 JMP LL66               \ Jump down to LL66

\ ******************************************************************************
\
\       Name: LL9 (Part 7 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Calculate the visibility of each of the ship's vertices
\  Deep dive: Drawing ships
\             Calculating vertex coordinates
\
\ ------------------------------------------------------------------------------
\
\ This section continues the coordinate adding from part 6 by finishing off the
\ calculation that we started above:
\
\                      [ sidev_x roofv_x nosev_x ]   [ x ]   [ x ]
\   vector to vertex = [ sidev_y roofv_y nosev_y ] . [ y ] + [ y ]
\                      [ sidev_z roofv_z nosev_z ]   [ z ]   [ z ]
\
\ The gets stored as follows, in sign-magnitude values with the magnitudes
\ fitting into the low bytes:
\
\   XX15(2 0)           [ x y z ] . [ sidev_x roofv_x nosev_x ] + [ x y z ]
\
\   XX15(5 3)           [ x y z ] . [ sidev_y roofv_y nosev_y ] + [ x y z ]
\
\   (U T)               [ x y z ] . [ sidev_z roofv_z nosev_z ] + [ x y z ]
\
\ Finally, because this vector is from our ship to the vertex, and we are at the
\ origin, this vector is the same as the coordinates of the vertex. In other
\ words, we have just worked out:
\
\   XX15(2 0)           x-coordinate of the current vertex
\
\   XX15(5 3)           y-coordinate of the current vertex
\
\   (U T)               z-coordinate of the current vertex
\
\ ******************************************************************************

.LL56

 LDA XX1+6              \ Set (U T) = XX1(7 6) - XX12(5 4)
 SEC                    \           = (z_hi z_lo) - vertv_z
 SBC XX12+4             \
 STA T                  \ Starting with the low bytes

 LDA XX1+7              \ And then doing the high bytes (we can subtract 0 here
 SBC #0                 \ as we know the sign byte of vertv_z is 0)
 STA U

 BCC LL140              \ If the subtraction just underflowed, skip to LL140 to
                        \ set (U T) to the minimum value of 4

 BNE LL57               \ If U is non-zero, jump down to LL57

 LDA T                  \ If T >= 4, jump down to LL57
 CMP #4
 BCS LL57

.LL140

 LDA #0                 \ If we get here then either (U T) < 4 or the
 STA U                  \ subtraction underflowed, so set (U T) = 4
 LDA #4
 STA T

.LL57

                        \ By this point we have our results, so now to scale
                        \ the 16-bit results down into 8-bit values

 LDA U                  \ If the high bytes of the result are all zero, we are
 ORA XX15+1             \ done, so jump down to LL60 for the next stage
 ORA XX15+4
 BEQ LL60

 LSR XX15+1             \ Shift XX15(1 0) to the right
 ROR XX15

 LSR XX15+4             \ Shift XX15(4 3) to the right
 ROR XX15+3

 LSR U                  \ Shift (U T) to the right
 ROR T

 JMP LL57               \ Jump back to LL57 to see if we can shift the result
                        \ any more

\ ******************************************************************************
\
\       Name: LL9 (Part 8 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Calculate the screen coordinates of visible vertices
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This section projects the coordinate of the vertex into screen coordinates and
\ stores them on the XX3 heap. By the end of this part, the XX3 heap contains
\ four bytes containing the 16-bit screen coordinates of the current vertex, in
\ the order: x_lo, x_hi, y_lo, y_hi.
\
\ When we reach here, we are looping through the vertices, and we've just worked
\ out the coordinates of the vertex in our normal coordinate system, as follows
\
\   XX15(2 0)           (x_sign x_lo) = x-coordinate of the current vertex
\
\   XX15(5 3)           (y_sign y_lo) = y-coordinate of the current vertex
\
\   (U T)               (z_sign z_lo) = z-coordinate of the current vertex
\
\ Note that U is always zero when we get to this point, as the vertex is always
\ in front of us (so it has a positive z-coordinate, into the screen).
\
\ Other entry points:
\
\   LL70+1              Contains an RTS (as the first byte of an LDA
\                       instruction)
\
\ ******************************************************************************

.LL60

 LDA T                  \ Set Q = z_lo
 STA Q

 LDA XX15               \ Set A = x_lo

 CMP Q                  \ If x_lo < z_lo jump to LL69
 BCC LL69

 JSR LL61               \ Call LL61 to calculate:
                        \
                        \   (U R) = 256 * A / Q
                        \         = 256 * x / z
                        \
                        \ which we can do as x >= z

 JMP LL65               \ Jump to LL65 to skip the division for x_lo < z_lo

.LL69

 JSR LL28               \ Call LL28 to calculate:
                        \
                        \   R = 256 * A / Q
                        \     = 256 * x / z
                        \
                        \ Because x < z, the result fits into one byte, and we
                        \ also know that U = 0, so (U R) also contains the
                        \ result

.LL65

                        \ At this point we have:
                        \
                        \   (U R) = x / z
                        \
                        \ so (U R) contains the vertex's x-coordinate projected
                        \ on screen
                        \
                        \ The next task is to convert (U R) to a pixel screen
                        \ coordinate and stick it on the XX3 heap.
                        \
                        \ We start with the x-coordinate. To convert the
                        \ x-coordinate to a screen pixel we add 128, the
                        \ x-coordinate of the centre of the screen, because the
                        \ projected value is relative to an origin at the centre
                        \ of the screen, but the origin of the screen pixels is
                        \ at the top-left of the screen

 LDX CNT                \ Fetch the pointer to the end of the XX3 heap from CNT
                        \ into X

 LDA XX15+2             \ If x_sign is negative, jump up to LL62, which will
 BMI LL62               \ store 128 - (U R) on the XX3 heap and return by
                        \ jumping down to LL66 below

 LDA R                  \ Calculate 128 + (U R), starting with the low bytes
 CLC
 ADC #128

 STA XX3,X              \ Store the low byte of the result in the X-th byte of
                        \ the heap at XX3

 INX                    \ Increment the heap pointer in X to point to the next
                        \ byte

 LDA U                  \ And then add the high bytes
 ADC #0

 STA XX3,X              \ Store the high byte of the result in the X-th byte of
                        \ the heap at XX3

.LL66

                        \ We've just stored the screen x-coordinate of the
                        \ vertex on the XX3 heap, so now for the y-coordinate

 TXA                    \ Store the heap pointer in X on the stack (at this
 PHA                    \ it points to the last entry on the heap, not the first
                        \ free byte)

 LDA #0                 \ Set U = 0
 STA U

 LDA T                  \ Set Q = z_lo
 STA Q

 LDA XX15+3             \ Set A = y_lo

 CMP Q                  \ If y_lo < z_lo jump to LL67
 BCC LL67

 JSR LL61               \ Call LL61 to calculate:
                        \
                        \   (U R) = 256 * A / Q
                        \         = 256 * y / z
                        \
                        \ which we can do as y >= z

 JMP LL68               \ Jump to LL68 to skip the division for y_lo < z_lo

.LL70

                        \ This gets called from below when y_sign is negative

 LDA #Y                 \ Calculate #Y + (U R), starting with the low bytes
 CLC
 ADC R

 STA XX3,X              \ Store the low byte of the result in the X-th byte of
                        \ the heap at XX3

 INX                    \ Increment the heap pointer in X to point to the next
                        \ byte

 LDA #0                 \ And then add the high bytes
 ADC U

 STA XX3,X              \ Store the high byte of the result in the X-th byte of
                        \ the heap at XX3

 JMP LL50               \ Jump to LL68 to skip the division for y_lo < z_lo

.LL67

 JSR LL28               \ Call LL28 to calculate:
                        \
                        \   R = 256 * A / Q
                        \     = 256 * y / z
                        \
                        \ Because y < z, the result fits into one byte, and we
                        \ also know that U = 0, so (U R) also contains the
                        \ result

.LL68

                        \ At this point we have:
                        \
                        \   (U R) = y / z
                        \
                        \ so (U R) contains the vertex's y-coordinate projected
                        \ on screen
                        \
                        \ We now want to convert this to a screen y-coordinate
                        \ and stick it on the XX3 heap, much like we did with
                        \ the x-coordinate above. Again, we convert the
                        \ coordinate by adding or subtracting the y-coordinate
                        \ of the centre of the screen, which is in the constant
                        \ #Y, but this time we do the opposite, as a positive
                        \ projected y-coordinate, i.e. up the space y-axis and
                        \ up the screen, converts to a low y-coordinate, which
                        \ is the opposite way round to the x-coordinates

 PLA                    \ Restore the heap pointer from the stack into X
 TAX

 INX                    \ When we stored the heap pointer, it pointed to the
                        \ last entry on the heap, not the first free byte, so we
                        \ increment it so it does point to the next free byte

 LDA XX15+5             \ If y_sign is negative, jump up to LL70, which will
 BMI LL70               \ store #Y + (U R) on the XX3 heap and return by jumping
                        \ down to LL50 below

 LDA #Y                 \ Calculate #Y - (U R), starting with the low bytes
 SEC
 SBC R

 STA XX3,X              \ Store the low byte of the result in the X-th byte of
                        \ the heap at XX3

 INX                    \ Increment the heap pointer in X to point to the next
                        \ byte

 LDA #0                 \ And then subtract the high bytes
 SBC U

 STA XX3,X              \ Store the high byte of the result in the X-th byte of
                        \ the heap at XX3

.LL50

                        \ By the time we get here, the XX3 heap contains four
                        \ bytes containing the screen coordinates of the current
                        \ vertex, in the order: x_lo, x_hi, y_lo, y_hi

 CLC                    \ Set CNT = CNT + 4, so the heap pointer points to the
 LDA CNT                \ next free byte on the heap
 ADC #4
 STA CNT

 LDA XX17               \ Set A to the offset of the current vertex's data,
                        \ which we set in part 6

 ADC #6                 \ Set Y = A + 6, so Y now points to the data for the
 TAY                    \ next vertex

 BCS LL72               \ If the addition just overflowed, meaning we just tried
                        \ to access vertex #43, jump to LL72, as the maximum
                        \ number of vertices allowed is 42

 CMP XX20               \ If Y >= number of vertices * 6 (which we stored in
 BCS LL72               \ XX20 in part 6), jump to LL72, as we have processed
                        \ all the vertices for this ship

 JMP LL48               \ Loop back to LL48 in part 6 to calculate visibility
                        \ and screen coordinates for the next vertex

\ ******************************************************************************
\
\       Name: LL9 (Part 9 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Draw laser beams if the ship is firing its laser at us
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This part sets things up so we can loop through the edges in the next part. It
\ also adds a line to the ship line heap, if the ship is firing at us.
\
\ When we get here, the heap at XX3 contains all the visible vertex screen
\ coordinates.
\
\ ******************************************************************************

.LL72

 LDA XX1+31             \ If bit 5 of the ship's byte #31 is clear, then the
 AND #%00100000         \ ship is not currently exploding, so jump down to EE31
 BEQ EE31

 LDA XX1+31             \ The ship is exploding, so set bit 3 of the ship's byte
 ORA #8                 \ #31 to denote that we are drawing something on-screen
 STA XX1+31             \ for this ship

                        \ --- Original Acornsoft code removed: ---------------->

\ JMP DOEXP             \ Jump to DOEXP to display the explosion cloud,
\                       \ returning from the subroutine using a tail call

                        \ --- And replaced by: -------------------------------->

 JMP TT48               \ AJD

                        \ --- End of replacement ------------------------------>

.EE31

 LDA #%00001000         \ If bit 3 of the ship's byte #31 is clear, then there
 BIT XX1+31             \ is nothing already being shown for this ship, so skip
 BEQ LL74               \ to LL74 as we don't need to erase anything from the
                        \ screen

 JSR LL155              \ Otherwise call LL155 to draw the existing ship, which
                        \ removes it from the screen

 LDA #%00001000         \ Set bit 3 of A so the next instruction sets bit 3 of
                        \ the ship's byte #31 to denote that we are drawing
                        \ something on-screen for this ship

.LL74

 ORA XX1+31             \ Apply bit 3 of A to the ship's byte #31, so if there
 STA XX1+31             \ was no ship already on screen, the bit is clear,
                        \ otherwise it is set

 LDY #9                 \ Fetch byte #9 of the ship's blueprint, which is the
 LDA (XX0),Y            \ number of edges, and store it in XX20
 STA XX20

 LDY #0                 \ We are about to step through all the edges, using Y
                        \ as a counter

 STY U                  \ Set U = 0 (though we increment it to 1 below)

 STY XX17               \ Set XX17 = 0, which we are going to use as a counter
                        \ for stepping through the ship's edges

 INC U                  \ We are going to start calculating the lines we need to
                        \ draw for this ship, and will store them in the ship
                        \ line heap, using U to point to the end of the heap, so
                        \ we start by setting U = 1

 BIT XX1+31             \ If bit 6 of the ship's byte #31 is clear, then the
 BVC LL170              \ ship is not firing its lasers, so jump to LL170 to
                        \ skip the drawing of laser lines

                        \ The ship is firing its laser at us, so we need to draw
                        \ the laser lines

 LDA XX1+31             \ Clear bit 6 of the ship's byte #31 so the ship doesn't
 AND #%10111111         \ keep firing endlessly
 STA XX1+31

 LDY #6                 \ Fetch byte #6 of the ship's blueprint, which is the
 LDA (XX0),Y            \ number * 4 of the vertex where the ship has its lasers

 TAY                    \ Put the vertex number into Y, where it can act as an
                        \ index into list of vertex screen coordinates we added
                        \ to the XX3 heap

 LDX XX3,Y              \ Fetch the x_lo coordinate of the laser vertex from the
 STX XX15               \ XX3 heap into XX15

 INX                    \ If X = 255 then the laser vertex is not visible, as
 BEQ LL170              \ the value we stored in part 2 wasn't overwritten by
                        \ the vertex calculation in part 6 and 7, so jump to
                        \ LL170 to skip drawing the laser lines

                        \ We now build a laser beam from the ship's laser vertex
                        \ towards our ship, as follows:
                        \
                        \   XX15(1 0) = laser vertex x-coordinate
                        \
                        \   XX15(3 2) = laser vertex y-coordinate
                        \
                        \   XX15(5 4) = x-coordinate of the end of the beam
                        \
                        \   XX12(1 0) = y-coordinate of the end of the beam
                        \
                        \ The end of the laser beam will be set positioned to
                        \ look good, rather than being directly aimed at us, as
                        \ otherwise we would only see a flashing point of light
                        \ as they unleashed their attack

 LDX XX3+1,Y            \ Fetch the x_hi coordinate of the laser vertex from the
 STX XX15+1             \ XX3 heap into XX15+1

 INX                    \ If X = 255 then the laser vertex is not visible, as
 BEQ LL170              \ the value we stored in part 2 wasn't overwritten by
                        \ a vertex calculation in part 6 and 7, so jump to LL170
                        \ to skip drawing the laser beam

 LDX XX3+2,Y            \ Fetch the y_lo coordinate of the laser vertex from the
 STX XX15+2             \ XX3 heap into XX15+2

 LDX XX3+3,Y            \ Fetch the y_hi coordinate of the laser vertex from the
 STX XX15+3             \ XX3 heap into XX15+3

 LDA #0                 \ Set XX15(5 4) = 0, so their laser beam fires to the
 STA XX15+4             \ left edge of the screen
 STA XX15+5

 STA XX12+1             \ Set XX12(1 0) = the ship's z_lo coordinate, which will
 LDA XX1+6              \ effectively make the vertical position of the end of
 STA XX12               \ the laser beam move around as the ship moves in space

 LDA XX1+2              \ If the ship's x_sign is positive, skip the next
 BPL P%+4               \ instruction

 DEC XX15+4             \ The ship's x_sign is negative (i.e. it's on the left
                        \ side of the screen), so switch the laser beam so it
                        \ goes to the right edge of the screen by decrementing
                        \ XX15(5 4) to 255

 JSR LL145              \ Call LL145 to see if the laser beam needs to be
                        \ clipped to fit on-screen, returning the clipped line's
                        \ end-points in (X1, Y1) and (X2, Y2)

 BCS LL170              \ If the C flag is set then the line is not visible on
                        \ screen, so jump to LL170 so we don't store this line
                        \ in the ship line heap

 LDY U                  \ Fetch the ship line heap pointer, which points to the
                        \ next free byte on the heap, into Y

 LDA XX15               \ Add X1 to the end of the heap
 STA (XX19),Y

 INY                    \ Increment the heap pointer

 LDA XX15+1             \ Add Y1 to the end of the heap
 STA (XX19),Y

 INY                    \ Increment the heap pointer

 LDA XX15+2             \ Add X2 to the end of the heap
 STA (XX19),Y

 INY                    \ Increment the heap pointer

 LDA XX15+3             \ Add Y2 to the end of the heap
 STA (XX19),Y

 INY                    \ Increment the heap pointer

 STY U                  \ Store the updated ship line heap pointer in U

\ ******************************************************************************
\
\       Name: LL9 (Part 10 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Calculate the visibility of each of the ship's edges
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This part calculates which edges are visible - in other words, which lines we
\ should draw - and clips them to fit on the screen.
\
\ When we get here, the heap at XX3 contains all the visible vertex screen
\ coordinates.
\
\ ******************************************************************************

.LL170

 LDY #3                 \ Fetch byte #3 of the ship's blueprint, which contains
 CLC                    \ the low byte of the offset to the edges data
 LDA (XX0),Y

 ADC XX0                \ Set V = low byte edges offset + XX0
 STA V

 LDY #16                \ Fetch byte #16 of the ship's blueprint, which contains
 LDA (XX0),Y            \ the high byte of the offset to the edges data

 ADC XX0+1              \ Set V+1 = high byte edges offset + XX0+1
 STA V+1                \
                        \ So V(1 0) now points to the start of the edges data
                        \ for this ship

 LDY #5                 \ Fetch byte #5 of the ship's blueprint, which contains
 LDA (XX0),Y            \ the maximum heap size for plotting the ship (which is
 STA T1                 \ 1 + 4 * the maximum number of visible edges) and store
                        \ it in T1

 LDY XX17               \ Set Y to the edge counter in XX17

.LL75

 LDA (V),Y              \ Fetch byte #0 for this edge, which contains the
                        \ visibility distance for this edge, beyond which the
                        \ edge is not shown

 CMP XX4                \ If XX4 > the visibility distance, where XX4 contains
 BCC LL79-3             \ the ship's z-distance reduced to 0-31 (which we set in
                        \ part 2), then this edge is too far away to be visible,
                        \ so jump down to LL78 (via LL79-3) to move on to the
                        \ next edge

 INY                    \ Increment Y to point to byte #1

 LDA (V),Y              \ Fetch byte #1 for this edge into A, so:
                        \
                        \   A = %ffff ffff, where:
                        \
                        \     * Bits 0-3 = the number of face 1
                        \
                        \     * Bits 4-7 = the number of face 2

 INY                    \ Increment Y to point to byte #2

 STA P                  \ Store byte #1 into P

 AND #%00001111         \ Extract the number of face 1 into X
 TAX

 LDA XX2,X              \ If XX2+X is non-zero then we decided in part 5 that
 BNE LL79               \ face 1 is visible, so jump to LL79

 LDA P                  \ Fetch byte #1 for this edge into A

 LSR A                  \ Shift right four times to extract the number of face 2
 LSR A                  \ from bits 4-7 into X
 LSR A
 LSR A
 TAX

 LDA XX2,X              \ If XX2+X is non-zero then we decided in part 5 that
 BNE LL79               \ face 2 is visible, so skip the following instruction

 JMP LL78               \ Face 2 is hidden, so jump to LL78

.LL79

                        \ We now build the screen line for this edge, as
                        \ follows:
                        \
                        \   XX15(1 0) = start x-coordinate
                        \
                        \   XX15(3 2) = start y-coordinate
                        \
                        \   XX15(5 4) = end x-coordinate
                        \
                        \   XX12(1 0) = end y-coordinate
                        \
                        \ We can then pass this to the line clipping routine
                        \ before storing the resulting line in the ship line
                        \ heap

 LDA (V),Y              \ Fetch byte #2 for this edge into X, which contains
 TAX                    \ the number of the vertex at the start of the edge

 INY                    \ Increment Y to point to byte #3

 LDA (V),Y              \ Fetch byte #3 for this edge into Q, which contains
 STA Q                  \ the number of the vertex at the end of the edge

 LDA XX3+1,X            \ Fetch the x_hi coordinate of the edge's start vertex
 STA XX15+1             \ from the XX3 heap into XX15+1

 LDA XX3,X              \ Fetch the x_lo coordinate of the edge's start vertex
 STA XX15               \ from the XX3 heap into XX15

 LDA XX3+2,X            \ Fetch the y_lo coordinate of the edge's start vertex
 STA XX15+2             \ from the XX3 heap into XX15+2

 LDA XX3+3,X            \ Fetch the y_hi coordinate of the edge's start vertex
 STA XX15+3             \ from the XX3 heap into XX15+3

 LDX Q                  \ Set X to the number of the vertex at the end of the
                        \ edge, which we stored in Q

 LDA XX3,X              \ Fetch the x_lo coordinate of the edge's end vertex
 STA XX15+4             \ from the XX3 heap into XX15+4

 LDA XX3+3,X            \ Fetch the y_hi coordinate of the edge's end vertex
 STA XX12+1             \ from the XX3 heap into XX11+1

 LDA XX3+2,X            \ Fetch the y_lo coordinate of the edge's end vertex
 STA XX12               \ from the XX3 heap into XX12

 LDA XX3+1,X            \ Fetch the x_hi coordinate of the edge's end vertex
 STA XX15+5             \ from the XX3 heap into XX15+5

 JSR LL147              \ Call LL147 to see if the new line segment needs to be
                        \ clipped to fit on-screen, returning the clipped line's
                        \ end-points in (X1, Y1) and (X2, Y2)

 BCS LL79-3             \ If the C flag is set then the line is not visible on
                        \ screen, so jump to LL78 (via LL79-3) so we don't store
                        \ this line in the ship line heap

 JMP LL80               \ Jump down to part 11 to draw this edge

\ ******************************************************************************
\
\       Name: LL145 (Part 1 of 4)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Clip line: Work out which end-points are on-screen, if any
\  Deep dive: Line-clipping
\             Extended screen coordinates
\
\ ------------------------------------------------------------------------------
\
\ This routine clips the line from (x1, y1) to (x2, y2) so it fits on-screen, or
\ returns an error if it can't be clipped to fit. The arguments are 16-bit
\ coordinates, and the clipped line is returned using 8-bit screen coordinates.
\
\ This part sets XX13 to reflect which of the two points are on-screen and
\ off-screen.
\
\ Arguments:
\
\   XX15(1 0)           x1 as a 16-bit coordinate (x1_hi x1_lo)
\
\   XX15(3 2)           y1 as a 16-bit coordinate (y1_hi y1_lo)
\
\   XX15(5 4)           x2 as a 16-bit coordinate (x2_hi x2_lo)
\
\   XX12(1 0)           y2 as a 16-bit coordinate (y2_hi y2_lo)
\
\ Returns:
\
\   (X1, Y1)            Screen coordinate of the start of the clipped line
\
\   (X2, Y2)            Screen coordinate of the end of the clipped line
\
\   C flag              Clear if the clipped line fits on-screen, set if it
\                       doesn't
\
\   XX13                The state of the original coordinates on-screen:
\
\                         * 0   = (x2, y2) on-screen
\
\                         * 95  = (x1, y1) on-screen,  (x2, y2) off-screen
\
\                         * 191 = (x1, y1) off-screen, (x2, y2) off-screen
\
\                       So XX13 is non-zero if the end of the line was clipped,
\                       meaning the next line sent to BLINE can't join onto the
\                       end but has to start a new segment
\
\   SWAP                The swap status of the returned coordinates:
\
\                         * &FF if we swapped the values of (x1, y1) and
\                           (x2, y2) as part of the clipping process
\
\                         * 0 if the coordinates are still in the same order
\
\   Y                   Y is preserved
\
\ Other entry points:
\
\   LL147               Don't initialise the values in SWAP or A
\
\ ******************************************************************************

.LL145

 LDA #0                 \ Set SWAP = 0
 STA SWAP

 LDA XX15+5             \ Set A = x2_hi

.LL147

 LDX #Y*2-1             \ Set Y2 = #Y * 2 - 1. The constant #Y is 96, the
                        \ y-coordinate of the mid-point of the space view, so
                        \ this sets Y2 to 191, the y-coordinate of the bottom
                        \ pixel row of the space view

 ORA XX12+1             \ If one or both of x2_hi and y2_hi are non-zero, jump
 BNE LL107              \ to LL107 to skip the following

 CPX XX12               \ If y2_lo > the y-coordinate of the bottom of screen
 BCC LL107              \ then (x2, y2) is off the bottom of the screen, so skip
                        \ the following instruction, leaving X at 191

 LDX #0                 \ Set X = 0

.LL107

 STX XX13               \ Set XX13 = X, so we have:
                        \
                        \   * XX13 = 0 if x2_hi = y2_hi = 0, y2_lo is on-screen
                        \
                        \   * XX13 = 191 if x2_hi or y2_hi are non-zero or y2_lo
                        \            is off the bottom of the screen
                        \
                        \ In other words, XX13 is 191 if (x2, y2) is off-screen,
                        \ otherwise it is 0

 LDA XX15+1             \ If one or both of x1_hi and y1_hi are non-zero, jump
 ORA XX15+3             \ jump to LL83
 BNE LL83

 LDA #Y*2-1             \ If y1_lo > the y-coordinate of the bottom of screen
 CMP XX15+2             \ then (x1, y1) is off the bottom of the screen, so jump
 BCC LL83               \ to LL83

                        \ If we get here, (x1, y1) is on-screen

 LDA XX13               \ If XX13 is non-zero, i.e. (x2, y2) is off-screen, jump
 BNE LL108              \ to LL108 to halve it before continuing at LL83

                        \ If we get here, the high bytes are all zero, which
                        \ means the x-coordinates are < 256 and therefore fit on
                        \ screen, and neither coordinate is off the bottom of
                        \ the screen. That means both coordinates are already on
                        \ screen, so we don't need to do any clipping, all we
                        \ need to do is move the low bytes into (X1, Y1) and
                        \ X2, Y2) and return

.LL146

                        \ If we get here then we have clipped our line to the
                        \ (if we had to clip it at all), so we move the low
                        \ bytes from (x1, y1) and (x2, y2) into (X1, Y1) and
                        \ (X2, Y2), remembering that they share locations with
                        \ XX15:
                        \
                        \   X1 = XX15
                        \   Y1 = XX15+1
                        \   X2 = XX15+2
                        \   Y2 = XX15+3
                        \
                        \ X1 already contains x1_lo, so now we do the rest

 LDA XX15+2             \ Set Y1 (aka XX15+1) = y1_lo
 STA XX15+1

 LDA XX15+4             \ Set X2 (aka XX15+2) = x2_lo
 STA XX15+2

 LDA XX12               \ Set Y2 (aka XX15+3) = y2_lo
 STA XX15+3

 CLC                    \ Clear the C flag as the clipped line fits on-screen

 RTS                    \ Return from the subroutine

.LL109

 SEC                    \ Set the C flag to indicate the clipped line does not
                        \ fit on-screen

 RTS                    \ Return from the subroutine

.LL108

 LSR XX13               \ If we get here then (x2, y2) is off-screen and XX13 is
                        \ 191, so shift XX13 right to halve it to 95

\ ******************************************************************************
\
\       Name: LL145 (Part 2 of 4)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Clip line: Work out if any part of the line is on-screen
\  Deep dive: Line-clipping
\             Extended screen coordinates
\
\ ------------------------------------------------------------------------------
\
\ This part does a number of tests to see if the line is on or off the screen.
\
\ If we get here then at least one of (x1, y1) and (x2, y2) is off-screen, with
\ XX13 set as follows:
\
\   * 0   = (x1, y1) off-screen, (x2, y2) on-screen
\
\   * 95  = (x1, y1) on-screen,  (x2, y2) off-screen
\
\   * 191 = (x1, y1) off-screen, (x2, y2) off-screen
\
\ where "off-screen" is defined as having a non-zero high byte in one of the
\ coordinates, or in the case of y-coordinates, having a low byte > 191, the
\ y-coordinate of the bottom of the space view.
\
\ ******************************************************************************

.LL83

 LDA XX13               \ If XX13 < 128 then only one of the points is on-screen
 BPL LL115              \ so jump down to LL115 to skip the checks of whether
                        \ both points are in the strips to the right or bottom
                        \ of the screen

                        \ If we get here, both points are off-screen

 LDA XX15+1             \ If both x1_hi and x2_hi have bit 7 set, jump to LL109
 AND XX15+5             \ to return from the subroutine with the C flag set, as
 BMI LL109              \ the entire line is above the top of the screen

 LDA XX15+3             \ If both y1_hi and y2_hi have bit 7 set, jump to LL109
 AND XX12+1             \ to return from the subroutine with the C flag set, as
 BMI LL109              \ the entire line is to the left of the screen

 LDX XX15+1             \ Set A = X = x1_hi - 1
 DEX
 TXA

 LDX XX15+5             \ Set XX12+2 = x2_hi - 1
 DEX
 STX XX12+2

 ORA XX12+2             \ If neither (x1_hi - 1) or (x2_hi - 1) have bit 7 set,
 BPL LL109              \ jump to LL109 to return from the subroutine with the C
                        \ flag set, as the line doesn't fit on-screen

 LDA XX15+2             \ If y1_lo < y-coordinate of screen bottom, clear the C
 CMP #Y*2               \ flag, otherwise set it

 LDA XX15+3             \ Set XX12+2 = y1_hi - (1 - C), so:
 SBC #0                 \
 STA XX12+2             \  * Set XX12+2 = y1_hi - 1 if y1_lo is on-screen
                        \  * Set XX12+2 = y1_hi     otherwise
                        \
                        \ We do this subtraction because we are only interested
                        \ in trying to move the points up by a screen if that
                        \ might move the point into the space view portion of
                        \ the screen, i.e. if y1_lo is on-screen

 LDA XX12               \ If y2_lo < y-coordinate of screen bottom, clear the C
 CMP #Y*2               \ flag, otherwise set it

 LDA XX12+1             \ Set XX12+2 = y2_hi - (1 - C), so:
 SBC #0                 \
                        \  * Set XX12+1 = y2_hi - 1 if y2_lo is on-screen
                        \  * Set XX12+1 = y2_hi     otherwise
                        \
                        \ We do this subtraction because we are only interested
                        \ in trying to move the points up by a screen if that
                        \ might move the point into the space view portion of
                        \ the screen, i.e. if y1_lo is on-screen

 ORA XX12+2             \ If neither XX12+1 or XX12+2 have bit 7 set, jump to
 BPL LL109              \ LL109 to return from the subroutine with the C flag
                        \ set, as the line doesn't fit on-screen

\ ******************************************************************************
\
\       Name: LL145 (Part 3 of 4)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Clip line: Calculate the line's gradient
\  Deep dive: Line-clipping
\             Extended screen coordinates
\
\ ******************************************************************************

.LL115

 TYA                    \ Store Y on the stack so we can preserve it through the
 PHA                    \ call to this subroutine

 LDA XX15+4             \ Set XX12+2 = x2_lo - x1_lo
 SEC
 SBC XX15
 STA XX12+2

 LDA XX15+5             \ Set XX12+3 = x2_hi - x1_hi
 SBC XX15+1
 STA XX12+3

 LDA XX12               \ Set XX12+4 = y2_lo - y1_lo
 SEC
 SBC XX15+2
 STA XX12+4

 LDA XX12+1             \ Set XX12+5 = y2_hi - y1_hi
 SBC XX15+3
 STA XX12+5

                        \ So we now have:
                        \
                        \   delta_x in XX12(3 2)
                        \   delta_y in XX12(5 4)
                        \
                        \ where the delta is (x1, y1) - (x2, y2))

 EOR XX12+3             \ Set S = the sign of delta_x * the sign of delta_y, so
 STA S                  \ if bit 7 of S is set, the deltas have different signs

 LDA XX12+5             \ If delta_y_hi is positive, jump down to LL110 to skip
 BPL LL110              \ the following

 LDA #0                 \ Otherwise flip the sign of delta_y to make it
 SEC                    \ positive, starting with the low bytes
 SBC XX12+4
 STA XX12+4

 LDA #0                 \ And then doing the high bytes, so now:
 SBC XX12+5             \
 STA XX12+5             \   XX12(5 4) = |delta_y|

.LL110

 LDA XX12+3             \ If delta_x_hi is positive, jump down to LL111 to skip
 BPL LL111              \ the following

 SEC                    \ Otherwise flip the sign of delta_x to make it
 LDA #0                 \ positive, starting with the low bytes
 SBC XX12+2
 STA XX12+2

 LDA #0                 \ And then doing the high bytes, so now:
 SBC XX12+3             \
                        \   (A XX12+2) = |delta_x|

.LL111

                        \ We now keep halving |delta_x| and |delta_y| until
                        \ both of them have zero in their high bytes

 TAX                    \ IF |delta_x_hi| is non-zero, skip the following
 BNE LL112

 LDX XX12+5             \ If |delta_y_hi| = 0, jump down to LL113 (as both
 BEQ LL113              \ |delta_x_hi| and |delta_y_hi| are 0)

.LL112

 LSR A                  \ Halve the value of delta_x in (A XX12+2)
 ROR XX12+2

 LSR XX12+5             \ Halve the value of delta_y XX12(5 4)
 ROR XX12+4

 JMP LL111              \ Loop back to LL111

.LL113

                        \ By now, the high bytes of both |delta_x| and |delta_y|
                        \ are zero

 STX T                  \ We know that X = 0 as that's what we tested with a BEQ
                        \ above, so this sets T = 0

 LDA XX12+2             \ If delta_x_lo < delta_y_lo, so our line is more
 CMP XX12+4             \ vertical than horizontal, jump to LL114
 BCC LL114

 STA Q                  \ Set Q = delta_x_lo

 LDA XX12+4             \ Set A = delta_y_lo

 JSR LL28               \ Call LL28 to calculate:
                        \
                        \   R = 256 * A / Q
                        \     = 256 * delta_y_lo / delta_x_lo

 JMP LL116              \ Jump to LL116, as we now have the line's gradient in R

.LL114

 LDA XX12+4             \ Set Q = delta_y_lo
 STA Q
 LDA XX12+2             \ Set A = delta_x_lo

 JSR LL28               \ Call LL28 to calculate:
                        \
                        \   R = 256 * A / Q
                        \     = 256 * delta_x_lo / delta_y_lo

 DEC T                  \ T was set to 0 above, so this sets T = &FF

\ ******************************************************************************
\
\       Name: LL145 (Part 4 of 4)
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Clip line: Call the routine in LL188 to do the actual clipping
\  Deep dive: Line-clipping
\             Extended screen coordinates
\
\ ------------------------------------------------------------------------------
\
\ This part sets things up to call the routine in LL188, which does the actual
\ clipping.
\
\ If we get here, then R has been set to the gradient of the line (x1, y1) to
\ (x2, y2), with T indicating the type of slope:
\
\   * 0   = it's more vertical than horizontal
\
\   * &FF = it's more horizontal than vertical
\
\ and XX13 has been set as follows:
\
\   * 0   = (x1, y1) off-screen, (x2, y2) on-screen
\
\   * 95  = (x1, y1) on-screen,  (x2, y2) off-screen
\
\   * 191 = (x1, y1) off-screen, (x2, y2) off-screen
\
\ ******************************************************************************

.LL116

 LDA R                  \ Store the gradient in XX12+2
 STA XX12+2

 LDA S                  \ Store the type of slope in XX12+3, bit 7 clear means
 STA XX12+3             \ top left to bottom right, bit 7 set means top right to
                        \ bottom left

 LDA XX13               \ If XX13 = 0, skip the following instruction
 BEQ LL138

 BPL LLX117             \ If XX13 is positive, it must be 95. This means
                        \ (x1, y1) is on-screen but (x2, y2) isn't, so we jump
                        \ to LLX117 to swap the (x1, y1) and (x2, y2)
                        \ coordinates around before doing the actual clipping,
                        \ because we need to clip (x2, y2) but the clipping
                        \ routine at LL118 only clips (x1, y1)

.LL138

                        \ If we get here, XX13 = 0 or 191, so (x1, y1) is
                        \ off-screen and needs clipping

 JSR LL118              \ Call LL118 to move (x1, y1) along the line onto the
                        \ screen, i.e. clip the line at the (x1, y1) end

 LDA XX13               \ If XX13 = 0, i.e. (x2, y2) is on-screen, jump down to
 BPL LL124              \ LL124 to return with a successfully clipped line

.LL117

                        \ If we get here, XX13 = 191 (both coordinates are
                        \ off-screen)

 LDA XX15+1             \ If either of x1_hi or y1_hi are non-zero, jump to
 ORA XX15+3             \ LL137 to return from the subroutine with the C flag
 BNE LL137              \ set, as the line doesn't fit on-screen

 LDA XX15+2             \ If y1_lo > y-coordinate of the bottom of the screen
 CMP #Y*2               \ jump to LL137 to return from the subroutine with the
 BCS LL137              \ C flag set, as the line doesn't fit on-screen

.LLX117

                        \ If we get here, XX13 = 95 or 191, and in both cases
                        \ (x2, y2) is off-screen, so we now need to swap the
                        \ (x1, y1) and (x2, y2) coordinates around before doing
                        \ the actual clipping, because we need to clip (x2, y2)
                        \ but the clipping routine at LL118 only clips (x1, y1)

 LDX XX15               \ Swap x1_lo = x2_lo
 LDA XX15+4
 STA XX15
 STX XX15+4

 LDA XX15+5             \ Swap x2_lo = x1_lo
 LDX XX15+1
 STX XX15+5
 STA XX15+1

 LDX XX15+2             \ Swap y1_lo = y2_lo
 LDA XX12
 STA XX15+2
 STX XX12

 LDA XX12+1             \ Swap y2_lo = y1_lo
 LDX XX15+3
 STX XX12+1
 STA XX15+3

 JSR LL118              \ Call LL118 to move (x1, y1) along the line onto the
                        \ screen, i.e. clip the line at the (x1, y1) end

 DEC SWAP               \ Set SWAP = &FF to indicate that we just clipped the
                        \ line at the (x2, y2) end by swapping the coordinates
                        \ (the DEC does this as we set SWAP to 0 at the start of
                        \ this subroutine)

.LL124

 PLA                    \ Restore Y from the stack so it gets preserved through
 TAY                    \ the call to this subroutine

 JMP LL146              \ Jump up to LL146 to move the low bytes of (x1, y1) and
                        \ (x2, y2) into (X1, Y1) and (X2, Y2), and return from
                        \ the subroutine with a successfully clipped line

.LL137

 PLA                    \ Restore Y from the stack so it gets preserved through
 TAY                    \ the call to this subroutine

 SEC                    \ Set the C flag to indicate the clipped line does not
                        \ fit on-screen

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL9 (Part 11 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Add all visible edges to the ship line heap
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This part adds all the visible edges to the ship line heap, so we can draw
\ them in part 12.
\
\ Other entry points:
\
\   LL81+2              Draw the contents of the ship line heap, used to draw
\                       the ship as a dot from SHPPT
\
\ ******************************************************************************

.LL80

 LDY U                  \ Fetch the ship line heap pointer, which points to the
                        \ next free byte on the heap, into Y

 LDA XX15               \ Add X1 to the end of the heap
 STA (XX19),Y

 INY                    \ Increment the heap pointer

 LDA XX15+1             \ Add Y1 to the end of the heap
 STA (XX19),Y

 INY                    \ Increment the heap pointer

 LDA XX15+2             \ Add X2 to the end of the heap
 STA (XX19),Y

 INY                    \ Increment the heap pointer

 LDA XX15+3             \ Add Y2 to the end of the heap
 STA (XX19),Y

 INY                    \ Increment the heap pointer

 STY U                  \ Store the updated ship line heap pointer in U

 CPY T1                 \ If Y >= T1 then we have reached the maximum number of
 BCS LL81               \ edge lines that we can store in the ship line heap, so
                        \ skip to LL81 so we don't loop back for the next edge

.LL78

 INC XX17               \ Increment the edge counter to point to the next edge

 LDY XX17               \ If Y >= XX20, which contains the number of edges in
 CPY XX20               \ the blueprint, jump to LL81 as we have processed all
 BCS LL81               \ the edges and don't need to loop back for the next one

 LDY #0                 \ Set Y to point to byte #0 again, ready for the next
                        \ edge

 LDA V                  \ Increment V by 4 so V(1 0) points to the data for the
 ADC #4                 \ next edge
 STA V

 BCC ll81               \ If the above addition didn't overflow, jump to ll81

 INC V+1                \ Otherwise increment the high byte of V(1 0), as we
                        \ just moved the V(1 0) pointer past a page boundary

.ll81

 JMP LL75               \ Loop back to LL75 to process the next edge

.LL81

                        \ We have finished adding lines to the ship line heap,
                        \ so now we need to set the first byte of the heap to
                        \ the number of bytes stored there

 LDA U                  \ Fetch the ship line heap pointer from U into A, which
                        \ points to the end of the heap, and therefore contains
                        \ the heap size

 LDY #0                 \ Store A as the first byte of the ship line heap, so
 STA (XX19),Y           \ the heap is now correctly set up

\ ******************************************************************************
\
\       Name: LL9 (Part 12 of 12)
\       Type: Subroutine
\   Category: Drawing ships
\    Summary: Draw ship: Draw all the visible edges from the ship line heap
\  Deep dive: Drawing ships
\
\ ------------------------------------------------------------------------------
\
\ This part draws the lines in the ship line heap, which is used both to draw
\ the ship, and to remove it from the screen.
\
\ ******************************************************************************

.LL155

 LDY #0                 \ Fetch the first byte from the ship line heap into A,
 LDA (XX19),Y           \ which contains the number of bytes in the heap

 STA XX20               \ Store the heap size in XX20

 CMP #4                 \ If the heap size is less than 4, there is nothing to
 BCC LL118-1            \ draw, so return from the subroutine (as LL118-1
                        \ contains an RTS)

 INY                    \ Set Y = 1, which we will use as an index into the ship
                        \ line heap, starting at byte #1 (as byte #0 contains
                        \ the heap size)

.LL27

 LDA (XX19),Y           \ Fetch the X1 line coordinate from the heap and store
 STA XX15               \ it in XX15

 INY                    \ Increment the heap pointer

 LDA (XX19),Y           \ Fetch the Y1 line coordinate from the heap and store
 STA XX15+1             \ it in XX15+1

 INY                    \ Increment the heap pointer

 LDA (XX19),Y           \ Fetch the X2 line coordinate from the heap and store
 STA XX15+2             \ it in XX15+2

 INY                    \ Increment the heap pointer

 LDA (XX19),Y           \ Fetch the Y2 line coordinate from the heap and store
 STA XX15+3             \ it in XX15+3

 JSR LL30               \ Draw a line from (X1, Y1) to (X2, Y2)

 INY                    \ Increment the heap pointer

 CPY XX20               \ If the heap counter is less than the size of the heap,
 BCC LL27               \ loop back to LL27 to draw the next line from the heap

\LL82                   \ This label is commented out in the original source

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL118
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Move a point along a line until it is on-screen
\  Deep dive: Line-clipping
\
\ ------------------------------------------------------------------------------
\
\ Given a point (x1, y1), a gradient and a direction of slope, move the point
\ along the line until it is on-screen, so this effectively clips the (x1, y1)
\ end of a line to be on the screen.
\
\ See the deep dive on "Line-clipping" for more details.
\
\ Arguments:
\
\   XX15(1 0)           x1 as a 16-bit coordinate (x1_hi x1_lo)
\
\   XX15(3 2)           y1 as a 16-bit coordinate (y1_hi y1_lo)
\
\   XX12+2              The line's gradient * 256 (so 1.0 = 256)
\
\   XX12+3              The direction of slope:
\
\                         * Positive (bit 7 clear) = top left to bottom right
\
\                         * Negative (bit 7 set) = top right to bottom left
\
\   T                   The type of slope:
\
\                         * 0 if it's more vertical than horizontal
\
\                         * &FF if it's more horizontal than vertical
\
\ Returns:
\
\   XX15                x1 as an 8-bit coordinate
\
\   XX15+2              y1 as an 8-bit coordinate
\
\ Other entry points:
\
\   LL118-1             Contains an RTS
\
\ ******************************************************************************

.LL118

 LDA XX15+1             \ If x1_hi is positive, jump down to LL119 to skip
 BPL LL119              \ the following

 STA S                  \ Otherwise x1_hi is negative, i.e. off the left of the
                        \ screen, so set S = x1_hi

 JSR LL120              \ Call LL120 to calculate:
                        \
                        \   (Y X) = (S x1_lo) * XX12+2      if T = 0
                        \         = x1 * gradient
                        \
                        \   (Y X) = (S x1_lo) / XX12+2      if T <> 0
                        \         = x1 / gradient
                        \
                        \ with the sign of (Y X) set to the opposite of the
                        \ line's direction of slope

 TXA                    \ Set y1 = y1 + (Y X)
 CLC                    \
 ADC XX15+2             \ starting with the low bytes
 STA XX15+2

 TYA                    \ And then adding the high bytes
 ADC XX15+3
 STA XX15+3

 LDA #0                 \ Set x1 = 0
 STA XX15
 STA XX15+1

 TAX                    \ Set X = 0 so the next instruction becomes a JMP

.LL119

 BEQ LL134              \ If x1_hi = 0 then jump down to LL134 to skip the
                        \ following, as the x-coordinate is already on-screen
                        \ (as 0 <= (x_hi x_lo) <= 255)

 STA S                  \ Otherwise x1_hi is positive, i.e. x1 >= 256 and off
 DEC S                  \ the right side of the screen, so set S = x1_hi - 1

 JSR LL120              \ Call LL120 to calculate:
                        \
                        \   (Y X) = (S x1_lo) * XX12+2      if T = 0
                        \         = (x1 - 256) * gradient
                        \
                        \   (Y X) = (S x1_lo) / XX12+2      if T <> 0
                        \         = (x1 - 256) / gradient
                        \
                        \ with the sign of (Y X) set to the opposite of the
                        \ line's direction of slope

 TXA                    \ Set y1 = y1 + (Y X)
 CLC                    \
 ADC XX15+2             \ starting with the low bytes
 STA XX15+2

 TYA                    \ And then adding the high bytes
 ADC XX15+3
 STA XX15+3

 LDX #255               \ Set x1 = 255
 STX XX15
 INX
 STX XX15+1

.LL134

                        \ We have moved the point so the x-coordinate is on
                        \ screen (i.e. in the range 0-255), so now for the
                        \ y-coordinate

 LDA XX15+3             \ If y1_hi is positive, jump down to LL119 to skip
 BPL LL135              \ the following

 STA S                  \ Otherwise y1_hi is negative, i.e. off the top of the
                        \ screen, so set S = y1_hi

 LDA XX15+2             \ Set R = y1_lo
 STA R

 JSR LL123              \ Call LL123 to calculate:
                        \
                        \   (Y X) = (S R) / XX12+2      if T = 0
                        \         = y1 / gradient
                        \
                        \   (Y X) = (S R) * XX12+2      if T <> 0
                        \         = y1 * gradient
                        \
                        \ with the sign of (Y X) set to the opposite of the
                        \ line's direction of slope

 TXA                    \ Set x1 = x1 + (Y X)
 CLC                    \
 ADC XX15               \ starting with the low bytes
 STA XX15

 TYA                    \ And then adding the high bytes
 ADC XX15+1
 STA XX15+1

 LDA #0                 \ Set y1 = 0
 STA XX15+2
 STA XX15+3

.LL135

\BNE LL139              \ This instruction is commented out in the original
                        \ source

 LDA XX15+2             \ Set (S R) = (y1_hi y1_lo) - 192
 SEC                    \
 SBC #Y*2               \ starting with the low bytes
 STA R

 LDA XX15+3             \ And then subtracting the high bytes
 SBC #0
 STA S

 BCC LL136              \ If the subtraction underflowed, i.e. if y1 < 192, then
                        \ y1 is already on-screen, so jump to LL136 to return
                        \ from the subroutine, as we are done

.LL139

                        \ If we get here then y1 >= 192, i.e. off the bottom of
                        \ the screen

 JSR LL123              \ Call LL123 to calculate:
                        \
                        \   (Y X) = (S R) / XX12+2      if T = 0
                        \         = (y1 - 192) / gradient
                        \
                        \   (Y X) = (S R) * XX12+2      if T <> 0
                        \         = (y1 - 192) * gradient
                        \
                        \ with the sign of (Y X) set to the opposite of the
                        \ line's direction of slope

 TXA                    \ Set x1 = x1 + (Y X)
 CLC                    \
 ADC XX15               \ starting with the low bytes
 STA XX15

 TYA                    \ And then adding the high bytes
 ADC XX15+1
 STA XX15+1

 LDA #Y*2-1             \ Set y1 = 2 * #Y - 1. The constant #Y is 96, the
 STA XX15+2             \ y-coordinate of the mid-point of the space view, so
 LDA #0                 \ this sets Y2 to 191, the y-coordinate of the bottom
 STA XX15+3             \ pixel row of the space view

.LL136

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL120
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (Y X) = (S x1_lo) * XX12+2 or (S x1_lo) / XX12+2
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   * If T = 0  (more vertical than horizontal), (Y X) = (S x1_lo) * XX12+2
\
\   * If T <> 0 (more horizontal than vertical), (Y X) = (S x1_lo) / XX12+2
\
\ giving (Y X) the opposite sign to the slope direction in XX12+3.
\
\ Other entry points:
\
\   LL122               Calculate (Y X) = (S R) * Q and set the sign to the
\                       opposite of the top byte on the stack
\
\ ******************************************************************************

.LL120

 LDA XX15               \ Set R = x1_lo
 STA R

\.LL120                 \ This label is commented out in the original source

 JSR LL129              \ Call LL129 to do the following:
                        \
                        \   Q = XX12+2
                        \     = line gradient
                        \
                        \   A = S EOR XX12+3
                        \     = S EOR slope direction
                        \
                        \   (S R) = |S R|
                        \
                        \ So A contains the sign of S * slope direction

 PHA                    \ Store A on the stack so we can use it later

 LDX T                  \ If T is non-zero, so it's more horizontal than
 BNE LL121              \ vertical, jump down to LL121 to calculate this
                        \ instead:
                        \
                        \   (Y X) = (S R) / Q

.LL122

                        \ The following calculates:
                        \
                        \   (Y X) = (S R) * Q
                        \
                        \ using the same shift-and-add algorithm that's
                        \ documented in MULT1

 LDA #0                 \ Set A = 0

 TAX                    \ Set (Y X) = 0 so we can start building the answer here
 TAY

 LSR S                  \ Shift (S R) to the right, so we extract bit 0 of (S R)
 ROR R                  \ into the C flag

 ASL Q                  \ Shift Q to the left, catching bit 7 in the C flag

 BCC LL126              \ If C (i.e. the next bit from Q) is clear, do not do
                        \ the addition for this bit of Q, and instead skip to
                        \ LL126 to just do the shifts

.LL125

 TXA                    \ Set (Y X) = (Y X) + (S R)
 CLC                    \
 ADC R                  \ starting with the low bytes
 TAX

 TYA                    \ And then doing the high bytes
 ADC S
 TAY

.LL126

 LSR S                  \ Shift (S R) to the right
 ROR R

 ASL Q                  \ Shift Q to the left, catching bit 7 in the C flag

 BCS LL125              \ If C (i.e. the next bit from Q) is set, loop back to
                        \ LL125 to do the addition for this bit of Q

 BNE LL126              \ If Q has not yet run out of set bits, loop back to
                        \ LL126 to do the "shift" part of shift-and-add until
                        \ we have done additions for all the set bits in Q, to
                        \ give us our multiplication result

 PLA                    \ Restore A, which we calculated above, from the stack

 BPL LL133              \ If A is positive jump to LL133 to negate (Y X) and
                        \ return from the subroutine using a tail call

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL123
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (Y X) = (S R) / XX12+2 or (S R) * XX12+2
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following:
\
\   * If T = 0,  calculate (Y X) = (S R) / XX12+2
\
\   * If T <> 0, calculate (Y X) = (S R) * XX12+2
\
\ giving (Y X) the opposite sign to the slope direction in XX12+3.
\
\ Arguments:
\
\   XX12+2              The line's gradient * 256 (so 1.0 = 256)
\
\   XX12+3              The direction of slope:
\
\                         * Bit 7 clear means top left to bottom right
\
\                         * Bit 7 set means top right to bottom left
\
\ Other entry points:
\
\   LL121               Calculate (Y X) = (S R) / Q and set the sign to the
\                       opposite of the top byte on the stack
\
\   LL133               Negate (Y X) and return from the subroutine
\
\   LL128               Contains an RTS
\
\ ******************************************************************************

.LL123

 JSR LL129              \ Call LL129 to do the following:
                        \
                        \   Q = XX12+2
                        \     = line gradient
                        \
                        \   A = S EOR XX12+3
                        \     = S EOR slope direction
                        \
                        \   (S R) = |S R|
                        \
                        \ So A contains the sign of S * slope direction

 PHA                    \ Store A on the stack so we can use it later

 LDX T                  \ If T is non-zero, so it's more horizontal than
 BNE LL122              \ vertical, jump up to LL122 to calculate this instead:
                        \
                        \   (Y X) = (S R) * Q

.LL121

                        \ The following calculates:
                        \
                        \   (Y X) = (S R) / Q
                        \
                        \ using the same shift-and-subtract algorithm that's
                        \ documented in TIS2

 LDA #%11111111         \ Set Y = %11111111
 TAY

 ASL A                  \ Set X = %11111110
 TAX

                        \ This sets (Y X) = %1111111111111110, so we can rotate
                        \ through 15 loop iterations, getting a 1 each time, and
                        \ then getting a 0 on the 16th iteration... and we can
                        \ also use it to catch our result bits into bit 0 each
                        \ time

.LL130

 ASL R                  \ Shift (S R) to the left
 ROL S

 LDA S                  \ Set A = S

 BCS LL131              \ If bit 7 of S was set, then jump straight to the
                        \ subtraction

 CMP Q                  \ If A < Q (i.e. S < Q), skip the following subtractions
 BCC LL132

.LL131

 SBC Q                  \ A >= Q (i.e. S >= Q) so set:
 STA S                  \
                        \   S = (A R) - Q
                        \     = (S R) - Q
                        \
                        \ starting with the low bytes (we know the C flag is
                        \ set so the subtraction will be correct)

 LDA R                  \ And then doing the high bytes
 SBC #0
 STA R

 SEC                    \ Set the C flag to rotate into the result in (Y X)

.LL132

 TXA                    \ Rotate the counter in (Y X) to the left, and catch the
 ROL A                  \ result bit into bit 0 (which will be a 0 if we didn't
 TAX                    \ do the subtraction, or 1 if we did)
 TYA
 ROL A
 TAY

 BCS LL130              \ If we still have set bits in (Y X), loop back to LL130
                        \ to do the next iteration of 15, until we have done the
                        \ whole division

 PLA                    \ Restore A, which we calculated above, from the stack

 BMI LL128              \ If A is negative jump to LL128 to return from the
                        \ subroutine with (Y X) as is

.LL133

 TXA                    \ Otherwise negate (Y X) using two's complement by first
 EOR #%11111111         \ setting the low byte to ~X + 1
\CLC                    \
 ADC #1                 \ The CLC instruction is commented out in the original
 TAX                    \ source. It would have no effect as we know the C flag
                        \ is clear from when we passed through the BCS above

 TYA                    \ Then set the high byte to ~Y + C
 EOR #%11111111
 ADC #0
 TAY

.LL128

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: LL129
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate Q = XX12+2, A = S EOR XX12+3 and (S R) = |S R|
\
\ ------------------------------------------------------------------------------
\
\ Do the following, in this order:
\
\   Q = XX12+2
\
\   A = S EOR XX12+3
\
\   (S R) = |S R|
\
\ This sets up the variables required above to calculate (S R) / XX12+2 and give
\ the result the opposite sign to XX13+3.
\
\ ******************************************************************************

.LL129

 LDX XX12+2             \ Set Q = XX12+2
 STX Q

 LDA S                  \ If S is positive, jump to LL127
 BPL LL127

 LDA #0                 \ Otherwise set R = -R
 SEC
 SBC R
 STA R

 LDA S                  \ Push S onto the stack
 PHA

 EOR #%11111111         \ Set S = ~S + 1 + C
 ADC #0
 STA S

 PLA                    \ Pull the original, negative S from the stack into A

.LL127

 EOR XX12+3             \ Set A = original argument S EOR'd with XX12+3

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\ Save output/ELTG.bin
\
\ ******************************************************************************

PRINT "ELITE G"
PRINT "Assembled at ", ~CODE_G%
PRINT "Ends at ", ~P%
PRINT "Code size is ", ~(P% - CODE_G%)
PRINT "Execute at ", ~LOAD%
PRINT "Reload at ", ~LOAD_G%

PRINT "S.F.ELTG ", ~CODE_G%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD_G%
\SAVE "output/F.ELTG.bin", CODE_G%, P%, LOAD%

\ ******************************************************************************
\
\ ELITE H FILE
\
\ ******************************************************************************

CODE_H% = P%
LOAD_H% = LOAD% + P% - CODE%

\ ******************************************************************************
\
\       Name: info_menu
\       Type: Subroutine
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.info_menu

 LDX #&00
 JSR menu
 CMP #&01
 BNE n_shipsag
 JMP ships_ag

.n_shipsag

 CMP #&02
 BNE n_shipskw
 JMP ships_kw

.n_shipskw

 CMP #&03
 BNE n_equipdat
 JMP equip_data

.n_equipdat

 CMP #&04
 BNE n_controls
 JMP controls

.n_controls

 CMP #&05
 BNE jmp_start3
 JMP trading

.jmp_start3

 JSR dn2
 JMP BAY

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: ships_ag
\       Type: Subroutine
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.ships_ag

.ships_kw

 PHA
 TAX
 JSR menu
 SBC #&00
 PLP
 BCS ship_over
 ADC menu_entry+1

.ship_over

 STA TYPE
 CLC
 ADC #&07
 PHA
 LDA #&20
 JSR TT66
 JSR MT1
 LDX TYPE

 LDA ship_file,X
 CMP ship_load+4
 BEQ ship_skip
 STA ship_load+4
 LDX #LO(ship_load)
 LDY #HI(ship_load)
 JSR OSCLI

.ship_skip

 LDX TYPE
 LDA ship_centre,X
 STA XC
 PLA
 JSR write_msg3
 JSR NLIN4
 JSR ZINF
 LDA #&60
 STA INWK+14
 LDA #&B0
 STA INWK+7
 LDX #&7F
 STX INWK+29
 STX INWK+30
 INX
 STA QQ17
 LDA TYPE
 JSR write_card

 LDX TYPE
 LDA ship_posn,X
 JSR NWSHP

.l_release

 JSR RDKEY
 BNE l_release

.l_395a

 LDX TYPE
 LDA ship_dist,X
 CMP INWK+7
 BEQ l_3962
 DEC INWK+7

.l_3962

 JSR MVEIT
 LDA #&80
 STA INWK+6
 ASL A
 STA INWK
 STA INWK+3
 JSR LL9
 DEC MCNT

 JSR WSCAN
 JSR RDKEY

 BEQ l_395a
 JMP BAY

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: controls
\       Type: Subroutine
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.controls

 LDX #&03
 JSR menu
 ADC #&56
 PHA
 ADC #&04
 PHA
 LDA #&20
 JSR TT66
 JSR MT1
 LDA #&0B
 STA XC
 PLA
 JSR write_msg3
 JSR NLIN4
 JSR MT2
 INC YC
 PLA
 JSR write_msg3
 JMP l_restart

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: equip_data
\       Type: Subroutine
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.equip_data

 LDX #&04
 JSR menu
 ADC #&6B
 PHA
 SBC #&0C
 PHA
 LDA #&20
 JSR TT66
 JSR MT1
 LDA #&0B
 STA XC
 PLA
 JSR write_msg3
 JSR NLIN4
 JSR MT2
 JSR MT13
 INC YC
 INC YC
 LDA #&01
 STA XC
 PLA
 JSR write_msg3
 JMP l_restart

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: trading
\       Type: Subroutine
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.trading

.l_restart

 JSR PAUSE2

 JMP BAY

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: write_card
\       Type: Subroutine
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.write_card

 ASL A
 TAY
 LDA card_addr,Y
 STA V
 LDA card_addr+1,Y
 STA V+1

.card_repeat

 JSR MT1
 LDY #&00
 LDA (V),Y
 TAX
 BEQ quit_card
 BNE card_check

.card_find

 INY
 INY
 INY
 LDA card_pattern-1,Y
 BNE card_find

.card_check

 DEX
 BNE card_find

.card_found

 LDA card_pattern,Y
 STA XC
 LDA card_pattern+1,Y
 STA YC
 LDA card_pattern+2,Y
 BEQ card_details
 JSR write_msg3
 INY
 INY
 INY
 BNE card_found

.card_details

 JSR MT2
 LDY #&00

.card_loop

 INY
 LDA (V),Y
 BEQ card_end
 BMI card_msg
 CMP #&20
 BCC card_macro
 JSR DTS
 JMP card_loop

.card_macro

 JSR DT3
 JMP card_loop

.card_msg

 CMP #&D7
 BCS card_pairs
 AND #&7F
 JSR write_msg3
 JMP card_loop

.card_pairs

 JSR msg_pairs
 JMP card_loop

.card_end

 TYA
 SEC
 ADC V
 STA V
 BCC card_repeat
 INC V+1
 BCS card_repeat

.quit_card

 RTS

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: ship_load
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.ship_load

 EQUS "L.S.0"
 EQUB 13

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: ship_file
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.ship_file

 EQUB 'A', 'H', 'I', 'K', 'J', 'P', 'B'
 EQUB 'N', 'A', 'B', 'A', 'M', 'E', 'B'
 EQUB 'G', 'I', 'M', 'A', 'O', 'F', 'E'
 EQUB 'L', 'L', 'C', 'C', 'P', 'A', 'H'

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: ship_posn
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.ship_posn

 EQUB 19, 14, 27, 11, 20, 12, 17
 EQUB 11,  2,  2,  3, 25, 17, 11
 EQUB 20, 17, 17, 11, 22, 21, 11
 EQUB  9, 17, 29, 30, 10, 16, 15

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: ship_dist
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.ship_dist

 EQUB &01, &02, &01, &02, &01, &01, &01
 EQUB &02, &04, &04, &01, &01, &01, &02
 EQUB &01, &02, &01, &02, &01, &01, &02
 EQUB &01, &01, &03, &01, &01, &01, &01

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: menu
\       Type: Subroutine
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.menu

 LDA menu_entry,X
 STA QQ25
 LDA menu_offset,X
 STA QQ29
 LDA menu_query,X
 PHA
 LDA menu_title,X
 PHA
 LDA menu_titlex,X
 PHA
 LDA #&20
 JSR TT66
 JSR MT1
 PLA
 STA XC
 PLA
 JSR write_msg3
 JSR NLIN4

 JSR MT2
 LDA #&80
 STA QQ17

 INC YC
 LDX #&00

.menu_loop

 STX XX13
 JSR TT67
 LDX XX13
 INX
 CLC
 JSR pr2
 JSR TT162

 CLC
 LDA XX13
 ADC QQ29
 JSR write_msg3
 LDX XX13
 INX
 CPX QQ25
 BCC menu_loop
 JSR CLYNS
 PLA
 JSR write_msg3
 LDA #'?'
 JSR DASC
 JSR gnum
 BEQ menu_start
 BCS menu_start
 RTS

.menu_start

 JMP BAY

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: menu_title
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.menu_title

 EQUB &01, &02, &03, &05, &04

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: menu_titlex
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.menu_titlex

 EQUB &05, &0C, &0C, &0C, &0B

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: menu_offset
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.menu_offset

 EQUB &02, &07, &15, &5B, &5F

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: menu_entry
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.menu_entry

 EQUB &04, &0E, &0E, &04, &0D

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: menu_query
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.menu_query

 EQUB &06, &43, &43, &05, &04

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: EJMP
\       Type: Macro
\   Category: Text
\    Summary: Macro definition for jump tokens in the extended token table
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used when building the extended token table:
\
\   EJMP n              Insert a jump to address n in the JMTB table
\
\ See the deep dive on "Printing extended text tokens" for details on how jump
\ tokens are stored in the extended token table.
\
\ Arguments:
\
\   n                   The jump number to insert into the table
\
\ ******************************************************************************

MACRO EJMP n

  EQUB n EOR VE

ENDMACRO

\ ******************************************************************************
\
\       Name: ECHR
\       Type: Macro
\   Category: Text
\    Summary: Macro definition for characters in the extended token table
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used when building the extended token table:
\
\   ECHR 'x'            Insert ASCII character "x"
\
\ To include an apostrophe, use a backtick character, as in ECHR '`'.
\
\ See the deep dive on "Printing extended text tokens" for details on how
\ characters are stored in the extended token table.
\
\ Arguments:
\
\   'x'                 The character to insert into the table
\
\ ******************************************************************************

MACRO ECHR x

  IF x = '`'
    EQUB 39 EOR VE
  ELSE
    EQUB x EOR VE
  ENDIF

ENDMACRO

\ ******************************************************************************
\
\       Name: ETOK
\       Type: Macro
\   Category: Text
\    Summary: Macro definition for recursive tokens in the extended token table
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used when building the extended token table:
\
\   ETOK n              Insert extended recursive token [n]
\
\ See the deep dive on "Printing extended text tokens" for details on how
\ recursive tokens are stored in the extended token table.
\
\ Arguments:
\
\   n                   The number of the recursive token to insert into the
\                       table, in the range 129 to 214
\
\ ******************************************************************************

MACRO ETOK n

  EQUB n EOR VE

ENDMACRO

\ ******************************************************************************
\
\       Name: ETWO
\       Type: Macro
\   Category: Text
\    Summary: Macro definition for two-letter tokens in the extended token table
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used when building the extended token table:
\
\   ETWO 'x', 'y'       Insert two-letter token "xy"
\
\ The newline token can be entered using ETWO '-', '-'.
\
\ See the deep dive on "Printing extended text tokens" for details on how
\ two-letter tokens are stored in the extended token table.
\
\ Arguments:
\
\   'x'                 The first letter of the two-letter token to insert into
\                       the table
\
\   'y'                 The second letter of the two-letter token to insert into
\                       the table
\
\ ******************************************************************************

MACRO ETWO t, k

  IF t = '-' AND k = '-' : EQUB 215 EOR VE : ENDIF
  IF t = 'A' AND k = 'B' : EQUB 216 EOR VE : ENDIF
  IF t = 'O' AND k = 'U' : EQUB 217 EOR VE : ENDIF
  IF t = 'S' AND k = 'E' : EQUB 218 EOR VE : ENDIF
  IF t = 'I' AND k = 'T' : EQUB 219 EOR VE : ENDIF
  IF t = 'I' AND k = 'L' : EQUB 220 EOR VE : ENDIF
  IF t = 'E' AND k = 'T' : EQUB 221 EOR VE : ENDIF
  IF t = 'S' AND k = 'T' : EQUB 222 EOR VE : ENDIF
  IF t = 'O' AND k = 'N' : EQUB 223 EOR VE : ENDIF
  IF t = 'L' AND k = 'O' : EQUB 224 EOR VE : ENDIF
  IF t = 'N' AND k = 'U' : EQUB 225 EOR VE : ENDIF
  IF t = 'T' AND k = 'H' : EQUB 226 EOR VE : ENDIF
  IF t = 'N' AND k = 'O' : EQUB 227 EOR VE : ENDIF

  IF t = 'A' AND k = 'L' : EQUB 228 EOR VE : ENDIF
  IF t = 'L' AND k = 'E' : EQUB 229 EOR VE : ENDIF
  IF t = 'X' AND k = 'E' : EQUB 230 EOR VE : ENDIF
  IF t = 'G' AND k = 'E' : EQUB 231 EOR VE : ENDIF
  IF t = 'Z' AND k = 'A' : EQUB 232 EOR VE : ENDIF
  IF t = 'C' AND k = 'E' : EQUB 233 EOR VE : ENDIF
  IF t = 'B' AND k = 'I' : EQUB 234 EOR VE : ENDIF
  IF t = 'S' AND k = 'O' : EQUB 235 EOR VE : ENDIF
  IF t = 'U' AND k = 'S' : EQUB 236 EOR VE : ENDIF
  IF t = 'E' AND k = 'S' : EQUB 237 EOR VE : ENDIF
  IF t = 'A' AND k = 'R' : EQUB 238 EOR VE : ENDIF
  IF t = 'M' AND k = 'A' : EQUB 239 EOR VE : ENDIF
  IF t = 'I' AND k = 'N' : EQUB 240 EOR VE : ENDIF
  IF t = 'D' AND k = 'I' : EQUB 241 EOR VE : ENDIF
  IF t = 'R' AND k = 'E' : EQUB 242 EOR VE : ENDIF
  IF t = 'A' AND k = '?' : EQUB 243 EOR VE : ENDIF
  IF t = 'E' AND k = 'R' : EQUB 244 EOR VE : ENDIF
  IF t = 'A' AND k = 'T' : EQUB 245 EOR VE : ENDIF
  IF t = 'E' AND k = 'N' : EQUB 246 EOR VE : ENDIF
  IF t = 'B' AND k = 'E' : EQUB 247 EOR VE : ENDIF
  IF t = 'R' AND k = 'A' : EQUB 248 EOR VE : ENDIF
  IF t = 'L' AND k = 'A' : EQUB 249 EOR VE : ENDIF
  IF t = 'V' AND k = 'E' : EQUB 250 EOR VE : ENDIF
  IF t = 'T' AND k = 'I' : EQUB 251 EOR VE : ENDIF
  IF t = 'E' AND k = 'D' : EQUB 252 EOR VE : ENDIF
  IF t = 'O' AND k = 'R' : EQUB 253 EOR VE : ENDIF
  IF t = 'Q' AND k = 'U' : EQUB 254 EOR VE : ENDIF
  IF t = 'A' AND k = 'N' : EQUB 255 EOR VE : ENDIF

ENDMACRO

\ ******************************************************************************
\
\       Name: ERND
\       Type: Macro
\   Category: Text
\    Summary: Macro definition for random tokens in the extended token table
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used when building the extended token table:
\
\   ERND n              Insert recursive token [n]
\
\                         * Tokens 0-123 get stored as n + 91
\
\ See the deep dive on "Printing extended text tokens" for details on how
\ random tokens are stored in the extended token table.
\
\ Arguments:
\
\   n                   The number of the random token to insert into the
\                       table, in the range 0 to 37
\
\ ******************************************************************************

MACRO ERND n

  EQUB (n + 91) EOR VE

ENDMACRO

\ ******************************************************************************
\
\       Name: TOKN
\       Type: Macro
\   Category: Text
\    Summary: Macro definition for standard tokens in the extended token table
\  Deep dive: Printing text tokens
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used when building the recursive token table:
\
\   TOKN n              Insert recursive token [n]
\
\                         * Tokens 0-95 get stored as n + 160
\
\                         * Tokens 128-145 get stored as n - 114
\
\                         * Tokens 96-127 get stored as n
\
\ See the deep dive on "Printing text tokens" for details on how recursive
\ tokens are stored in the recursive token table.
\
\ Arguments:
\
\   n                   The number of the recursive token to insert into the
\                       table, in the range 0 to 145
\
\ ******************************************************************************

MACRO TOKN n

  IF n >= 0 AND n <= 95
    t = n + 160
  ELIF n >= 128
    t = n - 114
  ELSE
    t = n
  ENDIF

  EQUB t EOR VE

ENDMACRO

\ ******************************************************************************
\
\       Name: TKN1
\       Type: Variable
\   Category: Text
\    Summary: The first extended token table for recursive tokens 0-255 (DETOK)
\  Deep dive: Extended text tokens
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.TKN1

 EQUB VE                \ Token 0:      ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 1:      ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 2:      ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 3:      ""
                        \
                        \ Encoded as:   ""

 ETOK 150               \ Token 4:      "{clear screen}
 ETOK 151               \                {draw box around title}
 ECHR ' '               \                {all caps}
 EJMP 16                \                {tab 6}DRIVE {drive number} CATALOGUE
 ETOK 152               \                {crlf}
 ETWO '-', '-'          \               "
 EQUB VE                \
                        \ Encoded as:   "[150][151] {16}[152]<215>"

 ETOK 176               \ Token 5:      "{lower case}
 ERND 18                \                {justify}
 ETOK 202               \                {single cap}[86-90] IS [140-144].{cr}
 ERND 19                \                {left align}"
 ETOK 177               \
 EQUB VE                \ Encoded as:   "[176][18?][202][19?][177]"

 EQUB VE                \ Token 6:      ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 7:      ""
                        \
                        \ Encoded as:   ""

 ETOK 154               \ Token 8:      "{single cap}COMMANDER'S NAME? "
 ECHR '`'               \
 ECHR 'S'               \ Encoded as:   "[154][39]S[200]"
 ETOK 200
 EQUB VE

 EQUB VE                \ Token 9:      ""
                        \
                        \ Encoded as:   ""

 EJMP 22                \ Token 10:     "" AJD
 EQUB VE                \
                        \ Encoded as:   ""

 EQUB VE                \ Token 11:     ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 12:     ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 13:     ""
                        \
                        \ Encoded as:   ""

 EJMP 21                \ Token 14:     "{clear bottom of screen}
 ETOK 145               \                PLANET NAME?
 ETOK 200               \                {fetch line input from keyboard}"
 EJMP 26                \
 EQUB VE                \ Encoded as:   "{21}[145][200]{26}"

 EQUB VE                \ Token 15:     ""
                        \
                        \ Encoded as:   ""

 ECHR 'F'               \ Token 16:     "FABLED"
 ETWO 'A', 'B'          \
 ETWO 'L', 'E'          \ Encoded as:   "F<216><229>D"
 ECHR 'D'
 EQUB VE

 ETWO 'N', 'O'          \ Token 17:     "NOTABLE"
 ECHR 'T'               \
 ETWO 'A', 'B'          \ Encoded as:   "<227>T<216><229>"
 ETWO 'L', 'E'
 EQUB VE

 ECHR 'W'               \ Token 18:     "WELL KNOWN"
 ECHR 'E'               \
 ECHR 'L'               \ Encoded as:   "WELL K<227>WN"
 ECHR 'L'
 ECHR ' '
 ECHR 'K'
 ETWO 'N', 'O'
 ECHR 'W'
 ECHR 'N'
 EQUB VE

 ECHR 'F'               \ Token 19:     "FAMOUS"
 ECHR 'A'               \
 ECHR 'M'               \ Encoded as:   "FAMO<236>"
 ECHR 'O'
 ETWO 'U', 'S'
 EQUB VE

 ETWO 'N', 'O'          \ Token 20:     "NOTED"
 ECHR 'T'               \
 ETWO 'E', 'D'          \ Encoded as:   "<227>T<252>"
 EQUB VE

 ETWO 'V', 'E'          \ Token 21:     "VERY"
 ECHR 'R'               \
 ECHR 'Y'               \ Encoded as:   "<250>RY"
 EQUB VE

 ECHR 'M'               \ Token 22:     "MILDLY"
 ETWO 'I', 'L'          \
 ECHR 'D'               \ Encoded as:   "M<220>DLY"
 ECHR 'L'
 ECHR 'Y'
 EQUB VE

 ECHR 'M'               \ Token 23:     "MOST"
 ECHR 'O'               \
 ETWO 'S', 'T'          \ Encoded as:   "MO<222>"
 EQUB VE

 ETWO 'R', 'E'          \ Token 24:     "REASONABLY"
 ECHR 'A'               \
 ECHR 'S'               \ Encoded as:   "<242>AS<223><216>LY"
 ETWO 'O', 'N'
 ETWO 'A', 'B'
 ECHR 'L'
 ECHR 'Y'
 EQUB VE

 EQUB VE                \ Token 25:     ""
                        \
                        \ Encoded as:   ""

 ETOK 165               \ Token 26:     "ANCIENT"
 EQUB VE                \
                        \ Encoded as:   "[165]"

 ERND 23                \ Token 27:     "[130-134]"
 EQUB VE                \
                        \ Encoded as:   "[23?]"

 ECHR 'G'               \ Token 28:     "GREAT"
 ETWO 'R', 'E'          \
 ETWO 'A', 'T'          \ Encoded as:   "G<242><245>"
 EQUB VE

 ECHR 'V'               \ Token 29:     "VAST"
 ECHR 'A'               \
 ETWO 'S', 'T'          \ Encoded as:   "VA<222>"
 EQUB VE

 ECHR 'P'               \ Token 30:     "PINK"
 ETWO 'I', 'N'          \
 ECHR 'K'               \ Encoded as:   "P<240>K"
 EQUB VE

 EJMP 2                 \ Token 31:     "{sentence case}[190-194] [185-189]
 ERND 28                \                {lower case} PLANTATIONS"
 ECHR ' '               \
 ERND 27                \ Encoded as:   "{2}[28?] [27?]{13} [185]A<251><223>S"
 EJMP 13
 ECHR ' '
 ETOK 185
 ECHR 'A'
 ETWO 'T', 'I'
 ETWO 'O', 'N'
 ECHR 'S'
 EQUB VE

 ETOK 156               \ Token 32:     "MOUNTAINS"
 ECHR 'S'               \
 EQUB VE                \ Encoded as:   "[156]S"

 ERND 26                \ Token 33:     "[180-184]"
 EQUB VE                \
                        \ Encoded as:   "[26?]"

 ERND 37                \ Token 34:     "[125-129] FORESTS"
 ECHR ' '               \
 ECHR 'F'               \ Encoded as:   "[37?] F<253><237>TS"
 ETWO 'O', 'R'
 ETWO 'E', 'S'
 ECHR 'T'
 ECHR 'S'
 EQUB VE

 ECHR 'O'               \ Token 35:     "OCEANS"
 ETWO 'C', 'E'          \
 ETWO 'A', 'N'          \ Encoded as:   "O<233><255>S"
 ECHR 'S'
 EQUB VE

 ECHR 'S'               \ Token 36:     "SHYNESS"
 ECHR 'H'               \
 ECHR 'Y'               \ Encoded as:   "SHYN<237>S"
 ECHR 'N'
 ETWO 'E', 'S'
 ECHR 'S'
 EQUB VE

 ECHR 'S'               \ Token 37:     "SILLINESS"
 ETWO 'I', 'L'          \
 ECHR 'L'               \ Encoded as:   "S<220>L<240><237>S"
 ETWO 'I', 'N'
 ETWO 'E', 'S'
 ECHR 'S'
 EQUB VE

 ETWO 'M', 'A'          \ Token 38:     "MATING TRADITIONS"
 ECHR 'T'               \
 ETOK 195               \ Encoded as:   "<239>T[195]T<248><241><251><223>S"
 ECHR 'T'
 ETWO 'R', 'A'
 ETWO 'D', 'I'
 ETWO 'T', 'I'
 ETWO 'O', 'N'
 ECHR 'S'
 EQUB VE

 ETWO 'L', 'O'          \ Token 39:     "LOATHING OF [41-45]"
 ETWO 'A', 'T'          \
 ECHR 'H'               \ Encoded as:   "<224><245>H[195]OF [9?]"
 ETOK 195
 ECHR 'O'
 ECHR 'F'
 ECHR ' '
 ERND 9
 EQUB VE

 ETWO 'L', 'O'          \ Token 40:     "LOVE FOR [41-45]"
 ETWO 'V', 'E'          \
 ECHR ' '               \ Encoded as:   "<224><250> F<253> [9?]"
 ECHR 'F'
 ETWO 'O', 'R'
 ECHR ' '
 ERND 9
 EQUB VE

 ECHR 'F'               \ Token 41:     "FOOD BLENDERS"
 ECHR 'O'               \
 ECHR 'O'               \ Encoded as:   "FOOD B<229>ND<244>S"
 ECHR 'D'
 ECHR ' '
 ECHR 'B'
 ETWO 'L', 'E'
 ECHR 'N'
 ECHR 'D'
 ETWO 'E', 'R'
 ECHR 'S'
 EQUB VE

 ECHR 'T'               \ Token 42:     "TOURISTS"
 ETWO 'O', 'U'          \
 ECHR 'R'               \ Encoded as:   "T<217>RI<222>S"
 ECHR 'I'
 ETWO 'S', 'T'
 ECHR 'S'
 EQUB VE

 ECHR 'P'               \ Token 43:     "POETRY"
 ECHR 'O'               \
 ETWO 'E', 'T'          \ Encoded as:   "PO<221>RY"
 ECHR 'R'
 ECHR 'Y'
 EQUB VE

 ETWO 'D', 'I'          \ Token 44:     "DISCOS"
 ECHR 'S'               \
 ECHR 'C'               \ Encoded as:   "<241>SCOS"
 ECHR 'O'
 ECHR 'S'
 EQUB VE

 ERND 17                \ Token 45:     "[81-85]"
 EQUB VE                \
                        \ Encoded as:   "[17?]"

 ECHR 'W'               \ Token 46:     "WALKING TREE"
 ETWO 'A', 'L'          \
 ECHR 'K'               \ Encoded as:   "W<228>K[195][158]"
 ETOK 195
 ETOK 158
 EQUB VE

 ECHR 'C'               \ Token 47:     "CRAB"
 ETWO 'R', 'A'          \
 ECHR 'B'               \ Encoded as:   "C<248>B"
 EQUB VE

 ECHR 'B'               \ Token 48:     "BAT"
 ETWO 'A', 'T'          \
 EQUB VE                \ Encoded as:   "B<245>"

 ETWO 'L', 'O'          \ Token 49:     "LOBST"
 ECHR 'B'               \
 ETWO 'S', 'T'          \ Encoded as:   "<224>B<222>"
 EQUB VE

 EJMP 18                \ Token 50:     "{random 1-8 letter word}"
 EQUB VE                \
                        \ Encoded as:   "{18}"

 ETWO 'B', 'E'          \ Token 51:     "BESET"
 ECHR 'S'               \
 ETWO 'E', 'T'          \ Encoded as:   "<247>S<221>"
 EQUB VE

 ECHR 'P'               \ Token 52:     "PLAGUED"
 ETWO 'L', 'A'          \
 ECHR 'G'               \ Encoded as:   "P<249>GU<252>"
 ECHR 'U'
 ETWO 'E', 'D'
 EQUB VE

 ETWO 'R', 'A'          \ Token 53:     "RAVAGED"
 ECHR 'V'               \
 ECHR 'A'               \ Encoded as:   "<248>VAG<252>"
 ECHR 'G'
 ETWO 'E', 'D'
 EQUB VE

 ECHR 'C'               \ Token 54:     "CURSED"
 ECHR 'U'               \
 ECHR 'R'               \ Encoded as:   "CURS<252>"
 ECHR 'S'
 ETWO 'E', 'D'
 EQUB VE

 ECHR 'S'               \ Token 55:     "SCOURGED"
 ECHR 'C'               \
 ETWO 'O', 'U'          \ Encoded as:   "SC<217>RG<252>"
 ECHR 'R'
 ECHR 'G'
 ETWO 'E', 'D'
 EQUB VE

 ERND 22                \ Token 56:     "[135-139] CIVIL WAR"
 ECHR ' '               \
 ECHR 'C'               \ Encoded as:   "[22?] CIV<220> W<238>"
 ECHR 'I'
 ECHR 'V'
 ETWO 'I', 'L'
 ECHR ' '
 ECHR 'W'
 ETWO 'A', 'R'
 EQUB VE

 ERND 13                \ Token 57:     "[170-174] [155-159] [160-164]S"
 ECHR ' '               \
 ERND 4                 \ Encoded as:   "[13?] [4?] [5?]S"
 ECHR ' '
 ERND 5
 ECHR 'S'
 EQUB VE

 ECHR 'A'               \ Token 58:     "A [170-174] DISEASE"
 ECHR ' '               \
 ERND 13                \ Encoded as:   "A [13?] <241><218>A<218>"
 ECHR ' '
 ETWO 'D', 'I'
 ETWO 'S', 'E'
 ECHR 'A'
 ETWO 'S', 'E'
 EQUB VE

 ERND 22                \ Token 59:     "[135-139] EARTHQUAKES"
 ECHR ' '               \
 ECHR 'E'               \ Encoded as:   "[22?] E<238><226><254>AK<237>"
 ETWO 'A', 'R'
 ETWO 'T', 'H'
 ETWO 'Q', 'U'
 ECHR 'A'
 ECHR 'K'
 ETWO 'E', 'S'
 EQUB VE

 ERND 22                \ Token 60:     "[135-139] SOLAR ACTIVITY"
 ECHR ' '               \
 ETWO 'S', 'O'          \ Encoded as:   "[22?] <235><249>R AC<251>V<219>Y"
 ETWO 'L', 'A'
 ECHR 'R'
 ECHR ' '
 ECHR 'A'
 ECHR 'C'
 ETWO 'T', 'I'
 ECHR 'V'
 ETWO 'I', 'T'
 ECHR 'Y'
 EQUB VE

 ETOK 175               \ Token 61:     "ITS [26-30] [31-35]"
 ERND 2                 \
 ECHR ' '               \ Encoded as:   "[175][2?] [3?]"
 ERND 3
 EQUB VE

 ETOK 147               \ Token 62:     "THE {system name adjective} [155-159]
 EJMP 17                \                 [160-164]"
 ECHR ' '               \
 ERND 4                 \ Encoded as:   "[147]{17} [4?] [5?]"
 ECHR ' '
 ERND 5
 EQUB VE

 ETOK 175               \ Token 63:     "ITS INHABITANTS' [165-169] [36-40]"
 ETOK 193               \
 ECHR 'S'               \ Encoded as:   "[175][193]S[39] [7?] [8?]"
 ECHR '`'
 ECHR ' '
 ERND 7
 ECHR ' '
 ERND 8
 EQUB VE

 EJMP 2                 \ Token 64:     "{sentence case}[235-239]{lower case}"
 ERND 31                \
 EJMP 13                \ Encoded as:   "{2}[31?]{13}"
 EQUB VE

 ETOK 175               \ Token 65:     "ITS [76-80] [81-85]"
 ERND 16                \
 ECHR ' '               \ Encoded as:   "[175][16?] [17?]"
 ERND 17
 EQUB VE

 ECHR 'J'               \ Token 66:     "JUICE"
 ECHR 'U'               \
 ECHR 'I'               \ Encoded as:   "JUI<233>"
 ETWO 'C', 'E'
 EQUB VE

 ECHR 'B'               \ Token 67:     "BRANDY"
 ETWO 'R', 'A'          \
 ECHR 'N'               \ Encoded as:   "B<248>NDY"
 ECHR 'D'
 ECHR 'Y'
 EQUB VE

 ECHR 'W'               \ Token 68:     "WATER"
 ETWO 'A', 'T'          \
 ETWO 'E', 'R'          \ Encoded as:   "W<245><244>"
 EQUB VE

 ECHR 'B'               \ Token 69:     "BREW"
 ETWO 'R', 'E'          \
 ECHR 'W'               \ Encoded as:   "B<242>W"
 EQUB VE

 ECHR 'G'               \ Token 70:     "GARGLE BLASTERS"
 ETWO 'A', 'R'          \
 ECHR 'G'               \ Encoded as:   "G<238>G<229> B<249><222><244>S"
 ETWO 'L', 'E'
 ECHR ' '
 ECHR 'B'
 ETWO 'L', 'A'
 ETWO 'S', 'T'
 ETWO 'E', 'R'
 ECHR 'S'
 EQUB VE

 EJMP 18                \ Token 71:     "{random 1-8 letter word}"
 EQUB VE                \
                        \ Encoded as:   "{18}"

 EJMP 17                \ Token 72:     "{system name adjective} [160-164]"
 ECHR ' '               \
 ERND 5                 \ Encoded as:   "{17} [5?]"
 EQUB VE

 EJMP 17                \ Token 73:     "{system name adjective} {random 1-8
 ECHR ' '               \                letter word}"
 EJMP 18                \
 EQUB VE                \ Encoded as:   "{17} {18}"

 EJMP 17                \ Token 74:     "{system name adjective} [170-174]"
 ECHR ' '               \
 ERND 13                \ Encoded as:   "{17} [13?]"
 EQUB VE

 ERND 13                \ Token 75:     "[170-174] {random 1-8 letter word}"
 ECHR ' '               \
 EJMP 18                \ Encoded as:   "[13?] {18}"
 EQUB VE

 ECHR 'F'               \ Token 76:     "FABULOUS"
 ETWO 'A', 'B'          \
 ECHR 'U'               \ Encoded as:   "F<216>U<224><236>"
 ETWO 'L', 'O'
 ETWO 'U', 'S'
 EQUB VE

 ECHR 'E'               \ Token 77:     "EXOTIC"
 ECHR 'X'               \
 ECHR 'O'               \ Encoded as:   "EXO<251>C"
 ETWO 'T', 'I'
 ECHR 'C'
 EQUB VE

 ECHR 'H'               \ Token 78:     "HOOPY"
 ECHR 'O'               \
 ECHR 'O'               \ Encoded as:   "HOOPY"
 ECHR 'P'
 ECHR 'Y'
 EQUB VE

 ECHR 'U'               \ Token 79:     "UNUSUAL"
 ETWO 'N', 'U'          \
 ECHR 'S'               \ Encoded as:   "U<225>SU<228>"
 ECHR 'U'
 ETWO 'A', 'L'
 EQUB VE

 ECHR 'E'               \ Token 80:     "EXCITING"
 ECHR 'X'               \
 ECHR 'C'               \ Encoded as:   "EXC<219><240>G"
 ETWO 'I', 'T'
 ETWO 'I', 'N'
 ECHR 'G'
 EQUB VE

 ECHR 'C'               \ Token 81:     "CUISINE"
 ECHR 'U'               \
 ECHR 'I'               \ Encoded as:   "CUIS<240>E"
 ECHR 'S'
 ETWO 'I', 'N'
 ECHR 'E'
 EQUB VE

 ECHR 'N'               \ Token 82:     "NIGHT LIFE"
 ECHR 'I'               \
 ECHR 'G'               \ Encoded as:   "NIGHT LIFE"
 ECHR 'H'
 ECHR 'T'
 ECHR ' '
 ECHR 'L'
 ECHR 'I'
 ECHR 'F'
 ECHR 'E'
 EQUB VE

 ECHR 'C'               \ Token 83:     "CASINOS"
 ECHR 'A'               \
 ECHR 'S'               \ Encoded as:   "CASI<227>S"
 ECHR 'I'
 ETWO 'N', 'O'
 ECHR 'S'
 EQUB VE

 ECHR 'S'               \ Token 84:     "SIT COMS"
 ETWO 'I', 'T'          \
 ECHR ' '               \ Encoded as:   "S<219> COMS"
 ECHR 'C'
 ECHR 'O'
 ECHR 'M'
 ECHR 'S'
 EQUB VE

 EJMP 2                 \ Token 85:     "{sentence case}[235-239]{lower case}"
 ERND 31                \
 EJMP 13                \ Encoded as:   "{2}[31?]{13}"
 EQUB VE

 EJMP 3                 \ Token 86:     "{selected system name}"
 EQUB VE                \
                        \ Encoded as:   "{3}"

 ETOK 147               \ Token 87:     "THE PLANET {selected system name}"
 ETOK 145               \
 ECHR ' '               \ Encoded as:   "[147][145] {3}"
 EJMP 3
 EQUB VE

 ETOK 147               \ Token 88:     "THE WORLD {selected system name}"
 ETOK 146               \
 ECHR ' '               \ Encoded as:   "[147][146] {3}"
 EJMP 3
 EQUB VE

 ETOK 148               \ Token 89:     "THIS PLANET"
 ETOK 145               \
 EQUB VE                \ Encoded as:   "[148][145]"

 ETOK 148               \ Token 90:     "THIS WORLD"
 ETOK 146               \
 EQUB VE                \ Encoded as:   "[148][146]"

 ECHR 'S'               \ Token 91:     "SON OF A BITCH"
 ETWO 'O', 'N'          \
 ECHR ' '               \ Encoded as:   "S<223> OF[208]B<219>CH"
 ECHR 'O'
 ECHR 'F'
 ETOK 208
 ECHR 'B'
 ETWO 'I', 'T'
 ECHR 'C'
 ECHR 'H'
 EQUB VE

 ECHR 'S'               \ Token 92:     "SCOUNDREL"
 ECHR 'C'               \
 ETWO 'O', 'U'          \ Encoded as:   "SC<217>ND<242>L"
 ECHR 'N'
 ECHR 'D'
 ETWO 'R', 'E'
 ECHR 'L'
 EQUB VE

 ECHR 'B'               \ Token 93:     "BLACKGUARD"
 ETWO 'L', 'A'          \
 ECHR 'C'               \ Encoded as:   "B<249>CKGU<238>D"
 ECHR 'K'
 ECHR 'G'
 ECHR 'U'
 ETWO 'A', 'R'
 ECHR 'D'
 EQUB VE

 ECHR 'R'               \ Token 94:     "ROGUE"
 ECHR 'O'               \
 ECHR 'G'               \ Encoded as:   "ROGUE"
 ECHR 'U'
 ECHR 'E'
 EQUB VE

 ECHR 'W'               \ Token 95:     "WHORESON BEETLE HEAD FLAP EAR'D
 ECHR 'H'               \                KNAVE"
 ETWO 'O', 'R'          \
 ETWO 'E', 'S'          \ Encoded as:   "WH<253><237><223> <247><221><229> HEAD
 ETWO 'O', 'N'          \                [198]F<249>P E<238>[39]D KNA<250>"
 ECHR ' '
 ETWO 'B', 'E'
 ETWO 'E', 'T'
 ETWO 'L', 'E'
 ECHR ' '
 ECHR 'H'
 ECHR 'E'
 ECHR 'A'
 ECHR 'D'
 ETOK 198
 ECHR 'F'
 ETWO 'L', 'A'
 ECHR 'P'
 ECHR ' '
 ECHR 'E'
 ETWO 'A', 'R'
 ECHR '`'
 ECHR 'D'
 ECHR ' '
 ECHR 'K'
 ECHR 'N'
 ECHR 'A'
 ETWO 'V', 'E'
 EQUB VE

 ECHR 'N'               \ Token 96:     "N UNREMARKABLE"
 ECHR ' '               \
 ECHR 'U'               \ Encoded as:   "N UN<242><239>RK<216><229>"
 ECHR 'N'
 ETWO 'R', 'E'
 ETWO 'M', 'A'
 ECHR 'R'
 ECHR 'K'
 ETWO 'A', 'B'
 ETWO 'L', 'E'
 EQUB VE

 ECHR ' '               \ Token 97:     " BORING"
 ECHR 'B'               \
 ETWO 'O', 'R'          \ Encoded as:   " B<253><240>G"
 ETWO 'I', 'N'
 ECHR 'G'
 EQUB VE

 ECHR ' '               \ Token 98:     " DULL"
 ECHR 'D'               \
 ECHR 'U'               \ Encoded as:   " DULL"
 ECHR 'L'
 ECHR 'L'
 EQUB VE

 ECHR ' '               \ Token 99:     " TEDIOUS"
 ECHR 'T'               \
 ECHR 'E'               \ Encoded as:   " TE<241>O<236>"
 ETWO 'D', 'I'
 ECHR 'O'
 ETWO 'U', 'S'
 EQUB VE

 ECHR ' '               \ Token 100:    " REVOLTING"
 ETWO 'R', 'E'          \
 ECHR 'V'               \ Encoded as:   " <242>VOLT<240>G"
 ECHR 'O'
 ECHR 'L'
 ECHR 'T'
 ETWO 'I', 'N'
 ECHR 'G'
 EQUB VE

 ETOK 145               \ Token 101:    "PLANET"
 EQUB VE                \
                        \ Encoded as:   "[145]"

 ETOK 146               \ Token 102:    "WORLD"
 EQUB VE                \
                        \ Encoded as:   "[146]"

 ECHR 'P'               \ Token 103:    "PLACE"
 ETWO 'L', 'A'          \
 ETWO 'C', 'E'          \ Encoded as:   "P<249><233>"
 EQUB VE

 ECHR 'L'               \ Token 104:    "LITTLE PLANET"
 ETWO 'I', 'T'          \
 ECHR 'T'               \ Encoded as:   "L<219>T<229> [145]"
 ETWO 'L', 'E'
 ECHR ' '
 ETOK 145
 EQUB VE

 ECHR 'D'               \ Token 105:    "DUMP"
 ECHR 'U'               \
 ECHR 'M'               \ Encoded as:   "DUMP"
 ECHR 'P'
 EQUB VE

 EQUB VE                \ Token 106:    ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 107:    ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 108:    ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 109:    ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 110:    ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 111:    ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 112:    ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 113:    ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 114:    ""
                        \
                        \ Encoded as:   ""

 ECHR 'W'               \ Token 115:    "WASP"
 ECHR 'A'               \
 ECHR 'S'               \ Encoded as:   "WASP"
 ECHR 'P'
 EQUB VE

 ECHR 'M'               \ Token 116:    "MOTH"
 ECHR 'O'               \
 ETWO 'T', 'H'          \ Encoded as:   "MO<226>"
 EQUB VE

 ECHR 'G'               \ Token 117:    "GRUB"
 ECHR 'R'               \
 ECHR 'U'               \ Encoded as:   "GRUB"
 ECHR 'B'
 EQUB VE

 ETWO 'A', 'N'          \ Token 118:    "ANT"
 ECHR 'T'               \
 EQUB VE                \ Encoded as:   "<255>T"

 EJMP 18                \ Token 119:    "{random 1-8 letter word}"
 EQUB VE                \
                        \ Encoded as:   "{18}"

 ECHR 'P'               \ Token 120:    "POET"
 ECHR 'O'               \
 ETWO 'E', 'T'          \ Encoded as:   "PO<221>"
 EQUB VE

 ETWO 'A', 'R'          \ Token 121:    "ARTS GRADUATE"
 ECHR 'T'               \
 ECHR 'S'               \ Encoded as:   "<238>TS G<248>DU<245>E"
 ECHR ' '
 ECHR 'G'
 ETWO 'R', 'A'
 ECHR 'D'
 ECHR 'U'
 ETWO 'A', 'T'
 ECHR 'E'
 EQUB VE

 ECHR 'Y'               \ Token 122:    "YAK"
 ECHR 'A'               \
 ECHR 'K'               \ Encoded as:   "YAK"
 EQUB VE

 ECHR 'S'               \ Token 123:    "SNAIL"
 ECHR 'N'               \
 ECHR 'A'               \ Encoded as:   "SNA<220>"
 ETWO 'I', 'L'
 EQUB VE

 ECHR 'S'               \ Token 124:    "SLUG"
 ECHR 'L'               \
 ECHR 'U'               \ Encoded as:   "SLUG"
 ECHR 'G'
 EQUB VE

 ECHR 'T'               \ Token 125:    "TROPICAL"
 ECHR 'R'               \
 ECHR 'O'               \ Encoded as:   "TROPIC<228>"
 ECHR 'P'
 ECHR 'I'
 ECHR 'C'
 ETWO 'A', 'L'
 EQUB VE

 ECHR 'D'               \ Token 126:    "DENSE"
 ETWO 'E', 'N'          \
 ETWO 'S', 'E'          \ Encoded as:   "D<246><218>"
 EQUB VE

 ETWO 'R', 'A'          \ Token 127:    "RAIN"
 ETWO 'I', 'N'          \
 EQUB VE                \ Encoded as:   "<248><240>"

 ECHR 'I'               \ Token 128:    "IMPENETRABLE"
 ECHR 'M'               \
 ECHR 'P'               \ Encoded as:   "IMP<246><221><248>B<229>"
 ETWO 'E', 'N'
 ETWO 'E', 'T'
 ETWO 'R', 'A'
 ECHR 'B'
 ETWO 'L', 'E'
 EQUB VE

 ECHR 'E'               \ Token 129:    "EXUBERANT"
 ECHR 'X'               \
 ECHR 'U'               \ Encoded as:   "EXU<247><248>NT"
 ETWO 'B', 'E'
 ETWO 'R', 'A'
 ECHR 'N'
 ECHR 'T'
 EQUB VE

 ECHR 'F'               \ Token 130:    "FUNNY"
 ECHR 'U'               \
 ECHR 'N'               \ Encoded as:   "FUNNY"
 ECHR 'N'
 ECHR 'Y'
 EQUB VE

 ECHR 'W'               \ Token 131:    "WIERD"
 ECHR 'I'               \
 ETWO 'E', 'R'          \ Encoded as:   "WI<244>D"
 ECHR 'D'
 EQUB VE

 ECHR 'U'               \ Token 132:    "UNUSUAL"
 ETWO 'N', 'U'          \
 ECHR 'S'               \ Encoded as:   "U<225>SU<228>"
 ECHR 'U'
 ETWO 'A', 'L'
 EQUB VE

 ETWO 'S', 'T'          \ Token 133:    "STRANGE"
 ETWO 'R', 'A'          \
 ECHR 'N'               \ Encoded as:   "<222><248>N<231>"
 ETWO 'G', 'E'
 EQUB VE

 ECHR 'P'               \ Token 134:    "PECULIAR"
 ECHR 'E'               \
 ECHR 'C'               \ Encoded as:   "PECULI<238>"
 ECHR 'U'
 ECHR 'L'
 ECHR 'I'
 ETWO 'A', 'R'
 EQUB VE

 ECHR 'F'               \ Token 135:    "FREQUENT"
 ETWO 'R', 'E'          \
 ETWO 'Q', 'U'          \ Encoded as:   "F<242><254><246>T"
 ETWO 'E', 'N'
 ECHR 'T'
 EQUB VE

 ECHR 'O'               \ Token 136:    "OCCASIONAL"
 ECHR 'C'               \
 ECHR 'C'               \ Encoded as:   "OCCASI<223><228>"
 ECHR 'A'
 ECHR 'S'
 ECHR 'I'
 ETWO 'O', 'N'
 ETWO 'A', 'L'
 EQUB VE

 ECHR 'U'               \ Token 137:    "UNPREDICTABLE"
 ECHR 'N'               \
 ECHR 'P'               \ Encoded as:   "UNP<242><241>CT<216><229>"
 ETWO 'R', 'E'
 ETWO 'D', 'I'
 ECHR 'C'
 ECHR 'T'
 ETWO 'A', 'B'
 ETWO 'L', 'E'
 EQUB VE

 ECHR 'D'               \ Token 138:    "DREADFUL"
 ETWO 'R', 'E'          \
 ECHR 'A'               \ Encoded as:   "D<242>ADFUL"
 ECHR 'D'
 ECHR 'F'
 ECHR 'U'
 ECHR 'L'
 EQUB VE

 ETOK 171               \ Token 139:    "DEADLY"
 EQUB VE                \
                        \ Encoded as:   "[171]"

 ERND 1                 \ Token 140:    "[21-25] [16-20] FOR [61-65]"
 ECHR ' '               \
 ERND 0                 \ Encoded as:   "[1?] [0?] F<253> [10?]"
 ECHR ' '
 ECHR 'F'
 ETWO 'O', 'R'
 ECHR ' '
 ERND 10
 EQUB VE

 ETOK 140               \ Token 141:    "[21-25] [16-20] FOR [61-65] AND
 ETOK 178               \                [61-65]"
 ERND 10                \
 EQUB VE                \ Encoded as:   "[140][178][10?]"

 ERND 11                \ Token 142:    "[51-55] BY [56-60]"
 ECHR ' '               \
 ECHR 'B'               \ Encoded as:   "[11?] BY [12?]"
 ECHR 'Y'
 ECHR ' '
 ERND 12
 EQUB VE

 ETOK 140               \ Token 143:    "[21-25] [16-20] FOR [61-65] BUT [51-55]
 ECHR ' '               \                BY [56-60]"
 ECHR 'B'               \
 ECHR 'U'               \ Encoded as:   "[140] BUT [142]"
 ECHR 'T'
 ECHR ' '
 ETOK 142
 EQUB VE

 ECHR ' '               \ Token 144:    " A[96-100] [101-105]"
 ECHR 'A'               \
 ERND 20                \ Encoded as:   " A[20?] [21?]"
 ECHR ' '
 ERND 21
 EQUB VE

 ECHR 'P'               \ Token 145:    "PLANET"
 ECHR 'L'               \
 ETWO 'A', 'N'          \ Encoded as:   "PL<255><221>"
 ETWO 'E', 'T'
 EQUB VE

 ECHR 'W'               \ Token 146:    "WORLD"
 ETWO 'O', 'R'          \
 ECHR 'L'               \ Encoded as:   "W<253>LD"
 ECHR 'D'
 EQUB VE

 ETWO 'T', 'H'          \ Token 147:    "THE "
 ECHR 'E'               \
 ECHR ' '               \ Encoded as:   "<226>E "
 EQUB VE

 ETWO 'T', 'H'          \ Token 148:    "THIS "
 ECHR 'I'               \
 ECHR 'S'               \ Encoded as:   "<226>IS "
 ECHR ' '
 EQUB VE

 ETWO 'L', 'O'          \ Token 149:    "LOAD NEW {single cap}COMMANDER"
 ECHR 'A'               \
 ECHR 'D'               \ Encoded as:   "<224>AD[210][154]"
 ETOK 210
 ETOK 154
 EQUB VE

 EJMP 9                 \ Token 150:    "{clear screen}
 EJMP 11                \                {draw box around title}
 EJMP 1                 \                {all caps}
 EJMP 8                 \                {tab 6}"
 EQUB VE                \
                        \ Encoded as:   "{9}{11}{1}{8}"

 ECHR 'D'               \ Token 151:    "DRIVE"
 ECHR 'R'               \
 ECHR 'I'               \ Encoded as:   "DRI<250>"
 ETWO 'V', 'E'
 EQUB VE

 ECHR ' '               \ Token 152:    " CATALOGUE"
 ECHR 'C'               \
 ETWO 'A', 'T'          \ Encoded as:   " C<245>A<224>GUE"
 ECHR 'A'
 ETWO 'L', 'O'
 ECHR 'G'
 ECHR 'U'
 ECHR 'E'
 EQUB VE

 ECHR 'I'               \ Token 153:    "IAN"
 ETWO 'A', 'N'          \
 EQUB VE                \ Encoded as:   "I<255>"

 EJMP 19                \ Token 154:    "{single cap}COMMANDER"
 ECHR 'C'               \
 ECHR 'O'               \ Encoded as:   "{19}COMM<255>D<244>"
 ECHR 'M'
 ECHR 'M'
 ETWO 'A', 'N'
 ECHR 'D'
 ETWO 'E', 'R'
 EQUB VE

 ERND 13                \ Token 155:    "[170-174]"
 EQUB VE                \
                        \ Encoded as:   "[13?]"

 ECHR 'M'               \ Token 156:    "MOUNTAIN"
 ETWO 'O', 'U'          \
 ECHR 'N'               \ Encoded as:   "M<217>NTA<240>"
 ECHR 'T'
 ECHR 'A'
 ETWO 'I', 'N'
 EQUB VE

 ETWO 'E', 'D'          \ Token 157:    "EDIBLE"
 ECHR 'I'               \
 ECHR 'B'               \ Encoded as:   "<252>IB<229>"
 ETWO 'L', 'E'
 EQUB VE

 ECHR 'T'               \ Token 158:    "TREE"
 ETWO 'R', 'E'          \
 ECHR 'E'               \ Encoded as:   "T<242>E"
 EQUB VE

 ECHR 'S'               \ Token 159:    "SPOTTED"
 ECHR 'P'               \
 ECHR 'O'               \ Encoded as:   "SPOTT<252>"
 ECHR 'T'
 ECHR 'T'
 ETWO 'E', 'D'
 EQUB VE

 ERND 29                \ Token 160:    "[225-229]"
 EQUB VE                \
                        \ Encoded as:   "[29?]"

 ERND 30                \ Token 161:    "[230-234]"
 EQUB VE                \
                        \ Encoded as:   "[30?]"

 ERND 6                 \ Token 162:    "[46-50]OID"
 ECHR 'O'               \
 ECHR 'I'               \ Encoded as:   "[6?]OID"
 ECHR 'D'
 EQUB VE

 ERND 36                \ Token 163:    "[120-124]"
 EQUB VE                \
                        \ Encoded as:   "[36?]"

 ERND 35                \ Token 164:    "[115-119]"
 EQUB VE                \
                        \ Encoded as:   "[35?]"

 ETWO 'A', 'N'          \ Token 165:    "ANCIENT"
 ECHR 'C'               \
 ECHR 'I'               \ Encoded as:   "<255>CI<246>T"
 ETWO 'E', 'N'
 ECHR 'T'
 EQUB VE

 ECHR 'E'               \ Token 166:    "EXCEPTIONAL"
 ECHR 'X'               \
 ETWO 'C', 'E'          \ Encoded as:   "EX<233>P<251><223><228>"
 ECHR 'P'
 ETWO 'T', 'I'
 ETWO 'O', 'N'
 ETWO 'A', 'L'
 EQUB VE

 ECHR 'E'               \ Token 167:    "ECCENTRIC"
 ECHR 'C'               \
 ETWO 'C', 'E'          \ Encoded as:   "EC<233>NTRIC"
 ECHR 'N'
 ECHR 'T'
 ECHR 'R'
 ECHR 'I'
 ECHR 'C'
 EQUB VE

 ETWO 'I', 'N'          \ Token 168:    "INGRAINED"
 ECHR 'G'               \
 ETWO 'R', 'A'          \ Encoded as:   "<240>G<248><240><252>"
 ETWO 'I', 'N'
 ETWO 'E', 'D'
 EQUB VE

 ERND 23                \ Token 169:    "[130-134]"
 EQUB VE                \
                        \ Encoded as:   "[23?]"

 ECHR 'K'               \ Token 170:    "KILLER"
 ETWO 'I', 'L'          \
 ECHR 'L'               \ Encoded as:   "K<220>L<244>"
 ETWO 'E', 'R'
 EQUB VE

 ECHR 'D'               \ Token 171:    "DEADLY"
 ECHR 'E'               \
 ECHR 'A'               \ Encoded as:   "DEADLY"
 ECHR 'D'
 ECHR 'L'
 ECHR 'Y'
 EQUB VE

 ECHR 'E'               \ Token 172:    "EVIL"
 ECHR 'V'               \
 ETWO 'I', 'L'          \ Encoded as:   "EV<220>"
 EQUB VE

 ETWO 'L', 'E'          \ Token 173:    "LETHAL"
 ETWO 'T', 'H'          \
 ETWO 'A', 'L'          \ Encoded as:   "<229><226><228>"
 EQUB VE

 ECHR 'V'               \ Token 174:    "VICIOUS"
 ECHR 'I'               \
 ECHR 'C'               \ Encoded as:   "VICIO<236>"
 ECHR 'I'
 ECHR 'O'
 ETWO 'U', 'S'
 EQUB VE

 ETWO 'I', 'T'          \ Token 175:    "ITS "
 ECHR 'S'               \
 ECHR ' '               \ Encoded as:   "<219>S "
 EQUB VE

 EJMP 13                \ Token 176:    "{lower case}
 EJMP 14                \                {justify}
 EJMP 19                \                {single cap}"
 EQUB VE                \
                        \ Encoded as:   "{13}{14}{19}"

 ECHR '.'               \ Token 177:    ".{cr}
 EJMP 12                \                {left align}"
 EJMP 15                \
 EQUB VE                \ Encoded as:   ".{12}{15}"

 ECHR ' '               \ Token 178:    " AND "
 ETWO 'A', 'N'          \
 ECHR 'D'               \ Encoded as:   " <255>D "
 ECHR ' '
 EQUB VE

 ECHR 'Y'               \ Token 179:    "YOU"
 ETWO 'O', 'U'          \
 EQUB VE                \ Encoded as:   "Y<217>"

 ECHR 'P'               \ Token 180:    "PARKING METERS"
 ETWO 'A', 'R'          \
 ECHR 'K'               \ Encoded as:   "P<238>K[195]M<221><244>S"
 ETOK 195
 ECHR 'M'
 ETWO 'E', 'T'
 ETWO 'E', 'R'
 ECHR 'S'
 EQUB VE

 ECHR 'D'               \ Token 181:    "DUST CLOUDS"
 ETWO 'U', 'S'          \
 ECHR 'T'               \ Encoded as:   "D<236>T C<224>UDS"
 ECHR ' '
 ECHR 'C'
 ETWO 'L', 'O'
 ECHR 'U'
 ECHR 'D'
 ECHR 'S'
 EQUB VE

 ECHR 'I'               \ Token 182:    "ICE BERGS"
 ETWO 'C', 'E'          \
 ECHR ' '               \ Encoded as:   "I<233> <247>RGS"
 ETWO 'B', 'E'
 ECHR 'R'
 ECHR 'G'
 ECHR 'S'
 EQUB VE

 ECHR 'R'               \ Token 183:    "ROCK FORMATIONS"
 ECHR 'O'               \
 ECHR 'C'               \ Encoded as:   "ROCK F<253><239><251><223>S"
 ECHR 'K'
 ECHR ' '
 ECHR 'F'
 ETWO 'O', 'R'
 ETWO 'M', 'A'
 ETWO 'T', 'I'
 ETWO 'O', 'N'
 ECHR 'S'
 EQUB VE

 ECHR 'V'               \ Token 184:    "VOLCANOES"
 ECHR 'O'               \
 ECHR 'L'               \ Encoded as:   "VOLCA<227><237>"
 ECHR 'C'
 ECHR 'A'
 ETWO 'N', 'O'
 ETWO 'E', 'S'
 EQUB VE

 ECHR 'P'               \ Token 185:    "PLANT"
 ECHR 'L'               \
 ETWO 'A', 'N'          \ Encoded as:   "PL<255>T"
 ECHR 'T'
 EQUB VE

 ECHR 'T'               \ Token 186:    "TULIP"
 ECHR 'U'               \
 ECHR 'L'               \ Encoded as:   "TULIP"
 ECHR 'I'
 ECHR 'P'
 EQUB VE

 ECHR 'B'               \ Token 187:    "BANANA"
 ETWO 'A', 'N'          \
 ETWO 'A', 'N'          \ Encoded as:   "B<255><255>A"
 ECHR 'A'
 EQUB VE

 ECHR 'C'               \ Token 188:    "CORN"
 ETWO 'O', 'R'          \
 ECHR 'N'               \ Encoded as:   "C<253>N"
 EQUB VE

 EJMP 18                \ Token 189:    "{random 1-8 letter word}WEED"
 ECHR 'W'               \
 ECHR 'E'               \ Encoded as:   "{18}WE<252>"
 ETWO 'E', 'D'
 EQUB VE

 EJMP 18                \ Token 190:    "{random 1-8 letter word}"
 EQUB VE                \
                        \ Encoded as:   "{18}"

 EJMP 17                \ Token 191:    "{system name adjective} {random 1-8
 ECHR ' '               \                letter word}"
 EJMP 18                \
 EQUB VE                \ Encoded as:   "{17} {18}"

 EJMP 17                \ Token 192:    "{system name adjective} [170-174]"
 ECHR ' '               \
 ERND 13                \ Encoded as:   "{17} [13?]"
 EQUB VE

 ETWO 'I', 'N'          \ Token 193:    "INHABITANT"
 ECHR 'H'               \
 ECHR 'A'               \ Encoded as:   "<240>HA<234>T<255>T"
 ETWO 'B', 'I'
 ECHR 'T'
 ETWO 'A', 'N'
 ECHR 'T'
 EQUB VE

 ETOK 191               \ Token 194:    "{system name adjective} {random 1-8
 EQUB VE                \                letter word}"
                        \
                        \ Encoded as:   "[191]"

 ETWO 'I', 'N'          \ Token 195:    "ING "
 ECHR 'G'               \
 ECHR ' '               \ Encoded as:   "<240>G "
 EQUB VE

 ETWO 'E', 'D'          \ Token 196:    "ED "
 ECHR ' '               \
 EQUB VE                \ Encoded as:   "<252> "

 EQUB VE                \ Token 197:    ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 198:    ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 199:    ""
                        \
                        \ Encoded as:   ""

 ECHR ' '               \ Token 200:    " NAME? "
 ECHR 'N'               \
 ECHR 'A'               \ Encoded as:   " NAME? "
 ECHR 'M'
 ECHR 'E'
 ECHR '?'
 ECHR ' '
 EQUB VE

 ECHR ' '               \ Token 201:    " TO "
 ECHR 'T'               \
 ECHR 'O'               \ Encoded as:   " TO "
 ECHR ' '
 EQUB VE

 ECHR ' '               \ Token 202:    " IS "
 ECHR 'I'               \
 ECHR 'S'               \ Encoded as:   " IS "
 ECHR ' '
 EQUB VE

 ECHR 'W'               \ Token 203:    "WAS LAST SEEN AT {single cap}"
 ECHR 'A'               \
 ECHR 'S'               \ Encoded as:   "WAS <249><222> <218><246> <245> {19}"
 ECHR ' '
 ETWO 'L', 'A'
 ETWO 'S', 'T'
 ECHR ' '
 ETWO 'S', 'E'
 ETWO 'E', 'N'
 ECHR ' '
 ETWO 'A', 'T'
 ECHR ' '
 EJMP 19
 EQUB VE

 ECHR '.'               \ Token 204:    ".{cr}
 EJMP 12                \                 {single cap}"
 ECHR ' '               \
 EJMP 19                \ Encoded as:   ".{12} {19}"
 EQUB VE

 ECHR 'D'               \ Token 205:    "DOCKED"
 ECHR 'O'               \
 ECHR 'C'               \ Encoded as:   "DOCK<252>"
 ECHR 'K'
 ETWO 'E', 'D'
 EQUB VE

 EJMP 1                 \ Token 206:    "{all caps}(Y/N)?"
 ECHR '('               \
 ECHR 'Y'               \ Encoded as:   "{1}(Y/N)?"
 ECHR '/'
 ECHR 'N'
 ECHR ')'
 ECHR '?'
 EQUB VE

 ECHR 'S'               \ Token 207:    "SHIP"
 ECHR 'H'               \
 ECHR 'I'               \ Encoded as:   "SHIP"
 ECHR 'P'
 EQUB VE

 ECHR ' '               \ Token 208:    " A "
 ECHR 'A'               \
 ECHR ' '               \ Encoded as:   " A "
 EQUB VE

 ECHR ' '               \ Token 209:    " ERRIUS"
 ETWO 'E', 'R'          \
 ECHR 'R'               \ Encoded as:   " <244>RI<236>"
 ECHR 'I'
 ETWO 'U', 'S'
 EQUB VE

 ECHR ' '               \ Token 210:    " NEW "
 ECHR 'N'               \
 ECHR 'E'               \ Encoded as:   " NEW "
 ECHR 'W'
 ECHR ' '
 EQUB VE

 EQUB VE                \ Token 211:    ""
                        \
                        \ Encoded as:   ""

 ETOK 177               \ Token 212:    ".{cr}
 EJMP 8                 \                {left align}
 EJMP 1                 \                {tab 6}{all caps}  MESSAGE ENDS"
 ECHR ' '               \
 ECHR ' '               \ Encoded as:   "[177]{8}{1}  M<237>SA<231> <246>DS"
 ECHR 'M'
 ETWO 'E', 'S'
 ECHR 'S'
 ECHR 'A'
 ETWO 'G', 'E'
 ECHR ' '
 ETWO 'E', 'N'
 ECHR 'D'
 ECHR 'S'
 EQUB VE

 EQUB VE                \ Token 213:    ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 214:    ""
                        \
                        \ Encoded as:   ""

 EJMP 15                \ Token 215:    "{left align} UNKNOWN PLANET"
 ECHR ' '               \
 ECHR 'U'               \ Encoded as:   "{15} UNK<227>WN [145]"
 ECHR 'N'
 ECHR 'K'
 ETWO 'N', 'O'
 ECHR 'W'
 ECHR 'N'
 ECHR ' '
 ETOK 145
 EQUB VE

 EJMP 9                 \ Token 216:    "{clear screen}
 EJMP 8                 \                {tab 6}
 EJMP 23                \                {move to row 10, white, lower case}
 EJMP 1                 \                {all caps}
 ETWO 'I', 'N'          \                INCOMING MESSAGE"
 ECHR 'C'               \
 ECHR 'O'               \ Encoded as:   "{9}{8}{23}{1}<240>COM[195]M<237>SA
 ECHR 'M'               \                <231>"
 ETOK 195
 ECHR 'M'
 ETWO 'E', 'S'
 ECHR 'S'
 ECHR 'A'
 ETWO 'G', 'E'
 EQUB VE

 EQUB VE                \ Token 217:    ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 218:    ""
                        \
                        \ Encoded as:   ""

 ECHR 'F'               \ Token 219:    "FORTESQUE"
 ETWO 'O', 'R'          \
 ECHR 'T'               \ Encoded as:   "F<253>T<237><254>E"
 ETWO 'E', 'S'
 ETWO 'Q', 'U'
 ECHR 'E'
 EQUB VE

 ETOK 203               \ Token 220:    "WAS LAST SEEN AT {single cap}REESDICE"
 ETWO 'R', 'E'          \
 ETWO 'E', 'S'          \ Encoded as:   "[203]<242><237><241><233>"
 ETWO 'D', 'I'
 ETWO 'C', 'E'
 EQUB VE

 EQUB VE                \ Token 221:    ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 222:    ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 223:    ""
                        \
                        \ Encoded as:   ""

 EQUB VE                \ Token 224:    ""
                        \
                        \ Encoded as:   ""

 ECHR 'S'               \ Token 225:    "SHREW"
 ECHR 'H'               \
 ETWO 'R', 'E'          \ Encoded as:   "SH<242>W"
 ECHR 'W'
 EQUB VE

 ETWO 'B', 'E'          \ Token 226:    "BEAST"
 ECHR 'A'               \
 ETWO 'S', 'T'          \ Encoded as:   "<247>A<222>"
 EQUB VE

 ETWO 'B', 'I'          \ Token 227:    "BISON"
 ECHR 'S'               \
 ETWO 'O', 'N'          \ Encoded as:   "<234>IS<223>"
 EQUB VE

 ECHR 'S'               \ Token 228:    "SNAKE"
 ECHR 'N'               \
 ECHR 'A'               \ Encoded as:   "SNAKE"
 ECHR 'K'
 ECHR 'E'
 EQUB VE

 ECHR 'W'               \ Token 229:    "WOLF"
 ECHR 'O'               \
 ECHR 'L'               \ Encoded as:   "WOLF"
 ECHR 'F'
 EQUB VE

 ETWO 'L', 'E'          \ Token 230:    "LEOPARD"
 ECHR 'O'               \
 ECHR 'P'               \ Encoded as:   "<229>OP<238>D"
 ETWO 'A', 'R'
 ECHR 'D'
 EQUB VE

 ECHR 'C'               \ Token 231:    "CAT"
 ETWO 'A', 'T'          \
 EQUB VE                \ Encoded as:   "C<245>"

 ECHR 'M'               \ Token 232:    "MONKEY"
 ETWO 'O', 'N'          \
 ECHR 'K'               \ Encoded as:   "M<223>KEY"
 ECHR 'E'
 ECHR 'Y'
 EQUB VE

 ECHR 'G'               \ Token 233:    "GOAT"
 ECHR 'O'               \
 ETWO 'A', 'T'          \ Encoded as:   "GO<245>"
 EQUB VE

 ECHR 'F'               \ Token 234:    "FISH"
 ECHR 'I'               \
 ECHR 'S'               \ Encoded as:   "FISH"
 ECHR 'H'
 EQUB VE

 ERND 15                \ Token 235:    "[71-75] [66-70]"
 ECHR ' '               \
 ERND 14                \ Encoded as:   "[15?] [14?]"
 EQUB VE

 EJMP 17                \ Token 236:    "{system name adjective} [225-229]
 ECHR ' '               \                 [240-244]"
 ERND 29                \
 ECHR ' '               \ Encoded as:   "{17} [29?] [32?]"
 ERND 32
 EQUB VE

 ETOK 175               \ Token 237:    "ITS [76-80] [230-234] [240-244]"
 ERND 16                \
 ECHR ' '               \ Encoded as:   "[175][16?] [30?] [32?]"
 ERND 30
 ECHR ' '
 ERND 32
 EQUB VE

 ERND 33                \ Token 238:    "[245-249] [250-254]"
 ECHR ' '               \
 ERND 34                \ Encoded as:   "[33?] [34?]"
 EQUB VE

 ERND 15                \ Token 239:    "[71-75] [66-70]"
 ECHR ' '               \
 ERND 14                \ Encoded as:   "[15?] [14?]"
 EQUB VE

 ECHR 'M'               \ Token 240:    "MEAT"
 ECHR 'E'               \
 ETWO 'A', 'T'          \ Encoded as:   "ME<245>"
 EQUB VE

 ECHR 'C'               \ Token 241:    "CUTLET"
 ECHR 'U'               \
 ECHR 'T'               \ Encoded as:   "CUTL<221>"
 ECHR 'L'
 ETWO 'E', 'T'
 EQUB VE

 ETWO 'S', 'T'          \ Token 242:    "STEAK"
 ECHR 'E'               \
 ECHR 'A'               \ Encoded as:   "<222>EAK"
 ECHR 'K'
 EQUB VE

 ECHR 'B'               \ Token 243:    "BURGERS"
 ECHR 'U'               \
 ECHR 'R'               \ Encoded as:   "BURG<244>S"
 ECHR 'G'
 ETWO 'E', 'R'
 ECHR 'S'
 EQUB VE

 ETWO 'S', 'O'          \ Token 244:    "SOUP"
 ECHR 'U'               \
 ECHR 'P'               \ Encoded as:   "<235>UP"
 EQUB VE

 ECHR 'I'               \ Token 245:    "ICE"
 ETWO 'C', 'E'          \
 EQUB VE                \ Encoded as:   "I<233>"

 ECHR 'M'               \ Token 246:    "MUD"
 ECHR 'U'               \
 ECHR 'D'               \ Encoded as:   "MUD"
 EQUB VE

 ECHR 'Z'               \ Token 247:    "ZERO-{single cap}G"
 ETWO 'E', 'R'          \
 ECHR 'O'               \ Encoded as:   "Z<244>O-{19}G"
 ECHR '-'
 EJMP 19
 ECHR 'G'
 EQUB VE

 ECHR 'V'               \ Token 248:    "VACUUM"
 ECHR 'A'               \
 ECHR 'C'               \ Encoded as:   "VACUUM"
 ECHR 'U'
 ECHR 'U'
 ECHR 'M'
 EQUB VE

 EJMP 17                \ Token 249:    "{system name adjective} ULTRA"
 ECHR ' '               \
 ECHR 'U'               \ Encoded as:   "{17} ULT<248>"
 ECHR 'L'
 ECHR 'T'
 ETWO 'R', 'A'
 EQUB VE

 ECHR 'H'               \ Token 250:    "HOCKEY"
 ECHR 'O'               \
 ECHR 'C'               \ Encoded as:   "HOCKEY"
 ECHR 'K'
 ECHR 'E'
 ECHR 'Y'
 EQUB VE

 ECHR 'C'               \ Token 251:    "CRICKET"
 ECHR 'R'               \
 ECHR 'I'               \ Encoded as:   "CRICK<221>"
 ECHR 'C'
 ECHR 'K'
 ETWO 'E', 'T'
 EQUB VE

 ECHR 'K'               \ Token 252:    "KARATE"
 ETWO 'A', 'R'          \
 ETWO 'A', 'T'          \ Encoded as:   "K<238><245>E"
 ECHR 'E'
 EQUB VE

 ECHR 'P'               \ Token 253:    "POLO"
 ECHR 'O'               \
 ETWO 'L', 'O'          \ Encoded as:   "PO<224>"
 EQUB VE

 ECHR 'T'               \ Token 254:    "TENNIS"
 ETWO 'E', 'N'          \
 ECHR 'N'               \ Encoded as:   "T<246>NIS"
 ECHR 'I'
 ECHR 'S'
 EQUB VE

 EQUB VE                \ Token 255:    ""
                        \
                        \ Encoded as:   ""

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: msg_3
\       Type: Variable
\   Category: Text
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.msg_3

 EQUB VE                \ Token 0:      ""
                        \
                        \ Encoded as:   ""

 ETWO 'E', 'N'          \ Token 1:      "ENCYCLOPEDIA GALACTICA"
 ECHR 'C'               \
 ECHR 'Y'               \ Encoded as:   "<246>CYC<224>P<252>IA G<228>AC<251>CA"
 ECHR 'C'
 ETWO 'L', 'O'
 ECHR 'P'
 ETWO 'E', 'D'
 ECHR 'I'
 ECHR 'A'
 ECHR ' '
 ECHR 'G'
 ETWO 'A', 'L'
 ECHR 'A'
 ECHR 'C'
 ETWO 'T', 'I'
 ECHR 'C'
 ECHR 'A'
 EQUB VE

 ETOK 207               \ Token 2:      "SHIPS {all caps}A-G{sentence case}"
 ECHR 'S'               \
 ECHR ' '               \ Encoded as:   "[207]S {1}A-G{2}"
 EJMP 1
 ECHR 'A'
 ECHR '-'
 ECHR 'G'
 EJMP 2
 EQUB VE

 ETOK 207               \ Token 3:      "SHIPS {all caps}I-W{sentence case}""
 ECHR 'S'               \
 ECHR ' '               \ Encoded as:   "[207]S {1}I-W{2}"
 EJMP 1
 ECHR 'I'
 ECHR '-'
 ECHR 'W'
 EJMP 2
 EQUB VE

 ECHR 'E'               \ Token 4:      "EQUIPMENT"
 ETWO 'Q', 'U'          \
 ECHR 'I'               \ Encoded as:   "E<254>IPM<246>T"
 ECHR 'P'
 ECHR 'M'
 ETWO 'E', 'N'
 ECHR 'T'
 EQUB VE

 ECHR 'C'               \ Token 5:      "CONTROLS"
 ETWO 'O', 'N'          \
 ECHR 'T'               \ Encoded as:   "C<223>TROLS"
 ECHR 'R'
 ECHR 'O'
 ECHR 'L'
 ECHR 'S'
 EQUB VE

 ETWO 'I', 'N'          \ Token 6:      "INFORMATION"
 ECHR 'F'               \
 ETWO 'O', 'R'          \ Encoded as:   "<240>F<253><239><251><223>"
 ETWO 'M', 'A'
 ETWO 'T', 'I'
 ETWO 'O', 'N'
 EQUB VE

 ECHR 'A'               \ Token 7:      "ADDER"
 ECHR 'D'               \
 ECHR 'D'               \ Encoded as:   "ADD<244>"
 ETWO 'E', 'R'
 EQUB VE

 ETWO 'A', 'N'          \ Token 8:      "ANACONDA"
 ECHR 'A'               \
 ECHR 'C'               \ Encoded as:   "<255>AC<223>DA"
 ETWO 'O', 'N'
 ECHR 'D'
 ECHR 'A'
 EQUB VE

 ECHR 'A'               \ Token 9:      "ASP MK2"
 ECHR 'S'               \
 ECHR 'P'               \ Encoded as:   "ASP MK2"
 ECHR ' '
 ECHR 'M'
 ECHR 'K'
 ECHR '2'
 EQUB VE

 ECHR 'B'               \ Token 10:     "BOA"
 ECHR 'O'               \
 ECHR 'A'               \ Encoded as:   "BOA"
 EQUB VE

 ECHR 'B'               \ Token 11:     "BUSHMASTER"
 ECHR 'U'               \
 ECHR 'S'               \ Encoded as:   "BUSHMASTER"
 ECHR 'H'
 ECHR 'M'
 ECHR 'A'
 ECHR 'S'
 ECHR 'T'
 ECHR 'E'
 ECHR 'R'
 EQUB VE

 ECHR 'C'               \ Token 12:     "CHAMELEON"
 ECHR 'H'               \
 ECHR 'A'               \ Encoded as:   "CHAMELEON"
 ECHR 'M'
 ECHR 'E'
 ECHR 'L'
 ECHR 'E'
 ECHR 'O'
 ECHR 'N'
 EQUB VE

 ECHR 'C'               \ Token 13:     "COBRA MK1"
 ECHR 'O'               \
 ECHR 'B'               \ Encoded as:   "COB<248> MK1"
 ETWO 'R', 'A'
 ECHR ' '
 ECHR 'M'
 ECHR 'K'
 ECHR '1'
 EQUB VE

 ECHR 'C'               \ Token 14:     "COBRA MK3"
 ECHR 'O'               \
 ECHR 'B'               \ Encoded as:   "COB<248> MK3"
 ETWO 'R', 'A'
 ECHR ' '
 ECHR 'M'
 ECHR 'K'
 ECHR '3'
 EQUB VE

 ECHR 'C'               \ Token 15:     "CORIOLIS STATION"
 ETWO 'O', 'R'          \
 ECHR 'I'               \ Encoded as:   "C<253>IOLIS <222><245>I<223>"
 ECHR 'O'
 ECHR 'L'
 ECHR 'I'
 ECHR 'S'
 ECHR ' '
 ETWO 'S', 'T'
 ETWO 'A', 'T'
 ECHR 'I'
 ETWO 'O', 'N'
 EQUB VE

 ECHR 'D'               \ Token 16:     "DODECAGON STATION"
 ECHR 'O'               \
 ECHR 'D'               \ Encoded as:   "DODECAG<223> <222><245>I<223>"
 ECHR 'E'
 ECHR 'C'
 ECHR 'A'
 ECHR 'G'
 ETWO 'O', 'N'
 ECHR ' '
 ETWO 'S', 'T'
 ETWO 'A', 'T'
 ECHR 'I'
 ETWO 'O', 'N'
 EQUB VE

 ETWO 'E', 'S'          \ Token 17:     "ESCAPE CAPSULE"
 ECHR 'C'               \
 ECHR 'A'               \ Encoded as:   "<237>CAPE CAPSU<229>"
 ECHR 'P'
 ECHR 'E'
 ECHR ' '
 ECHR 'C'
 ECHR 'A'
 ECHR 'P'
 ECHR 'S'
 ECHR 'U'
 ETWO 'L', 'E'
 EQUB VE

 ECHR 'F'               \ Token 18:     "FER-DE-{single cap}LANCE"
 ETWO 'E', 'R'          \
 ECHR '-'               \ Encoded as:   "F<244>-DE-{19}<249>N<233>"
 ECHR 'D'
 ECHR 'E'
 ECHR '-'
 EJMP 19
 ETWO 'L', 'A'
 ECHR 'N'
 ETWO 'C', 'E'
 EQUB VE

 ETWO 'G', 'E'          \ Token 19:     "GECKO"
 ECHR 'C'               \
 ECHR 'K'               \ Encoded as:   "<231>CKO"
 ECHR 'O'
 EQUB VE

 ECHR 'G'               \ Token 20:     "GHAVIAL"
 ECHR 'H'               \
 ECHR 'A'               \ Encoded as:   "GHAVI<228>"
 ECHR 'V'
 ECHR 'I'
 ETWO 'A', 'L'
 EQUB VE

 ECHR 'I'               \ Token 21:     "IGUANA"
 ECHR 'G'               \
 ECHR 'U'               \ Encoded as:   "IGUANA"
 ECHR 'A'
 ECHR 'N'
 ECHR 'A'
 EQUB VE

 ECHR 'K'               \ Token 22:     "KRAIT"
 ETWO 'R', 'A'          \
 ETWO 'I', 'T'          \ Encoded as:   "K<248><219>"
 EQUB VE

 ETWO 'M', 'A'          \ Token 23:     "MAMBA"
 ECHR 'M'               \
 ECHR 'B'               \ Encoded as:   "<239>MBA"
 ECHR 'A'
 EQUB VE

 ECHR 'M'               \ Token 24:     "MONITOR"
 ETWO 'O', 'N'          \
 ETWO 'I', 'T'          \ Encoded as:   "M<223><219><253>"
 ETWO 'O', 'R'
 EQUB VE

 ECHR 'M'               \ Token 25:     "MORAY"
 ECHR 'O'               \
 ETWO 'R', 'A'          \ Encoded as:   "MO<248>Y"
 ECHR 'Y'
 EQUB VE

 ECHR 'O'               \ Token 26:     "OPHIDIAN"
 ECHR 'P'               \
 ECHR 'H'               \ Encoded as:   "OPHI<241><255>"
 ECHR 'I'
 ETWO 'D', 'I'
 ETWO 'A', 'N'
 EQUB VE

 ECHR 'P'               \ Token 27:     "PYTHON"
 ECHR 'Y'               \
 ETWO 'T', 'H'          \ Encoded as:   "PY<226><223>"
 ETWO 'O', 'N'
 EQUB VE

 ECHR 'S'               \ Token 28:     "SHUTTLE"
 ECHR 'H'               \
 ECHR 'U'               \ Encoded as:   "SHUTT<229>"
 ECHR 'T'
 ECHR 'T'
 ETWO 'L', 'E'
 EQUB VE

 ECHR 'S'               \ Token 29:     "SIDEWINDER"
 ECHR 'I'               \
 ECHR 'D'               \ Encoded as:   "SIDEW<240>D<244>"
 ECHR 'E'
 ECHR 'W'
 ETWO 'I', 'N'
 ECHR 'D'
 ETWO 'E', 'R'
 EQUB VE

 ETWO 'T', 'H'          \ Token 30:     "THARGOID"
 ETWO 'A', 'R'          \
 ECHR 'G'               \ Encoded as:   "<226><238>GOID"
 ECHR 'O'
 ECHR 'I'
 ECHR 'D'
 EQUB VE

 ETWO 'T', 'H'          \ Token 31:     "THARGON"
 ETWO 'A', 'R'          \
 ECHR 'G'               \ Encoded as:   "<226><238>G<223>"
 ETWO 'O', 'N'
 EQUB VE

 ECHR 'T'               \ Token 32:     "TRANSPORTER"
 ETWO 'R', 'A'          \
 ECHR 'N'               \ Encoded as:   "T<248>NSP<253>T<244>"
 ECHR 'S'
 ECHR 'P'
 ETWO 'O', 'R'
 ECHR 'T'
 ETWO 'E', 'R'
 EQUB VE

 ECHR 'V'               \ Token 33:     "VIPER"
 ECHR 'I'               \
 ECHR 'P'               \ Encoded as:   "VIP<244>"
 ETWO 'E', 'R'
 EQUB VE

 ECHR 'W'               \ Token 34:     "WORM"
 ETWO 'O', 'R'          \
 ECHR 'M'               \ Encoded as:   "W<253>M"
 EQUB VE

 ETWO 'A', 'R'          \ Token 35:     "ARMAMENTS:"
 ETWO 'M', 'A'          \
 ECHR 'M'               \ Encoded as:   "<238><239>M<246>TS:"
 ETWO 'E', 'N'
 ECHR 'T'
 ECHR 'S'
 ECHR ':'
 EQUB VE

 ECHR 'S'               \ Token 36:     "SPEED:"
 ECHR 'P'               \
 ECHR 'E'               \ Encoded as:   "SPE<252>:"
 ETWO 'E', 'D'
 ECHR ':'
 EQUB VE

 ETWO 'I', 'N'          \ Token 37:     "INSERVICE DATE:"
 ETWO 'S', 'E'          \
 ECHR 'R'               \ Encoded as:   "<240><218>RVI<233> D<245>E:"
 ECHR 'V'
 ECHR 'I'
 ETWO 'C', 'E'
 ECHR ' '
 ECHR 'D'
 ETWO 'A', 'T'
 ECHR 'E'
 ECHR ':'
 EQUB VE

 ECHR 'C'               \ Token 38:     "COMBAT"
 ECHR 'O'               \
 ECHR 'M'               \ Encoded as:   "COMB<245>"
 ECHR 'B'
 ETWO 'A', 'T'
 EQUB VE

 ECHR 'C'               \ Token 39:     "CREW:"
 ETWO 'R', 'E'          \
 ECHR 'W'               \ Encoded as:   "C<242>W:"
 ECHR ':'
 EQUB VE

 ETOK 151               \ Token 40:     "DRIVE MOTORS:"
 ECHR ' '               \
 ECHR 'M'               \ Encoded as:   "[151] MOT<253>S:"
 ECHR 'O'
 ECHR 'T'
 ETWO 'O', 'R'
 ECHR 'S'
 ECHR ':'
 EQUB VE

 ETWO 'R', 'A'          \ Token 41:     "RANGE:"
 ECHR 'N'               \
 ETWO 'G', 'E'          \ Encoded as:   "<248>N<231>:"
 ECHR ':'
 EQUB VE

 ECHR 'F'               \ Token 42:     "FT"
 ECHR 'T'               \
 EQUB VE                \ Encoded as:   "FT"

 ETWO 'D', 'I'          \ Token 43:     "DIMENSIONS:"
 ECHR 'M'               \
 ETWO 'E', 'N'          \ Encoded as:   "<241>M<246>SI<223>S:"
 ECHR 'S'
 ECHR 'I'
 ETWO 'O', 'N'
 ECHR 'S'
 ECHR ':'
 EQUB VE

 ECHR 'H'               \ Token 44:     "HULL:"
 ECHR 'U'               \
 ECHR 'L'               \ Encoded as:   "HULL:"
 ECHR 'L'
 ECHR ':'
 EQUB VE

 ECHR 'S'               \ Token 45:     "SPACE:"
 ECHR 'P'               \
 ECHR 'A'               \ Encoded as:   "SPA<233>:"
 ETWO 'C', 'E'
 ECHR ':'
 EQUB VE

 ECHR ' '               \ Token 46:     " MISSILES"
 ECHR 'M'               \
 ECHR 'I'               \ Encoded as:   " MISS<220><237>"
 ECHR 'S'
 ECHR 'S'
 ETWO 'I', 'L'
 ETWO 'E', 'S'
 EQUB VE

 ECHR 'F'               \ Token 47:     "FACTOR:"
 ECHR 'A'               \
 ECHR 'C'               \ Encoded as:   "FACT<253>:"
 ECHR 'T'
 ETWO 'O', 'R'
 ECHR ':'
 EQUB VE

 ETWO 'G', 'E'          \ Token 48:     "GREAT STARSEEKER"
 ECHR 'R'               \
 ETWO 'E', 'T'          \ Encoded as:   "<231>R<221> <222><238><218>EK<244>"
 ECHR ' '
 ETWO 'S', 'T'
 ETWO 'A', 'R'
 ETWO 'S', 'E'
 ECHR 'E'
 ECHR 'K'
 ETWO 'E', 'R'
 EQUB VE

 ECHR ' '               \ Token 49:     " LASER"
 ETWO 'L', 'A'          \
 ETWO 'S', 'E'          \ Encoded as:   "<249><218>R"
 ECHR 'R'
 EQUB VE

 ECHR ' '               \ Token 50:     " PULSE"
 ECHR 'P'               \
 ECHR 'U'               \ Encoded as:   "PUL<218>"
 ECHR 'L'
 ETWO 'S', 'E'
 EQUB VE

 ECHR ' '               \ Token 51:     " SYSTEM"
 ECHR 'S'               \
 ECHR 'Y'               \ Encoded as:   " SY<222>EM"
 ETWO 'S', 'T'
 ECHR 'E'
 ECHR 'M'
 EQUB VE

 ETWO 'E', 'R'          \ Token 52:     "ERGON"
 ECHR 'G'               \
 ETWO 'O', 'N'          \ Encoded as:   "<244>G<223>"
 EQUB VE

 ETOK 151               \ Token 53:     "DRIVE"
 EQUB VE                \
                        \ Encoded as:   "[151]"

 ETWO 'S', 'E'          \ Token 54:     "SEEK"
 ECHR 'E'               \
 ECHR 'K'               \ Encoded as:   "<218>EK"
 EQUB VE

 ECHR 'L'               \ Token 55:     "LIGHT"
 ECHR 'I'               \
 ECHR 'G'               \ Encoded as:   "LIGHT"
 ECHR 'H'
 ECHR 'T'
 EQUB VE

 ETWO 'I', 'N'          \ Token 56:     "INGRAM"
 ECHR 'G'               \
 ETWO 'R', 'A'          \ Encoded as:   "<240>G<248>M"
 ECHR 'M'
 EQUB VE

 ETWO 'L', 'A'          \ Token 57:     "LANCE & FERMAN"
 ECHR 'N'               \
 ETWO 'C', 'E'          \ Encoded as:   "<249>N<233> & F<244><239>N"
 ECHR ' '
 ECHR '&'
 ECHR ' '
 ECHR 'F'
 ETWO 'E', 'R'
 ETWO 'M', 'A'
 ECHR 'N'
 EQUB VE

 EJMP 19                \ Token 58:     "{single cap}KRUGER ""
 ECHR 'K'               \
 ECHR 'R'               \ Encoded as:   "{19}KRU<231>R "
 ECHR 'U'
 ETWO 'G', 'E'
 ECHR 'R'
 ECHR ' '
 EQUB VE

 ECHR 'H'               \ Token 59:     "HASSONI"
 ECHR 'A'               \
 ECHR 'S'               \ Encoded as:   "HASS<223>I"
 ECHR 'S'
 ETWO 'O', 'N'
 ECHR 'I'
 EQUB VE

 ECHR 'V'               \ Token 60:     "VOLTAIRE"
 ECHR 'O'               \
 ECHR 'L'               \ Encoded as:   "VOLTAI<242>"
 ECHR 'T'
 ECHR 'A'
 ECHR 'I'
 ETWO 'R', 'E'
 EQUB VE

 ECHR 'C'               \ Token 61:     "CARGO"
 ETWO 'A', 'R'          \
 ECHR 'G'               \ Encoded as:   "C<238>GO"
 ECHR 'O'
 EQUB VE

 EJMP 1                 \ Token 62:     "{all caps}TC{sentence case}"
 ECHR 'T'               \
 ECHR 'C'               \ Encoded as:   "{1}TC{2}"
 EJMP 2
 EQUB VE

 EJMP 1                 \ Token 63:     "{all caps}LY{sentence case}"
 ECHR 'L'               \
 ECHR 'Y'               \ Encoded as:   "{1}LY{2}"
 EJMP 2
 EQUB VE

 EJMP 1                 \ Token 64:     "{all caps}LM{sentence case}"
 ECHR 'L'               \
 ECHR 'M'               \ Encoded as:   "{1}LM{2}"
 EJMP 2
 EQUB VE

 ECHR 'C'               \ Token 65:     "CF"
 ECHR 'F'               \
 EQUB VE                \ Encoded as:   "CF"

 ETWO 'T', 'H'          \ Token 66:     "THRUST"
 ECHR 'R'               \
 ECHR 'U'               \ Encoded as:   "<226>RU<222>"
 ETWO 'S', 'T'
 EQUB VE

 ECHR ' '               \ Token 67:     " SHIP"
 ETOK 207               \
 EQUB VE                \ Encoded as:   " [207]"

 ETWO 'I', 'N'          \ Token 68:     "INVENTION"
 ECHR 'V'               \
 ETWO 'E', 'N'          \ Encoded as:   "<240>V<246><251><223>"
 ETWO 'T', 'I'
 ETWO 'O', 'N'
 EQUB VE

 ETWO 'O', 'U'          \ Token 69:     "OUTWORLD"
 ECHR 'T'               \
 ECHR 'W'               \ Encoded as:   "<217>TW<253>LD"
 ETWO 'O', 'R'
 ECHR 'L'
 ECHR 'D'
 EQUB VE

 ECHR 'Z'               \ Token 70:     "ZORGON PETTERSON)"
 ETWO 'O', 'R'          \
 ECHR 'G'               \ Encoded as:   "Z<253>G<223> P<221>T<244>S<223>)"
 ETWO 'O', 'N'
 ECHR ' '
 ECHR 'P'
 ETWO 'E', 'T'
 ECHR 'T'
 ETWO 'E', 'R'
 ECHR 'S'
 ETWO 'O', 'N'
 ECHR ')'
 EQUB VE

 ECHR 'D'               \ Token 71:     "DE{single cap}LACY"
 ECHR 'E'               \
 EJMP 19                \ Encoded as:   "DE{19}<249>CY"
 ETWO 'L', 'A'
 ECHR 'C'
 ECHR 'Y'
 EQUB VE

 EJMP 1                 \ Token 72:     "{all caps}4*C40KV{sentence case} AMES
 ECHR '4'               \                DRIVE"
 ECHR '*'               \ Encoded as:   "{1}4*C40KV{2} AM<237> [151]"
 ECHR 'C'
 ECHR '4'
 ECHR '0'
 ECHR 'K'
 ECHR 'V'
 EJMP 2
 ECHR ' '
 ECHR 'A'
 ECHR 'M'
 ETWO 'E', 'S'
 ECHR ' '
 ETOK 151
 EQUB VE

 ECHR 'V'               \ Token 73:     "V & K "
 ECHR ' '               \
 ECHR '&'               \ Encoded as:   "V & K "
 ECHR ' '
 ECHR 'K'
 ECHR ' '
 EQUB VE

 ECHR 'B'               \ Token 74:     "BLAST"
 ETWO 'L', 'A'          \
 ETWO 'S', 'T'          \ Encoded as:   "B<249><222>"
 EQUB VE

 ECHR ' '               \ Token 75:     " ({single cap}GASEC LABS, VETITICE)""
 ECHR '('               \
 EJMP 19                \ Encoded as:   "({19}GA<218>C L<216>S, <250><251><251>
 ECHR 'G'               \                <233>)"
 ECHR 'A'
 ETWO 'S', 'E'
 ECHR 'C'
 ECHR ' '
 ECHR 'L'
 ETWO 'A', 'B'
 ECHR 'S'
 ECHR ','
 ECHR ' '
 ETWO 'V', 'E'
 ETWO 'T', 'I'
 ETWO 'T', 'I'
 ETWO 'C', 'E'
 ECHR ')'
 EQUB VE

 ECHR 'F'               \ Token 76:     "FEDERATION"
 ETWO 'E', 'D'          \
 ECHR 'E'               \ Encoded as:   "F<252>E<248><251><223>"
 ETWO 'R', 'A'
 ETWO 'T', 'I'
 ETWO 'O', 'N'
 EQUB VE

 ECHR 'S'               \ Token 77:     "SPACE"
 ECHR 'P'               \
 ECHR 'A'               \ Encoded as:   "SPA<233>"
 ETWO 'C', 'E'
 EQUB VE

 EJMP 19                \ Token 78:     "{single cap}IONIC"
 ECHR 'I'               \
 ETWO 'O', 'N'          \ Encoded as:   "{19}I<223>IC"
 ECHR 'I'
 ECHR 'C'
 EQUB VE

 ECHR 'H'               \ Token 79:     "HUNT"
 ECHR 'U'               \
 ECHR 'N'               \ Encoded as:   "HUNT"
 ECHR 'T'
 EQUB VE

 ECHR 'P'               \ Token 80:     "PROSSET "
 ECHR 'R'               \
 ECHR 'O'               \ Encoded as:   "PROS<218>T "
 ECHR 'S'
 ETWO 'S', 'E'
 ECHR 'T'
 ECHR ' '
 EQUB VE

 ECHR ' '               \ Token 81:     " WORKSHOPS)"
 ECHR 'W'               \
 ETWO 'O', 'R'          \ Encoded as:   " W<253>KSHOPS)"
 ECHR 'K'
 ECHR 'S'
 ECHR 'H'
 ECHR 'O'
 ECHR 'P'
 ECHR 'S'
 ECHR ')'
 EQUB VE

 EJMP 1                 \ Token 82:     "{all caps}/1L{sentence case}"
 ECHR '/'               \
 ECHR '1'               \ Encoded as:   "{1}/1L{2}"
 ECHR 'L'
 EJMP 2
 EQUB VE

 EJMP 1                 \ Token 83:     "{all caps}/2L{sentence case}"
 ECHR '/'               \
 ECHR '2'               \ Encoded as:   "{1}/2L{2}"
 ECHR 'L'
 EJMP 2
 EQUB VE

 EJMP 1                 \ Token 84:     "{all caps}/4L{sentence case}"
 ECHR '/'               \
 ECHR '4'               \ Encoded as:   "{1}/4L{2}"
 ECHR 'L'
 EJMP 2
 EQUB VE

 ECHR ' '               \ Token 85:     " ({single cap}"
 ECHR '('               \
 EJMP 19                \ Encoded as:   " ({19}"
 EQUB VE

 EJMP 1                 \ Token 86:     "{all caps}IFS{sentence case} "
 ECHR 'I'               \
 ECHR 'F'               \ Encoded as:   "{1}IFS{2} "
 ECHR 'S'
 EJMP 2
 ECHR ' '
 EQUB VE

 EJMP 12                \ Token 87:     "{cr}
 ECHR 'F'               \                FLIGHT CONTROLS{crlf}
 ECHR 'L'               \                <{tab 6}ANTI-CLOCKWISE ROLL{cr}
 ECHR 'I'               \                >{tab 6}CLOCKWISE ROLL{cr}
 ECHR 'G'               \                S{tab 6}DIVE{cr}
 ECHR 'H'               \                X{tab 6}CLIMB{cr}
 ECHR 'T'               \                {all caps}SPC{sentence case}{tab 6}
 ECHR ' '               \                INCREASE SPEED{cr}
 ECHR 'C'               \                ?{tab 6}DECREASE SPEED{cr}
 ETWO 'O', 'N'          \                {all caps}TAB{sentence case}{tab 6}
 ECHR 'T'               \                HYPERSPACE ESCAPE{cr}
 ECHR 'R'               \                {all caps}ESC{sentence case}{tab 6}
 ECHR 'O'               \                ESCAPE CAPSULE{cr}
 ECHR 'L'               \                F{tab 6}TOGGLE COMPASS{cr}
 ECHR 'S'               \                V{tab 6}{standard tokens, sentence
 ETWO '-', '-'          \                case} DOCKING COMPUTERS{extended
 ECHR '<'               \                tokens}ON{cr}
 EJMP 8                 \                P{tab 6}{standard tokens, sentence
 ETWO 'A', 'N'          \                case} DOCKING COMPUTERS{extended
 ETWO 'T', 'I'          \                tokens} OFF{cr}
 ECHR '-'               \                J{tab 6}MICROJUMP{cr}
 ECHR 'C'               \                {lower case}F0{sentence case}{tab 6}
 ETWO 'L', 'O'          \                FRONT VIEW{cr}
 ECHR 'C'               \                {lower case}F1{sentence case}{tab 6}
 ECHR 'K'               \                REAR VIEW{cr}
 ECHR 'W'               \                {lower case}F2{sentence case}{tab 6}
 ECHR 'I'               \                LEFT VIEW{cr}
 ETWO 'S', 'E'          \                {lower case}F3{sentence case}{tab 6}
 ECHR ' '               \                RIGHT VIEW{cr}"
 ECHR 'R'               \
 ECHR 'O'               \ Encoded as:   "{12}FLIGHT C<223>TROLS<215><{8}<255>
 ECHR 'L'               \                <251>-C<224>CKWI<218> ROLL{12}>{8}C
 ECHR 'L'               \                <224>CKWI<218> ROLL{12}S{8}<241><250>
 EJMP 12                \                {12}X{8}CLIMB{12}{1}SPC{2}{8}<240>C
 ECHR '>'               \                <242>A<218> SPE<252>{12}?{8}DEC<242>A
 EJMP 8                 \                <218> SPE<252>{12}{1}T<216>{2}{8}HYP
 ECHR 'C'               \                <244>SPA<233> <237>CAPE{12}{1}<237>C{2}
 ETWO 'L', 'O'          \                {8}<237>CAPE CAPSU<229>{12}F{8}TOGG
 ECHR 'C'               \                <229> COMPASS{12}V{8}{4}[115]{5} <223>
 ECHR 'K'               \                {12}P{8}{4}[115]{5} OFF{12}J{8}MICROJUM
 ECHR 'W'               \                P{12}{13}F0{2}{8}FR<223>T VIEW{12}{13}
 ECHR 'I'               \                F1{2}{8}<242><238> VIEW{12}{13}F2{2}{8}
 ETWO 'S', 'E'          \                <229>FT VIEW{12}{13}F3{2}{8}RIGHT VIEW
 ECHR ' '               \                {12}"
 ECHR 'R'
 ECHR 'O'
 ECHR 'L'
 ECHR 'L'
 EJMP 12
 ECHR 'S'
 EJMP 8
 ETWO 'D', 'I'
 ETWO 'V', 'E'
 EJMP 12
 ECHR 'X'
 EJMP 8
 ECHR 'C'
 ECHR 'L'
 ECHR 'I'
 ECHR 'M'
 ECHR 'B'
 EJMP 12
 EJMP 1
 ECHR 'S'
 ECHR 'P'
 ECHR 'C'
 EJMP 2
 EJMP 8
 ETWO 'I', 'N'
 ECHR 'C'
 ETWO 'R', 'E'
 ECHR 'A'
 ETWO 'S', 'E'
 ECHR ' '
 ECHR 'S'
 ECHR 'P'
 ECHR 'E'
 ETWO 'E', 'D'
 EJMP 12
 ECHR '?'
 EJMP 8
 ECHR 'D'
 ECHR 'E'
 ECHR 'C'
 ETWO 'R', 'E'
 ECHR 'A'
 ETWO 'S', 'E'
 ECHR ' '
 ECHR 'S'
 ECHR 'P'
 ECHR 'E'
 ETWO 'E', 'D'
 EJMP 12
 EJMP 1
 ECHR 'T'
 ETWO 'A', 'B'
 EJMP 2
 EJMP 8
 ECHR 'H'
 ECHR 'Y'
 ECHR 'P'
 ETWO 'E', 'R'
 ECHR 'S'
 ECHR 'P'
 ECHR 'A'
 ETWO 'C', 'E'
 ECHR ' '
 ETWO 'E', 'S'
 ECHR 'C'
 ECHR 'A'
 ECHR 'P'
 ECHR 'E'
 EJMP 12
 EJMP 1
 ETWO 'E', 'S'
 ECHR 'C'
 EJMP 2
 EJMP 8
 ETWO 'E', 'S'
 ECHR 'C'
 ECHR 'A'
 ECHR 'P'
 ECHR 'E'
 ECHR ' '
 ECHR 'C'
 ECHR 'A'
 ECHR 'P'
 ECHR 'S'
 ECHR 'U'
 ETWO 'L', 'E'
 EJMP 12
 ECHR 'F'
 EJMP 8
 ECHR 'T'
 ECHR 'O'
 ECHR 'G'
 ECHR 'G'
 ETWO 'L', 'E'
 ECHR ' '
 ECHR 'C'
 ECHR 'O'
 ECHR 'M'
 ECHR 'P'
 ECHR 'A'
 ECHR 'S'
 ECHR 'S'
 EJMP 12
 ECHR 'V'
 EJMP 8
 EJMP 4
 TOKN 115
 EJMP 5
 ECHR ' '
 ETWO 'O', 'N'
 EJMP 12
 ECHR 'P'
 EJMP 8
 EJMP 4
 TOKN 115
 EJMP 5
 ECHR ' '
 ECHR 'O'
 ECHR 'F'
 ECHR 'F'
 EJMP 12
 ECHR 'J'
 EJMP 8
 ECHR 'M'
 ECHR 'I'
 ECHR 'C'
 ECHR 'R'
 ECHR 'O'
 ECHR 'J'
 ECHR 'U'
 ECHR 'M'
 ECHR 'P'
 EJMP 12
 EJMP 13
 ECHR 'F'
 ECHR '0'
 EJMP 2
 EJMP 8
 ECHR 'F'
 ECHR 'R'
 ETWO 'O', 'N'
 ECHR 'T'
 ECHR ' '
 ECHR 'V'
 ECHR 'I'
 ECHR 'E'
 ECHR 'W'
 EJMP 12
 EJMP 13
 ECHR 'F'
 ECHR '1'
 EJMP 2
 EJMP 8
 ETWO 'R', 'E'
 ETWO 'A', 'R'
 ECHR ' '
 ECHR 'V'
 ECHR 'I'
 ECHR 'E'
 ECHR 'W'
 EJMP 12
 EJMP 13
 ECHR 'F'
 ECHR '2'
 EJMP 2
 EJMP 8
 ETWO 'L', 'E'
 ECHR 'F'
 ECHR 'T'
 ECHR ' '
 ECHR 'V'
 ECHR 'I'
 ECHR 'E'
 ECHR 'W'
 EJMP 12
 EJMP 13
 ECHR 'F'
 ECHR '3'
 EJMP 2
 EJMP 8
 ECHR 'R'
 ECHR 'I'
 ECHR 'G'
 ECHR 'H'
 ECHR 'T'
 ECHR ' '
 ECHR 'V'
 ECHR 'I'
 ECHR 'E'
 ECHR 'W'
 EJMP 12
 EQUB VE

 EJMP 12                \ Token 88:     "{cr}
 ECHR 'C'               \                COMBAT CONTROLS{crlf}
 ECHR 'O'               \                A{tab 6}FIRE LASER{cr}
 ECHR 'M'               \                T{tab 6}TARGET {standard tokens,
 ECHR 'B'               \                sentence case} MISSILE{extended
 ETWO 'A', 'T'          \                tokens}{cr}
 ECHR ' '               \                M{tab 6}FIRE {standard tokens, sentence
 ECHR 'C'               \                case} MISSILE{extended tokens}{cr}
 ETWO 'O', 'N'          \                U{tab 6}UNARM {standard tokens,
 ECHR 'T'               \                sentence case} MISSILE{extended
 ECHR 'R'               \                tokens}{cr}
 ECHR 'O'               \                E{tab 6}TRIGGER E.C.M.{cr}
 ECHR 'L'               \                {cr}
 ECHR 'S'               \                I.F.F. COLOUR CODES{crlf}
 ETWO '-', '-'          \                WHITE{tab 16}OFFICIAL SHIP{cr}
 ECHR 'A'               \                BLUE{tab 16}LEGAL SHIP{cr}
 EJMP 8                 \                BLUE/{single cap}WHITE{tab 16}DEBRIS
 ECHR 'F'               \                {cr}
 ECHR 'I'               \                BLUE/{single cap}RED{tab 16}
 ETWO 'R', 'E'          \                NON-RESPONDENT{cr}
 ECHR ' '               \                WHITE/{single cap}RED{tab 16}{standard
 ETWO 'L', 'A'          \                tokens, sentence case} MISSILE{extended
 ETWO 'S', 'E'          \                tokens}{cr}"
 ECHR 'R'               \
 EJMP 12                \ Encoded as:   "{12}COMB<245> C<223>TROLS<215>A{8}FI
 ECHR 'T'               \                <242> <249><218>R{12}T{8}T<238>G<221>
 EJMP 8                 \                 {4}[106]{5}{12}M{8}FI<242> {4}[106]{5}
 ECHR 'T'               \                {12}U{8}UN<238>M {4}[106]{5}{12}E{8}TRI
 ETWO 'A', 'R'          \                G<231>R E.C.M.{12}{12}I.F.F. COL<217>R
 ECHR 'G'               \                 COD<237><215>WH<219>E{22}OFFICI<228>
 ETWO 'E', 'T'          \                 [207]{12}BLUE{22}<229>G<228> [207]{12}
 ECHR ' '               \                BLUE/{19}WH<219>E{22}DEBRIS{12}BLUE/
 EJMP 4                 \                {19}<242>D{22}N<223>-R<237>P<223>D<246>
 TOKN 106               \                T{12}WH<219>E/{19}<242>D{22}{4}[106]{5}
 EJMP 5                 \                {12}"
 EJMP 12
 ECHR 'M'
 EJMP 8
 ECHR 'F'
 ECHR 'I'
 ETWO 'R', 'E'
 ECHR ' '
 EJMP 4
 TOKN 106
 EJMP 5
 EJMP 12
 ECHR 'U'
 EJMP 8
 ECHR 'U'
 ECHR 'N'
 ETWO 'A', 'R'
 ECHR 'M'
 ECHR ' '
 EJMP 4
 TOKN 106
 EJMP 5
 EJMP 12
 ECHR 'E'
 EJMP 8
 ECHR 'T'
 ECHR 'R'
 ECHR 'I'
 ECHR 'G'
 ETWO 'G', 'E'
 ECHR 'R'
 ECHR ' '
 ECHR 'E'
 ECHR '.'
 ECHR 'C'
 ECHR '.'
 ECHR 'M'
 ECHR '.'
 EJMP 12
 EJMP 12
 ECHR 'I'
 ECHR '.'
 ECHR 'F'
 ECHR '.'
 ECHR 'F'
 ECHR '.'
 ECHR ' '
 ECHR 'C'
 ECHR 'O'
 ECHR 'L'
 ETWO 'O', 'U'
 ECHR 'R'
 ECHR ' '
 ECHR 'C'
 ECHR 'O'
 ECHR 'D'
 ETWO 'E', 'S'
 ETWO '-', '-'
 ECHR 'W'
 ECHR 'H'
 ETWO 'I', 'T'
 ECHR 'E'
 EJMP 22
 ECHR 'O'
 ECHR 'F'
 ECHR 'F'
 ECHR 'I'
 ECHR 'C'
 ECHR 'I'
 ETWO 'A', 'L'
 ECHR ' '
 ETOK 207
 EJMP 12
 ECHR 'B'
 ECHR 'L'
 ECHR 'U'
 ECHR 'E'
 EJMP 22
 ETWO 'L', 'E'
 ECHR 'G'
 ETWO 'A', 'L'
 ECHR ' '
 ETOK 207
 EJMP 12
 ECHR 'B'
 ECHR 'L'
 ECHR 'U'
 ECHR 'E'
 ECHR '/'
 EJMP 19
 ECHR 'W'
 ECHR 'H'
 ETWO 'I', 'T'
 ECHR 'E'
 EJMP 22
 ECHR 'D'
 ECHR 'E'
 ECHR 'B'
 ECHR 'R'
 ECHR 'I'
 ECHR 'S'
 EJMP 12
 ECHR 'B'
 ECHR 'L'
 ECHR 'U'
 ECHR 'E'
 ECHR '/'
 EJMP 19
 ETWO 'R', 'E'
 ECHR 'D'
 EJMP 22
 ECHR 'N'
 ETWO 'O', 'N'
 ECHR '-'
 ECHR 'R'
 ETWO 'E', 'S'
 ECHR 'P'
 ETWO 'O', 'N'
 ECHR 'D'
 ETWO 'E', 'N'
 ECHR 'T'
 EJMP 12
 ECHR 'W'
 ECHR 'H'
 ETWO 'I', 'T'
 ECHR 'E'
 ECHR '/'
 EJMP 19
 ETWO 'R', 'E'
 ECHR 'D'
 EJMP 22
 EJMP 4
 TOKN 106
 EJMP 5
 EJMP 12
 EQUB VE

 EJMP 12                \ Token 89:     "{cr}
 ECHR 'N'               \                NAVIGATION CONTROLS{crlf}
 ECHR 'A'               \                H{tab 6}HYPERSPACE JUMP{cr}
 ECHR 'V'               \                C-{single cap}H{tab 6}{standard tokens,
 ECHR 'I'               \                sentence case} GALACTIC HYPERSPACE
 ECHR 'G'               \                {extended tokens}{cr}
 ETWO 'A', 'T'          \                CURSOR KEYS{cr}
 ECHR 'I'               \                {tab 6}HYPERSPACE CURSOR CONTROL{cr}
 ETWO 'O', 'N'          \                D{tab 6}DISTANCE TO SYSTEM{cr}
 ECHR ' '               \                O{tab 6}HOME CURSOR{cr}
 ECHR 'C'               \                F{tab 6}FIND SYSTEM ({single cap}DOCKED
 ETWO 'O', 'N'          \                ){cr}
 ECHR 'T'               \                W{tab 6}FIND DESTINATION SYSTEM{cr}
 ECHR 'R'               \                {lower case}F4{sentence case}{tab 6}
 ECHR 'O'               \                GALACTIC MAP{cr}
 ECHR 'L'               \                {lower case}F5{sentence case}{tab 6}
 ECHR 'S'               \                SHORT RANGE MAP{cr}
 ETWO '-', '-'          \                {lower case}F6{sentence case}{tab 6}
 ECHR 'H'               \                DATA ON PLANET{cr}"
 EJMP 8                 \
 ECHR 'H'               \ Encoded as:   "{12}NAVIG<245>I<223> C<223>TROLS<215>H
 ECHR 'Y'               \                {8}HYP<244>SPA<233> JUMP{12}C-{19}H{8}
 ECHR 'P'               \                {4}[116]{5}{12}CUR<235>R KEYS{12}{8}HYP
 ETWO 'E', 'R'          \                <244>SPA<233> CUR<235>R C<223>TROL{12}D
 ECHR 'S'               \                {8}<241><222><255><233>[201]SY<222>EM
 ECHR 'P'               \                {12}O{8}HOME CUR<235>R{12}F{8}F<240>D S
 ECHR 'A'               \                Y<222>EM ({19}[205]){12}W{8}F<240>D DE
 ETWO 'C', 'E'          \                <222><240><245>I<223> SY<222>EM{12}{13}
 ECHR ' '               \                F4{2}{8}G<228>AC<251>C <239>P{12}{13}F5
 ECHR 'J'               \                {2}{8}SH<253>T <248>N<231> <239>P{12}
 ECHR 'U'               \                {13}F6{2}{8}D<245>A <223> [145]{12}"
 ECHR 'M'
 ECHR 'P'
 EJMP 12
 ECHR 'C'
 ECHR '-'
 EJMP 19
 ECHR 'H'
 EJMP 8
 EJMP 4
 TOKN 116
 EJMP 5
 EJMP 12
 ECHR 'C'
 ECHR 'U'
 ECHR 'R'
 ETWO 'S', 'O'
 ECHR 'R'
 ECHR ' '
 ECHR 'K'
 ECHR 'E'
 ECHR 'Y'
 ECHR 'S'
 EJMP 12
 EJMP 8
 ECHR 'H'
 ECHR 'Y'
 ECHR 'P'
 ETWO 'E', 'R'
 ECHR 'S'
 ECHR 'P'
 ECHR 'A'
 ETWO 'C', 'E'
 ECHR ' '
 ECHR 'C'
 ECHR 'U'
 ECHR 'R'
 ETWO 'S', 'O'
 ECHR 'R'
 ECHR ' '
 ECHR 'C'
 ETWO 'O', 'N'
 ECHR 'T'
 ECHR 'R'
 ECHR 'O'
 ECHR 'L'
 EJMP 12
 ECHR 'D'
 EJMP 8
 ETWO 'D', 'I'
 ETWO 'S', 'T'
 ETWO 'A', 'N'
 ETWO 'C', 'E'
 ETOK 201
 ECHR 'S'
 ECHR 'Y'
 ETWO 'S', 'T'
 ECHR 'E'
 ECHR 'M'
 EJMP 12
 ECHR 'O'
 EJMP 8
 ECHR 'H'
 ECHR 'O'
 ECHR 'M'
 ECHR 'E'
 ECHR ' '
 ECHR 'C'
 ECHR 'U'
 ECHR 'R'
 ETWO 'S', 'O'
 ECHR 'R'
 EJMP 12
 ECHR 'F'
 EJMP 8
 ECHR 'F'
 ETWO 'I', 'N'
 ECHR 'D'
 ECHR ' '
 ECHR 'S'
 ECHR 'Y'
 ETWO 'S', 'T'
 ECHR 'E'
 ECHR 'M'
 ECHR ' '
 ECHR '('
 EJMP 19
 ETOK 205
 ECHR ')'
 EJMP 12
 ECHR 'W'
 EJMP 8
 ECHR 'F'
 ETWO 'I', 'N'
 ECHR 'D'
 ECHR ' '
 ECHR 'D'
 ECHR 'E'
 ETWO 'S', 'T'
 ETWO 'I', 'N'
 ETWO 'A', 'T'
 ECHR 'I'
 ETWO 'O', 'N'
 ECHR ' '
 ECHR 'S'
 ECHR 'Y'
 ETWO 'S', 'T'
 ECHR 'E'
 ECHR 'M'
 EJMP 12
 EJMP 13
 ECHR 'F'
 ECHR '4'
 EJMP 2
 EJMP 8
 ECHR 'G'
 ETWO 'A', 'L'
 ECHR 'A'
 ECHR 'C'
 ETWO 'T', 'I'
 ECHR 'C'
 ECHR ' '
 ETWO 'M', 'A'
 ECHR 'P'
 EJMP 12
 EJMP 13
 ECHR 'F'
 ECHR '5'
 EJMP 2
 EJMP 8
 ECHR 'S'
 ECHR 'H'
 ETWO 'O', 'R'
 ECHR 'T'
 ECHR ' '
 ETWO 'R', 'A'
 ECHR 'N'
 ETWO 'G', 'E'
 ECHR ' '
 ETWO 'M', 'A'
 ECHR 'P'
 EJMP 12
 EJMP 13
 ECHR 'F'
 ECHR '6'
 EJMP 2
 EJMP 8
 ECHR 'D'
 ETWO 'A', 'T'
 ECHR 'A'
 ECHR ' '
 ETWO 'O', 'N'
 ECHR ' '
 ETOK 145
 EJMP 12
 EQUB VE

 EJMP 12                \ Token 90:     "{cr}
 ECHR 'T'               \                TRADING CONTROLS{crlf}
 ETWO 'R', 'A'          \                {lower case}F0{sentence case}{tab 6}
 ECHR 'D'               \                LAUNCH FROM STATION{cr}
 ETOK 195               \                C-F0{sentence case}{tab 6}REMAIN DOCKED
 ECHR 'C'               \                {cr}
 ETWO 'O', 'N'          \                {lower case}F1{sentence case}{tab 6}BUY
 ECHR 'T'               \                CARGO{cr}
 ECHR 'R'               \                C-F1{tab 6}BUY SPECIAL CARGO{cr}
 ECHR 'O'               \                {lower case}F2{sentence case}{tab 6}
 ECHR 'L'               \                SELL CARGO{cr}
 ECHR 'S'               \                C-F2{tab 6}SELL EQUIPMENT{cr}
 ETWO '-', '-'          \                {lower case}F3{sentence case}{tab 6}
 EJMP 13                \                EQUIP SHIP{cr}
 ECHR 'F'               \                C-F3{tab 6}BUY SHIP{cr}
 ECHR '0'               \                C-F6{tab 6}ENCYCLOPEDIA{cr}
 EJMP 2                 \                {lower case}F7{sentence case}{tab 6}
 EJMP 8                 \                MARKET PRICES{cr}
 ETWO 'L', 'A'          \                {lower case}F8{sentence case}{tab 6}
 ECHR 'U'               \                STATUS PAGE{cr}
 ECHR 'N'               \                {lower case}F9{sentence case}{tab 6}
 ECHR 'C'               \                INVENTORY{cr}"
 ECHR 'H'               \
 ECHR ' '               \ Encoded as:   "{12}T<248>D[195]C<223>TROLS<215>{13}F0
 ECHR 'F'               \                {2}{8}<249>UNCH FROM <222><245>I<223>
 ECHR 'R'               \                {12}C-F0{2}{8}<242><239><240> [205]{12}
 ECHR 'O'               \                {13}F1{2}{8}BUY C<238>GO{12}C-F1{8}BUY
 ECHR 'M'               \                 SPECI<228> C<238>GO{12}{13}F2{2}{8}
 ECHR ' '               \                <218>LL C<238>GO{12}C-F2{8}<218>LL EQUI
 ETWO 'S', 'T'          \                PMENT{12}{13}F3{2}{8}EQUIP [207]{12}C-F
 ETWO 'A', 'T'          \                3{8}BUY [207]{12}C-F6{8}<246>CYC<224>P
 ECHR 'I'               \                <252>IA{12}{13}F7{2}{8}M<238>K<221> PRI
 ETWO 'O', 'N'          \                <233>S{12}{13}F8{2}{8}<222><245><236> P
 EJMP 12                \                A<231>{12}{13}F9{2}{8}<240>V<246>T<253>
 ECHR 'C'               \                Y{12}"
 ECHR '-'
 ECHR 'F'
 ECHR '0'
 EJMP 2
 EJMP 8
 ETWO 'R', 'E'
 ETWO 'M', 'A'
 ETWO 'I', 'N'
 ECHR ' '
 ETOK 205
 EJMP 12
 EJMP 13
 ECHR 'F'
 ECHR '1'
 EJMP 2
 EJMP 8
 ECHR 'B'
 ECHR 'U'
 ECHR 'Y'
 ECHR ' '
 ECHR 'C'
 ETWO 'A', 'R'
 ECHR 'G'
 ECHR 'O'
 EJMP 12
 ECHR 'C'
 ECHR '-'
 ECHR 'F'
 ECHR '1'
 EJMP 8
 ECHR 'B'
 ECHR 'U'
 ECHR 'Y'
 ECHR ' '
 ECHR 'S'
 ECHR 'P'
 ECHR 'E'
 ECHR 'C'
 ECHR 'I'
 ETWO 'A', 'L'
 ECHR ' '
 ECHR 'C'
 ETWO 'A', 'R'
 ECHR 'G'
 ECHR 'O'
 EJMP 12
 EJMP 13
 ECHR 'F'
 ECHR '2'
 EJMP 2
 EJMP 8
 ETWO 'S', 'E'
 ECHR 'L'
 ECHR 'L'
 ECHR ' '
 ECHR 'C'
 ETWO 'A', 'R'
 ECHR 'G'
 ECHR 'O'
 EJMP 12
 ECHR 'C'
 ECHR '-'
 ECHR 'F'
 ECHR '2'
 EJMP 8
 ETWO 'S', 'E'
 ECHR 'L'
 ECHR 'L'
 ECHR ' '
 ECHR 'E'
 ECHR 'Q'
 ECHR 'U'
 ECHR 'I'
 ECHR 'P'
 ECHR 'M'
 ECHR 'E'
 ECHR 'N'
 ECHR 'T'
 EJMP 12
 EJMP 13
 ECHR 'F'
 ECHR '3'
 EJMP 2
 EJMP 8
 ECHR 'E'
 ECHR 'Q'
 ECHR 'U'
 ECHR 'I'
 ECHR 'P'
 ECHR ' '
 ETOK 207
 EJMP 12
 ECHR 'C'
 ECHR '-'
 ECHR 'F'
 ECHR '3'
 EJMP 8
 ECHR 'B'
 ECHR 'U'
 ECHR 'Y'
 ECHR ' '
 ETOK 207
 EJMP 12
 ECHR 'C'
 ECHR '-'
 ECHR 'F'
 ECHR '6'
 EJMP 8
 ETWO 'E', 'N'
 ECHR 'C'
 ECHR 'Y'
 ECHR 'C'
 ETWO 'L', 'O'
 ECHR 'P'
 ETWO 'E', 'D'
 ECHR 'I'
 ECHR 'A'
 EJMP 12
 EJMP 13
 ECHR 'F'
 ECHR '7'
 EJMP 2
 EJMP 8
 ECHR 'M'
 ETWO 'A', 'R'
 ECHR 'K'
 ETWO 'E', 'T'
 ECHR ' '
 ECHR 'P'
 ECHR 'R'
 ECHR 'I'
 ETWO 'C', 'E'
 ECHR 'S'
 EJMP 12
 EJMP 13
 ECHR 'F'
 ECHR '8'
 EJMP 2
 EJMP 8
 ETWO 'S', 'T'
 ETWO 'A', 'T'
 ETWO 'U', 'S'
 ECHR ' '
 ECHR 'P'
 ECHR 'A'
 ETWO 'G', 'E'
 EJMP 12
 EJMP 13
 ECHR 'F'
 ECHR '9'
 EJMP 2
 EJMP 8
 ETWO 'I', 'N'
 ECHR 'V'
 ETWO 'E', 'N'
 ECHR 'T'
 ETWO 'O', 'R'
 ECHR 'Y'
 EJMP 12
 EQUB VE

 ECHR 'F'               \ Token 91:     "FLIGHT"
 ECHR 'L'               \
 ECHR 'I'               \ Encoded as:   "FLIGHT"
 ECHR 'G'
 ECHR 'H'
 ECHR 'T'
 EQUB VE

 ECHR 'C'               \ Token 92:     "COMBAT"
 ECHR 'O'               \
 ECHR 'M'               \ Encoded as:   "COMB<245>"
 ECHR 'B'
 ETWO 'A', 'T'
 EQUB VE

 ECHR 'N'               \ Token 93:     "NAVIGATION"
 ECHR 'A'               \
 ECHR 'V'               \ Encoded as:   "NAVIG<245>I<223>"
 ECHR 'I'
 ECHR 'G'
 ETWO 'A', 'T'
 ECHR 'I'
 ETWO 'O', 'N'
 EQUB VE

 ECHR 'T'               \ Token 94:     "TRADING"
 ETWO 'R', 'A'          \
 ECHR 'D'               \ Encoded as:   "T<248>D<240>G"
 ETWO 'I', 'N'
 ECHR 'G'
 EQUB VE

 EJMP 4                 \ Token 95:     "{standard tokens, sentence case}MISSILE
 TOKN 106               \                {extended tokens}"
 EJMP 5                 \
 EQUB VE                \ Encoded as:   "{4}[106]{5}"

 EJMP 4                 \ Token 96:     "{standard tokens, sentence case}I.F.F.
 TOKN 107               \                SYSTEM{extended tokens}" AJD
 EJMP 5                 \
 EQUB VE                \ Encoded as:   "{4}[107]{5}"

 EJMP 4                 \ Token 97:     "{standard tokens, sentence case}
 TOKN 108               \                E.C.M.SYSTEM{extended tokens}"
 EJMP 5                 \
 EQUB VE                \ Encoded as:   "{4}[108]{5}"

 EJMP 4                 \ Token 98:     "{standard tokens, sentence case}PULSE
 TOKN 103               \                LASER{extended tokens}"
 EJMP 5                 \
 EQUB VE                \ Encoded as:   "{4}[103]{5}"

 EJMP 4                 \ Token 99:     "{standard tokens, sentence case}BEAM
 TOKN 104               \                LASER{extended tokens}"
 EJMP 5                 \
 EQUB VE                \ Encoded as:   "{4}[104]{5}"

 EJMP 4                 \ Token 100:    "{standard tokens, sentence case}FUEL
 TOKN 111               \                SCOOPS{extended tokens}"
 EJMP 5                 \
 EQUB VE                \ Encoded as:   "{4}[111]{5}"

 EJMP 4                 \ Token 101:    "{standard tokens, sentence case}ESCAPE
 TOKN 112               \                POD{extended tokens}"
 EJMP 5                 \
 EQUB VE                \ Encoded as:   "{4}[112]{5}"

 EJMP 4                 \ Token 102:    "{standard tokens, sentence case}
 TOKN 113               \                HYPERSPACE UNIT{extended tokens}" AJD
 EJMP 5                 \
 EQUB VE                \ Encoded as:   "{4}[113]{5}"

 EJMP 4                 \ Token 103:    "{standard tokens, sentence case}ENERGY
 TOKN 114               \                UNIT{extended tokens}"
 EJMP 5                 \
 EQUB VE                \ Encoded as:   "{4}[114]{5}"

 EJMP 4                 \ Token 104:    "{standard tokens, sentence case}DOCKING
 TOKN 115               \                COMPUTERS{extended tokens}"
 EJMP 5                 \
 EQUB VE                \ Encoded as:   "{4}[115]{5}"

 EJMP 4                 \ Token 105:    "{standard tokens, sentence case}
 TOKN 116               \                GALACTIC HYPERSPACE {extended tokens}"
 EJMP 5                 \
 EQUB VE                \ Encoded as:   "{4}[116]{5}"

 EJMP 4                 \ Token 106:    "{standard tokens, sentence case}
 TOKN 117               \                MILITARY LASER{extended tokens}"
 EJMP 5                 \
 EQUB VE                \ Encoded as:   "{4}[117]{5}"

 EJMP 4                 \ Token 107:    "{standard tokens, sentence case}
 TOKN 118               \                MINING LASER{extended tokens}"
 EJMP 5                 \
 EQUB VE                \ Encoded as:   "{4}[118]{5}"

 EJMP 14                \ Token 108:    "{justify}{single cap}SELF HOMING
 EJMP 19                \                MISSILES MAY BE BOUGHT AT ANY SYSTEM.
 ETWO 'S', 'E'          \                {crlf}
 ECHR 'L'               \                {single cap}BEFORE A MISSILE CAN BE
 ECHR 'F'               \                FIRED IT MUST BE LOCKED ONTO A TARGET.
 ECHR ' '               \                {crlf}
 ECHR 'H'               \                {single cap}WHEN FIRED, IT WILL HOME IN
 ECHR 'O'               \                TO THE TARGET UNLESS THE TARGET CAN
 ECHR 'M'               \                OUTMANOEUVRE THE MISSILE, SHOOT IT, OR
 ETOK 195               \                USE ELECTRONIC COUNTER MEASURES ON IT.
 ECHR 'M'               \                {cr}
 ECHR 'I'               \                {left align}"
 ECHR 'S'               \
 ECHR 'S'               \ Encoded as:   "{14}{19}<218>LF HOM[195]MISS<220><237>
 ETWO 'I', 'L'          \                 <239>Y <247> B<217>GHT <245> <255>Y SY
 ETWO 'E', 'S'          \                <222>EM.<215>{19}<247>FO<242>[208]MISS
 ECHR ' '               \                <220>E C<255> <247> FIR[196]<219> MU
 ETWO 'M', 'A'          \                <222> <247> <224>CK[196]<223>TO A T
 ECHR 'Y'               \                <238>G<221>.<215>{19}WH<246> FI<242>D,
 ECHR ' '               \                 <219> W<220>L HOME <240>[201][147]T
 ETWO 'B', 'E'          \                <238>G<221> UN<229>SS [147]T<238>G<221>
 ECHR ' '               \                 C<255> <217>T<239><227>EUV<242> [147]M
 ECHR 'B'               \                ISS<220>E, SHOOT <219>, <253> U<218> E
 ETWO 'O', 'U'          \                <229>CTR<223>IC C<217>NT<244> MEASUR
 ECHR 'G'               \                <237> <223> <219>[177]"
 ECHR 'H'
 ECHR 'T'
 ECHR ' '
 ETWO 'A', 'T'
 ECHR ' '
 ETWO 'A', 'N'
 ECHR 'Y'
 ECHR ' '
 ECHR 'S'
 ECHR 'Y'
 ETWO 'S', 'T'
 ECHR 'E'
 ECHR 'M'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ETWO 'B', 'E'
 ECHR 'F'
 ECHR 'O'
 ETWO 'R', 'E'
 ETOK 208
 ECHR 'M'
 ECHR 'I'
 ECHR 'S'
 ECHR 'S'
 ETWO 'I', 'L'
 ECHR 'E'
 ECHR ' '
 ECHR 'C'
 ETWO 'A', 'N'
 ECHR ' '
 ETWO 'B', 'E'
 ECHR ' '
 ECHR 'F'
 ECHR 'I'
 ECHR 'R'
 ETOK 196
 ETWO 'I', 'T'
 ECHR ' '
 ECHR 'M'
 ECHR 'U'
 ETWO 'S', 'T'
 ECHR ' '
 ETWO 'B', 'E'
 ECHR ' '
 ETWO 'L', 'O'
 ECHR 'C'
 ECHR 'K'
 ETOK 196
 ETWO 'O', 'N'
 ECHR 'T'
 ECHR 'O'
 ECHR ' '
 ECHR 'A'
 ECHR ' '
 ECHR 'T'
 ETWO 'A', 'R'
 ECHR 'G'
 ETWO 'E', 'T'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ECHR 'W'
 ECHR 'H'
 ETWO 'E', 'N'
 ECHR ' '
 ECHR 'F'
 ECHR 'I'
 ETWO 'R', 'E'
 ECHR 'D'
 ECHR ','
 ECHR ' '
 ETWO 'I', 'T'
 ECHR ' '
 ECHR 'W'
 ETWO 'I', 'L'
 ECHR 'L'
 ECHR ' '
 ECHR 'H'
 ECHR 'O'
 ECHR 'M'
 ECHR 'E'
 ECHR ' '
 ETWO 'I', 'N'
 ETOK 201
 ETOK 147
 ECHR 'T'
 ETWO 'A', 'R'
 ECHR 'G'
 ETWO 'E', 'T'
 ECHR ' '
 ECHR 'U'
 ECHR 'N'
 ETWO 'L', 'E'
 ECHR 'S'
 ECHR 'S'
 ECHR ' '
 ETOK 147
 ECHR 'T'
 ETWO 'A', 'R'
 ECHR 'G'
 ETWO 'E', 'T'
 ECHR ' '
 ECHR 'C'
 ETWO 'A', 'N'
 ECHR ' '
 ETWO 'O', 'U'
 ECHR 'T'
 ETWO 'M', 'A'
 ETWO 'N', 'O'
 ECHR 'E'
 ECHR 'U'
 ECHR 'V'
 ETWO 'R', 'E'
 ECHR ' '
 ETOK 147
 ECHR 'M'
 ECHR 'I'
 ECHR 'S'
 ECHR 'S'
 ETWO 'I', 'L'
 ECHR 'E'
 ECHR ','
 ECHR ' '
 ECHR 'S'
 ECHR 'H'
 ECHR 'O'
 ECHR 'O'
 ECHR 'T'
 ECHR ' '
 ETWO 'I', 'T'
 ECHR ','
 ECHR ' '
 ETWO 'O', 'R'
 ECHR ' '
 ECHR 'U'
 ETWO 'S', 'E'
 ECHR ' '
 ECHR 'E'
 ETWO 'L', 'E'
 ECHR 'C'
 ECHR 'T'
 ECHR 'R'
 ETWO 'O', 'N'
 ECHR 'I'
 ECHR 'C'
 ECHR ' '
 ECHR 'C'
 ETWO 'O', 'U'
 ECHR 'N'
 ECHR 'T'
 ETWO 'E', 'R'
 ECHR ' '
 ECHR 'M'
 ECHR 'E'
 ECHR 'A'
 ECHR 'S'
 ECHR 'U'
 ECHR 'R'
 ETWO 'E', 'S'
 ECHR ' '
 ETWO 'O', 'N'
 ECHR ' '
 ETWO 'I', 'T'
 ETOK 177
 EQUB VE

 EJMP 14                \ Token 109:    "{justify}{single cap}AN IDENTIFICATION
 EJMP 19                \                FRIEND OR FOE SYSTEM CAN BE OBTAINED AT
 ETWO 'A', 'N'          \                TECH LEVEL 2 OR ABOVE.{crlf}
 ECHR ' '               \                {single cap}AN {all caps}I.F.F.{lower
 ECHR 'I'               \                case} SYSTEM WILL DISPLAY DIFFERENT
 ECHR 'D'               \                TYPES OF OBJECT IN DIFFERENT COLOURS ON
 ETWO 'E', 'N'          \                THE RADAR DISPLAY.{crlf}
 ETWO 'T', 'I'          \                {single cap}SEE {single cap}CONTROLS
 ECHR 'F'               \                ({single cap}COMBAT).{cr}
 ECHR 'I'               \                {left align}"
 ECHR 'C'               \
 ETWO 'A', 'T'          \ Encoded as:   "{14}{19}<255> ID<246><251>FIC<245>I
 ECHR 'I'               \                <223> FRI<246>D <253> FOE SY<222>EM C
 ETWO 'O', 'N'          \                <255> <247> OBTA<240>[196]<245> TECH
 ECHR ' '               \                 <229><250>L 2 <253> <216>O<250>.<215>
 ECHR 'F'               \                {19}<255> {1}I.F.F.{13} SY<222>EM W
 ECHR 'R'               \                <220>L <241>SP<249>Y <241>FFE<242>NT TY
 ECHR 'I'               \                P<237> OF OBJECT <240> <241>FFE<242>NT
 ETWO 'E', 'N'          \                 COL<217>RS <223> [147]<248>D<238>
 ECHR 'D'               \                 <241>SP<249>Y.<215>{19}<218>E {19}C
 ECHR ' '               \                <223>TROLS ({19}COMB<245>)[177]"
 ETWO 'O', 'R'
 ECHR ' '
 ECHR 'F'
 ECHR 'O'
 ECHR 'E'
 ECHR ' '
 ECHR 'S'
 ECHR 'Y'
 ETWO 'S', 'T'
 ECHR 'E'
 ECHR 'M'
 ECHR ' '
 ECHR 'C'
 ETWO 'A', 'N'
 ECHR ' '
 ETWO 'B', 'E'
 ECHR ' '
 ECHR 'O'
 ECHR 'B'
 ECHR 'T'
 ECHR 'A'
 ETWO 'I', 'N'
 ETOK 196
 ETWO 'A', 'T'
 ECHR ' '
 ECHR 'T'
 ECHR 'E'
 ECHR 'C'
 ECHR 'H'
 ECHR ' '
 ETWO 'L', 'E'
 ETWO 'V', 'E'
 ECHR 'L'
 ECHR ' '
 ECHR '2'
 ECHR ' '
 ETWO 'O', 'R'
 ECHR ' '
 ETWO 'A', 'B'
 ECHR 'O'
 ETWO 'V', 'E'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ETWO 'A', 'N'
 ECHR ' '
 EJMP 1
 ECHR 'I'
 ECHR '.'
 ECHR 'F'
 ECHR '.'
 ECHR 'F'
 ECHR '.'
 EJMP 13
 ECHR ' '
 ECHR 'S'
 ECHR 'Y'
 ETWO 'S', 'T'
 ECHR 'E'
 ECHR 'M'
 ECHR ' '
 ECHR 'W'
 ETWO 'I', 'L'
 ECHR 'L'
 ECHR ' '
 ETWO 'D', 'I'
 ECHR 'S'
 ECHR 'P'
 ETWO 'L', 'A'
 ECHR 'Y'
 ECHR ' '
 ETWO 'D', 'I'
 ECHR 'F'
 ECHR 'F'
 ECHR 'E'
 ETWO 'R', 'E'
 ECHR 'N'
 ECHR 'T'
 ECHR ' '
 ECHR 'T'
 ECHR 'Y'
 ECHR 'P'
 ETWO 'E', 'S'
 ECHR ' '
 ECHR 'O'
 ECHR 'F'
 ECHR ' '
 ECHR 'O'
 ECHR 'B'
 ECHR 'J'
 ECHR 'E'
 ECHR 'C'
 ECHR 'T'
 ECHR ' '
 ETWO 'I', 'N'
 ECHR ' '
 ETWO 'D', 'I'
 ECHR 'F'
 ECHR 'F'
 ECHR 'E'
 ETWO 'R', 'E'
 ECHR 'N'
 ECHR 'T'
 ECHR ' '
 ECHR 'C'
 ECHR 'O'
 ECHR 'L'
 ETWO 'O', 'U'
 ECHR 'R'
 ECHR 'S'
 ECHR ' '
 ETWO 'O', 'N'
 ECHR ' '
 ETOK 147
 ETWO 'R', 'A'
 ECHR 'D'
 ETWO 'A', 'R'
 ECHR ' '
 ETWO 'D', 'I'
 ECHR 'S'
 ECHR 'P'
 ETWO 'L', 'A'
 ECHR 'Y'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ETWO 'S', 'E'
 ECHR 'E'
 ECHR ' '
 EJMP 19
 ECHR 'C'
 ETWO 'O', 'N'
 ECHR 'T'
 ECHR 'R'
 ECHR 'O'
 ECHR 'L'
 ECHR 'S'
 ECHR ' '
 ECHR '('
 EJMP 19
 ECHR 'C'
 ECHR 'O'
 ECHR 'M'
 ECHR 'B'
 ETWO 'A', 'T'
 ECHR ')'
 ETOK 177
 EQUB VE

 EJMP 14                \ Token 110:    "{justify}{single cap}AN ELECTRONIC
 EJMP 19                \                COUNTER MEASURES SYSTEM MAY BE BOUGHT
 ETWO 'A', 'N'          \                AT ANY SYSTEM OF TECH LEVEL 3 OR
 ECHR ' '               \                HIGHER.{crlf}
 ECHR 'E'               \                {single cap}WHEN ACTIVATED, THE {all
 ETWO 'L', 'E'          \                caps}E.C.M.{lower case} SYSTEM WILL
 ECHR 'C'               \                DISRUPT THE GUIDANCE SYSTEMS OF ALL
 ECHR 'T'               \                MISSILES IN THE VICINITY, MAKING THEM
 ECHR 'R'               \                SELF DESTRUCT.{cr}
 ETWO 'O', 'N'          \                {left align}"
 ECHR 'I'               \
 ECHR 'C'               \ Encoded as:   "{14}{19}<255> E<229>CTR<223>IC C<217>NT
 ECHR ' '               \                <244> MEASUR<237> SY<222>EM <239>Y
 ECHR 'C'               \                 <247> B<217>GHT <245> <255>Y SY<222>EM
 ETWO 'O', 'U'          \                 OF TECH <229><250>L 3 <253> HIGH<244>.
 ECHR 'N'               \                <215>{19}WH<246> AC<251>V<245><252>,
 ECHR 'T'               \                 [147]{1}E.C.M.{13} SY<222>EM W<220>L
 ETWO 'E', 'R'          \                 <241>SRUPT [147]GUID<255><233> SY<222>
 ECHR ' '               \                EMS OF <228>L MISS<220><237> <240>
 ECHR 'M'               \                 [147]VIC<240><219>Y, <239>K[195]<226>E
 ECHR 'E'               \                M <218>LF DE<222>RUCT[177]"
 ECHR 'A'
 ECHR 'S'
 ECHR 'U'
 ECHR 'R'
 ETWO 'E', 'S'
 ECHR ' '
 ECHR 'S'
 ECHR 'Y'
 ETWO 'S', 'T'
 ECHR 'E'
 ECHR 'M'
 ECHR ' '
 ETWO 'M', 'A'
 ECHR 'Y'
 ECHR ' '
 ETWO 'B', 'E'
 ECHR ' '
 ECHR 'B'
 ETWO 'O', 'U'
 ECHR 'G'
 ECHR 'H'
 ECHR 'T'
 ECHR ' '
 ETWO 'A', 'T'
 ECHR ' '
 ETWO 'A', 'N'
 ECHR 'Y'
 ECHR ' '
 ECHR 'S'
 ECHR 'Y'
 ETWO 'S', 'T'
 ECHR 'E'
 ECHR 'M'
 ECHR ' '
 ECHR 'O'
 ECHR 'F'
 ECHR ' '
 ECHR 'T'
 ECHR 'E'
 ECHR 'C'
 ECHR 'H'
 ECHR ' '
 ETWO 'L', 'E'
 ETWO 'V', 'E'
 ECHR 'L'
 ECHR ' '
 ECHR '3'
 ECHR ' '
 ETWO 'O', 'R'
 ECHR ' '
 ECHR 'H'
 ECHR 'I'
 ECHR 'G'
 ECHR 'H'
 ETWO 'E', 'R'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ECHR 'W'
 ECHR 'H'
 ETWO 'E', 'N'
 ECHR ' '
 ECHR 'A'
 ECHR 'C'
 ETWO 'T', 'I'
 ECHR 'V'
 ETWO 'A', 'T'
 ETWO 'E', 'D'
 ECHR ','
 ECHR ' '
 ETOK 147
 EJMP 1
 ECHR 'E'
 ECHR '.'
 ECHR 'C'
 ECHR '.'
 ECHR 'M'
 ECHR '.'
 EJMP 13
 ECHR ' '
 ECHR 'S'
 ECHR 'Y'
 ETWO 'S', 'T'
 ECHR 'E'
 ECHR 'M'
 ECHR ' '
 ECHR 'W'
 ETWO 'I', 'L'
 ECHR 'L'
 ECHR ' '
 ETWO 'D', 'I'
 ECHR 'S'
 ECHR 'R'
 ECHR 'U'
 ECHR 'P'
 ECHR 'T'
 ECHR ' '
 ETOK 147
 ECHR 'G'
 ECHR 'U'
 ECHR 'I'
 ECHR 'D'
 ETWO 'A', 'N'
 ETWO 'C', 'E'
 ECHR ' '
 ECHR 'S'
 ECHR 'Y'
 ETWO 'S', 'T'
 ECHR 'E'
 ECHR 'M'
 ECHR 'S'
 ECHR ' '
 ECHR 'O'
 ECHR 'F'
 ECHR ' '
 ETWO 'A', 'L'
 ECHR 'L'
 ECHR ' '
 ECHR 'M'
 ECHR 'I'
 ECHR 'S'
 ECHR 'S'
 ETWO 'I', 'L'
 ETWO 'E', 'S'
 ECHR ' '
 ETWO 'I', 'N'
 ECHR ' '
 ETOK 147
 ECHR 'V'
 ECHR 'I'
 ECHR 'C'
 ETWO 'I', 'N'
 ETWO 'I', 'T'
 ECHR 'Y'
 ECHR ','
 ECHR ' '
 ETWO 'M', 'A'
 ECHR 'K'
 ETOK 195
 ETWO 'T', 'H'
 ECHR 'E'
 ECHR 'M'
 ECHR ' '
 ETWO 'S', 'E'
 ECHR 'L'
 ECHR 'F'
 ECHR ' '
 ECHR 'D'
 ECHR 'E'
 ETWO 'S', 'T'
 ECHR 'R'
 ECHR 'U'
 ECHR 'C'
 ECHR 'T'
 ETOK 177
 EQUB VE

 EJMP 14                \ Token 111:    "{justify}{single cap}PULSE LASERS ARE
 EJMP 19                \                FOR SALE AT TECH LEVEL 4 OR ABOVE.
 ECHR 'P'               \                {crlf}
 ECHR 'U'               \                {single cap}PULSE LASERS FIRE
 ECHR 'L'               \                INTERMITTENT LASER BEAMS.{cr}
 ETWO 'S', 'E'          \                {left align}"
 ECHR ' '               \
 ETWO 'L', 'A'          \ Encoded as:   "{14}{19}PUL<218> <249><218>RS <238>E
 ETWO 'S', 'E'          \                 F<253> S<228>E <245> TECH <229><250>L
 ECHR 'R'               \                 4 <253> <216>O<250>.<215>{19}PUL<218>
 ECHR 'S'               \                 <249><218>RS FI<242> <240>T<244>M<219>
 ECHR ' '               \                T<246>T <249><218>R <247>AMS[177]"
 ETWO 'A', 'R'
 ECHR 'E'
 ECHR ' '
 ECHR 'F'
 ETWO 'O', 'R'
 ECHR ' '
 ECHR 'S'
 ETWO 'A', 'L'
 ECHR 'E'
 ECHR ' '
 ETWO 'A', 'T'
 ECHR ' '
 ECHR 'T'
 ECHR 'E'
 ECHR 'C'
 ECHR 'H'
 ECHR ' '
 ETWO 'L', 'E'
 ETWO 'V', 'E'
 ECHR 'L'
 ECHR ' '
 ECHR '4'
 ECHR ' '
 ETWO 'O', 'R'
 ECHR ' '
 ETWO 'A', 'B'
 ECHR 'O'
 ETWO 'V', 'E'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ECHR 'P'
 ECHR 'U'
 ECHR 'L'
 ETWO 'S', 'E'
 ECHR ' '
 ETWO 'L', 'A'
 ETWO 'S', 'E'
 ECHR 'R'
 ECHR 'S'
 ECHR ' '
 ECHR 'F'
 ECHR 'I'
 ETWO 'R', 'E'
 ECHR ' '
 ETWO 'I', 'N'
 ECHR 'T'
 ETWO 'E', 'R'
 ECHR 'M'
 ETWO 'I', 'T'
 ECHR 'T'
 ETWO 'E', 'N'
 ECHR 'T'
 ECHR ' '
 ETWO 'L', 'A'
 ETWO 'S', 'E'
 ECHR 'R'
 ECHR ' '
 ETWO 'B', 'E'
 ECHR 'A'
 ECHR 'M'
 ECHR 'S'
 ETOK 177
 EQUB VE

 EJMP 14                \ Token 112:    "{justify}{single cap}BEAM LASERS ARE
 EJMP 19                \                AVAILABLE AT SYSTEMS OF TECH LEVEL 5 OR
 ETWO 'B', 'E'          \                HIGHER.{crlf}
 ECHR 'A'               \                {single cap}BEAM LASERS FIRE CONTINUOUS
 ECHR 'M'               \                LASER STRANDS, WITH MANY STRANDS IN
 ECHR ' '               \                PARALLEL.{crlf}
 ETWO 'L', 'A'          \                {single cap}BEAM LASERS OVERHEAT MORE
 ETWO 'S', 'E'          \                RAPIDLY THAN PULSE LASERS.{cr}
 ECHR 'R'               \                {left align}"
 ECHR 'S'               \
 ECHR ' '               \ Encoded as:   "{14}{19}<247>AM <249><218>RS <238>E AVA
 ETWO 'A', 'R'          \                <220><216><229> <245> SY<222>EMS OF TEC
 ECHR 'E'               \                H <229><250>L 5 <253> HIGH<244>.<215>
 ECHR ' '               \                {19}<247>AM <249><218>RS FI<242> C<223>
 ECHR 'A'               \                <251><225><217>S <249><218>R <222><248>
 ECHR 'V'               \                NDS, W<219>H <239>NY <222><248>NDS
 ECHR 'A'               \                 <240> P<238><228><229>L.<215>{19}<247>
 ETWO 'I', 'L'          \                AM <249><218>RS OV<244>HE<245> MO<242>
 ETWO 'A', 'B'          \                 <248>PIDLY <226><255> PUL<218> <249>  
 ETWO 'L', 'E'          \                <218>RS[177]"
 ECHR ' '
 ETWO 'A', 'T'
 ECHR ' '
 ECHR 'S'
 ECHR 'Y'
 ETWO 'S', 'T'
 ECHR 'E'
 ECHR 'M'
 ECHR 'S'
 ECHR ' '
 ECHR 'O'
 ECHR 'F'
 ECHR ' '
 ECHR 'T'
 ECHR 'E'
 ECHR 'C'
 ECHR 'H'
 ECHR ' '
 ETWO 'L', 'E'
 ETWO 'V', 'E'
 ECHR 'L'
 ECHR ' '
 ECHR '5'
 ECHR ' '
 ETWO 'O', 'R'
 ECHR ' '
 ECHR 'H'
 ECHR 'I'
 ECHR 'G'
 ECHR 'H'
 ETWO 'E', 'R'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ETWO 'B', 'E'
 ECHR 'A'
 ECHR 'M'
 ECHR ' '
 ETWO 'L', 'A'
 ETWO 'S', 'E'
 ECHR 'R'
 ECHR 'S'
 ECHR ' '
 ECHR 'F'
 ECHR 'I'
 ETWO 'R', 'E'
 ECHR ' '
 ECHR 'C'
 ETWO 'O', 'N'
 ETWO 'T', 'I'
 ETWO 'N', 'U'
 ETWO 'O', 'U'
 ECHR 'S'
 ECHR ' '
 ETWO 'L', 'A'
 ETWO 'S', 'E'
 ECHR 'R'
 ECHR ' '
 ETWO 'S', 'T'
 ETWO 'R', 'A'
 ECHR 'N'
 ECHR 'D'
 ECHR 'S'
 ECHR ','
 ECHR ' '
 ECHR 'W'
 ETWO 'I', 'T'
 ECHR 'H'
 ECHR ' '
 ETWO 'M', 'A'
 ECHR 'N'
 ECHR 'Y'
 ECHR ' '
 ETWO 'S', 'T'
 ETWO 'R', 'A'
 ECHR 'N'
 ECHR 'D'
 ECHR 'S'
 ECHR ' '
 ETWO 'I', 'N'
 ECHR ' '
 ECHR 'P'
 ETWO 'A', 'R'
 ETWO 'A', 'L'
 ETWO 'L', 'E'
 ECHR 'L'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ETWO 'B', 'E'
 ECHR 'A'
 ECHR 'M'
 ECHR ' '
 ETWO 'L', 'A'
 ETWO 'S', 'E'
 ECHR 'R'
 ECHR 'S'
 ECHR ' '
 ECHR 'O'
 ECHR 'V'
 ETWO 'E', 'R'
 ECHR 'H'
 ECHR 'E'
 ETWO 'A', 'T'
 ECHR ' '
 ECHR 'M'
 ECHR 'O'
 ETWO 'R', 'E'
 ECHR ' '
 ETWO 'R', 'A'
 ECHR 'P'
 ECHR 'I'
 ECHR 'D'
 ECHR 'L'
 ECHR 'Y'
 ECHR ' '
 ETWO 'T', 'H'
 ETWO 'A', 'N'
 ECHR ' '
 ECHR 'P'
 ECHR 'U'
 ECHR 'L'
 ETWO 'S', 'E'
 ECHR ' '
 ETWO 'L', 'A'
 ETWO 'S', 'E'
 ECHR 'R'
 ECHR 'S'
 ETOK 177
 EQUB VE

 EJMP 14                \ Token 113:    "{justify}{single cap}FUEL SCOOPS ENABLE
 EJMP 19                \                A SHIP TO OBTAIN FREE HYPERSPACE FUEL
 ECHR 'F'               \                BY 'SUN-SKIMMING' - FLYING CLOSE TO THE
 ECHR 'U'               \                SUN.{crlf}
 ECHR 'E'               \                {single cap}FUEL SCOOPS CAN ALSO BE
 ECHR 'L'               \                USED TO PICK UP SPACE DEBRIS, SUCH AS
 ECHR ' '               \                CARGO BARRELS OR ASTEROID FRAGMENTS.
 ECHR 'S'               \                {crlf}
 ECHR 'C'               \                {single cap}FUEL SCOOPS ARE AVAILABLE
 ECHR 'O'               \                FROM SYSTEMS OF TECH LEVEL 6 OR ABOVE.
 ECHR 'O'               \                {cr}
 ECHR 'P'               \                {left align}"
 ECHR 'S'               \
 ECHR ' '               \ Encoded as:   "{14}{19}FUEL SCOOPS <246><216><229>
 ETWO 'E', 'N'          \                [208][207][201]OBTA<240> F<242>E HYP
 ETWO 'A', 'B'          \                <244>SPA<233> FUEL BY 'SUN-SKIMM<240>G'
 ETWO 'L', 'E'          \                 - FLY[195]C<224><218>[201][147]SUN.
 ETOK 208               \                <215>{19}FUEL SCOOPS C<255> <228><235>
 ETOK 207               \                 <247> <236>[196]TO PICK UP SPA<233> DE
 ETOK 201               \                BRIS, SUCH AS C<238>GO B<238><242>LS
 ECHR 'O'               \                 <253> A<222><244>OID F<248>GM<246>TS.
 ECHR 'B'               \                <215>{19}FUEL SCOOPS <238>E AVA<220>
 ECHR 'T'               \                <216><229> FROM SY<222>EMS OF TECH
 ECHR 'A'               \                 <229><250>L 6 <253> <216>O<250>[177]"
 ETWO 'I', 'N'
 ECHR ' '
 ECHR 'F'
 ETWO 'R', 'E'
 ECHR 'E'
 ECHR ' '
 ECHR 'H'
 ECHR 'Y'
 ECHR 'P'
 ETWO 'E', 'R'
 ECHR 'S'
 ECHR 'P'
 ECHR 'A'
 ETWO 'C', 'E'
 ECHR ' '
 ECHR 'F'
 ECHR 'U'
 ECHR 'E'
 ECHR 'L'
 ECHR ' '
 ECHR 'B'
 ECHR 'Y'
 ECHR ' '
 ECHR '`'
 ECHR 'S'
 ECHR 'U'
 ECHR 'N'
 ECHR '-'
 ECHR 'S'
 ECHR 'K'
 ECHR 'I'
 ECHR 'M'
 ECHR 'M'
 ETWO 'I', 'N'
 ECHR 'G'
 ECHR '`'
 ECHR ' '
 ECHR '-'
 ECHR ' '
 ECHR 'F'
 ECHR 'L'
 ECHR 'Y'
 ETOK 195
 ECHR 'C'
 ETWO 'L', 'O'
 ETWO 'S', 'E'
 ETOK 201
 ETOK 147
 ECHR 'S'
 ECHR 'U'
 ECHR 'N'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ECHR 'F'
 ECHR 'U'
 ECHR 'E'
 ECHR 'L'
 ECHR ' '
 ECHR 'S'
 ECHR 'C'
 ECHR 'O'
 ECHR 'O'
 ECHR 'P'
 ECHR 'S'
 ECHR ' '
 ECHR 'C'
 ETWO 'A', 'N'
 ECHR ' '
 ETWO 'A', 'L'
 ETWO 'S', 'O'
 ECHR ' '
 ETWO 'B', 'E'
 ECHR ' '
 ETWO 'U', 'S'
 ETOK 196
 ECHR 'T'
 ECHR 'O'
 ECHR ' '
 ECHR 'P'
 ECHR 'I'
 ECHR 'C'
 ECHR 'K'
 ECHR ' '
 ECHR 'U'
 ECHR 'P'
 ECHR ' '
 ECHR 'S'
 ECHR 'P'
 ECHR 'A'
 ETWO 'C', 'E'
 ECHR ' '
 ECHR 'D'
 ECHR 'E'
 ECHR 'B'
 ECHR 'R'
 ECHR 'I'
 ECHR 'S'
 ECHR ','
 ECHR ' '
 ECHR 'S'
 ECHR 'U'
 ECHR 'C'
 ECHR 'H'
 ECHR ' '
 ECHR 'A'
 ECHR 'S'
 ECHR ' '
 ECHR 'C'
 ETWO 'A', 'R'
 ECHR 'G'
 ECHR 'O'
 ECHR ' '
 ECHR 'B'
 ETWO 'A', 'R'
 ETWO 'R', 'E'
 ECHR 'L'
 ECHR 'S'
 ECHR ' '
 ETWO 'O', 'R'
 ECHR ' '
 ECHR 'A'
 ETWO 'S', 'T'
 ETWO 'E', 'R'
 ECHR 'O'
 ECHR 'I'
 ECHR 'D'
 ECHR ' '
 ECHR 'F'
 ETWO 'R', 'A'
 ECHR 'G'
 ECHR 'M'
 ETWO 'E', 'N'
 ECHR 'T'
 ECHR 'S'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ECHR 'F'
 ECHR 'U'
 ECHR 'E'
 ECHR 'L'
 ECHR ' '
 ECHR 'S'
 ECHR 'C'
 ECHR 'O'
 ECHR 'O'
 ECHR 'P'
 ECHR 'S'
 ECHR ' '
 ETWO 'A', 'R'
 ECHR 'E'
 ECHR ' '
 ECHR 'A'
 ECHR 'V'
 ECHR 'A'
 ETWO 'I', 'L'
 ETWO 'A', 'B'
 ETWO 'L', 'E'
 ECHR ' '
 ECHR 'F'
 ECHR 'R'
 ECHR 'O'
 ECHR 'M'
 ECHR ' '
 ECHR 'S'
 ECHR 'Y'
 ETWO 'S', 'T'
 ECHR 'E'
 ECHR 'M'
 ECHR 'S'
 ECHR ' '
 ECHR 'O'
 ECHR 'F'
 ECHR ' '
 ECHR 'T'
 ECHR 'E'
 ECHR 'C'
 ECHR 'H'
 ECHR ' '
 ETWO 'L', 'E'
 ETWO 'V', 'E'
 ECHR 'L'
 ECHR ' '
 ECHR '6'
 ECHR ' '
 ETWO 'O', 'R'
 ECHR ' '
 ETWO 'A', 'B'
 ECHR 'O'
 ETWO 'V', 'E'
 ETOK 177
 EQUB VE

 EJMP 14                \ Token 114:    "{justify}{single cap}AN ESCAPE POD IS
 EJMP 19                \                AN ESSENTIAL PIECE OF EQUIPMENT FOR
 ETWO 'A', 'N'          \                MOST SPACESHIPS.{crlf}
 ECHR ' '               \                {single cap}WHEN EJECTED, THE CAPSULE
 ETWO 'E', 'S'          \                WILL BE TRACKED TO THE NEAREST SPACE
 ECHR 'C'               \                STATION.{crlf}
 ECHR 'A'               \                {single cap}MOST ESCAPE PODS COME WITH
 ECHR 'P'               \                INSURANCE POLICIES TO REPLACE THE SHIP
 ECHR 'E'               \                AND EQUIPMENT.{crlf}
 ECHR ' '               \                {single cap}PENALTIES FOR INTERFERING
 ECHR 'P'               \                WITH ESCAPE PODS ARE SEVERE IN MOST
 ECHR 'O'               \                PLANETARY SYSTEMS.{crlf}
 ECHR 'D'               \                {single cap}ESCAPE PODS MAY BE BOUGHT
 ETOK 202               \                AT SYSTEMS OF TECH LEVEL 7 OR HIGHER.
 ETWO 'A', 'N'          \                {cr}
 ECHR ' '               \                {left align}"
 ETWO 'E', 'S'          \
 ETWO 'S', 'E'          \ Encoded as:   "{14}{19}<255> <237>CAPE POD[202]<255>
 ECHR 'N'               \                 <237><218>N<251><228> PIE<233> OF EQUI
 ETWO 'T', 'I'          \                PM<246>T F<253> MO<222> SPA<233>[207]S.
 ETWO 'A', 'L'          \                <215>{19}WH<246> EJECT<252>, [147]CAPSU
 ECHR ' '               \                <229> W<220>L <247> T<248>CK[196]TO
 ECHR 'P'               \                 [147]NE<238>E<222> SPA<233> <222><245>
 ECHR 'I'               \                I<223>.<215>{19}MO<222> <237>CAPE PODS
 ECHR 'E'               \                 COME W<219>H <240>SU<248>N<233> POLICI
 ETWO 'C', 'E'          \                <237>[201]<242>P<249><233> [147][207]
 ECHR ' '               \                [178]EQUIPM<246>T.<215>{19}P<246><228>
 ECHR 'O'               \                <251><237> F<253> <240>T<244>F<244>
 ECHR 'F'               \                [195]W<219>H <237>CAPE PODS <238>E 
 ECHR ' '               \                <218><250><242> <240> MO<222> [145]
 ECHR 'E'               \                <238>Y SY<222>EMS.<215>{19}<237>CAPE PO
 ECHR 'Q'               \                DS <239>Y <247> B<217>GHT <245> SY<222>
 ECHR 'U'               \                EMS OF TECH <229><250>L 7 <253> HIGH
 ECHR 'I'               \                <244>[177]"
 ECHR 'P'
 ECHR 'M'
 ETWO 'E', 'N'
 ECHR 'T'
 ECHR ' '
 ECHR 'F'
 ETWO 'O', 'R'
 ECHR ' '
 ECHR 'M'
 ECHR 'O'
 ETWO 'S', 'T'
 ECHR ' '
 ECHR 'S'
 ECHR 'P'
 ECHR 'A'
 ETWO 'C', 'E'
 ETOK 207
 ECHR 'S'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ECHR 'W'
 ECHR 'H'
 ETWO 'E', 'N'
 ECHR ' '
 ECHR 'E'
 ECHR 'J'
 ECHR 'E'
 ECHR 'C'
 ECHR 'T'
 ETWO 'E', 'D'
 ECHR ','
 ECHR ' '
 ETOK 147
 ECHR 'C'
 ECHR 'A'
 ECHR 'P'
 ECHR 'S'
 ECHR 'U'
 ETWO 'L', 'E'
 ECHR ' '
 ECHR 'W'
 ETWO 'I', 'L'
 ECHR 'L'
 ECHR ' '
 ETWO 'B', 'E'
 ECHR ' '
 ECHR 'T'
 ETWO 'R', 'A'
 ECHR 'C'
 ECHR 'K'
 ETOK 196
 ECHR 'T'
 ECHR 'O'
 ECHR ' '
 ETOK 147
 ECHR 'N'
 ECHR 'E'
 ETWO 'A', 'R'
 ECHR 'E'
 ETWO 'S', 'T'
 ECHR ' '
 ECHR 'S'
 ECHR 'P'
 ECHR 'A'
 ETWO 'C', 'E'
 ECHR ' '
 ETWO 'S', 'T'
 ETWO 'A', 'T'
 ECHR 'I'
 ETWO 'O', 'N'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ECHR 'M'
 ECHR 'O'
 ETWO 'S', 'T'
 ECHR ' '
 ETWO 'E', 'S'
 ECHR 'C'
 ECHR 'A'
 ECHR 'P'
 ECHR 'E'
 ECHR ' '
 ECHR 'P'
 ECHR 'O'
 ECHR 'D'
 ECHR 'S'
 ECHR ' '
 ECHR 'C'
 ECHR 'O'
 ECHR 'M'
 ECHR 'E'
 ECHR ' '
 ECHR 'W'
 ETWO 'I', 'T'
 ECHR 'H'
 ECHR ' '
 ETWO 'I', 'N'
 ECHR 'S'
 ECHR 'U'
 ETWO 'R', 'A'
 ECHR 'N'
 ETWO 'C', 'E'
 ECHR ' '
 ECHR 'P'
 ECHR 'O'
 ECHR 'L'
 ECHR 'I'
 ECHR 'C'
 ECHR 'I'
 ETWO 'E', 'S'
 ETOK 201
 ETWO 'R', 'E'
 ECHR 'P'
 ETWO 'L', 'A'
 ETWO 'C', 'E'
 ECHR ' '
 ETOK 147
 ETOK 207
 ETOK 178
 ECHR 'E'
 ECHR 'Q'
 ECHR 'U'
 ECHR 'I'
 ECHR 'P'
 ECHR 'M'
 ETWO 'E', 'N'
 ECHR 'T'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ECHR 'P'
 ETWO 'E', 'N'
 ETWO 'A', 'L'
 ETWO 'T', 'I'
 ETWO 'E', 'S'
 ECHR ' '
 ECHR 'F'
 ETWO 'O', 'R'
 ECHR ' '
 ETWO 'I', 'N'
 ECHR 'T'
 ETWO 'E', 'R'
 ECHR 'F'
 ETWO 'E', 'R'
 ETOK 195
 ECHR 'W'
 ETWO 'I', 'T'
 ECHR 'H'
 ECHR ' '
 ETWO 'E', 'S'
 ECHR 'C'
 ECHR 'A'
 ECHR 'P'
 ECHR 'E'
 ECHR ' '
 ECHR 'P'
 ECHR 'O'
 ECHR 'D'
 ECHR 'S'
 ECHR ' '
 ETWO 'A', 'R'
 ECHR 'E'
 ECHR ' '
 ETWO 'S', 'E'
 ETWO 'V', 'E'
 ETWO 'R', 'E'
 ECHR ' '
 ETWO 'I', 'N'
 ECHR ' '
 ECHR 'M'
 ECHR 'O'
 ETWO 'S', 'T'
 ECHR ' '
 ETOK 145
 ETWO 'A', 'R'
 ECHR 'Y'
 ECHR ' '
 ECHR 'S'
 ECHR 'Y'
 ETWO 'S', 'T'
 ECHR 'E'
 ECHR 'M'
 ECHR 'S'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ETWO 'E', 'S'
 ECHR 'C'
 ECHR 'A'
 ECHR 'P'
 ECHR 'E'
 ECHR ' '
 ECHR 'P'
 ECHR 'O'
 ECHR 'D'
 ECHR 'S'
 ECHR ' '
 ETWO 'M', 'A'
 ECHR 'Y'
 ECHR ' '
 ETWO 'B', 'E'
 ECHR ' '
 ECHR 'B'
 ETWO 'O', 'U'
 ECHR 'G'
 ECHR 'H'
 ECHR 'T'
 ECHR ' '
 ETWO 'A', 'T'
 ECHR ' '
 ECHR 'S'
 ECHR 'Y'
 ETWO 'S', 'T'
 ECHR 'E'
 ECHR 'M'
 ECHR 'S'
 ECHR ' '
 ECHR 'O'
 ECHR 'F'
 ECHR ' '
 ECHR 'T'
 ECHR 'E'
 ECHR 'C'
 ECHR 'H'
 ECHR ' '
 ETWO 'L', 'E'
 ETWO 'V', 'E'
 ECHR 'L'
 ECHR ' '
 ECHR '7'
 ECHR ' '
 ETWO 'O', 'R'
 ECHR ' '
 ECHR 'H'
 ECHR 'I'
 ECHR 'G'
 ECHR 'H'
 ETWO 'E', 'R'
 ETOK 177
 EQUB VE

 EJMP 14                \ Token 115:    "{justify}{single cap}A RECENT
 EJMP 19                \                INVENTION, THE HYPERSPACE UNIT IS AN
 ECHR 'A'               \                ALTERNATIVE TO THE ESCAPE POD FOR MANY
 ECHR ' '               \                TRADERS.{crlf}
 ETWO 'R', 'E'          \                {single cap}WHEN TRIGGERED, THE
 ETWO 'C', 'E'          \                HYPERSPACE UNIT WILL USE ITS POWER IN
 ECHR 'N'               \                EXECUTING A HYPERJUMP AWAY FROM THE
 ECHR 'T'               \                CURRENT POSITION.{crlf}
 ECHR ' '               \                {single cap}UNFORTUNATELY, BECAUSE THE
 ETWO 'I', 'N'          \                HYPERJUMP IS INSTANTANEOUS, THERE IS NO
 ECHR 'V'               \                CONTROL OF THE DESTINATION POSITION.
 ETWO 'E', 'N'          \                {crlf}
 ETWO 'T', 'I'          \                {single cap}A HYPERSPACE UNIT IS
 ETWO 'O', 'N'          \                AVAILABLE AT TECH LEVEL 8 OR ABOVE.{cr}
 ECHR ','               \                {left align}"
 ECHR ' '               \
 ETOK 147               \ Encoded as:   "{14}{19}A <242><233>NT <240>V<246><251>
 ECHR 'H'               \                <223>, [147]HYP<244>SPA<233> UN<219>
 ECHR 'Y'               \                [202]<255> <228>T<244>N<245>I<250> TO
 ECHR 'P'               \                 [147]<237>CAPE POD F<253> <239>NY T
 ETWO 'E', 'R'          \                <248>D<244>S.<215>{19}WH<246> TRIG<231>
 ECHR 'S'               \                <242>D, [147]HYP<244>SPA<233> UN<219> W
 ECHR 'P'               \                <220>L U<218> <219>S POW<244> <240> E
 ECHR 'A'               \                <230>CUT[195]A HYP<244>JUMP AWAY FROM
 ETWO 'C', 'E'          \                 [147]CUR<242>NT POS<219>I<223>.<215>
 ECHR ' '               \                {19}UNF<253>TUN<245>ELY, <247>CAU<218>
 ECHR 'U'               \                 [147]HYP<244>JUMP[202]<240><222><255>T
 ECHR 'N'               \                <255>E<217>S, <226>E<242>[202]<227> C
 ETWO 'I', 'T'          \                <223>TROL OF [147]DE<222><240><245>I
 ETOK 202               \                <223> POS<219>I<223>.<215>{19}A HYP
 ETWO 'A', 'N'          \                <244>SPA<233> UN<219>[202]AVA<220><216>
 ECHR ' '               \                <229> <245> TECH <229><250>L 8 <253>
 ETWO 'A', 'L'          \                 <216>O<250>[177]"
 ECHR 'T'
 ETWO 'E', 'R'
 ECHR 'N'
 ETWO 'A', 'T'
 ECHR 'I'
 ETWO 'V', 'E'
 ECHR ' '
 ECHR 'T'
 ECHR 'O'
 ECHR ' '
 ETOK 147
 ETWO 'E', 'S'
 ECHR 'C'
 ECHR 'A'
 ECHR 'P'
 ECHR 'E'
 ECHR ' '
 ECHR 'P'
 ECHR 'O'
 ECHR 'D'
 ECHR ' '
 ECHR 'F'
 ETWO 'O', 'R'
 ECHR ' '
 ETWO 'M', 'A'
 ECHR 'N'
 ECHR 'Y'
 ECHR ' '
 ECHR 'T'
 ETWO 'R', 'A'
 ECHR 'D'
 ETWO 'E', 'R'
 ECHR 'S'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ECHR 'W'
 ECHR 'H'
 ETWO 'E', 'N'
 ECHR ' '
 ECHR 'T'
 ECHR 'R'
 ECHR 'I'
 ECHR 'G'
 ETWO 'G', 'E'
 ETWO 'R', 'E'
 ECHR 'D'
 ECHR ','
 ECHR ' '
 ETOK 147
 ECHR 'H'
 ECHR 'Y'
 ECHR 'P'
 ETWO 'E', 'R'
 ECHR 'S'
 ECHR 'P'
 ECHR 'A'
 ETWO 'C', 'E'
 ECHR ' '
 ECHR 'U'
 ECHR 'N'
 ETWO 'I', 'T'
 ECHR ' '
 ECHR 'W'
 ETWO 'I', 'L'
 ECHR 'L'
 ECHR ' '
 ECHR 'U'
 ETWO 'S', 'E'
 ECHR ' '
 ETWO 'I', 'T'
 ECHR 'S'
 ECHR ' '
 ECHR 'P'
 ECHR 'O'
 ECHR 'W'
 ETWO 'E', 'R'
 ECHR ' '
 ETWO 'I', 'N'
 ECHR ' '
 ECHR 'E'
 ETWO 'X', 'E'
 ECHR 'C'
 ECHR 'U'
 ECHR 'T'
 ETOK 195
 ECHR 'A'
 ECHR ' '
 ECHR 'H'
 ECHR 'Y'
 ECHR 'P'
 ETWO 'E', 'R'
 ECHR 'J'
 ECHR 'U'
 ECHR 'M'
 ECHR 'P'
 ECHR ' '
 ECHR 'A'
 ECHR 'W'
 ECHR 'A'
 ECHR 'Y'
 ECHR ' '
 ECHR 'F'
 ECHR 'R'
 ECHR 'O'
 ECHR 'M'
 ECHR ' '
 ETOK 147
 ECHR 'C'
 ECHR 'U'
 ECHR 'R'
 ETWO 'R', 'E'
 ECHR 'N'
 ECHR 'T'
 ECHR ' '
 ECHR 'P'
 ECHR 'O'
 ECHR 'S'
 ETWO 'I', 'T'
 ECHR 'I'
 ETWO 'O', 'N'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ECHR 'U'
 ECHR 'N'
 ECHR 'F'
 ETWO 'O', 'R'
 ECHR 'T'
 ECHR 'U'
 ECHR 'N'
 ETWO 'A', 'T'
 ECHR 'E'
 ECHR 'L'
 ECHR 'Y'
 ECHR ','
 ECHR ' '
 ETWO 'B', 'E'
 ECHR 'C'
 ECHR 'A'
 ECHR 'U'
 ETWO 'S', 'E'
 ECHR ' '
 ETOK 147
 ECHR 'H'
 ECHR 'Y'
 ECHR 'P'
 ETWO 'E', 'R'
 ECHR 'J'
 ECHR 'U'
 ECHR 'M'
 ECHR 'P'
 ETOK 202
 ETWO 'I', 'N'
 ETWO 'S', 'T'
 ETWO 'A', 'N'
 ECHR 'T'
 ETWO 'A', 'N'
 ECHR 'E'
 ETWO 'O', 'U'
 ECHR 'S'
 ECHR ','
 ECHR ' '
 ETWO 'T', 'H'
 ECHR 'E'
 ETWO 'R', 'E'
 ETOK 202
 ETWO 'N', 'O'
 ECHR ' '
 ECHR 'C'
 ETWO 'O', 'N'
 ECHR 'T'
 ECHR 'R'
 ECHR 'O'
 ECHR 'L'
 ECHR ' '
 ECHR 'O'
 ECHR 'F'
 ECHR ' '
 ETOK 147
 ECHR 'D'
 ECHR 'E'
 ETWO 'S', 'T'
 ETWO 'I', 'N'
 ETWO 'A', 'T'
 ECHR 'I'
 ETWO 'O', 'N'
 ECHR ' '
 ECHR 'P'
 ECHR 'O'
 ECHR 'S'
 ETWO 'I', 'T'
 ECHR 'I'
 ETWO 'O', 'N'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ECHR 'A'
 ECHR ' '
 ECHR 'H'
 ECHR 'Y'
 ECHR 'P'
 ETWO 'E', 'R'
 ECHR 'S'
 ECHR 'P'
 ECHR 'A'
 ETWO 'C', 'E'
 ECHR ' '
 ECHR 'U'
 ECHR 'N'
 ETWO 'I', 'T'
 ETOK 202
 ECHR 'A'
 ECHR 'V'
 ECHR 'A'
 ETWO 'I', 'L'
 ETWO 'A', 'B'
 ETWO 'L', 'E'
 ECHR ' '
 ETWO 'A', 'T'
 ECHR ' '
 ECHR 'T'
 ECHR 'E'
 ECHR 'C'
 ECHR 'H'
 ECHR ' '
 ETWO 'L', 'E'
 ETWO 'V', 'E'
 ECHR 'L'
 ECHR ' '
 ECHR '8'
 ECHR ' '
 ETWO 'O', 'R'
 ECHR ' '
 ETWO 'A', 'B'
 ECHR 'O'
 ETWO 'V', 'E'
 ETOK 177
 EQUB VE

 EJMP 14                \ Token 116:    "{justify}{single cap}AN ENERGY UNIT
 EJMP 19                \                INCREASES THE RATE OF RECHARGING OF THE
 ETWO 'A', 'N'          \                ENERGY BANKS FROM SURFACE RADIATION
 ECHR ' '               \                ABSORPTION.{crlf}
 ETWO 'E', 'N'          \                {single cap}ENERGY UNITS ARE AVAILABLE
 ETWO 'E', 'R'          \                FROM TECH LEVEL 9 UPWARDS.{cr}
 ECHR 'G'               \                {left align}"
 ECHR 'Y'               \
 ECHR ' '               \ Encoded as:   "{14}{19}<255> <246><244>GY UN<219>
 ECHR 'U'               \                 <240>C<242>A<218>S [147]R<245>E OF
 ECHR 'N'               \                 <242>CH<238>G[195]OF [147]<246><244>GY
 ETWO 'I', 'T'          \                 B<255>KS FROM SURFA<233> <248><241>
 ECHR ' '               \                <245>I<223> <216><235>RP<251><223>.
 ETWO 'I', 'N'          \                <215>{19}<246><244>GY UN<219>S <238>E
 ECHR 'C'               \                 AVA<220><216><229> FROM TECH <229>
 ETWO 'R', 'E'          \                <250>L 9 UPW<238>DS[177]"
 ECHR 'A'
 ETWO 'S', 'E'
 ECHR 'S'
 ECHR ' '
 ETOK 147
 ECHR 'R'
 ETWO 'A', 'T'
 ECHR 'E'
 ECHR ' '
 ECHR 'O'
 ECHR 'F'
 ECHR ' '
 ETWO 'R', 'E'
 ECHR 'C'
 ECHR 'H'
 ETWO 'A', 'R'
 ECHR 'G'
 ETOK 195
 ECHR 'O'
 ECHR 'F'
 ECHR ' '
 ETOK 147
 ETWO 'E', 'N'
 ETWO 'E', 'R'
 ECHR 'G'
 ECHR 'Y'
 ECHR ' '
 ECHR 'B'
 ETWO 'A', 'N'
 ECHR 'K'
 ECHR 'S'
 ECHR ' '
 ECHR 'F'
 ECHR 'R'
 ECHR 'O'
 ECHR 'M'
 ECHR ' '
 ECHR 'S'
 ECHR 'U'
 ECHR 'R'
 ECHR 'F'
 ECHR 'A'
 ETWO 'C', 'E'
 ECHR ' '
 ETWO 'R', 'A'
 ETWO 'D', 'I'
 ETWO 'A', 'T'
 ECHR 'I'
 ETWO 'O', 'N'
 ECHR ' '
 ETWO 'A', 'B'
 ETWO 'S', 'O'
 ECHR 'R'
 ECHR 'P'
 ETWO 'T', 'I'
 ETWO 'O', 'N'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ETWO 'E', 'N'
 ETWO 'E', 'R'
 ECHR 'G'
 ECHR 'Y'
 ECHR ' '
 ECHR 'U'
 ECHR 'N'
 ETWO 'I', 'T'
 ECHR 'S'
 ECHR ' '
 ETWO 'A', 'R'
 ECHR 'E'
 ECHR ' '
 ECHR 'A'
 ECHR 'V'
 ECHR 'A'
 ETWO 'I', 'L'
 ETWO 'A', 'B'
 ETWO 'L', 'E'
 ECHR ' '
 ECHR 'F'
 ECHR 'R'
 ECHR 'O'
 ECHR 'M'
 ECHR ' '
 ECHR 'T'
 ECHR 'E'
 ECHR 'C'
 ECHR 'H'
 ECHR ' '
 ETWO 'L', 'E'
 ETWO 'V', 'E'
 ECHR 'L'
 ECHR ' '
 ECHR '9'
 ECHR ' '
 ECHR 'U'
 ECHR 'P'
 ECHR 'W'
 ETWO 'A', 'R'
 ECHR 'D'
 ECHR 'S'
 ETOK 177
 EQUB VE

 EJMP 14                \ Token 117:    "{justify}{single cap}DOCKING COMPUTERS
 EJMP 19                \                ARE RECOMMENDED BY ALL PLANETARY
 ECHR 'D'               \                GOVERNMENTS AS A SAFE WAY OF REDUCING
 ECHR 'O'               \                THE NUMBER OF DOCKING ACCIDENTS.{crlf}
 ECHR 'C'               \                {single cap}DOCKING COMPUTERS WILL
 ECHR 'K'               \                AUTOMATICALLY DOCK A SHIP WHEN TURNED
 ETOK 195               \                ON.{crlf}
 ECHR 'C'               \                {single cap}DOCKING COMPUTERS CAN BE
 ECHR 'O'               \                BOUGHT AT SYSTEMS OF TECH LEVEL 10 OR
 ECHR 'M'               \                MORE.{cr}
 ECHR 'P'               \                {left align}"
 ECHR 'U'               \
 ECHR 'T'               \ Encoded as:   "{14}{19}DOCK[195]COMPUT<244>S <238>E
 ETWO 'E', 'R'          \                 <242>COMM<246>D[196]BY <228>L [145]
 ECHR 'S'               \                <238>Y GOV<244>NM<246>TS AS[208]SAFE WA
 ECHR ' '               \                Y OF <242>DUC[195][147]<225>MB<244> OF
 ETWO 'A', 'R'          \                 DOCK[195]ACCID<246>TS.<215>{19}DOCK
 ECHR 'E'               \                [195]COMPUT<244>S W<220>L AUTO<239>
 ECHR ' '               \                <251>C<228>LY DOCK[208][207] WH<246> TU
 ETWO 'R', 'E'          \                RN[196]<223>.<215>{19}DOCK[195]COMPUT
 ECHR 'C'               \                <244>S C<255> <247> B<217>GHT <245> SY
 ECHR 'O'               \                <222>EMS OF TECH <229><250>L 10 <253> M
 ECHR 'M'               \                O<242>[177]"
 ECHR 'M'
 ETWO 'E', 'N'
 ECHR 'D'
 ETOK 196
 ECHR 'B'
 ECHR 'Y'
 ECHR ' '
 ETWO 'A', 'L'
 ECHR 'L'
 ECHR ' '
 ETOK 145
 ETWO 'A', 'R'
 ECHR 'Y'
 ECHR ' '
 ECHR 'G'
 ECHR 'O'
 ECHR 'V'
 ETWO 'E', 'R'
 ECHR 'N'
 ECHR 'M'
 ETWO 'E', 'N'
 ECHR 'T'
 ECHR 'S'
 ECHR ' '
 ECHR 'A'
 ECHR 'S'
 ETOK 208
 ECHR 'S'
 ECHR 'A'
 ECHR 'F'
 ECHR 'E'
 ECHR ' '
 ECHR 'W'
 ECHR 'A'
 ECHR 'Y'
 ECHR ' '
 ECHR 'O'
 ECHR 'F'
 ECHR ' '
 ETWO 'R', 'E'
 ECHR 'D'
 ECHR 'U'
 ECHR 'C'
 ETOK 195
 ETOK 147
 ETWO 'N', 'U'
 ECHR 'M'
 ECHR 'B'
 ETWO 'E', 'R'
 ECHR ' '
 ECHR 'O'
 ECHR 'F'
 ECHR ' '
 ECHR 'D'
 ECHR 'O'
 ECHR 'C'
 ECHR 'K'
 ETOK 195
 ECHR 'A'
 ECHR 'C'
 ECHR 'C'
 ECHR 'I'
 ECHR 'D'
 ETWO 'E', 'N'
 ECHR 'T'
 ECHR 'S'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ECHR 'D'
 ECHR 'O'
 ECHR 'C'
 ECHR 'K'
 ETOK 195
 ECHR 'C'
 ECHR 'O'
 ECHR 'M'
 ECHR 'P'
 ECHR 'U'
 ECHR 'T'
 ETWO 'E', 'R'
 ECHR 'S'
 ECHR ' '
 ECHR 'W'
 ETWO 'I', 'L'
 ECHR 'L'
 ECHR ' '
 ECHR 'A'
 ECHR 'U'
 ECHR 'T'
 ECHR 'O'
 ETWO 'M', 'A'
 ETWO 'T', 'I'
 ECHR 'C'
 ETWO 'A', 'L'
 ECHR 'L'
 ECHR 'Y'
 ECHR ' '
 ECHR 'D'
 ECHR 'O'
 ECHR 'C'
 ECHR 'K'
 ETOK 208
 ETOK 207
 ECHR ' '
 ECHR 'W'
 ECHR 'H'
 ETWO 'E', 'N'
 ECHR ' '
 ECHR 'T'
 ECHR 'U'
 ECHR 'R'
 ECHR 'N'
 ETOK 196
 ETWO 'O', 'N'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ECHR 'D'
 ECHR 'O'
 ECHR 'C'
 ECHR 'K'
 ETOK 195
 ECHR 'C'
 ECHR 'O'
 ECHR 'M'
 ECHR 'P'
 ECHR 'U'
 ECHR 'T'
 ETWO 'E', 'R'
 ECHR 'S'
 ECHR ' '
 ECHR 'C'
 ETWO 'A', 'N'
 ECHR ' '
 ETWO 'B', 'E'
 ECHR ' '
 ECHR 'B'
 ETWO 'O', 'U'
 ECHR 'G'
 ECHR 'H'
 ECHR 'T'
 ECHR ' '
 ETWO 'A', 'T'
 ECHR ' '
 ECHR 'S'
 ECHR 'Y'
 ETWO 'S', 'T'
 ECHR 'E'
 ECHR 'M'
 ECHR 'S'
 ECHR ' '
 ECHR 'O'
 ECHR 'F'
 ECHR ' '
 ECHR 'T'
 ECHR 'E'
 ECHR 'C'
 ECHR 'H'
 ECHR ' '
 ETWO 'L', 'E'
 ETWO 'V', 'E'
 ECHR 'L'
 ECHR ' '
 ECHR '1'
 ECHR '0'
 ECHR ' '
 ETWO 'O', 'R'
 ECHR ' '
 ECHR 'M'
 ECHR 'O'
 ETWO 'R', 'E'
 ETOK 177
 EQUB VE

 EJMP 14                \ Token 118:    "{justify}{single cap}GALACTIC
 EJMP 19                \                HYPERSPACE DRIVES ARE OBTAINABLE FROM
 ECHR 'G'               \                PLANETS OF TECH LEVEL 11 UPWARDS.{crlf}
 ETWO 'A', 'L'          \                {single cap}WHEN THE INTERGALACTIC
 ECHR 'A'               \                HYPERDRIVE IS ENGAGED, THE SHIP IS
 ECHR 'C'               \                HYPERJUMPED INTO THE PRE-PROGRAMMED
 ETWO 'T', 'I'          \                GALAXY.{cr}
 ECHR 'C'               \                {left align}"
 ECHR ' '               \
 ECHR 'H'               \ Encoded as:   "{14}{19}G<228>AC<251>C HYP<244>SPA<233>
 ECHR 'Y'               \                 [151]S <238>E OBTA<240><216><229> FROM
 ECHR 'P'               \                 [145]S OF TECH <229><250>L 11 UPW<238>
 ETWO 'E', 'R'          \                DS.<215>{19}WH<246> [147]<240>T<244>G
 ECHR 'S'               \                <228>AC<251>C HYP<244>[151] IS <246>GA
 ECHR 'P'               \                <231>D, [147][207][202]HYP<244>JUMP
 ECHR 'A'               \                [196]<240>TO [147]P<242>-PROG<248>MM
 ETWO 'C', 'E'          \                [196]G<228>AXY[177]"
 ECHR ' '
 ETOK 151
 ECHR 'S'
 ECHR ' '
 ETWO 'A', 'R'
 ECHR 'E'
 ECHR ' '
 ECHR 'O'
 ECHR 'B'
 ECHR 'T'
 ECHR 'A'
 ETWO 'I', 'N'
 ETWO 'A', 'B'
 ETWO 'L', 'E'
 ECHR ' '
 ECHR 'F'
 ECHR 'R'
 ECHR 'O'
 ECHR 'M'
 ECHR ' '
 ETOK 145
 ECHR 'S'
 ECHR ' '
 ECHR 'O'
 ECHR 'F'
 ECHR ' '
 ECHR 'T'
 ECHR 'E'
 ECHR 'C'
 ECHR 'H'
 ECHR ' '
 ETWO 'L', 'E'
 ETWO 'V', 'E'
 ECHR 'L'
 ECHR ' '
 ECHR '1'
 ECHR '1'
 ECHR ' '
 ECHR 'U'
 ECHR 'P'
 ECHR 'W'
 ETWO 'A', 'R'
 ECHR 'D'
 ECHR 'S'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ECHR 'W'
 ECHR 'H'
 ETWO 'E', 'N'
 ECHR ' '
 ETOK 147
 ETWO 'I', 'N'
 ECHR 'T'
 ETWO 'E', 'R'
 ECHR 'G'
 ETWO 'A', 'L'
 ECHR 'A'
 ECHR 'C'
 ETWO 'T', 'I'
 ECHR 'C'
 ECHR ' '
 ECHR 'H'
 ECHR 'Y'
 ECHR 'P'
 ETWO 'E', 'R'
 ETOK 151
 ECHR ' '
 ECHR 'I'
 ECHR 'S'
 ECHR ' '
 ETWO 'E', 'N'
 ECHR 'G'
 ECHR 'A'
 ETWO 'G', 'E'
 ECHR 'D'
 ECHR ','
 ECHR ' '
 ETOK 147
 ETOK 207
 ETOK 202
 ECHR 'H'
 ECHR 'Y'
 ECHR 'P'
 ETWO 'E', 'R'
 ECHR 'J'
 ECHR 'U'
 ECHR 'M'
 ECHR 'P'
 ETOK 196
 ETWO 'I', 'N'
 ECHR 'T'
 ECHR 'O'
 ECHR ' '
 ETOK 147
 ECHR 'P'
 ETWO 'R', 'E'
 ECHR '-'
 ECHR 'P'
 ECHR 'R'
 ECHR 'O'
 ECHR 'G'
 ETWO 'R', 'A'
 ECHR 'M'
 ECHR 'M'
 ETOK 196
 ECHR 'G'
 ETWO 'A', 'L'
 ECHR 'A'
 ECHR 'X'
 ECHR 'Y'
 ETOK 177
 EQUB VE

 EJMP 14                \ Token 119:    "{justify}{single cap}MILITARY LASERS
 EJMP 19                \                ARE THE HEIGHT OF LASER SOPHISTICATION.
 ECHR 'M'               \                {crlf}
 ETWO 'I', 'L'          \                {single cap}THEY USE HIGH ENERGY LASERS
 ETWO 'I', 'T'          \                FIRING CONTINUOUSLY TO PRODUCE
 ETWO 'A', 'R'          \                DEVASTATING EFFECTS, BUT ARE PRONE TO
 ECHR 'Y'               \                OVERHEATING.{crlf}
 ECHR ' '               \                {single cap}MILITARY LASERS ARE
 ETWO 'L', 'A'          \                AVAILABLE FROM PLANETS OF TECH LEVEL 12
 ETWO 'S', 'E'          \                OR MORE.{cr}
 ECHR 'R'               \                {left align}"
 ECHR 'S'               \
 ECHR ' '               \ Encoded as:   "{14}{19}M<220><219><238>Y <249><218>RS
 ETWO 'A', 'R'          \                 <238>E [147]HEIGHT OF <249><218>R
 ECHR 'E'               \                 <235>PHI<222>IC<245>I<223>.<215>{19}
 ECHR ' '               \                <226>EY U<218> HIGH <246><244>GY <249>
 ETOK 147               \                <218>RS FIR[195]C<223><251><225><217>SL
 ECHR 'H'               \                Y[201]PRODU<233> DEVA<222><245>[195]EFF
 ECHR 'E'               \                ECTS, BUT <238>E PR<223>E[201]OV<244>HE
 ECHR 'I'               \                <245><240>G.<215>{19}M<220><219><238>Y
 ECHR 'G'               \                 <249><218>RS <238>E AVA<220><216><229>
 ECHR 'H'               \                 FROM [145]S OF TECH <229><250>L 12
 ECHR 'T'               \                 <253> MO<242>[177]"
 ECHR ' '
 ECHR 'O'
 ECHR 'F'
 ECHR ' '
 ETWO 'L', 'A'
 ETWO 'S', 'E'
 ECHR 'R'
 ECHR ' '
 ETWO 'S', 'O'
 ECHR 'P'
 ECHR 'H'
 ECHR 'I'
 ETWO 'S', 'T'
 ECHR 'I'
 ECHR 'C'
 ETWO 'A', 'T'
 ECHR 'I'
 ETWO 'O', 'N'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ETWO 'T', 'H'
 ECHR 'E'
 ECHR 'Y'
 ECHR ' '
 ECHR 'U'
 ETWO 'S', 'E'
 ECHR ' '
 ECHR 'H'
 ECHR 'I'
 ECHR 'G'
 ECHR 'H'
 ECHR ' '
 ETWO 'E', 'N'
 ETWO 'E', 'R'
 ECHR 'G'
 ECHR 'Y'
 ECHR ' '
 ETWO 'L', 'A'
 ETWO 'S', 'E'
 ECHR 'R'
 ECHR 'S'
 ECHR ' '
 ECHR 'F'
 ECHR 'I'
 ECHR 'R'
 ETOK 195
 ECHR 'C'
 ETWO 'O', 'N'
 ETWO 'T', 'I'
 ETWO 'N', 'U'
 ETWO 'O', 'U'
 ECHR 'S'
 ECHR 'L'
 ECHR 'Y'
 ETOK 201
 ECHR 'P'
 ECHR 'R'
 ECHR 'O'
 ECHR 'D'
 ECHR 'U'
 ETWO 'C', 'E'
 ECHR ' '
 ECHR 'D'
 ECHR 'E'
 ECHR 'V'
 ECHR 'A'
 ETWO 'S', 'T'
 ETWO 'A', 'T'
 ETOK 195
 ECHR 'E'
 ECHR 'F'
 ECHR 'F'
 ECHR 'E'
 ECHR 'C'
 ECHR 'T'
 ECHR 'S'
 ECHR ','
 ECHR ' '
 ECHR 'B'
 ECHR 'U'
 ECHR 'T'
 ECHR ' '
 ETWO 'A', 'R'
 ECHR 'E'
 ECHR ' '
 ECHR 'P'
 ECHR 'R'
 ETWO 'O', 'N'
 ECHR 'E'
 ETOK 201
 ECHR 'O'
 ECHR 'V'
 ETWO 'E', 'R'
 ECHR 'H'
 ECHR 'E'
 ETWO 'A', 'T'
 ETWO 'I', 'N'
 ECHR 'G'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ECHR 'M'
 ETWO 'I', 'L'
 ETWO 'I', 'T'
 ETWO 'A', 'R'
 ECHR 'Y'
 ECHR ' '
 ETWO 'L', 'A'
 ETWO 'S', 'E'
 ECHR 'R'
 ECHR 'S'
 ECHR ' '
 ETWO 'A', 'R'
 ECHR 'E'
 ECHR ' '
 ECHR 'A'
 ECHR 'V'
 ECHR 'A'
 ETWO 'I', 'L'
 ETWO 'A', 'B'
 ETWO 'L', 'E'
 ECHR ' '
 ECHR 'F'
 ECHR 'R'
 ECHR 'O'
 ECHR 'M'
 ECHR ' '
 ETOK 145
 ECHR 'S'
 ECHR ' '
 ECHR 'O'
 ECHR 'F'
 ECHR ' '
 ECHR 'T'
 ECHR 'E'
 ECHR 'C'
 ECHR 'H'
 ECHR ' '
 ETWO 'L', 'E'
 ETWO 'V', 'E'
 ECHR 'L'
 ECHR ' '
 ECHR '1'
 ECHR '2'
 ECHR ' '
 ETWO 'O', 'R'
 ECHR ' '
 ECHR 'M'
 ECHR 'O'
 ETWO 'R', 'E'
 ETOK 177
 EQUB VE

 EJMP 14                \ Token 120:    "{justify}{single cap}MINING LASERS ARE
 EJMP 19                \                HIGHLY POWERED, SLOW FIRING PULSE
 ECHR 'M'               \                LASERS WHICH ARE TUNED TO FRAGMENT
 ETWO 'I', 'N'          \                ASTEROIDS.{crlf}
 ETOK 195               \                {single cap}MINING LASERS ARE AVAILABLE
 ETWO 'L', 'A'          \                FROM TECH LEVEL 12 UPWARDS.{cr}
 ETWO 'S', 'E'          \                {left align}"
 ECHR 'R'               \
 ECHR 'S'               \ Encoded as:   "{14}{19}M<240>[195]<249><218>RS <238>E
 ECHR ' '               \                 HIGHLY POWE<242>D, S<224>W FIR[195]PUL
 ETWO 'A', 'R'          \                <218> <249><218>RS WHICH <238>E TUN
 ECHR 'E'               \                [196]TO F<248>GM<246>T A<222><244>OIDS.
 ECHR ' '               \                <215>{19}M<240>[195]<249><218>RS <238>E
 ECHR 'H'               \                 AVA<220><216><229> FROM TECH <229>
 ECHR 'I'               \                <250>L 12 UPW<238>DS[177]"
 ECHR 'G'
 ECHR 'H'
 ECHR 'L'
 ECHR 'Y'
 ECHR ' '
 ECHR 'P'
 ECHR 'O'
 ECHR 'W'
 ECHR 'E'
 ETWO 'R', 'E'
 ECHR 'D'
 ECHR ','
 ECHR ' '
 ECHR 'S'
 ETWO 'L', 'O'
 ECHR 'W'
 ECHR ' '
 ECHR 'F'
 ECHR 'I'
 ECHR 'R'
 ETOK 195
 ECHR 'P'
 ECHR 'U'
 ECHR 'L'
 ETWO 'S', 'E'
 ECHR ' '
 ETWO 'L', 'A'
 ETWO 'S', 'E'
 ECHR 'R'
 ECHR 'S'
 ECHR ' '
 ECHR 'W'
 ECHR 'H'
 ECHR 'I'
 ECHR 'C'
 ECHR 'H'
 ECHR ' '
 ETWO 'A', 'R'
 ECHR 'E'
 ECHR ' '
 ECHR 'T'
 ECHR 'U'
 ECHR 'N'
 ETOK 196
 ECHR 'T'
 ECHR 'O'
 ECHR ' '
 ECHR 'F'
 ETWO 'R', 'A'
 ECHR 'G'
 ECHR 'M'
 ETWO 'E', 'N'
 ECHR 'T'
 ECHR ' '
 ECHR 'A'
 ETWO 'S', 'T'
 ETWO 'E', 'R'
 ECHR 'O'
 ECHR 'I'
 ECHR 'D'
 ECHR 'S'
 ECHR '.'
 ETWO '-', '-'
 EJMP 19
 ECHR 'M'
 ETWO 'I', 'N'
 ETOK 195
 ETWO 'L', 'A'
 ETWO 'S', 'E'
 ECHR 'R'
 ECHR 'S'
 ECHR ' '
 ETWO 'A', 'R'
 ECHR 'E'
 ECHR ' '
 ECHR 'A'
 ECHR 'V'
 ECHR 'A'
 ETWO 'I', 'L'
 ETWO 'A', 'B'
 ETWO 'L', 'E'
 ECHR ' '
 ECHR 'F'
 ECHR 'R'
 ECHR 'O'
 ECHR 'M'
 ECHR ' '
 ECHR 'T'
 ECHR 'E'
 ECHR 'C'
 ECHR 'H'
 ECHR ' '
 ETWO 'L', 'E'
 ETWO 'V', 'E'
 ECHR 'L'
 ECHR ' '
 ECHR '1'
 ECHR '2'
 ECHR ' '
 ECHR 'U'
 ECHR 'P'
 ECHR 'W'
 ETWO 'A', 'R'
 ECHR 'D'
 ECHR 'S'
 ETOK 177
 EQUB VE

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: MTIN
\       Type: Variable
\   Category: Text
\    Summary: Lookup table for random tokens in the extended token table (0-37)
\  Deep dive: Extended text tokens
\
\ ------------------------------------------------------------------------------
\
\ The ERND token type, which is part of the extended token system, takes an
\ argument between 0 and 37, and returns a randomly chosen token in the range
\ specified in this table. This is used to generate the extended description of
\ each system.
\
\ For example, the entry at position 13 in this table (counting from 0) is 66,
\ so ERND 14 will expand into a random token in the range 66-70, i.e. one of
\ "JUICE", "BRANDY", "WATER", "BREW" and "GARGLE BLASTERS".
\
\ ******************************************************************************

.MTIN

 EQUB 16                \ Token  0: a random extended token between 16 and 20
 EQUB 21                \ Token  1: a random extended token between 21 and 25
 EQUB 26                \ Token  2: a random extended token between 26 and 30
 EQUB 31                \ Token  3: a random extended token between 31 and 35
 EQUB 155               \ Token  4: a random extended token between 155 and 159
 EQUB 160               \ Token  5: a random extended token between 160 and 164
 EQUB 46                \ Token  6: a random extended token between 46 and 50
 EQUB 165               \ Token  7: a random extended token between 165 and 169
 EQUB 36                \ Token  8: a random extended token between 36 and 40
 EQUB 41                \ Token  9: a random extended token between 41 and 45
 EQUB 61                \ Token 10: a random extended token between 61 and 65
 EQUB 51                \ Token 11: a random extended token between 51 and 55
 EQUB 56                \ Token 12: a random extended token between 56 and 60
 EQUB 170               \ Token 13: a random extended token between 170 and 174
 EQUB 66                \ Token 14: a random extended token between 66 and 70
 EQUB 71                \ Token 15: a random extended token between 71 and 75
 EQUB 76                \ Token 16: a random extended token between 76 and 80
 EQUB 81                \ Token 17: a random extended token between 81 and 85
 EQUB 86                \ Token 18: a random extended token between 86 and 90
 EQUB 140               \ Token 19: a random extended token between 140 and 144
 EQUB 96                \ Token 20: a random extended token between 96 and 100
 EQUB 101               \ Token 21: a random extended token between 101 and 105
 EQUB 135               \ Token 22: a random extended token between 135 and 139
 EQUB 130               \ Token 23: a random extended token between 130 and 134
 EQUB 91                \ Token 24: a random extended token between 91 and 95
 EQUB 106               \ Token 25: a random extended token between 106 and 110
 EQUB 180               \ Token 26: a random extended token between 180 and 184
 EQUB 185               \ Token 27: a random extended token between 185 and 189
 EQUB 190               \ Token 28: a random extended token between 190 and 194
 EQUB 225               \ Token 29: a random extended token between 225 and 229
 EQUB 230               \ Token 30: a random extended token between 230 and 234
 EQUB 235               \ Token 31: a random extended token between 235 and 239
 EQUB 240               \ Token 32: a random extended token between 240 and 244
 EQUB 245               \ Token 33: a random extended token between 245 and 249
 EQUB 250               \ Token 34: a random extended token between 250 and 254
 EQUB 115               \ Token 35: a random extended token between 115 and 119
 EQUB 120               \ Token 36: a random extended token between 120 and 124
 EQUB 125               \ Token 37: a random extended token between 125 and 129

\ ******************************************************************************
\
\       Name: ship_centre
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.ship_centre

 EQUB &0D, &0C, &0C, &0B, &0D, &0C, &0B
 EQUB &0B, &08, &07, &09, &0A, &0D, &0C
 EQUB &0D, &0D, &0D, &0C, &0D, &0C, &0D
 EQUB &0C, &0B, &0C, &0C, &0A, &0D, &0E

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: card_pattern
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.card_pattern

 EQUB  1,  3, &25       \ inservice date
 EQUB  1,  4, &00
 EQUB 24,  6, &26       \ combat factor
 EQUB 24,  7, &2F
 EQUB 24,  8, &41
 EQUB 26,  8, &00
 EQUB  1,  6, &2B       \ dimensions
 EQUB  1,  7, &00
 EQUB  1,  9, &24       \ speed
 EQUB  1, 10, &00
 EQUB 24, 10, &27       \ crew
 EQUB 24, 11, &00
 EQUB 24, 13, &29       \ range
 EQUB 24, 14, &00
 EQUB  1, 12, &3D       \ cargo space
 EQUB  1, 13, &2D
 EQUB  1, 14, &00
 EQUB  1, 16, &23       \ armaments
 EQUB  1, 17, &00
 EQUB 23, 20, &2C       \ hull
 EQUB 23, 21, &00
 EQUB  1, 20, &28       \ drive motors
 EQUB  1, 21, &00
 EQUB  1, 20, &2D       \ space
 EQUB  1, 21, &00

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: card_addr
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.card_addr

 EQUW adder, anaconda, asp_2, boa, bushmaster, chameleon, cobra_1
 EQUW cobra_3, coriolis, dodecagon, escape_pod
 EQUW fer_de_lance, gecko, ghavial
 EQUW iguana, krait, mamba, monitor, moray, ophidian, python
 EQUW shuttle, sidewinder, thargoid, thargon
 EQUW transporter, viper, worm

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: adder
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.adder

 EQUB 1
 EQUS "2914", &D5, &C5, &D1
 EQUB 0, 2
 EQUS "6"
 EQUB 0, 3
 EQUS "45/8/30", &AA
 EQUB 0, 4
 EQUS "0.24", &C0
 EQUB 0, 5
 EQUS "1"
 EQUB 0, 6
 EQUS "6", &BF
 EQUB 0, 7
 EQUS "4", &BE
 EQUB 0, 8
 EQUS &B8, " 1928 AZ ", &F7, "am", &B1, &0C, &B0, &AE
 EQUB 0, 9
 EQUS "D4-18", &D3
 EQUB 0, 10
 EQUS "AM 18 ", &EA, " ", &C2
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: anaconda
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.anaconda

 EQUB 1
 EQUS "2856", &D5, "Riml", &F0, &F4, " G", &E4, "ac", &FB, "c)"
 EQUB 0, 2
 EQUS "3"
 EQUB 0, 3
 EQUS "170/60/75", &AA
 EQUB 0, 4
 EQUS "0.14", &C0
 EQUB 0, 5
 EQUS "2-10"
 EQUB 0, 6
 EQUS "10", &BF
 EQUB 0, 7
 EQUS "245", &BE
 EQUB 0, 8
 EQUS &BB, " Hi-", &F8, "d", &B2, &B1, &0C, &B0, &AE
 EQUB 0, 9
 EQUS "M8-**", &D4
 EQUB 0, 10
 EQUS &C9, "32.24", &0C, &F4, "g", &EF, &DE, &F4, "s"
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: asp_2
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.asp_2

 EQUB 1
 EQUS "2878", &D5, "G", &E4, "cop", &D1
 EQUB 0, 2
 EQUS "6"
 EQUB 0, 3
 EQUS "70/20/65", &AA
 EQUB 0, 4
 EQUS "0.40", &C0
 EQUB 0, 5
 EQUS "1"
 EQUB 0, 6
 EQUS "12.5", &BF
 EQUB 0, 7
 EQUS "0", &BE
 EQUB 0, 8
 EQUS &BB, "-", &BA, "Bur", &DE, &B1, &0C, &B0, &AE
 EQUB 0, 9
 EQUS "J6-31", &D2
 EQUB 0, 10
 EQUS &BC, " Whip", &F9, "sh", &0C, &01, "HK", &02, " ", &B2, &B5
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: boa
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.boa

 EQUB 1
 EQUS "3017", &D5, &E7, &F2, &E7, " ", &CC, ")"
 EQUB 0, 2
 EQUS "4"
 EQUB 0, 3
 EQUS "115/60/65", &AA
 EQUB 0, 4
 EQUS "0.24", &C0
 EQUB 0, 5
 EQUS "2-6"
 EQUB 0, 6
 EQUS "9", &BF
 EQUB 0, 7
 EQUS "125", &BE
 EQUB 0, 8
 EQUS &B4, &B1, &B3, &0C, &D6, &B6, " & ", &CF, &AE
 EQUB 0, 9
 EQUS "J7-24", &D3
 EQUB 0, 10
 EQUS &C8, &0C, &B6, &B7, " ", &C2, &F4, "s"
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: bushmaster
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.bushmaster

 EQUB 1
 EQUS "3001", &D5, &DF, "ri", &F8, " ", &FD, "b", &DB, &E4, ")"
 EQUB 0, 2
 EQUS "8"
 EQUB 0, 3
 EQUS "50/20/50", &AA
 EQUB 0, 4
 EQUS "0.35", &C0
 EQUB 0, 5
 EQUS "1-2"
 EQUB 0, 8
 EQUS "Du", &E4, " 22-18", &B1, &0C, &B0, &AE
 \EQUB 0, 9
 \EQUA "3|!R"
 EQUB 0, 10
 EQUS &BC, " Whip", &F9, "sh", &0C, &01, "HT", &02, " ", &B2, &B5
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: chameleon
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.chameleon

 EQUB 1
 EQUS "3122", &D5, &EE, "d", &F6, " Co-op", &F4, "a", &FB, &FA, ")"
 EQUB 0, 2
 EQUS "6"
 EQUB 0, 3
 EQUS "75/24/40", &AA
 EQUB 0, 4
 EQUS "0.29", &C0
 EQUB 0, 5
 EQUS "1-4"
 EQUB 0, 6
 EQUS "8", &BF
 EQUB 0, 7
 EQUS "30", &BE
 EQUB 0, 8
 EQUS &B8, " Mega", &CA, &B2, &B1, &0C, &B6, &F4, " X3", &AE
 EQUB 0, 9
 EQUS "H5-23", &D3
 EQUB 0, 10
 EQUS &BC, " ", &DE, &F0, "g", &F4, &0C, "Pul", &DA, &B5
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: cobra_1
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.cobra_1

 EQUB 1
 EQUS "2855", &D5, "Payn", &D9, ", ", &D0, "& S", &E4, "em)"
 EQUB 0, 2
 EQUS "5"
 EQUB 0, 3
 EQUS "55/15/70", &AA
 EQUB 0, 4
 EQUS "0.26", &C0
 EQUB 0, 5
 EQUS "1"
 EQUB 0, 6
 EQUS "6", &BF
 EQUB 0, 7
 EQUS "10", &BE
 EQUB 0, 8
 EQUS &BB, " V", &EE, "isc", &FF, &B1, &0C, &B9, &AE
 EQUB 0, 9
 EQUS "E4-20", &D4
 EQUB 0, 10
 EQUS &D0, &B5
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: cobra_3
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.cobra_3

 EQUB 1
 EQUS "3100", &D5, "Cowell & Mg", &13, &F8, &E2, ", ", &F9, &FA, ")"
 EQUB 0, 2
 EQUS "7"
 EQUB 0, 3
 EQUS "65/30/130", &AA
 EQUB 0, 4
 EQUS "0.28", &C0
 EQUB 0, 5
 EQUS "1-3"
 EQUB 0, 6
 EQUS "7", &BF
 EQUB 0, 7
 EQUS "35", &BE
 EQUB 0, 8
 EQUS &B8, &B1, &B3, &0C, &B9, &AE
 EQUB 0, 9
 EQUS "G7-24", &D4
 EQUB 0, 10
 EQUS &BA, &B7, "fa", &DE, &0C, "Irrik", &FF, " Thru", &CD
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: coriolis
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.coriolis

 EQUB 1
 EQUS "2752", &CB
 EQUB 0, 3
 EQUS "1/1/1km"
 EQUB 0, 11
 EQUS "2000", &C3, "s"
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: dodecagon
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.dodecagon

 EQUB 1
 EQUS "3152", &CB
 EQUB 0, 3
 EQUS "1/1/1km"
 EQUB 0, 11
 EQUS "2700", &C3, "s"
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: escape_pod
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.escape_pod

 EQUB 1
 EQUS "p", &F2, "-2500"
 EQUB 0, 3
 EQUS "10/5/5", &AA
 EQUB 0, 4
 EQUS "0.08", &C0
 EQUB 0, 5
 EQUS "1-2"
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: fer_de_lance
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.fer_de_lance

 EQUB 1
 EQUS "3100", &D5, &C6
 EQUB 0, 2
 EQUS "6"
 EQUB 0, 3
 EQUS "85/20/45", &AA
 EQUB 0, 4
 EQUS "0.30", &C0
 EQUB 0, 5
 EQUS "1-3"
 EQUB 0, 6
 EQUS "8.5", &BF
 EQUB 0, 7
 EQUS "2", &BE
 EQUB 0, 8
 EQUS &B4, &B1, &B3, &0C, &D6, &B6, " & ", &CF, &AE
 EQUB 0, 9
 EQUS "H7-28", &D4
 EQUB 0, 10
 EQUS "T", &DB, "r", &DF, "ix ", &F0, "t", &F4, "sun", &0C, &01, "LT", &02, " ", &CE
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: gecko
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.gecko

 EQUB 1
 EQUS "2852", &D5, "A", &E9, " & F", &D8, &F4, ", ", &E5, &F2, &F9, &E9, ")"
 EQUB 0, 2
 EQUS "7"
 EQUB 0, 3
 EQUS "40/12/65", &AA
 EQUB 0, 4
 EQUS "0.30", &C0
 EQUB 0, 5
 EQUS "1-2"
 EQUB 0, 6
 EQUS "7", &BF
 EQUB 0, 7
 EQUS "3", &BE
 EQUB 0, 8
 EQUS &B8, " 1919 A4", &B1, &0C, &C0, " Hom", &F0, "g", &AE
 EQUB 0, 9
 EQUS "E6-19", &D3
 EQUB 0, 10
 EQUS "B", &F2, "am", &B2, &B7, " ", &01, "XL", &02
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: ghavial
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.ghavial

 EQUB 1
 EQUS "3077", &D5, &EE, "d", &F6, " Co-op", &F4, "a", &FB, &FA, ")"
 EQUB 0, 2
 EQUS "5"
 EQUB 0, 3
 EQUS "80/30/60", &AA
 EQUB 0, 4
 EQUS "0.25", &C0
 EQUB 0, 5
 EQUS "2-7"
 EQUB 0, 6
 EQUS "8", &BF
 EQUB 0, 7
 EQUS "50", &BE
 EQUB 0, 8
 EQUS "Fai", &F2, "y", &B2, &B1, &0C, &B9, &AE
 EQUB 0, 9
 EQUS "I5-25", &D4
 EQUB 0, 10
 EQUS "Sp", &E4, "d", &F4, " & Prime ", &01, "TT1", &02
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: iguana
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.iguana

 EQUB 1
 EQUS "3095", &D5, "Faulc", &DF, " ", &EF, "n", &CD, ")"
 EQUB 0, 2
 EQUS "6"
 EQUB 0, 3
 EQUS "65/20/40", &AA
 EQUB 0, 4
 EQUS "0.33", &C0
 EQUB 0, 5
 EQUS "1-3"
 EQUB 0, 6
 EQUS "7.5", &BF
 EQUB 0, 7
 EQUS "15", &BE
 EQUB 0, 8
 EQUS &B9, &B1, &0C, &B6, &F4, " X1", &AE
 EQUB 0, 9
 EQUS "G6-20", &D4
 EQUB 0, 10
 EQUS &C7, " Sup", &F4, " ", &C2, &0C, &01, "VC", &02, "9"
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: krait
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.krait

 EQUB 1
 EQUS "3027", &D5, &C7, &C3, "W", &FD, "ks, ", &F0, &F0, &ED, ")"
 EQUB 0, 2
 EQUS "7"
 EQUB 0, 3
 EQUS "80/20/90", &AA
 EQUB 0, 4
 EQUS "0.30", &C0
 EQUB 0, 5
 EQUS "1"
 EQUB 0, 7
 EQUS "10", &BE
 EQUB 0, 8
 EQUS &B4, &B1, &B3
 \EQUB 0, 9
 \EQUA "8|!S"
 EQUB 0, 10
 EQUS &C7, " Sp", &F0, &CE, " ZX14"
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: mamba
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.mamba

 EQUB 1
 EQUS "3110", &D5, &F2, &FD, "te", &C3, " ", &CC, ")"
 EQUB 0, 2
 EQUS "8"
 EQUB 0, 3
 EQUS "55/12/65", &AA
 EQUB 0, 4
 EQUS "0.30", &C0
 EQUB 0, 5
 EQUS "1-2"
 EQUB 0, 7
 EQUS "10", &BE
 EQUB 0, 8
 EQUS &B4, &B1, &B3, &0C, &D6, &B6, " & ", &CF, &AE
 \EQUB 0, 9
 \EQUA "7|!R"
 EQUB 0, 10
 EQUS &B6, &B7, " ", &01, "HV", &02, " ", &C2
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: monitor
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.monitor

 EQUB 1
 EQUS "3112", &D5, &C6
 EQUB 0, 2
 EQUS "4"
 EQUB 0, 3
 EQUS "100/40/50", &AA
 EQUB 0, 4
 EQUS "0.16", &C0
 EQUB 0, 5
 EQUS "7-19"
 EQUB 0, 6
 EQUS "11", &BF
 EQUB 0, 7
 EQUS "75", &BE
 EQUB 0, 8
 EQUS &BA, &01, "HMB", &02, &B1, &0C, &B0, &AE
 EQUB 0, 9
 EQUS "J6-28", &D4
 EQUB 0, 10
 EQUS &C9, "29.01", &0C, &B7, " ", &CA, &F4, "s"
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: moray
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.moray

 EQUB 1
 EQUS "3028", &D5, "M", &EE, &F0, "e T", &F2, "nch Co.)"
 EQUB 0, 2
 EQUS "7"
 EQUB 0, 3
 EQUS "60/25/60", &AA
 EQUB 0, 4
 EQUS "0.25", &C0
 EQUB 0, 5
 EQUS "1-4"
 EQUB 0, 6
 EQUS "8", &BF
 EQUB 0, 7
 EQUS "7", &BE
 EQUB 0, 8
 EQUS &B8, &B1, &B3, &0C, &B0, &AE
 EQUB 0, 9
 EQUS "F4-22", &D4
 EQUB 0, 10
 EQUS "Turbul", &F6, " ", &FE, &EE, "k", &0C, &F2, "-ch", &EE, "g", &F4, " 1287"
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: ophidian
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.ophidian

 EQUB 1
 EQUS "2981", &D5, &C5, &D1
 EQUB 0, 2
 EQUS "8"
 EQUB 0, 3
 EQUS "65/15/30", &AA
 EQUB 0, 4
 EQUS "0.34", &C0
 EQUB 0, 5
 EQUS "1-3"
 EQUB 0, 6
 EQUS "7", &BF
 EQUB 0, 7
 EQUS "20", &BE
 EQUB 0, 8
 EQUS &B9, &B1, &0C, &B6, &F4, " X1", &AE
 EQUB 0, 9
 EQUS "D4-16", &D2
 EQUB 0, 10
 EQUS &BC, " ", &DE, &F0, "g", &F4, &0C, "Pul", &DA, &B5
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: python
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.python

 EQUB 1
 EQUS "2700", &D5, "Wh", &F5, "t & Pr", &DB, "ney SC)"
 EQUB 0, 2
 EQUS "3"
 EQUB 0, 3
 EQUS "130/40/80", &AA
 EQUB 0, 4
 EQUS "0.20", &C0
 EQUB 0, 5
 EQUS "2-9"
 EQUB 0, 6
 EQUS "8", &BF
 EQUB 0, 7
 EQUS "100", &BE
 EQUB 0, 8
 EQUS "Volt-", &13, "V", &EE, "isc", &FF, &B2, &B1
 EQUB 0, 9
 EQUS "K6-27", &D4
 EQUB 0, 10
 EQUS &C8, &0C, "Exl", &DF, " 76NN Model"
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: shuttle
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.shuttle

 EQUB 1
 EQUS "2856", &D5, "Saud-", &BA, "A", &DE, "ro)"
 EQUB 0, 2
 EQUS "4"
 EQUB 0, 3
 EQUS "35/20/20", &AA
 EQUB 0, 4
 EQUS "0.08", &C0
 EQUB 0, 5
 EQUS "2"
 EQUB 0, 7
 EQUS "60", &BE
 EQUB 0, 10
 EQUS &C9, "20.20", &0C, &DE, &EE, &EF, "t ", &B5
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: sidewinder
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.sidewinder

 EQUB 1
 EQUS "2982", &D5, &DF, "ri", &F8, " ", &FD, "b", &DB, &E4, ")"
 EQUB 0, 2
 EQUS "9"
 EQUB 0, 3
 EQUS "35/15/65", &AA
 EQUB 0, 4
 EQUS "0.37", &C0
 EQUB 0, 5
 EQUS "1"
 EQUB 0, 8
 EQUS "Du", &E4, " 22-18", &B1
 \EQUB 0, 9
 \EQUA "3|!R"
 EQUB 0, 10
 EQUS &C7, " Sp", &F0, &CE, " ", &01, "MV", &02
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: thargoid
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.thargoid

 EQUB 2
 EQUS "6"
 EQUB 0, 3
 EQUS "180/40/180", &AA
 EQUB 0, 4
 EQUS "0.39", &C0
 EQUB 0, 5
 EQUS "50"
 EQUB 0, 6
 EQUS "Unk", &E3, "wn"
 EQUB 0, 8
 EQUS "Widely v", &EE, "y", &F0, "g"
 \EQUB 0, 9
 \EQUA "Unk|!cwn"
 EQUB 0, 10
 EQUS &9E, " ", &C4
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: thargon
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.thargon

 EQUB 2
 EQUS "6"
 EQUB 0, 3
 EQUS "40/10/35", &AA
 EQUB 0, 4
 EQUS "0.30", &C0
 EQUB 0, 5
 EQUS &E3, "ne"
 EQUB 0, 8
 EQUS &9E, &B1
 \EQUB 0, 9
 \EQUA "|!cne"
 EQUB 0, 10
 EQUS &9E, " ", &C4
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: transporter
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.transporter

 EQUB 1
 EQUS "p", &F2, "-2500", &D5, &CD, "L", &F0, "k", &C3, "y", &EE, "ds)"
 EQUB 0, 3
 EQUS "35/10/30", &AA
 EQUB 0, 4
 EQUS "0.10", &C0
 EQUB 0, 5
 EQUS "5"
 EQUB 0, 7
 EQUS "10", &BE
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: viper
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.viper

 EQUB 1
 EQUS "2762", &D5, "Faulc", &DF, " ", &EF, "n", &CD, ")"
 EQUB 0, 2
 EQUS "7"
 EQUB 0, 3
 EQUS "55/20/50", &AA
 EQUB 0, 4
 EQUS "0.32", &C0
 EQUB 0, 5
 EQUS "1-10"
 EQUB 0, 8
 EQUS &B8, " Mega", &CA, &B2, &B1, &0C, &B6, &F4, " X3", &AE
 \EQUB 0, 9
 \EQUA "9|!R"
 EQUB 0, 10
 EQUS &C7, " Sup", &F4, " ", &C2, &0C, &01, "VC", &02, "10"
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\       Name: worm
\       Type: Variable
\   Category: Encyclopedia
\    Summary: AJD
\
\ ******************************************************************************

                        \ --- Whole section added for Elite-A: ---------------->

.worm

 EQUB 1
 EQUS "3101"
 EQUB 0, 2
 EQUS "6"
 EQUB 0, 3
 EQUS "35/12/35", &AA
 EQUB 0, 4
 EQUS "0.23", &C0
 EQUB 0, 5
 EQUS "1"
 EQUB 0, 8
 EQUS &B8, &B2, &B1
 \EQUB 0, 9
 \EQUA "3|!R"
 EQUB 0, 10
 EQUS &B6, &B7, " ", &01, "HV", &02, " ", &C2
 EQUB 0, 0

                        \ --- End of added section ---------------------------->

\ ******************************************************************************
\
\ Save output/1.E.bin
\
\ ******************************************************************************

PRINT "S.1.E ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD%
SAVE "output/1.E.bin", CODE%, P%, LOAD%