;*** MiniStartup by Photon ***
	INCDIR	"NAS:AMIGA/CODE/crippled_cyborg_amiga/"
	SECTION	"Code",CODE
	INCLUDE	"PhotonsMiniWrapper1.04!.S"
	INCLUDE	"Blitter-Register-List.S"	;use if you like ;)
	INCLUDE	"PT12_OPTIONS.i"
	INCLUDE	"P6112-Play-stripped.i"
;********** Constants **********
w=	336		; screen width
h=	256		; screen height
bpls=	4		; depth
bpl=	w/16*2		; byte-width of 1 bitplane line (40bytes)
bwid=	bpls*bpl		; byte-width of 1 pixel line (all bpls)
blitsize=	h*64+w/16	; size of blitter operation
blitsizeF=%000000000000010101	; size of FULL blitter operation
bplsize=	bpl*h		; size of 1 bitplane screen
hband=	10		; lines reserved for textscroller
hblit=	h	;-hband		; size of blitter op without textscroller
;*************
MODSTART_POS=0		; start music at position # !! MUST BE EVEN FOR 16BIT
;*************

;********** Demo **********	;Demo-specific non-startup code below.
Demo:				;a4=VBR, a6=Custom Registers Base addr
	;*--- init ---*
	MOVE.L	#VBint,$6C(A4)
	MOVE.W	#%1110000000100000,INTENA
	;** SOMETHING INSIDE HERE IS NEEDED TO MAKE MOD PLAY! **
	MOVE.W	#%1000011111100000,DMACON	; BIT10=BLIT NASTY
	MOVE.W	MODSTART_POS,D3
	CMP.W	#0,D3
	BEQ.S	.dontDisableBlitterNasty	; IF START > 0 DISABLE BLIT NASTY NOW
	MOVE.W	#%0000010000000000,DMACON	; BIT10=BLIT NASTY DISABLED
	.dontDisableBlitterNasty:
	;*--- clear screens ---*
	LEA	SCREEN1,A1
	BSR.W	ClearScreen
	LEA	SCREEN2,A1
	BSR.W	ClearScreen
	BSR	WaitBlitter
	;*--- start copper ---*
	LEA	SCREEN1,A0
	MOVEQ	#bpl,D0
	LEA	BplPtrs+2,A1
	MOVEQ	#bpls-1,D1
	BSR.W	PokePtrs

	; #### CPU INTENSIVE TASKS BEFORE STARTING MUSIC
	JSR	__ADD_BLITTER_WORD
	JSR	__CREATESCROLLSPACE
	; #### CPU INTENSIVE TASKS BEFORE STARTING MUSIC

	; #### Point LOGO sprites
	LEA	SpritePointers,A1	; Puntatori in copperlist
	MOVE.L	#SPRT_K,D0	; indirizzo dello sprite in d0
	MOVE.L	#0,D0
	MOVE.W	D0,6(A1)
	SWAP	D0
	MOVE.W	D0,2(A1)

	ADDQ.W	#8,A1
	MOVE.L	#SPRT_O,D0	; indirizzo dello sprite in d0
	MOVE.L	#0,D0
	MOVE.W	D0,6(A1)
	SWAP	D0
	MOVE.W	D0,2(A1)

	ADDQ.W	#8,A1
	MOVE.L	#SPRT_N,D0	; indirizzo dello sprite in d0
	MOVE.L	#0,D0
	MOVE.W	D0,6(A1)
	SWAP	D0
	MOVE.W	D0,2(A1)

	ADDQ.W	#8,A1
	MOVE.L	#SPRT_Y,D0	; indirizzo dello sprite in d0
	MOVE.L	#0,D0
	MOVE.W	D0,6(A1)
	SWAP	D0
	MOVE.W	D0,2(A1)

	ADDQ.W	#8,A1
	MOVE.L	#SPRT_E,D0	; indirizzo dello sprite in d0
	MOVE.L	#0,D0
	MOVE.W	D0,6(A1)
	SWAP	D0
	MOVE.W	D0,2(A1)
	; #### Point LOGO sprites

	;---  Call P61_Init  ---
	MOVEM.L	D0-A6,-(SP)
	LEA	MODULE,A0
	SUB.L	A1,A1
	SUB.L	A2,A2
	MOVE.W	#MODSTART_POS,P61_InitPos	; TRACK START OFFSET
	;JSR	P61_Init
	MOVEM.L (SP)+,D0-A6

	MOVE.L	#COPPER,$80(a6)

;********************  main loop  ********************
MainLoop:
	move.w	#$12c,d0		;No buffering, so wait until raster
	bsr.w	WaitRaster	;is below the Display Window.
	;*--- swap buffers ---*
	movem.l	DrawBuffer(PC),a2-a3
	exg	a2,a3
	movem.l	a2-a3,DrawBuffer	;draw into a2, show a3
	;*--- show one... ---*
	move.l	a3,a0
	move.l	#bpl*h,d0
	lea	BplPtrs+2,a1
	moveq	#bpls-1,d1
	bsr.w	PokePtrs
	;*--- ...draw into the other(a2) ---*
	move.l	a2,a1
	;bsr	ClearScreen

	BSR.W	__SET_PT_VISUALS
	MOVE.L	KONEYBG,DrawBuffer

	; do stuff here :)

	; ## SONG POS RESETS ##
	MOVE.W	P61_Pos,D6
	MOVE.W	P61_DUMMY_POS,D5
	CMP.W	D5,D6
	BEQ.S	.dontReset
	ADDQ.W	#1,P61_DUMMY_POS
	ADDQ.W	#1,P61_LAST_POS
	.dontReset:
	; ## SONG POS RESETS ##

	SONG_BLOCKS_EVENTS:
	;* FOR TIMED EVENTS ON BLOCK ****
	;CLR.W	$100		; DEBUG | w 0 100 2
	MOVE.W	P61_LAST_POS,D5
	LEA	TIMELINE,A3
	;MULU.W	#4,D5		; CALCULATES OFFSET FROM SONGPOSITION
	LSL.W	#2,D5		; CALCULATES OFFSET (OPTIMIZED)
	MOVE.L	(A3,D5),A4	; THANKS HEDGEHOG!!
	JSR	(A4)		; EXECUTE SUBROUTINE BLOCK#

	; ## LOGO ##############
	MOVE.B	SPR_0_POS,D0
	SUB.B	AUDIOCHLEVEL1,D0
	SUB.B	AUDIOCHLEVEL1,D0
	MOVE.B	D0,SPRT_K_POS

	MOVE.B	SPR_1_POS,D0
	SUB.B	AUDIOCHLEVEL1,D0
	MOVE.B	D0,SPRT_O_POS

	MOVE.B	SPR_3_POS,D0
	ADD.B	AUDIOCHLEVEL1,D0
	MOVE.B	D0,SPRT_E_POS

	MOVE.B	SPR_4_POS,D0
	ADD.B	AUDIOCHLEVEL1,D0
	ADD.B	AUDIOCHLEVEL1,D0
	MOVE.B	D0,SPRT_Y_POS
	; ## LOGO ##############

	;*--- main loop end ---*

	ENDING_CODE:
	BTST	#6,$BFE001
	BNE.S	.DontShowRasterTime
	MOVE.W	#$FF0,$180(A6)	; show rastertime left down to $12c
	;SUB.L	#bpl,BGPLANE3	; SCROLL 1PX UP
	;ADD.L	#bpl,BGPLANE0	; SCROLL 1PX UP
	;MOVE.W	#2,CIPPA
	.DontShowRasterTime:
	BTST	#2,$DFF016	; POTINP - RMB pressed?
	BNE.W	MainLoop		; then loop
	;*--- exit ---*
	;;    ---  Call P61_End  ---
	MOVEM.L D0-A6,-(SP)
	JSR P61_End
	MOVEM.L (SP)+,D0-A6
	RTS

