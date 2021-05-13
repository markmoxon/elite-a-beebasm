
.d_3469

 LDA &65
 ORA #&A0
 STA &65

.d_3468

 RTS

.d_3470

 LDA &65
 AND #&40
 BEQ d_3479
 JSR d_34d3

.d_3479

 LDA &4C
 STA &D1
 LDA &4D
 CMP #&20
 BCC d_3487
 LDA #&FE
 BNE d_348f

.d_3487

 ASL &D1
 ROL A
 ASL &D1
 ROL A
 SEC
 ROL A

.d_348f

 STA &81
 LDY #&01
 LDA (&67),Y
 ADC #&04
 BCS d_3469
 STA (&67),Y
 JSR l_2316
 LDA &1B
 CMP #&1C
 BCC d_34a8
 LDA #&FE
 BNE d_34b1

.d_34a8

 ASL &82
 ROL A
 ASL &82
 ROL A
 ASL &82
 ROL A

.d_34b1

 DEY
 STA (&67),Y
 LDA &65
 AND #&BF
 STA &65
 AND #&08
 BEQ d_3468
 LDY #&02
 LDA (&67),Y
 TAY

.d_34c3

 LDA &F9,Y
 STA (&67),Y
 DEY
 CPY #&06
 BNE d_34c3
 LDA &65
 ORA #&40
 STA &65

.d_34d3

 LDY #&00
 LDA (&67),Y
 STA &81
 INY
 LDA (&67),Y
 BPL d_34e0
 EOR #&FF

.d_34e0

 LSR A
 LSR A
 LSR A
 ORA #&01
 STA &80
 INY
 LDA (&67),Y
 STA &8F
 LDA &01
 PHA
 LDY #&06

.d_34f1

 LDX #&03

.d_34f3

 INY
 LDA (&67),Y
 STA &D2,X
 DEX
 BPL d_34f3
 STY &93
 LDY #&02

.d_34ff

 INY
 LDA (&67),Y
 EOR &93
 STA &FFFD,Y
 CPY #&06
 BNE d_34ff
 LDY &80

.d_350d

 JSR d_3f85
 STA &88
 LDA &D3
 STA &82
 LDA &D2
 JSR d_354b
 BNE d_3545
 CPX #&BF
 BCS d_3545
 STX &35
 LDA &D5
 STA &82
 LDA &D4
 JSR d_354b
 BNE d_3533
 LDA &35
 JSR draw_pixel

.d_3533

 DEY
 BPL d_350d
 LDY &93
 CPY &8F
 BCC d_34f1
 PLA
 STA &01
 LDA &0906
 STA &03
 RTS

.d_3545

 JSR d_3f85
 JMP d_3533

.d_354b

 STA &83
 JSR d_3f85
 ROL A
 BCS d_355e
 JSR l_21fa
 ADC &82
 TAX
 LDA &83
 ADC #&00
 RTS

.d_355e

 JSR l_21fa
 STA &D1
 LDA &82
 SBC &D1
 TAX
 LDA &83
 SBC #&00
 RTS

.d_356d

 JSR show_missle
 LDA #&7F
 STA &63
 STA &64
 LDA home_tech
 AND #&02
 ORA #&80
 JMP ins_ship

.d_3580

 \	LDA cmdr_legal
 \	BEQ legal_over
 \legal_next
 \	DEC cmdr_legal
 \	LSR a
 \	BNE legal_next
 \legal_over
 \\	LSR cmdr_legal
 LDA hype_dist
 LDY #3

.legal_div

 LSR hype_dist+1
 ROR A
 DEY
 BNE legal_div
 SEC
 SBC cmdr_legal
 BCC legal_over
 LDA #&FF

.legal_over

 EOR #&FF
 STA cmdr_legal
 JSR init_ship
 LDA &6D
 AND #&03
 ADC #&03
 STA &4E
 ROR A
 STA &48
 STA &4B
 JSR d_356d
 LDA &6F
 AND #&07
 ORA #&81
 STA &4E
 LDA &71
 AND #&03
 STA &48
 STA &47
 LDA #&00
 STA &63
 STA &64
 LDA #&81
 JSR ins_ship

.d_35b1

 LDA &87
 BNE d_35d8

.d_35b5

 LDY &03C3

.d_35b8

 JSR rnd_seq
 ORA #&08
 STA &0FA8,Y
 STA &88
 JSR rnd_seq
 STA &0F5C,Y
 STA &34
 JSR rnd_seq
 STA &0F82,Y
 STA &35
 JSR d_1910
 DEY
 BNE d_35b8

.d_35d8

 JMP l_3283

.d_3619

 LDA #&95
 JSR tube_write
 TXA
 JMP tube_write

.d_3624

 DEX
 RTS

.d_3626

 INX
 BEQ d_3624

.d_3629

 DEC energy
 PHP
 BNE d_3632
 INC energy

.d_3632

 PLP
 RTS

.d_3642

 ASL A
 TAX
 LDA #&00
 ROR A
 TAY
 LDA #&14
 STA &81
 TXA
 JSR l_2316
 LDX &1B
 TYA
 BMI d_3658
 LDY #&00
 RTS

.d_3658

 LDY #&FF
 TXA
 EOR #&FF
 TAX
 INX
 RTS

.d_3634

 JSR d_3694
 LDY #&25
 LDA &0320
 BNE d_station
 LDY &9F	\ finder

.d_station

 JSR d_42ae
 LDA &34
 JSR d_3642
 TXA
 ADC #&C3
 STA &03A8
 LDA &35
 JSR d_3642
 STX &D1
 LDA #&CC
 SBC &D1
 STA &03A9
 LDA #&F0
 LDX &36
 BPL d_3691
 LDA #&FF

.d_3691

 STA &03C5

.d_3694

 LDA &03A9
 STA &35
 LDA &03A8
 STA &34
 LDA &03C5
 STA &91
 CMP #&F0
 BNE d_36ac
 \d_36a7:
 JSR d_36ac
 DEC &35

.d_36ac

 LDA #&90
 JSR tube_write
 LDA &34
 JSR tube_write
 LDA &35
 JSR tube_write
 LDA &91
 JMP tube_write

.d_36e4

 SEC	\ reduce damage
 SBC new_shields
 BCC n_shok

