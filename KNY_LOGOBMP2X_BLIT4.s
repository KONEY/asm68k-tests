;*** More blitter tests, continuous scroll from populated buffer

;*** MiniStartup by Photon ***
	INCDIR	"NAS:AMIGA/CODE/KONEY/"
	INCLUDE	"PhotonsMiniWrapper1.04!.S"
	INCLUDE	"Blitter-Register-List.S"	;use if you like ;)

;********** Constants **********
w=320		;screen width, height, depth
h=256
bpls=3		;handy values:
bpl=w/16*2	;byte-width of 1 bitplane line (40)
bwid=bpls*bpl	;byte-width of 1 pixel line (all bpls)

POS_TOP=124*bpl
POS_LEFT=16
POS_MID=4
POS_RIGHT=20
POS_BOTTOM=122*bpl
BAND_OFFSET=86*bpl

;BLITTER CONSTANTS
bltx	=0
blty	=0
bltoffs	=210*(w/8)+bltx/8

blth	=12
bltw	=320/16
bltskip	=(320-320)/8

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
	MOVEQ	#0,D7		; INDICE PER TABELLA
	BSR	CREAPATCH		; FILL THE BUFFER
	BSR	CREATESCROLLSPACE	; NOW WE USE THE BLITTER HERE!

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
	MOVE.L	#KONEYBG,DrawBuffer
	BSR	BLITINPLACE	; FIRST BLITTATA
	BSR	SHIFTTEXT		; SHIFT DATI BUFFER?
	BSR	POPULATETXTBUFFER	; PUT SOMETHING
	;BSR.W	CYCLEPALETTE
	;*--- main loop end ---*
	;move.w	#$323,$180(a6)	; show rastertime left down to $12c
	BTST	#2,$DFF016	; POTINP - RMB pressed?
	bne.w	MainLoop		; then loop
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

ClearScreen:			; a1=screen destination address to clear
	bsr	WaitBlitter
	clr.w	$66(a6)		;destination modulo
	move.l	#$01000000,$40(a6)	;set operation type in BLTCON0/1
	move.l	a1,$54(a6)	;destination address
	move.w	#h*bpls*64+bpl/2,$58(a6)	;blitter operation size
	rts

VBint:				; Blank template VERTB interrupt
	movem.l	d0/a6,-(sp)	;Save used registers
	lea	$dff000,a6
	btst	#5,$1f(a6)	;check if it's our vertb int.
	beq.s	.notvb
	;*--- do stuff here ---*
	moveq	#$20,d0		;poll irq bit
	move.w	d0,$9c(a6)
	move.w	d0,$9c(a6)
.notvb:	movem.l	(sp)+,d0/a6	; restore
	rte

PRINT2X:
	MOVEM.L	D0-A6,-(SP)	; SAVE TO STACK
	MOVEQ	#bpls-1,D1	; UGUALI PER TUTTI I BITPLANE
	MOVE.W	DISPLACEINDEX,D7
	LEA	KONEYBG,A4
	LEA	DISPLACETABLE,A3
	LEA	PATCH,A0
.OUTERLOOP:
	LEA	KONEY2X,A5
	MOVEQ	#0,D6		; RESET D6
	MOVE.B	#9,D6			
	ADD.W	#POS_TOP,A4	; POSITIONING
.INNERLOOP:			; LOOP KE CICLA LA BITMAP
	ADD.W	#POS_LEFT,A4	; POSITIONING
	MOVE.L	(A0)+,D2		; SALVO SFONDO
	MOVE.L	(A5)+,D3		; QUESTA ISTRUZIONE FA ESPLODERE TUTTO
	MOVE.L	(A3,D7.W),D5	; FX 1
	ADD.W	#2,D7		; INCREMENTO INDICE TAB
	AND.W	#256-1,D7		; AND TIRA FUORI SEMPRE FINO A X E POI WRAPPA
	ROL.L	D5,D3		; GLITCH

	EOR.L	D2,D3		; KOMBINO SFONDO+SKRITTA
	MOVE.L	D3,(A4)		; QUESTA ISTRUZIONE FA ESPLODERE TUTTO
	ADD.W	#POS_MID,A4	; POSITIONING

	MOVE.L	(A0)+,D2		; SALVO SFONDO
	MOVE.L	(A5)+,D3		; QUESTA ISTRUZIONE FA ESPLODERE TUTTO
	LSR.L	D5,D3		; GLITCH
	EOR.L	D2,D3		; KOMBINO SFONDO+SKRITTA
	MOVE.L	D3,(A4)		; QUESTA ISTRUZIONE FA ESPLODERE TUTTO
	ADD.W	#POS_RIGHT,A4	; POSITIONING
	DBRA	D6,.INNERLOOP
	ADD.W	#POS_BOTTOM,A4	; POSITIONING
	DBF	D1,.OUTERLOOP
	MOVE.W	D7,DISPLACEINDEX
	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	RTS

