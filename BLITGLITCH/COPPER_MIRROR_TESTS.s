;*** MiniStartup by Photon ***
	INCDIR	"NAS:AMIGA/CODE/crippled_cyborg_amiga/"
	SECTION	"Code",CODE
	INCLUDE	"PhotonsMiniWrapper1.04!.S"
	INCLUDE	"Blitter-Register-List.S"	;use if you like ;)
	;INCLUDE	"PT12_OPTIONS.i"
	;INCLUDE	"P6112-Play-stripped.i"
;********** Constants **********
wi		EQU 320
he		EQU 256		; screen height
bpls		EQU 2		; depth
bypl		EQU wi/16*2	; byte-width of 1 bitplane line (40bytes)
bwid		EQU bpls*bypl	; byte-width of 1 pixel line (all bpls)
blitsize		EQU he*64+wi/16	; size of blitter operation
blitsizeF		EQU %000000000000010101	; size of FULL blitter operation
bplsize		EQU bypl*he		; size of 1 bitplane screen
hband		EQU 10		; lines reserved for textscroller
hblit		EQU he/2		;-hband	; size of blitter op without textscroller
wblit		EQU wi/2/16*2
bypl_real		EQU wi/16*2
TEXTURE_H		EQU 640
X_2X_SLICE	EQU 9
X_SLICE		EQU 13
COP_Y_MIRROR	EQU 1
COP_DEFRAG	EQU 1
;*************
MODSTART_POS	EQU 0		; start music at position # !! MUST BE EVEN FOR 16BIT
;*************

;********** Demo **********	;Demo-specific non-startup code below.
Demo:			;a4=VBR, a6=Custom Registers Base addr
	;*--- init ---*
	MOVE.L	#VBint,$6C(A4)
	MOVE.W	#%1110000000100000,INTENA
	;** SOMETHING INSIDE HERE IS NEEDED TO MAKE MOD PLAY! **
	MOVE.W	#%1000011111100000,DMACON
	;*--- clear screens ---*
	;LEA	SCREEN1,A1
	;BSR.W	ClearScreen
	;LEA	SCREEN2,A1
	;BSR.W	ClearScreen
	BSR	WaitBlitter
	;*--- start copper ---*
	LEA	BGPLANE1,A0
	LEA	COPPER\.BplPtrs,A1
	BSR.W	PokePtrs

	LEA	BGPLANE0,A0
	LEA	COPPER\.BplPtrs+8,A1
	BSR.W	PokePtrs

	; #### CPU INTENSIVE TASKS BEFORE STARTING MUSIC
	; #### POPULATE COPPER WAITS ####
	IFNE	COP_Y_MIRROR
	LEA	COPWAITSSRC\.BplPtrsWaits,A1
	LEA	BGPLANE1+he/2*bypl,A0

	;MOVE.W	#he/2/2-1,D7		; HOM MANY LINES
	;MOVE.W	#$6E,D0			; STARTING WAITPOS #$AE
	;MOVE.L	#$00E20000,D1		; PRELOAD REGISTER LONG
	;BSR.W	__COPPER_POPULATE_MIRROR

	;LEA	BGPLANE0+he/2/2*bypl,A0
	MOVE.W	#he/2-1,D7		; HOM MANY LINES
	MOVE.W	#$AE,D0			; STARTING WAITPOS
	;MOVE.W	#$EE,D0			; STARTING WAITPOS
	MOVE.L	#$00E20000,D1		; PRELOAD REGISTER LONG
	BSR.W	__COPPER_POPULATE_MIRROR

	;LEA	COPWAITSSRC\.BplPtrsWaits,A1
	LEA	BGPLANE0+he/2*bypl,A0
	MOVE.W	#he/2-1,D7		; HOM MANY LINES
	MOVE.W	#$AE,D0			; STARTING WAITPOS
	MOVE.L	#$00E60000,D1		; PRELOAD REGISTER LONG
	BSR.W	__COPPER_POPULATE_MIRROR
	ENDC

	LEA	COPWAITSSRC\.gradients,A2	; PRELOAD DEST
	MOVE.W	#$2C,D0			; PRELOAD H STARTPOS
	MOVE.W	#$0180,D1			; PRELOAD REGISTER#
	MOVE.L	#$00000305,D2		; START | END COLOR
	MOVE.W	#4,D3			; STEP IN PIXELS
	BSR.W	__COPPER_CREATE_GRADIENT

	MOVE.W	#$1E,D0			; PRELOAD H STARTPOS
	MOVE.L	#$02040000,D2		; START | END COLOR
	BSR.W	__COPPER_CREATE_GRADIENT

	MOVE.W	#$2C,D0			; PRELOAD H STARTPOS
	MOVE.W	#$0182,D1			; PRELOAD REGISTER#
	MOVE.L	#$00020A07,D2		; START | END COLOR
	MOVE.W	#3,D3			; STEP IN PIXELS
	BSR.W	__COPPER_CREATE_GRADIENT

	MOVE.W	#$FF,D0			; PRELOAD H STARTPOS
	MOVE.L	#$09060002,D2		; START | END COLOR
	BSR.W	__COPPER_CREATE_GRADIENT

	IFNE	COP_DEFRAG
	BSR.W	__COPPER_DEFRAG
	ENDC
	; #### POPULATE COPPER WAITS ####

	;MOVE.L	KICKSTART_ADDR,A3
	LEA	TEXTURE,A3		; NOW 2 BPLS
	LEA	X_TEXTURE_MIRROR,A4		; FILLS A PLANE
	BSR.W	__FILL_MIRROR_TEXTURE	; WITH DITHERING
	LEA	X_TEXTURE_MIRROR+he*bypl,A4	; FILLS A PLANE
	BSR.W	__FILL_MIRROR_TEXTURE	; WITH DITHERING

	LEA	X_TEXTURE_MIRROR,A3		; FILLS A PLANE
	LEA	X_TEXTURE_MIRROR,A4		; FILLS A PLANE
	BSR.W	__MIRROR_PLANE
	LEA	X_TEXTURE_MIRROR+he*bypl,A3	; FILLS A PLANE
	LEA	X_TEXTURE_MIRROR+he*bypl,A4	; FILLS A PLANE
	BSR.W	__MIRROR_PLANE

	MOVE.L	#DITHERPLANE,A4		; FILLS A PLANE
	MOVE.W	#0,D0
	BSR.W	__DITHER_PLANE		; WITH DITHERING
	; #### CPU INTENSIVE TASKS BEFORE STARTING MUSIC

	MOVE.L	#COPPER,COP1LC
;********************  main loop  ********************
MainLoop:
	MOVE.W	#$12C,D0		; No buffering, so wait until raster
	BSR.W	WaitRaster	; is below the Display Window.
	;*--- swap buffers ---*
	;movem.l	DrawBuffer(PC),a2-a3
	;exg	a2,a3
	;movem.l	a2-a3,DrawBuffer	;draw into a2, show a3
	;;*--- show one... ---*
	;move.l	a3,a0
	;move.l	#bypl*h,d0
	;lea	COPPER\.BplPtrs+2,a1
	;moveq	#bpls-1,d1
	;bsr.w	PokePtrs
	;;*--- ...draw into the other(a2) ---*
	;move.l	a2,a1
	;;bsr	ClearScreen
	;BSR.W	__SET_PT_VISUALS
	;MOVE.L	KONEYBG,DrawBuffer

	; do stuff here :)
	SONG_BLOCKS_EVENTS:
	;* FOR TIMED EVENTS ON BLOCK ****
	MOVE.W	P61_LAST_POS,D5
	LEA	TIMELINE,A3
	LSL.W	#2,D5		; CALCULATES OFFSET (OPTIMIZED)
	MOVE.L	(A3,D5),A4	; THANKS HEDGEHOG!!
	JSR	(A4)		; EXECUTE SUBROUTINE BLOCK#

	;TST.B	FRAME_STROBE
	;BNE.W	.oddFrame
	;MOVE.B	#1,FRAME_STROBE
	;MOVE.W	#0,P61_LAST_POS
	;BRA.W	.evenFrame
	;.oddFrame:
	;MOVE.B	#0,FRAME_STROBE
	;MOVE.W	#1,P61_LAST_POS
	;.evenFrame:

	;*--- main loop end ---*
	ENDING_CODE:
	BTST	#6,$BFE001
	BNE.S	.DontShowRasterTime

	;MOVE.W	#$0FFF,$DFF184	; show rastertime left down to $12c

	;## VERTICAL TEXTURE ###########
	;MOVE.L	#$10000,BLIT_A_MOD
	;LEA	BGPLANE0,A4
	;ADD.L	#bypl/2-2,A4
	;BSR.W	__BLIT_GLITCH_SLICE
	;## VERTICAL TEXTURE ###########

	MOVE.B	SCROLL_DIR_Y,D5
	NEG.B	D5
	MOVE.B	D5,SCROLL_DIR_Y
	MOVE.B	SCROLL_DIR_X,D5
	NEG.B	D5
	MOVE.B	D5,SCROLL_DIR_X
	MOVE.B	#1,IS_FRAME_EVEN
	;MOVE.W	Y_EASYING_INDX,D5
	;MOVE.W	X_EASYING_INDX,D6
	;ADD.W	D5,D6
	;MOVE.W	D5,X_EASYING_INDX
	;MOVE.W	D6,Y_EASYING_INDX
	;BSR.W	__X_LFO_EASYING
	;BSR.W	__Y_LFO_EASYING
	;MOVE.W	X_EASYING_INDX,Y_EASYING_INDX
	.DontShowRasterTime:
	BTST	#2,$DFF016	; POTINP - RMB pressed?
	BNE.W	MainLoop		; then loop
	;*--- exit ---*
	;;    ---  Call P61_End  ---
	;MOVEM.L D0-A6,-(SP)
	;JSR P61_End
	;MOVEM.L (SP)+,D0-A6
	RTS

