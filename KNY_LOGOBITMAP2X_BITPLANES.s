;*** MiniStartup by Photon ***
	INCDIR	"NAS:AMIGA/CODE/KONEY/"
	INCLUDE	"PhotonsMiniWrapper1.04!.S"
;********** Constants **********

;	INCLUDE "Blitter-Register-List.S"	;use if you like ;)

w=320		;screen width, height, depth
h=256
bpls=3		;handy values:
bpl=w/16*2	;byte-width of 1 bitplane line
bwid=bpls*bpl	;byte-width of 1 pixel line (all bpls)

;********** Macros **********

WAITBLIT:	macro
	tst.w	(a6)	;for compatibility with A1000
.wb\@:	btst	#6,2(a6)
	bne.s	.wb\@
	endm

;********** Demo **********	;Demo-specific non-startup code below.

Demo:	;a4=VBR, a6=Custom Registers Base addr
	;*--- init ---*
	move.l	#VBint,$6c(a4)
	move.w	#$c020,$9a(a6)
	move.w	#$87c0,$96(a6)
	;*--- clear screens ---*
	lea	Screen1,a1
	bsr.w	ClearScreen
	lea	Screen2,a1
	bsr.w	ClearScreen
	bsr	WaitBlitter
	;*--- start copper ---*
	lea	Screen1,a0
	moveq	#bpl,d0
	lea	BplPtrs+2,a1
	moveq	#bpls-1,d1
	bsr.w	PokePtrs

	move.l	#Copper,$80(a6)

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
	move.l	#bpl*256,d0
	lea	BplPtrs+2,a1
	moveq	#bpls-1,d1
	bsr.w	PokePtrs
	;*--- ...draw into the other(a2) ---*
	move.l	a2,a1
	;bsr	ClearScreen
	bsr	WaitBlitter

	; do stuff here :)
	BSR.W	PRINT2X
	MOVE.L	#BFRKNY,DrawBuffer
	;MOVE.L	#KONEYBG,DrawBuffer
	;*--- main loop end ---*
	;move.w	#$323,$180(a6)	;show rastertime left down to $12c
	btst	#6,$bfe001	;Left mouse button not pressed?
	bne.w	MainLoop		;then loop
	;*--- exit ---*
	rts

;********** Demo Routines **********

PokePtrs:	
			;Generic, poke ptrs into copper list
.bpll:	move.l	a0,d2
	swap	d2
	move.w	d2,(a1)		;high word of address
	move.w	a0,4(a1)		;low word of address
	addq.w	#8,a1		;skip two copper instructions
	add.l	d0,a0		;next ptr
	dbf	d1,.bpll
	rts

ClearScreen:			;a1=screen destination address to clear
	bsr	WaitBlitter
	clr.w	$66(a6)		;destination modulo
	move.l	#$01000000,$40(a6)	;set operation type in BLTCON0/1
	move.l	a1,$54(a6)	;destination address
	move.w	#h*bpls*64+bpl/2,$58(a6)	;blitter operation size
	rts

VBint:				;Blank template VERTB interrupt
	movem.l	d0/a6,-(sp)	;Save used registers
	lea	$dff000,a6
	btst	#5,$1f(a6)	;check if it's our vertb int.
	beq.s	.notvb
	;*--- do stuff here ---*
	moveq	#$20,d0		;poll irq bit
	move.w	d0,$9c(a6)
	move.w	d0,$9c(a6)
.notvb:	movem.l	(sp)+,d0/a6	;restore
	rte

PRINT2X:				; Routine che stampa
	MOVEM.L	D1/D6/A4/A5,-(SP)	; SAVE TO STACK
	MOVEQ	#bpls-1,D1	; UGUALI PER TUTTI I BITPLANE
	MOVE.L	#BFRKNY,A4
.OUTERLOOP:
	MOVE.L	#KONEY2X,A5
	MOVEQ	#0,D6		; RESET D6
	MOVE.B	#9,D6			
	ADD.W	#4600,A4		; POSITIONING
.INNERLOOP:			; LOOP KE CICLA LA BITMAP
	ADD.W	#14,A4		; POSITIONING
	MOVE.L	(A5)+,(A4)	; QUESTA ISTRUZIONE FA ESPLODERE TUTTO
	ADD.W	#4,A4		; POSITIONING
	MOVE.L	(A5)+,(A4)	; QUESTA ISTRUZIONE FA ESPLODERE TUTTO
	ADD.W	#22,A4		; POSITIONING
	DBRA	D6,.INNERLOOP
	ADD.W	#5240,A4		; POSITIONING
	;MOVE.W	#%1010101010101010,(A4); SHOW FINAL POSITIONING
	DBF	D1,.OUTERLOOP
	MOVEM.L	(SP)+,D1/D6/A4/A5	; FETCH FROM STACK
	RTS

;********** Fastmem Data **********
DrawBuffer:	dc.l Screen2	;pointers to buffers to be swapped
ViewBuffer:	dc.l Screen1

;*******************************************************************************
	SECTION ChipData,DATA_C	;declared data that must be in chipmem
;*******************************************************************************

KONEYBG:
	INCBIN	"dithermirrorbg.raw"
KONEY2X:
	INCBIN	"koney10x64.raw"	
BFRKNY:	DS.B h*bwid	;I need a buffer to center KONEY

Copper:
	DC.W $1FC,0	;Slow fetch mode, remove if AGA demo.
	DC.W $8E,$2C81	;238h display window top, left
	DC.W $90,$2CC1	;and bottom, right.
	DC.W $92,$38	;Standard bitplane dma fetch start
	DC.W $94,$D0	;and stop for standard screen.

	DC.W $106,$0C00	;(AGA compat. if any Dual Playf. mode)
	DC.W $108,0	;bwid-bpl	;modulos
	DC.W $10A,0	;bwid-bpl	;RISULTATO = 80 ?

	dc.w $102,0	;Scroll register (and playfield pri)

Palette:			;Some kind of palette (3 bpls=8 colors)
	DC.W $0180,$0111,$0182,$0333,$0184,$0444,$0186,$0555
	DC.W $0188,$0777,$018A,$0888,$018C,$0AAA,$018E,$0FFF

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

Screen1:	DS.B h*bwid		;Define storage for buffer 1
Screen2:	DS.B h*bwid		;two buffers

	END