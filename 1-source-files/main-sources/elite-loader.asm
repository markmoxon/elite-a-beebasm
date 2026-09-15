\ ******************************************************************************
\
\ ELITE-A GAME LOADER SOURCE
\
\ Elite-A is an extended version of BBC Micro Elite by Angus Duggan
\
\ The original Elite was written by Ian Bell and David Braben and is copyright
\ Acornsoft 1984, and the extra code in Elite-A is copyright Angus Duggan
\
\ The code in this file is identical to Angus Duggan's source discs (it's just
\ been reformatted, and the label names have been changed to be consistent with
\ the sources for the original BBC Micro disc version on which it is based)
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology and notations used in this commentary are explained at
\ https://elite.bbcelite.com/terminology
\
\ The deep dive articles referred to in this commentary can be found at
\ https://elite.bbcelite.com/deep_dives
\
\ ------------------------------------------------------------------------------
\
\ This source file contains the loader for Elite-A.
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * ELITE.bin
\
\ after reading in the following files:
\
\   * P.A-SOFT.bin
\   * P.(C)ASFT.bin
\   * P.DIALS.bin
\   * P.ELITE.bin
\   * MISSILE.bin
\   * WORDS.bin
\
\ ******************************************************************************

 INCLUDE "1-source-files/main-sources/elite-build-options.asm"

 _RELEASED              = (_VARIANT = 1)
 _SOURCE_DISC           = (_VARIANT = 2)
 _BUG_FIX               = (_VARIANT = 3)

 GUARD &6000            \ Guard against assembling over screen memory

\ ******************************************************************************
\
\ Configuration variables
\
\ ******************************************************************************

 CODE% = &1900          \ The address where the code will be run

 LOAD% = &1900          \ The address where the code will be loaded

 Q% = _MAX_COMMANDER    \ Set Q% to TRUE to max out the default commander, FALSE
                        \ for the standard default commander

 N% = 67                \ N% is set to the number of bytes in the VDU table, so
                        \ we can loop through them in part 1 below

 VSCAN = 57             \ Defines the split position in the split-screen mode

 BRKV = &0202           \ The break vector that we intercept to enable us to
                        \ handle and display system errors

 IRQ1V = &0204          \ The IRQ1V vector that we intercept to implement the
                        \ split-screen mode

 WRCHV = &020E          \ The WRCHV vector that we intercept with our custom
                        \ text printing routine

 BYTEV = &020A          \ The BYTEV vector that we intercept on the BBC Master

 FILEV = &0212          \ The FILEV vector that we intercept on the BBC Master

 FSCV = &021E           \ The FSCV vector that we intercept on the BBC Master

 NETV = &0224           \ The NETV vector that we intercept as part of the copy
                        \ protection

 LASCT = &0346          \ The laser pulse count for the current laser, matching
                        \ the address in the main game code

 HFX = &0348            \ A flag that toggles the hyperspace colour effect,
                        \ matching the address in the main game code

 CRGO = &036E           \ The flag that determines whether we have an I.F.F.
                        \ system fitted, matching the address in the main game
                        \ code

 ESCP = &0386           \ The flag that determines whether we have an escape pod
                        \ fitted, matching the address in the main game code

 S% = &11E3             \ The address of the main entry point workspace in the
                        \ main game code

 VIA = &FE00            \ Memory-mapped space for accessing internal hardware,
                        \ such as the video ULA, 6845 CRTC and 6522 VIAs (also
                        \ known as SHEILA)

 OSWRCH = &FFEE         \ The address for the OSWRCH routine

 OSBYTE = &FFF4         \ The address for the OSBYTE routine

 OSWORD = &FFF1         \ The address for the OSWORD routine

 OSCLI = &FFF7          \ The address for the OSCLI vector

 VEC = &7FFE            \ VEC is where we store the original value of the IRQ1
                        \ vector, matching the address in the elite-missile.asm
                        \ source

\ ******************************************************************************
\
\       Name: ZP
\       Type: Workspace
\    Address: &0070 to &008C
\   Category: Workspaces
\    Summary: Important variables used by the loader
\
\ ******************************************************************************

 ORG &0004              \ Set the assembly address to &0004

.TRTB%

 SKIP 2                 \ Contains the address of the keyboard translation
                        \ table, which is used to translate internal key
                        \ numbers to ASCII

 ORG &0020              \ Set the assembly address to &0020

.INF

 SKIP 2                 \ Temporary storage, typically used for storing the
                        \ address of a ship's data block, so it can be copied
                        \ to and from the internal workspace at INWK

 ORG &0070              \ Set the assembly address to &0070

.ZP

 SKIP 2                 \ Stores addresses used for moving content around

.P

 SKIP 1                 \ Temporary storage, used in a number of places

.Q

 SKIP 1                 \ Temporary storage, used in a number of places

.YY

 SKIP 1                 \ Temporary storage, used in a number of places

.T

 SKIP 1                 \ Temporary storage, used in a number of places

.SC

 SKIP 1                 \ Screen address (low byte)
                        \
                        \ Elite draws on-screen by poking bytes directly into
                        \ screen memory, and SC(1 0) is typically set to the
                        \ address of the character block containing the pixel
                        \ we want to draw

.SCH

 SKIP 1                 \ Screen address (high byte)

.CHKSM

 SKIP 2                 \ Used in the copy protection code

 ORG &008B              \ Set the assembly address to &008B

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

 ORG &0090              \ Set the assembly address to &0090

.key_tube

 SKIP 2                 \ Contains the address of the I/O processor's keyboard
                        \ translation table (as opposed to the parasite's
                        \ table), which is used to translate internal key
                        \ numbers to ASCII in the I/O processor code

 ORG &00F4              \ Set the assembly address to &00F4

.LATCH

 SKIP 2                 \ The RAM copy of the currently selected paged ROM/RAM
                        \ in SHEILA &30

\ ******************************************************************************
\
\ ELITE LOADER
\
\ ******************************************************************************

 ORG CODE%              \ Set the assembly address to CODE%

\ ******************************************************************************
\
\       Name: B%
\       Type: Variable
\   Category: Drawing the screen
\    Summary: VDU commands for setting the square mode 4 screen
\  Deep dive: The split-screen mode in BBC Micro Elite
\             Drawing monochrome pixels on the BBC Micro
\
\ ------------------------------------------------------------------------------
\
\ This block contains the bytes that get written by OSWRCH to set up the screen
\ mode (this is equivalent to using the VDU statement in BASIC).
\
\ It defines the whole screen using a square, monochrome mode 4 configuration;
\ the mode 5 part for the dashboard is implemented in the IRQ1 routine.
\
\ The top part of Elite's screen mode is based on mode 4 but with the following
\ differences:
\
\   * 32 columns, 31 rows (256 x 248 pixels) rather than 40, 32
\
\   * The horizontal sync position is at character 45 rather than 49, which
\     pushes the screen to the right (which centres it as it's not as wide as
\     the normal screen modes)
\
\   * Screen memory goes from &6000 to &7EFF, which leaves another whole page
\     for code (i.e. 256 bytes) after the end of the screen. This is where the
\     Python ship blueprint slots in
\
\   * The text window is 1 row high and 13 columns wide, and is at (2, 16)
\
\   * The cursor is disabled
\
\ This almost-square mode 4 variant makes life a lot easier when drawing to the
\ screen, as there are 256 pixels on each row (or, to put it in screen memory
\ terms, there's one page of memory per row of pixels).
\
\ There is also an interrupt-driven routine that switches the bytes-per-pixel
\ setting from that of mode 4 to that of mode 5, when the raster reaches the
\ split between the space view and the dashboard.
\
\ ******************************************************************************

.B%

 EQUB 22, 4             \ Switch to screen mode 4

 EQUB 28                \ Define a text window as follows:
 EQUB 2, 17, 15, 16     \
                        \   * Left = 2
                        \   * Right = 15
                        \   * Top = 16
                        \   * Bottom = 17
                        \
                        \ i.e. 1 row high, 13 columns wide at (2, 16)

 EQUB 23, 0, 6, 31      \ Set 6845 register R6 = 31
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "vertical displayed" register, and sets
                        \ the number of displayed character rows to 31. For
                        \ comparison, this value is 32 for standard modes 4 and
                        \ 5, but we claw back the last row for storing code just
                        \ above the end of screen memory

 EQUB 23, 0, 12, &0C    \ Set 6845 register R12 = &0C and R13 = &00
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This sets 6845 registers (R12 R13) = &0C00 to point
 EQUB 23, 0, 13, &00    \ to the start of screen memory in terms of character
 EQUB 0, 0, 0           \ rows. There are 8 pixel lines in each character row,
 EQUB 0, 0, 0           \ so to get the actual address of the start of screen
                        \ memory, we multiply by 8:
                        \
                        \   &0C00 * 8 = &6000
                        \
                        \ So this sets the start of screen memory to &6000

 EQUB 23, 0, 1, 32      \ Set 6845 register R1 = 32
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "horizontal displayed" register, which
                        \ defines the number of character blocks per horizontal
                        \ character row. For comparison, this value is 40 for
                        \ modes 4 and 5, but our custom screen is not as wide at
                        \ only 32 character blocks across

 EQUB 23, 0, 2, 45      \ Set 6845 register R2 = 45
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "horizontal sync position" register, which
                        \ defines the position of the horizontal sync pulse on
                        \ the horizontal line in terms of character widths from
                        \ the left-hand side of the screen. For comparison this
                        \ is 49 for modes 4 and 5, but needs to be adjusted for
                        \ our custom screen's width

 EQUB 23, 0, 10, 32     \ Set 6845 register R10 = %00100000 = 32
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "cursor start" register, and bits 5 and 6
                        \ define the "cursor display mode", as follows:
                        \
                        \   * %00 = steady, non-blinking cursor
                        \
                        \   * %01 = do not display a cursor
                        \
                        \   * %10 = fast blinking cursor (blink at 1/16 of the
                        \           field rate)
                        \
                        \   * %11 = slow blinking cursor (blink at 1/32 of the
                        \           field rate)
                        \
                        \ We can therefore turn off the cursor completely by
                        \ setting cursor display mode %01, with bit 6 of R10
                        \ clear and bit 5 of R10 set

\ ******************************************************************************
\
\       Name: E%
\       Type: Variable
\   Category: Sound
\    Summary: Sound envelope definitions
\
\ ------------------------------------------------------------------------------
\
\ This table contains the sound envelope data, which is passed to OSWORD by the
\ FNE macro to create the four sound envelopes used in-game. Refer to chapter 30
\ of the "BBC Microcomputer User Guide" by John Coll for details of sound
\ envelopes and what all the parameters mean.
\
\ The envelopes are as follows:
\
\   * Envelope 1 is the sound of our own laser firing
\
\   * Envelope 2 is the sound of lasers hitting us, or hyperspace
\
\   * Envelope 3 is the first sound in the two-part sound of us dying, or the
\     second sound in the two-part sound of us hitting or killing an enemy ship
\
\   * Envelope 4 is the sound of E.C.M. firing
\
\ ******************************************************************************

.E%

 EQUB 1, 1, 0, 111, -8, 4, 1, 8, 8, -2, 0, -1, 126, 44
 EQUB 2, 1, 14, -18, -1, 44, 32, 50, 6, 1, 0, -2, 120, 126
 EQUB 3, 1, 1, -1, -3, 17, 32, 128, 1, 0, 0, -1, 1, 1
 EQUB 4, 1, 4, -8, 44, 4, 6, 8, 22, 0, 0, -127, 126, 0

\ ******************************************************************************
\
\       Name: FNE
\       Type: Macro
\   Category: Sound
\    Summary: Macro definition for defining a sound envelope
\
\ ------------------------------------------------------------------------------
\
\ The following macro is used to define the four sound envelopes used in the
\ game. It uses OSWORD 8 to create an envelope using the 14 parameters in the
\ I%-th block of 14 bytes at location E%. This OSWORD call is the same as BBC
\ BASIC's ENVELOPE command.
\
\ See variable E% for more details of the envelopes themselves.
\
\ ******************************************************************************

MACRO FNE I%

 LDX #LO(E%+I%*14)      \ Set (Y X) to point to the I%-th set of envelope data
 LDY #HI(E%+I%*14)      \ in E%

 LDA #8                 \ Call OSWORD with A = 8 to set up sound envelope I%
 JSR OSWORD

ENDMACRO

\ ******************************************************************************
\
\       Name: Elite loader (Part 1 of 3)
\       Type: Subroutine
\   Category: Loader
\    Summary: Set up the split screen mode, move code around, set up the sound
\             envelopes and configure the system
\
\ ******************************************************************************

.ENTRY

                        \ --- Mod: Code removed for Elite-A: ------------------>

\IF _STH_DISC OR _IB_DISC
\
\JSR PROT1              \ Call PROT1 to calculate checksums into CHKSM
\
\ELIF _SRAM_DISC
\
\JSR PROT4              \ Fetch the address of the keyboard translation table
\                       \ before calling PROT1 to calculate checksums into CHKSM
\
\ENDIF
\
\IF _INTERLACE_FIX
\
\LDA #144               \ Call OSBYTE with A = 144, X = 255 and Y set to the
\LDX #255               \ current interlace setting (which the MOS stores at
\LDY &0291              \ &0291), so this moves the screen down one line but
\JSR OSBYTE             \ without changing the interlace
\
\ELSE
\
\LDA #144               \ Call OSBYTE with A = 144, X = 255 and Y = 0 to move
\LDX #255               \ the screen down one line and turn screen interlace on
\JSR OSB
\
\ENDIF

                        \ --- And replaced by: -------------------------------->

 CLI                    \ Enable interrupts

 LDA #144               \ Call OSBYTE with A = 144, X = 255 and Y = 1 to move
 LDX #255               \ the screen down one line and turn screen interlace off
 LDY #1
 JSR OSBYTE

                        \ --- End of replacement ------------------------------>

 LDA #LO(B%)            \ Set the low byte of ZP(1 0) to point to the VDU code
 STA ZP                 \ table at B%

 LDA #HI(B%)            \ Set the high byte of ZP(1 0) to point to the VDU code
 STA ZP+1               \ table at B%

 LDY #0                 \ We are now going to send the N% VDU bytes in the table
                        \ at B% to OSWRCH to set up the special mode 4 screen
                        \ that forms the basis for the split-screen mode