;********** Demo Routines **********
PokePtrs:				; SUPER SHRINKED REFACTOR
	MOVE.L	A0,(A0)		; Needs EMPTY plane to write addr
	MOVE.W	(A0)+,2(A1)	; high word of address
	MOVE.W	(A0),6(A1)	; low word of address
	RTS

ClearScreen:			; a1=screen destination address to clear
	bsr	WaitBlitter
	clr.w	$66(a6)		; destination modulo
	move.l	#$01000000,$40(a6)	; set operation type in BLTCON0/1
	move.l	a1,$54(a6)	; destination address
	move.l	#blitsize*bpls,$58(a6)	;blitter operation size
	rts

VBint:				; Blank template VERTB interrupt
	movem.l	d0/a6,-(sp)	; Save used registers
	lea	$dff000,a6
	btst	#5,$1f(a6)	; check if it's our vertb int.
	beq.s	.notvb
	;*--- do stuff here ---*
	moveq	#$20,d0		; poll irq bit
	move.w	d0,$9c(a6)
	move.w	d0,$9c(a6)
	.notvb:	
	movem.l	(sp)+,d0/a6	; restore
	rte

__DITHER_PLANE:
	MOVE.L	A4,A4
	MOVE.W	#he-1,D4		; QUANTE LINEE
	MOVE.L	#$AAAAAAAA,D5
	.outerloop:		; NUOVA RIGA
	MOVE.W	#(bypl/4)-1,D6	; RESET D6
	NOT.L	D5
	.innerloop:		; LOOP KE CICLA LA BITMAP
	MOVE.W	$DFF006,$DFF180	; SHOW ACTIVITY :)
	MOVE.L	D5,(A4)+
	DBRA	D6,.innerloop
	TST.W	D0
	BEQ.S	.noWait
	BSR.W	WaitEOF		; TO SLOW DOWN :)
	.noWait:
	DBRA	D4,.outerloop
	RTS

__MIRROR_PLANE:
	MOVE.L	A4,A5
	ADD.L	#bypl,A5
	MOVE.W	#(TEXTURE_H)-1,D4	; QUANTE LINEE
	.outerloop:		; NUOVA RIGA
	MOVE.W	#(bypl/2)-1,D6
	.innerloop:
	MOVE.W	$DFF006,$DFF180	; SHOW ACTIVITY :)
	MOVE.B	(A3)+,D5

	MOVE.B	D5,D0
	REPT 8
	ROXR.B	#1,D0		; FLIP BITS
	ROXL.B	#1,D2		; FLIP BITS
	ENDR
	MOVE.B	D2,-(A5)		; BOTTOM RIGHT
	DBRA	D6,.innerloop
	ADD.L	#(bypl/2),A3
	ADD.L	#(bypl/2)*3,A5
	DBRA	D4,.outerloop
	RTS

__FILL_MIRROR_TEXTURE:
	;MOVE.L	$DFF006,D4
	;SWAP	D4
	MOVE.W	#TEXTURE_H-1,D4	; QUANTE LINEE
	.outerloop:		; NUOVA RIGA
	MOVE.W	#(bypl/8)-1,D6	; RESET D6
	.innerloop:		; LOOP KE CICLA LA BITMAP
	MOVE.W	$DFF006,$DFF180	; SHOW ACTIVITY :)

	;BTST.B	#0,(A3)		; IF LINE EMPTY
	;BRA.S	.skip
	;LEA	10(A3),A3		; OPTIMIZED
	;SWAP	D4
	;MOVE.B	$DFF007,D4
	;ROR.W	#6,D4
	;move.b	$BFD800,d3
	;NOT.W	D4
	;AND.B	-80(A4),D4
	;SWAP	D4
	;.skip:

	;MOVE.L	(A3)+,D5
	;EOR.B	D4,D5
	;ROL.W	D6,D5
	;EOR.L	D4,D5
	;ROR.W	D6,D5
	MOVE.L	(A3)+,(A4)+
	DBRA	D6,.innerloop
	LEA	20(A4),A4
	DBRA	D4,.outerloop
	RTS

__COPPER_CREATE_GRADIENT:
	CLR.L	D4
	CLR.L	D6
	CLR.L	D7
	MOVE.L	D2,A3		; BACKUP :)
	ROL.W	#4,D2		; B
	MOVE.B	D2,D7		; B
	ROR.W	#4,D7		; B
	ROR.L	#8,D7		; B
	LSR.W	#4,D2		; B
	MOVE.B	D2,D7		; G
	ROR.W	#4,D7		; G
	ROR.L	#8,D7		; G
	LSR.W	#4,D2		; G
	MOVE.B	D2,D7		; R
	ROR.W	#4,D7		; R
	ROR.L	#8,D7		; R
	LSR.L	#8,D7		; NOW END VALUES ARE ONE NIBBLE IN EACH BYTE
	SWAP	D2
	ROL.W	#4,D2		; B
	MOVE.B	D2,D6		; B
	ROR.W	#4,D6		; B
	ROR.L	#8,D6		; B
	LSR.W	#4,D2		; B
	MOVE.B	D2,D6		; G
	ROR.W	#4,D6		; G
	ROR.L	#8,D6		; G
	LSR.W	#4,D2		; G
	MOVE.B	D2,D6		; R
	ROR.W	#4,D6		; R
	ROR.L	#8,D6		; R
	LSR.L	#8,D6		; NOW START VALUES ARE ONE NIBBLE IN EACH BYTE
	MOVE.L	A3,D2		; RESTORE

	.outerloop:
	MOVE.W	$DFF006,$DFF180	; SHOW ACTIVITY :)
	MOVE.W	#3,D5
	.innerloop:
	MOVE.B	D6,D4		; PUTS VALUE BACK
	CMP.B	D6,D7
	BEQ.S	.skip		; SAME VALUE
	BLO.S	.less
	CMP.B	#$F,D6
	BEQ.S	.skip
	ADD.B	#$1,D6		; INCR COLOR
	BRA.S	.skip
	.less:
	CMP.B	#$0,D6
	BEQ.S	.skip
	SUB.B	#$1,D6		; DECREASE

	.skip:
	ROR.L	#4,D4		; IN THE SAME SPOT
	ROR.L	#8,D6
	ROR.L	#8,D7

	DBRA	D5,.innerloop

	MOVE.L	#$0001FF00,(A2)	; WAIT
	MOVE.B	D0,(A2)		; PUT THE LINE VALUE
	ADD.L	#4,A2
	SWAP	D4
	MOVE.W	D4,2(A2)		; COLOR VALUE
	MOVE.W	D1,(A2)		; COLOR REGISTER
	ADD.L	#4,A2
	ADD.W	D3,D0		; NEXT STEP
	AND.W	#$FF,D0

	CMP.W	D4,D2
	BNE.S	.outerloop	; FINISHED!
	CLR.W	$100		; DEBUG | w 0 100 2
	RTS

