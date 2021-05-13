
.beep_wait

 JSR sound_20
 LDY #&32
 JMP y_sync

.snap_cursor

 JSR map_cursor
 JSR snap_hype
 JSR map_cursor
 JMP clr_line

.write_planet

 LDX #&05

.l_311b

 LDA &6C,X
 STA &73,X
 DEX
 BPL l_311b
 LDY #&03
 BIT &6C
 BVS l_3129
 DEY

.l_3129

 STY &D1

.l_312b

 LDA &71
 AND #&1F
 BEQ l_3136
 ORA #&80
 JSR de_token

.l_3136

 JSR permute_1
 DEC &D1
 BPL l_312b
 LDX #&05

.l_313f

 LDA &73,X
 STA &6C,X
 DEX
 BPL l_313f
 RTS

.write_cmdr

 JSR set_upprmsk
 LDY #&00

.l_314c

 LDA &1181,Y
 CMP #&0D
 BEQ l_3159
 JSR punctuate
 INY
 BNE l_314c

.l_3159

 RTS

.l_315a

 JSR l_3160
 JSR write_planet

.l_3160

 LDX #&05

.l_3162

 LDA &6C,X
 LDY &03B2,X
 STA &03B2,X
 STY &6C,X
 DEX
 BPL l_3162
 RTS

.l_3170

 CLC
 LDX cmdr_galxy
 INX
 JMP writed_3

.show_fuel

 LDA #&69
 JSR pre_colon
 LDX cmdr_fuel
 SEC
 JSR writed_3
 LDA #&C3
 JSR de_tokln
 LDA #&77
 BNE de_token

.show_money

 LDX #&03

.l_318f

 LDA cmdr_money,X
 STA &40,X
 DEX
 BPL l_318f
 LDA #&09
 STA &80
 SEC
 JSR l_1bd0
 LDA #&E2

.de_tokln

 JSR de_token
 JMP new_line

.pre_colon

 JSR de_token

.l_31aa

 LDA #&3A

.de_token

 TAX
 BEQ show_money
 BMI l_3225
 DEX
 BEQ l_3170
 DEX
 BEQ l_315a
 DEX
 BNE l_31bd
 JMP write_planet

.l_31bd

 DEX
 BEQ write_cmdr
 DEX
 BEQ show_fuel
 DEX
 BNE l_31cb
 LDA #&80
 STA vdu_stat
 RTS

.l_31cb

 DEX
 DEX
 BNE l_31d2
 STX vdu_stat
 RTS

.l_31d2

 DEX
 BEQ l_320d
 CMP #&60
 BCS l_323f
 CMP #&0E
 BCC l_31e1
 CMP #&20
 BCC l_3209

.l_31e1

 LDX vdu_stat
 BEQ l_3222
 BMI l_31f8
 BIT vdu_stat
 BVS l_321b

.l_31eb

 CMP #&41
 BCC l_31f5
 CMP #&5B
 BCS l_31f5
 ADC #&20

.l_31f5

 JMP punctuate

.l_31f8

 BIT vdu_stat
 BVS l_3213
 CMP #&41
 BCC l_3222
 PHA
 TXA
 ORA #&40
 STA vdu_stat
 PLA
 BNE l_31f5

.l_3209

 ADC #&72
 BNE l_323f

.l_320d

 LDA #&15
 STA cursor_x
 BNE l_31aa

.l_3213

 CPX #&FF
 BEQ l_327a
 CMP #&41
 BCS l_31eb

.l_321b

 PHA
 TXA
 AND #&BF
 STA vdu_stat
 PLA

.l_3222

 JMP punctuate

.l_3225

 CMP #&A0
 BCS l_323d
 AND #&7F
 ASL A
 TAY
 LDA to880,Y
 JSR de_token
 LDA to880+&01,Y
 CMP #&3F
 BEQ l_327a
 JMP de_token

.l_323d

 SBC #&A0

.l_323f

 TAX
 LDA #&00
 STA &22
 LDA #&04
 STA &23
 LDY #&00
 TXA
 BEQ l_3260

.l_324d

 LDA (&22),Y
 BEQ l_3258
 INY
 BNE l_324d
 INC &23
 BNE l_324d

.l_3258

 INY
 BNE l_325d
 INC &23

.l_325d

 DEX
 BNE l_324d

.l_3260

 TYA
 PHA
 LDA &23
 PHA
 LDA (&22),Y
 EOR #&23
 JSR de_token
 PLA
 STA &23
 PLA
 TAY
 INY
 BNE l_3276
 INC &23

.l_3276

 LDA (&22),Y
 BNE l_3260

.l_327a

 RTS

.l_3283

 LDX #&00

.l_3285

 LDA ship_type,X
 BEQ l_32a8
 BMI l_32a5
 JSR ship_ptr
 LDY #&1F

.l_3291

 LDA (&20),Y
 STA &46,Y
 DEY
 BPL l_3291
 STX &84
 LDX &84
 LDY #&1F
 LDA (&20),Y
 AND #&A7
 STA (&20),Y

.l_32a5

 INX
 BNE l_3285

.l_32a8

 LDX #&FF
 STX &0EC0
 STX &0F0E

.l_32b0

 LDY #&BF
 LDA #&00

.l_32b4

 STA &0E00,Y
 DEY
 BNE l_32b4
 DEY
 STY &0E00
 RTS

.ship_ptr

 TXA
 ASL A
 TAY
 LDA ship_addr,Y
 STA &20
 LDA ship_addr+&01,Y
 STA &21
 RTS

.ins_ship

 STA &D1
 LDX #&00

.l_32ff

 LDA ship_type,X
 BEQ l_330b
 INX
 CPX #&0C
 BCC l_32ff
 CLC

.l_330a

 RTS

.l_330b

 JSR ship_ptr
 LDA &D1
 BMI l_3362
 ASL A
 TAY
 LDA ship_data,Y
 STA &1E
 LDA ship_data+&01,Y
 STA &1F
 LDY #&05
 LDA (&1E),Y
 STA &06
 LDA &03B0
 SEC
 SBC &06
 STA &67
 LDA &03B1
 SBC #&00
 STA &68
 LDA &67
 SBC &20
 TAY
 LDA &68
 SBC &21
 BCC l_330a
 BNE l_3348
 CPY #&25
 BCC l_330a

.l_3348

 LDA &67
 STA &03B0
 LDA &68
 STA &03B1
 LDY #&0E
 LDA (&1E),Y
 STA &69
 LDY #&13
 LDA (&1E),Y
 AND #&07
 STA &65
 LDA &D1

.l_3362

 STA ship_type,X
 TAX
 BMI l_336b
 INC &031E,X

.l_336b

 LDY #&24

.l_336d

 LDA &46,Y
 STA (&20),Y
 DEY
 BPL l_336d
 SEC
 RTS

.l_33c0

 TXA
 EOR #&FF
 CLC
 ADC #&01
 TAX

.l_33c7

 LDA #&FF
 BNE l_340e