.n_through

 STA &D1
 LDX #&00
 LDY #&08
 LDA (&20),Y
 BMI d_36fe
 LDA f_shield
 SBC &D1
 BCC d_36f9
 STA f_shield

.n_shok

 RTS

.d_36f9

 STX f_shield
 BCC d_370c

.d_36fe

 LDA r_shield
 SBC &D1
 BCC d_3709
 STA r_shield
 RTS

.d_3709

 STX r_shield

.d_370c

 ADC energy
 STA energy
 BEQ d_3716
 BCS d_3719

.d_3716

 JMP d_41c6

.d_3719

 JSR d_43b1
 JMP d_45ea

.d_371f

 LDA &0901,Y
 STA &D2,X
 LDA &0902,Y
 PHA
 AND #&7F
 STA &D3,X
 PLA
 AND #&80
 STA &D4,X
 INY
 INY
 INY
 INX
 INX
 INX
 RTS

.ship_addr

 EQUW &0900, &0925, &094A, &096F, &0994, &09B9, &09DE, &0A03
 EQUW &0A28, &0A4D, &0A72, &0A97, &0ABC

.ship_ptr

 TXA
 ASL A
 TAY
 LDA ship_addr,Y
 STA &20
 LDA ship_addr+&01,Y
 STA &21
 RTS

.d_3740

 JSR draw_stn
 LDX #&81
 STX &66
 LDX #&FF
 STX &63
 INX
 STX &64
 STX ship_type+&01
 STX &67
 LDA cmdr_legal
 BPL n_enemy
 LDX #&04

.n_enemy

 STX &6A
 LDX #&0A
 JSR d_37fc
 JSR d_37fc
 STX &68
 JSR d_37fc
 LDA #&02

.ins_ship

 STA &D1
 LDX #&00

.d_376c

 LDA ship_type,X
 BEQ d_3778
 INX
 CPX #&0C
 BCC d_376c

.d_3776

 CLC

.d_3777

 RTS

.d_3778

 JSR ship_ptr
 LDA &D1
 BMI d_37d1
 ASL A
 TAY
 LDA ship_data+1,Y
 BEQ d_3776
 STA &1F
 LDA ship_data,Y
 STA &1E
 CPY #&04
 BEQ d_37c1
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
 BCC d_3777
 BNE d_37b7
 CPY #&25
 BCC d_3777

.d_37b7

 LDA &67
 STA &03B0
 LDA &68
 STA &03B1

.d_37c1

 LDY #&0E
 LDA (&1E),Y
 STA &69
 LDY #&13
 LDA (&1E),Y
 AND #&07
 STA &65
 LDA &D1

.d_37d1

 STA ship_type,X
 TAX
 BMI d_37e5
 CPX #&03
 BCC d_37e2
 CPX #&0B
 BCS d_37e2
 INC &033E

.d_37e2

 INC &031E,X

.d_37e5

 LDY &D1
 LDA ship_flags,Y
 AND #&6F
 ORA &6A
 STA &6A
 LDY #&24

.d_37f2

 LDA &46,Y
 STA (&20),Y
 DEY
 BPL d_37f2
 SEC
 RTS

.d_37fc

 LDA &46,X
 EOR #&80
 STA &46,X
 INX
 INX
 RTS

.d_3805

 LDX #&FF

.d_3807

 STX &45
 LDX cmdr_misl
 DEX
 JSR d_383d
 STY target
 RTS

.d_3813

 LDA #&20
 STA &30
 ASL A
 JSR sound

.draw_ecm

 LDA #&93
 JMP tube_write

.draw_stn

 LDA #&92
 JMP tube_write

.d_383d

 CPX #4
 BCC n_mok
 LDX #3

.n_mok

 JMP put_missle

.d_3856

 LDA &46
 STA &1B
 LDA &47
 STA &1C
 LDA &48
 JSR d_3cfa
 BCS d_388d
 LDA &40
 ADC #&80
 STA &D2
 TXA
 ADC #&00
 STA &D3
 LDA &49
 STA &1B
 LDA &4A
 STA &1C
 LDA &4B
 EOR #&80
 JSR d_3cfa
 BCS d_388d
 LDA &40
 ADC #&60
 STA &E0
 TXA
 ADC #&00
 STA &E1
 CLC

.d_388d

 RTS

.d_388e

 LDA &8C
 LSR A
 BCS d_3896
 JMP d_3bed

.d_3896

 JMP d_3c30

.d_3899

 LDA &4E
 BMI d_388e
 CMP #&30
 BCS d_388e
 ORA &4D
 BEQ d_388e
 JSR d_3856
 BCS d_388e
 LDA #&60
 STA &1C
 LDA #&00
 STA &1B
 JSR d_297e
 LDA &41
 BEQ d_38bd
 LDA #&F8
 STA &40

.d_38bd

 LDA &8C
 LSR A
 BCC d_38c5
 JMP l_33cb

.d_38c5

 JSR d_3bed
 JSR d_3b76
 BCS d_38d1
 LDA &41
 BEQ d_38d2

.d_38d1

 RTS

.d_38d2

 LDA &8C
 CMP #&80
 BNE d_3914
 LDA &40
 CMP #&06
 BCC d_38d1
 LDA &54
 EOR #&80
 STA &1B
 LDA &5A
 JSR d_3cdb
 LDX #&09
 JSR d_3969
 STA &9B
 STY &09
 JSR d_3969
 STA &9C
 STY &0A
 LDX #&0F
 JSR d_3ceb
 JSR d_3987
 LDA &54
 EOR #&80
 STA &1B
 LDA &60
 JSR d_3cdb
 LDX #&15
 JSR d_3ceb
 JMP d_3987

.d_3914

 LDA &5A
 BMI d_38d1
 LDX #&0F
 JSR d_3cba
 CLC
 ADC &D2
 STA &D2
 TYA
 ADC &D3
 STA &D3
 JSR d_3cba
 STA &1B
 LDA &E0
 SEC
 SBC &1B
 STA &E0
 STY &1B
 LDA &E1
 SBC &1B
 STA &E1
 LDX #&09
 JSR d_3969
 LSR A
 STA &9B
 STY &09
 JSR d_3969
 LSR A
 STA &9C
 STY &0A
 LDX #&15
 JSR d_3969
 LSR A
 STA &9D
 STY &0B
 JSR d_3969
 LSR A
 STA &9E
 STY &0C
 LDA #&40
 STA &8F
 LDA #&00
 STA &94
 BEQ d_398b