__COPPER_POPULATE_MIRROR:
	.loop:
	MOVE.W	$DFF006,$DFF180		; SHOW ACTIVITY :)
	CMP.B	#$FF,D0
	BNE.S	.notFF
	CLR.L	D0
	;MOVE.L	#$FFDFFFFE,(A1)+		; ALLOW VPOS>$FF
	.notFF:

	MOVE.L	#$0001FF00,(A1)
	MOVE.B	D0,(A1)			; WAIT LINE
	MOVE.L	D1,4(A1)			; ACTUAL REGISTERS
	MOVE.W	A0,6(A1)			; ONLY LOW WORD

	LEA	8(A1),A1			; NEXT GROUP
	LEA	((bypl*-1),A0),A0		; PREVIOUS LINE
	ADD.B	#1,D0			; INC. WAITLINE
	DBRA	D7,.loop
	RTS

__COPPER_DEFRAG:				; ROUTINES CONTAINER
	LEA	COPPER\.COPPERWAITS,A2	; PRELOAD DEST
	LEA	COPWAITSSRC,A0		; PRELOAD SOURCE BUFFER
	MOVE.W	#$2C,D0			; PRELOAD COUNTER START
	BSR.W	__COPPER_MOVE_WAITS		; ONLY WAITS
	MOVE.L	#$FFDFFFFE,(A2)+		; ALLOW VPOS>$FF
	MOVE.W	#$00,D0			; PRELOAD COUNTER START
	BSR.W	__COPPER_MOVE_WAITS		; ONLY WAITS
	MOVE.L	#$FFFFFFFE,(A2)		; COPPER END
	RTS

__COPPER_MOVE_WAITS:
	LEA	(A0),A1
	.loop:
	MOVE.W	A1,$DFF180		; SHOW ACTIVITY :)
	CMP.W	#$FF00,2(A1)		; IS IT A WAIT?
	BNE.S	.nextLine			; IF NOT TRY NEXT LINE

	MOVE.B	(A1),D1
	CMP.B	D0,D1			; WAIT MATCH EXISTS?
	BNE.S	.nextLine

	MOVE.L	(A1)+,(A2)+		; COPY WAIT LINE ONCE
	BSR.S	__COPPER_MOVE_INSTRC	; ONLY INSTRUCTIONS NOW
	BRA.S	.nextCounter

	.nextLine:
	ADD.L	#$4,A1
	CMP.L	#$FFFFFFFE,(A1)		; IS END?
	BNE.S	.loop

	.nextCounter:
	LEA	(A0),A1
	ADD.W	#$1,D0			; INC COUNTER
	CMP.W	#$FF+1,D0
	BNE.S	.loop
	RTS

__COPPER_MOVE_INSTRC:
	LEA	(A0),A3			; PRELOAD SOURCE
	.loop:
	MOVE.B	$DFF006,$DFF180		; SHOW ACTIVITY :)
	TST.L	(A3)			; IS THERE SOMETHING?
	BEQ.S	.nextLine			; IF NO JUST SKIP

	CMP.W	#$FF00,2(A3)		; IS IT A WAIT?
	BNE.S	.nextLine			; IF NO JUST SKIP
	MOVE.B	(A3),D1			; IF YES
	CMP.B	D0,D1			; WAIT MATCH?
	BNE.S	.nextLine

	ADD.L	#$4,A3			; NEXT LINE
	CMP.L	#$FFDFFFFE,(A3)		; IS NEXT A VPOS>$FF?
	BEQ.S	.nextLine			; WE PUT IT MANUALLY ON THE CONTAINER

	MOVE.L	(A3),(A2)+		; COPY INSTRUCTION
	MOVE.L	#$00,(A3)			; RESET INSTR
	MOVE.L	#$00,-4(A3)		; RESET WAIT

	.nextLine:
	ADD.L	#$4,A3			; NEXT LINE
	CMP.L	#$FFFFFFFE,(A3)		; IS END?
	BNE.S	.loop
	RTS

__BLIT_GLITCH_DATA:
	MOVE.W	#%0000100111110000,D1
	; ## MAIN BLIT ####
	MOVE.L	SCROLL_SRC,A3
	MOVE.L	SCROLL_PLANE,A4
	ADD.L	#bypl*(he/2-30),A4		; CENTER!
	bsr	WaitBlitter
	MOVE.W	BLIT_X_MASK,BLTAFWM
	MOVE.W	BLIT_Y_MASK,BLTALWM
	MOVE.W	D1,BLTCON0		; BLTCON0 (usa A+D); con shift di un pixel
	MOVE.W	#%0000100111110000,BLTCON1	; BLTCON1 BIT 12 DESC MODE
	MOVE.L	#0,BLTAMOD

	MOVE.L	A3,BLTAPTH
	MOVE.L	A4,BLTDPTH
	MOVE.W	#32*64+(wi)/16,BLTSIZE
	MOVE.B	(A3),SCROLL_SHIFT
	; ## MAIN BLIT ####
	;ADD.L	#bypl,GLITCHDATA
	RTS

__BLIT_GLITCH_TILE:
	MOVE.L	(A5),D0			; A5 PRELOADED WITH RESET ADDRESS
	MOVE.L	4(A5),A3			; NEXT LONG CONTAINS ACTUALE POINTER
	ADD.L	#(TEXTURE_H-60)*(64/16*2),D0	; OFFSET FOR TEXTURE END
	CMP.L	D0,A3
	BLS.S	.notEnd			; PAST END OF TEXTURE?
	MOVE.L	(A5),A3			; RELOAD RESET ADDRESS
	.notEnd:

	ADD.L	#bypl*(he/4+8)+(bypl/2-4),A4	; POSITION IN CENTER!
	BSR	WaitBlitter
	MOVE.W	#%00001111111001010,BLTCON0	; BLTCON0
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1
	MOVE.L	#$FFFFFFFF,BLTAFWM		; THEY'LL NEVER
	MOVE.W	#0,BLTBMOD		; BLTAMOD
	MOVE.W	#0,BLTAMOD		; BLTBMOD =0 for texture
	MOVE.W	#bypl-(64/16*2),BLTCMOD	; BLTCMOD
	MOVE.W	#bypl-(64/16*2),BLTDMOD	; BLTDMOD 40-4=36
	MOVE.L	#PATTERN,BLTAPTH		; TEXTURE
	MOVE.L	A3,BLTBPTH		; BLTAPT
	MOVE.L	A4,BLTCPTH
	MOVE.L	A4,BLTDPTH
	MOVE.W	#64*64+64/16,BLTSIZE	; BLTSIZE
	LEA	8(A3),A3			; INCREASE TEXTURE POSITION 8
	MOVE.L	A3,4(A5)			; REMEMBER POSITION
	RTS

__BLIT_GLITCH_BAND:
	MOVE.L	(A5),D0			; A5 PRELOADED WITH RESET ADDRESS
	MOVE.L	4(A5),A3			; NEXT LONG CONTAINS ACTUALE POINTER
	SUB.L	#(TEXTURE_H-16)*bypl,D0	; OFFSET FOR TEXTURE END
	CMP.L	D0,A3
	BHI.S	.notEnd
	MOVE.L	(A5),A3			; RELOAD RESET ADDRESS
	.notEnd:

	bsr	WaitBlitter
	MOVE.W	#%0000100111110000,BLTCON0	; BLTCON0
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1 BIT 12 DESC MODE
	MOVE.L	#$FFFFFFFF,BLTAFWM		; THEY'LL NEVER
	MOVE.L	BLIT_A_MOD,BLTAMOD		; BLTAMOD

	MOVE.L	A3,BLTAPTH		; BLTAPT
	MOVE.L	A4,BLTDPTH
	MOVE.W	BLIT_SIZE,BLTSIZE		; BLTSIZE

	CLR.L	D5
	MOVE.W	Y_HALF_SHIFT,D5
	MULU.W	#bypl,D5
	SUB.L	D5,A3
	;LEA	-40(A3),A3		; OPTIMIZED
	MOVE.L	A3,4(A5)			; REMEMBER POSITION
	RTS