.l_33cb

 LDA #&01
 STA &0E00
 JSR l_35b7
 LDA #&00
 LDX &40
 CPX #&60
 ROL A
 CPX #&28
 ROL A
 CPX #&10
 ROL A
 STA &93
 LDA #&BF
 LDX &1D
 BNE l_33f2
 CMP &1C
 BCC l_33f2
 LDA &1C
 BNE l_33f2
 LDA #&01

.l_33f2

 STA &8F
 LDA #&BF
 SEC
 SBC &E0
 TAX
 LDA #&00
 SBC &E1
 BMI l_33c0
 BNE l_340a
 INX
 DEX
 BEQ l_33c7
 CPX &40
 BCC l_340e

.l_340a

 LDX &40
 LDA #&00

.l_340e

 STX &22
 STA &23
 LDA &40
 JSR square
 STA &9C
 LDA &1B
 STA &9B
 LDY #&BF
 LDA &28
 STA &26
 LDA &29
 STA &27

.l_3427

 CPY &8F
 BEQ l_3436
 LDA &0E00,Y
 BEQ l_3433
 JSR l_1909

.l_3433

 DEY
 BNE l_3427

.l_3436

 LDA &22
 JSR square
 STA &D1
 LDA &9B
 SEC
 SBC &1B
 STA &81
 LDA &9C
 SBC &D1
 STA &82
 STY &35
 JSR sqr_root
 LDY &35
 JSR rnd_seq
 AND &93
 CLC
 ADC &81
 BCC l_345d
 LDA #&FF

.l_345d

 LDX &0E00,Y
 STA &0E00,Y
 BEQ l_34af
 LDA &28
 STA &26
 LDA &29
 STA &27
 TXA
 JSR l_3586
 LDA &34
 STA &24
 LDA &36
 STA &25
 LDA &D2
 STA &26
 LDA &D3
 STA &27
 LDA &0E00,Y
 JSR l_3586
 BCS l_3494
 LDA &36
 LDX &24
 STX &36
 STA &24
 JSR draw_hline

.l_3494

 LDA &24
 STA &34
 LDA &25
 STA &36

.l_349c

 JSR draw_hline

.l_349f

 DEY
 BEQ l_34e1
 LDA &23
 BNE l_34c3
 DEC &22
 BNE l_3436
 DEC &23

.l_34ac

 JMP l_3436

.l_34af

 LDX &D2
 STX &26
 LDX &D3
 STX &27
 JSR l_3586
 BCC l_349c
 LDA #&00
 STA &0E00,Y
 BEQ l_349f

.l_34c3

 LDX &22
 INX
 STX &22
 CPX &40
 BCC l_34ac
 BEQ l_34ac
 LDA &28
 STA &26
 LDA &29
 STA &27

.l_34d6

 LDA &0E00,Y
 BEQ l_34de
 JSR l_1909

.l_34de

 DEY
 BNE l_34d6

.l_34e1

 CLC
 LDA &D2
 STA &28
 LDA &D3
 STA &29
 RTS

.circle

 LDX #&FF
 STX &92
 INX
 STX &93

.l_3507

 LDA &93
 JSR l_21f0
 LDX #&00
 STX &D1
 LDX &93
 CPX #&21
 BCC l_3523
 EOR #&FF
 ADC #&00
 TAX
 LDA #&FF
 ADC #&00
 STA &D1
 TXA
 CLC

.l_3523

 ADC &D2
 STA &76
 LDA &D3
 ADC &D1
 STA &77
 LDA &93
 CLC
 ADC #&10
 JSR l_21f0
 TAX
 LDA #&00
 STA &D1
 LDA &93
 ADC #&0F
 AND #&3F
 CMP #&21
 BCC l_3551
 TXA
 EOR #&FF
 ADC #&00
 TAX
 LDA #&FF
 ADC #&00
 STA &D1
 CLC

.l_3551

 JSR l_1a16
 CMP #&41
 BCS l_355b
 JMP l_3507

.l_355b

 CLC
 RTS

.l_3586

 STA &D1
 CLC
 ADC &26
 STA &36
 LDA &27
 ADC #&00
 BMI l_35b0
 BEQ l_3599
 LDA #&FE
 STA &36

.l_3599

 LDA &26
 SEC
 SBC &D1
 STA &34
 LDA &27
 SBC #&00
 BNE l_35a8
 CLC
 RTS

.l_35a8

 BPL l_35b0
 LDA #&02
 STA &34

.l_35ae

 CLC
 RTS

.l_35b0

 LDA #&00
 STA &0E00,Y

.l_35b5

 SEC
 RTS

.l_35b7

 LDA &D2
 CLC
 ADC &40
 LDA &D3
 ADC #&00
 BMI l_35b5
 LDA &D2
 SEC
 SBC &40
 LDA &D3
 SBC #&00
 BMI l_35cf
 BNE l_35b5

.l_35cf

 LDA &E0
 CLC
 ADC &40
 STA &1C
 LDA &E1
 ADC #&00
 BMI l_35b5
 STA &1D
 LDA &E0
 SEC
 SBC &40
 TAX
 LDA &E1
 SBC #&00
 BMI l_35ae
 BNE l_35b5
 CPX #&BF
 RTS

.get_dirn

 JSR direction
 LDA k_flag
 BEQ keybd_dirn
 LDA adval_x
 EOR #&FF
 JSR adval_chop
 TYA
 TAX
 LDA adval_y

.adval_chop

 TAY
 LDA #&00
 CPY #&10
 SBC #&00
 CPY #&40
 SBC #&00
 CPY #&C0
 ADC #&00
 CPY #&E0
 ADC #&00
 TAY
 LDA last_key
 RTS

.keybd_dirn

 LDA last_key
 LDX #&00
 LDY #&00
 CMP #&19
 BNE not_lcurs
 DEX

.not_lcurs

 CMP #&79
 BNE not_rcurs
 INX

.not_rcurs

 CMP #&39
 BNE not_ucurs
 INY

.not_ucurs

 CMP #&29
 BNE not_dcurs
 DEY

.not_dcurs

 STX &D1
 LDX #&00
 JSR scan_x
 BPL not_shift
 ASL &D1
 ASL &D1
 TYA
 ASL A
 ASL A
 TAY

.not_shift

 LDX &D1
 LDA last_key
 RTS

.set_home

 LDX #&01

.l_3650

 LDA cmdr_homex,X
 STA data_homex,X
 DEX
 BPL l_3650
 RTS

.sound_tab

 EQUB &12, &01, &00, &10
 EQUB &12, &02, &2C, &08
 EQUB &11, &03, &F0, &18
 EQUB &10, &F1, &07, &1A
 EQUB &03, &F1, &BC, &01
 EQUB &13, &F4, &0C, &08
 EQUB &10, &F1, &06, &0C
 EQUB &10, &02, &60, &10
 EQUB &13, &04, &C2, &FF
 EQUB &13, &00, &00, &00