.loop1

 LDA (ZP),Y             \ Pass the Y-th byte of the B% table to OSWRCH
 JSR OSWRCH

 INY                    \ Increment the loop counter

 CPY #N%                \ Loop back for the next byte until we have done them
 BNE loop1              \ all (the number of bytes was set in N% above)

 JSR PLL1               \ Call PLL1 to draw Saturn

                        \ --- Mod: Code removed for Elite-A: ------------------>

\LDA #16                \ Call OSBYTE with A = 16 and X = 3 to set the ADC to
\LDX #3                 \ sample 3 channels from the joystick/Bitstik
\JSR OSBYTE

                        \ --- And replaced by: -------------------------------->

 LDA #16                \ Call OSBYTE with A = 16 and X = 2 to set the ADC to
 LDX #2                 \ sample 2 channels from the joystick
 JSR OSBYTE

                        \ --- End of replacement ------------------------------>

 LDA #&60               \ Store an RTS instruction in location &0232
 STA &0232

 LDA #&02               \ Point the NETV vector to &0232, which we just filled
 STA NETV+1             \ with an RTS
 LDA #&32
 STA NETV

 LDA #190               \ Call OSBYTE with A = 190, X = 8 and Y = 0 to set the
 LDX #8                 \ ADC conversion type to 8 bits, for the joystick
 JSR OSB

                        \ --- Mod: Code removed for Elite-A: ------------------>

\IF _STH_DISC OR _IB_DISC
\
\LDA #200               \ Call OSBYTE with A = 200, X = 0 and Y = 0 to enable
\LDX #0                 \ the ESCAPE key and disable memory clearing if the
\JSR OSB                \ BREAK key is pressed
\
\ELIF _SRAM_DISC
\
\LDA #219               \ Store 219 in location &9F. This gets checked by the
\STA &9F                \ TITLE routine in the main docked code as part of the
\                       \ copy protection (the game hangs if it doesn't match)
\                       \
\                       \ This is normally done in the OSBmod routine, but the
\                       \ sideways RAM variant doesn't call OSBmod as that part
\                       \ of the copy protection is disabled, so we set the
\                       \ value of location &BF here instead
\
\NOP                    \ Pad out the code so it takes up the same amount of
\NOP                    \ space as in the original version
\NOP
\
\ENDIF

                        \ --- And replaced by: -------------------------------->

 LDA #200               \ Call OSBYTE with A = 200, X = 3 and Y = 0 to disable
 LDX #3                 \ the ESCAPE key and clear memory if the BREAK key is
 JSR OSB                \ pressed

                        \ --- End of replacement ------------------------------>

 LDA #13                \ Call OSBYTE with A = 13, X = 0 and Y = 0 to disable
 LDX #0                 \ the "output buffer empty" event
 JSR OSB

 LDA #225               \ Call OSBYTE with A = 225, X = 128 and Y = 0 to set
 LDX #128               \ the function keys to return ASCII codes for SHIFT-fn
 JSR OSB                \ keys (i.e. add 128)

                        \ --- Mod: Code removed for Elite-A: ------------------>

\LDA #12                \ Set A = 12 and X = 0 to pretend that this is an
\LDX #0                 \ innocent call to OSBYTE to reset the keyboard delay
\                       \ and auto-repeat rate to the default, when in reality
\                       \ the OSB address in the next instruction gets modified
\                       \ to point to OSBmod
\
\.OSBjsr
\
\IF _STH_DISC OR _IB_DISC
\
\JSR OSB                \ This JSR gets modified by code inserted into PLL1 so
\                       \ that it points to OSBmod instead of OSB, so this
\                       \ actually calls OSBmod to calculate some checksums
\
\ELIF _SRAM_DISC
\
\NOP                    \ The sideways RAM variant has this part of the copy
\NOP                    \ protection disabled, so pad out the code so it takes
\NOP                    \ up the same amount of space as in the original version
\
\ENDIF

                        \ --- End of removed code ----------------------------->

 LDA #13                \ Call OSBYTE with A = 13, X = 2 and Y = 0 to disable
 LDX #2                 \ the "character entering buffer" event
 JSR OSB

 LDA #4                 \ Call OSBYTE with A = 4, X = 1 and Y = 0 to disable
 LDX #1                 \ cursor editing, so the cursor keys return ASCII values
 JSR OSB                \ and can therefore be used in-game

 LDA #9                 \ Call OSBYTE with A = 9, X = 0 and Y = 0 to disable
 LDX #0                 \ flashing colours
 JSR OSB

                        \ --- Mod: Code added for Elite-A: -------------------->

 LDA #119               \ Call OSBYTE with A = 119 to close any *SPOOL or *EXEC
 JSR OSBYTE             \ files

                        \ --- End of added code ------------------------------->

 JSR PROT3              \ Call PROT3 to do more checks on the CHKSM checksum

 LDA #&00               \ Set the following:
 STA ZP                 \
 LDA #&11               \   ZP(1 0) = &1100
 STA ZP+1               \   P(1 0) = TVT1code
 LDA #LO(TVT1code)
 STA P
 LDA #HI(TVT1code)
 STA P+1

                        \ --- Mod: Code removed for Elite-A: ------------------>

\JSR MVPG               \ Call MVPG to move and decrypt a page of memory from
\                       \ TVT1code to &1100-&11FF

                        \ --- And replaced by: -------------------------------->

 JSR MVPG               \ Call MVPG to move a page of memory from TVT1code to
                        \ &1100-&11FF

 LDA #LO(S%+11)         \ Point BRKV to the fifth entry in the main docked
 STA BRKV               \ code's S% workspace, which contains JMP BRBR
 LDA #HI(S%+11)
 STA BRKV+1

                        \ --- End of replacement ------------------------------>

 LDA #&00               \ Set the following:
 STA ZP                 \
 LDA #&78               \   ZP(1 0) = &7800
 STA ZP+1               \   P(1 0) = DIALS
 LDA #LO(DIALS)         \   X = 8
 STA P
 LDA #HI(DIALS)
 STA P+1
 LDX #8

                        \ --- Mod: Code removed for Elite-A: ------------------>

\JSR MVBL               \ Call MVBL to move and decrypt 8 pages of memory from
\                       \ DIALS to &7800-&7FFF
\
\IF _INTERLACE_FIX
\
\LDA &0291              \ If interlace is on then the MOS will have set &0291 to
\BEQ lace1              \ zero, so jump to lace1 to skip the following
\
\                       \ If we get here then interlace is off, so we modify the
\                       \ split-screen interrupt timer from (57 30) to (56 222)
\                       \ to ensure a clean transition between the space view
\                       \ and dashboard, using figures derived by Patrick Moore
\
\LDA #222               \ Modify the LDA #30 instruction in LINSCN to LDA #222
\STA LINSCN+1           \ to change the low-order T1 count to 222
\
\LDA #56                \ Modify the LDA #VSCAN instruction in LINSCN to LDA #56
\STA LINSCN+8           \ to change the high-order T1 count to 56
\
\STA lace2+1            \ Modify the LDA #VSCAN instruction at lace2 to LDA #56
\                       \ to change the high-order T1 count to 56
\
\.lace1
\
\ENDIF
\
\SEI                    \ Disable interrupts while we set up our interrupt
\                       \ handler to support the split-screen mode
\
\LDA VIA+&44            \ Read the 6522 System VIA T1C-L timer 1 low-order
\STA &0001              \ counter (SHEILA &44), which decrements one million
\                       \ times a second and will therefore be pretty random,
\                       \ and store it in location &0001, which is among the
\                       \ main game code's random seeds (so this seeds the
\                       \ random number generator for the main game)
\
\LDA #%00111001         \ Set 6522 System VIA interrupt enable register IER
\STA VIA+&4E            \ (SHEILA &4E) bits 0 and 3-5 (i.e. disable the Timer1,
\                       \ CB1, CB2 and CA2 interrupts from the System VIA)
\
\LDA #%01111111         \ Set 6522 User VIA interrupt enable register IER
\STA VIA+&6E            \ (SHEILA &6E) bits 0-7 (i.e. disable all hardware
\                       \ interrupts from the User VIA)
\
\LDA IRQ1V              \ Copy the current IRQ1V vector address into VEC(1 0)
\STA VEC
\LDA IRQ1V+1
\STA VEC+1
\
\LDA #LO(IRQ1)          \ Set the IRQ1V vector to IRQ1, so IRQ1 is now the
\STA IRQ1V              \ interrupt handler
\LDA #HI(IRQ1)
\STA IRQ1V+1
\
\IF _INTERLACE_FIX
\
\.lace2
\
\ENDIF
\
\LDA #VSCAN             \ Set 6522 System VIA T1C-L timer 1 high-order counter
\STA VIA+&45            \ (SHEILA &45) to VSCAN (57) to start the T1 counter
\                       \ counting down from 14622 at a rate of 1 MHz
\
\CLI                    \ Re-enable interrupts

                        \ --- And replaced by: -------------------------------->

 JSR MVBL               \ Call MVBL to move 8 pages of memory from DIALS to
                        \ &7800-&7FFF

                        \ --- End of replacement ------------------------------>

 LDA #&00               \ Set the following:
 STA ZP                 \
 LDA #&61               \   ZP(1 0) = &6100
 STA ZP+1               \   P(1 0) = ASOFT
 LDA #LO(ASOFT)
 STA P
 LDA #HI(ASOFT)
 STA P+1

 JSR MVPG               \ Call MVPG to move a page of memory from ASOFT to
                        \ &6100-&61FF

 LDA #&63               \ Set the following:
 STA ZP+1               \
 LDA #LO(ELITE)         \   ZP(1 0) = &6300
 STA P                  \   P(1 0) = ELITE
 LDA #HI(ELITE)
 STA P+1

 JSR MVPG               \ Call MVPG to move a page of memory from ELITE to
                        \ &6300-&63FF

 LDA #&76               \ Set the following:
 STA ZP+1               \
 LDA #LO(CpASOFT)       \   ZP(1 0) = &7600
 STA P                  \   P(1 0) = CpASOFT
 LDA #HI(CpASOFT)
 STA P+1

                        \ --- Mod: Code removed for Elite-A: ------------------>

\JSR MVPG               \ Call MVPG to move and decrypt a page of memory from
\                       \ CpASOFT to &7600-&76FF
\
\LDA #&00               \ Set the following:
\STA ZP                 \
\LDA #&04               \   ZP(1 0) = &0400
\STA ZP+1               \   P(1 0) = WORDS
\LDA #LO(WORDS)         \   X = 4
\STA P
\LDA #HI(WORDS)
\STA P+1
\LDX #4
\
\JSR MVBL               \ Call MVBL to move and decrypt 4 pages of memory from
\                       \ WORDS to &0400-&07FF
\
\LDX #35                \ We now want to copy the disc catalogue routine from
\                       \ CATDcode to CATD, so set a counter in X for the 36
\                       \ bytes to copy
\
\.loop2
\
\LDA CATDcode,X         \ Copy the X-th byte of CATDcode to the X-th byte of
\STA CATD,X             \ CATD
\
\DEX                    \ Decrement the loop counter
\
\BPL loop2              \ Loop back to copy the next byte until they are all
\                       \ done
\
\LDA &76                \ Set the drive number in the CATD routine to the
\STA CATBLOCK           \ contents of &76, which gets set in ELITE3

                        \ --- And replaced by: -------------------------------->

 JSR MVPG               \ Call MVPG to move a page of memory from CpASOFT to
                        \ &7600-&76FF

                        \ --- End of replacement ------------------------------>

 FNE 0                  \ Set up sound envelopes 0-3 using the FNE macro
 FNE 1
 FNE 2
 FNE 3

 LDX #LO(MESS1)         \ Set (Y X) to point to MESS1 ("DIR E")
 LDY #HI(MESS1)

 JSR OSCLI              \ Call OSCLI to run the OS command in MESS1, which
                        \ changes the disc directory to E

                        \ --- Mod: Code removed for Elite-A: ------------------>

\LDA #LO(LOAD)          \ Set the following:
\STA ZP                 \
\LDA #HI(LOAD)          \   ZP(1 0) = LOAD
\STA ZP+1               \   P(1 0) = LOADcode
\LDA #LO(LOADcode)
\STA P
\LDA #HI(LOADcode)
\STA P+1
\
\LDY #0                 \ We now want to move and decrypt one page of memory
\                       \ from LOADcode to LOAD, so set Y as a byte counter
\
\.loop3
\
\LDA (P),Y              \ Fetch the Y-th byte of the P(1 0) memory block
\
\IF _STH_DISC OR _IB_DISC
\
\EOR #&18               \ Decrypt it by EOR'ing with &18
\
\ELIF _SRAM_DISC
\
\EOR CHKSM              \ Decrypt it by EOR'ing with the checksum value
\
\ENDIF
\
\STA (ZP),Y             \ Store the decrypted result in the Y-th byte of the
\                       \ ZP(1 0) memory block
\
\DEY                    \ Decrement the byte counter
\
\BNE loop3              \ Loop back to copy the next byte until we have done a
\                       \ whole page of 256 bytes
\
\JMP LOAD               \ Jump to the start of the routine we just decrypted

                        \ --- And replaced by: -------------------------------->

 LDA #%11110000         \ Set the Data Direction Register (DDR) of port B of the
 STA VIA+&62            \ user port so we can read the buttons on the Delta 14B
                        \ joystick, using PB4 to PB7 as output (so we can write
                        \ to the button columns to select the column we are
                        \ interested in) and PB0 to PB3 as input (so we can read
                        \ from the button rows)

 LDA #0                 \ Set HFX = 0
 STA HFX

 STA LASCT              \ Set LASCT = 0

 LDA #&FF               \ Set ESCP = &FF so we show the palette for when we have
 STA ESCP               \ an escape pod fitted (i.e. black, red, white, cyan)

 SEI                    \ Disable interrupts while we set up our interrupt
                        \ handler to support the split-screen mode

 LDA VIA+&44            \ If the STA instruction were not commented out, then