CREAPATCH:
	MOVEM.L	D0-A6,-(SP)	; SAVE TO STACK
	MOVEQ	#bpls-1,D1	; UGUALI PER TUTTI I BITPLANE
	LEA	KONEYBG,A4
	LEA	PATCH,A5
.OUTERLOOP:
	MOVEQ	#0,D6		; RESET D6
	MOVE.B	#9,D6			
	ADD.W	#POS_TOP,A4	; POSITIONING
.INNERLOOP:			; LOOP KE CICLA LA BITMAP
	ADD.W	#POS_LEFT,A4	; POSITIONING
	MOVE.L	(A4),(A5)+	; QUESTA ISTRUZIONE FA ESPLODERE TUTTO
	ADD.W	#POS_MID,A4	; POSITIONING
	MOVE.L	(A4),(A5)+	; QUESTA ISTRUZIONE FA ESPLODERE TUTTO
	ADD.W	#POS_RIGHT,A4	; POSITIONING
	DBRA	D6,.INNERLOOP
	ADD.W	#POS_BOTTOM,A4	; POSITIONING
	DBF	D1,.OUTERLOOP
	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	RTS

CREATESCROLLSPACE:
	MOVEM.L	D0-D7/A0-A6,-(SP)	; SAVE TO STACK
	MOVEQ	#bpls-1,D1	; UGUALI PER TUTTI I BITPLANE
	LEA	KONEYBG,A4
.OUTERLOOP:
	MOVEQ	#0,D6		; RESET D6
	MOVE.B	#10*11-1,D6
	ADD.W	#POS_TOP+BAND_OFFSET,A4	; POSITIONING
.INNERLOOP:			; LOOP KE CICLA LA BITMAP
	MOVE.L	#0,(A4)+			; QUESTA ISTRUZIONE FA ESPLODERE TUTTO
	DBRA	D6,.INNERLOOP
	ADD.W	#POS_BOTTOM-BAND_OFFSET-bpl,A4	; POSITIONING
	DBF	D1,.OUTERLOOP
	MOVEM.L	(SP)+,D0-D7/A0-A6	; FETCH FROM STACK
	RTS

BLITINPLACE:
	MOVEM.L	D0-A6,-(SP)	; SAVE TO STACK
	LEA	KONEYBG,A4
	ADD.W	#bltoffs+40,A4
	MOVE.L	A4,BLTDPTH

	BTST.b	#6,DMACONR	; for compatibility
.WBlit:
	BTST.B	#6,DMACONR
	BNE.S	.Wblit

	MOVE.W	#$FFFF,BLTAFWM	; BLTAFWM lo spiegheremo dopo
	MOVE.W	#$FFFF,BLTALWM	; BLTALWM lo spiegheremo dopo
	MOVE.W	#$09F0,BLTCON0	; BLTCON0 (usa A+D)
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1 lo spiegheremo dopo
	MOVE.W	#0,BLTAMOD	; BLTAMOD =0 perche` il rettangolo

	MOVE.W	#0,BLTDMOD	; BLTDMOD 40-4=36 il rettangolo


	MOVE.L	#TXTSCROLLBUF,BLTAPTH	; BLTAPT  (fisso alla figura sorgente)

	MOVE.W	#8*64+320/16,BLTSIZE	; BLTSIZE (via al blitter !)
				; adesso, blitteremo una figura di
				; 2 word X 6 linee con una sola
				; blittata coi moduli opportunamente
				; settati per lo schermo.
				; BLTSIZE = (Altezza in righe)
				; * 64 + (Larghezza in pixel)/16 
	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	RTS