.clr_common

 LDA #&12
 STA &03C3
 LDX #&FF
 STX &0EC0
 STX &0F0E
 STX &45
 LDA #&80
 STA adval_y
 STA &32
 STA &7B
 ASL A
 STA &33
 STA &7C
 STA &8A
 LDA #&03
 STA &7D
 STA &8D
 STA &31
 LDA &30
 BEQ l_36c5
 JSR sound_0

.l_36c5

 JSR l_3283
 JSR clr_ships
 LDA #&FF
 STA &03B0
 LDA #&0C
 STA &03B1

.init_ship

 LDY #&24
 LDA #&00

.l_36dc

 STA &46,Y
 DEY
 BPL l_36dc
 LDA #&60
 STA &58
 STA &5C
 ORA #&80
 STA &54
 RTS

.l_3706

 LDA &03A4
 JSR l_3d82
 LDA #&00
 STA &034A
 JMP l_3754

.rnd_seq

 LDA &00
 ROL A
 TAX
 ADC &02
 STA &00
 STX &02
 LDA &01
 TAX
 ADC &03
 STA &01
 STX &03
 RTS

.l_374a

 DEC &034A
 BEQ l_3706
 BPL l_3754
 INC &034A

.l_3754

 DEC &8A

.repeat_fn

 LDX #&FF
 TXS
 LDY #&02
 JSR y_sync
 JSR get_dirn

.function

 JSR check_mode
 LDA &8E
 BNE repeat_fn
 JMP l_374a

.check_mode

 CMP #&76
 BNE not_status
 JMP info_menu

.not_status

 CMP #&14
 BNE not_long
 JMP long_map

.not_long

 CMP #&74
 BNE not_short
 JMP short_map

.not_short

 CMP #&75
 BNE not_data
 JSR l_3c91
 BPL jump_data
 JMP launch

.jump_data

 JSR snap_hype
 JMP data_onsys

.not_data

 CMP #&77
 BNE not_invnt
 JMP info_menu

.not_invnt

 CMP #&16
 BNE not_price
 JMP info_menu

.not_price

 CMP #&20
 BEQ jump_menu
 CMP #&71
 BEQ jump_menu
 CMP #&72
 BEQ jump_menu
 CMP #&73
 BNE not_equip

.jump_menu

 JMP info_menu

.not_equip

 CMP #&54
 BNE not_hype
 JSR clr_line
 LDA #&0F
 STA cursor_x
 LDA #&CD
 JMP write_msg1

.not_hype

 CMP #&32
 BEQ distance
 CMP #&43
 BNE not_find
 LDA &87
 AND #&C0
 BEQ not_map
 JMP find_plant

.not_find

 STA &06
 LDA &87
 AND #&C0
 BEQ not_map
 LDA &2F
 BNE not_map
 LDA &06
 CMP #&36
 BNE not_home
 JSR map_cursor
 JSR set_home
 JSR map_cursor

.not_cour

 JSR add_dirn

.not_map

 RTS

.not_home

 CMP #&21
 BNE not_cour
 LDA cmdr_cour
 ORA cmdr_cour+1
 BEQ not_cour
 JSR map_cursor
 LDA cmdr_courx
 STA data_homex
 LDA cmdr_coury
 STA data_homey
 JSR map_cursor

.distance

 LDA &87
 AND #&C0
 BEQ not_map
 JSR snap_cursor
 STA vdu_stat
 JSR write_planet
 LDA #&80
 STA vdu_stat
 LDA #&01
 STA cursor_x
 INC cursor_y
 JMP show_nzdist

.err_count

 EQUB &00

.jmp_escape

 JMP escape

.brk_go

 DEC err_count
 BNE jmp_escape
 JSR clr_common

.start_loop

 LDA #&FF
 STA &8E
 LDA #&73
 JMP function

.get_line

 LDA #&81
 STA &FE4E
 JSR flush_inp
 LDX #LO(word_0)
 LDY #HI(word_0)
 LDA #&00
 JSR osword
 BCC l_39e1
 LDY #&00

.l_39e1

 LDA #&01
 STA &FE4E
 JMP l_1c8a

.word_0

 EQUW &004B
 EQUB &09, &21, &7B

.clr_ships

 LDX #&3A
 LDA #&00

.l_39f2

 STA ship_type,X
 DEX
 BPL l_39f2
 RTS

.clr_page

 LDY #&00
 STY ptr

.l_3a03

 LDA #&00
 STX ptr+&01

.l_3a07

 STA (ptr),Y
 INY
 BNE l_3a07
 RTS

.l_3bd6

 LDA &34
 JSR l_21be
 STA &82
 LDA &1B
 STA &81
 LDA &35
 JSR l_21be
 STA &D1
 LDA &1B
 ADC &81
 STA &81
 LDA &D1
 ADC &82
 STA &82
 LDA &36
 JSR l_21be
 STA &D1
 LDA &1B
 ADC &81
 STA &81
 LDA &D1
 ADC &82
 STA &82
 JSR sqr_root
 LDA &34
 JSR l_3e8c
 STA &34
 LDA &35
 JSR l_3e8c
 STA &35
 LDA &36
 JSR l_3e8c
 STA &36

.l_3c1f

 RTS

.scan_10

 LDX #&10

.scan_loop

 JSR scan_x
 BMI scan_key
 INX
 BPL scan_loop
 TXA

.scan_key

 EOR #&80
 TAX
 RTS

.sound_0

 LDA #&00
 STA &30
 STA &0340
 LDA #&48
 BNE sound

.sound_20

 LDA #&20

.sound

 JSR pp_sound
 LDX s_flag
 BNE l_3c1f
 LDX #&09
 LDY #&00
 LDA #&07
 JMP osword

.pp_sound

 LSR A
 ADC #&03
 TAY
 LDX #&07

.l_3c83

 LDA #&00
 STA &09,X
 DEX
 LDA sound_tab,Y
 STA &09,X
 DEY
 DEX
 BPL l_3c83

.l_3c91

 LDX #&01

.scan_x

 LDA #&03
 SEI
 STA &FE40
 LDA #&7F
 STA &FE43
 STX &FE4F
 LDX &FE4F
 LDA #&0B
 STA &FE40
 CLI
 TXA
 RTS

.adval

 LDA #&80
 JSR osbyte
 TYA
 EOR j_flag
 RTS

.tog_flag

 STY &D1
 CPX &D1
 BNE tog_end
 LDA &0387,X
 EOR #&FF
 STA &0387,X
 JSR bell
 JSR y_sync
 LDY &D1

.tog_end

 RTS

.direction

 LDA k_flag
 BEQ spec_key
 LDX #&01
 JSR adval
 ORA #&01
 STA adval_x
 LDX #&02
 JSR adval
 EOR y_flag
 STA adval_y

.spec_key

 JSR scan_10
 STX last_key
 CPX #&69
 BNE no_freeze