\STA &0001              \ this would set location &0001 among the random number
                        \ seeds to a pretty random number (i.e. the value of the
                        \ 6522 System VIA T1C-L timer 1 low-order counter), but
                        \ as the STA is commented out, this has no effect

 LDA #%00111001         \ Set 6522 System VIA interrupt enable register IER
 STA VIA+&4E            \ (SHEILA &4E) bits 0 and 3-5 (i.e. disable the Timer1,
                        \ CB1, CB2 and CA2 interrupts from the System VIA)

 LDA #%01111111         \ Set 6522 User VIA interrupt enable register IER
 STA VIA+&6E            \ (SHEILA &6E) bits 0-7 (i.e. disable all hardware
                        \ interrupts from the User VIA)

 LDA IRQ1V              \ Copy the current IRQ1V vector address into VEC(1 0)
 STA VEC
 LDA IRQ1V+1
 STA VEC+1

 LDA #LO(IRQ1)          \ Set the IRQ1V vector to IRQ1, so IRQ1 is now the
 STA IRQ1V              \ interrupt handler
 LDA #HI(IRQ1)
 STA IRQ1V+1

 LDA #VSCAN             \ Set 6522 System VIA T1C-L timer 1 high-order counter
 STA VIA+&45            \ (SHEILA &45) to VSCAN (57) to start the T1 counter
                        \ counting down from 14622 at a rate of 1 MHz

 CLI                    \ Re-enable interrupts

 LDA #0                 \ Call OSBYTE with A = 0 and X = 1 to fetch the
 LDX #1                 \ operating system version into X
 JSR OSBYTE

 CPX #3                 \ If X =< 3 then this is not a BBC Master, so jump to
 BCC not_master         \ not_master to continue loading the BBC Micro version

                        \ This is a BBC Master, so now we copy the block of
                        \ Master-specific filing system code from to_dd00 to
                        \ &DD00 (so we copy the following routines: do_FILEV,
                        \ do_FSCV, do_BYTEV, set_vectors and old_BYTEV)

 LDX #0                 \ Set up a counter in X for the copy

.cpmaster

 LDA to_dd00,X          \ Copy the X-th byte of to_dd00 to &DD00
 STA &DD00,X

 INX                    \ Increment the loop counter

 CPX #dd00_len          \ Loop back until we have copied all the bytes in the
 BNE cpmaster           \ to_dd00 block (as the length of the block is set in
                        \ dd00_len below)

 LDA #143               \ Call OSBYTE 143 to issue a paged ROM service call of
 LDX #&21               \ type &21 with argument &C0, which is the "Indicate
 LDY #&C0               \ static workspace in 'hidden' RAM" service call. This
 JSR OSBYTE             \ call returns the address of a safe place that we can
                        \ use within the memory bank &C000-&DFFF, and returns
                        \ the start location in (Y X)

                        \ We now modify the savews routine so that when it's
                        \ called, it copies the first three pages from the &C000
                        \ workspace to this safe place, and then copies the MOS
                        \ character set into the first three pages of &C000, so
                        \ the character printing routines can use them

                        \ We also modify the restorews routine in a similar way,
                        \ so that when it's called, it copies the three pages
                        \ from the safe place back into the first three pages
                        \ of &C000, thus restoring the filing system workspace

 STX put0+1             \ Modify the low byte of the workspace save address in
 STX put1+1             \ the savews routine to that of (Y X)
 STX put2+1

 STX get0+1             \ Modify the low byte of the workspace restore address
 STX get1+1             \ in the restorews routine to that of (Y X)
 STX get2+1

 STY put0+2             \ Modify the high byte of the workspace save address of
                        \ the first page in the savews routine to that of (Y X)

 STY get0+2             \ Modify the high byte of the workspace restore address
                        \ of the first page in the restorews routine to that of
                        \ (Y X)

 INY                    \ Increment Y so that (Y X) points to the second page,
                        \ i.e. (Y+1 X)

 STY put1+2             \ Modify the high byte of the workspace save address of
                        \ the second page in the savews routine to (Y+1 X)

 STY get1+2             \ Modify the high byte of the workspace restore address
                        \ of the second page in the restorews routine to that of
                        \ (Y+1 X)

 INY                    \ Increment Y so that (Y X) points to the third page,
                        \ i.e. (Y+2 X)

 STY put2+2             \ Modify the high byte of the workspace save address of
                        \ the third page in the savews routine to (Y+2 X)

 STY get2+2             \ Modify the high byte of the workspace restore address
                        \ of the third page in the restorews routine to that of
                        \ (Y+2 X)

 LDA FILEV              \ Set old_FILEV(1 0) to the existing address for FILEV
 STA old_FILEV+1        \ (this modifies the JMP instruction in the do_FILEV
 LDA FILEV+1            \ routine)
 STA old_FILEV+2

 LDA FSCV               \ Set old_FSCV(1 0) to the existing address for FSCV
 STA old_FSCV+1         \ (this modifies the JMP instruction in the do_FILEV
 LDA FSCV+1             \ routine)
 STA old_FSCV+2

 LDA BYTEV              \ Set old_BYTEV(1 0) to the existing address for BYTEV
 STA old_BYTEV+1        \ (this modifies the JMP instruction in the old_BYTEV
 LDA BYTEV+1            \ routine)
 STA old_BYTEV+2

IF _BUG_FIX

 JSR savews             \ The do_FILEV handler starts by restoring the filing
                        \ system workspace, so we need to save it first so the
                        \ handler will work

ENDIF

 JSR set_vectors        \ Call set_vectors to update FILEV, FSCV and BYTEV to
                        \ point to the new handlers in do_FILEV, do_FSCV and
                        \ do_BYTEV

.not_master

 LDA #234               \ Call OSBYTE with A = 234, X = 0 and Y = &FF, which
 LDY #&FF               \ detects whether Tube hardware is present, returning
 LDX #0                 \ X = 0 (not present) or X = &FF (present)
 JSR OSBYTE

 TXA                    \ Copy the result of the Tube check from X into A

 BNE tube_go            \ If X is non-zero then we are running this over the
                        \ Tube, so jump to tube_go to set up the Tube version

                        \ If we get here then we are not running on a 6502
                        \ Second Processor

 LDA #172               \ Call OSBYTE 172 to read the address of the MOS
 LDX #0                 \ keyboard translation table into (Y X)
 LDY #&FF
 JSR OSBYTE

 STX TRTB%              \ Store the address of the keyboard translation table in
 STY TRTB%+1            \ TRTB%(1 0)

 LDA #&00               \ Set the following:
 STA ZP                 \
 LDA #&04               \   ZP(1 0) = &0400
 STA ZP+1               \   P(1 0) = WORDS
 LDA #LO(WORDS)         \   X = 4
 STA P
 LDA #HI(WORDS)
 STA P+1
 LDX #4

 JSR MVBL               \ Call MVBL to move 4 pages of memory from WORDS to
                        \ &0400-&07FF

 LDA #LO(S%+6)          \ Point WRCHV to the third entry in the main docked
 STA WRCHV              \ code's S% workspace, which contains JMP CHPR
 LDA #HI(S%+6)
 STA WRCHV+1

 LDA #LO(LOAD)          \ Set the following:
 STA ZP                 \
 LDA #HI(LOAD)          \   ZP(1 0) = LOAD
 STA ZP+1               \   P(1 0) = LOADcode
 LDA #LO(LOADcode)
 STA P
 LDA #HI(LOADcode)
 STA P+1

 JSR MVPG               \ Call MVPG to move a page of memory from LOADcode to
                        \ LOAD

 LDY #35                \ We now want to copy the iff_index routine from
                        \ iff_index_code to iff_index, so set a counter in Y
                        \ for the 36 bytes to copy

.copy_d7a

 LDA iff_index_code,Y   \ Copy the X-th byte of iff_index_code to the X-th byte
 STA iff_index,Y        \ of iff_index

 DEY                    \ Decrement the loop counter

 BPL copy_d7a           \ Loop back to copy the next byte until they are all
                        \ done

 JMP LOAD               \ Jump to the start of the LOAD routine we moved above,
                        \ to run the game

.tube_go

 LDA #172               \ Call OSBYTE 172 to read the address of the MOS
 LDX #0                 \ keyboard translation table into (Y X)
 LDY #&FF
 JSR OSBYTE

 STX key_tube           \ Store the address of the keyboard translation table in
 STY key_tube+1         \ key_tube(1 0)

\LDX #LO(tube_400)      \ These instructions are commented out in the original
\LDY #HI(tube_400)      \ source
\LDA #1
\JSR &0406
\
\LDA #LO(WORDS)
\STA &72
\LDA #HI(WORDS)
\STA &73
\
\LDX #&04
\LDY #&00
\
\.tube_wr
\
\LDA (&72),Y
\JSR tube_wait
\
\BIT tube_r3s
\BVC tube_wr
\
\STA tube_r3d
\
\INY
\BNE tube_wr
\
\INC &73
\
\DEX
\BNE tube_wr
\
\LDA #LO(tube_wrch)
\STA WRCHV
\LDA #HI(tube_wrch)
\STA WRCHV+&01

 LDX #LO(tube_run)      \ Set (Y X) to point to tube_run ("R.2.H")
 LDY #HI(tube_run)

 JMP OSCLI              \ Call OSCLI to run the OS command in tube_run, which
                        \ runs the I/O processor code in 2.H

.tube_run

 EQUS "R.2.H"           \ The OS command for running the Tube version's I/O
 EQUB 13                \ processor code in file 2.H (this command is short for
                        \ "*RUN 2.H")

\.tube_400              \ These instructions are commented out in the original
\                       \ source
\EQUD &0400
\
\.tube_wait
\
\JSR tube_wait2
\
\.tube_wait2
\
\JSR tube_wait3
\
\.tube_wait3
\
\RTS

                        \ --- End of replacement ------------------------------>

\ ******************************************************************************
\
\       Name: iff_index_code
\       Type: Subroutine
\   Category: Dashboard
\    Summary: The iff_index routine, bundled up in the loader so it can be moved
\             to &0D7A to be run
\
\ ******************************************************************************

.iff_index_code

 ORG &0D7A              \ Set the assembly address to &0D7A

\ ******************************************************************************
\
\       Name: iff_index
\       Type: Subroutine
\   Category: Dashboard
\    Summary: Return the type index for this ship in the I.F.F. system
\  Deep dive: The I.F.F. system
\
\ ------------------------------------------------------------------------------
\
\ This routine is copied to &0D7A in part 1 above.
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   X                   The index for the current ship in the I.F.F. system:
\
\                         * 0 = Clean
\                               Innocent trader, innocent bounty hunter
\
\                         * 1 = Station tracked
\                               Cop, space station, escape pod
\
\                         * 2 = Debris
\                               Cargo, alloy plate, asteroid, boulder, splinter
\
\                         * 3 = Missile
\
\                         * 4 = Offender/fugitive
\                               Pirate, non-innocent bounty hunter
\
\                       If there is no I.F.F. system fitted, the index returned
\                       in X is always 0
\
\ ******************************************************************************

                        \ --- Mod: Code added for Elite-A: -------------------->

.iff_index

 LDX CRGO               \ If we do not have an I.F.F. system fitted (i.e. CRGO
 BEQ iff_not            \ is zero), jump to iff_not to return from the routine
                        \ with X = 0

                        \ If we get here then X = &FF (as CRGO is &FF if we have
                        \ an I.F.F. system fitted)

 LDY #36                \ Set A to byte #36 of the ship's blueprint, i.e. the
 LDA (INF),Y            \ NEWB flags

 ASL A                  \ If bit 6 is set, i.e. this is a cop, a space station
 ASL A                  \ or an escape pod, jump to iff_cop to return X = 1
 BCS iff_cop

 ASL A                  \ If bit 5 is set, i.e. this is an innocent bystander
 BCS iff_trade          \ (which applies to traders and some bounty hunters),
                        \ jump to iff_trade to return X = 0

 LDY TYPE               \ Set Y to the ship's type - 1
 DEY

 BEQ iff_missle         \ If Y = 0, i.e. this is a missile, then jump to
                        \ iff_missle to return X = 3

 CPY #8                 \ If Y < 8, i.e. this is a cargo canister, alloy plate,
 BCC iff_aster          \ boulder, asteroid or splinter, then jump to iff_aster
                        \ to return X = 2

                        \ If we get here then the ship is not the following:
                        \
                        \   * A cop/station/escape pod
                        \   * An innocent bystander/trader/good bounty hunter
                        \   * A missile
                        \   * Cargo or an asteroid
                        \
                        \ So it must be a pirate or a non-innocent bounty hunter

 INX                    \ X is &FF at this point, so this INX sets X = 0, and we
                        \ then fall through into the four INX instructions below
                        \ to return X = 4

.iff_missle

 INX                    \ If we jump to this point, then return X = 3

.iff_aster

 INX                    \ If we jump to this point, then return X = 2

.iff_cop

 INX                    \ If we jump to this point, then return X = 1

.iff_trade

 INX                    \ If we jump to this point, then return X = 0