SHIFTTEXT:
	MOVEM.L	D0-A6,-(SP)	; SAVE TO STACK
	MOVE.L	#_TXTSCROLLBUF,BLTDPTH

	BTST.b	#6,DMACONR	; for compatibility
.WBlit:
	BTST.B	#6,DMACONR
	BNE.S	.Wblit

	MOVE.W	#$FFFF,BLTAFWM	; BLTAFWM lo spiegheremo dopo
	MOVE.W	#$FFFE,BLTALWM	; BLTALWM lo spiegheremo dopo
	MOVE.W	#%0001100111110000,BLTCON0	; BLTCON0 (usa A+D); con shift di un pixel
	MOVE.W	#%0000000000000010,BLTCON1	; BLTCON1 BIT 12 DESC MODE
	MOVE.W	#0,BLTAMOD	; BLTAMOD =0 perche` il rettangolo
				; sorgente ha le righe consecutive
				; in memoria.

	MOVE.W	#0,BLTDMOD	; BLTDMOD 40-4=36 il rettangolo
				; destinazione e` all'interno di un
				; bitplane largo 20 words, ovvero 40
				; bytes. Il rettangolo blittato
				; e` largo 2 words, cioe` 4 bytes.
				; Il valore del modulo e` dato dalla
				; differenza tra le larghezze

	MOVE.L	#_TXTSCROLLBUF,BLTAPTH	; BLTAPT  (fisso alla figura sorgente)

	MOVE.W	#8*64+336/16,BLTSIZE	; BLTSIZE (via al blitter !)
				; adesso, blitteremo una figura di
				; 2 word X 6 linee con una sola
				; blittata coi moduli opportunamente
				; settati per lo schermo.
				; BLTSIZE = (Altezza in righe)
				; * 64 + (Larghezza in pixel)/16 
	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	RTS

POPULATETXTBUFFER:
	MOVEM.L	D0-D7/A0-A6,-(SP)	; SAVE TO STACK
	LEA	TXTSCROLLBUF,A4
	MOVEQ	#0,D6		; RESET D6
	MOVE.B	#4-1,D6
.INNERLOOP:			; LOOP KE CICLA LA BITMAP
	ADD.W	#38,A4		; POSITIONING
	MOVE.W	#%1010101010101010,(A4)
	ADD.W	#2,A4		; POSITIONING
	ADD.W	#38,A4		; POSITIONING
	MOVE.W	#%0101010101010101,(A4)
	ADD.W	#2,A4		; POSITIONING
	DBRA	D6,.INNERLOOP
	MOVEM.L	(SP)+,D0-D7/A0-A6	; FETCH FROM STACK
	RTS

CYCLEPALETTE:
	MOVEM.L	D0-A6,-(SP)		; SAVE TO STACK
	;MOVE.B	COLORSINDEX,D0		; UGUALI PER TUTTI I BITPLANE
	MOVE.W	BPLCOLORINDEX,D0
	;LEA	COLORSTABLE,A0
	LEA	Palette,A1
	SUB.W	#4,D0
	MOVE.W	BUFFEREDCOLOR,(A1,D0.W)	; RESTORE OLD COLOR
	CMP.W	#26,D0
	BEQ.W	.RESET
	ADD.W	#4,D0
	MOVE.W	(A1,D0.W),BUFFEREDCOLOR	; PEEK THE COPPER	
	MOVE.W	#$0FFF,(A1,D0.W)		; POKE THE COPPER
	ADD.W	#4,D0
	MOVE.W	#$0000,2(A1)		; ALWAYS CLEAR BG
	MOVE.W	D0,BPLCOLORINDEX
	MOVEM.L	(SP)+,D0-A6		; FETCH FROM STACK
	RTS
.RESET:
	MOVE.W	#6,BPLCOLORINDEX
	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	BRA	CYCLEPALETTE
