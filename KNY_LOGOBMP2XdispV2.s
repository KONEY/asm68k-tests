;** VERSION WITH DISPLACED GFX VALUES IN TABLE **

;*** MiniStartup by Photon ***
	INCDIR	"NAS:AMIGA/CODE/KONEY/"
	INCLUDE	"PhotonsMiniWrapper1.04!.S"
;********** Constants **********
;INCLUDE "Blitter-Register-List.S"	;use if you like ;)

w=320				;screen width, height, depth
h=256
bpls=1				;handy values:
bpl=w/16*2			;byte-width of 1 bitplane line
bwid=bpls*bpl			;byte-width of 1 pixel line (all bpls)

;********** Macros **********

WAITBLIT:macro
	tst.w	(a6)		;for compatibility with A1000
.wb\@:	
	btst	#6,2(a6)
	bne.s	.wb\@
	endm

;********** Demo **********	;Demo-specific non-startup code below.

Demo:				;a4=VBR, a6=Custom Registers Base addr
	;*--- init ---*
	move.l	#VBint,$6c(a4)
	move.w	#$c020,$9a(a6)
	move.w	#$87c0,$96(a6)
	;*--- clear screens ---*
	lea	Screen,a1
	bsr.w	ClearScreen
	lea	Screen2,a1
	bsr.w	ClearScreen
	bsr	WaitBlitter
	;*--- start copper ---*
	lea	Screen,a0
	moveq	#bpl,d0
	lea	BplPtrs+2,a1
	moveq	#bpls-1,d1
	bsr.w	PokePtrs

	move.l	#Copper,$80(a6)

	LEA	DISPLACETABLE,A3
	MOVEQ	#0,D3		;INDICE PER TABELLA

;********************  main loop  ********************
MainLoop:
	lea	Screen,a1	;Then, the screen
	bsr.s	ClearScreen	;clear, Yoda pls.
	bsr.s	WaitBlitter	;Wait out blit: we plot to same area

	moveq	#18,d0		;Read 18
	;lea	Points(PC),a0	;points from the source data,
	lea	Screen,a1	;and to the destination screen
	bsr.w	PRINT2X		;Stampa KONEY

	move.w	#$12c,d0	;No buffering, so wait until raster
	bsr.w	WaitRaster	;is below the Display Window.
	;move.w	#$888,$182(a6)	;show rastertime left down to $12c

	; do stuff here :)

	;*--- main loop end ---*

	btst	#6,$bfe001	;Left mouse button not pressed?
	bne.w	MainLoop		;then loop
	;*--- exit ---*
	rts

;********** Demo Routines **********

PokePtrs:				;Generic, poke ptrs into copper list
.bpll:	
	move.l	a0,d2
	swap	d2
	move.w	d2,(a1)		;high word of address
	move.w	a0,4(a1)		;low word of address
	addq.w	#8,a1		;skip two copper instructions
	add.l	d0,a0		;next ptr
	dbf	d1,.bpll
	rts

ClearScreen:				;a1=screen destination address to clear
	bsr	WaitBlitter
	clr.w	$66(a6)			;destination modulo
	move.l	#$01000000,$40(a6)		;set operation type in BLTCON0/1
	move.l	a1,$54(a6)		;destination address
	move.w	#h*bpls*64+bpl/2,$58(a6)	;blitter operation size
	rts

VBint:					;Blank template VERTB interrupt
	movem.l	d0/a6,-(sp)		;Save used registers
	lea	$dff000,a6
	btst	#5,$1f(a6)		;check if it's our vertb int.
	beq.s	.notvb
	;*--- do stuff here ---*
	moveq	#$20,d0			;poll irq bit
	move.w	d0,$9c(a6)
.notvb:	
	movem.l	(sp)+,d0/a6		;restore
	rte

PRINT2X:				; Routine che stampa
	MOVEM.L	D1/D4/D5/A2,-(SP)	; SAVE TO STACK
	MOVE.L	#KONEY2X,A2
	MOVEQ	#0,D1		; RESET D6
	MOVE.B	#10-1,D1			
	ADD.W	#4600,A1		; POSITIONING