.iff_not

 RTS                    \ Return from the subroutine

                        \ --- End of added code ------------------------------->

 COPYBLOCK iff_index, P%, iff_index_code

 ORG iff_index_code + P% - iff_index

\ ******************************************************************************
\
\       Name: LOADcode
\       Type: Subroutine
\   Category: Loader
\    Summary: Encrypted LOAD routine, bundled up in the loader so it can be
\             moved to &0B00 to be run
\
\ ******************************************************************************

.LOADcode

 ORG &0B00              \ Set the assembly address to &0B00

\ ******************************************************************************
\
\       Name: LOAD
\       Type: Subroutine
\   Category: Loader
\    Summary: Load the main docked code, set up various vectors, run a checksum
\             and start the game
\
\ ******************************************************************************

.LOAD

                        \ --- Mod: Code removed for Elite-A: ------------------>

\LDX #LO(LTLI)          \ Set (Y X) to point to LTLI ("L.T.CODE")
\LDY #HI(LTLI)
\
\JSR OSCLI              \ Call OSCLI to run the OS command in LTLI, which loads
\                       \ the T.CODE binary (the main docked code) to its load
\                       \ address of &11E3
\
\LDA #LO(S%+11)         \ Point BRKV to the fifth entry in the main docked
\STA BRKV               \ code's S% workspace, which contains JMP BRBR1
\LDA #HI(S%+11)
\STA BRKV+1
\
\LDA #LO(S%+6)          \ Point WRCHV to the third entry in the main docked
\STA WRCHV              \ code's S% workspace, which contains JMP CHPR
\LDA #HI(S%+6)
\STA WRCHV+1
\
\SEC                    \ Set the C flag so the checksum we calculate in A
\                       \ starts with an initial value of 18 (17 plus carry)
\
\LDY #0                 \ Set Y = 0 to act as a byte pointer
\
\STY ZP                 \ Set the low byte of ZP(1 0) to 0, so ZP(1 0) always
\                       \ points to the start of a page
\
\LDX #&11               \ Set X = &11, so ZP(1 0) will point to &1100 when we
\                       \ stick X in ZP+1 below
\
\TXA                    \ Set A = &11 = 17, to set the initial value of the
\                       \ checksum to 18 (17 plus carry)
\
\.l1
\
\STX ZP+1               \ Set the high byte of ZP(1 0) to the page number in X
\
\ADC (ZP),Y             \ Set A = A + the Y-th byte of ZP(1 0)
\
\DEY                    \ Decrement the byte pointer
\
\BNE l1                 \ Loop back to add the next byte until we have added the
\                       \ whole page
\
\INX                    \ Increment the page number in X
\
\CPX #&54               \ Loop back to checksum the next page until we have
\BCC l1                 \ checked up to (but not including) page &54
\
\CMP &55FF              \ Compare the checksum with the value in &55FF, which is
\                       \ in the docked file we just loaded, in the byte before
\                       \ the ship hangar blueprints at XX21
\
\IF _REMOVE_CHECKSUMS OR _INTERLACE_FIX
\
\NOP                    \ If we have disabled checksums, then ignore the result
\NOP                    \ of the checksum comparison
\
\ELSE
\
\IF _STH_DISC OR _IB_DISC
\
\BNE P%                 \ If the checksums don't match then enter an infinite
\                       \ loop, which hangs the computer
\
\ELIF _SRAM_DISC
\
\NOP                    \ The sideways RAM variant ignores the result of the
\NOP                    \ checksum comparison
\
\ENDIF
\
\ENDIF

                        \ --- And replaced by: -------------------------------->

 LDX #LO(LTLI)          \ Set (Y X) to point to LTLI ("L.1.D")
 LDY #HI(LTLI)

 JSR OSCLI              \ Call OSCLI to run the OS command in LTLI, which loads
                        \ the 1.D binary (the main docked code) to its load
                        \ address of &11E3

                        \ --- End of replacement ------------------------------>

 JMP S%+3               \ Jump to the second entry in the main docked code's S%
                        \ workspace to start a new game

.LTLI

                        \ --- Mod: Code removed for Elite-A: ------------------>

\EQUS "L.T.CODE"        \ This is short for "*LOAD T.CODE"
\EQUB 13
\
\EQUS "Does your mother know you do this?"

                        \ --- And replaced by: -------------------------------->

 EQUS "L.1.D"           \ This is short for "*LOAD 1.D"
 EQUB 13

                        \ --- End of replacement ------------------------------>

 COPYBLOCK LOAD, P%, LOADcode

 ORG LOADcode + P% - LOAD

\ ******************************************************************************
\
\       Name: PLL1 (Part 1 of 3)
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Draw Saturn on the loading screen (draw the planet)
\  Deep dive: Drawing Saturn on the loading screen
\
\ ******************************************************************************

.PLL1

                        \ The following loop iterates CNT(1 0) times, i.e. &300
                        \ or 768 times, and draws the planet part of the
                        \ loading screen's Saturn

 LDA VIA+&44            \ Read the 6522 System VIA T1C-L timer 1 low-order
 STA RAND+1             \ counter (SHEILA &44), which decrements one million
                        \ times a second and will therefore be pretty random,
                        \ and store it in location RAND+1, which is among the
                        \ main game code's random seeds in RAND (so this seeds
                        \ the random number generator)

 JSR DORND              \ Set A and X to signed random numbers between -128 and
                        \ 127, so let's say A = r1

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r1^2

 STA ZP+1               \ Set ZP(1 0) = (A P)
 LDA P                  \             = r1^2
 STA ZP

                        \ --- Mod: Code removed for Elite-A: ------------------>

\LDA #LO(OSBmod)        \ As part of the copy protection, the JSR OSB
\STA OSBjsr+1           \ instruction at OSBjsr gets modified to point to OSBmod
\                       \ instead of OSB, and this is where we modify the low
\                       \ byte of the destination address

                        \ --- End of removed code ----------------------------->

 JSR DORND              \ Set A and X to signed random numbers between -128 and
                        \ 127, so let's say A = r2

 STA YY                 \ Set YY = A
                        \        = r2

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r2^2

 TAX                    \ Set (X P) = (A P)
                        \           = r2^2

 LDA P                  \ Set (A ZP) = (X P) + ZP(1 0)
 ADC ZP                 \
 STA ZP                 \ first adding the low bytes

 TXA                    \ And then adding the high bytes
 ADC ZP+1

 BCS PLC1               \ If the addition overflowed, jump down to PLC1 to skip
                        \ to the next pixel

 STA ZP+1               \ Set ZP(1 0) = (A ZP)
                        \             = r1^2 + r2^2

 LDA #1                 \ Set ZP(1 0) = &4001 - ZP(1 0) - (1 - C)
 SBC ZP                 \             = 128^2 - ZP(1 0)
 STA ZP                 \
                        \ (as the C flag is clear), first subtracting the low
                        \ bytes

 LDA #&40               \ And then subtracting the high bytes
 SBC ZP+1
 STA ZP+1

 BCC PLC1               \ If the subtraction underflowed, jump down to PLC1 to
                        \ skip to the next pixel

                        \ If we get here, then both calculations fitted into
                        \ 16 bits, and we have:
                        \
                        \   ZP(1 0) = 128^2 - (r1^2 + r2^2)
                        \
                        \ where ZP(1 0) >= 0

 JSR ROOT               \ Set ZP = SQRT(ZP(1 0))

 LDA ZP                 \ Set X = ZP >> 1
 LSR A                  \       = SQRT(128^2 - (a^2 + b^2)) / 2
 TAX

 LDA YY                 \ Set A = YY
                        \       = r2

 CMP #128               \ If YY >= 128, set the C flag (so the C flag is now set
                        \ to bit 7 of A)

 ROR A                  \ Rotate A and set the sign bit to the C flag, so A is
                        \ halved while retaining its sign
                        \
                        \ A is still a signed number from -128 to 127

 JSR PIX                \ Draw a pixel at screen coordinate (X + 128, A + 128),
                        \ where:
                        \
                        \   X = ZP / 2
                        \   A = r2 / 2
                        \   ZP = SQRT(128^2 - (r1^2 + r2^2))
                        \
                        \ So this is the same as plotting at (x, y) where:
                        \
                        \   r1 = random number from -128 to 127
                        \   r2 = random number from -128 to 127
                        \
                        \   (r1^2 + r2^2) < 128^2
                        \
                        \   x = (SQRT(128^2 - (r1^2 + r2^2)) / 2) + 128
                        \   y = (r2 / 2) + 128
                        \
                        \ which is what we want

.PLC1

 DEC CNT                \ Decrement the counter in CNT (the low byte)

 BNE PLL1               \ Loop back to PLL1 until CNT = 0

 DEC CNT+1              \ Decrement the counter in CNT+1 (the high byte)

 BNE PLL1               \ Loop back to PLL1 until CNT+1 = 0

\ ******************************************************************************
\
\       Name: PLL1 (Part 2 of 3)
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Draw Saturn on the loading screen (draw the stars)
\  Deep dive: Drawing Saturn on the loading screen
\
\ ******************************************************************************

                        \ The following loop iterates CNT2(1 0) times, i.e. &1DD
                        \ or 477 times, and draws the background stars on the
                        \ loading screen

.PLL2

 JSR DORND              \ Set A and X to signed random numbers between -128 and
                        \ 127, so let's say A = r3

 TAX                    \ Set X = A
                        \       = r3

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r3^2

 STA ZP+1               \ Set ZP+1 = A
                        \          = r3^2 / 256

 JSR DORND              \ Set A and X to signed random numbers between -128 and
                        \ 127, so let's say A = r4

 STA YY                 \ Set YY = r4

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r4^2

 ADC ZP+1               \ Set A = A + r3^2 / 256
                        \       = r4^2 / 256 + r3^2 / 256
                        \       = (r3^2 + r4^2) / 256

 CMP #&11               \ If A < 17, jump down to PLC2 to skip to the next pixel
 BCC PLC2

 LDA YY                 \ Set A = r4

 JSR PIX                \ Draw a pixel at screen coordinate (X + 128, A + 128),
                        \ where:
                        \
                        \   X = r3
                        \   A = r4
                        \
                        \ So this is the same as plotting at (x, y) where:
                        \
                        \   r3 = random number from -128 to 127
                        \   r4 = random number from -128 to 127
                        \
                        \   (r3^2 + r4^2) / 256 >= 17
                        \
                        \   x = r3
                        \   y = r4
                        \
                        \ which is what we want

.PLC2

 DEC CNT2               \ Decrement the counter in CNT2 (the low byte)

 BNE PLL2               \ Loop back to PLL2 until CNT2 = 0

 DEC CNT2+1             \ Decrement the counter in CNT2+1 (the high byte)

 BNE PLL2               \ Loop back to PLL2 until CNT2+1 = 0

\ ******************************************************************************
\
\       Name: PLL1 (Part 3 of 3)
\       Type: Subroutine
\   Category: Drawing planets
\    Summary: Draw Saturn on the loading screen (draw the rings)
\  Deep dive: Drawing Saturn on the loading screen
\
\ ******************************************************************************

                        \ The following loop iterates CNT3(1 0) times, i.e. &333
                        \ or 819 times, and draws the rings around the loading
                        \ screen's Saturn

.PLL3

 JSR DORND              \ Set A and X to signed random numbers between -128 and
                        \ 127, so let's say A = r5

 STA ZP                 \ Set ZP = r5

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r5^2

 STA ZP+1               \ Set ZP+1 = A
                        \          = r5^2 / 256

                        \ --- Mod: Code removed for Elite-A: ------------------>

\LDA #HI(OSBmod)        \ As part of the copy protection, the JSR OSB
\STA OSBjsr+2           \ instruction at OSBjsr gets modified to point to OSBmod
\                       \ instead of OSB, and this is where we modify the high
\                       \ byte of the destination address

                        \ --- End of removed code ----------------------------->

 JSR DORND              \ Set A and X to signed random numbers between -128 and
                        \ 127, so let's say A = r6

 STA YY                 \ Set YY = r6

 JSR SQUA2              \ Set (A P) = A * A
                        \           = r6^2

 STA T                  \ Set T = A
                        \       = r6^2 / 256

 ADC ZP+1               \ Set ZP+1 = A + r5^2 / 256
 STA ZP+1               \          = r6^2 / 256 + r5^2 / 256
                        \          = (r5^2 + r6^2) / 256

 LDA ZP                 \ Set A = ZP
                        \       = r5

 CMP #128               \ If A >= 128, set the C flag (so the C flag is now set
                        \ to bit 7 of ZP, i.e. bit 7 of A)

 ROR A                  \ Rotate A and set the sign bit to the C flag, so bits
                        \ 6 and 7 are now the same

 CMP #128               \ If A >= 128, set the C flag (so again, the C flag is
                        \ set to bit 7 of A)

 ROR A                  \ Rotate A and set the sign bit to the C flag, so bits
                        \ 5-7 are now the same, i.e. A is a random number in one
                        \ of these ranges:
                        \
                        \   %00000000 - %00011111  = 0-31
                        \   %11100000 - %11111111  = 224-255
                        \
                        \ In terms of signed 8-bit integers, this is a random
                        \ number from -32 to 31. Let's call it r7

 ADC YY                 \ Set A = A + YY
                        \       = r7 + r6

 TAX                    \ Set X = A
                        \       = r6 + r7

 JSR SQUA2              \ Set (A P) = A * A
                        \           = (r6 + r7)^2

 TAY                    \ Set Y = A
                        \       = (r6 + r7)^2 / 256

 ADC ZP+1               \ Set A = A + ZP+1
                        \       = (r6 + r7)^2 / 256 + (r5^2 + r6^2) / 256
                        \       = ((r6 + r7)^2 + r5^2 + r6^2) / 256

 BCS PLC3               \ If the addition overflowed, jump down to PLC3 to skip
                        \ to the next pixel

 CMP #80                \ If A >= 80, jump down to PLC3 to skip to the next
 BCS PLC3               \ pixel

 CMP #32                \ If A < 32, jump down to PLC3 to skip to the next pixel
 BCC PLC3

 TYA                    \ Set A = Y + T
 ADC T                  \       = (r6 + r7)^2 / 256 + r6^2 / 256
                        \       = ((r6 + r7)^2 + r6^2) / 256

 CMP #16                \ If A >= 16, skip to PL1 to plot the pixel
 BCS PL1

 LDA ZP                 \ If ZP is positive (i.e. r5 < 128), jump down to PLC3
 BPL PLC3               \ to skip to the next pixel