.d_3969

 LDA &46,X
 STA &1B
 LDA &47,X
 AND #&7F
 STA &1C
 LDA &47,X
 AND #&80
 JSR d_297e
 LDA &40
 LDY &41
 BEQ d_3982
 LDA #&FE

.d_3982

 LDY &43
 INX
 INX
 RTS

.d_3987

 LDA #&1F
 STA &8F

.d_398b

 LDX #&00
 STX &93
 DEX
 STX &92

.d_3992

 LDA &94
 AND #&1F
 TAX
 LDA _07C0,X
 STA &81
 LDA &9D
 JSR l_21fa
 STA &82
 LDA &9E
 JSR l_21fa
 STA &40
 LDX &94
 CPX #&21
 LDA #&00
 ROR A
 STA &0E
 LDA &94
 CLC
 ADC #&10
 AND #&1F
 TAX
 LDA _07C0,X
 STA &81
 LDA &9C
 JSR l_21fa
 STA &42
 LDA &9B
 JSR l_21fa
 STA &1B
 LDA &94
 ADC #&0F
 AND #&3F
 CMP #&21
 LDA #&00
 ROR A
 STA &0D
 LDA &0E
 EOR &0B
 STA &83
 LDA &0D
 EOR &09
 JSR scale_angle
 STA &D1
 BPL d_39fb
 TXA
 EOR #&FF
 CLC
 ADC #&01
 TAX
 LDA &D1
 EOR #&7F
 ADC #&00
 STA &D1

.d_39fb

 TXA
 ADC &D2
 STA &76
 LDA &D1
 ADC &D3
 STA &77
 LDA &40
 STA &82
 LDA &0E
 EOR &0C
 STA &83
 LDA &42
 STA &1B
 LDA &0D
 EOR &0A
 JSR scale_angle
 EOR #&80
 STA &D1
 BPL d_3a30
 TXA
 EOR #&FF
 CLC
 ADC #&01
 TAX
 LDA &D1
 EOR #&7F
 ADC #&00
 STA &D1

.d_3a30

 JSR l_1a16
 CMP &8F
 BEQ d_3a39
 BCS d_3a45

.d_3a39

 LDA &94
 CLC
 ADC &95
 AND #&3F
 STA &94
 JMP d_3992

.d_3a45

 RTS

.d_3b76

 JSR l_35b7
 BCS d_3a45
 LDA #&00
 STA &0EC0
 LDX &40
 LDA #&08
 CPX #&08
 BCC d_3b8e
 LSR A
 CPX #&3C
 BCC d_3b8e
 LSR A

.d_3b8e

 STA &95
 JMP circle

.d_3bed

 LDY &0EC0
 BNE d_3c26

.d_3bf2

 CPY &6B
 BCS d_3c26
 LDA &0F0E,Y
 CMP #&FF
 BEQ d_3c17
 STA &37
 LDA &0EC0,Y
 STA &36
 JSR draw_line
 INY
 \	LDA &90
 \	BNE d_3bf2
 LDA &36
 STA &34
 LDA &37
 STA &35
 JMP d_3bf2

.d_3c17

 INY
 LDA &0EC0,Y
 STA &34
 LDA &0F0E,Y
 STA &35
 INY
 JMP d_3bf2

.d_3c26

 LDA #&01
 STA &6B
 LDA #&FF
 STA &0EC0

.d_3c2f

 RTS

.d_3c30

 LDA &0E00
 BMI d_3c2f
 LDA &28
 STA &26
 LDA &29
 STA &27
 LDY #&BF

.d_3c3f

 LDA &0E00,Y
 BEQ d_3c47
 JSR l_1909

.d_3c47

 DEY
 BNE d_3c3f
 DEY
 STY &0E00
 RTS

.d_3cba

 JSR d_3969
 STA &1B
 LDA #&DE
 STA &81
 STX &80
 JSR price_mult
 LDX &80
 LDY &43
 BPL d_3cd8
 EOR #&FF
 CLC
 ADC #&01
 BEQ d_3cd8
 LDY #&FF
 RTS

.d_3cd8

 LDY #&00
 RTS

.d_3cdb

 STA &81
 JSR d_2a3c
 LDX &54
 BMI d_3ce6
 EOR #&80

.d_3ce6

 LSR A
 LSR A
 STA &94
 RTS

.d_3ceb

 JSR d_3969
 STA &9D
 STY &0B
 JSR d_3969
 STA &9E
 STY &0C
 RTS

.d_3cfa

 JSR d_297e
 LDA &43
 AND #&7F
 ORA &42
 BNE d_3cb8
 LDX &41
 CPX #&04
 BCS d_3d1e
 LDA &43
 BPL d_3d1e
 LDA &40
 EOR #&FF
 ADC #&01
 STA &40
 TXA
 EOR #&FF
 ADC #&00
 TAX
 CLC

.d_3d1e

 RTS

.d_3cb8

 SEC
 RTS

.d_3d74

 LDA &1B
 STA &03B0
 LDA &1C
 STA &03B1
 RTS

.d_3d7f

 LDX &84
 JSR d_3dd8
 LDX &84
 JMP d_1376

.d_3d89

 JSR init_ship
 JSR l_32b0
 STA ship_type+&01
 STA &0320
 JSR draw_stn
 LDA #&06
 STA &4B
 LDA #&81
 JMP ins_ship

.d_3da1

 LDX #&FF

.d_3da3

 INX
 LDA ship_type,X
 BEQ d_3d74
 CMP #&01
 BNE d_3da3
 TXA
 ASL A
 TAY
 LDA ship_addr,Y
 STA ptr
 LDA ship_addr+&01,Y
 STA ptr+&01
 LDY #&20
 LDA (ptr),Y
 BPL d_3da3
 AND #&7F
 LSR A
 CMP &96
 BCC d_3da3
 BEQ d_3dd2
 SBC #&01
 ASL A
 ORA #&80
 STA (ptr),Y
 BNE d_3da3

.d_3dd2

 LDA #&00
 STA (ptr),Y
 BEQ d_3da3

.d_3dd8

 STX &96
 CPX &45
 BNE d_3de8
 LDY #&EE
 JSR d_3805
 LDA #&C8
 JSR d_45c6