;********** Demo Routines **********
PokePtrs:				; Generic, poke ptrs into copper list
	.bpll:	
	move.l	a0,d2
	swap	d2
	move.w	d2,(a1)		;high word of address
	move.w	a0,4(a1)		;low word of address
	addq.w	#8,a1		;skip two copper instructions
	add.l	d0,a0		;next ptr
	dbf	d1,.bpll
	rts

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

__ADD_BLITTER_WORD:
	MOVEM.L	D0-A6,-(SP)	; SAVE TO STACK
	LEA	BG1_DATA,A0
	LEA	BG1,A1
	;ADD.W	#h*bpls,A0		; POSITIONING THE SOURCE
	MOVE.L	#h*bpls-1,D1	; LINES
	.OUTERLOOP:
	MOVE.L	#(w-16)/16-1,D0	; SIZE OF SOURCE IN WORDS
	.INNERLOOP:
	MOVE.W	(A0)+,(A1)+
	DBRA	D0,.INNERLOOP
	MOVE.W	#0,(A1)+		; THE EXTRA WORD
	DBRA.W	D1,.OUTERLOOP

	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	RTS

__CREATESCROLLSPACE:
	MOVEM.L	D0-A6,-(SP)	; SAVE TO STACK
	MOVEQ	#bpls-1,D1	; UGUALI PER TUTTI I BITPLANE
	MOVE.L	#%00000000111111110000000000000000,D2	
	MOVE.L	KONEYBG,A4
	.OUTERLOOP:
	MOVEQ	#0,D6		; RESET D6
	MOVE.W	#bpl*hband-1,D6
	ADD.W	#bpl*(hblit),A4	; POSITIONING
	.INNERLOOP:
	MOVE.B	D2,(A4)+	
	DBRA	D6,.INNERLOOP
	ROR.L	#8,D2		; LAST BITPLANE FILLED
	DBRA	D1,.OUTERLOOP
	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	RTS

__SCROLL_BG_PLANE:
	MOVEM.L	D0-A6,-(SP)	; SAVE TO STACK
	BTST.B	#6,DMACONR	; for compatibility

	MOVE.B	SCROLL_SHIFT,D1
	AND.B	#15,D1
	MOVE.B	D1,SCROLL_SHIFT

	MOVE.W	#%0000100111110000,D1
	MOVE.B	SCROLL_DIRECTION,D5
	;NOT.B	D5
	MOVE.B	D5,SCROLL_DIRECTION

	;ADD.L	#4,GLITCHSRC

	CMP.B	#1,D5
	BEQ.B	.mainBlit

	; ## FOR LEFT ####
	MOVE.L	SCROLL_PLANE,A4	; PATCH FIRST WORD COLUMN
	bsr	WaitBlitter
	MOVE.L	GLITCHSRC,BLTAPTH	; BLTAPT  (fisso alla figura sorgente)
	ADD.L	#bpl-2,A4		; POSITION FOR DESC
	MOVE.L	A4,BLTDPTH
	MOVE.W	#$FFFF,BLTAFWM	; BLTAFWM lo spiegheremo dopo
	MOVE.W	#$FFFF,BLTALWM	; BLTALWM lo spiegheremo dopo
	MOVE.W	D1,BLTCON0	; BLTCON0 (usa A+D); con shift di un pixel
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1 BIT 12 DESC MODE
	MOVE.W	#bpl-2,BLTAMOD	; BLTAMOD =0 perche` il rettangolo
	MOVE.W	#bpl-2,BLTDMOD	; BLTDMOD 40-4=36 il rettangolo

	MOVE.W	#(hblit<<6)+%000001,BLTSIZE	; BLTSIZE (via al blitter !)
	; ## FOR LEFT ####

	; ## MAIN BLIT ####
	.mainBlit:
	MOVE.L	SCROLL_PLANE,A4
	ROL.W	#4,D1
	MOVE.B	SCROLL_SHIFT,D1
	ROR.W	#4,D1
	bsr	WaitBlitter
	MOVE.W	#$FFFF,BLTAFWM	; BLTAFWM lo spiegheremo dopo
	MOVE.W	#$FFFF,BLTALWM	; BLTALWM lo spiegheremo dopo
	MOVE.W	D1,BLTCON0	; BLTCON0 (usa A+D); con shift di un pixel
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1 BIT 12 DESC MODE
	MOVE.W	#0,BLTAMOD	; BLTAMOD =0 perche` il rettangolo
	MOVE.W	#0,BLTDMOD	; BLTDMOD 40-4=36 il rettangolo

	CMP.B	#1,D5
	BEQ.B	.goBlitter		; FOR LEFT
	ADD.L	#bpl*hblit-2,A4
	MOVE.W	#%0000000000000010,BLTCON1	; BLTCON1 BIT 12 DESC MODE

	.goBlitter:
	MOVE.L	A4,BLTAPTH	; BLTAPT  (fisso alla figura sorgente)
	MOVE.L	A4,BLTDPTH
	MOVE.W	#(hblit<<6)+%00010101,BLTSIZE	; BLTSIZE (via al blitter !)

	; ## MAIN BLIT ####

	CMP.B	#1,D5
	BNE.B	.skip
	
	; ## FOR RIGHT ####
	MOVE.L	SCROLL_PLANE,A4	; PATCH FIRST WORD COLUMN
	bsr	WaitBlitter
	MOVEQ	#bpl-2,D0
	MOVE.L	GLITCHSRC,BLTAPTH	; BLTAPT  (fisso alla figura sorgente)
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

	ADD.B	#2,SCROLL_SHIFT

	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	RTS