.PL1

                        \ If we get here then the following is true:
                        \
                        \   32 <= ((r6 + r7)^2 + r5^2 + r6^2) / 256 < 80
                        \
                        \ and either this is true:
                        \
                        \   ((r6 + r7)^2 + r6^2) / 256 >= 16
                        \
                        \ or both these are true:
                        \
                        \   ((r6 + r7)^2 + r6^2) / 256 < 16
                        \   r5 >= 128

 LDA YY                 \ Set A = YY
                        \       = r6

 JSR PIX                \ Draw a pixel at screen coordinate (X + 128, A + 128),
                        \ where:
                        \
                        \   X = (random -32 to 31) + r6
                        \   A = r6
                        \
                        \ So this is the same as plotting at (x, y) where:
                        \
                        \   r5 = random number from -128 to 127
                        \   r6 = random number from -128 to 127
                        \   r7 = r5, squashed into -32 to 31
                        \
                        \   32 <= ((r6 + r7)^2 + r5^2 + r6^2) / 256 < 80
                        \
                        \   Either: ((r6 + r7)^2 + r6^2) / 256 >= 16
                        \
                        \   Or:     ((r6 + r7)^2 + r6^2) / 256 <  16
                        \           r5 >= 128
                        \
                        \   x = r6 + r7 + 128
                        \   y = r6 + 128
                        \
                        \ which is what we want

.PLC3

 DEC CNT3               \ Decrement the counter in CNT3 (the low byte)

 BNE PLL3               \ Loop back to PLL3 until CNT3 = 0

 DEC CNT3+1             \ Decrement the counter in CNT3+1 (the high byte)

 BNE PLL3               \ Loop back to PLL3 until CNT3+1 = 0

                        \ The following code is not required, as we copy the
                        \ title images to their correct places on-screen when
                        \ we return from the subroutine, overwriting the copy
                        \ that we do here

 LDA #&00               \ Set ZP(1 0) = &6300
 STA ZP
 LDA #&63
 STA ZP+1

                        \ --- Mod: Code removed for Elite-A: ------------------>

\LDA #LO(ELITE)         \ Set P(1 0) = ELITE
\STA P
\LDA #HI(ELITE)
\STA P+1
\
\LDX #8                 \ Call MVPG with X = 8 to copy 8 pages of memory from
\JSR MVPG               \ ELITE to &6300

                        \ --- And replaced by: -------------------------------->

 LDA #&62               \ Set P(1 0) = &2A62
 STA P
 LDA #&2A
 STA P+1

 LDX #8                 \ Call MVPG with X = 8 to copy 8 pages of memory from
 JSR MVPG               \ &2A62 to &6300

                        \ --- End of replacement ------------------------------>

\ ******************************************************************************
\
\       Name: DORND
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Generate random numbers
\  Deep dive: Generating random numbers
\             Fixing ship positions
\
\ ------------------------------------------------------------------------------
\
\ Set A and X to random numbers (though note that X is set to the random number
\ that was returned in A the last time DORND was called).
\
\ The C and V flags are also set randomly.
\
\ This is a simplified version of the DORND routine in the main game code. It
\ swaps the two calculations around and omits the ROL A instruction, but is
\ otherwise very similar. See the DORND routine in the main game code for more
\ details.
\
\ ******************************************************************************

.DORND

 LDA RAND+1             \ r1´ = r1 + r3 + C
 TAX                    \ r3´ = r1
 ADC RAND+3
 STA RAND+1
 STX RAND+3

 LDA RAND               \ X = r2´ = r0
 TAX                    \ A = r0´ = r0 + r2
 ADC RAND+2
 STA RAND
 STX RAND+2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: RAND
\       Type: Variable
\   Category: Drawing planets
\    Summary: The random number seed used for drawing Saturn
\
\ ******************************************************************************

.RAND

 EQUD &34785349

\ ******************************************************************************
\
\       Name: SQUA2
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate (A P) = A * A
\  Deep dive: Shift-and-add multiplication
\
\ ------------------------------------------------------------------------------
\
\ Do the following multiplication of signed 8-bit numbers:
\
\   (A P) = A * A
\
\ This uses a similar approach to routine SQUA2 in the main game code, which
\ itself uses the MU11 routine to do the multiplication. However, this version
\ first ensures that A is positive, so it can support signed numbers.
\
\ ******************************************************************************

.SQUA2

 BPL SQUA               \ If A > 0, jump to SQUA

 EOR #&FF               \ Otherwise we need to negate A for the SQUA algorithm
 CLC                    \ to work, so we do this using two's complement, by
 ADC #1                 \ setting A = ~A + 1

.SQUA

 STA Q                  \ Set Q = A and P = A

 STA P                  \ Set P = A

 LDA #0                 \ Set A = 0 so we can start building the answer in A

 LDY #8                 \ Set up a counter in Y to count the 8 bits in P

 LSR P                  \ Set P = P >> 1
                        \ and C flag = bit 0 of P

.SQL1

 BCC SQ1                \ If C (i.e. the next bit from P) is set, do the
 CLC                    \ addition for this bit of P:
 ADC Q                  \
                        \   A = A + Q

.SQ1

 ROR A                  \ Shift A right to catch the next digit of our result,
                        \ which the next ROR sticks into the left end of P while
                        \ also extracting the next bit of P

 ROR P                  \ Add the overspill from shifting A to the right onto
                        \ the start of P, and shift P right to fetch the next
                        \ bit for the calculation into the C flag

 DEY                    \ Decrement the loop counter

 BNE SQL1               \ Loop back for the next bit until P has been rotated
                        \ all the way

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: PIX
\       Type: Subroutine
\   Category: Drawing pixels
\    Summary: Draw a single pixel at a specific coordinate
\
\ ------------------------------------------------------------------------------
\
\ Draw a pixel at screen coordinate (X + 128, A + 128). The routine uses the
\ same approach as the PIXEL routine in the main game code, except it plots a
\ single pixel from TWOS instead of a two pixel dash from TWOS2. This applies
\ to the top part of the screen (the monochrome mode 4 space view).
\
\ See the PIXEL routine in the main game code for more details.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   X                   The signed screen x-coordinate of the pixel to draw,
\                       from -128 to 127, to be plotted relative to the origin
\                       at (128, 128)
\
\   A                   The signed screen y-coordinate of the pixel to draw,
\                       from -128 to 127, to be plotted relative to the origin
\                       at (128, 128)
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   out                 Contains an RTS
\
\ ******************************************************************************

.PIX

 TAY                    \ Copy A into Y, for use later

 EOR #%10000000         \ Add 128 to A and treat this as an unsigned number from
                        \ now on

 LSR A                  \ Set A = A >> 3
 LSR A
 LSR A

 LSR CHKSM+1            \ Rotate the high byte of CHKSM+1 to the right, as part
                        \ of the copy protection

 ORA #&60               \ Set ZP+1 = &60 + A >> 3
 STA ZP+1

 TXA                    \ Set ZP = (X >> 3) * 8
 EOR #%10000000
 AND #%11111000
 STA ZP

 TYA                    \ Set Y = Y mod 8, which is the pixel row within the
 AND #7                 \ character block at which we want to draw our pixel
 TAY                    \ (as each character block has 8 rows)

 TXA                    \ Set X = X mod 8, which is the horizontal pixel number
 AND #7                 \ within the character block where the pixel lies (as
 TAX                    \ each pixel line in the character block is 8 pixels
                        \ wide)

 LDA TWOS,X             \ Fetch a pixel from TWOS and poke it into ZP+Y
 STA (ZP),Y

.out

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: TWOS
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Ready-made single-pixel character row bytes for mode 4
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting one-pixel points in mode 4 (the top part of the
\ split screen). See the PIX routine for details.
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
\       Name: CNT
\       Type: Variable
\   Category: Drawing planets
\    Summary: A counter for use in drawing Saturn's planetary body
\
\ ------------------------------------------------------------------------------
\
\ Defines the number of iterations of the PLL1 loop, which draws the planet part
\ of the loading screen's Saturn.
\
\ ******************************************************************************

.CNT

 EQUW &0300             \ The number of iterations of the PLL1 loop (768)

\ ******************************************************************************
\
\       Name: CNT2
\       Type: Variable
\   Category: Drawing planets
\    Summary: A counter for use in drawing Saturn's background stars
\
\ ------------------------------------------------------------------------------
\
\ Defines the number of iterations of the PLL2 loop, which draws the background
\ stars on the loading screen.
\
\ ******************************************************************************

.CNT2

 EQUW &01DD             \ The number of iterations of the PLL2 loop (477)

\ ******************************************************************************
\
\       Name: CNT3
\       Type: Variable
\   Category: Drawing planets
\    Summary: A counter for use in drawing Saturn's rings
\
\ ------------------------------------------------------------------------------
\
\ Defines the number of iterations of the PLL3 loop, which draws the rings
\ around the loading screen's Saturn.
\
\ ******************************************************************************

.CNT3

 EQUW &0333             \ The number of iterations of the PLL3 loop (819)

\ ******************************************************************************
\
\       Name: PROT3
\       Type: Subroutine
\   Category: Copy protection
\    Summary: Part of the CHKSM copy protection checksum calculation
\
\ ******************************************************************************

.PROT3

 LDA CHKSM              \ Update the checksum
 AND CHKSM+1
 ORA #&0C
 ASL A
 STA CHKSM

 RTS                    \ Return from the subroutine

                        \ --- Mod: Code removed for Elite-A: ------------------>

\JMP P%                 \ This would hang the computer, but we never get here as
\                       \ the checksum code has been disabled

                        \ --- End of removed code ----------------------------->

\ ******************************************************************************
\
\       Name: ROOT
\       Type: Subroutine
\   Category: Maths (Arithmetic)
\    Summary: Calculate ZP = SQRT(ZP(1 0))
\
\ ------------------------------------------------------------------------------
\
\ Calculate the following square root:
\
\   ZP = SQRT(ZP(1 0))
\
\ This routine is identical to LL5 in the main game code - it even has the same
\ label names. The only difference is that LL5 calculates Q = SQRT(R Q), but
\ apart from the variables used, the instructions are identical, so see the LL5
\ routine in the main game code for more details on the algorithm used here.
\
\ ******************************************************************************

.ROOT

 LDY ZP+1               \ Set (Y Q) = ZP(1 0)
 LDA ZP
 STA Q

                        \ So now to calculate ZP = SQRT(Y Q)

 LDX #0                 \ Set X = 0, to hold the remainder

 STX ZP                 \ Set ZP = 0, to hold the result

 LDA #8                 \ Set P = 8, to use as a loop counter
 STA P

.LL6

 CPX ZP                 \ If X < ZP, jump to LL7
 BCC LL7

 BNE LL8                \ If X > ZP, jump to LL8

 CPY #64                \ If Y < 64, jump to LL7 with the C flag clear,
 BCC LL7                \ otherwise fall through into LL8 with the C flag set

.LL8

 TYA                    \ Set Y = Y - 64
 SBC #64                \
 TAY                    \ This subtraction will work as we know C is set from
                        \ the BCC above, and the result will not underflow as we
                        \ already checked that Y >= 64, so the C flag is also
                        \ set for the next subtraction

 TXA                    \ Set X = X - ZP
 SBC ZP
 TAX

.LL7

 ROL ZP                 \ Shift the result in Q to the left, shifting the C flag
                        \ into bit 0 and bit 7 into the C flag

 ASL Q                  \ Shift the dividend in (Y S) to the left, inserting
 TYA                    \ bit 7 from above into bit 0
 ROL A
 TAY

 TXA                    \ Shift the remainder in X to the left
 ROL A
 TAX

 ASL Q                  \ Shift the dividend in (Y S) to the left
 TYA
 ROL A
 TAY

 TXA                    \ Shift the remainder in X to the left
 ROL A
 TAX

 DEC P                  \ Decrement the loop counter

 BNE LL6                \ Loop back to LL6 until we have done 8 loops

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: OSB
\       Type: Subroutine
\   Category: Utility routines
\    Summary: A convenience routine for calling OSBYTE with Y = 0
\
\ ******************************************************************************

.OSB

 LDY #0                 \ Call OSBYTE with Y = 0, returning from the subroutine
 JMP OSBYTE             \ using a tail call (so we can call OSB to call OSBYTE
                        \ for when we know we want Y set to 0)

\ ******************************************************************************
\
\       Name: MVPG
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Move a page of memory
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   P(1 0)              The source address of the page to move
\
\   ZP(1 0)             The destination address of the page to move
\
\ ******************************************************************************

.MVPG

 LDY #0                 \ We want to move one page of memory, so set Y as a byte
                        \ counter

.MPL

 LDA (P),Y              \ Fetch the Y-th byte of the P(1 0) memory block

                        \ --- Mod: Code removed for Elite-A: ------------------>