.d_3de8

 LDY &96
 LDX ship_type,Y
 CPX #&02
 BEQ d_3d89
 CPX #&1F
 BNE d_3dfd
 LDA cmdr_mission
 ORA #&02
 STA cmdr_mission

.d_3dfd

 CPX #&03
 BCC d_3e08
 CPX #&0B
 BCS d_3e08
 DEC &033E

.d_3e08

 DEC &031E,X
 LDX &96
 LDY #&05
 LDA (&1E),Y
 LDY #&21
 CLC
 ADC (&20),Y
 STA &1B
 INY
 LDA (&20),Y
 ADC #&00
 STA &1C

.d_3e1f

 INX
 LDA ship_type,X
 STA &0310,X
 BNE d_3e2b
 JMP d_3da1

.d_3e2b

 ASL A
 TAY
 LDA ship_data,Y
 STA ptr
 LDA ship_data+1,Y
 STA ptr+&01
 LDY #&05
 LDA (ptr),Y
 STA &D1
 LDA &1B
 SEC
 SBC &D1
 STA &1B
 LDA &1C
 SBC #&00
 STA &1C
 TXA
 ASL A
 TAY
 LDA ship_addr,Y
 STA ptr
 LDA ship_addr+&01,Y
 STA ptr+&01
 LDY #&24
 LDA (ptr),Y
 STA (&20),Y
 DEY
 LDA (ptr),Y
 STA (&20),Y
 DEY
 LDA (ptr),Y
 STA &41
 LDA &1C
 STA (&20),Y
 DEY
 LDA (ptr),Y
 STA &40
 LDA &1B
 STA (&20),Y
 DEY

.d_3e75

 LDA (ptr),Y
 STA (&20),Y
 DEY
 BPL d_3e75
 LDA ptr
 STA &20
 LDA ptr+&01
 STA &21
 LDY &D1

.d_3e86

 DEY
 LDA (&40),Y
 STA (&1B),Y
 TYA
 BNE d_3e86
 BEQ d_3e1f

.rand_posn

 JSR init_ship
 JSR rnd_seq
 STA &46
 STX &49
 STA &06
 LSR A
 ROR &48
 LSR A
 ROR &4B
 LSR A
 STA &4A
 TXA
 AND #&1F
 STA &47
 LDA #&50
 SBC &47
 SBC &4A
 STA &4D
 JMP rnd_seq

.d_3eb8

 LDX cmdr_galxy
 DEX
 BNE d_3ecc
 LDA cmdr_homex
 CMP #&90
 BNE d_3ecc
 LDA cmdr_homey
 CMP #&21
 BEQ d_3ecd

.d_3ecc

 CLC

.d_3ecd

 RTS

.d_3f62

 JSR rand_posn	\ IN
 CMP #&F5
 ROL A
 ORA #&C0
 STA &66

.d_3f85

 CLC
 JMP rnd_seq

.d_3f9a

 JSR rnd_seq
 LSR A
 STA &66
 STA &63
 ROL &65
 AND #&0F
 STA &61
 JSR rnd_seq
 BMI d_3fb9
 LDA &66
 ORA #&C0
 STA &66
 LDX #&10
 STX &6A

.d_3fb9

 LDA #&0B
 LDX #&03
 JMP hordes

.d_3fc0

 JSR d_1228
 DEC &034A
 BEQ d_3f54
 BPL d_3fcd
 INC &034A

.d_3fcd

 DEC &8A
 BEQ d_3fd4

.d_3fd1

 JMP d_40db

.d_3f54

 LDA &03A4
 JSR d_45c6
 LDA #&00
 STA &034A
 JMP d_3fcd

.d_3fd4

 LDA &0341
 BNE d_3fd1
 JSR rnd_seq
 CMP #&33	\ trader fraction
 BCS d_402e
 LDA &033E
 CMP #&03
 BCS d_402e
 JSR rand_posn	\ IN
 BVS d_3f9a
 ORA #&6F
 STA &63
 LDA &0320
 BNE d_4033
 TXA
 BCS d_401e
 AND #&0F
 STA &61
 BCC d_4022

.d_401e

 ORA #&7F
 STA &64

.d_4022

 JSR rnd_seq
 CMP #&0A
 AND #&01
 ADC #&05
 BNE horde_plain

.d_402e

 LDA &0320
 BEQ d_4036

.d_4033

 JMP d_40db

.d_4036

 JSR d_41a6
 ASL A
 LDX &032E
 BEQ d_4042
 ORA cmdr_legal

.d_4042

 STA &D1
 JSR d_3f62
 CMP &D1
 BCS d_4050
 LDA #&10

.horde_plain

 LDX #&00
 BEQ hordes

.d_4050

 LDA &032E
 BNE d_4033
 DEC &0349
 BPL d_4033
 INC &0349
 LDA cmdr_mission
 AND #&0C
 CMP #&08
 BNE d_4070
 JSR rnd_seq
 CMP #&C8
 BCC d_4070
 JSR d_320e

.d_4070

 JSR rnd_seq
 LDY home_govmt
 BEQ d_4083
 CMP #&78
 BCS d_4033
 AND #&07
 CMP home_govmt
 BCC d_4033

.d_4083

 CPX #&64
 BCS d_40b2
 INC &0349
 AND #&03
 ADC #&19
 TAY
 JSR d_3eb8
 BCC d_40a8
 LDA #&F9
 STA &66
 LDA cmdr_mission
 AND #&03
 LSR A
 BCC d_40a8
 ORA &033D
 BEQ d_40aa

.d_40a8

 TYA
 EQUB &2C

.d_40aa

 LDA #&1F
 JSR ins_ship
 JMP d_40db

.d_40b2

 LDA #&11
 LDX #&07

.hordes

 STA horde_base+1
 STX horde_mask+1
 JSR rnd_seq
 CMP #&F8
 BCS horde_large
 STA &89
 TXA
 AND &89
 AND #&03

.horde_large

 AND #&07
 STA &0349
 STA &89

.d_40b9

 JSR rnd_seq
 STA &D1
 TXA
 AND &D1

.horde_mask

 AND #&FF
 STA &0FD2

.d_40c8

 LDA &0FD2
 CLC