__BLIT_GLITCH_SLICE:
	;MOVE.L	GLITCHDATA2,A3
	.dataOk:
	;CMP.L	#_DITHER_V-160*2,A3		; LAST WORD OF DATA?
	BLS.S	.notEnd
	MOVE.L	TEXTURERESET3,A3		; RELOAD
	.notEnd:

	bsr	WaitBlitter
	MOVE.W	#%0000100111110000,BLTCON0	; BLTCON0
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1 BIT 12 DESC MODE
	;MOVE.L	(A5),BLTAFWM		; THEY'LL NEVER
	MOVE.L	#$FFFFFFFF,BLTAFWM		; THEY'LL NEVER
	MOVE.W	#bypl-4,D2
	;SUB.W	BLIT_A_MOD,D1
	MOVE.W	#0,BLTAMOD		; BLTAMOD
	;SUB.W	BLIT_D_MOD,D2
	MOVE.W	D2,BLTDMOD		; BLTDMOD

	MOVE.L	A3,BLTAPTH		; BLTAPT
	MOVE.L	A4,BLTDPTH
	MOVE.W	#(he/2+2)*64+(32/16),BLTSIZE	; BLTSIZE
	LEA	4(A3),A3			; OPTIMIZED
	;MOVE.L	A3,GLITCHDATA2		; REMEMBER POSITION
	; ## MAIN BLIT ####
	RTS

__SCROLL_BG_X:
	MOVEM.L	D0-A6,-(SP)		; SAVE TO STACK
	BTST.B	#6,DMACONR		; for compatibility

	MOVE.B	SCROLL_DIR_X,D5
	NEG.B	D5
	MOVE.B	D5,SCROLL_DIR_X

	MOVE.W	#%0000100111110000,D1

	CMP.B	#1,D5
	BEQ.B	.mainBlit
	ADD.L	#bypl*hblit,SCROLL_PLANE
	ADD.L	#bypl*hblit,SCROLL_SRC
	; ## FOR LEFT ####
	MOVE.L	SCROLL_SRC,A3
	MOVE.L	SCROLL_PLANE,A4		; PATCH FIRST WORD COLUMN
	bsr	WaitBlitter
	MOVE.L	A3,BLTAPTH		; BLTAPT  (fisso alla figura sorgente)
	ADD.L	#bypl-2,A4			; POSITION FOR DESC
	MOVE.L	A4,BLTDPTH
	MOVE.W	#$FFFF,BLTAFWM		; BLTAFWM lo spiegheremo dopo
	MOVE.W	#$FFFF,BLTALWM		; BLTALWM lo spiegheremo dopo
	MOVE.W	D1,BLTCON0		; BLTCON0 (usa A+D); con shift di un pixel
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1 BIT 12 DESC MODE
	MOVE.W	#bypl-2,BLTAMOD		; BLTAMOD =0 perche` il rettangolo
	MOVE.W	#bypl-2,BLTDMOD		; BLTDMOD 40-4=36 il rettangolo

	MOVE.W	#(hblit<<6)+%000001,BLTSIZE	; BLTSIZE (via al blitter !)
	; ## FOR LEFT ####

	; ## MAIN BLIT ####
	.mainBlit:
	MOVE.L	SCROLL_SRC,A3
	MOVE.L	SCROLL_PLANE,A4
	ROL.W	#4,D1
	MOVE.B	SCROLL_SHIFT,D1
	ROR.W	#4,D1
	bsr	WaitBlitter
	MOVE.W	BLIT_X_MASK,BLTAFWM		; BLTAFWM lo spiegheremo dopo
	MOVE.W	BLIT_X_MASK,BLTALWM		; BLTALWM lo spiegheremo dopo
	MOVE.W	D1,BLTCON0		; BLTCON0 (usa A+D); con shift di un pixel
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1 BIT 12 DESC MODE
	MOVE.L	#0,BLTAMOD		; BLTAMOD =0 perche` il rettangolo

	CMP.B	#1,D5
	BEQ.B	.goBlitter		; FOR LEFT
	ADD.L	#bypl*hblit-2,A3
	ADD.L	#bypl*hblit-2,A4
	MOVE.W	#%0000000000000010,BLTCON1	; BLTCON1 BIT 12 DESC MODE

	.goBlitter:
	MOVE.L	A3,BLTAPTH		; BLTAPT  (fisso alla figura sorgente)
	MOVE.L	A4,BLTDPTH
	MOVE.W	#(hblit<<6)+%00010101,BLTSIZE	; BLTSIZE (via al blitter !)
	; ## MAIN BLIT ####

	CMP.B	#1,D5
	BNE.B	.skip
	
	; ## FOR RIGHT ####
	MOVE.L	SCROLL_SRC,A3
	MOVE.L	SCROLL_PLANE,A4		; PATCH FIRST WORD COLUMN
	bsr	WaitBlitter
	MOVEQ	#bypl-2,D0
	MOVE.L	A3,BLTAPTH		; BLTAPT  (fisso alla figura sorgente)
	MOVE.L	A4,BLTDPTH
	ADD.L	D0,A4
	MOVE.L	A4,BLTBPTH
	MOVE.W	#%0000110111100100,BLTCON0	; d = ac+b!c = abc+a!bc+ab!c+!ab!c = %11100100 = $e4
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1 BIT 12 DESC MODE
	MOVE.B	SCROLL_SHIFT,D1
	MOVE.W	#$FFFF,D2
	LSR.W	D1,D2

	MOVE.W	D2,BLTCDAT
	MOVE.W	D0,BLTAMOD
	MOVE.W	D0,BLTBMOD
	MOVE.W	D0,BLTDMOD

	MOVE.W	#(hblit<<6)+%000001,BLTSIZE	; BLTSIZE (via al blitter !)
	.skip:
	; ## FOR RIGHT ####

	ADD.B	#1,SCROLL_SHIFT

	MOVEM.L	(SP)+,D0-A6		; FETCH FROM STACK
	RTS

__SCROLL_BG_Y:
	MOVEM.L	D0-A6,-(SP)		; SAVE TO STACK
	BTST.B	#6,DMACONR		; for compatibility

	bsr	WaitBlitter
	MOVE.W	#%0000100111110000,BLTCON0

	MOVE.L	#0,D1
	MOVE.B	SCROLL_SHIFT,D1
	;SUB.B	#2,D1
	MULU.W	#bypl,D1

	; ## MAIN BLIT ####
	MOVE.L	SCROLL_SRC,A3
	MOVE.L	SCROLL_PLANE,A4
	MOVE.B	SCROLL_DIR_Y,D5
	NEG.B	D5
	MOVE.B	D5,SCROLL_DIR_Y
	TST.B	D5
	BEQ.S	.goUp
	MOVE.W	#%0000000000000010,BLTCON1	; BLTCON1 DESC MODE
	ADD.L	D1,A4			; POSITION Y
	ADD.L	#bypl*(he-1)-2,A3
	ADD.L	#bypl*(he-1)-2,A4
	BRA.S	.goBlit
	.goUp:
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1
	;SUB.B	#bypl,D1
	ADD.L	D1,A3			; POSITION Y
	.goBlit:

	MOVE.W	BLIT_Y_MASK,BLTAFWM		; BLTAFWM
	MOVE.W	BLIT_Y_MASK,BLTALWM		; BLTALWM
	MOVE.W	#bypl-wblit,BLTAMOD		; BLTAMOD
	MOVE.W	#bypl-wblit,BLTDMOD		; BLTDMOD

	MOVE.L	A3,BLTAPTH		; BLTAPT SRC
	MOVE.L	A4,BLTDPTH		; DESC
	MOVE.W	#(he-3)*64+(wi/2)/16,BLTSIZE	; BLTSIZE
	; ## MAIN BLIT ####

	ADD.B	#1,SCROLL_SHIFT

	MOVEM.L	(SP)+,D0-A6		; FETCH FROM STACK
	RTS

__SCROLL2_BG_Y:
	MOVEM.L	D0-A6,-(SP)		; SAVE TO STACK
	BTST.B	#6,DMACONR		; for compatibility

	bsr	WaitBlitter
	MOVE.W	#%0000100111110000,BLTCON0

	MOVE.L	#0,D1
	MOVE.B	SCROLL_SHIFT,D1
	;SUB.B	#2,D1
	MULU.W	#bypl,D1

	; ## MAIN BLIT ####
	MOVE.L	SCROLL_SRC,A3
	MOVE.L	SCROLL_PLANE,A4
	MOVE.B	SCROLL_DIR_Y,D5
	NEG.B	D5
	MOVE.B	D5,SCROLL_DIR_Y
	TST.B	D5
	BEQ.S	.goUp
	MOVE.W	#%0000000000000010,BLTCON1	; BLTCON1 DESC MODE
	ADD.L	D1,A4			; POSITION Y
	ADD.L	#bypl*hblit-2,A3
	ADD.L	#bypl*hblit-2,A4
	BRA.S	.goBlit
	.goUp:
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1
	;SUB.B	#bypl,D1
	ADD.L	D1,A3			; POSITION Y
	.goBlit:

	MOVE.W	BLIT_Y_MASK,BLTAFWM		; BLTAFWM
	MOVE.W	BLIT_Y_MASK,BLTALWM		; BLTALWM
	MOVE.L	#0,BLTAMOD

	MOVE.L	A3,BLTAPTH		; BLTAPT SRC
	MOVE.L	A4,BLTDPTH		; DESC
	MOVE.W	#hblit*64+wi/16,BLTSIZE	; BLTSIZE
	; ## MAIN BLIT ####

	ADD.B	#1,SCROLL_SHIFT

	MOVEM.L	(SP)+,D0-A6		; FETCH FROM STACK
	RTS