\EOR #&A5               \ Decrypt it by EOR'ing with &A5

                        \ --- End of removed code ----------------------------->

 STA (ZP),Y             \ Store the result in the Y-th byte of the ZP(1 0)
                        \ memory block

 DEY                    \ Decrement the byte counter

 BNE MPL                \ Loop back to copy the next byte until we have done a
                        \ whole page of 256 bytes

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MVBL
\       Type: Subroutine
\   Category: Utility routines
\    Summary: Move a multi-page block of memory
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   P(1 0)              The source address of the block to move
\
\   ZP(1 0)             The destination address of the block to move
\
\   X                   Number of pages of memory to move (1 page = 256 bytes)
\
\ ******************************************************************************

.MVBL

 JSR MVPG               \ Call MVPG above to copy one page of memory from the
                        \ address in P(1 0) to the address in ZP(1 0)

 INC ZP+1               \ Increment the high byte of the source address to point
                        \ to the next page

 INC P+1                \ Increment the high byte of the destination address to
                        \ point to the next page

 DEX                    \ Decrement the page counter

 BNE MVBL               \ Loop back to copy the next page until we have done X
                        \ pages

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: MESS1
\       Type: Variable
\   Category: Loader
\    Summary: The OS command string for changing the disc directory to E
\
\ ******************************************************************************

.MESS1

                        \ --- Mod: Code removed for Elite-A: ------------------>

\EQUS "*DIR E"
\EQUB 13

                        \ --- And replaced by: -------------------------------->

 EQUS "DIR e"
 EQUB 13

                        \ --- End of replacement ------------------------------>

\ ******************************************************************************
\
\       Name: Elite loader (Part 2 of 3)
\       Type: Subroutine
\   Category: Loader
\    Summary: Include binaries for recursive tokens, Missile blueprint and
\             images
\
\ ------------------------------------------------------------------------------
\
\ The loader bundles a number of binary files in with the loader code, and moves
\ them to their correct memory locations in part 1 above.
\
\ There are two files containing code:
\
\   * WORDS.bin contains the recursive token table, which is moved to &0400
\     before the main game is loaded
\
\   * MISSILE.bin contains the missile ship blueprint, which gets moved to &7F00
\     before the main game is loaded
\
\ and one file containing an image, which is moved into screen memory by the
\ loader:
\
\   * P.DIALS.bin contains the dashboard, which gets moved to screen address
\     &7800, which is the starting point of the four-colour mode 5 portion at
\     the bottom of the split screen
\
\ There are three other image binaries bundled into the loader, which are
\ described in part 3 below.
\
\ ******************************************************************************

.DIALS

 INCBIN "1-source-files/images/P.DIALS.bin"

.SHIP_MISSILE

 INCBIN "3-assembled-output/MISSILE.bin"

.WORDS

 INCBIN "3-assembled-output/WORDS.bin"

\ ******************************************************************************
\
\       Name: TVT1code
\       Type: Subroutine
\   Category: Loader
\    Summary: Code block at &1100-&11E2 that remains resident in both docked and
\             flight mode (palettes, screen mode routine and commander data)
\
\ ******************************************************************************

.TVT1code

 ORG &1100              \ Set the assembly address to &1100

\ ******************************************************************************
\
\       Name: TVT1
\       Type: Variable
\   Category: Drawing the screen
\    Summary: Palette data for space and the two dashboard colour schemes
\
\ ------------------------------------------------------------------------------
\
\ Palette bytes for use with the split-screen mode (see IRQ1 below for more
\ details).
\
\ Palette data is given as a set of bytes, with each byte mapping a logical
\ colour to a physical one. In each byte, the logical colour is given in bits
\ 4-7 and the physical colour in bits 0-3. See page 379 of the "Advanced User
\ Guide for the BBC Micro" by Bray, Dickens and Holmes for details of how
\ palette mapping works, as in modes 4 and 5 we have to do multiple palette
\ commands to change the colours correctly, and the physical colour value is
\ EOR'd with 7, just to make things even more confusing.
\
\ Similarly, the palette at TVT1+16 is for the monochrome space view, where
\ logical colour 1 is mapped to physical colour 0 EOR 7 = 7 (white), and
\ logical colour 0 is mapped to physical colour 7 EOR 7 = 0 (black). Each of
\ these mappings requires six calls to SHEILA &21 - see page 379 of the
\ "Advanced User Guide for the BBC Micro" by Bray, Dickens and Holmes for an
\ explanation.
\
\ The mode 5 palette table has two blocks which overlap. The block used depends
\ on whether or not we have an escape pod fitted. The block at TVT1 is used for
\ the standard dashboard colours, while TVT1+8 is used for the dashboard when an
\ escape pod is fitted. The colours are as follows:
\
\                 Normal (TVT1)     Escape pod (TVT1+8)
\
\   Colour 0      Black             Black
\   Colour 1      Red               Red
\   Colour 2      Yellow            White
\   Colour 3      Green             Cyan
\
\ ******************************************************************************

.TVT1

 EQUB &D4, &C4          \ This block of palette data is used to create two
 EQUB &94, &84          \ palettes used in three different places, all of them
 EQUB &F5, &E5          \ redefining four colours in mode 5:
 EQUB &B5, &A5          \
                        \ 12 bytes from TVT1 (i.e. the first 6 rows): applied
 EQUB &76, &66          \ when the T1 timer runs down at the switch from the
 EQUB &36, &26          \ space view to the dashboard, so this is the standard
                        \ dashboard palette
 EQUB &E1, &F1          \
 EQUB &B1, &A1          \ 8 bytes from TVT1+8 (i.e. the last 4 rows): applied
                        \ when the T1 timer runs down at the switch from the
                        \ space view to the dashboard, and we have an escape
                        \ pod fitted, so this is the escape pod dashboard
                        \ palette
                        \
                        \ 8 bytes from TVT1+8 (i.e. the last 4 rows): applied
                        \ at vertical sync in LINSCN when HFX is non-zero, to
                        \ create the hyperspace effect in LINSCN (where the
                        \ whole screen is switched to mode 5 at vertical sync)

 EQUB &F0, &E0          \ 12 bytes of palette data at TVT1+16, used to set the
 EQUB &B0, &A0          \ mode 4 palette in LINSCN when we hit vertical sync,
 EQUB &D0, &C0          \ so the palette is set to monochrome when we start to
 EQUB &90, &80          \ draw the first row of the screen
 EQUB &77, &67
 EQUB &37, &27

\ ******************************************************************************
\
\       Name: IRQ1
\       Type: Subroutine
\   Category: Drawing the screen
\    Summary: The main screen-mode interrupt handler (IRQ1V points here)
\  Deep dive: The split-screen mode in BBC Micro Elite
\
\ ------------------------------------------------------------------------------
\
\ The main interrupt handler, which implements Elite's split-screen mode.
\
\ IRQ1V is set to point to IRQ1 by the loading process.
\
\ ******************************************************************************

.LINSCN

                        \ This is called from the interrupt handler below, at
                        \ the start of each vertical sync (i.e. when the screen
                        \ refresh starts)

 LDA #30                \ Set the line scan counter to a non-zero value, so
 STA DL                 \ routines like WSCAN can set DL to 0 and then wait for
                        \ it to change to non-zero to catch the vertical sync

 STA VIA+&44            \ Set 6522 System VIA T1C-L timer 1 low-order counter
                        \ (SHEILA &44) to 30

 LDA #VSCAN             \ Set 6522 System VIA T1C-L timer 1 high-order counter
 STA VIA+&45            \ (SHEILA &45) to VSCAN (57) to start the T1 counter
                        \ counting down from 14622 at a rate of 1 MHz

 LDA HFX                \ If HFX is non-zero, jump to VNT1 to set the mode 5
 BNE VNT1               \ palette instead of switching to mode 4, which will
                        \ have the effect of blurring and colouring the top
                        \ screen. This is how the white hyperspace rings turn
                        \ to colour when we do a hyperspace jump, and is
                        \ triggered by setting HFX to 1 in routine LL164

 LDA #%00001000         \ Set the Video ULA control register (SHEILA &20) to
 STA VIA+&20            \ %00001000, which is the same as switching to mode 4
                        \ (i.e. the top part of the screen) but with no cursor

.VNT3

 LDA TVT1+16,Y          \ Copy the Y-th palette byte from TVT1+16 to SHEILA &21
 STA VIA+&21            \ to map logical to actual colours for the bottom part
                        \ of the screen (i.e. the dashboard)

 DEY                    \ Decrement the palette byte counter

 BPL VNT3               \ Loop back to VNT3 until we have copied all the
                        \ palette bytes

 LDA LASCT              \ Decrement the value of LASCT, but if we go too far
 BEQ P%+5               \ and it becomes negative, bump it back up again (this
 DEC LASCT              \ controls the pulsing of pulse lasers)

 PLA                    \ Otherwise restore Y from the stack
 TAY

 LDA VIA+&41            \ Read 6522 System VIA input register IRA (SHEILA &41)

 LDA &FC                \ Set A to the interrupt accumulator save register,
                        \ which restores A to the value it had on entering the
                        \ interrupt

 RTI                    \ Return from interrupts, so this interrupt is not
                        \ passed on to the next interrupt handler, but instead
                        \ the interrupt terminates here

.IRQ1

 TYA                    \ Store Y on the stack
 PHA

 LDY #11                \ Set Y as a counter for 12 bytes, to use when setting
                        \ the dashboard palette below

 LDA #%00000010         \ Read the 6522 System VIA status byte bit 1 (SHEILA
 BIT VIA+&4D            \ &4D), which is set if vertical sync has occurred on
                        \ the video system

 BNE LINSCN             \ If we are on the vertical sync pulse, jump to LINSCN
                        \ to set up the timers to enable us to switch the
                        \ screen mode between the space view and dashboard

 BVC jvec               \ Read the 6522 System VIA status byte bit 6, which is
                        \ set if timer 1 has timed out. We set the timer in
                        \ LINSCN above, so this means we only run the next bit
                        \ if the screen redraw has reached the boundary between
                        \ the space view and the dashboard. Otherwise bit 6 is
                        \ clear and we aren't at the boundary, so we jump to
                        \ jvec to pass control to the next interrupt handler

 ASL A                  \ Double the value in A to 4

 STA VIA+&20            \ Set the Video ULA control register (SHEILA &20) to
                        \ %00000100, which is the same as switching to mode 5,
                        \ (i.e. the bottom part of the screen) but with no
                        \ cursor

 LDA ESCP               \ If an escape pod is fitted, jump to VNT1 to set the
 BNE VNT1               \ mode 5 palette differently (so the dashboard is a
                        \ different colour if we have an escape pod)

 LDA TVT1,Y             \ Copy the Y-th palette byte from TVT1 to SHEILA &21
 STA VIA+&21            \ to map logical to actual colours for the bottom part
                        \ of the screen (i.e. the dashboard)

 DEY                    \ Decrement the palette byte counter

 BPL P%-7               \ Loop back to the LDA TVT1,Y instruction until we have
                        \ copied all the palette bytes

.jvec

 PLA                    \ Restore Y from the stack
 TAY

 JMP (VEC)              \ Jump to the address in VEC, which was set to the
                        \ original IRQ1V vector by the loading process, so this
                        \ instruction passes control to the next interrupt
                        \ handler

.VNT1

 LDY #7                 \ Set Y as a counter for 8 bytes

 LDA TVT1+8,Y           \ Copy the Y-th palette byte from TVT1+8 to SHEILA &21
 STA VIA+&21            \ to map logical to actual colours for the bottom part
                        \ of the screen (i.e. the dashboard)

 DEY                    \ Decrement the palette byte counter

 BPL VNT1+2             \ Loop back to the LDA TVT1+8,Y instruction until we
                        \ have copied all the palette bytes

 BMI jvec               \ Jump up to jvec to pass control to the next interrupt
                        \ handler (this BMI is effectively a JMP as we didn't
                        \ loop back with the BPL above, so BMI is always true)

\ ******************************************************************************
\
\       Name: S1%
\       Type: Variable
\   Category: Save and load
\    Summary: The drive and directory number used when saving or loading a
\             commander file
\  Deep dive: Commander save files
\
\ ------------------------------------------------------------------------------
\
\ The drive part of this string (the "0") is updated with the chosen drive in
\ the GTNMEW routine, but the directory part (the "E") is fixed. The variable
\ is followed directly by the commander file at NA%, which starts with the
\ commander name, so the full string at S1% is in the format ":0.E.JAMESON",
\ which gives the full filename of the commander file.
\
\ ******************************************************************************

.S1%

 EQUS ":0.E."

\ ******************************************************************************
\
\       Name: NA%
\       Type: Variable
\   Category: Save and load
\    Summary: The data block for the last saved commander
\  Deep dive: Commander save files
\             The competition code
\
\ ------------------------------------------------------------------------------
\
\ Contains the last saved commander data, with the name at NA% and the data at
\ NA%+8 onwards. The size of the data block is given in NT% (which also includes
\ the two checksum bytes that follow this block). This block is initially set up
\ with the default commander, which can be maxed out for testing purposes by
\ setting Q% to TRUE.
\
\ The commander's name is stored at NA%, and can be up to 7 characters long
\ (the DFS filename limit). It is terminated with a carriage return character,
\ ASCII 13.
\
\ The offset of each byte within a saved commander file is also shown as #0, #1
\ and so on, so the kill tally, for example, is in bytes #71 and #72 of the
\ saved file. The related variable name from the current commander block is
\ also shown.
\
\ ******************************************************************************

.NA%

                        \ --- Mod: Code removed for Elite-A: ------------------>