__SET_PT_VISUALS:
	; ## MOD VISUALIZERS ##########
	ifne visuctrs
	MOVEM.L D0-A6,-(SP)

	; ## COMMANDS 80x TRIGGERED EVENTS ##
	MOVE.W	P61_1F,D2		; 1Fx
	CMPI.W	#4,D2		; 1F4 - INVERT DIRECTION CH 3
	BNE.S	.keepDir0
	MOVE.B	SCROLL_DIR_0,D1
	NOT	D1
	MOVE.B	D1,SCROLL_DIR_0
	MOVE.W	#0,P61_1F		; RESET FX
	.keepDir0:
	MOVE.W	P61_E8,D2		; 80x
	CMPI.W	#4,D2		; 804 - INVERT DIRECTION CH 3
	BNE.S	.keepDir3
	MOVE.B	SCROLL_DIR_3,D1
	NOT	D1
	MOVE.B	D1,SCROLL_DIR_3
	MOVE.W	#0,P61_E8	; RESET FX
	.keepDir3:
	MOVE.W	P61_E8,D2		; 80x
	CMPI.W	#1,D2		; 804 - INVERT DIRECTION CH 3
	BNE.S	.keepDir1
	MOVE.B	SCROLL_DIR_1,D1
	NOT	D1
	MOVE.B	D1,SCROLL_DIR_1
	MOVE.W	#0,P61_E8	; RESET FX
	.keepDir1:
	; ## COMMANDS 80x TRIGGERED EVENTS ##

	; GLITCH
	LEA	P61_visuctr0(PC),A0 ; which channel? 0-3
	MOVEQ	#45,D0		; maxvalue
	SUB.W	(A0),D0		; -#frames/irqs since instrument trigger
	BPL.S	.ok5		; below minvalue?
	MOVEQ	#0,D0		; then set to minvalue
	.ok5:
	CMPI.W	#16,D0
	BLO.S	.keepValue
	MOVEQ	#15,D0
	.keepValue:	
	MOVE.B	D0,AUDIOCHLEVEL0NRM
	_ok5:

	; GLITCH
	LEA	P61_visuctr0(PC),A0 ; which channel? 0-3
	MOVEQ	#30,D0		; maxvalue
	SUB.W	(A0),D0		; -#frames/irqs since instrument trigger
	BPL.S	.ok0		; below minvalue?
	MOVEQ	#0,D0		; then set to minvalue
	.ok0:
	MOVE.B	D0,AUDIOCHLEVEL0
	_ok0:

	; KICK
	LEA	P61_visuctr1(PC),A0 ; which channel? 0-3
	MOVEQ	#8,D0		; maxvalue
	SUB.W	(A0),D0		; -#frames/irqs since instrument trigger
	BPL.S	.ok1		; below minvalue?
	MOVEQ	#0,D0		; then set to minvalue
	.ok1:
	MOVE.B	D0,AUDIOCHLEVEL1
	MULU.W	#$2,D0		; start from a darker shade
	MOVE.L	D0,D3
	ROL.L	#$4,D3		; expand bits to green
	ADD.L	D3,D0
	ROL.L	#$4,D3
	ADD.L	D3,D0		; expand bits to red
	MOVE.W	D0,LOGOCOL1	; poke WHITE color now
	MOVE.W	D0,LOGOCOL2	; poke WHITE color now
	MOVE.W	D0,LOGOCOL3	; poke WHITE color now
	_ok1:

	; BASS
	LEA	P61_visuctr2(PC),A0 ; which channel? 0-3
	MOVEQ	#15,D0		; maxvalue
	SUB.W	(A0),D0		; -#frames/irqs since instrument trigger
	BPL.S	.ok2		; below minvalue?
	MOVEQ	#0,D0		; then set to minvalue
	.ok2:
	MOVE.B	D0,AUDIOCHLEVEL2
	_ok2:

	; CYBORG
	LEA	P61_visuctr3(PC),A0 ; which channel? 0-3
	MOVEQ	#15,D0		; maxvalue
	SUB.W	(A0),D0		; -#frames/irqs since instrument trigger
	BPL.S	.ok3		; below minvalue?
	MOVEQ	#0,D0		; then set to minvalue
	.ok3:
	MOVE.B	D0,AUDIOCHLEVEL3
	;CMP.W	#15,D0
	;BLO.W	.keepValue
	;MOVE.B	SCROLL_DIR_3,D1
	;NOT	D1
	;MOVE.B	D1,SCROLL_DIR_3
	;.keepValue:
	_ok3:

	MOVEM.L (SP)+,D0-A6
	RTS
	endc
	; MOD VISUALIZERS *****