__SCROLL2_BG_X:
	MOVEM.L	D0-A6,-(SP)		; SAVE TO STACK
	BTST.B	#6,DMACONR		; for compatibility

	MOVE.B	SCROLL_DIR_X,D5
	NEG.B	D5
	MOVE.B	D5,SCROLL_DIR_X

	MOVE.W	#%0000100111110000,D1

	ADD.L	#(wi/2/16*2),SCROLL_PLANE
	ADD.L	#(wi/2/16*2),SCROLL_SRC

	CMP.B	#1,D5
	BEQ.B	.mainBlit
	; ## FOR LEFT ####
	SUB.L	#(wi/2/16*2),SCROLL_PLANE	; THIS IS...
	SUB.L	#(wi/2/16*2),SCROLL_SRC	; ...UGLY...
	MOVE.L	SCROLL_SRC,A3
	MOVE.L	SCROLL_PLANE,A4		; PATCH FIRST WORD COLUMN
	bsr	WaitBlitter
	MOVE.L	A3,BLTAPTH		; BLTAPT  (fisso alla figura sorgente)
	ADD.L	#bypl-2,A4			; POSITION FOR DESC
	MOVE.L	A4,BLTDPTH
	MOVE.W	#$FFFF,BLTAFWM		; BLTAFWM lo spiegheremo dopo
	MOVE.W	#$FFFF,BLTALWM		; BLTALWM lo spiegheremo dopo
	MOVE.W	D1,BLTCON0		; BLTCON0 (usa A+D); con shift di un pixel
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1 BIT 12 DESC MODE
	MOVE.W	#bypl-2,BLTAMOD		; BLTAMOD =0 perche` il rettangolo
	MOVE.W	#bypl-2,BLTDMOD		; BLTDMOD 40-4=36 il rettangolo

	MOVE.W	#(hblit<<6)+%000001,BLTSIZE	; BLTSIZE (via al blitter !)
	; ## FOR LEFT ####

	; ## MAIN BLIT ####
	.mainBlit:
	MOVE.L	SCROLL_SRC,A3
	MOVE.L	SCROLL_PLANE,A4
	ROL.W	#4,D1
	MOVE.B	SCROLL_SHIFT,D1
	ROR.W	#4,D1
	bsr	WaitBlitter
	MOVE.W	BLIT_X_MASK,BLTAFWM		; BLTAFWM lo spiegheremo dopo
	MOVE.W	BLIT_X_MASK,BLTALWM		; BLTALWM lo spiegheremo dopo
	MOVE.W	D1,BLTCON0		; BLTCON0 (usa A+D); con shift di un pixel
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1 BIT 12 DESC MODE
	MOVE.W	#bypl-wblit,BLTAMOD		; BLTAMOD
	MOVE.W	#bypl-wblit,BLTDMOD		; BLTDMOD

	CMP.B	#1,D5
	BEQ.B	.goBlitter		; FOR LEFT
	ADD.L	#bypl*he-wblit-4,A3
	ADD.L	#bypl*he-wblit-4,A4
	MOVE.W	#%0000000000000010,BLTCON1	; BLTCON1 BIT 12 DESC MODE

	.goBlitter:
	MOVE.L	A3,BLTAPTH		; BLTAPT  (fisso alla figura sorgente)
	MOVE.L	A4,BLTDPTH
	MOVE.W	#hblit*64+(wi/2)/16,BLTSIZE	; BLTSIZE
	; ## MAIN BLIT ####

	CMP.B	#1,D5
	BNE.B	.skip
	
	; ## FOR RIGHT ####
	MOVE.L	SCROLL_SRC,A3
	MOVE.L	SCROLL_PLANE,A4		; PATCH FIRST WORD COLUMN
	bsr	WaitBlitter
	MOVEQ	#bypl-2,D0
	MOVE.L	A3,BLTAPTH		; BLTAPT  (fisso alla figura sorgente)
	MOVE.L	A4,BLTDPTH
	ADD.L	D0,A4
	MOVE.L	A4,BLTBPTH
	MOVE.W	#%0000110111100100,BLTCON0	; d = ac+b!c = abc+a!bc+ab!c+!ab!c = %11100100 = $e4
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1 BIT 12 DESC MODE
	MOVE.B	SCROLL_SHIFT,D1
	MOVE.W	#$FFFF,D2
	LSR.W	D1,D2

	MOVE.W	D2,BLTCDAT
	MOVE.W	D0,BLTAMOD
	MOVE.W	D0,BLTBMOD
	MOVE.W	D0,BLTDMOD

	MOVE.W	#(hblit<<6)+%000001,BLTSIZE	; BLTSIZE (via al blitter !)
	.skip:
	; ## FOR RIGHT ####

	ADD.B	#1,SCROLL_SHIFT

	MOVEM.L	(SP)+,D0-A6		; FETCH FROM STACK
	RTS

__SCROLL_X_1_4:
	MOVE.W	#%1001111100000000,D1
	MOVE.W	#bypl*he/2-(bypl/2)-1,D6	; OPTIMIZE
	MOVE.L	#((bypl/2)<<16)+bypl/2,D7
	MOVE.W	#0,D2
	MOVE.B	X_1_4_SHIFT+1,D4		; FIX FOR -1 VALUES
	MOVE.B	X_1_4_DIR,D5
	CMP.B	#1,D5
	BEQ.B	.notDesc
	; ## MAIN BLIT ####
	BSET.L	#$1,D2			; BLTCON1 BIT 12 DESC MODE
	ADD.W	D6,A3
	ADD.W	D6,A4
	;LEA	40(A4),A4
	;LEA	40(A3),A3
	.notDesc:

	MOVE.B	D4,D1
	ROR.W	#4,D1
	bsr	WaitBlitter

	MOVE.L	#$FFFFFFFF,BLTAFWM		; THEY'LL NEVER
	MOVE.W	D1,BLTCON0		; BLTCON0
	MOVE.W	D2,BLTCON1
	MOVE.L	D7,BLTAMOD		; BLTAMOD
	MOVE.L	A3,BLTAPTH		; BLTAPT
	MOVE.L	A4,BLTDPTH
	MOVE.W	#(he/2)*64+(wi/2/16),BLTSIZE	; BLTSIZE
	; ## MAIN BLIT ####
	RTS

__SCROLL_Y_HALF:
	MOVEQ	#0,D1
	MOVE.W	Y_HALF_SHIFT,D1

	MULU.W	#bypl,D1
	;LEA	BPL_PRECALC,A0
	;ADD.W	D1,D1
	;MOVE.W	(A0,D1.W),D1

	; ## MAIN BLIT ####
	MOVE.B	Y_HALF_DIR,D5
	;NEG.B	D5
	;MOVE.B	D5,Y_HALF_DIR

	BSR	WaitBlitter
	MOVE.W	#%0000100111110000,BLTCON0
	CMP.B	#1,D5
	BEQ.S	.goUp
	MOVE.W	#%0000000000000010,BLTCON1	; BLTCON1 DESC MODE
	SUB.L	D1,A3			; POSITION Y
	MOVE.W	#bypl*(he/2+16)-1,D6
	ADD.W	D6,A3
	ADD.W	D6,A4
	BRA.S	.goBlit
	.goUp:
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1
	ADD.L	D1,A3			; POSITION Y
	.goBlit:

	MOVE.L	#$FFFFFFFF,BLTAFWM		; THEY'LL NEVER
	MOVE.L	BLIT_A_MOD,BLTAMOD		; BLTAMOD

	MOVE.L	A3,BLTAPTH		; BLTAPT SRC
	MOVE.L	A4,BLTDPTH		; DEST
	MOVE.W	BLIT_SIZE,BLTSIZE		; BLTSIZE
	; ## MAIN BLIT ####
	RTS