.horde_base

 ADC #&00
 INC &61	\ space out horde
 INC &47
 INC &4A
 JSR ins_ship
 CMP #&18
 BCS d_40d7
 DEC &0FD2
 BPL d_40c8

.d_40d7

 DEC &89
 BPL d_40b9

.d_40db

 LDX #&FF
 TXS
 LDX laser_t
 BEQ d_40e6
 DEC laser_t

.d_40e6

 JSR console
 JSR d_3634
 LDA &87
 BEQ d_40f8
 \	AND x_flag
 \	LSR A
 \	BCS d_40f8
 LDY #&02
 JSR y_sync
 \	JSR sync

.d_40f8

 JSR d_44af
 JSR chk_dirn

.d_40fb

 PHA
 LDA &2F
 BNE d_locked
 PLA
 JSR check_mode
 JMP d_3fc0

.d_locked

 PLA
 JSR d_416c
 JMP d_3fc0

.check_mode

 CMP #&76
 BNE not_status
 JMP status

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
 JSR snap_hype
 JMP data_onsys

.not_data

 CMP #&77
 BNE not_invnt
 JMP inventory

.not_invnt

 CMP #&16
 BNE not_price
 JMP mark_price

.not_price

 CMP #&32
 BEQ distance
 CMP #&43
 BNE not_find
 LDA &87
 AND #&C0
 BEQ n_finder
 LDA dockedp
 BNE not_map
 JMP find_plant

.n_finder

 LDA dockedp
 BEQ not_map
 LDA &9F
 EOR #&25
 STA &9F
 JMP sync

.not_map

 RTS

.not_find

 CMP #&36
 BNE not_home
 \	STA &06
 LDA &87
 AND #&C0
 BEQ not_map
 \	LDA &2F
 \	BNE not_map
 \	LDA &06
 JSR map_cursor
 JSR set_home
 \	JSR map_cursor
 JMP map_cursor

.not_home

 CMP #&21
 BNE not_cour
 LDA &87
 AND #&C0
 BEQ not_map
 LDA cmdr_cour
 ORA cmdr_cour+1
 BEQ not_map
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

.not_cour

 BIT dockedp
 BMI flying
 CMP #&20
 BNE not_launch
 JSR l_3c91
 BMI jump_stay
 JMP launch

.jump_stay

 JMP stay_here

.not_launch

 CMP #&73
 BNE not_equip
 JMP equip

.not_equip

 CMP #&71
 BNE not_buy
 JMP buy_cargo

.not_buy

 CMP #&47
 BNE not_disk
 JSR disk_menu
 BCC not_loaded
 JMP not_loadc

.not_loaded

 JMP start_loop

.not_disk

 CMP #&72
 BNE not_sell
 JMP sell_cargo

.not_sell

 CMP #&54
 BNE not_hype
 JSR clr_line
 LDA #&0F
 STA cursor_x
 LDA #&CD
 JMP write_msg1

.flying

 CMP #&20
 BNE d_4135
 JMP d_3292

.d_4135

 CMP #&71
 BCC d_4143
 CMP #&74
 BCS d_4143
 AND #&03
 TAX
 JMP d_5493

.d_4143

 CMP #&54
 BNE not_hype
 JMP d_3011

.d_416c

 LDA &2F
 BEQ d_418a
 DEC &2E
 BNE d_418a
 LDX &2F
 DEX
 JSR d_30ac
 LDA #&05
 STA &2E
 LDX &2F
 JSR d_30ac
 DEC &2F
 BNE d_418a
 JMP d_3254

.d_41a6

 LDA cmdr_cargo+&03
 CLC
 ADC cmdr_cargo+&06
 ASL A
 ADC cmdr_cargo+&0A

.d_418a

 RTS

.not_hype

 LDA &87
 AND #&C0
 BEQ d_418a
 JMP add_dirn

.d_41b2

 LDA #&E0

.d_41b4

 CMP &47
 BCC d_41be
 CMP &4A
 BCC d_41be
 CMP &4D

.d_41be

 RTS

.d_41bf

 ORA &47
 ORA &4A
 ORA &4D
 RTS

.d_41c6

 JSR d_43b1
 JSR clr_common
 ASL &7D
 ASL &7D
 LDX #&18
 JSR d_3619
 JSR clr_scrn
 JSR d_54eb
 JSR d_35b5
 LDA #&0C
 STA cursor_y
 STA cursor_x
 LDA #&92
 JSR l_323f

.d_41e9

 JSR d_3f62
 LSR A
 LSR A
 STA &46
 LDY #&00
 STY &87
 STY &47
 STY &4A
 STY &4D
 STY &66
 DEY
 STY &8A
 \	STY &0346
 EOR #&2A
 STA &49
 ORA #&50
 STA &4C
 TYA
 JSR write_0346
 TXA
 AND #&8F
 STA &63
 ROR A
 AND #&87
 STA &64
 LDX #&05
 \LDA &5607
 \BEQ d_421e
 BCC d_421e
 DEX

.d_421e

 JSR d_251d
 JSR rnd_seq
 AND #&80
 LDY #&1F
 STA (&20),Y
 LDA ship_type+&04
 BEQ d_41e9
 JSR d_44a4
 STA &7D

.d_4234

 JSR d_1228
 JSR read_0346
 BNE d_4234
 LDX #&1F
 JSR d_3619
 JMP d_1220

.launch

 JSR d_4255
 JSR clr_boot
 LDA #&FF
 STA &8E
 STA &87
 STA dockedp
 LDA #&20
 JMP d_40fb

.d_4255

 LDA #0
 STA &9F	\ reset finder

.d_427e

 LDX #&00
 LDA home_tech
 CMP #&0A
 BCS mix_station
 INX

.mix_station

 LDY #&02
 JSR install_ship
 LDY #9

.mix_retry

 LDA #0
 STA &34

.mix_match

 JSR rnd_seq
 CMP #ship_total	\ # POSSIBLE SHIPS
 BCS mix_match
 ASL A
 ASL A
 STA &35
 TYA
 AND #&07
 TAX
 LDA mix_bits,X
 LDX &35
 CPY #16
 BCC mix_byte2
 CPY #24
 BCC mix_byte3
 INX	\24-28

.mix_byte3

 INX	\16-23

.mix_byte2

 INX	\8-15
 AND ship_bits,X
 BEQ mix_fail