.no_thaw

 JSR sync
 JSR scan_10
 CPX #&51
 BNE not_sound
 LDA #&00
 STA s_flag

.not_sound

 LDY #&40

.flag_loop

 JSR tog_flag
 INY
 CPY #&48
 BNE flag_loop
 CPX #&10
 BNE not_quiet
 STX s_flag

.not_quiet

 CPX #&70
 BNE not_escape
 JMP escape

.not_escape

 CPX #&59
 BNE no_thaw

.no_freeze

 LDA &87
 BNE frz_ret
 LDY #&10
 LDA #&FF
 RTS

.get_keyy

 STY &85

.get_key

 LDY #&02
 JSR y_sync
 JSR scan_10
 BNE get_key

.press

 JSR scan_10
 BEQ press
 TAY
 LDA (key_table),Y
 LDY &85
 TAX

.frz_ret

 RTS

.l_3d77

 STX &034A
 PHA
 LDA &03A4
 JSR l_3d99
 PLA

.l_3d82

 LDX #&00
 STX vdu_stat
 LDY #&09
 STY cursor_x
 LDY #&16
 STY cursor_y
 CPX &034A
 BNE l_3d77
 STY &034A
 STA &03A4

.l_3d99

 JSR de_token
 LSR &034B
 BEQ frz_ret
 LDA #&FD
 JMP de_token

.l_3dea

 TYA
 LDY #&02
 JSR l_3eb9
 STA &5A
 JMP l_3e32

.l_3df5

 TAX
 LDA &35
 AND #&60
 BEQ l_3dea
 LDA #&02
 JSR l_3eb9
 STA &58
 JMP l_3e32

.l_3e06

 LDA &50
 STA &34
 LDA &52
 STA &35
 LDA &54
 STA &36
 JSR l_3bd6
 LDA &34
 STA &50
 LDA &35
 STA &52
 LDA &36
 STA &54
 LDY #&04
 LDA &34
 AND #&60
 BEQ l_3df5
 LDX #&02
 LDA #&00
 JSR l_3eb9
 STA &56

.l_3e32

 LDA &56
 STA &34
 LDA &58
 STA &35
 LDA &5A
 STA &36
 JSR l_3bd6
 LDA &34
 STA &56
 LDA &35
 STA &58
 LDA &36
 STA &5A
 LDA &52
 STA &81
 LDA &5A
 JSR l_2287
 LDX &54
 LDA &58
 JSR l_22ec
 EOR #&80
 STA &5C
 LDA &56
 JSR l_2287
 LDX &50
 LDA &5A
 JSR l_22ec
 EOR #&80
 STA &5E
 LDA &58
 JSR l_2287
 LDX &52
 LDA &56
 JSR l_22ec
 EOR #&80
 STA &60
 LDA #&00
 LDX #&0E

.l_3e85

 STA &4F,X
 DEX
 DEX
 BPL l_3e85
 RTS

.l_3e8c

 TAY
 AND #&7F
 CMP &81
 BCS l_3eb3
 LDX #&FE
 STX &D1

.l_3e97

 ASL A
 CMP &81
 BCC l_3e9e
 SBC &81

.l_3e9e

 ROL &D1
 BCS l_3e97
 LDA &D1
 LSR A
 LSR A
 STA &D1
 LSR A
 ADC &D1
 STA &D1
 TYA
 AND #&80
 ORA &D1
 RTS

.l_3eb3

 TYA
 AND #&80
 ORA #&60
 RTS

.l_3eb9

 STA &1D
 LDA &50,X
 STA &81
 LDA &56,X
 JSR l_2287
 LDX &50,Y
 STX &81
 LDA &56,Y
 JSR l_22ad
 STX &1B
 LDY &1D
 LDX &50,Y
 STX &81
 EOR #&80
 STA &1C
 EOR &81
 AND #&80
 STA &D1
 LDA #&00
 LDX #&10
 ASL &1B
 ROL &1C
 ASL &81
 LSR &81

.l_3eec

 ROL A
 CMP &81
 BCC l_3ef3
 SBC &81

.l_3ef3

 ROL &1B
 ROL &1C
 DEX
 BNE l_3eec
 LDA &1B
 ORA &D1
 RTS

.l_3eff

 JSR l_4059
 LDA #&60
 CMP #&BE
 BCS l_3f23
 LDY #&02
 JSR l_3f2a
 LDY #&06
 LDA #&60
 ADC #&01
 JSR l_3f2a
 LDA #&08
 ORA &65
 STA &65
 LDA #&08
 JMP l_46ef

.l_3f21

 PLA
 PLA

.l_3f23

 LDA #&F7
 AND &65
 STA &65
 RTS

.l_3f2a

 STA (&67),Y
 INY
 INY
 STA (&67),Y
 LDA #&80
 DEY
 STA (&67),Y
 ADC #&03
 BCS l_3f21
 DEY
 DEY
 STA (&67),Y
 RTS

.sqr_root

 LDY &82
 LDA &81
 STA &83
 LDX #&00
 STX &81
 LDA #&08
 STA &D1

.l_3f4c

 CPX &81
 BCC l_3f5e
 BNE l_3f56
 CPY #&40
 BCC l_3f5e

.l_3f56

 TYA
 SBC #&40
 TAY
 TXA
 SBC &81
 TAX

.l_3f5e

 ROL &81
 ASL &83
 TYA
 ROL A
 TAY
 TXA
 ROL A
 TAX
 ASL &83
 TYA
 ROL A
 TAY
 TXA
 ROL A
 TAX
 DEC &D1
 BNE l_3f4c
 RTS

.l_3f75

 CMP &81
 BCS l_3f93
 LDX #&FE
 STX &82

.l_3f7d

 ASL A
 BCS l_3f8b
 CMP &81
 BCC l_3f86
 SBC &81

.l_3f86

 ROL &82
 BCS l_3f7d
 RTS

.l_3f8b

 SBC &81
 SEC
 ROL &82
 BCS l_3f7d
 RTS

.l_3f93

 LDA #&FF
 STA &82
 RTS

.l_3f98

 EOR &83
 BMI l_3fa2
 LDA &81
 CLC
 ADC &82
 RTS

.l_3fa2

 LDA &82
 SEC
 SBC &81
 BCC l_3fab
 CLC
 RTS

.l_3fab

 PHA
 LDA &83
 EOR #&80
 STA &83
 PLA
 EOR #&FF
 ADC #&01
 RTS

.l_3fb8

 LDX #&00
 LDY #&00

.l_3fbc

 LDA &34
 STA &81
 LDA &09,X
 JSR l_21fa
 STA &D1
 LDA &35
 EOR &0A,X
 STA &83
 LDA &36
 STA &81
 LDA &0B,X
 JSR l_21fa
 STA &81
 LDA &D1
 STA &82
 LDA &37
 EOR &0C,X
 JSR l_3f98
 STA &D1
 LDA &38
 STA &81
 LDA &0D,X
 JSR l_21fa
 STA &81
 LDA &D1
 STA &82
 LDA &39
 EOR &0E,X
 JSR l_3f98
 STA &3A,Y
 LDA &83
 STA &3B,Y
 INY
 INY
 TXA
 CLC
 ADC #&06
 TAX
 CMP #&11
 BCC l_3fbc
 RTS