__SCROLL_Y_HALF_PROGR:
	MOVEQ	#4-1,D0
	MOVE.W	#36*64+wi/16,BLIT_SIZE
	.loop:
	BSR.W	__SCROLL_Y_HALF
	SUB.W	#1,Y_HALF_SHIFT
	TST.W	Y_HALF_SHIFT
	BNE.S	.skip
	MOVE.W	#1,Y_HALF_SHIFT
	.skip:
	ADD.L	#36*bypl,A3
	ADD.L	#36*bypl,A4
	DBRA	D0,.loop
	RTS

__SCROLL_X_PROGR_SPLITX2:
	MOVEQ	#0,D1			; RESETS...
	MOVE.L	D1,D2
	MOVE.L	D1,D3
	MOVE.L	D1,D4
	MOVE.L	D1,D5
	MOVE.L	D1,D6
	MOVE.L	D1,D7

	MOVE.B	X_PROGR_DIR,D5
	MOVE.B	#-1,D6
	MOVE.W	#1,D4			; FOR LOOP
	MOVE.L	A3,A1
	MOVE.L	A4,A2

	BSR	WaitBlitter
	MOVE.L	#$FFFFFFFF,BLTAFWM		; THEY'LL NEVER

	MOVE.W	#bypl*X_2X_SLICE-1,D0	; OPTIMIZE
	MOVE.W	#bypl*X_2X_SLICE,A5	; OPTIMIZE

	.outerLoop:
	MOVE.W	#he/2/X_2X_SLICE,D2	; FOR LOOP
	MOVE.B	D2,D3			; FOR SHIFT
	SUB.B	#1,D2

	CMP.B	#1,D6
	BNE.S	.blitloop
	MOVE.B	#1,D3

	.blitLoop:
	MOVE.L	A1,A3
	MOVE.L	A2,A4
	MOVE.W	#%0000100111110000,D1
	ROL.W	#4,D1
	MOVE.B	D3,D1
	ROR.W	#4,D1
	MOVE.W	#%0000000000000000,D7

	CMP.B	#1,D5
	BEQ.B	.goBlit			; FOR LEFT
	ADD.W	D0,A3
	ADD.W	D0,A4
	MOVE.W	#%0000000000000010,D7	; BLTCON1 BIT 12 DESC MODE
	.goBlit:

	BSR	WaitBlitter
	MOVE.W	D1,BLTCON0		; BLTCON0
	MOVE.W	D7,BLTCON1		; BLTCON1
	MOVE.W	#bypl/2,BLTAMOD		; BLTAMOD
	MOVE.W	#bypl/2,BLTDMOD		; BLTDMOD
	MOVE.L	A3,BLTAPTH		; BLTAPT
	MOVE.L	A4,BLTDPTH
	MOVE.W	#X_2X_SLICE*64+wi/2/16,BLTSIZE

	ADD.W	A5,A1			; NEW TRICK! USE ADRS
	ADD.W	A5,A2			; REGISTERS AS DATA :)
	ADD.B	D6,D3			; CAN BE 1 OR -1

	DBRA	D2,.blitLoop
	NEG.B	D5
	NEG.B	D6
	DBRA	D4,.outerLoop
	RTS

__SCROLL_X_PROGR:
	MOVE.B	X_PROGR_DIR,D5
	MOVE.W	#10,D2			; FOR LOOP
	MOVE.B	D2,D3			; FOR SHIFT
	;ADD.W	X_EASYING2,D3
	SUB.B	#1,D2
	MOVE.B	X_PROGR_TYPE,D4
	MOVE.L	A3,A1
	MOVE.L	A4,A2

	MOVE.W	#bypl*X_SLICE-(bypl/2)-1,D6	; OPTIMIZE
	MOVE.W	#bypl*X_SLICE,D7		; OPTIMIZE
	;SUB.W	D7,D6

	CMP.B	#1,D4
	BNE.S	.blitloop
	MOVE.B	#1,D3
	.blitLoop:
	MOVEQ	#-1,D0			; $ffffffff for FWM/LWM
	MOVE.L	A1,A3
	MOVE.L	A2,A4
	MOVE.W	#%0000100111110000,D1
	ROL.W	#4,D1
	MOVE.B	D3,D1
	ROR.W	#4,D1
	bsr	WaitBlitter
	MOVE.L	#$FFFFFFFF,BLTAFWM		; THEY'LL NEVER
	MOVE.L	D0,BLTAFWM		; FWM, LWM
	MOVE.W	D1,BLTCON0		; BLTCON0
	LSR.W	D3,D0			; add x number of zeroed bits to LOW word (LWM)
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1 BIT 12 DESC MODE

	CMP.B	#1,D5
	BEQ.B	.goBlit			; FOR LEFT
	ADD.W	D6,A3
	ADD.W	D6,A4
	LSL.W	D3,D0			; add x number of zeroed bits to LOW word (LWM)
	MOVE.W	#%0000000000000010,BLTCON1	; BLTCON1 BIT 12 DESC MODE

	.goBlit:
	MOVE.W	#bypl/2,BLTAMOD		; BLTAMOD
	MOVE.W	#bypl/2,BLTDMOD		; BLTDMOD
	MOVE.L	A3,BLTAPTH		; BLTAPT
	MOVE.L	A4,BLTDPTH
	MOVE.W	#X_SLICE*64+wi/2/16,BLTSIZE	; BLTSIZE
	ADD.W	D7,A1
	ADD.W	D7,A2
	ADD.B	D4,D3			; CAN BE 1 OR -1
	;NEG.B	D4
	DBRA	D2,.blitLoop
	RTS

__Y_LFO_EASYING:
	MOVE.W	Y_EASYING_INDX,D0
	LEA	Y_EASYING_TBL,A0
	MOVE.W	(A0,D0.W),D1
	MOVE.W	D1,Y_EASYING
	ADDQ.B	#2,D0
	AND.W	#$7E,D0
	MOVE.W	D0,Y_EASYING_INDX

	TST.W	D0
	BEQ.S	__X_LFO_EASYING2
	RTS

__X_LFO_EASYING:
	MOVE.W	X_EASYING_INDX,D0
	LEA	X_EASYING_TBL,A0
	MOVE.W	(A0,D0.W),D1
	MOVE.W	D1,X_EASYING
	ADDQ.B	#2,D0
	AND.W	#$7E,D0
	MOVE.W	D0,X_EASYING_INDX
	RTS

__X_LFO_EASYING2:
	MOVE.W	X_EASYING2_INDX,D0
	LEA	X_EASYING2_TBL,A0
	MOVE.W	(A0,D0.W),D1
	MOVE.W	D1,X_EASYING2
	ADDQ.B	#2,D0
	AND.W	#$7E,D0
	MOVE.W	D0,X_EASYING2_INDX

	TST.W	D0
	BNE.S	.notSameIndex
	SUB.W	#1,X_CYCLES_COUNTER
	TST.W	X_CYCLES_COUNTER
	BNE.S	.notSameIndex
	MOVE.W	#6,X_CYCLES_COUNTER	; RESET
	MOVE.B	X_PROGR_TYPE,D5	; INVERT
	;NEG.B	D5
	MOVE.B	D5,X_PROGR_TYPE
	MOVE.B	X_PROGR_DIR,D5	; INVERT
	NEG.B	D5
	MOVE.B	D5,X_PROGR_DIR
	;MOVE.W	#$0FF2,$DFF180	; show rastertime left down to $12c
	.notSameIndex:
	RTS

__BLOCK_0:
	LEA	BGPLANE0,A4
	BSR.W	__BLIT_GLITCH_TILE

	MOVE.L	#BGPLANE0,SCROLL_SRC
	MOVE.L	#BGPLANE0,SCROLL_PLANE

	TST.B	IS_FRAME_EVEN
	BNE.S	.notEven
	MOVE.B	#1,IS_FRAME_EVEN

	MOVE.B	SCROLL_SHIFT,D1
	AND.B	#$3,D1
	MOVE.B	D1,SCROLL_SHIFT

	BSR.W	__SCROLL2_BG_Y
	BSR.W	__SCROLL2_BG_Y		; SHIFT !!
	BSR.W	__SCROLL_BG_X		; SHIFT !!
	BSR.W	__SCROLL_BG_X

	BRA.S	.notOdd
	.notEven:
	MOVE.B	#0,IS_FRAME_EVEN

	;BSR.W	__SCROLL2_BG_X		; SHIFT !!
	
	MOVE.B	SCROLL_SHIFT,D1
	AND.B	#$2,D1
	MOVE.B	D1,SCROLL_SHIFT
	
	BSR.W	__SCROLL2_BG_Y
	BSR.W	__SCROLL2_BG_Y		; SHIFT !!
	;BSR.W	__SCROLL2_BG_X	

	;MOVE.L	GLITCHDATA,SCROLL_SRC
	;MOVE.L	#BGPLANE0,SCROLL_PLANE
	;BSR.W	__BLIT_GLITCH_DATA

	.notOdd:

	RTS