.mix_try

 JSR rnd_seq
 LDX &35
 CMP ship_bytes,X
 BCC mix_ok

.mix_fail

 DEC &34
 BNE mix_match
 LDX #ship_total*4

.mix_ok

 STY &36
 CPX #52		\ ANACONDA?
 BEQ mix_anaconda
 CPX #116	\ DRAGON?
 BEQ mix_dragon
 TXA
 LSR A
 LSR A
 TAX

.mix_install

 JSR install_ship
 LDY &36

.mix_next

 INY
 CPY #15
 BNE mix_skip
 INY
 INY

.mix_skip

 CPY #29
 BNE mix_retry
 RTS

.mix_anaconda

 LDX #13
 LDY #14
 JSR install_ship
 LDX #14
 LDY #15
 JMP mix_install

.mix_dragon

 LDX #29
 LDY #14
 JSR install_ship
 LDX #17
 LDY #15
 JMP mix_install

.mix_bits

 EQUB &01, &02, &04, &08, &10, &20, &40, &80

.d_42ae

 LDX #&00
 JSR d_371f
 JSR d_371f
 JSR d_371f

.d_42bd

 LDA &D2
 ORA &D5
 ORA &D8
 ORA #&01
 STA &DB
 LDA &D3
 ORA &D6
 ORA &D9

.d_42cd

 ASL &DB
 ROL A
 BCS d_42e0
 ASL &D2
 ROL &D3
 ASL &D5
 ROL &D6
 ASL &D8
 ROL &D9
 BCC d_42cd

.d_42e0

 LDA &D3
 LSR A
 ORA &D4
 STA &34
 LDA &D6
 LSR A
 ORA &D7
 STA &35
 LDA &D9
 LSR A
 ORA &DA
 STA &36
 JMP l_3bd6

.d_434e

 LDX &033E
 LDA ship_type+&02,X
 ORA &033E	\ no jump if any ship
 ORA &0320
 ORA &0341
 BNE d_439f
 LDY &0908
 BMI d_4368
 TAY
 JSR d_1c43
 LSR A
 BEQ d_439f

.d_4368

 LDY &092D
 BMI d_4375
 LDY #&25
 JSR d_1c41
 LSR A
 BEQ d_439f

.d_4375

 LDA #&81
 STA &83
 STA &82
 STA &1B
 LDA &0908
 JSR scale_angle
 STA &0908
 LDA &092D
 JSR scale_angle
 STA &092D
 LDA #&01
 STA &87
 STA &8A
 LSR A
 STA &0349
 LDX view_dirn
 JMP d_5493

.d_439f

 LDA #&28
 JMP sound

.d_43b1

 JSR sound_10
 LDA #&18
 JMP sound

.d_43be

 LDX #&01
 JSR d_2590
 BCC d_4418
 LDA #&78
 JSR d_45c6

.n_sound30

 LDA #&30
 JMP sound

.d_4418

 RTS

.d_43ce

 INC cmdr_kills
 BNE d_43db
 INC cmdr_kills+&01
 LDA #&65
 JSR d_45c6

.d_43db

 LDX #&07

.d_43dd

 STX &D1
 LDA #&18
 JSR pp_sound
 LDA &4D
 LSR A
 LSR A
 AND &D1
 ORA #&F1
 STA &0B
 JSR sound_rdy

.sound_10

 LDA #&10
 JMP sound

.d_4429

 LDA #&96
 JSR tube_write
 TYA
 JSR tube_write
 LDA b_flag
 JSR tube_write
 JSR tube_read
 BPL b_quit
 STA last_key,Y

.b_quit

 RTS

.d_4473

 LDA &033F
 BNE d_44c7
 LDY #&01
 JSR d_4429
 INY
 JSR d_4429
 JSR scan_fire
 EOR #&10
 STA &0307
 LDX #&01
 JSR adval
 ORA #&01
 STA adval_x
 LDX #&02
 JSR adval
 EOR y_flag
 STA adval_y
 JMP d_4555

.d_44a4

 LDA #&00
 LDY #&10

.d_44a8

 STA last_key,Y
 DEY
 BNE d_44a8
 RTS

.d_44af

 JSR d_44a4
 LDA &2F
 BEQ d_open
 JMP d_4555

.d_open

 LDA k_flag
 BNE d_4473
 LDY #&07

.d_44bc

 JSR d_4429
 DEY
 BNE d_44bc
 LDA &033F
 BEQ d_4526

.d_44c7

 JSR init_ship
 LDA #&60
 STA &54
 ORA #&80
 STA &5C
 STA &8C
 LDA &7D	\ ? Too Fast
 STA &61
 JSR d_2346
 LDA &61
 CMP #&16
 BCC d_44e3
 LDA #&16

.d_44e3

 STA &7D
 LDA #&FF
 LDX #&00
 LDY &62
 BEQ d_44f3
 BMI d_44f0
 INX

.d_44f0

 STA &0301,X

.d_44f3

 LDA #&80
 LDX #&00
 ASL &63
 BEQ d_450f
 BCC d_44fe
 INX

.d_44fe

 BIT &63
 BPL d_4509
 LDA #&40
 STA adval_x
 LDA #&00

.d_4509

 STA &0303,X
 LDA adval_x

.d_450f

 STA adval_x
 LDA #&80
 LDX #&00
 ASL &64
 BEQ d_4523
 BCS d_451d
 INX

.d_451d

 STA &0305,X
 LDA adval_y

.d_4523

 STA adval_y

.d_4526

 LDX adval_x
 LDA #&07
 LDY &0303
 BEQ d_4533
 JSR d_2a16

.d_4533

 LDY &0304
 BEQ d_453b
 JSR d_2a26

.d_453b

 STX adval_x
 ASL A
 LDX adval_y
 LDY &0305
 BEQ d_454a
 JSR d_2a26

.d_454a

 LDY &0306
 BEQ d_4552
 JSR d_2a16

.d_4552

 STX adval_y

.d_4555

 JSR scan_10
 STX last_key
 CPX #&69
 BNE d_459c

.d_455f

 JSR sync
 JSR scan_10
 CPX #&51
 BNE d_456e
 LDA #&00
 STA s_flag

.d_456e

 LDY #&40