;********** Fastmem Data **********
DrawBuffer:	DC.L SCREEN2	;pointers to buffers to be swapped
ViewBuffer:	DC.L SCREEN1
DISPLACEINDEX:	DC.W 0
DISPLACETABLE:
	DC.W 0,0,0,2,0,0,0,0,0,2,0,3,0,0,6,1
	DC.W 0,0,0,3,0,0,0,0,3,0,0,7,0,0,0,0
	DC.W 0,0,3,0,0,0,0,1,4,0,0,0,0,8,1
	DC.W 0,3,0,1,0,0,0,0,0,0,0,0,0,0,0,2
	DC.W 0,0,0,5,0,0,0,0,0,0,3,0,0,0,1
	DC.W 2,1,0,1,0,3,0,3,0,0,0,1,2,1,0,0
	DC.W 0,0,0,0,3,0,0,0,0,1,0,0,0,2,1,0
	DC.W 1,3,0,2,0,0,0,3,2,0,4,0,1,0,7,0
COLORSINDEX:	DC.W 0
COLORSTABLE:
	DC.W $000F,$0EEE,$0DDD,$0CCC,$0BBB,$0AAA,$0999,$0888
	DC.W $0777,$0666,$0555,$0444,$0333,$0222,$0111,$0000
BUFFEREDCOLOR:	DC.W $0000
BPLCOLORINDEX:	DC.W 6

PATCH:		DS.B 10*64*bpls	;I need a buffer to save trap BG
;*******************************************************************************
	SECTION	ChipData,DATA_C	;declared data that must be in chipmem
;*******************************************************************************
KONEY2X:
	INCBIN	"koney10x64.raw"
DUMMYTXT:
	INCBIN	"dummytxt_320_8_1.raw"
	;DS.B h*bwid
_DUMMYTXT:
TXTSCROLLBUF:
	;INCBIN	"dummytxt_336_8_1.raw"
	DS.B (bpl+4)*8
_TXTSCROLLBUF:
KONEYBG:
	INCBIN	"dithermirrorbg_3.raw"
	;INCBIN	"glitchbg320256_3.raw"
	;DS.B h*bwid	
Copper:
	DC.W $1FC,0	;Slow fetch mode, remove if AGA demo.
	DC.W $8E,$2C81	;238h display window top, left
	DC.W $90,$2CC1	;and bottom, right.
	DC.W $92,$38	;Standard bitplane dma fetch start
	DC.W $94,$D0	;and stop for standard screen.

	DC.W $106,$0C00	;(AGA compat. if any Dual Playf. mode)
	DC.W $108,0	;bwid-bpl	;modulos
	DC.W $10A,0	;bwid-bpl	;RISULTATO = 80 ?

	DC.W $102,0	;SCROLL REGISTER (AND PLAYFIELD PRI)

Palette:			;Some kind of palette (3 bpls=8 colors)
	DC.W $0180,$0000
	DC.W $0182,$0333
	DC.W $0184,$0444
	DC.W $0186,$0555
	DC.W $0188,$0666
	DC.W $018A,$0777
	DC.W $018C,$0888
	DC.W $018E,$0FFF

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
	DC.W $100,BPLS*$1000+$200	;enable bitplanes

	DC.W $FE07,$FFFE
	DC.W $0180,$0FFF
	DC.W $FF07,$FFFE
	DC.W $0180,$0000
	DC.W $0182,$0FFF	; SCROLLING TEXT WHITE ON

	DC.W $FFDF,$FFFE	;allow VPOS>$ff

	DC.W $0807,$FFFE
	DC.W $0180,$0FFF
	DC.W $0907,$FFFE
	DC.W $0180,$0000
	DC.W $0182,$0333	; SCROLLING TEXT WHITE OFF

	DC.W $FFFF,$FFFE	;magic value to end copperlist

CopperE:
;*******************************************************************************
	SECTION ChipBuffers,BSS_C	;BSS doesn't count toward exe size
;*******************************************************************************

SCREEN1:	DS.B h*bwid	;Define storage for buffer 1
SCREEN2:	DS.B h*bwid	;two buffers

	END