__BLOCK_00:
	MOVE.W	#2,Y_HALF_SHIFT

	;## HORIZ TEXTURE ##############
	MOVE.W	#16*64+wi/16,BLIT_SIZE
	MOVE.L	#0,BLIT_A_MOD
	LEA	BLEEDBOTTOM0,A4
	ADD.L	#bypl*16,A4
	BSR.W	__BLIT_GLITCH_BAND
	LEA	BLEEDBOTTOM1,A4
	ADD.L	#bypl*16,A4
	BSR.W	__BLIT_GLITCH_BAND
	;## HORIZ TEXTURE ##############

	BSR.W	__X_LFO_EASYING
	BSR.W	__X_LFO_EASYING2
	BSR.W	__Y_LFO_EASYING
	MOVE.W	Y_EASYING,X_1_4_SHIFT

	;#################################
	MOVE.W	#(he/2+16)*64+wi/16,BLIT_SIZE
	MOVE.L	#0,BLIT_A_MOD
	MOVE.B	#1,Y_HALF_DIR
	LEA	BGPLANE0,A3
	MOVE.L	A3,A4
	BSR.W	__SCROLL_Y_HALF_PROGR
	LEA	BGPLANE1,A3
	MOVE.L	A3,A4
	BSR.W	__SCROLL_Y_HALF_PROGR
	;#################################

	LEA	BGPLANE0,A3
	MOVE.L	A3,A4
	BSR.W	__SCROLL_X_1_4
	LEA	BGPLANE1,A3
	MOVE.L	A3,A4
	BSR.W	__SCROLL_X_1_4

	MOVE.B	X_1_4_DIR,D5	; INVERT
	NEG.B	D5
	MOVE.B	D5,X_1_4_DIR

	LEA	BGPLANE0,A3
	LEA	20(A3),A3
	MOVE.L	A3,A4
	BSR.W	__SCROLL_X_1_4
	LEA	BGPLANE1,A3
	LEA	20(A3),A3
	MOVE.L	A3,A4
	BSR.W	__SCROLL_X_1_4

	MOVE.B	X_1_4_DIR,D5	; RESTORE
	NEG.B	D5
	MOVE.B	D5,X_1_4_DIR
	RTS

__BLOCK_000:
	MOVE.W	X_EASYING,X_1_4_SHIFT
	MOVE.W	Y_EASYING,Y_HALF_SHIFT

	;## DRAW GLITCH ##
	MOVE.W	#16*64+wi/16,BLIT_SIZE
	MOVE.L	#0,BLIT_A_MOD
	;MOVE.W	#0,BLIT_D_MOD

	MOVE.B	#1,Y_HALF_DIR
	LEA	BGPLANE0,A3
	MOVE.L	A3,A4
	BSR.W	__SCROLL_Y_HALF

	LEA	BLEEDBOTTOM0,A4
	ADD.L	#bypl*16,A4
	BSR.W	__BLIT_GLITCH_BAND

	LEA	BGPLANE0,A3
	MOVE.L	A3,A4
	BSR.W	__SCROLL_X_PROGR_SPLITX2

	MOVE.B	X_PROGR_DIR,D5	; INVERT
	NEG.B	D5
	MOVE.B	D5,X_PROGR_DIR

	LEA	BGPLANE0,A3
	MOVE.L	A3,A4
	BSR.W	__SCROLL_X_PROGR_SPLITX2

	MOVE.B	X_PROGR_DIR,D5	; INVERT
	NEG.B	D5
	MOVE.B	D5,X_PROGR_DIR

	BSR.W	__Y_LFO_EASYING
	BSR.W	__X_LFO_EASYING
	RTS

__BLOCK_0000:
	BSR.W	__X_LFO_EASYING
	BSR.W	__Y_LFO_EASYING
	BSR.W	__X_LFO_EASYING2
	MOVE.W	X_EASYING,X_1_4_SHIFT
	MOVE.W	Y_EASYING,Y_HALF_SHIFT
	MOVE.W	X_EASYING2,X_PROGR_SHIFT

	;## TILE TEXTURE ##
	LEA	TEXTURERESET3,A5
	LEA	BGPLANE0,A4
	BSR.W	__BLIT_GLITCH_TILE
	LEA	TEXTURERESET4,A5
	LEA	BGPLANE1,A4
	BSR.W	__BLIT_GLITCH_TILE
	;## TILE TEXTURE ##

	;## VERTICAL TEXTURE ###########
	MOVE.L	#$10000,BLIT_A_MOD
	LEA	BGPLANE0,A4
	ADD.L	#bypl/2-2,A4
	;BSR.W	__BLIT_GLITCH_SLICE
	LEA	BGPLANE1,A4
	ADD.L	#bypl/2-2,A4
	;BSR.W	__BLIT_GLITCH_SLICE
	;## VERTICAL TEXTURE ###########

	;## HORIZ TEXTURE ##############
	MOVE.W	#16*64+wi/16,BLIT_SIZE
	MOVE.L	#0,BLIT_A_MOD
	LEA	BLEEDBOTTOM0,A4
	ADD.L	#bypl*16,A4
	LEA	TEXTURERESET1,A5
	BSR.W	__BLIT_GLITCH_BAND
	LEA	BLEEDBOTTOM1,A4
	ADD.L	#bypl*16,A4
	LEA	TEXTURERESET2,A5
	BSR.W	__BLIT_GLITCH_BAND
	;## HORIZ TEXTURE ##############

	;#################################
	MOVE.W	#(he/2+16)*64+wi/16,BLIT_SIZE
	MOVE.L	#0,BLIT_A_MOD
	MOVE.B	#1,Y_HALF_DIR
	MOVE.W	#2,Y_HALF_SHIFT
	LEA	BGPLANE0,A3
	MOVE.L	A3,A4
	BSR.W	__SCROLL_Y_HALF_PROGR
	MOVE.W	#2,Y_HALF_SHIFT
	LEA	BGPLANE1,A3
	MOVE.L	A3,A4
	BSR.W	__SCROLL_Y_HALF_PROGR
	;#################################

	MOVE.B	#1,X_PROGR_DIR
	LEA	BGPLANE0,A3
	LEA	20(A3),A3
	MOVE.L	A3,A4
	BSR.W	__SCROLL_X_PROGR

	MOVE.B	#-1,X_PROGR_DIR
	LEA	BGPLANE0,A3
	MOVE.L	A3,A4
	BSR.W	__SCROLL_X_PROGR

	MOVE.B	#1,X_PROGR_DIR
	LEA	BGPLANE1,A3
	LEA	20(A3),A3
	MOVE.L	A3,A4
	BSR.W	__SCROLL_X_PROGR

	MOVE.B	#-1,X_PROGR_DIR
	LEA	BGPLANE1,A3
	MOVE.L	A3,A4
	BSR.W	__SCROLL_X_PROGR
	RTS

__BLOCK_END:
	RTS

;********** Fastmem Data **********
TIMELINE:		DC.L __BLOCK_0000,__BLOCK_0000,__BLOCK_END

BPL_PTR_BUF:	DC.L 0
AUDIOCHLEVEL0NRM:	DC.W 0
AUDIOCHLEVEL0:	DC.W 0
AUDIOCHLEVEL1:	DC.W 0
AUDIOCHLEVEL2:	DC.W 0
AUDIOCHLEVEL3:	DC.W 0
P61_LAST_POS:	DC.W MODSTART_POS
P61_DUMMY_POS:	DC.W 0
P61_FRAMECOUNT:	DC.W 0
SCROLL_INDEX:	DC.W 0
SCROLL_PLANE:	DC.L 0
SCROLL_SRC:	DC.L 0
SPR_0_POS:	DC.B $7C		; K
SPR_1_POS:	DC.B $84		; O
SPR_2_POS:	DC.B $8C		; N
SPR_3_POS:	DC.B $94		; E
SPR_4_POS:	DC.B $9C		; Y
SCROLL_SHIFT:	DC.B 0
SHIFT_INCR:	DC.B -1
SCROLL_SHIFT_Y:	DC.B 2
SCROLL_DIR_X:	DC.B 1		; 0=LEFT 1=RIGHT
SCROLL_DIR_Y:	DC.B 0		; 0=LEFT 1=RIGHT
SCROLL_DIR_0:	DC.B 1
SCROLL_DIR_1:	DC.B 1
SCROLL_DIR_2:	DC.B 1
SCROLL_DIR_3:	DC.B 1
IS_FRAME_EVEN:	DC.B 1,0
TEXTINDEX:	DC.W 0
FRAME_STROBE:	DC.B 0,0
BLIT_Y_MASK:	DC.W $FFFF
BLIT_X_MASK:	DC.W $FFFF
BLIT_A_MOD:	DC.W 0
BLIT_D_MOD:	DC.W 0
BLIT_SIZE:	DC.W 2*64+wi/2/16