.l_400f

 LDA #&1F
 STA &96
 LDA #&20
 BIT &65
 BNE l_4046
 BPL l_4046
 ORA &65
 AND #&3F
 STA &65
 LDA #&00
 LDY #&1C
 STA (&20),Y
 LDY #&1E
 STA (&20),Y
 JSR l_4059
 LDY #&01
 LDA #&12
 STA (&67),Y
 LDY #&07
 LDA (&1E),Y
 LDY #&02
 STA (&67),Y

.l_403c

 INY
 JSR rnd_seq
 STA (&67),Y
 CPY #&06
 BNE l_403c

.l_4046

 LDA &4E
 BPL l_4067

.l_404a

 LDA &65
 AND #&20
 BEQ l_4059
 LDA &65
 AND #&F7
 STA &65
 JMP l_327a

.l_4059

 LDA #&08
 BIT &65
 BEQ l_4066
 EOR &65
 STA &65
 JMP l_46f3

.l_4066

 RTS

.l_4067

 LDA &4D
 CMP #&C0
 BCS l_404a
 LDA &46
 CMP &4C
 LDA &47
 SBC &4D
 BCS l_404a
 LDA &49
 CMP &4C
 LDA &4A
 SBC &4D
 BCS l_404a
 LDY #&06
 LDA (&1E),Y
 TAX
 LDA #&FF
 STA &0100,X
 STA &0101,X
 LDA &4C
 STA &D1
 LDA &4D
 LSR A
 ROR &D1
 LSR A
 ROR &D1
 LSR A
 ROR &D1
 LSR A
 BNE l_40aa
 LDA &D1
 ROR A
 LSR A
 LSR A
 LSR A
 STA &96
 BPL l_40bb

.l_40aa

 LDY #&0D
 LDA (&1E),Y
 CMP &4D
 BCS l_40bb
 LDA #&20
 AND &65
 BNE l_40bb
 JMP l_3eff

.l_40bb

 LDX #&05

.l_40bd

 LDA &5B,X
 STA &09,X
 LDA &55,X
 STA &0F,X
 LDA &4F,X
 STA &15,X
 DEX
 BPL l_40bd
 LDA #&C5
 STA &81
 LDY #&10

.l_40d2

 LDA &09,Y
 ASL A
 LDA &0A,Y
 ROL A
 JSR l_3f75
 LDX &82
 STX &09,Y
 DEY
 DEY
 BPL l_40d2
 LDX #&08

.l_40e7

 LDA &46,X
 STA vdu_stat,X
 DEX
 BPL l_40e7
 LDA #&FF
 STA &E1
 LDY #&0C
 LDA &65
 AND #&20
 BEQ l_410c
 LDA (&1E),Y
 LSR A
 LSR A
 TAX
 LDA #&FF

.l_4101

 STA &D2,X
 DEX
 BPL l_4101
 INX
 STX &96

.l_4109

 JMP l_427f

.l_410c

 LDA (&1E),Y
 BEQ l_4109
 STA &97
 LDY #&12
 LDA (&1E),Y
 TAX
 LDA &79
 TAY
 BEQ l_412b

.l_411c

 INX
 LSR &76
 ROR &75
 LSR &73
 ROR vdu_stat
 LSR A
 ROR &78
 TAY
 BNE l_411c

.l_412b

 STX &86
 LDA &7A
 STA &39
 LDA vdu_stat
 STA &34
 LDA &74
 STA &35
 LDA &75
 STA &36
 LDA &77
 STA &37
 LDA &78
 STA &38
 JSR l_3fb8
 LDA &3A
 STA vdu_stat
 LDA &3B
 STA &74
 LDA &3C
 STA &75
 LDA &3D
 STA &77
 LDA &3E
 STA &78
 LDA &3F
 STA &7A
 LDY #&04
 LDA (&1E),Y
 CLC
 ADC &1E
 STA &22
 LDY #&11
 LDA (&1E),Y
 ADC &1F
 STA &23
 LDY #&00

.l_4173

 LDA (&22),Y
 STA &3B
 AND #&1F
 CMP &96
 BCS l_418c
 TYA
 LSR A
 LSR A
 TAX
 LDA #&FF
 STA &D2,X
 TYA
 ADC #&04
 TAY
 JMP l_4278

.l_418c

 LDA &3B
 ASL A
 STA &3D
 ASL A
 STA &3F
 INY
 LDA (&22),Y
 STA &3A
 INY
 LDA (&22),Y
 STA &3C
 INY
 LDA (&22),Y
 STA &3E
 LDX &86
 CPX #&04
 BCC l_41cc
 LDA vdu_stat
 STA &34
 LDA &74
 STA &35
 LDA &75
 STA &36
 LDA &77
 STA &37
 LDA &78
 STA &38
 LDA &7A
 STA &39
 JMP l_422a

.l_41c4

 LSR vdu_stat
 LSR &78
 LSR &75
 LDX #&01

.l_41cc

 LDA &3A
 STA &34
 LDA &3C
 STA &36
 LDA &3E
 DEX
 BMI l_41e1

.l_41d9

 LSR &34
 LSR &36
 LSR A
 DEX
 BPL l_41d9

.l_41e1

 STA &82
 LDA &3F
 STA &83
 LDA &78
 STA &81
 LDA &7A
 JSR l_3f98
 BCS l_41c4
 STA &38
 LDA &83
 STA &39
 LDA &34
 STA &82
 LDA &3B
 STA &83
 LDA vdu_stat
 STA &81
 LDA &74
 JSR l_3f98
 BCS l_41c4
 STA &34
 LDA &83
 STA &35
 LDA &36
 STA &82
 LDA &3D
 STA &83
 LDA &75
 STA &81
 LDA &77
 JSR l_3f98
 BCS l_41c4
 STA &36
 LDA &83
 STA &37

.l_422a

 LDA &3A
 STA &81
 LDA &34
 JSR l_21fa
 STA &D1
 LDA &3B
 EOR &35
 STA &83
 LDA &3C
 STA &81
 LDA &36
 JSR l_21fa
 STA &81
 LDA &D1
 STA &82
 LDA &3D
 EOR &37
 JSR l_3f98
 STA &D1
 LDA &3E
 STA &81
 LDA &38
 JSR l_21fa
 STA &81
 LDA &D1
 STA &82
 LDA &39
 EOR &3F
 JSR l_3f98
 PHA
 TYA
 LSR A
 LSR A
 TAX
 PLA
 BIT &83
 BMI l_4275
 LDA #&00

.l_4275

 STA &D2,X
 INY

.l_4278

 CPY &97
 BCS l_427f
 JMP l_4173