\EQUS "JAMESON"         \ The current commander name, which defaults to JAMESON
\EQUB 13                \
\                       \ The commander name can be up to seven characters (the
\                       \ DFS limit for filenames), and is terminated by a
\                       \ carriage return

                        \ --- And replaced by: -------------------------------->

 EQUS "NEWCOME"         \ The current commander name, which defaults to NEWCOME
 EQUB 13                \
                        \ The commander name can be up to seven characters (the
                        \ DFS limit for filenames), and is terminated by a
                        \ carriage return

                        \ --- End of replacement ------------------------------>

                        \ NA%+8 is the start of the commander data block
                        \
                        \ This block contains the last saved commander data
                        \ block. As the game is played it uses an identical
                        \ block at location TP to store the current commander
                        \ state, and that block is copied here when the game is
                        \ saved. Conversely, when the game starts up, the block
                        \ here is copied to TP, which restores the last saved
                        \ commander when we die
                        \
                        \ The initial state of this block defines the default
                        \ commander. Q% can be set to TRUE to give the default
                        \ commander lots of credits and equipment

 EQUB 0                 \ TP = Mission status, #0

 EQUB 20                \ QQ0 = Current system X-coordinate (Lave), #1
 EQUB 173               \ QQ1 = Current system Y-coordinate (Lave), #2

 EQUW &5A4A             \ QQ21 = Seed s0 for system 0, galaxy 0 (Tibedied), #3-4
 EQUW &0248             \ QQ21 = Seed s1 for system 0, galaxy 0 (Tibedied), #5-6
 EQUW &B753             \ QQ21 = Seed s2 for system 0, galaxy 0 (Tibedied), #7-8

                        \ --- Mod: Code removed for Elite-A: ------------------>

\IF Q%
\EQUD &00CA9A3B         \ CASH = Amount of cash (100,000,000 Cr), #9-12
\ELSE
\EQUD &E8030000         \ CASH = Amount of cash (100 Cr), #9-12
\ENDIF
\
\EQUB 70                \ QQ14 = Fuel level, #13

                        \ --- And replaced by: -------------------------------->

IF Q%
 EQUD &00CA9A3B         \ CASH = Amount of cash (100,000,000 Cr), #9-12
ELSE
 EQUD &88130000         \ CASH = Amount of cash (500 Cr), #9-12
ENDIF

 EQUB 60 + (15 AND Q%)  \ QQ14 = Fuel level, #13

                        \ --- End of replacement ------------------------------>

 EQUB 0                 \ COK = Competition flags, #14

 EQUB 0                 \ GCNT = Galaxy number, 0-7, #15

                        \ --- Mod: Code removed for Elite-A: ------------------>

\EQUB POW+(128 AND Q%)  \ LASER = Front laser, #16
\
\EQUB (POW+128) AND Q%  \ LASER+1 = Rear laser, #17
\
\EQUB 0                 \ LASER+2 = Left laser, #18
\
\EQUB 0                 \ LASER+3 = Right laser, #19
\
\EQUW 0                 \ These bytes appear to be unused (they were originally
\                       \ used for up/down lasers, but they were dropped),
\                       \ #20-21
\
\EQUB 22 + (15 AND Q%)  \ CRGO = Cargo capacity, #22

                        \ --- And replaced by: -------------------------------->

 EQUB &9C AND Q%        \ LASER = Front laser, #16

 EQUB &9C AND Q%        \ LASER+1 = Rear laser, #17

 EQUB 0                 \ LASER+2 = Left laser, #18

 EQUB 0                 \ LASER+3 = Right laser, #19

 EQUB 0                 \ This byte appears to be unused, #20

 EQUB 8 AND Q%          \ cmdr_type = Type of our current ship, #21

 EQUB Q%                \ CRGO = I.F.F. system, #22

                        \ --- End of replacement ------------------------------>

 EQUB 0                 \ QQ20+0  = Amount of food in cargo hold, #23
 EQUB 0                 \ QQ20+1  = Amount of textiles in cargo hold, #24
 EQUB 0                 \ QQ20+2  = Amount of radioactives in cargo hold, #25
 EQUB 0                 \ QQ20+3  = Amount of slaves in cargo hold, #26
 EQUB 0                 \ QQ20+4  = Amount of liquor/Wines in cargo hold, #27
 EQUB 0                 \ QQ20+5  = Amount of luxuries in cargo hold, #28
 EQUB 0                 \ QQ20+6  = Amount of narcotics in cargo hold, #29
 EQUB 0                 \ QQ20+7  = Amount of computers in cargo hold, #30
 EQUB 0                 \ QQ20+8  = Amount of machinery in cargo hold, #31
 EQUB 0                 \ QQ20+9  = Amount of alloys in cargo hold, #32
 EQUB 0                 \ QQ20+10 = Amount of firearms in cargo hold, #33
 EQUB 0                 \ QQ20+11 = Amount of furs in cargo hold, #34
 EQUB 0                 \ QQ20+12 = Amount of minerals in cargo hold, #35
 EQUB 0                 \ QQ20+13 = Amount of gold in cargo hold, #36
 EQUB 0                 \ QQ20+14 = Amount of platinum in cargo hold, #37
 EQUB 0                 \ QQ20+15 = Amount of gem-stones in cargo hold, #38
 EQUB 0                 \ QQ20+16 = Amount of alien items in cargo hold, #39

 EQUB Q%                \ ECM = E.C.M. system, #40

 EQUB Q%                \ BST = Fuel scoops ("barrel status"), #41

                        \ --- Mod: Code removed for Elite-A: ------------------>

\EQUB Q% AND 127        \ BOMB = Energy bomb, #42

                        \ --- And replaced by: -------------------------------->

 EQUB Q%                \ BOMB = Hyperspace unit, #42

                        \ --- End of replacement ------------------------------>

 EQUB Q% AND 1          \ ENGY = Energy/shield level, #43

 EQUB Q%                \ DKCMP = Docking computer, #44

 EQUB Q%                \ GHYP = Galactic hyperdrive, #45

 EQUB Q%                \ ESCP = Escape pod, #46

                        \ --- Mod: Code removed for Elite-A: ------------------>

\EQUD 0                 \ These four bytes appear to be unused, #47-50
\
\EQUB 3 + (Q% AND 1)    \ NOMSL = Number of missiles, #51

                        \ --- And replaced by: -------------------------------->

 EQUW 0                 \ cmdr_cour = Special cargo mission timer, #47

 EQUB 0                 \ cmdr_courx = Special cargo destination x-coord, #49

 EQUB 0                 \ cmdr_coury = Special cargo destination y-coord, #50

 EQUB 0                 \ NOMSL = Number of missiles, #51

                        \ --- End of replacement ------------------------------>

 EQUB 0                 \ FIST = Legal status ("fugitive/innocent status"), #52

                        \ --- Mod: Code removed for Elite-A: ------------------>

\EQUB 16                \ AVL+0  = Market availability of food, #53

                        \ --- And replaced by: -------------------------------->

 EQUB 0                 \ AVL+0  = Market availability of food, #53

                        \ --- End of replacement ------------------------------>

 EQUB 15                \ AVL+1  = Market availability of textiles, #54
 EQUB 17                \ AVL+2  = Market availability of radioactives, #55
 EQUB 0                 \ AVL+3  = Market availability of slaves, #56
 EQUB 3                 \ AVL+4  = Market availability of liquor/Wines, #57
 EQUB 28                \ AVL+5  = Market availability of luxuries, #58
 EQUB 14                \ AVL+6  = Market availability of narcotics, #59
 EQUB 0                 \ AVL+7  = Market availability of computers, #60
 EQUB 0                 \ AVL+8  = Market availability of machinery, #61
 EQUB 10                \ AVL+9  = Market availability of alloys, #62
 EQUB 0                 \ AVL+10 = Market availability of firearms, #63
 EQUB 17                \ AVL+11 = Market availability of furs, #64
 EQUB 58                \ AVL+12 = Market availability of minerals, #65
 EQUB 7                 \ AVL+13 = Market availability of gold, #66
 EQUB 9                 \ AVL+14 = Market availability of platinum, #67
 EQUB 8                 \ AVL+15 = Market availability of gem-stones, #68
 EQUB 0                 \ AVL+16 = Market availability of alien items, #69

 EQUB 0                 \ QQ26 = Random byte that changes for each visit to a
                        \ system, for randomising market prices, #70

 EQUW 0                 \ TALLY = Number of kills, #71-72

                        \ --- Mod: Code removed for Elite-A: ------------------>

\EQUB 128               \ SVC = Save count, #73

                        \ --- And replaced by: -------------------------------->

 EQUB 32                \ SVC = Save count, #73

                        \ --- End of replacement ------------------------------>