X_CYCLES_COUNTER:	DC.W 15
X_1_4_DIR:	DC.B -1		; -1=LEFT 1=RIGHT
Y_1_4_DIR:	DC.B -1		; -1=LEFT 1=RIGHT
X_1_4_SHIFT:	DC.W 3
Y_1_4_SHIFT:	DC.W 10
X_HALF_DIR:	DC.B -1
Y_HALF_DIR:	DC.B 1
X_HALF_SHIFT:	DC.W 0
Y_HALF_SHIFT:	DC.W 2

X_PROGR_DIR:	DC.B -1
Y_PROGR_DIR:	DC.B 1
X_PROGR_TYPE:	DC.B 1
Y_PROGR_TYPE:	DC.B 1		; SOLO POSITIVO
X_PROGR_SHIFT:	DC.W 1

KICKSTART_ADDR:	DC.L $F80000	; POINTERS TO BITMAPS
TEXTURERESET1:	DC.L X_TEXTURE_MIRROR+TEXTURE_H*bypl
		DC.L X_TEXTURE_MIRROR+TEXTURE_H*bypl
TEXTURERESET2:	DC.L X_TEXTURE_MIRROR+TEXTURE_H*bwid
		DC.L X_TEXTURE_MIRROR+TEXTURE_H*bwid
TEXTURERESET3:	DC.L TEXTURE_V
		DC.L TEXTURE_V
TEXTURERESET4:	DC.L TEXTURE_V+TEXTURE_H*(64/16*2)	; FIRST LONG IS RESET ADDRESS
		DC.L TEXTURE_V+TEXTURE_H*(64/16*2)	; SECOND LONG IS CURRENT ADDRESS

Y_EASYING_INDX:	DC.W 48
Y_EASYING_TBL:	DC.W $1,$2,$1,$2,$1,$2,$1,$2,$2,$3,$2,$3,$2,$3,$3,$3,$4,$3,$4,$4,$4,$4,$4,$4,$5,$4,$5,$4,$5,$4,$5,$5
		DC.W $5,$6,$5,$6,$5,$6,$5,$6,$5,$5,$5,$5,$4,$5,$4,$5,$4,$4,$4,$3,$4,$3,$3,$2,$3,$2,$1,$2,$1,$2,$1,$1
Y_EASYING:	DC.W 1

X_EASYING_INDX:	DC.W 60
X_EASYING_TBL:	DC.W $1,$2,$1,$2,$2,$2,$2,$3,$3,$3,$3,$4,$4,$4,$4,$5,$5,$5,$5,$6,$6,$7,$6,$7,$6,$6,$5,$5,$5,$5,$4,$4
		DC.W $3,$4,$3,$3,$3,$3,$3,$2,$2,$2,$2,$2,$2,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1,$1
X_EASYING:	DC.W 1

X_EASYING2_INDX:	DC.W 4
X_EASYING2_TBL:	DC.W $1,$2,$1,$1,$2,$3,$2,$3,$2,$3,$4,$3,$4,$3,$4,$5,$4,$5,$6,$5,$6,$7,$6,$7,$8,$7,$8,$9,$8,$8,$7,$6
		DC.W $7,$6,$5,$6,$5,$4,$4,$3,$2,$3,$2,$3,$2,$1,$2,$1,$2,$1,$2,$1,$2,$1,$2,$1,$2,$1,$1,$1,$1,$1,$1,$0
X_EASYING2:	DC.W 1

	;*******************************************************************************
	SECTION	ChipData,DATA_C	;declared data that must be in chipmem
	;*******************************************************************************

BLEEDTOP0:	DS.B 16*bypl*2
BGPLANE0:		DS.B he/2*bypl
BLEEDBOTTOM0:	DS.B 16*bypl*2
BLEEDTOP1:	DS.B 16*bypl*2
BGPLANE1:		DS.B he/2*bypl
BLEEDBOTTOM1:	DS.B 16*bypl*2

SPRITES:		INCLUDE "sprite_KONEY.s"
PATTERN:		INCBIN "pattern_new.raw"
TEXTURE:		INCBIN "PurpleT_160x320x2.raw"
TEXTURE_V:	INCBIN "ThinPurple_64x320x2.raw"

FONT:		DC.L 0,0		; SPACE CHAR
		INCBIN "digital_font.raw",0
		EVEN

TEXT:		DC.B "!!WARNING!! - EPILEPSY DANGER AHEAD!!   SERIOUSLY... :)    "
		DC.B "LOREM IPSUM :)            .EOF			     "
		EVEN
_TEXT:

COPPER:
	DC.W $1FC,0	; Slow fetch mode, remove if AGA demo.
	DC.W $8E,$2C81	; 238h display window top, left | DIWSTRT - 11.393
	DC.W $90,$2CC1	; and bottom, right.	| DIWSTOP - 11.457
	DC.W $92,$38	; Standard bitplane dma fetch start
	DC.W $94,$D0	; and stop for standard screen.
	DC.W $106,$0C00	; (AGA compat. if any Dual Playf. mode)
	DC.W $108,0	; BPL1MOD	 Bitplane modulo (odd planes)
	DC.W $10A,0	; BPL2MOD Bitplane modulo (even planes)
	DC.W $102,0	; SCROLL REGISTER (AND PLAYFIELD PRI)

	.Palette:
	DC.W $0180,$0000,$0182,$0002,$0184,$0507,$0186,$0706
	DC.W $0188,$0667,$018A,$0333,$018C,$0667,$018E,$0777
	DC.W $0190,$0888,$0192,$0888,$0194,$0999,$0196,$0AAA
	DC.W $0198,$0BBB,$019A,$0CCC,$019C,$0DDD,$019E,$0FFF

	.BplPtrs:
	DC.W $E0,0
	DC.W $E2,0
	DC.W $E4,0
	DC.W $E6,0
	DC.W $E8,0
	DC.W $EA,0
	DC.W $EC,0
	DC.W $EE,0
	DC.W $F0,0
	DC.W $F2,0
	DC.W $F4,0
	DC.W $F6,0		;full 6 ptrs, in case you increase bpls
	DC.W $100,bpls*$1000+$200	;enable bitplanes

	.SpritePointers:
	DC.W $120,0,$122,0	; 0
	DC.W $124,0,$126,0	; 1
	DC.W $128,0,$12A,0	; 2
	DC.W $12C,0,$12E,0	; 3
	DC.W $130,0,$132,0	; 4
	DC.W $134,0,$136,0	; 5
	DC.W $138,0,$13A,0	; 6
	DC.W $13C,0,$13E,0	; 7

	DC.W $1A6
	DC.W $000		; COLOR0-1
	DC.W $1AE
	DC.W $000		; COLOR2-3
	DC.W $1B6
	DC.W $000		; COLOR4-5

	.COPPERWAITS:
	IFNE	COP_DEFRAG
	DS.W 16*4*4	; GRADIENTS
	DS.W he/2*bpls*4	; 4 word * lines + 2 VPOS>$ff
	DS.W 2		; 4 word * lines + 2 VPOS>$ff
	ENDC
_COPPER:

COPWAITSSRC:
	IFNE	COP_Y_MIRROR
	.BplPtrsWaits:
	DS.W he/2*bpls*4	; 4 word * lines + 2 VPOS>$ff
	DS.W 2		; 4 word * lines + 2 VPOS>$ff
	ENDC

	.gradients:
	DS.W 16*4*4
	DC.W $FFFF,$FFFE	; magic value to end copperlist

;*******************************************************************************
	SECTION ChipBuffers,BSS_C	;BSS doesn't count toward exe size
;*******************************************************************************

X_TEXTURE_MIRROR:	DS.B TEXTURE_H*bwid	; mirrored texture
DITHERPLANE:	DS.B TEXTURE_H*bypl	; 1 plane
END