.l_427f

 LDY &0B
 LDX &0C
 LDA &0F
 STA &0B
 LDA &10
 STA &0C
 STY &0F
 STX &10
 LDY &0D
 LDX &0E
 LDA &15
 STA &0D
 LDA &16
 STA &0E
 STY &15
 STX &16
 LDY &13
 LDX &14
 LDA &17
 STA &13
 LDA &18
 STA &14
 STY &17
 STX &18
 LDY #&08
 LDA (&1E),Y
 STA &97
 LDA &1E
 CLC
 ADC #&14
 STA &22
 LDA &1F
 ADC #&00
 STA &23
 LDY #&00
 STY &93

.l_42c6

 STY &86
 LDA (&22),Y
 STA &34
 INY
 LDA (&22),Y
 STA &36
 INY
 LDA (&22),Y
 STA &38
 INY
 LDA (&22),Y
 STA &D1
 AND #&1F
 CMP &96
 BCC l_430f
 INY
 LDA (&22),Y
 STA &1B
 AND #&0F
 TAX
 LDA &D2,X
 BNE l_4312
 LDA &1B
 LSR A
 LSR A
 LSR A
 LSR A
 TAX
 LDA &D2,X
 BNE l_4312
 INY
 LDA (&22),Y
 STA &1B
 AND #&0F
 TAX
 LDA &D2,X
 BNE l_4312
 LDA &1B
 LSR A
 LSR A
 LSR A
 LSR A
 TAX
 LDA &D2,X
 BNE l_4312

.l_430f

 JMP l_4487

.l_4312

 LDA &D1
 STA &35
 ASL A
 STA &37
 ASL A
 STA &39
 JSR l_3fb8
 LDA &48
 STA &36
 EOR &3B
 BMI l_4337
 CLC
 LDA &3A
 ADC &46
 STA &34
 LDA &47
 ADC #&00
 STA &35
 JMP l_435a

.l_4337

 LDA &46
 SEC
 SBC &3A
 STA &34
 LDA &47
 SBC #&00
 STA &35
 BCS l_435a
 EOR #&FF
 STA &35
 LDA #&01
 SBC &34
 STA &34
 BCC l_4354
 INC &35

.l_4354

 LDA &36
 EOR #&80
 STA &36

.l_435a

 LDA &4B
 STA &39
 EOR &3D
 BMI l_4372
 CLC
 LDA &3C
 ADC &49
 STA &37
 LDA &4A
 ADC #&00
 STA &38
 JMP l_4397

.l_4372

 LDA &49
 SEC
 SBC &3C
 STA &37
 LDA &4A
 SBC #&00
 STA &38
 BCS l_4397
 EOR #&FF
 STA &38
 LDA &37
 EOR #&FF
 ADC #&01
 STA &37
 LDA &39
 EOR #&80
 STA &39
 BCC l_4397
 INC &38

.l_4397

 LDA &3F
 BMI l_43e5
 LDA &3E
 CLC
 ADC &4C
 STA &D1
 LDA &4D
 ADC #&00
 STA &80
 JMP l_4404

.l_43ab

 LDX &81
 BEQ l_43cb
 LDX #&00

.l_43b1

 LSR A
 INX
 CMP &81
 BCS l_43b1
 STX &83
 JSR l_3f75
 LDX &83
 LDA &82

.l_43c0

 ASL A
 ROL &80
 BMI l_43cb
 DEX
 BNE l_43c0
 STA &82
 RTS

.l_43cb

 LDA #&32
 STA &82
 STA &80
 RTS

.l_43d2

 LDA #&80
 SEC
 SBC &82
 STA &0100,X
 INX
 LDA #&00
 SBC &80
 STA &0100,X
 JMP l_4444

.l_43e5

 LDA &4C
 SEC
 SBC &3E
 STA &D1
 LDA &4D
 SBC #&00
 STA &80
 BCC l_43fc
 BNE l_4404
 LDA &D1
 CMP #&04
 BCS l_4404

.l_43fc

 LDA #&00
 STA &80
 LDA #&04
 STA &D1

.l_4404

 LDA &80
 ORA &35
 ORA &38
 BEQ l_441b
 LSR &35
 ROR &34
 LSR &38
 ROR &37
 LSR &80
 ROR &D1
 JMP l_4404

.l_441b

 LDA &D1
 STA &81
 LDA &34
 CMP &81
 BCC l_442b
 JSR l_43ab
 JMP l_442e

.l_442b

 JSR l_3f75

.l_442e

 LDX &93
 LDA &36
 BMI l_43d2
 LDA &82
 CLC
 ADC #&80
 STA &0100,X
 INX
 LDA &80
 ADC #&00
 STA &0100,X

.l_4444

 TXA
 PHA
 LDA #&00
 STA &80
 LDA &D1
 STA &81
 LDA &37
 CMP &81
 BCC l_446d
 JSR l_43ab
 JMP l_4470

.l_445a

 LDA #&60
 CLC
 ADC &82
 STA &0100,X
 INX
 LDA #&00
 ADC &80
 STA &0100,X
 JMP l_4487

.l_446d

 JSR l_3f75

.l_4470

 PLA
 TAX
 INX
 LDA &39
 BMI l_445a
 LDA #&60
 SEC
 SBC &82
 STA &0100,X
 INX
 LDA #&00
 SBC &80
 STA &0100,X

.l_4487

 CLC
 LDA &93
 ADC #&04
 STA &93
 LDA &86
 ADC #&06
 TAY
 BCS l_449c
 CMP &97
 BCS l_449c
 JMP l_42c6

.l_449c

 LDA &65
 AND #&20
 BEQ l_44ab
 LDA &65
 ORA #&08
 STA &65
 JMP l_327a

.l_44ab

 LDA #&08
 BIT &65
 BEQ l_44b6
 JSR l_46f3
 LDA #&08

.l_44b6

 ORA &65
 STA &65
 LDY #&09
 LDA (&1E),Y
 STA &97
 LDY #&00
 STY &80
 STY &86
 INC &80
 BIT &65
 BVC l_4520
 LDA &65
 AND #&BF
 STA &65
 LDY #&06
 LDA (&1E),Y
 TAY
 LDX &0100,Y
 STX &34
 INX
 BEQ l_4520
 LDX &0101,Y
 STX &35
 INX
 BEQ l_4520
 LDX &0102,Y
 STX &36
 LDX &0103,Y
 STX &37
 LDA #&00
 STA &38
 STA &39
 STA &3B
 LDA &4C
 STA &3A
 LDA &48
 BPL l_4503
 DEC &38

.l_4503

 JSR l_4594
 BCS l_4520
 LDY &80
 LDA &34
 STA (&67),Y
 INY
 LDA &35
 STA (&67),Y
 INY
 LDA &36
 STA (&67),Y
 INY
 LDA &37
 STA (&67),Y
 INY
 STY &80

