;*** MiniStartup by Photon ***
	INCLUDE "PhotonsMiniWrapper1.04!.S"
;********** Constants **********

	;INCLUDE "Blitter-Register-List.S"	;use if you like ;)

w=320				;screen width, height, depth
h=256
bpls=1				;handy values:
bpl=w/16*2			;byte-width of 1 bitplane line
bwid	=bpls*bpl			;byte-width of 1 pixel line (all bpls)

;********** Macros **********

WAITBLIT:macro
	tst.w (a6)		;for compatibility with A1000
.wb\@:	
	btst #6,2(a6)
	bne.s .wb\@
	endm

;********** Demo **********	;Demo-specific non-startup code below.

Demo:				;a4=VBR, a6=Custom Registers Base addr
	*--- init ---*
	move.l	#VBint,$6c(a4)
	move.w	#$c020,$9a(a6)
	move.w	#$87c0,$96(a6)
	*--- clear screens ---*
	lea	Screen,a1
	bsr.w	ClearScreen
	lea	Screen2,a1
	bsr.w	ClearScreen
	bsr	WaitBlitter
	*--- start copper ---*
	lea	Screen,a0
	moveq	#bpl,d0
	lea	BplPtrs+2,a1
	moveq	#bpls-1,d1
	bsr.w	PokePtrs

	move.l	#Copper,$80(a6)

	bsr.s	__DBLBMP

;********************  main loop  ********************
MainLoop:
	lea	Screen,a1		;Then, the screen
	;bsr.s	ClearScreen	;clear, Yoda pls.
	bsr.s	WaitBlitter	;Wait out blit: we plot to same area

	moveq	#18,d0		;Read 18
	;lea	Points(PC),a0	;points from the source data,
	lea	Screen,a1		;and to the destination screen
	bsr.w	PRINT2X		; Stampa le linee di testo sullo schermo
	;bsr.w	PRINT		; Stampa le linee di testo sullo schermo
	;bsr.w	PRINT		; Stampa le linee di testo sullo schermo

	move.w	#$12c,d0		;No buffering, so wait until raster
	bsr.w	WaitRaster	;is below the Display Window.
	;move.w	#$888,$182(a6)	;show rastertime left down to $12c

	; do stuff here :)


	;bsr.w	PRINT		; Stampa le linee di testo sullo schermo
	;bsr.w	PRINT		; Stampa le linee di testo sullo schermo

	*--- main loop end ---*
	;move.w	#$888,$180(a6)	;show rastertime left down to $12c

	btst	#6,$bfe001	;Left mouse button not pressed?
	bne.w	MainLoop		;then loop
	*--- exit ---*
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

VBint:				;Blank template VERTB interrupt
	movem.l	d0/a6,-(sp)	;Save used registers
	lea	$dff000,a6
	btst	#5,$1f(a6)	;check if it's our vertb int.
	beq.s	.notvb
	*--- do stuff here ---*
	moveq	#$20,d0		;poll irq bit
	move.w	d0,$9c(a6)
	move.w	d0,$9c(a6)
.notvb:	
	movem.l	(sp)+,d0/a6	;restore
	rte

;********** Fastmem Data **********
;DrawBuffer:	dc.l Screen2	;pointers to buffers to be swapped
;ViewBuffer:	dc.l Screen

