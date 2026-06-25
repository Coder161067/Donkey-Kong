; Donkey Kong for Atari 2600
; Assembled with DASM - NTSC 4K ROM
    processor 6502

; TIA write registers
VSYNC   equ $00
VBLANK  equ $01
WSYNC   equ $02
NUSIZ0  equ $04
NUSIZ1  equ $05
COLUP0  equ $06
COLUP1  equ $07
COLUPF  equ $08
COLUBK  equ $09
CTRLPF  equ $0A
REFP0   equ $0B
REFP1   equ $0C
PF0     equ $0D
PF1     equ $0E
PF2     equ $0F
RESP0   equ $10
RESP1   equ $11
RESM0   equ $12
RESM1   equ $13
AUDC0   equ $15
AUDC1   equ $16
AUDF0   equ $17
AUDF1   equ $18
AUDV0   equ $19
AUDV1   equ $1A
HMP0    equ $20
HMP1    equ $21
HMM0    equ $22
HMM1    equ $23
HMOVE   equ $2B
GRP0    equ $2D
GRP1    equ $2E
ENAM0   equ $2F
ENAM1   equ $30
RESMP0  equ $29
RESMP1  equ $2A

; TIA collision read registers
CXM0P   equ $00
CXM1P   equ $01
CXPPMM  equ $07
INPT4   equ $0C
SWCHA   equ $280
INTIM   equ $284
TIM64T  equ $296

; ===== Zero Page RAM ($80-$FF) =====
    seg.u vars
    org $80

FCnt  ds 1
Rnd   ds 1
GStat ds 1
JM_X  ds 1
JM_Y  ds 1
JM_D  ds 1
JM_J  ds 1
JM_V  ds 1
JM_G  ds 1
JM_H  ds 1
B1_X  ds 1
B1_Y  ds 1
B1_A  ds 1
B1_D  ds 1
B2_X  ds 1
B2_Y  ds 1
B2_A  ds 1
B2_D  ds 1
Lives ds 1
DK_T  ds 1
SLoc  ds 1
Tmp   ds 1
Tmp2  ds 1
HmpV  ds 1
P0Row ds 1
P1Row ds 1
B1On  ds 1
B2On  ds 1
PFCol ds 1

; ===== Code =====
    seg code
    org $F000

Start
    sei
    cld
    ldx #0
    txa
    tay
Clear
    sta 0,x
    inx
    bne Clear
    ldx #$FF
    txs
    lda #3
    sta Lives
    lda #76
    sta JM_X
    lda #150
    sta JM_Y
    lda #160
    sta JM_G

; ===== FRAME LOOP =====
Main
    lda #2
    sta VSYNC
    sta WSYNC
    sta WSYNC
    sta WSYNC
    lda #0
    sta VSYNC
    lda #%01000010
    sta VBLANK
    jsr DoLogic
    jsr PosSpr
    lda #43
    sta TIM64T
VWait
    lda INTIM
    bne VWait
    lda #0
    sta VBLANK
    jsr DoKernel
    lda #%01000010
    sta VBLANK
    lda #35
    sta TIM64T
OWait
    lda INTIM
    bne OWait
    lda #0
    sta VBLANK
    inc FCnt
    jmp Main

; ===== GAME LOGIC =====
DoLogic
    lda GStat
    cmp #0
    beq DoTitle
    cmp #1
    beq DoPlay
    cmp #2
    beq DoDying
    rts

DoTitle
    lda INPT4
    bmi TitleWait
    lda FCnt
    and #$0F
    bne TitleWait
    lda #1
    sta GStat
    lda #76
    sta JM_X
    lda #150
    sta JM_Y
    lda #160
    sta JM_G
    lda #0
    sta JM_J
    sta JM_V
    sta B1_A
    sta B2_A
    lda #3
    sta Lives
    lda #60
    sta DK_T
TitleWait
    rts

DoDying
    lda JM_H
    beq DyingCont
    dec JM_H
    rts
DyingCont
    dec Lives
    bpl DyingRespawn
    lda #0
    sta GStat
    rts
DyingRespawn
    lda #1
    sta GStat
    lda #76
    sta JM_X
    lda #150
    sta JM_Y
    lda #160
    sta JM_G
    lda #0
    sta JM_J
    sta JM_V
    rts

DoPlay
    ; Left joystick (SWCHA bit 1, active low)
    lda SWCHA
    and #%00000010
    bne DoPlayRight
    lda JM_X
    sec
    sbc #2
    bmi DoPlayJump
    sta JM_X
    lda #1
    sta JM_D
    jmp DoPlayJump
