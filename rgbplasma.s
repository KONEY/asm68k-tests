; Programmed by Yragael for Stash of Code (http://www.stashofcode.fr) in 2017.

; This work is made available under the terms of the Creative Commons Attribution-Noncommercial-ShareAlike License 4.0 France.

; RGB plasma. Several versions are displayed successively, resulting from the different combinations of sources A, B and C that the blitter allows.

; Based on the explanations given in the article "Le RGB plasma" by St phane Rubinstein in Amiga News Tech n 31 (March 1992)

; Version with precalculations and the use of Blitter to modify the colors in the Copper list. This optimization is not at all effective on A1200, but it is day and night on A500: without optimization, it is possible to display at most 60 lines in the frame, while with optimization it is possible to 'display 256 (and there is still time: it only takes 273 raster lines!)
;---------- Constantes ----------

;Registres

FMODE=$1FC
VPOSR=$004
INTENA=$09A
INTENAR=$01C
INTREQ=$09C
INTREQR=$01E
DMACON=$096
DMACONR=$002
DIWSTRT=$08E
DIWSTOP=$090
BPLCON0=$100
BPLCON1=$102
BPLCON2=$104
DDFSTRT=$092
DDFSTOP=$094
BPL1MOD=$108
BPL2MOD=$10A
BPL1PTH=$0E0
BPL1PTL=$0E2
COLOR00=$180
COLOR01=$182
COP1LCH=$080
COPJMP1=$088
BLTAFWM=$044
BLTALWM=$046
BLTAPTH=$050
BLTBPTH=$04C
BLTCPTH=$048
BLTDPTH=$054
BLTAMOD=$064
BLTBMOD=$062
BLTCMOD=$060
BLTDMOD=$066
BLTADAT=$074
BLTCON0=$040
BLTCON1=$042
BLTSIZE=$058

;Programme

DISPLAY_X=$81
DISPLAY_Y=$2C
DISPLAY_DX=320
DISPLAY_DY=256
DISPLAY_DEPTH=1
COPSIZE=13*4+DISPLAY_DY*(4+((DISPLAY_DX>>3)+1)*4)+4

;Param�tres du plasma

BORDER_COLOR=$0000
OFFSET_AMPLITUDE=10
OFFSET_ROW_SPEED=2
RED_START=359<<1
RED_ROW_SPEED=1
RED_FRAME_SPEED=3
RED_AMPLITUDE=18		;OFFSET_AMPLITUDE+RED_AMPLITUDE doit �tre <= 29
GREEN_START=90<<1
GREEN_ROW_SPEED=3
GREEN_FRAME_SPEED=3
GREEN_AMPLITUDE=15		;OFFSET_AMPLITUDE+GREEN_AMPLITUDE doit �tre <= 29
BLUE_START=60<<1
BLUE_ROW_SPEED=12
BLUE_FRAME_SPEED=6
BLUE_AMPLITUDE=19		;OFFSET_AMPLITUDE+BLUE_AMPLITUDE doit �tre <= 29
MINTERMS_SPEED=100		;Exprim� en trames (1/50 seconde)

;---------- Macros ----------

WAITBLIT:	MACRO
_waitBlitter0\@
	btst #14,DMACONR(a5)
	bne _waitBlitter0\@
_waitBlitter1\@
	btst #14,DMACONR(a5)
	bne _waitBlitter1\@
	ENDM

;---------- Initialisations ----------

;Empiler les registres

	movem.l d0-d7/a0-a6,-(sp)
	lea $dff000,a5

;Allouer de la m�moire en CHIP mise � 0 pour la Copper list

	move.l #COPSIZE,d0
	move.l #$10002,d1
	movea.l $4,a6
	jsr -198(a6)
	move.l d0,copperList0

	move.l #COPSIZE,d0
	move.l #$10002,d1
	movea.l $4,a6
	jsr -198(a6)
	move.l d0,copperList1

;Allouer de la m�moire en CHIP mise � 0 pour le bitplane

	move.l #DISPLAY_DY*(DISPLAY_DX>>3),d0
	move.l #$10002,d1
	movea.l $4,a6
	jsr -198(a6)
	move.l d0,bitplane

;Allouer de la m�moire pour les offsets des lignes
	
	move.l #DISPLAY_DY<<1,d0
	move.l #$10002,d1
	movea.l $4,a6
	jsr -198(a6)
	move.l d0,rowOffsets

;Allouer de la m�moire pour les offsets des composantes

	move.l #3*(360<<1),d0
	move.l #$10002,d1
	movea.l $4,a6
	jsr -198(a6)
	move.l d0,rgbOffsets

;Couper le syst�me

	movea.l $4,a6
	jsr -132(a6)

;Couper les interruptions hardware et les DMA

	move.w INTENAR(a5),intena_v
	move.w #$7FFF,INTENA(a5)
	move.w INTREQR(a5),intreq_v
	move.w #$7FFF,INTREQ(a5)
	move.w DMACONR(a5),dmacon_v
	move.w #$07FF,DMACON(a5)

;---------- Copper list ----------

	movea.l copperList0,a0

;Configuration de l'�cran

	move.w #DIWSTRT,(a0)+
	move.w #(DISPLAY_Y<<8)!DISPLAY_X,(a0)+
	move.w #DIWSTOP,(a0)+
	move.w #((DISPLAY_Y+DISPLAY_DY-256)<<8)!(DISPLAY_X+DISPLAY_DX-256),(a0)+
	move.w #BPLCON0,(a0)+
	move.w #(DISPLAY_DEPTH<<12)!$0200,(a0)+
	move.w #BPLCON1,(a0)+
	move.w #$0000,(a0)+
	move.w #BPLCON2,(a0)+
	move.w #$0000,(a0)+
	move.w #DDFSTRT,(a0)+
	move.w #((DISPLAY_X-17)>>1)&$00FC,(a0)+
	move.w #DDFSTOP,(a0)+
	move.w #((DISPLAY_X-17+(((DISPLAY_DX>>4)-1)<<4))>>1)&$00FC,(a0)+
	move.w #BPL1MOD,(a0)+
	move.w #0,(a0)+
	move.w #BPL2MOD,(a0)+
	move.w #0,(a0)+

;Comptabilit� ECS avec AGA

	move.w #FMODE,(a0)+
	move.w #$0000,(a0)+

;Adresse du bitplane

	move.w #BPL1PTL,(a0)+
	move.l bitplane,d0
	move.w d0,(a0)+
	move.w #BPL1PTH,(a0)+
	swap d0
	move.w d0,(a0)+

;Palette

	move.w #COLOR00,(a0)+
	move.w #BORDER_COLOR,(a0)+

;Plasma (WAIT et valeur de COLOR01 non renseign�s)

	move.w #DISPLAY_DY-1,d0
_copperListRows:
	move.l #$00000000,(a0)+
	move.w #DISPLAY_DX>>3,d1	;41 MOV par ligne, et non 40...
_copperListCols:
	move.w #COLOR01,(a0)+
	move.w #$0000,(a0)+
	dbf d1,_copperListCols
	dbf d0,_copperListRows

;Fin

	move.l #$FFFFFFFE,(a0)

;Double buffering de la Copper list

	movea.l copperList0,a0
	movea.l copperList1,a1
	move.w #(COPSIZE>>2)-1,d0
_copperListCopy:
	move.l (a0)+,(a1)+
	dbf d0,_copperListCopy

;Activer les DMA

	move.w #$83C0,DMACON(a5)	;DMAEN=1, COPEN=1, BPLEN=1, COPEN=1, BLTEN=1

;D�marrer la Copper list

	move.l copperList0,COP1LCH(a5)
	clr.w COPJMP1(a5)

;---------- Pr�calculs ----------

;Surface du plasma (simple rectangle de couleur 1)

	WAITBLIT
	move.w #$FFFF,BLTADAT(a5)
	move.w #0,BLTDMOD(a5)
	move.w #$01F0,BLTCON0(a5)	;Ne pas utiliser la source A pour alimenter BLTADAT mais D = Abc | AbC | ABc | ABC = A
	move.w #$0000,BLTCON1(a5)
	move.l bitplane,BLTDPTH(a5)
	move.w #(DISPLAY_DX>>4)!(DISPLAY_DY<<6),BLTSIZE(a5)

;Offsets des lignes

	movea.l rowOffsets,a0
	lea sinus,a1
	move.w #(360-1)<<1,d1
	move.w #DISPLAY_DY-1,d0
_rowOffsetsLoop:
	move.w (a1,d1.w),d2
	muls #OFFSET_AMPLITUDE,d2
	swap d2
	rol.l #2,d2
	addi.w #OFFSET_AMPLITUDE,d2
	bclr #0,d2					;Revient � diviser Dn par 2 pour le rapport � [0, AMPLITUDE] puis � le multiplier par 2 pour qu'il permette d'adresser un WORD
	move.w d2,(a0)+
	subi.w #OFFSET_ROW_SPEED<<1,d1
	bge _rowOffsetsLoopNoSinusUnderflow
	addi.w #360<<1,d1
_rowOffsetsLoopNoSinusUnderflow:
	dbf d0,_rowOffsetsLoop

;Offsets des composantes

	movea.l rgbOffsets,a0
	lea sinus,a1
	move.w #360-1,d0
_redOffsetsLoop:
	move.w (a1)+,d1
	muls #RED_AMPLITUDE,d1
	swap d1
	rol.l #2,d1
	addi.w #RED_AMPLITUDE,d1
	bclr #0,d1					;Revient � diviser Dn par 2 pour le rapport � [0, AMPLITUDE] puis � le multiplier par 2 pour qu'il permette d'adresser un WORD
	move.w d1,(a0)+
	dbf d0,_redOffsetsLoop

	lea sinus,a1
	move.w #360-1,d0
_greenOffsetsLoop:
	move.w (a1)+,d1
	muls #GREEN_AMPLITUDE,d1
	swap d1
	rol.l #2,d1
	addi.w #GREEN_AMPLITUDE,d1
	bclr #0,d1					;Revient � diviser Dn par 2 pour le rapport � [0, AMPLITUDE] puis � le multiplier par 2 pour qu'il permette d'adresser un WORD
	move.w d1,(a0)+
	dbf d0,_greenOffsetsLoop

	lea sinus,a1
	move.w #360-1,d0
_blueOffsetsLoop:
	move.w (a1)+,d1
	muls #BLUE_AMPLITUDE,d1
	swap d1
	rol.l #2,d1
	addi.w #BLUE_AMPLITUDE,d1
	bclr #0,d1					;Revient � diviser Dn par 2 pour le rapport � [0, AMPLITUDE] puis � le multiplier par 2 pour qu'il permette d'adresser un WORD
	move.w d1,(a0)+
	dbf d0,_blueOffsetsLoop

;Configuration du Blitter

	WAITBLIT
	move.w #$0000,BLTCON1(a5)
	move.w #0,BLTAMOD(a5)
	move.w #0,BLTBMOD(a5)
	move.w #0,BLTCMOD(a5)
	move.w #2,BLTDMOD(a5)
	move.w #$FFFF,BLTAFWM(a5)
	move.w #$FFFF,BLTALWM(a5)

;Timer et offset pour cycler les valeurs de BLTCON0 afin de tester les 256 combinaisons de minterms

	move.w #(256-1)<<1,d7	;Offset dans bltcon0
	swap d7
	move.w #1,d7			;Timer

;---------- Programme principal ----------

;Boucle principale

_loop:

;Attendre la fin de la trame

_waitEndOfFrame:
	move.l VPOSR(a5),d0
	lsr.l #8,d0
	and.w #$01FF,d0
	cmp.w #DISPLAY_Y+DISPLAY_DY,d0
	blt _waitEndOfFrame

;Changer de copper list

	move.l copperList0,COP1LCH(a5)
	clr.w COPJMP1(a5)
	move.l copperList1,a0
	move.l copperList0,copperList1
	move.l a0,copperList0

;Configurer les minterms (tous sauf abc pour D = A | B | C)

	WAITBLIT
	subq.w #1,d7
	bge _mintermsNoChange
	move.w #MINTERMS_SPEED,d7
	swap d7
	lea bltcon0_v,a1
	move.w (a1,d7.w),BLTCON0(a5)
	subq.w #2,d7
	bne _mintermsNoUnderflow
	move.w #(256-1)<<1,d7
_mintermsNoUnderflow:
	swap d7
_mintermsNoChange:

;G�n�rer la copper list

	lea 13*4(a0),a0
	movea.l rowOffsets,a6
	move.w redSinus,d3
	move.w greenSinus,d4
	move.w blueSinus,d5
	move.w #((DISPLAY_Y&$00FF)<<8)!((((DISPLAY_X-4)>>2)<<1)&$00FE)!$0001,d0
	move.w #DISPLAY_DY-1,d1
_rows:

	;WAIT (alterner la position horizontale entre DISPLAY_X-4 et DISPLAY_X d'une ligne � l'autre pour att�nuer l'effet de blocs g�n�r� par la longueur des MOV, 8 pixels)

	btst #0,d1
	beq _lineEven
	bset #1,d0
	bra _lineOdd
_lineEven:
	bclr #1,d0
_lineOdd:
	move.w d0,(a0)+
	move.w #$FFFE,(a0)+

	;Offsets de d�part sinuso�daux dans les composantes
	
	movea.l rgbOffsets,a1
	move.w (a1,d3.w),d6
	add.w (a6),d6
	lea red,a2
	lea (a2,d6.w),a2

	lea 360<<1(a1),a1
	move.w (a1,d4.w),d6
	add.w (a6),d6
	lea green,a3
	lea (a3,d6.w),a3

	lea 360<<1(a1),a1
	move.w (a1,d5.w),d6
	add.w (a6)+,d6		;Passer � la ligne suivante par la m�me occasion
	lea blue,a4
	lea (a4,d6.w),a4

	;S�rie de MOV
	
	WAITBLIT
	move.l a2,BLTAPTH(a5)
	move.l a3,BLTBPTH(a5)
	move.l a4,BLTCPTH(a5)
	lea 2(a0),a0
	move.l a0,BLTDPTH(a5)
	move.w #1!(((DISPLAY_DX>>3)+1)<<6),BLTSIZE(a5)

	;Passer � la ligne suivante

	addi.w #$0100,d0
	lea 4*((DISPLAY_DX>>3)+1)-2(a0),a0

	;Incr�menter les sinus de la ligne

	subi.w #RED_ROW_SPEED<<1,d3
	bge _noRedRowSinusUnderflow
	addi.w #360<<1,d3
_noRedRowSinusUnderflow:
	subi.w #GREEN_ROW_SPEED<<1,d4
	bge _noGreenRowSinusUnderflow
	addi.w #360<<1,d4
_noGreenRowSinusUnderflow:
	subi.w #BLUE_ROW_SPEED<<1,d5
	bge _noBlueRowSinusUnderflow
	addi.w #360<<1,d5
_noBlueRowSinusUnderflow:

	dbf d1,_rows

;Animer les sinus des composantes

	move.w redSinus,d3
	subi.w #RED_FRAME_SPEED<<1,d3
	bge _noRedSinusUnderflow
	addi.w #360<<1,d3
_noRedSinusUnderflow:
	move.w d3,redSinus

	move.w greenSinus,d4
	subi.w #GREEN_FRAME_SPEED<<1,d4
	bge _noGreenSinusUnderflow
	addi.w #360<<1,d4
_noGreenSinusUnderflow:
	move.w d4,greenSinus

	move.w blueSinus,d5
	subi.w #BLUE_FRAME_SPEED<<1,d5
	bge _noBlueSinusUnderflow
	addi.w #360<<1,d5
_noBlueSinusUnderflow:
	move.w d5,blueSinus
	
;Tester la pression du bouton gauche de la souris

	btst #6,$bfe001
	bne _loop
	WAITBLIT

;---------- Finalisations ----------

;Couper les interruptions hardware et les DMA

	move.w #$7FFF,INTENA(a5)
	move.w #$7FFF,INTREQ(a5)
	move.w #$07FF,DMACON(a5)

;R�tablir les interruptions hardware et les DMA

	move.w dmacon_v,d0
	bset #15,d0
	move.w d0,DMACON(a5)
	move.w intreq_v,d0
	bset #15,d0
	move.w d0,INTREQ(a5)
	move.w intena_v,d0
	bset #15,d0
	move.w d0,INTENA(a5)

;R�tablir la Copper list

	lea graphicslibrary,a1
	movea.l $4,a6
	jsr -408(a6)
	move.l d0,a1
	move.l 38(a1),COP1LCH(a5)
	clr.w COPJMP1(a5)
	jsr -414(a6)

;R�tablir le syst�me

	movea.l $4,a6
	jsr -138(a6)

;Lib�rer la m�moire

	movea.l copperList0,a1
	move.l #COPSIZE,d0
	movea.l $4,a6
	jsr -210(a6)

	movea.l copperList1,a1
	move.l #COPSIZE,d0
	movea.l $4,a6
	jsr -210(a6)

	movea.l bitplane,a1
	move.l #DISPLAY_DY*(DISPLAY_DX>>3),d0
	movea.l $4,a6
	jsr -210(a6)

	movea.l rowOffsets,a1
	move.l #DISPLAY_DY<<1,d0
	movea.l $4,a6
	jsr -210(a6)

	movea.l rgbOffsets,a1
	move.l #3*(360<<1),d0
	movea.l $4,a6
	jsr -210(a6)

;D�piler les registres

	movem.l (sp)+,d0-d7/a0-a6
	rts

;---------- Donn�es ----------

	SECTION yragael,DATA_C
bitplane:		DC.L 0
rgbOffsets:	DC.L 0
rowOffsets:	DC.L 0
graphicslibrary:	DC.B "graphics.library",0
	even
copperList0:	DC.L 0
copperList1:	DC.L 0
dmacon_v:		DC.W 0
intena_v:		DC.W 0
intreq_v:		DC.W 0
redSinus:		DC.W RED_START
greenSinus:	DC.W GREEN_START
blueSinus:		DC.W BLUE_START
sinus:		DC.W 0, 286, 572, 857, 1143, 1428, 1713, 1997, 2280, 2563, 2845, 3126, 3406, 3686, 3964, 4240, 4516, 4790, 5063, 5334, 5604, 5872, 6138, 6402, 6664, 6924, 7182, 7438, 7692, 7943, 8192, 8438, 8682, 8923, 9162, 9397, 9630, 9860, 10087, 10311, 10531, 10749, 10963, 11174, 11381, 11585, 11786, 11982, 12176, 12365, 12551, 12733, 12911, 13085, 13255, 13421, 13583, 13741, 13894, 14044, 14189, 14330, 14466, 14598, 14726, 14849, 14968, 15082, 15191, 15296, 15396, 15491, 15582, 15668, 15749, 15826, 15897, 15964, 16026, 16083, 16135, 16182, 16225, 16262, 16294, 16322, 16344, 16362, 16374, 16382, 16384, 16382, 16374, 16362, 16344, 16322, 16294, 16262, 16225, 16182, 16135, 16083, 16026, 15964, 15897, 15826, 15749, 15668, 15582, 15491, 15396, 15296, 15191, 15082, 14968, 14849, 14726, 14598, 14466, 14330, 14189, 14044, 13894, 13741, 13583, 13421, 13255, 13085, 12911, 12733, 12551, 12365, 12176, 11982, 11786, 11585, 11381, 11174, 10963, 10749, 10531, 10311, 10087, 9860, 9630, 9397, 9162, 8923, 8682, 8438, 8192, 7943, 7692, 7438, 7182, 6924, 6664, 6402, 6138, 5872, 5604, 5334, 5063, 4790, 4516, 4240, 3964, 3686, 3406, 3126, 2845, 2563, 2280, 1997, 1713, 1428, 1143, 857, 572, 286, 0, -286, -572, -857, -1143, -1428, -1713, -1997, -2280, -2563, -2845, -3126, -3406, -3686, -3964, -4240, -4516, -4790, -5063, -5334, -5604, -5872, -6138, -6402, -6664, -6924, -7182, -7438, -7692, -7943, -8192, -8438, -8682, -8923, -9162, -9397, -9630, -9860, -10087, -10311, -10531, -10749, -10963, -11174, -11381, -11585, -11786, -11982, -12176, -12365, -12551, -12733, -12911, -13085, -13255, -13421, -13583, -13741, -13894, -14044, -14189, -14330, -14466, -14598, -14726, -14849, -14968, -15082, -15191, -15296, -15396, -15491, -15582, -15668, -15749, -15826, -15897, -15964, -16026, -16083, -16135, -16182, -16225, -16262, -16294, -16322, -16344, -16362, -16374, -16382, -16384, -16382, -16374, -16362, -16344, -16322, -16294, -16262, -16225, -16182, -16135, -16083, -16026, -15964, -15897, -15826, -15749, -15668, -15582, -15491, -15396, -15296, -15191, -15082, -14968, -14849, -14726, -14598, -14466, -14330, -14189, -14044, -13894, -13741, -13583, -13421, -13255, -13085, -12911, -12733, -12551, -12365, -12176, -11982, -11786, -11585, -11381, -11174, -10963, -10749, -10531, -10311, -10087, -9860, -9630, -9397, -9162, -8923, -8682, -8438, -8192, -7943, -7692, -7438, -7182, -6924, -6664, -6402, -6138, -5872, -5604, -5334, -5063, -4790, -4516, -4240, -3964, -3686, -3406, -3126, -2845, -2563, -2280, -1997, -1713, -1428, -1143, -857, -572, -286
bltcon0_v:	DC.W %0000111100000000,%0000111100000001,%0000111100000010,%0000111100000011,%0000111100000100,%0000111100000101,%0000111100000110,%0000111100000111,%0000111100001000,%0000111100001001,%0000111100001010,%0000111100001011,%0000111100001100,%0000111100001101,%0000111100001110,%0000111100001111,%0000111100010000,%0000111100010001,%0000111100010010,%0000111100010011,%0000111100010100,%0000111100010101,%0000111100010110,%0000111100010111,%0000111100011000,%0000111100011001,%0000111100011010,%0000111100011011,%0000111100011100,%0000111100011101,%0000111100011110,%0000111100011111,%0000111100100000,%0000111100100001,%0000111100100010,%0000111100100011,%0000111100100100,%0000111100100101,%0000111100100110,%0000111100100111,%0000111100101000,%0000111100101001,%0000111100101010,%0000111100101011,%0000111100101100,%0000111100101101,%0000111100101110,%0000111100101111,%0000111100110000,%0000111100110001,%0000111100110010,%0000111100110011,%0000111100110100,%0000111100110101,%0000111100110110,%0000111100110111,%0000111100111000,%0000111100111001,%0000111100111010,%0000111100111011,%0000111100111100,%0000111100111101,%0000111100111110,%0000111100111111,%0000111101000000,%0000111101000001,%0000111101000010,%0000111101000011,%0000111101000100,%0000111101000101,%0000111101000110,%0000111101000111,%0000111101001000,%0000111101001001,%0000111101001010,%0000111101001011,%0000111101001100,%0000111101001101,%0000111101001110,%0000111101001111,%0000111101010000,%0000111101010001,%0000111101010010,%0000111101010011,%0000111101010100,%0000111101010101,%0000111101010110,%0000111101010111,%0000111101011000,%0000111101011001,%0000111101011010,%0000111101011011,%0000111101011100,%0000111101011101,%0000111101011110,%0000111101011111,%0000111101100000,%0000111101100001,%0000111101100010,%0000111101100011,%0000111101100100,%0000111101100101,%0000111101100110,%0000111101100111,%0000111101101000,%0000111101101001,%0000111101101010,%0000111101101011,%0000111101101100,%0000111101101101,%0000111101101110,%0000111101101111,%0000111101110000,%0000111101110001,%0000111101110010,%0000111101110011,%0000111101110100,%0000111101110101,%0000111101110110,%0000111101110111,%0000111101111000,%0000111101111001,%0000111101111010,%0000111101111011,%0000111101111100,%0000111101111101,%0000111101111110,%0000111101111111,%0000111110000000,%0000111110000001,%0000111110000010,%0000111110000011,%0000111110000100,%0000111110000101,%0000111110000110,%0000111110000111,%0000111110001000,%0000111110001001,%0000111110001010,%0000111110001011,%0000111110001100,%0000111110001101,%0000111110001110,%0000111110001111,%0000111110010000,%0000111110010001,%0000111110010010,%0000111110010011,%0000111110010100,%0000111110010101,%0000111110010110,%0000111110010111,%0000111110011000,%0000111110011001,%0000111110011010,%0000111110011011,%0000111110011100,%0000111110011101,%0000111110011110,%0000111110011111,%0000111110100000,%0000111110100001,%0000111110100010,%0000111110100011,%0000111110100100,%0000111110100101,%0000111110100110,%0000111110100111,%0000111110101000,%0000111110101001,%0000111110101010,%0000111110101011,%0000111110101100,%0000111110101101,%0000111110101110,%0000111110101111,%0000111110110000,%0000111110110001,%0000111110110010,%0000111110110011,%0000111110110100,%0000111110110101,%0000111110110110,%0000111110110111,%0000111110111000,%0000111110111001,%0000111110111010,%0000111110111011,%0000111110111100,%0000111110111101,%0000111110111110,%0000111110111111,%0000111111000000,%0000111111000001,%0000111111000010,%0000111111000011,%0000111111000100,%0000111111000101,%0000111111000110,%0000111111000111,%0000111111001000,%0000111111001001,%0000111111001010,%0000111111001011,%0000111111001100,%0000111111001101,%0000111111001110,%0000111111001111,%0000111111010000,%0000111111010001,%0000111111010010,%0000111111010011,%0000111111010100,%0000111111010101,%0000111111010110,%0000111111010111,%0000111111011000,%0000111111011001,%0000111111011010,%0000111111011011,%0000111111011100,%0000111111011101,%0000111111011110,%0000111111011111,%0000111111100000,%0000111111100001,%0000111111100010,%0000111111100011,%0000111111100100,%0000111111100101,%0000111111100110,%0000111111100111,%0000111111101000,%0000111111101001,%0000111111101010,%0000111111101011,%0000111111101100,%0000111111101101,%0000111111101110,%0000111111101111,%0000111111110000,%0000111111110001,%0000111111110010,%0000111111110011,%0000111111110100,%0000111111110101,%0000111111110110,%0000111111110111,%0000111111111000,%0000111111111001,%0000111111111010,%0000111111111011,%0000111111111100,%0000111111111101,%0000111111111110,%0000111111111111

;Composantes (dent de scie)

;red:				DC.W $0F00, $0E00, $0D00, $0C00, $0B00, $0A00, $0900, $0800, $0700, $0600, $0500, $0400, $0300, $0200, $0100, $0000, $0100, $0200, $0300, $0400, $0500, $0600, $0700, $0800, $0900, $0A00, $0B00, $0C00, $0D00, $0E00, $0F00, $0E00, $0D00, $0C00, $0B00, $0A00, $0900, $0800, $0700, $0600, $0500, $0400, $0300, $0200, $0100, $0000, $0100, $0200, $0300, $0400, $0500, $0600, $0700, $0800, $0900, $0A00, $0B00, $0C00, $0D00, $0E00, $0F00, $0E00, $0D00, $0C00, $0B00, $0A00, $0900, $0800, $0700, $0600
;green:				DC.W $00F0, $00E0, $00D0, $00C0, $00B0, $00A0, $0090, $0080, $0070, $0060, $0050, $0040, $0030, $0020, $0010, $0000, $0010, $0020, $0030, $0040, $0050, $0060, $0070, $0080, $0090, $00A0, $00B0, $00C0, $00D0, $00E0, $00F0, $00E0, $00D0, $00C0, $00B0, $00A0, $0090, $0080, $0070, $0060, $0050, $0040, $0030, $0020, $0010, $0000, $0010, $0020, $0030, $0040, $0050, $0060, $0070, $0080, $0090, $00A0, $00B0, $00C0, $00D0, $00E0, $00F0, $00E0, $00D0, $00C0, $00B0, $00A0, $0090, $0080, $0070, $0060
;blue:				DC.W $000F, $000E, $000D, $000C, $000B, $000A, $0009, $0008, $0007, $0006, $0005, $0004, $0003, $0002, $0001, $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $000D, $000E, $000F, $000E, $000D, $000C, $000B, $000A, $0009, $0008, $0007, $0006, $0005, $0004, $0003, $0002, $0001, $0000, $0001, $0002, $0003, $0004, $0005, $0006, $0007, $0008, $0009, $000A, $000B, $000C, $000D, $000E, $000F, $000E, $000D, $000C, $000B, $000A, $0009, $0008, $0007, $0006

;Composantes (sinuso�de)

red:				DC.W $0800, $0900, $0B00, $0C00, $0D00, $0E00, $0F00, $0F00, $0F00, $0F00, $0E00, $0D00, $0C00, $0B00, $0900, $0800, $0600, $0400, $0300, $0200, $0100, $0000, $0000, $0000, $0000, $0100, $0200, $0300, $0400, $0600, $0800, $0900, $0B00, $0C00, $0D00, $0E00, $0F00, $0F00, $0F00, $0F00, $0E00, $0D00, $0C00, $0B00, $0900, $0800, $0600, $0400, $0300, $0200, $0100, $0000, $0000, $0000, $0000, $0100, $0200, $0300, $0400, $0600, $0800, $0900, $0B00, $0C00, $0D00, $0E00, $0F00, $0F00, $0F00, $0F00
green:				DC.W $0080, $0090, $00B0, $00C0, $00D0, $00E0, $00F0, $00F0, $00F0, $00F0, $00E0, $00D0, $00C0, $00B0, $0090, $0080, $0060, $0040, $0030, $0020, $0010, $0000, $0000, $0000, $0000, $0010, $0020, $0030, $0040, $0060, $0080, $0090, $00B0, $00C0, $00D0, $00E0, $00F0, $00F0, $00F0, $00F0, $00E0, $00D0, $00C0, $00B0, $0090, $0080, $0060, $0040, $0030, $0020, $0010, $0000, $0000, $0000, $0000, $0010, $0020, $0030, $0040, $0060, $0080, $0090, $00B0, $00C0, $00D0, $00E0, $00F0, $00F0, $00F0, $00F0
blue:				DC.W $0008, $0009, $000B, $000C, $000D, $000E, $000F, $000F, $000F, $000F, $000E, $000D, $000C, $000B, $0009, $0008, $0006, $0004, $0003, $0002, $0001, $0000, $0000, $0000, $0000, $0001, $0002, $0003, $0004, $0006, $0008, $0009, $000B, $000C, $000D, $000E, $000F, $000F, $000F, $000F, $000E, $000D, $000C, $000B, $0009, $0008, $0006, $0004, $0003, $0002, $0001, $0000, $0000, $0000, $0000, $0001, $0002, $0003, $0004, $0006, $0008, $0009, $000B, $000C, $000D, $000E, $000F, $000F, $000F, $000F

;Composantes (7.5+7.5*sin*cos ou l'angle de sin d�marre � 50 et progresse de 12 et l'angle de cos d�marre � 0 et progresse de 20) : pas convaincant du tout !

;red:				DC.W $0D00, $0E00, $0D00, $0B00, $0900, $0600, $0400, $0300, $0400, $0500, $0600, $0800, $0800, $0800, $0700, $0500, $0200, $0100, $0000, $0100, $0200, $0400, $0700, $0800, $0900, $0800, $0700, $0600, $0400, $0400, $0500, $0600, $0900, $0B00, $0D00, $0E00, $0E00, $0D00, $0B00, $0900, $0800, $0800, $0800, $0A00, $0C00, $0D00, $0E00, $0D00, $0B00, $0900, $0600, $0400, $0300, $0400, $0500, $0600, $0800, $0800, $0800, $0700, $0500, $0200, $0100, $0000, $0100, $0200, $0400, $0700, $0800, $0900
;green:				DC.W $00D0, $00E0, $00D0, $00B0, $0090, $0060, $0040, $0030, $0040, $0050, $0060, $0080, $0080, $0080, $0070, $0050, $0020, $0010, $0000, $0010, $0020, $0040, $0070, $0080, $0090, $0080, $0070, $0060, $0040, $0040, $0050, $0060, $0090, $00B0, $00D0, $00E0, $00E0, $00D0, $00B0, $0090, $0080, $0080, $0080, $00A0, $00C0, $00D0, $00E0, $00D0, $00B0, $0090, $0060, $0040, $0030, $0040, $0050, $0060, $0080, $0080, $0080, $0070, $0050, $0020, $0010, $0000, $0010, $0020, $0040, $0070, $0080, $0090
;blue:				DC.W $000D, $000E, $000D, $000B, $0009, $0006, $0004, $0003, $0004, $0005, $0006, $0008, $0008, $0008, $0007, $0005, $0002, $0001, $0000, $0001, $0002, $0004, $0007, $0008, $0009, $0008, $0007, $0006, $0004, $0004, $0005, $0006, $0009, $000B, $000D, $000E, $000E, $000D, $000B, $0009, $0008, $0008, $0008, $000A, $000C, $000D, $000E, $000D, $000B, $0009, $0006, $0004, $0003, $0004, $0005, $0006, $0008, $0008, $0008, $0007, $0005, $0002, $0001, $0000, $0001, $0002, $0004, $0007, $0008, $0009