.l_4520

 LDY #&03
 CLC
 LDA (&1E),Y
 ADC &1E
 STA &22
 LDY #&10
 LDA (&1E),Y
 ADC &1F
 STA &23
 LDY #&05
 LDA (&1E),Y
 STA &06
 LDY &86

.l_4539

 LDA (&22),Y
 CMP &96
 BCC l_4557
 INY
 LDA (&22),Y
 INY
 STA &1B
 AND #&0F
 TAX
 LDA &D2,X
 BNE l_455a
 LDA &1B
 LSR A
 LSR A
 LSR A
 LSR A
 TAX
 LDA &D2,X
 BNE l_455a

.l_4557

 JMP l_46d6

.l_455a

 LDA (&22),Y
 TAX
 INY
 LDA (&22),Y
 STA &81
 LDA &0101,X
 STA &35
 LDA &0100,X
 STA &34
 LDA &0102,X
 STA &36
 LDA &0103,X
 STA &37
 LDX &81
 LDA &0100,X
 STA &38
 LDA &0103,X
 STA &3B
 LDA &0102,X
 STA &3A
 LDA &0101,X
 STA &39
 JSR l_459a
 BCS l_4557
 JMP l_46ba

.l_4594

 LDA #&00
 STA &90
 LDA &39

.l_459a

 LDX #&BF
 ORA &3B
 BNE l_45a6
 CPX &3A
 BCC l_45a6
 LDX #&00

.l_45a6

 STX &89
 LDA &35
 ORA &37
 BNE l_45ca
 LDA #&BF
 CMP &36
 BCC l_45ca
 LDA &89
 BNE l_45c8

.l_45b8

 LDA &36
 STA &35
 LDA &38
 STA &36
 LDA &3A
 STA &37
 CLC
 RTS

.l_45c6

 SEC
 RTS

.l_45c8

 LSR &89

.l_45ca

 LDA &89
 BPL l_45fd
 LDA &35
 AND &39
 BMI l_45c6
 LDA &37
 AND &3B
 BMI l_45c6
 LDX &35
 DEX
 TXA
 LDX &39
 DEX
 STX &3C
 ORA &3C
 BPL l_45c6
 LDA &36
 CMP #&C0
 LDA &37
 SBC #&00
 STA &3C
 LDA &3A
 CMP #&C0
 LDA &3B
 SBC #&00
 ORA &3C
 BPL l_45c6

.l_45fd

 TYA
 PHA
 LDA &38
 SEC
 SBC &34
 STA &3C
 LDA &39
 SBC &35
 STA &3D
 LDA &3A
 SEC
 SBC &36
 STA &3E
 LDA &3B
 SBC &37
 STA &3F
 EOR &3D
 STA &83
 LDA &3F
 BPL l_462e
 LDA #&00
 SEC
 SBC &3E
 STA &3E
 LDA #&00
 SBC &3F
 STA &3F

.l_462e

 LDA &3D
 BPL l_463d
 SEC
 LDA #&00
 SBC &3C
 STA &3C
 LDA #&00
 SBC &3D

.l_463d

 TAX
 BNE l_4644
 LDX &3F
 BEQ l_464e

.l_4644

 LSR A
 ROR &3C
 LSR &3F
 ROR &3E
 JMP l_463d

.l_464e

 STX &D1
 LDA &3C
 CMP &3E
 BCC l_4660
 STA &81
 LDA &3E
 JSR l_3f75
 JMP l_466b

.l_4660

 LDA &3E
 STA &81
 LDA &3C
 JSR l_3f75
 DEC &D1

.l_466b

 LDA &82
 STA &3C
 LDA &83
 STA &3D
 LDA &89
 BEQ l_4679
 BPL l_468c

.l_4679

 JSR l_471a
 LDA &89
 BPL l_46b1
 LDA &35
 ORA &37
 BNE l_46b6
 LDA &36
 CMP #&C0
 BCS l_46b6

.l_468c

 LDX &34
 LDA &38
 STA &34
 STX &38
 LDA &39
 LDX &35
 STX &39
 STA &35
 LDX &36
 LDA &3A
 STA &36
 STX &3A
 LDA &3B
 LDX &37
 STX &3B
 STA &37
 JSR l_471a
 DEC &90

.l_46b1

 PLA
 TAY
 JMP l_45b8

.l_46b6

 PLA
 TAY
 SEC
 RTS

.l_46ba

 LDY &80
 LDA &34
 STA (&67),Y
 INY
 LDA &35
 STA (&67),Y
 INY
 LDA &36
 STA (&67),Y
 INY
 LDA &37
 STA (&67),Y
 INY
 STY &80
 CPY &06
 BCS l_46ed

.l_46d6

 INC &86
 LDY &86
 CPY &97
 BCS l_46ed
 LDY #&00
 LDA &22
 ADC #&04
 STA &22
 BCC l_46ea
 INC &23

.l_46ea

 JMP l_4539

.l_46ed

 LDA &80

.l_46ef

 LDY #&00
 STA (&67),Y

.l_46f3

 LDY #&00
 LDA (&67),Y
 STA &97
 CMP #&04
 BCC l_4719
 INY

.l_46fe

 LDA (&67),Y
 STA &34
 INY
 LDA (&67),Y
 STA &35
 INY
 LDA (&67),Y
 STA &36
 INY
 LDA (&67),Y
 STA &37
 JSR draw_line
 INY
 CPY &97
 BCC l_46fe

.l_4719

 RTS

.l_471a

 LDA &35
 BPL l_4735
 STA &83
 JSR l_4794
 TXA
 CLC
 ADC &36
 STA &36
 TYA
 ADC &37
 STA &37
 LDA #&00
 STA &34
 STA &35
 TAX

.l_4735

 BEQ l_4750
 STA &83
 DEC &83
 JSR l_4794
 TXA
 CLC
 ADC &36
 STA &36
 TYA
 ADC &37
 STA &37
 LDX #&FF
 STX &34
 INX
 STX &35

.l_4750

 LDA &37
 BPL l_476e
 STA &83
 LDA &36
 STA &82
 JSR l_47c3
 TXA
 CLC
 ADC &34
 STA &34
 TYA
 ADC &35
 STA &35
 LDA #&00
 STA &36
 STA &37

.l_476e

 LDA &36
 SEC
 SBC #&C0
 STA &82
 LDA &37
 SBC #&00
 STA &83
 BCC l_4793
 JSR l_47c3
 TXA
 CLC
 ADC &34
 STA &34
 TYA
 ADC &35
 STA &35
 LDA #&BF
 STA &36
 LDA #&00
 STA &37

.l_4793

 RTS

.l_4794

 LDA &34
 STA &82
 JSR l_47ff
 PHA
 LDX &D1
 BNE l_47cb

.l_47a0

 LDA #&00
 TAX
 TAY
 LSR &83
 ROR &82
 ASL &81
 BCC l_47b5

.l_47ac

 TXA
 CLC
 ADC &82
 TAX
 TYA
 ADC &83
 TAY