DoPlayRight
    lda SWCHA
    and #%00000001
    bne DoPlayJump
    lda JM_X
    clc
    adc #2
    cmp #150
    bcs DoPlayJump
    sta JM_X
    lda #0
    sta JM_D

DoPlayJump
    lda INPT4
    bmi DoPlayNoJump
    lda JM_J
    bne DoPlayNoJump
    lda #1
    sta JM_J
    lda #$F0
    sta JM_V
    lda #12
    sta AUDC0
    lda #8
    sta AUDF0
    lda #8
    sta AUDV0

DoPlayNoJump
    lda JM_J
    beq DoPlayGround
    lda JM_V
    clc
    adc #4
    sta JM_V
    lda JM_Y
    clc
    adc JM_V
    sta JM_Y
    lda JM_Y
    cmp JM_G
    bcc DoPlayDK
    lda JM_G
    sta JM_Y
    lda #0
    sta JM_J
    sta JM_V
    sta AUDV0
    jmp DoPlayDK

DoPlayGround
    lda JM_Y
    cmp #160
    bcc DoPlaySetGround
    lda #160
    sta JM_G
    lda JM_G
    sta JM_Y
    jmp DoPlayDK
DoPlaySetGround
    lda JM_Y
    sec
    sbc #$10
    sta JM_G

DoPlayDK
    dec DK_T
    bne DoPlayBarrel
    lda #40
    sta DK_T
    lda B1_A
    beq DoPlaySpawn1
    lda B2_A
    beq DoPlaySpawn2
    jmp DoPlayBarrel
DoPlaySpawn1
    lda #1
    sta B1_A
    lda #50
    sta B1_X
    lda #30
    sta B1_Y
    lda FCnt
    and #$01
    sta B1_D
    jmp DoPlayBarrel
DoPlaySpawn2
    lda #1
    sta B2_A
    lda #50
    sta B2_X
    lda #30
    sta B2_Y
    lda FCnt
    and #$01
    sta B2_D

DoPlayBarrel
    lda B1_A
    beq DoPlayB2
    lda B1_Y
    clc
    adc #1
    sta B1_Y
    lda FCnt
    and #$01
    bne DoPlayB2
    lda B1_D
    beq DoPlayB1R
    lda B1_X
    sec
    sbc #1
    sta B1_X
    jmp DoPlayB2
DoPlayB1R
    lda B1_X
    clc
    adc #1
    sta B1_X
DoPlayB2
    lda B2_A
    beq DoPlayBChk
    lda B2_Y
    clc
    adc #1
    sta B2_Y
    lda FCnt
    and #$01
    bne DoPlayBChk
    lda B2_D
    beq DoPlayB2R
    lda B2_X
    sec
    sbc #1
    sta B2_X
    jmp DoPlayBChk
DoPlayB2R
    lda B2_X
    clc
    adc #1
    sta B2_X

DoPlayBChk
    lda B1_Y
    cmp #192
    bcc DoPlayBChk2
    lda #0
    sta B1_A
DoPlayBChk2
    lda B2_Y
    cmp #192
    bcc DoPlayCollide
    lda #0
    sta B2_A

DoPlayCollide
    lda B1_A
    beq DoPlayCollide2
    lda JM_X
    sec
    sbc B1_X
    bpl Col1Pos
    eor #$FF
    clc
    adc #1
Col1Pos
    cmp #10
    bcs DoPlayCollide2
    lda JM_Y
    sec
    sbc B1_Y
    bpl Col1PosY
    eor #$FF
    clc
    adc #1
Col1PosY
    cmp #12
    bcs DoPlayCollide2
    jmp KillJumpman

DoPlayCollide2
    lda B2_A
    beq DoPlayFall
    lda JM_X
    sec
    sbc B2_X
    bpl Col2Pos
    eor #$FF
    clc
    adc #1
Col2Pos
    cmp #10
    bcs DoPlayFall
    lda JM_Y
    sec
    sbc B2_Y
    bpl Col2PosY
    eor #$FF
    clc
    adc #1
Col2PosY
    cmp #12
    bcs DoPlayFall

KillJumpman
    lda #2
    sta GStat
    lda #50
    sta JM_H
    lda #4
    sta AUDC1
    lda #3
    sta AUDF1
    lda #10
    sta AUDV1
    rts

DoPlayFall
    lda JM_Y
    cmp #190
    bcc DoPlayDone
    lda #2
    sta GStat
    lda #40
    sta JM_H
DoPlayDone
    rts

; ===== SPRITE POSITIONING =====
PosSpr
    lda JM_X
    ldx #0
    jsr PosOne
    lda #40
    ldx #1
    jsr PosOne
    lda B1_A
    beq PosSpr2
    lda B1_X
    ldx #2
    jsr PosOne