\ ******************************************************************************
\
\       Name: CHK2
\       Type: Variable
\   Category: Save and load
\    Summary: Second checksum byte for the saved commander data file
\  Deep dive: Commander save files
\             The competition code
\
\ ------------------------------------------------------------------------------
\
\ Second commander checksum byte. If the default commander is changed, a new
\ checksum will be calculated and inserted by the elite-checksum.py script.
\
\ The offset of this byte within a saved commander file is also shown (it's at
\ byte #74).
\
\ ******************************************************************************

.CHK2

                        \ --- Mod: Code removed for Elite-A: ------------------>

\EQUB &03 EOR &A9       \ The checksum value for the default commander, EOR'd
\                       \ with &A9 to make it harder to tamper with the checksum
\                       \ byte, #74

                        \ --- And replaced by: -------------------------------->

 EQUB &58 EOR &A9       \ The checksum value for the default commander, EOR'd
                        \ with &A9 to make it harder to tamper with the checksum
                        \ byte, #74

                        \ --- End of replacement ------------------------------>

\ ******************************************************************************
\
\       Name: CHK
\       Type: Variable
\   Category: Save and load
\    Summary: First checksum byte for the saved commander data file
\  Deep dive: Commander save files
\             The competition code
\
\ ------------------------------------------------------------------------------
\
\ Commander checksum byte. If the default commander is changed, a new checksum
\ will be calculated and inserted by the elite-checksum.py script.
\
\ The offset of this byte within a saved commander file is also shown (it's at
\ byte #75).
\
\ ******************************************************************************

.CHK

                        \ --- Mod: Code removed for Elite-A: ------------------>

\EQUB &03               \ The checksum value for the default commander, #75

                        \ --- And replaced by: -------------------------------->

 EQUB &58               \ The checksum value for the default commander, #75

                        \ --- End of replacement ------------------------------>

\ ******************************************************************************
\
\       Name: BRBR1
\       Type: Subroutine
\   Category: Loader
\    Summary: Loader break handler: print a newline and the error message, and
\             then hang the computer
\  Deep dive: Swapping between the docked and flight code
\
\ ------------------------------------------------------------------------------
\
\ This break handler is used during loading and during flight, and is resident
\ in memory throughout the game's lifecycle. The docked code loads its own
\ break handler and overrides this one until the flight code is run.
\
\ The main difference between the two handlers is that this one display the
\ error and then hangs, while the docked code displays the error and returns.
\ This is because the docked code has to cope gracefully with errors from the
\ disc access menu (such as "File not found"), which we obviously don't want to
\ terminate the game.
\
\ ******************************************************************************

.BRBR1

                        \ The following loop prints out the null-terminated
                        \ message pointed to by (&FD &FE), which is the MOS
                        \ error message pointer - so this prints the error
                        \ message on the next line

 LDY #0                 \ Set Y = 0 to act as a character counter

 LDA #13                \ Set A = 13 so the first character printed is a
                        \ carriage return

.BRBRLOOP

 JSR OSWRCH             \ Print the character in A (which contains a carriage
                        \ return on the first loop iteration), and then any
                        \ characters we fetch from the error message

 INY                    \ Increment the loop counter

 LDA (&FD),Y            \ Fetch the Y-th byte of the block pointed to by
                        \ (&FD &FE), so that's the Y-th character of the message
                        \ pointed to by the MOS error message pointer

 BNE BRBRLOOP           \ If the fetched character is non-zero, loop back to the
                        \ JSR OSWRCH above to print the it, and keep looping
                        \ until we fetch a zero (which marks the end of the
                        \ message)

 BEQ P%                 \ Hang the computer as something has gone wrong

                        \ --- Mod: Code removed for Elite-A: ------------------>

\EQUB &64, &5F, &61     \ These bytes appear to be unused
\EQUB &74, &74, &72
\EQUB &69, &62, &75
\EQUB &74, &65, &73
\EQUB &00, &C4, &24
\EQUB &6A, &43, &67
\EQUB &65, &74, &72
\EQUB &64, &69, &73
\EQUB &63, &00, &B6
\EQUB &3C, &C6

                        \ --- End of removed code ----------------------------->

 COPYBLOCK TVT1, P%, TVT1code

 ORG TVT1code + P% - TVT1

\ ******************************************************************************
\
\       Name: Elite loader (Part 3 of 3)
\       Type: Subroutine
\   Category: Loader
\    Summary: Include binaries for the loading screen images
\
\ ------------------------------------------------------------------------------
\
\ The loader bundles a number of binary files in with the loader code, and moves
\ them to their correct memory locations in part 1 above.
\
\ This part includes three files containing images, which are all moved into
\ screen memory by the loader:
\
\   * P.A-SOFT.bin contains the "ACORNSOFT" title across the top of the loading
\     screen, which gets moved to screen address &6100, on the second character
\     row of the monochrome mode 4 screen
\
\   * P.ELITE.bin contains the "ELITE" title across the top of the loading
\     screen, which gets moved to screen address &6300, on the fourth character
\     row of the monochrome mode 4 screen
\
\   * P.(C)ASFT.bin contains the "(C) Acornsoft 1984" title across the bottom
\     of the loading screen, which gets moved to screen address &7600, the
\     penultimate character row of the monochrome mode 4 screen, just above the
\     dashboard
\
\ There are three other binaries bundled into the loader, which are described in
\ part 2 above.
\
\ ******************************************************************************

.ELITE

 INCBIN "1-source-files/images/P.ELITE.bin"

.ASOFT

 INCBIN "1-source-files/images/P.A-SOFT.bin"

.CpASOFT

 INCBIN "1-source-files/images/P.(C)ASFT.bin"

\ ******************************************************************************
\
\       Name: to_dd00
\       Type: Subroutine
\   Category: Loader
\    Summary: BBC Master code for saving and restoring the MOS character set,
\             bundled up in the loader so it can be moved to &DD00 to be run
\
\ ******************************************************************************

 CPU 1

.to_dd00

 ORG &DD00              \ Set the assembly address to &DD00

\ ******************************************************************************
\
\       Name: do_FILEV
\       Type: Subroutine
\   Category: Loader
\    Summary: The custom handler for OSFILE calls in the BBC Master version
\
\ ******************************************************************************

                        \ --- Mod: Code added for Elite-A: -------------------->

.do_FILEV

 JSR restorews          \ Call restorews to restore the filing system workspace,
                        \ so we can use the filing system

.old_FILEV

 JSR &100               \ This address is modified by the Master-specific code
                        \ in part 1 of the loader (just after the cpmaster
                        \ loop), so it calls the existing FILEV handler

                        \ Fall through into savews to save the filing system
                        \ workspace in a safe place and replace it with the MOS
                        \ character set, so that character printing will work
                        \ once again

                        \ --- End of added code ------------------------------->

\ ******************************************************************************
\
\       Name: savews
\       Type: Subroutine
\   Category: Loader
\    Summary: Save the filing system workspace in a safe place and replace it
\             with the MOS character set
\
\ ******************************************************************************

                        \ --- Mod: Code added for Elite-A: -------------------->

.savews

 PHP                    \ Store the status register, A, X and Y on the stack, so
 PHA                    \ we can retrieve them later to preserve them across
 PHX                    \ calls to the subroutine
 PHY

IF _BUG_FIX

 BIT wsstate            \ If bit 7 of wsstate is set then the filing system
 BMI saverts            \ workspace is already in its safe place, so jump to
                        \ saverts so we don't save it again

ENDIF

                        \ --- End of added code ------------------------------->

 LDA #%00001000         \ Set bit 3 of the Access Control Register at SHEILA &34
 TSB VIA+&34            \ to map the filing system RAM space into &C000-&DFFF
                        \ (HAZEL), in place of the MOS VDU workspace (the TSB
                        \ instruction applies the accumulator to the memory
                        \ location using an OR)

                        \ We now want to copy the first three pages from &C000
                        \ to the safe place that we obtained in the loader, and
                        \ whose location we poked directly into the put0, put1
                        \ and put2 instructions below, back in part 1 of the
                        \ loader

 LDX #0                 \ Set a byte counter in X so we can copy an entire page
                        \ of bytes, starting from 0

.putws

 LDA &C000,X            \ Fetch the X-th byte from the first page of the &C000
                        \ workspace

.put0

 STA &C000,X            \ This address is modified by the Master-specific code
                        \ in part 1 of the loader (just after the cpmaster
                        \ loop), so it points to the first page of the safe
                        \ place where we can copy the filing system workspace

 LDA &C100,X            \ Fetch the X-th byte from the second page of the &C000
                        \ workspace (i.e. &C100)

.put1

 STA &C100,X            \ This address is modified by the Master-specific code
                        \ in part 1 of the loader (just after the cpmaster
                        \ loop), so it points to the second page of the safe
                        \ place where we can copy the filing system workspace

 LDA &C200,X            \ Fetch the X-th byte from the third page of the &C000
                        \ workspace (i.e. &C200)

.put2

 STA &C200,X            \ This address is modified by the Master-specific code
                        \ in part 1 of the loader (just after the cpmaster
                        \ loop), so it points to the third page of the safe
                        \ place where we can copy the filing system workspace

 INX                    \ Increment the byte counter

 BNE putws              \ Loop back until we have copied a whole page of bytes
                        \ (three times)

 LDA LATCH              \ Fetch the RAM copy of the currently selected paged ROM
 PHA                    \ from LATCH and save it on the stack so we can restore
                        \ it below

 LDA #%10000000         \ Set the RAM copy of the currently selected paged ROM
 STA LATCH              \ so it matches the paged ROM selection latch at SHEILA
                        \ &30 that we are about to set

 STA VIA+&30            \ Set bit 7 of the ROM Select latch at SHEILA &30, to
                        \ map the MOS ROM to &8000-&8FFF in RAM (ANDY)

                        \ We now want to copy the three pages of MOS character
                        \ definitions from the MOS ROM to &C000, so the
                        \ character printing routines can use them

 LDX #0                 \ Set a byte counter in X so we can copy an entire page
                        \ of bytes, starting from 0

.copych

 LDA &8900,X            \ Copy the X-th byte of the first page of MOS character
 STA &C000,X            \ definitions at &8900 into the X-th byte of &C000

 LDA &8A00,X            \ Copy the X-th byte of the second page of MOS character
 STA &C100,X            \ definitions at &8A00 into the X-th byte of &C100

 LDA &8B00,X            \ Copy the X-th byte of the third page of MOS character
 STA &C200,X            \ definitions at &8B00 into the X-th byte of &C100

 INX                    \ Increment the byte counter

 BNE copych             \ Loop back until we have copied a whole page of bytes
                        \ (three times)

 PLA                    \ Restore the paged ROM number that we saved on the
 STA LATCH              \ stack and store it in LATCH so it matches the paged
                        \ ROM selection latch at SHEILA &30 that we are about
                        \ to set

 STA VIA+&30            \ Store the same value in SHEILA &30, to switch back to
                        \ the ROM that was selected before we changed it above

                        \ --- Mod: Code added for Elite-A: -------------------->

IF _BUG_FIX

 LDA #%10000000         \ Clear bit 7 of wsstate to denote that we have saved
 STA wsstate            \ the filing system workspace

.saverts

ENDIF

                        \ --- End of added code ------------------------------->

 PLY                    \ Restore the status register, A, X and Y from the
 PLX                    \ stack, so they are preserved by the subroutine
 PLA
 PLP

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: do_FSCV
\       Type: Subroutine
\   Category: Loader
\    Summary: The custom handler for filing system calls in the BBC Master
\             version
\
\ ******************************************************************************

                        \ --- Mod: Code added for Elite-A: -------------------->

.do_FSCV

 JSR restorews          \ Call restorews to restore the filing system workspace,
                        \ so we can use the filing system

.old_FSCV

 JSR &100               \ This address is modified by the Master-specific code
                        \ in part 1 of the loader (just after the cpmaster
                        \ loop), so it calls the existing FSCV handler

 JMP savews             \ Call savews to save the filing system workspace in a
                        \ safe place and replace it with the MOS character set,
                        \ so that character printing will work once again

                        \ --- End of added code ------------------------------->

\ ******************************************************************************
\
\       Name: restorews
\       Type: Subroutine
\   Category: Loader
\    Summary: Restore the filing system workspace
\
\ ******************************************************************************

                        \ --- Mod: Code added for Elite-A: -------------------->

.restorews

 PHA                    \ Store A and X on the stack, so we can retrieve them
 PHX                    \ later to preserve them across calls to the subroutine

IF _BUG_FIX

 BIT wsstate            \ If bit 7 of wsstate is clear then the filing system
 BPL restorerts         \ workspace is already restored, so jump to restorerts
                        \ so we don't restore it again

ENDIF

                        \ We now want to copy the first three pages from the
                        \ safe place back to &C00), reversing the copy that we
                        \ did in savews. As with savews, the location of the
                        \ safe place was poked directly into the get0, get1 and
                        \ get2 instructions below, back in part 1 of the loader

 LDX #0                 \ Set a byte counter in X so we can copy an entire page
                        \ of bytes, starting from 0

.getws

.get0

 LDA &C000,X            \ This address is modified by the Master-specific code
                        \ in part 1 of the loader (just after the cpmaster
                        \ loop), so it points to the first page of the safe
                        \ place where we copied the filing system workspace in
                        \ the savews routine

 STA &C000,X            \ Copy the X-th byte from the first page of the safe
                        \ place to the X-th byte of the first page of the &C000
                        \ block

.get1

 LDA &C100,X            \ This address is modified by the Master-specific code
                        \ in part 1 of the loader (just after the cpmaster
                        \ loop), so it points to the second page of the safe
                        \ place where we copied the filing system workspace in
                        \ the savews routine

 STA &C100,X            \ Copy the X-th byte from the second page of the safe
                        \ place to the X-th byte of the second page of the &C000
                        \ block (i.e. &C100)

.get2

 LDA &C200,X            \ This address is modified by the Master-specific code
                        \ in part 1 of the loader (just after the cpmaster
                        \ loop), so it points to the third page of the safe
                        \ place where we copied the filing system workspace in
                        \ the savews routine

 STA &C200,X            \ Copy the X-th byte from the third page of the safe
                        \ place to the X-th byte of the third page of the &C000
                        \ block (i.e. &C200)

 INX                    \ Increment the byte counter

 BNE getws              \ Loop back until we have copied a whole page of bytes
                        \ (three times)

IF _BUG_FIX

 STZ wsstate            \ Clear bit 7 of wsstate to denote that we have restored
                        \ the filing system workspace

.restorerts

ENDIF

 PLX                    \ Retore A and X from the stack, so they are preserved
 PLA                    \ by the subroutine

 RTS                    \ Return from the subroutine

                        \ --- End of added code ------------------------------->

\ ******************************************************************************
\
\       Name: do_BYTEV
\       Type: Subroutine
\   Category: Loader
\    Summary: The custom handler for OSBYTE calls in the BBC Master version
\
\ ******************************************************************************

                        \ --- Mod: Code added for Elite-A: -------------------->

.do_BYTEV

 CMP #143               \ If this is not OSBYTE 143, the paged ROM service call,
 BNE old_BYTEV          \ then jump to old_BYTEV to pass the call onto the
                        \ default handler

 CPX #&F                \ If the value of X is not &F ("vectors changed"), jump
 BNE old_BYTEV          \ to old_BYTEV to pass the call onto the default
                        \ handler

 JSR old_BYTEV          \ This is OSBYTE 143 with X = &F (the "vectors changed"
                        \ service call), so first of all call old_BYTEV so the
                        \ service call can be processed by the default handler

                        \ And then fall through into set_vectors to set the
                        \ FILEV, FSCV and BYTEV vectors to point to our custom
                        \ handlers

                        \ --- End of added code ------------------------------->

\ ******************************************************************************
\
\       Name: set_vectors
\       Type: Subroutine
\   Category: Loader
\    Summary: Set the FILEV, FSCV and BYTEV vectors to point to our custom
\             handlers
\
\ ******************************************************************************

                        \ --- Mod: Code added for Elite-A: -------------------->

.set_vectors

 SEI                    \ Disable interrupts while we update the vectors

 PHA                    \ Store A on the stack so we can retrieve it below

 LDA #LO(do_FILEV)      \ Set the FILEV to point to our custom handler in
 STA FILEV              \ do_FILEV
 LDA #HI(do_FILEV)
 STA FILEV+1

 LDA #LO(do_FSCV)       \ Set the FSCV to point to our custom handler in
 STA FSCV               \ do_FSCV
 LDA #HI(do_FSCV)
 STA FSCV+1

 LDA #LO(do_BYTEV)      \ Set the BYTEV to point to our custom handler in
 STA BYTEV              \ do_BYTEV
 LDA #HI(do_BYTEV)
 STA BYTEV+1

 PLA                    \ Restore A from the stack, so the subroutine doesn't
                        \ change its value

 CLI                    \ Enable interrupts again

 RTS                    \ Return from the subroutine

                        \ --- End of added code ------------------------------->

\ ******************************************************************************
\
\       Name: old_BYTEV
\       Type: Subroutine
\   Category: Loader
\    Summary: Call the default OSBYTE handler
\
\ ******************************************************************************

                        \ --- Mod: Code added for Elite-A: -------------------->

.old_BYTEV

 JMP &100               \ This address is modified by the Master-specific code
                        \ in part 1 of the loader (just after the cpmaster
                        \ loop), so it calls the existing BYTEV handler and
                        \ returns from the subroutine using a tail call

                        \ --- End of added code ------------------------------->

\ ******************************************************************************
\
\       Name: wsstate
\       Type: Variable
\   Category: Utility routines
\    Summary: Flag to keep track of whether we have saved or restored the filing
\             system workspace
\
\ ******************************************************************************

                        \ --- Mod: Code added for Elite-A: -------------------->

IF _BUG_FIX

.wsstate

 EQUB 0                 \ Bit 7 determines the state of the filing system
                        \ workspace and MOS character definitions:
                        \
                        \   * Clear = filing system workspace restored to &C000
                        \             so it is safe to do file operations
                        \
                        \   * Set = filing system workspace saved to safe place
                        \           and replaced by MOS character definitions
                        \           at &C000

ENDIF

                        \ --- End of added code ------------------------------->

 dd00_len = P% - do_FILEV

 COPYBLOCK do_FILEV, P%, to_dd00

 ORG to_dd00 + P% - do_FILEV

\ ******************************************************************************
\
\ Save ELITE.bin
\
\ ******************************************************************************

 PRINT "S.ELITE ", ~CODE%, " ", ~P%, " ", ~LOAD%, " ", ~LOAD%
 SAVE "3-assembled-output/ELITE.bin", CODE%, P%, LOAD%

 PRINT "Addresses for the scramble routines in elite-checksum.py"
 PRINT "Load address = ", ~CODE%
 PRINT "TVT1code = ", ~TVT1code
 PRINT "ELITE = ", ~ELITE
 PRINT "LOADcode = ", ~LOADcode
 PRINT "DIALS = ", ~DIALS
 PRINT "ELITE = ", ~ELITE
 PRINT "End of ELITE4 file = ", ~P%
 PRINT "TVT1code = ", ~TVT1code
 PRINT "TVT1 = ", ~TVT1
 PRINT "NA% = ", ~NA%
 PRINT "CHK2 = ", ~CHK2