.l_47b5

 LSR &83
 ROR &82
 ASL &81
 BCS l_47ac
 BNE l_47b5
 PLA
 BPL l_47f2
 RTS

.l_47c3

 JSR l_47ff
 PHA
 LDX &D1
 BNE l_47a0

.l_47cb

 LDA #&FF
 TAY
 ASL A
 TAX

.l_47d0

 ASL &82
 ROL &83
 LDA &83
 BCS l_47dc
 CMP &81
 BCC l_47e7

.l_47dc

 SBC &81
 STA &83
 LDA &82
 SBC #&00
 STA &82
 SEC

.l_47e7

 TXA
 ROL A
 TAX
 TYA
 ROL A
 TAY
 BCS l_47d0
 PLA
 BMI l_47fe

.l_47f2

 TXA
 EOR #&FF
 ADC #&01
 TAX
 TYA
 EOR #&FF
 ADC #&00
 TAY

.l_47fe

 RTS

.l_47ff

 LDX &3C
 STX &81
 LDA &83
 BPL l_4818
 LDA #&00
 SEC
 SBC &82
 STA &82
 LDA &83
 PHA
 EOR #&FF
 ADC #&00
 STA &83
 PLA

.l_4818

 EOR &3D
 RTS


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

 JSR beep_wait
 JMP start_loop

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

 STA &8C
 CLC
 ADC #&07
 PHA
 LDA #&20
 JSR clr_scrn
 JSR clr_deflowr
 LDX &8C
 LDA ship_file,X
 CMP ship_load+&04
 BEQ ship_skip
 STA ship_load+&04
 LDX #LO(ship_load)
 LDY #HI(ship_load)
 JSR oscli

.ship_skip

 LDX &8C
 LDA ship_centre,X
 STA cursor_x
 PLA
 JSR write_msg2
 JSR hline_19
 JSR init_ship
 LDA #&60
 STA &54
 LDA #&B0
 STA &4D
 LDX #&7F
 STX &63
 STX &64
 INX
 STA vdu_stat
 LDA &8C
 JSR write_card
 LDX &8C
 LDA ship_posn,X
 JSR ins_ship

.l_release

 JSR scan_10
 BNE l_release

.l_395a

 LDX &8C
 LDA ship_dist,X
 CMP &4D
 BEQ l_3962
 DEC &4D

.l_3962

 JSR l_14e1
 LDA #&80
 STA &4C
 ASL A
 STA &46
 STA &49
 JSR l_400f
 DEC &8A
 JSR sync
 JSR scan_10
 BEQ l_395a
 JMP start_loop

.controls

 LDX #&03
 JSR menu
 ADC #&56
 PHA
 ADC #&04
 PHA
 LDA #&20
 JSR clr_scrn
 JSR clr_deflowr
 LDA #&0B
 STA cursor_x
 PLA
 JSR write_msg2
 JSR hline_19
 JSR set_deflowr
 INC cursor_y
 PLA
 JSR write_msg2
 JMP l_restart

.equip_data

 LDX #&04
 JSR menu
 ADC #&6B
 PHA
 SBC #&0C
 PHA
 LDA #&20
 JSR clr_scrn
 JSR clr_deflowr
 LDA #&0B
 STA cursor_x
 PLA
 JSR write_msg2
 JSR hline_19
 JSR set_deflowr
 JSR set_forclwr
 INC cursor_y
 INC cursor_y
 LDA #&01
 STA cursor_x
 PLA
 JSR write_msg2
 JMP l_restart

.trading


.l_restart

 JSR l_250e
 JMP start_loop


.write_card

 ASL A
 TAY
 LDA card_addr,Y
 STA &22
 LDA card_addr+1,Y
 STA &23

.card_repeat

 JSR clr_deflowr
 LDY #&00
 LDA (&22),Y
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
 STA cursor_x
 LDA card_pattern+1,Y
 STA cursor_y
 LDA card_pattern+2,Y
 BEQ card_details
 JSR write_msg2
 INY
 INY
 INY
 BNE card_found

.card_details

 JSR set_deflowr
 LDY #&00

.card_loop

 INY
 LDA (&22),Y
 BEQ card_end
 BMI card_msg
 CMP #&20
 BCC card_macro
 JSR msg_alpha
 JMP card_loop

.card_macro

 JSR msg_macro
 JMP card_loop

.card_msg

 CMP #&D7
 BCS card_pairs
 AND #&7F
 JSR write_msg2
 JMP card_loop

.card_pairs

 JSR msg_pairs
 JMP card_loop

.card_end

 TYA
 SEC
 ADC &22
 STA &22
 BCC card_repeat
 INC &23
 BCS card_repeat

.quit_card

 RTS


.ship_load

 EQUS "L.S.0", &0D


.ship_file

 EQUB 'A', 'H', 'I', 'K', 'J', 'P', 'B'
 EQUB 'N', 'A', 'B', 'A', 'M', 'E', 'B'
 EQUB 'G', 'I', 'M', 'A', 'O', 'F', 'E'
 EQUB 'L', 'L', 'C', 'C', 'P', 'A', 'H'


.ship_posn

 EQUB 19, 14, 27, 11, 20, 12, 17
 EQUB 11,  2,  2,  3, 25, 17, 11
 EQUB 20, 17, 17, 11, 22, 21, 11
 EQUB  9, 17, 29, 30, 10, 16, 15


.ship_dist

 EQUB &01, &02, &01, &02, &01, &01, &01
 EQUB &02, &04, &04, &01, &01, &01, &02
 EQUB &01, &02, &01, &02, &01, &01, &02
 EQUB &01, &01, &03, &01, &01, &01, &01


.menu

 LDA menu_entry,X
 STA &03AB
 LDA menu_offset,X
 STA &03AD
 LDA menu_query,X
 PHA
 LDA menu_title,X	
 PHA
 LDA menu_titlex,X
 PHA
 LDA #&20
 JSR clr_scrn
 JSR clr_deflowr
 PLA
 STA cursor_x
 PLA
 JSR write_msg2
 JSR hline_19
 JSR set_deflowr
 LDA #&80
 STA vdu_stat
 INC cursor_y
 LDX #&00

.menu_loop

 STX &89
 JSR new_line
 LDX &89
 INX
 CLC
 JSR writed_3
 JSR price_spc
 CLC
 LDA &89
 ADC &03AD
 JSR write_msg2
 LDX &89
 INX
 CPX &03AB
 BCC menu_loop
 JSR clr_line
 PLA
 JSR write_msg2
 LDA #'?'
 JSR punctuate
 JSR buy_quant
 BEQ menu_start
 BCS menu_start
 RTS

.menu_start

 JMP start_loop


.menu_title

 EQUB &01, &02, &03, &05, &04

.menu_titlex

 EQUB &05, &0C, &0C, &0C, &0B

.menu_offset

 EQUB &02, &07, &15, &5B, &5F

.menu_entry

 EQUB &04, &0E, &0E, &04, &0D

.menu_query

 EQUB &06, &43, &43, &05, &04