__POPULATETXTBUFFER:
	MOVEM.L	D0-A6,-(SP)	; SAVE TO STACK
	MOVE.W	FRAMESINDEX,D7
	CMP.W	#4,D7
	BNE.W	.SKIP
	MOVE.L	BGPLANE3,A4
	LEA	FONT,A5
	LEA	TEXT,A6
	ADD.W	#bpl*(hblit),A4	; POSITIONING
	ADD.W	TEXTINDEX,A6
	CMP.L	#_TEXT-1,A6	; Siamo arrivati all'ultima word della TAB?
	BNE.S	.PROCEED
	MOVE.W	#0,TEXTINDEX	; Riparti a puntare dalla prima word
	LEA	TEXT,A6		; FIX FOR GLITCH (I KNOW IT'S FUN... :)
	.PROCEED:
	MOVE.B	(A6),D2		; Prossimo carattere in d2
	SUB.B	#$20,D2		; TOGLI 32 AL VALORE ASCII DEL CARATTERE, IN
	MULU.W	#8,D2		; MOLTIPLICA PER 8 IL NUMERO PRECEDENTE,
	ADD.W	D2,A5
	MOVEQ	#0,D6		; RESET D6
	MOVE.B	#8-1,D6
	.LOOP:
	ADD.W	#bpl-2,A4		; POSITIONING
	MOVE.B	(A5)+,(A4)+
	MOVE.B	#%00000000,(A4)+	; WRAPS MORE NICELY?
	DBRA	D6,.LOOP
	ADD.W	#bpl*2-2,A4		; POSITIONING
	MOVE.B	#%00000000,(A4)	; WRAPS MORE NICELY?
	.SKIP:
	SUB.W	#1,D7
	CMP.W	#0,D7
	BEQ.W	.RESET
	MOVE.W	D7,FRAMESINDEX
	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	RTS
	.RESET:
	ADD.W	#1,TEXTINDEX
	MOVE.W	#4,D7
	MOVE.W	D7,FRAMESINDEX	; OTTIMIZZABILE
	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	RTS

__SHIFTTEXT:
	MOVEM.L	D0-A6,-(SP)	; SAVE TO STACK
	BTST.B	#6,DMACONR	; for compatibility
	bsr	WaitBlitter

	MOVE.L	BGPLANE3,A4
	ADD.W	#bpl*h-2,A4	; POSITIONING
	MOVE.W	#$FFFF,BLTAFWM	; BLTAFWM lo spiegheremo dopo
	MOVE.W	#$FFFF,BLTALWM	; BLTALWM lo spiegheremo dopo
	MOVE.W	#%0010100111110000,BLTCON0	; BLTCON0 (usa A+D); con shift di un pixel
	MOVE.W	#%0000000000000010,BLTCON1	; BLTCON1 BIT 12 DESC MODE
	MOVE.W	#0,BLTAMOD	; BLTAMOD =0 perche` il rettangolo
	MOVE.W	#0,BLTDMOD	; BLTDMOD 40-4=36 il rettangolo

	MOVE.L	A4,BLTAPTH	; BLTAPT  (fisso alla figura sorgente)
	MOVE.L	A4,BLTDPTH

	MOVE.W	#(hband-1)*64+w/16,BLTSIZE	; BLTSIZE (via al blitter !)

	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	RTS

__BLOCK_0:
	; 0: EMPTY_BEGIN
	MOVE.B	#0,SCROLL_DIRECTION
	MOVE.L	GLITCHDATA,GLITCHSRC
	MOVE.L	BGPLANE3,SCROLL_PLANE
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIRECTION,D5
	;NOT.B	D5
	MOVE.B	D5,SCROLL_DIRECTION

	MOVE.L	BGPLANE0,GLITCHSRC
	MOVE.L	BGPLANE1,SCROLL_PLANE
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	ADD.B	#1,SCROLL_SHIFT

	MOVE.B	SCROLL_INDEX,D5
	ADD.B	#5,D5
	AND.B	#31,D5
	MOVE.B	D5,SCROLL_INDEX
	TST.B	D5
	BNE.S	.skip
	;MOVE.B	#0,SCROLL_SHIFT
	MOVE.B	SCROLL_DIRECTION,D5
	;NOT.B	D5
	MOVE.B	D5,SCROLL_DIRECTION
	;ADD.B	#1,SCROLL_SHIFT
	BRA.S	.skip2
	.skip:

	MOVE.L	BGPLANE1,GLITCHSRC
	MOVE.L	BGPLANE2,SCROLL_PLANE
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	ADD.L	#4,GLITCHDATA

	.skip2:

	ADD.B	#1,SCROLL_SHIFT
	MOVE.L	BGPLANE3,GLITCHSRC
	MOVE.L	BGPLANE0,SCROLL_PLANE
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	;MOVE.B	#1,SCROLL_DIRECTION

	;ADD.L	#bpl,BGPLANE0
	;SUB.L	#bpl,BGPLANE1
	;ADD.L	#bpl,BGPLANE2
	;SUB.L	#bpl,BGPLANE3

	;BSR.W	__POPULATETXTBUFFER
	;BSR.W	__SHIFTTEXT
	RTS

__BLOCK_1:
	; 1: Solo Robot
	MOVE.W	#%0000010000000000,DMACON	; BIT10=BLIT NASTY DISABLED
	BSR.W	__POPULATETXTBUFFER
	BSR.W	__SHIFTTEXT
	
	MOVE.B	#0,SCROLL_DIRECTION
	MOVE.L	BGPLANE1,SCROLL_PLANE
	MOVE.B	#1,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_3,SCROLL_DIRECTION
	MOVE.L	BGPLANE2,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL3,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	#1,SCROLL_DIRECTION
	MOVE.L	BGPLANE3,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL3,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	RTS

__BLOCK_2:
	; 4: Robot + KassaImberlada Kambio
	; 2: Robot + Kassa (pausa)
	BSR.W	__POPULATETXTBUFFER
	BSR.W	__SHIFTTEXT
	
	MOVE.B	#1,SCROLL_DIRECTION
	MOVE.L	BGPLANE0,SCROLL_PLANE
	MOVE.B	#3,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	; BASS DRIVING KICK DELAY
	;MOVE.B	#1,SCROLL_DIRECTION
	;MOVE.L	BGPLANE0,SCROLL_PLANE
	;MOVE.B	AUDIOCHLEVEL2,SCROLL_SHIFT
	;BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_3,SCROLL_DIRECTION
	MOVE.L	BGPLANE2,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL3,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!
	RTS

__BLOCK_3:
	; 5: Robot + Ritmo + KassaIPERImb
	BSR.W	__POPULATETXTBUFFER
	BSR.W	__SHIFTTEXT
	
	; BASS DRIVING KICK DELAY
	MOVE.B	#1,SCROLL_DIRECTION
	MOVE.L	BGPLANE1,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL2,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_3,SCROLL_DIRECTION
	MOVE.L	BGPLANE2,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL3,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_0,SCROLL_DIRECTION
	MOVE.L	BGPLANE3,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL0NRM,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!
	RTS

__BLOCK_4:
	; 2: Robot + Kassa (pausa)
	BSR.W	__POPULATETXTBUFFER
	BSR.W	__SHIFTTEXT
	
	; BASS
	MOVE.B	#0,SCROLL_DIRECTION
	MOVE.L	BGPLANE1,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL2,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_3,SCROLL_DIRECTION
	MOVE.L	BGPLANE2,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL3,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_0,SCROLL_DIRECTION
	MOVE.L	BGPLANE3,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL0NRM,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!
	RTS

__BLOCK_5:
	; 5: Robot + Ritmo + KassaIPERImb
	MOVE.W	#2,BPL1MOD		; FIX GLITCH
	MOVE.W	#2,BPL2MOD		; RESET

	BSR.W	__POPULATETXTBUFFER
	BSR.W	__SHIFTTEXT
	
	; BASS
	MOVE.B	#1,SCROLL_DIRECTION
	MOVE.L	BGPLANE1,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL2,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_3,SCROLL_DIRECTION
	MOVE.L	BGPLANE3,SCROLL_PLANE	; INVERT
	MOVE.B	AUDIOCHLEVEL3,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_0,SCROLL_DIRECTION
	MOVE.L	BGPLANE2,SCROLL_PLANE	; INVERT
	MOVE.B	AUDIOCHLEVEL0NRM,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	RTS

__BLOCK_6:
	; 15 8: KAssa pause
	BSR.W	__POPULATETXTBUFFER
	BSR.W	__SHIFTTEXT

	MOVE.B	SCROLL_DIR_0,SCROLL_DIRECTION
	MOVE.L	BGPLANE0,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL1,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_0,SCROLL_DIRECTION
	MOVE.L	BGPLANE3,SCROLL_PLANE
	MOVE.B	#5,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.W	AUDIOCHLEVEL0,BPL1MOD	; GLITCH BY MESSING WITH BPLxMOD
	ADDQ.W	#2,BPL1MOD		; TO END IN INITIAL VALUE

	MOVE.W	#2,BPL2MOD
	MOVE.W	P61_1F,D2			; 1Fx
	CMPI.W	#2,D2			; 1F2
	BNE.S	.dontGlitch

	MOVE.B	SCROLL_DIR_0,D3		; STROBE DIRECTION
	NOT	D3			; STROBE DIRECTION
	MOVE.B	D3,SCROLL_DIR_0		; STROBE DIRECTION

	;MOVE.W	BPLxMOD_INDEX,D7
	;LEA	BPLxMOD_TABLE,A3
	;MOVE.W	(A3,D7.W),BPL1MOD		; GLITCH BY MESSING WITH BPLxMOD

	;ADD.W	#2,D7			; INCREMENTO INDICE TAB
	;AND.W	#15,D7			; AND TIRA FUORI SEMPRE FINO A X E POI WRAPPA
	;MOVE.W	D7,BPLxMOD_INDEX
	.dontGlitch:
	RTS

__BLOCK_7:
	; 17 9: KAssa dritta
	BSR.W	__POPULATETXTBUFFER
	BSR.W	__SHIFTTEXT

	MOVE.B	#1,SCROLL_DIRECTION
	MOVE.L	BGPLANE1,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL1,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_0,SCROLL_DIRECTION
	MOVE.L	BGPLANE3,SCROLL_PLANE	; INVERT
	MOVE.B	AUDIOCHLEVEL0NRM,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.W	AUDIOCHLEVEL0,BPL1MOD	; GLITCH BY MESSING WITH BPLxMOD
	ADDQ.W	#2,BPL1MOD		; TO END IN INITIAL VALUE

	MOVE.W	#2,BPL2MOD		; RESET
	MOVE.W	P61_1F,D2			; 1Fx
	CMPI.W	#2,D2			; 1F2
	BNE.S	.dontGlitch

	MOVE.W	BPLxMOD_INDEX,D7
	LEA	BPLxMOD_TABLE,A3
	MOVE.W	(A3,D7.W),BPL2MOD		; GLITCH BY MESSING WITH BPLxMOD
	;MOVE.W	P61_visuctr0,BPL2MOD	; OK I'M CRAZY :D

	ADD.W	#2,D7			; INCREMENTO INDICE TAB
	AND.W	#15,D7			; AND TIRA FUORI SEMPRE FINO A X E POI WRAPPA
	MOVE.W	D7,BPLxMOD_INDEX
	.dontGlitch:
	RTS

__BLOCK_VOX:
	; 17 9: KAssa dritta
	BSR.W	__POPULATETXTBUFFER
	BSR.W	__SHIFTTEXT

	MOVE.B	#0,SCROLL_DIRECTION
	MOVE.L	BGPLANE0,SCROLL_PLANE
	MOVE.B	#1,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	#1,SCROLL_DIRECTION
	MOVE.L	BGPLANE1,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL1,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_0,SCROLL_DIRECTION
	MOVE.L	BGPLANE3,SCROLL_PLANE	; INVERT
	MOVE.B	AUDIOCHLEVEL0NRM,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.W	P61_rowpos,BPL1MOD		; GLITCH BY MESSING WITH BPLxMOD
	ADDQ.W	#2,BPL1MOD		; TO END IN INITIAL VALUE

	MOVE.W	#2,BPL2MOD		; RESET
	MOVE.W	P61_1F,D2			; 1Fx
	CMPI.W	#2,D2			; 1F2
	BNE.S	.dontGlitch

	MOVE.W	BPLxMOD_INDEX,D7
	LEA	BPLxMOD_TABLE,A3
	;MOVE.W	(A3,D7.W),BPL2MOD		; GLITCH BY MESSING WITH BPLxMOD
	MOVE.W	P61_visuctr0,BPL2MOD	; OK I'M CRAZY :D

	ADD.W	#2,D7			; INCREMENTO INDICE TAB
	AND.W	#15,D7			; AND TIRA FUORI SEMPRE FINO A X E POI WRAPPA
	MOVE.W	D7,BPLxMOD_INDEX
	.dontGlitch:
	RTS

__BLOCK_8:
	; 21 7: KASSA dritta gif2
	BSR.W	__POPULATETXTBUFFER
	BSR.W	__SHIFTTEXT
	
	; BASS
	MOVE.B	#0,SCROLL_DIRECTION
	MOVE.L	BGPLANE1,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL2,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_3,SCROLL_DIRECTION
	MOVE.L	BGPLANE3,SCROLL_PLANE	; INVERT
	MOVE.B	AUDIOCHLEVEL3,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_0,SCROLL_DIRECTION
	MOVE.L	BGPLANE2,SCROLL_PLANE	; INVERT
	MOVE.B	AUDIOCHLEVEL0NRM,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.W	#2,BPL2MOD		; RESET

	MOVE.W	AUDIOCHLEVEL0,BPL1MOD	; GLITCH BY MESSING WITH BPLxMOD
	ADDQ.W	#2,BPL1MOD		; TO END IN INITIAL VALUE

	RTS

__BLOCK_9:
	; 26 11: Argh+ PArte di kick
	BSR.W	__POPULATETXTBUFFER
	BSR.W	__SHIFTTEXT
	
	; BASS
	MOVE.B	#1,SCROLL_DIRECTION
	MOVE.L	BGPLANE0,SCROLL_PLANE
	MOVE.B	#2,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_0,SCROLL_DIRECTION
	MOVE.L	BGPLANE3,SCROLL_PLANE	; INVERT
	MOVE.B	AUDIOCHLEVEL0NRM,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_1,SCROLL_DIRECTION
	MOVE.L	BGPLANE1,SCROLL_PLANE	; INVERT
	MOVE.B	AUDIOCHLEVEL1,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.W	AUDIOCHLEVEL0,BPL2MOD	; GLITCH BY MESSING WITH BPLxMOD
	ADDQ.W	#2,BPL2MOD		; TO END IN INITIAL VALUE

	MOVE.W	#2,BPL1MOD
	MOVE.W	P61_1F,D2			; 1Fx
	CMPI.W	#2,D2			; 1F2
	BNE.S	.dontGlitch

	MOVE.B	SCROLL_DIR_0,D3		; STROBE DIRECTION
	NOT	D3			; STROBE DIRECTION
	MOVE.B	D3,SCROLL_DIR_0		; STROBE DIRECTION

	MOVE.W	BPLxMOD_INDEX,D7
	LEA	BPLxMOD_TABLE,A3
	MOVE.W	(A3,D7.W),BPL1MOD		; GLITCH BY MESSING WITH BPLxMOD

	ADD.W	#2,D7			; INCREMENTO INDICE TAB
	AND.W	#15,D7			; AND TIRA FUORI SEMPRE FINO A X E POI WRAPPA
	MOVE.W	D7,BPLxMOD_INDEX
	.dontGlitch:

	RTS

__BLOCK_A:
	; 28 11: Argh+ PArte di kick
	MOVE.W	#2,BPL1MOD		; RESET
	MOVE.W	#2,BPL2MOD		; RESET

	BSR.W	__POPULATETXTBUFFER
	BSR.W	__SHIFTTEXT
	
	; BASS
	MOVE.B	#0,SCROLL_DIRECTION
	MOVE.L	BGPLANE1,SCROLL_PLANE
	MOVE.B	#3,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_0,SCROLL_DIRECTION
	MOVE.L	BGPLANE3,SCROLL_PLANE	; INVERT
	MOVE.B	AUDIOCHLEVEL0NRM,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_1,SCROLL_DIRECTION
	MOVE.L	BGPLANE1,SCROLL_PLANE	; INVERT
	MOVE.B	AUDIOCHLEVEL0NRM,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.W	AUDIOCHLEVEL0,BPL1MOD	; GLITCH BY MESSING WITH BPLxMOD
	ADDQ.W	#2,BPL1MOD		; TO END IN INITIAL VALUE

	RTS

__BLOCK_B:
	; 2: Robot + Kassa (pausa)
	MOVE.W	#2,BPL1MOD		; RESET
	MOVE.W	#2,BPL2MOD		; RESET

	BSR.W	__POPULATETXTBUFFER
	BSR.W	__SHIFTTEXT
	
	; BASS
	MOVE.B	#0,SCROLL_DIRECTION
	MOVE.L	BGPLANE1,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL2,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_3,SCROLL_DIRECTION
	MOVE.L	BGPLANE2,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL3,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_0,SCROLL_DIRECTION
	MOVE.L	BGPLANE3,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL0NRM,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_0,D3		; STROBE DIRECTION
	NOT	D3			; STROBE DIRECTION
	MOVE.B	D3,SCROLL_DIR_0		; STROBE DIRECTION

	RTS

__BLOCK_C:
	; 28 11: Argh+ PArte di kick
	BSR.W	__POPULATETXTBUFFER
	BSR.W	__SHIFTTEXT
	
	; BASS
	MOVE.B	SCROLL_DIR_0,SCROLL_DIRECTION
	MOVE.L	BGPLANE0,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL2,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_0,SCROLL_DIRECTION
	MOVE.L	BGPLANE2,SCROLL_PLANE	; INVERT
	MOVE.B	AUDIOCHLEVEL0NRM,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_3,SCROLL_DIRECTION
	MOVE.L	BGPLANE3,SCROLL_PLANE	; INVERT
	MOVE.B	AUDIOCHLEVEL3,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.W	P61_visuctr1,D2
	;NOT	D2
	MOVE.W	P61_row,D4		; VARIATION
	ADD.W	AUDIOCHLEVEL1,D3		; SUSTAIN BY ADDING CHANS
	LSL.W	D3,D2
	AND.W	D4,D2
	;ROR.W	D4,D2			; VARIATION
	ADDQ.W	#2,D3			; TO END IN INITIAL VALUE
	ADDQ.W	#2,D2			; TO END IN INITIAL VALUE
	MOVE.W	AUDIOCHLEVEL1,BPL1MOD	; GLITCH BY MESSING WITH BPLxMOD
					; SOME EXTRA MESS
	MOVE.W	D2,BPL2MOD		; GLITCH BY MESSING WITH BPLxMOD

	RTS

__BLOCK_D:
	; 28 11: Argh+ PArte di kick
	; FIRST KICK GLITCH
	BSR.W	__POPULATETXTBUFFER
	BSR.W	__SHIFTTEXT
	
	; BASS
	MOVE.B	SCROLL_DIR_0,SCROLL_DIRECTION
	MOVE.L	BGPLANE1,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL2,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_0,SCROLL_DIRECTION
	MOVE.L	BGPLANE2,SCROLL_PLANE	; INVERT
	MOVE.B	AUDIOCHLEVEL0NRM,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_3,SCROLL_DIRECTION
	MOVE.L	BGPLANE3,SCROLL_PLANE	; INVERT
	MOVE.B	AUDIOCHLEVEL3,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.W	#2,BPL2MOD		; RESET
	; DO ONCE
	MOVE.W	P61_rowpos,D2		; STARTS AT 63
	;CLR.W	$100			; DEBUG | w 0 100 2
	CMPI.W	#57,D2			; GLITCH FIRST x ROWS
	BLO.S	.dontGlitch

	MOVE.W	AUDIOCHLEVEL1,D3
	MOVE.W	P61_pos,D4		; VARIATION
	ROR.W	D4,D3			; VARIATION
	ADD.W	AUDIOCHLEVEL2,D3		; SUSTAIN BY ADDING CHANS
	ADDQ.W	#2,D3			; TO END IN INITIAL VALUE
	MOVE.W	D3,BPL1MOD		; GLITCH BY MESSING WITH BPLxMOD
	NOT	D2			; SOME EXTRA MESS
	MOVE.W	D2,BPL2MOD		; GLITCH BY MESSING WITH BPLxMOD

	.dontGlitch:	

	RTS

__BLOCK_E:
	; 2: Robot + Kassa (pausa)
	MOVE.W	#2,BPL1MOD		; RESET
	MOVE.W	#2,BPL2MOD		; RESET

	BSR.W	__POPULATETXTBUFFER
	BSR.W	__SHIFTTEXT
	
	; BASS
	MOVE.B	SCROLL_DIR_0,SCROLL_DIRECTION
	MOVE.L	BGPLANE1,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL3,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_3,SCROLL_DIRECTION
	MOVE.L	BGPLANE3,SCROLL_PLANE
	MOVE.B	AUDIOCHLEVEL3,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	#0,SCROLL_DIRECTION
	MOVE.L	BGPLANE2,SCROLL_PLANE
	MOVE.B	#5,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!

	MOVE.B	SCROLL_DIR_0,D3		; STROBE DIRECTION
	NOT	D3			; STROBE DIRECTION
	MOVE.B	D3,SCROLL_DIR_0		; STROBE DIRECTION

	RTS

__BLOCK_END:
	; 0: EMPTY_BEGIN
	MOVE.W	P61_LAST_POS,D5
	CMP.W	#62,D5
	BNE.S	.dontStopMusic
	MOVE.W	#2,BPL1MOD		; RESET
	MOVE.W	#2,BPL2MOD		; RESET
	JSR	__CREATESCROLLSPACE
	MOVE.W	#%1000010000000000,DMACON	; BIT10=BLIT NASTY ENABLED

	MOVEM.L D0-A6,-(SP)
	JSR P61_End
	MOVEM.L (SP)+,D0-A6
	.dontStopMusic:

	MOVE.B	#1,SCROLL_DIRECTION
	MOVE.L	BGPLANE0,SCROLL_PLANE
	MOVE.B	#1,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!
	MOVE.B	#1,SCROLL_DIRECTION
	MOVE.L	BGPLANE1,SCROLL_PLANE
	MOVE.B	#2,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!
	MOVE.B	#1,SCROLL_DIRECTION
	MOVE.L	BGPLANE2,SCROLL_PLANE
	MOVE.B	#3,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!
	MOVE.B	#1,SCROLL_DIRECTION
	MOVE.L	BGPLANE3,SCROLL_PLANE
	MOVE.B	#4,SCROLL_SHIFT
	BSR.W	__SCROLL_BG_PLANE		; SHIFT !!
	
	MOVE.W	#61,P61_LAST_POS		; REPEAT ?
	MOVE.W	#23,P61_DUMMY_POS		; ANY VALUE

	RTS

;********** Fastmem Data **********
DrawBuffer:	DC.L SCREEN2	; pointers to buffers
ViewBuffer:	DC.L SCREEN1	; to be swapped

TIMELINE:		DC.L __BLOCK_0
		DC.L __BLOCK_1,__BLOCK_1		; 1 1: Solo Robot
		DC.L __BLOCK_2,__BLOCK_2		; 3 3: Robot + KassaImberlada
		DC.L __BLOCK_2,__BLOCK_3		; 5 2: Robot + Kassa (pausa)
		DC.L __BLOCK_3,__BLOCK_3		; 7 5: Robot + Ritmo + KassaIPERImb
		DC.L __BLOCK_4,__BLOCK_4		; 9 6: KASSA dritta + h?
		DC.L __BLOCK_5,__BLOCK_5		; 11 7: KASSA dritta gif2
		DC.L __BLOCK_5,__BLOCK_4		; 13 7: KASSA dritta gif2
		DC.L __BLOCK_6,__BLOCK_6		; 15 8: KAssa pause
		DC.L __BLOCK_7,__BLOCK_7		; 17 9: KAssa dritta
		DC.L __BLOCK_6,__BLOCK_7		; 19 8: KAssa pause
		DC.L __BLOCK_8,__BLOCK_8		; 21 7: KASSA dritta gif2
		DC.L __BLOCK_8,__BLOCK_8		; 24 7: KASSA dritta gif2
		DC.L __BLOCK_VOX			; 25 10: ARGH!
		DC.L __BLOCK_9,__BLOCK_9,__BLOCK_9	; 26 11: Argh+ PArte di kick
		DC.L __BLOCK_A,__BLOCK_A,__BLOCK_A	; 31 12: ARGH + kick
		DC.L __BLOCK_VOX			; 32 10: ARGH!
		DC.L __BLOCK_5,__BLOCK_5		; 33 13: Argh +kick +GIF2
		DC.L __BLOCK_B,__BLOCK_B		; 36 14: Argh +rull +gif2
		DC.L __BLOCK_5,__BLOCK_8		; 37 15: Argh + Casino
		DC.L __BLOCK_D,__BLOCK_D		; 39 16: KASSADRITTA!
		DC.L __BLOCK_D			; 41 13: Argh +kick +GIF2
		DC.L __BLOCK_8,__BLOCK_8,__BLOCK_8	; 42 17: KASSADRITTA2!
		DC.L __BLOCK_5,__BLOCK_5		; 45 12: ARGH + kick
		DC.L __BLOCK_6,__BLOCK_6		; 47 12: ARGH + kick
		DC.L __BLOCK_7,__BLOCK_7		; 50 11: Argh+ PArte di kick
		DC.L __BLOCK_C,__BLOCK_C		; 52 17: KASSADRITTA2!
		DC.L __BLOCK_D,__BLOCK_D		; 54 7: KASSA dritta gif2
		DC.L __BLOCK_B,__BLOCK_B		; 56 5: Robot + Ritmo + KassaIPERImb
		DC.L __BLOCK_E,__BLOCK_E		; 58 4: Robot + KassaImberlada Kambio
		DC.L __BLOCK_E,__BLOCK_E		; 60 1: Solo Robot
		DC.L __BLOCK_VOX			; 61 18: FINE!
		DC.L __BLOCK_END

AUDIOCHLEVEL0NRM:	DC.W 0
AUDIOCHLEVEL0:	DC.W 0
AUDIOCHLEVEL1:	DC.W 0
AUDIOCHLEVEL2:	DC.W 0
AUDIOCHLEVEL3:	DC.W 0
P61_LAST_POS:	DC.W MODSTART_POS
P61_DUMMY_POS:	DC.W 0
P61_FRAMECOUNT:	DC.W 0
KONEYBG:		DC.L BG1		; INIT BG
BGPLANE0:		DC.L BG1
BGPLANE1:		DC.L BG1+bpl*h
BGPLANE2:		DC.L BG1+bpl*h*2
BGPLANE3:		DC.L BG1+bpl*h*3
SPR_0_POS:	DC.B $7C		; K
SPR_1_POS:	DC.B $84		; O
SPR_2_POS:	DC.B $8C		; N
SPR_3_POS:	DC.B $94		; E
SPR_4_POS:	DC.B $9C		; Y
SCROLL_SHIFT:	DC.B 0
SCROLL_INDEX:	DC.W 0
SCROLL_PLANE:	DC.L 0
SCROLL_DIRECTION:	DC.B 1		; 0=LEFT 1=RIGHT
SCROLL_DIR_0:	DC.B 1
SCROLL_DIR_1:	DC.B 1
SCROLL_DIR_2:	DC.B 1
SCROLL_DIR_3:	DC.B 1
		EVEN
TEXTINDEX:	DC.W 0
FRAMESINDEX:	DC.W 4
GLITCHDATA:	DC.L DITHER
GLITCHSRC:	DC.L 0

	;*******************************************************************************
	SECTION	ChipData,DATA_C	;declared data that must be in chipmem
	;*******************************************************************************

BG1:		DS.W h*bpls	; DEFINE AN EMPTY AREA FOR THE MARGIN WORD
BG1_DATA:		DS.B h*bwid	;INCBIN "dithermirrorbg.raw"

BPLxMOD_INDEX:	DC.W 0
BPLxMOD_TABLE:	DC.W 1,3,4,1,12,5,4,7,1,4,3,1,0,2,6,10,7,3,2,1,5,4,1,8,7,6,5,1,8,0,1,8,0,3,1,7,17,4,30,3,6,1

SPRITES:		INCLUDE "sprite_KONEY.s"

DITHER:		INCBIN "BG_JPG_DITHER_3.raw"
MODULE:		INCBIN "CrippledCyborgV7.P61"	; code $1009307

FONT:		DC.L 0,0		; SPACE CHAR
		INCBIN "digital_font.raw",0
		EVEN

TEXT:	DC.B "!!WARNING!! - EPILEPSY DANGER AHEAD!!   SERIOUSLY... :)    "
	DC.B "WELCOME TO:   ### CRIPPLED CYBORG ###   KONEY'S SECOND AMIGA HARDCORE RELEASE!   "
	DC.B "AS PROMISED MORE GLITCHES AND BLITSTORTIONS ARE BEING DELIVERED TO YOUR AMIGA. "
	DC.B "IT SHOULDN'T BE NECESSARY TO REMIND THAT THIS PIECE OF CRAPPY CODE IS BEST VIEWED "
	DC.B "ON A REAL AMIGA WITH A TRUE CRT DISPLAY AND BIG LOUDSPEAKERZ!! NO EMULATION FUCKERS, "
	DC.B "AN EMULATOR IS LIKE AN INFLATABLE SEXDOLL: YOU CAN HAVE FUN WITH IT BUT YOU CAN'T "
	DC.B "SAY YOU HAVE A GIRLFRIEND! SO FIRE UP YOUR REAL AMIGA IF YOU HAVEN'T ALREADY!  "
	DC.B "IT'S NOW TIME FOR THE REAL SCROLLTEXT: I PUBLISHED THIS TRACK ON MY OWN LABEL BACK "
	DC.B "IN 2000 WITH CAT# KNY-04 'PEOPLEGRINDER' BUT ACCORDINGLY TO THE NOTE INSIDE .MED FILE "
	DC.B "IT WAS COMPOSED BACK IN 1997. ODDLY THIS IS NOT WHAT I REMEMBER BUT WE WRITE NOTES ON "
	DC.B "STUFF TO REMEMBER THINGS SO I ASSUME IT WAS REALLY 1997! TWENTY FUCKING THREE "
	DC.B "YEARS AGO! ALL MY AMIGA MUSIC WAS MADE WITH OCTAMED SOUNDSTUDIO SO TO PUT ANY SONG "
	DC.B "INTO ASSEMBLY CODE A CONVERSION TO .MOD IS REQUIRED. THIS IS USUALLY AN EASY TASK "
	DC.B "BUT BACK IN THE DAYS I THOUGHT IT WAS A GOOD IDEA TO LOAD ANY KIND OF FILE AS "
	DC.B "SAMPLES INTO OCTAMED... IT TURNED OUT THEY DON'T PLAY AS GOOD IN P61, SOME OF THEM MAKE "
	DC.B "GLITCHES... I KNOW IT'S FUNNY TO SAY, GIVEN THE VISUALS AND THE REST OF THE SOUNDZ, "
	DC.B "BUT I WANTED THE INTRO TO SOUND AS CLOSE AS POSSIBLE TO THE ORIGINAL "
	DC.B "RECORDING ON VINYL SO I HAD SOME OF THIS SAMPLES RE-SAMPLED FROM-TO-AMIGA "
	DC.B "(THANKS KCMA!). ABOUT LOADING RANDOM FILES AS SAMPLES... TO BE HONEST I STILL THINK IT WAS "
	DC.B "A GOOD IDEA!! THE SAME WAY THESE DAYS I THINK IT IS A GOOD IDEA TO FEED SEMI-RANDOM VALUES "
	DC.B "INTO BPLXMOD REGISTERS, JUST FOR SOME EXTRA GLITCH FUN! AND IT WORKS, GURULESSLY!!   "
	DC.B "SO THERE'S A LOT OF BLITTING ACTION HERE, IT TOOK ME A WHILE BUT I MANAGED TO DO WHAT I HAD IN "
	DC.B "MIND AND FOR THIS I MUST THANK ALL THE GUYS FROM EAB DISCUSSION: 'BLITTER SHIFT EATING 1PX AWAY' "
	DC.B "WHICH RAN FOR ALMOST ONE YEAR! THANKS FOR YOUR PATIENCE! ANYWAY MY IDEA WAS TO "
	DC.B "SCROLL 4 SEPARATE BITPLANES (ONE PER AUDIO CHANNEL) BUT IT TURNS OUT THAT BLITTING "
	DC.B "SO MUCH DATA IN A SINGLE FRAME REQUIRES NASTY BLITTER BIT SET BUT I LEARNT THE HARD "
	DC.B "WAY WHAT PHOTON/SCOOPEX ONCE SAID: 'THE BLITTER IS VERY NASTY INDEED. BUT PAULA IS NASTIER!'...   "
	DC.B "SO ONLY 3 BITPLANE SCROLLED AT A TIME, WELL ANYWAY THERE IS ENOUGH MESS ON SCREEN ALREADY I GUESS :)  "
	DC.B "I'LL POST THIS INTRO IN POUET.NET, IF YOU ARE ONE OF THE NICE GUYS WHO UPVOTED "
	DC.B "MY FIRST INTRO 'FATAL DEFRAG' I WANT YOU TO KNOW THAT I REALLY APPRECIATE YOUR SUPPORT! "
	DC.B "SPEAKING OF POUET.NET I'VE JUST NOTICED A GUY CALLED 'KIMI KANDLER' HAS ADDED 'FATAL DEFRAG' "
	DC.B "TO A LIST OF PRODUCTIONS PRESSED ON VINYL, NICE ONE! HERE YOU HAVE MORE FOR YOUR LIST! "
	DC.B "FOR THE FUTURE I AM ALREADY THINKING AT THE NEXT INTRO WHICH WILL FEATURE ONE OF MY MOST "
	DC.B "ARCHETYPAL TRACKS: 'KETAMUSKOLAR' RELEASED BACK IN 2002 ON SONIC POLLUTION #02.    "
	DC.B "ONE LAST WORD BEFORE ABANDONING THE SCREEN TO THE GLITCHES... I AM ABANDONING THE "
	DC.B "SCREEN TO THE GLITCHES :) - MAKE SURE TO VISIT WWW.KONEY.ORG FOR MORE INDUSTRIAL "
	DC.B "AMIGACORE!!            .EOF                                                              "
	EVEN
_TEXT:

COPPER:
	DC.W $1FC,0	; Slow fetch mode, remove if AGA demo.
	DC.W $8E,$2C81	; 238h display window top, left | DIWSTRT - 11.393
	DC.W $90,$2CC1	; and bottom, right.	| DIWSTOP - 11.457
	DC.W $92,$38	; Standard bitplane dma fetch start
	DC.W $94,$D0	; and stop for standard screen.

	DC.W $106,$0C00	; (AGA compat. if any Dual Playf. mode)
	
	DC.W $108	; BPL1MOD	 Bitplane modulo (odd planes)
	BPL1MOD:
	DC.W 2		; bwid-bpl	;modulos
	
	DC.W $10A	; BPL2MOD Bitplane modulo (even planes)
	BPL2MOD:
	DC.W 2		; bwid-bpl	;RISULTATO = 80 ?
	
	DC.W $102,0	; SCROLL REGISTER (AND PLAYFIELD PRI)

	Palette:
	DC.W $0180,$0000,$0182,$0334,$0184,$0445,$0186,$0556
	DC.W $0188,$0667,$018A,$0333,$018C,$0667,$018E,$0777
	DC.W $0190,$0888,$0192,$0888,$0194,$0999,$0196,$0AAA
	DC.W $0198,$0BBB,$019A,$0CCC,$019C,$0DDD,$019E,$0FFF

	BplPtrs:
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

	SpritePointers:
	DC.W $120,0,$122,0	; 0
	DC.W $124,0,$126,0	; 1
	DC.W $128,0,$12A,0	; 2
	DC.W $12C,0,$12E,0	; 3
	DC.W $130,0,$132,0	; 4
	DC.W $134,0,$136,0	; 5
	DC.W $138,0,$13A,0	; 6
	DC.W $13C,0,$13E,0	; 7

	DC.W $1A6
	LOGOCOL1:
	DC.W $000	; COLOR0-1
	DC.W $1AE
	LOGOCOL2:
	DC.W $000	; COLOR2-3
	DC.W $1B6
	LOGOCOL3:
	DC.W $000	; COLOR4-5

COPPERWAITS:
	; HW DISPLACEMENT
	;DC.W $002D,$FFFE
	;DC.W $F102,$A68E
	;DC.W $FE07,$FFFE
	;DC.W $F102,$1F83

	;DC.W $FE07,$FFFE
	;DC.W $0180,$0FFF
	;DC.W $FF07,$FFFE
	;DC.W $0180,$0011	; SCROLLAREA BG COLOR
	;DC.W $0182,$0AAA	; SCROLLING TEXT WHITE ON

	DC.W $FFDF,$FFFE	; allow VPOS>$ff

	DC.W $2201,$FF00	; horizontal position masked off
	DC.W $0108,$0002	; BPL1MOD - Should fix the scroll
	DC.W $010A,$0002	; BPL2MOD - when glitch but dont work :)
	DC.W $0188,$0FFF	; BG COLOR
	
	DC.W $2301,$FF00	; horizontal position masked off
	DC.W $0188,$0DDD	; BG COLOR
	DC.W $0198,$0000	; TXT COLOR
	
	;DC.W $2401,$FF00	; horizontal position masked off
	;DC.W $0198,$0222	; TXT COLOR
	
	DC.W $2501,$FF00	; horizontal position masked off
	DC.W $0188,$0AAA	; BG COLOR
	;DC.W $0198,$0444	; TXT COLOR

	;DC.W $2601,$FF00	; horizontal position masked off
	;DC.W $0198,$0333	; TXT COLOR

	DC.W $2701,$FF00	; horizontal position masked off
	DC.W $0188,$0888	; BG COLOR
	;DC.W $0198,$0666	; TXT COLOR

	;DC.W $2801,$FF00	; horizontal position masked off
	;DC.W $0198,$0999	; TXT COLOR

	DC.W $2901,$FF00	; horizontal position masked off
	DC.W $0188,$0555	; BG COLOR
	;DC.W $0198,$0AAA	; TXT COLOR

	DC.W $2A01,$FF00	; horizontal position masked off
	DC.W $0188,$0333	; BG COLOR
	;DC.W $0198,$0EEE	; TXT COLOR

	DC.W $2B01,$FF00	; RESTORE BLACK
	DC.W $0188,$0000

	DC.W $FFFF,$FFFE	;magic value to end copperlist

_COPPER:

;*******************************************************************************
	SECTION ChipBuffers,BSS_C	;BSS doesn't count toward exe size
;*******************************************************************************

SCREEN1:		DS.B h*bwid	; Define storage for buffer 1
SCREEN2:		DS.B h*bwid	; two buffers

END