PosSpr2
    lda B2_A
    beq PosSprEnd
    lda B2_X
    ldx #3
    jsr PosOne
PosSprEnd
    sta WSYNC
    sta HMOVE
    rts

; Position one sprite/missile
; A=X position, X=0(P0) 1(P1) 2(M0) 3(M1)
PosOne
    sec
    sta Tmp
    ldy #15
PosDiv
    sbc #15
    bcs PosDiv
    eor #$FF
    adc #1
    asl
    asl
    asl
    asl
    sta HmpV
    cpx #0
    beq PosResp0
    cpx #1
    beq PosResp1
    cpx #2
    beq PosResm0
    sta RESM1
    lda HmpV
    sta HMM1
    rts
PosResm0
    sta RESM0
    lda HmpV
    sta HMM0
    rts
PosResp1
    sta RESP1
    lda HmpV
    sta HMP1
    rts
PosResp0
    sta RESP0
    lda HmpV
    sta HMP0
    rts

; ===== DISPLAY KERNEL =====
DoKernel
    lda #$00
    sta COLUBK
    lda #$1C
    sta COLUP0
    lda #$C6
    sta COLUP1
    lda #%00000001
    sta CTRLPF
    lda #%00100000
    sta NUSIZ0
    sta NUSIZ1
    lda #0
    sta RESMP0
    sta RESMP1
    lda #0
    sta GRP0
    sta GRP1
    sta ENAM0
    sta ENAM1
    sta SLoc
    sta P0Row
    sta P1Row
    sta B1On
    sta B2On
    sta PFCol

    ldx #192
KernLoop
    lda P0Row
    sta GRP0
    lda P1Row
    sta GRP1
    lda B1On
    sta ENAM0
    lda B2On
    sta ENAM1
    lda PFCol
    sta COLUPF
    cmp #$C4
    beq KernGirder
    lda #0
    sta PF0
    sta PF1
    sta PF2
    jmp KernPFok
KernGirder
    lda #$FF
    sta PF0
    sta PF1
    sta PF2
KernPFok

    inc SLoc
    lda SLoc

    cmp #8
    bcc KernGirder2
    cmp #16
    bcs KernP1
    jmp KernOpen
KernP1
    cmp #22
    bcc KernGirder2
    cmp #38
    bcc KernOpen
    cmp #44
    bcc KernGirder2
    cmp #60
    bcc KernOpen
    cmp #66
    bcc KernGirder2
    cmp #82
    bcc KernOpen
    cmp #88
    bcc KernGirder2
    cmp #104
    bcc KernOpen
    cmp #110
    bcc KernGirder2
    cmp #126
    bcc KernOpen
    cmp #132
    bcc KernGirder2
    jmp KernOpen

KernGirder2
    lda #$C4
    sta PFCol
    jmp KernP0
KernOpen
    lda #$00
    sta PFCol

KernP0
    lda SLoc
    sec
    sbc JM_Y
    bmi KernP0off
    cmp #8
    bcs KernP0off
    tay
    lda JMSpr,y
    sta P0Row
    jmp KernP1draw
KernP0off
    lda #0
    sta P0Row

KernP1draw
    lda SLoc
    sec
    sbc #6
    bmi KernP1off
    cmp #10
    bcs KernP1off
    tay
    lda DKSpr,y
    sta P1Row
    jmp KernB1
KernP1off
    lda #0
    sta P1Row

KernB1
    lda B1_A
    beq KernB1off
    lda B1_Y
    sec
    sbc SLoc
    bpl KernB1chk
    eor #$FF
    clc
    adc #1
KernB1chk
    cmp #3
    bcs KernB1off
    lda #%00000010
    sta B1On
    jmp KernB2
KernB1off
    lda #0
    sta B1On

KernB2
    lda B2_A
    beq KernB2off
    lda B2_Y
    sec
    sbc SLoc
    bpl KernB2chk
    eor #$FF
    clc
    adc #1
KernB2chk
    cmp #3
    bcs KernB2off
    lda #%00000010
    sta B2On
    jmp KernWait
KernB2off
    lda #0
    sta B2On

KernWait
    dex
    beq KernDone
    sta WSYNC
    jmp KernLoop

KernDone
    sta WSYNC
    rts

; ===== SPRITE BITMAPS =====
JMSpr
    .byte $3C, $7E, $DB, $FF, $7E, $7E, $3C, $24
DKSpr
    .byte $00, $3C, $7E, $FF, $FF, $7E, $5A, $66, $66, $7E

; ===== RESET VECTORS =====
    org $FFFC
    .word Start
    .word Start