.LOOP:				; LOOP KE CICLA LA BITMAP
	ADD.W	#13,A1		; POSITIONING

	MOVE.L	(A2)+,D4
	MOVE.L	(A3,D3.W),D5
	ASL.L	D5,D4		; GLITCH
	MOVE.L	D4,(A1)		; QUESTA ISTRUZIONE FA ESPLODERE TUTTO
	ADD.W	#2,D3		; INCREMENTO INDICE TAB
	AND.W	#256-1,D3		; AND TIRA FUORI SEMPRE FINO A X E POI WRAPPA

	ADD.W	#4,A1		; POSITIONING

	MOVE.L	(A2)+,D4
	ROR.L	D5,D4		; GLITCH
	MOVE.L	D4,(A1)		; QUESTA ISTRUZIONE FA ESPLODERE TUTTO

	ADD.W	#23,A1		; POSITIONING
	DBRA	D1,.LOOP
	MOVEM.L	(SP)+,D1/D4/D5/A2	; FETCH FROM STACK
	RTS

STROBOSTABLE:
	DC.W $FFF,$000	; valori letti in sequenza e wrappati

DISPLACETABLE:
	DC.W 0,3,0,2,0,0,0,0,0,2,0,3,0,9,8,1
	DC.W 0,0,0,3,0,0,0,0,3,0,0,0,0,0,0,0
	DC.W 1,0,6,0,0,0,0,7,6,0,0,0,9,8,1
	DC.W 0,3,0,1,0,6,0,0,0,0,0,0,0,0,0,0
	DC.W 0,0,0,5,0,0,0,0,0,0,3,0,0,0,1
	DC.W 2,1,0,4,0,0,0,3,0,0,0,1,7,1,0,0
	DC.W 0,3,0,0,3,0,0,0,0,1,0,0,1,1,2,0
	DC.W 2,3,0,3,0,0,0,3,2,0,2,0,1,0,0,2

;*******************************************************************************
	SECTION	ChipData,DATA_C		;declared data that must be in chipmem
;*******************************************************************************

KONEY2X:
	INCBIN	"koney10x64.raw"	

Copper:
	DC.W $1FC,0	;SLOW FETCH MODE, REMOVE IF AGA DEMO.
	DC.W $8E,$2C81	;238H DISPLAY WINDOW TOP, LEFT
	DC.W $90,$2CC1	;AND BOTTOM, RIGHT.
	DC.W $92,$38	;STANDARD BITPLANE DMA FETCH START
	DC.W $94,$D0	;AND STOP FOR STANDARD SCREEN.

	DC.W $106,$0C00	;(AGA COMPAT. IF ANY DUAL PLAYF. MODE)
	DC.W $108,0	; Bpl1Mod
	DC.W $10A,0	; Bpl2Mod

	;dc.w $102,0	;Scroll register (and playfield pri)

Palette:			;Some kind of palette (3 bpls=8 colors)
	DC.W $180,$889	;BLACK
	DC.W $182,$000	;BLUE
	DC.W $184,$FFF	;GREEN
	DC.W $186,$555	;CYAN
	DC.W $188,$777	;RED
	DC.W $18A,$AAA	;MAGENTA
	DC.W $18C,$CCC	;YELLOW
	DC.W $18E,$EEE	;WHITE

BplPtrs:
	dc.w $e0,0
	dc.w $e2,0
	dc.w $e4,0
	dc.w $e6,0
	dc.w $e8,0
	dc.w $ea,0
	dc.w $ec,0
	dc.w $ee,0
	dc.w $f0,0
	dc.w $f2,0
	dc.w $f4,0
	dc.w $f6,0		;full 6 ptrs, in case you increase bpls
	dc.w $100,bpls*$1000+$200	;enable bitplanes

	dc.w $ffdf,$fffe		;allow VPOS>$ff
	dc.w $ffff,$fffe		;magic value to end copperlist

CopperE:
;*******************************************************************************
	SECTION	ChipBuffers,BSS_C	;BSS doesn't count toward exe size
;*******************************************************************************

Screen:	ds.b h*bwid		;Define storage for buffer 1
Screen2:	ds.b h*bwid		;two buffers

	END