.d_4570

 JSR tog_flags
 INY
 CPY #&48
 BNE d_4570
 CPX #&10
 BNE d_457f
 STX s_flag

.d_457f

 CPX #&70
 BNE d_4586
 JMP d_1220

.d_4586

 \	CPX #&37
 \	BNE dont_dump
 \	JSR printer
 \dont_dump
 CPX #&59
 BNE d_455f

.d_459c

 LDA &87
 BNE d_45b4
 LDY #&10

.d_45a4

 JSR d_4429
 DEY
 CPY #&07
 BNE d_45a4

.d_45b4

 RTS

.d_45b5

 STX &034A
 PHA
 LDA &03A4
 JSR d_45dd
 PLA
 EQUB &2C

.cargo_mtok

 ADC #&D0

.d_45c6

 LDX #&00
 STX vdu_stat
 LDY #&09
 STY cursor_x
 LDY #&16
 STY cursor_y
 CPX &034A
 BNE d_45b5
 STY &034A
 STA &03A4

.d_45dd

 JSR de_token
 LSR &034B
 BCC d_45b4
 LDA #&FD
 JMP de_token

.d_45ea

 JSR rnd_seq
 BMI d_45b4
 \	CPX #&17
 CPX #&18
 BCS d_45b4
 \	LDA cmdr_cargo,X
 LDA cmdr_hold,X
 BEQ d_45b4
 LDA &034A
 BNE d_45b4
 LDY #&03
 STY &034B
 \	STA cmdr_cargo,X
 STA cmdr_hold,X
 DEX
 BMI d_45c1
 CPX #&11
 BEQ d_45c1
 TXA
 BCC cargo_mtok

.d_460e

 CMP #&12
 BNE equip_mtok	\BEQ l_45c4
 \l_45c4
 LDA #&6F-&6B-1
 \	EQUB &2C

.d_45c1

 \	LDA #&6C
 ADC #&6B-&5D
 \	EQUB &2C

.equip_mtok

 ADC #&5D
 INC new_hold	\**
 BNE d_45c6

.d_4889

 JMP d_3899

.d_488c

 LDA &8C
 BMI d_4889
 JMP l_400f

.d_50a0

 LDA &65
 AND #&A0
 BNE d_50cb
 LDA &8A
 EOR &84
 AND #&0F
 BNE d_50b1
 JSR l_3e06

.d_50b1

 LDX &8C
 BPL d_50b8
 JMP d_533d

.d_50b8

 LDA &66
 BPL d_50cb
 CPX #&01
 BEQ d_50c8
 LDA &8A
 EOR &84
 AND #&07
 BNE d_50cb

.d_50c8

 JSR d_217a

.d_50cb

 JSR d_5558
 LDA &61
 ASL A
 ASL A
 STA &81
 LDA &50
 AND #&7F
 JSR l_21fa
 STA &82
 LDA &50
 LDX #&00
 JSR d_524a
 LDA &52
 AND #&7F
 JSR l_21fa
 STA &82
 LDA &52
 LDX #&03
 JSR d_524a
 LDA &54
 AND #&7F
 JSR l_21fa
 STA &82
 LDA &54
 LDX #&06
 JSR d_524a
 LDA &61
 CLC
 ADC &62
 BPL d_510d
 LDA #&00

.d_510d

 LDY #&0F
 CMP (&1E),Y
 BCC d_5115
 LDA (&1E),Y

.d_5115

 STA &61
 LDA #&00
 STA &62
 LDX &31
 LDA &46
 EOR #&FF
 STA &1B
 LDA &47
 JSR d_2877
 STA &1D
 LDA &33
 EOR &48
 LDX #&03
 JSR d_5308
 STA &9E
 LDA &1C
 STA &9C
 EOR #&FF
 STA &1B
 LDA &1D
 STA &9D
 LDX &2B
 JSR d_2877
 STA &1D
 LDA &9E
 EOR &7B
 LDX #&06
 JSR d_5308
 STA &4E
 LDA &1C
 STA &4C
 EOR #&FF
 STA &1B
 LDA &1D
 STA &4D
 JSR d_2879
 STA &1D
 LDA &9E
 STA &4B
 EOR &7B
 EOR &4E
 BPL d_517d
 LDA &1C
 ADC &9C
 STA &49
 LDA &1D
 ADC &9D
 STA &4A
 JMP d_519d

.d_517d

 LDA &9C
 SBC &1C
 STA &49
 LDA &9D
 SBC &1D
 STA &4A
 BCS d_519d
 LDA #&01
 SBC &49
 STA &49
 LDA #&00
 SBC &4A
 STA &4A
 LDA &4B
 EOR #&80
 STA &4B

.d_519d

 LDX &31
 LDA &49
 EOR #&FF
 STA &1B
 LDA &4A
 JSR d_2877
 STA &1D
 LDA &32
 EOR &4B
 LDX #&00
 JSR d_5308
 STA &48
 LDA &1D
 STA &47
 LDA &1C
 STA &46

.d_51bf

 LDA &7D
 STA &82
 LDA #&80
 LDX #&06
 JSR d_524c
 LDA &8C
 AND #&81
 CMP #&81
 BEQ d_frig
 JMP l_14f2

.d_frig

 RTS

.d_524a

 AND #&80

.d_524c

 ASL A
 STA &83
 LDA #&00
 ROR A
 STA &D1
 LSR &83
 EOR &48,X
 BMI d_526f
 LDA &82
 ADC &46,X
 STA &46,X
 LDA &83
 ADC &47,X
 STA &47,X
 LDA &48,X
 ADC #&00
 ORA &D1
 STA &48,X
 RTS

.d_526f

 LDA &46,X
 SEC
 SBC &82
 STA &46,X
 LDA &47,X
 SBC &83
 STA &47,X
 LDA &48,X
 AND #&7F
 SBC #&00
 ORA #&80
 EOR &D1
 STA &48,X
 BCS d_52a0
 LDA #&01
 SBC &46,X
 STA &46,X
 LDA #&00
 SBC &47,X
 STA &47,X
 LDA #&00
 SBC &48,X
 AND #&7F
 ORA &D1
 STA &48,X

.d_52a0

 RTS

.d_5308

 TAY
 EOR &48,X
 BMI d_531c
 LDA &1C
 CLC
 ADC &46,X
 STA &1C
 LDA &1D
 ADC &47,X
 STA &1D
 TYA
 RTS