__DBLBMP:
	lea	Screen,a2
	LEA	KONEY,A1
	LEA	KONEY2x,A5
	ADD.W	#4,A5		; POSITIONING
	ADD.W	#4,A5		; POSITIONING
	CLR.L	D6
	MOVE.W	#$9,D6	; QUANTE BYTE?

	.DBLBMP:		; LOGICA PER RADDOPPIARE LA BITMAP
	CLR.L	D0
	MOVE.W	(A1)+,D0		
	;MOVE.W	#%1010101010101010,D0

	;****************
	CLR.L	D1
	CLR.L	D2
	MOVE.W	#$F,D7
	.LOOP:	
	BTST	D7,D0
	BEQ.S	.NEXT
	MOVE.W	D7,D2
	ADD.W	D2,D2
	BSET	D2,D1
	ADDQ.W	#1,D2
	BSET	D2,D1
	.NEXT:	
	DBRA	D7,.LOOP
	;*****************

	MOVE.L	D1,(A5)

	SUB.W	#4,A5		; POSITIONING
	SUB.W	#4,A5		; POSITIONING

	MOVE.L	D1,(A5)
	ADD.W	#4,A5		; POSITIONING
	ADD.W	#4,A5		; POSITIONING
	ADD.W	#4,A5		; POSITIONING
	ADD.W	#2,A5		; POSITIONING
	ADD.W	#2,A5		; POSITIONING
	ADD.W	#2,A5		; POSITIONING
	ADD.W	#2,A5		; POSITIONING

	BTST	#0,D6
	BEQ.S	.skip
	SUB.W	#4,A5		; POSITIONING
	SUB.W	#4,A5		; POSITIONING
	MOVE.W	D6,(A2)+
	MOVE.W	#$0FF0,(A2)+
	;BRA.S	.ciao
	.skip:

	DBRA	D6,.DBLBMP
	.ciao:
	RTS

PRINT2X:				;Routine che stampa
	MOVE.L	#KONEY2X,A5
	CLR	D6		; RESET D6
	MOVE.B	#9,D6			
	ADD.W	#4400,A1		; POSITIONING

	.LOOP:			; LOOP KE CICLA LA BITMAP
	ADD.W	#16,A1		; POSITIONING
	MOVE.L	(A5)+,(A1)	; QUESTA ISTRUZIONE FA ESPLODERE TUTTO
	ADD.W	#4,A1		; POSITIONING
	MOVE.L	(A5)+,(A1)	; QUESTA ISTRUZIONE FA ESPLODERE TUTTO
	ADD.W	#20,A1		; POSITIONING
	DBRA	D6,.LOOP
	RTS

;*******************************************************************************
	SECTION ChipData,DATA_C		;declared data that must be in chipmem
;*******************************************************************************

KONEY:
	;DC.L %10101010101010101010101010101010	; TEST
	DC.L %01000101111101111101111101101100
	DC.L %01001001000101000101000000111000
	DC.L %01110001100101100101111100010000
	DC.L %01101001100101100101100000011000
	DC.L %01100101111101100101111100011000

KONEY2X:	 ds.b 64*10/16*2
	;incbin	"koney10x64.raw"	
	;DC.L	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;la bitmap sopra raddoppiata

	ds.b 64*10/16*2

Copper:
	DC.W	$1FC,0		;SLOW FETCH MODE, REMOVE IF AGA DEMO.
	DC.W	$8E,$2C81		;238H DISPLAY WINDOW TOP, LEFT
	DC.W	$90,$2CC1		;AND BOTTOM, RIGHT.
	DC.W	$92,$38		;STANDARD BITPLANE DMA FETCH START
	DC.W	$94,$D0		;AND STOP FOR STANDARD SCREEN.

	DC.W	$106,$0C00	;(AGA COMPAT. IF ANY DUAL PLAYF. MODE)
	DC.W	$108,0		; Bpl1Mod
	DC.W	$10A,0		; Bpl2Mod

	;dc.w	$102,0		;Scroll register (and playfield pri)

Palette:					;Some kind of palette (3 bpls=8 colors)
	DC.W	$180,$111		;BLACK
	DC.W	$182,$CCC		;BLUE
	DC.W	$184,$222		;GREEN
	DC.W	$186,$444	;CYAN
	DC.W	$188,$777		;RED
	DC.W	$18A,$AAA		;MAGENTA
	DC.W	$18C,$CCC		;YELLOW
	DC.W	$18E,$EEE		;WHITE

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
	SECTION ChipBuffers,BSS_C	;BSS doesn't count toward exe size
;*******************************************************************************

Screen:	ds.b h*bwid		;Define storage for buffer 1
Screen2:	ds.b h*bwid		;two buffers

	END

	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	move.w	#%1010110011010101,d0
	moveq	#15,d7
.loop:	btst	d7,d0
	beq.s	.next
	move.w	d7,d2
	add.w	d2,d2
	bset	d2,d1
	addq.w	#1,d2
	bset	d2,d1
.next:	dbf	d7,.loop