.d_531c

 LDA &46,X
 SEC
 SBC &1C
 STA &1C
 LDA &47,X
 SBC &1D
 STA &1D
 BCC d_532f
 TYA
 EOR #&80
 RTS

.d_532f

 LDA #&01
 SBC &1C
 STA &1C
 LDA #&00
 SBC &1D
 STA &1D
 TYA
 RTS

.d_533d

 LDA &8D
 EOR #&80
 STA &81
 LDA &46
 STA &1B
 LDA &47
 STA &1C
 LDA &48
 JSR d_2782
 LDX #&03
 JSR d_1d4c
 LDA &41
 STA &9C
 STA &1B
 LDA &42
 STA &9D
 STA &1C
 LDA &2A
 STA &81
 LDA &43
 STA &9E
 JSR d_2782
 LDX #&06
 JSR d_1d4c
 LDA &41
 STA &1B
 STA &4C
 LDA &42
 STA &1C
 STA &4D
 LDA &43
 STA &4E
 EOR #&80
 JSR d_2782
 LDA &43
 AND #&80
 STA &D1
 EOR &9E
 BMI d_53a8
 LDA &40
 CLC
 ADC &9B
 LDA &41
 ADC &9C
 STA &49
 LDA &42
 ADC &9D
 STA &4A
 LDA &43
 ADC &9E
 JMP d_53db

.d_53a8

 LDA &40
 SEC
 SBC &9B
 LDA &41
 SBC &9C
 STA &49
 LDA &42
 SBC &9D
 STA &4A
 LDA &9E
 AND #&7F
 STA &1B
 LDA &43
 AND #&7F
 SBC &1B
 STA &1B
 BCS d_53db
 LDA #&01
 SBC &49
 STA &49
 LDA #&00
 SBC &4A
 STA &4A
 LDA #&00
 SBC &1B
 ORA #&80

.d_53db

 EOR &D1
 STA &4B
 LDA &8D
 STA &81
 LDA &49
 STA &1B
 LDA &4A
 STA &1C
 LDA &4B
 JSR d_2782
 LDX #&00
 JSR d_1d4c
 LDA &41
 STA &46
 LDA &42
 STA &47
 LDA &43
 STA &48
 JMP d_51bf

.d_5404

 DEX
 BNE d_5438
 LDA &48
 EOR #&80
 STA &48
 LDA &4E
 EOR #&80
 STA &4E
 LDA &50
 EOR #&80
 STA &50
 LDA &54
 EOR #&80
 STA &54
 LDA &56
 EOR #&80
 STA &56
 LDA &5A
 EOR #&80
 STA &5A
 LDA &5C
 EOR #&80
 STA &5C
 LDA &60
 EOR #&80
 STA &60
 RTS

.d_5438

 LDA #&00
 CPX #&02
 ROR A
 STA &9A
 EOR #&80
 STA &99
 LDA &46
 LDX &4C
 STA &4C
 STX &46
 LDA &47
 LDX &4D
 STA &4D
 STX &47
 LDA &48
 EOR &99
 TAX
 LDA &4E
 EOR &9A
 STA &48
 STX &4E
 LDY #&09
 JSR d_546c
 LDY #&0F
 JSR d_546c
 LDY #&15

.d_546c

 LDA &46,Y
 LDX &4A,Y
 STA &4A,Y
 STX &46,Y
 LDA &47,Y
 EOR &99
 TAX
 LDA &4B,Y
 EOR &9A
 STA &47,Y
 STX &4B,Y

.d_5486

 RTS

.d_5487

 STX view_dirn
 JSR clr_scrn
 JSR d_54aa
 JMP d_35b1

.d_5493

 LDA #&00
 LDY &87
 BNE d_5487
 CPX view_dirn
 BEQ d_5486
 STX view_dirn
 JSR clr_scrn
 JSR d_1a05
 JSR d_35d8

.d_54aa

 LDY view_dirn
 LDA cmdr_laser,Y
 BEQ d_5486
 LDA #&80
 STA &73
 LDA #&48
 STA &74
 LDA #&14
 STA &75
 JSR map_cross
 LDA #&0A
 STA &75
 JMP map_cross

.iff_xor

 EQUB &00, &00, &0F	\, &FF, &F0 overlap

.iff_base

 EQUB &FF, &F0, &FF, &F0, &FF

.d_5557

 RTS

.d_5558

 LDA &65
 AND #&10
 BEQ d_5557
 LDA &8C
 BMI d_5557
 LDX cmdr_hold	\ iff code
 BEQ iff_not
 LDY #&24
 LDA (&20),Y
 ASL A
 ASL A
 BCS iff_cop
 ASL A
 BCS iff_trade
 LDY &8C
 DEY
 BEQ iff_missle
 CPY #&08
 BCC iff_aster
 INX	\ X=4

.iff_missle

 INX	\ X=3

.iff_aster

 INX	\ X=2

.iff_cop

 INX	\ X=1

.iff_trade

 INX	\ X=0

.iff_not

 LDA iff_base,X
 STA &91
 LDA iff_xor,X
 STA &37
 LDA &47
 ORA &4A
 ORA &4D
 AND #&C0
 BNE d_5557
 LDA &47
 CLC
 LDX &48
 BPL d_5581
 EOR #&FF
 ADC #&01

.d_5581

 ADC #&7B
 STA &34
 LDA &4D
 LSR A
 LSR A
 CLC
 LDX &4E
 BPL d_5591
 EOR #&FF
 SEC

.d_5591

 ADC #&23
 EOR #&FF
 STA ptr
 LDA &4A
 LSR A
 CLC
 LDX &4B
 BMI d_55a2
 EOR #&FF
 SEC

.d_55a2

 ADC ptr
 BPL d_55b0
 CMP #&C2
 BCS d_55ac
 LDA #&C2

.d_55ac

 CMP #&F7
 BCC d_55b2

.d_55b0

 LDA #&F6

.d_55b2

 STA &35
 SEC
 SBC ptr
 TAX
 LDA #&91
 JSR tube_write
 LDA &34
 JSR tube_write
 LDA &35
 JSR tube_write
 LDA &91
 JSR tube_write
 LDA &37
 JSR tube_write
 TXA
 JSR tube_write
 LDX #0
 RTS
