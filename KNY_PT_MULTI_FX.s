;*** WITH MED MODULE CONVERTED TO PT
;*** MiniStartup by Photon ***
	INCDIR	"NAS:AMIGA/CODE/KONEY/"
	SECTION	"Code+PT12",CODE
	INCLUDE	"PhotonsMiniWrapper1.04!.S"
	INCLUDE	"Blitter-Register-List.S"	;use if you like ;)
	INCLUDE	"PT12_OPTIONS.i"
	INCLUDE	"P6112-Play-stripped.i"
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
;blty	=0
bltoffs	=210*(w/8)+bltx/8

;blth	=12
;bltw	=320/16
;bltskip	=(320-320)/8

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

	;** SOMETHING INSIDE HERE IS NEEDED TO MAKE MOD PLAY! **
	MOVE.W	#$E000,$DFF09A	;Master and lev6
				;NO COPPER-IRQ!
	;** SOMETHING INSIDE HERE IS NEEDED TO MAKE MOD PLAY! **

	;---  Call P61_Init  ---
	MOVEM.L D0-A6,-(SP)
	lea Module1,a0
	sub.l a1,a1
	sub.l a2,a2
	moveq #0,d0
	jsr P61_Init
	MOVEM.L (SP)+,D0-A6

	;MOVEQ	#0,D7		; INDICE PER TABELLA
	BSR	CREAPATCH		; FILL THE BUFFER
	BSR	CREATESCROLLSPACE	; NOW WE USE THE BLITTER HERE!

	MOVE.L	#Copper,$80(a6)

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

;	MOVE.W	AUDIOCHANLEVEL0,D2
;	CMPI.W	#0,D2		; BEWARE RND ROUTINE WILL RESET D1
;	BEQ.S	_noglitch
	BSR.W	DITHERBGPLANE
;_noglitch:

	BSR	CREATESCROLLSPACE	; NOW WE USE THE BLITTER HERE!

	BSR	BLITINPLACE	; FIRST BLITTATA
	BSR	SHIFTTEXT		; SHIFT DATI BUFFER?
	BSR	POPULATETXTBUFFER	; PUT SOMETHING

	MOVE.W	AUDIOCHANLEVEL1,D2
	CMPI.W	#0,D2		; BEWARE RND ROUTINE WILL RESET D1
	BEQ.S	_noflash
	BSR.W	CYCLEPALETTE
_noflash:

	; MOD VISUALIZERS *****
	ifne visuctrs
	MOVEM.L D0-A6,-(SP)

	; GROOVE 2
	lea	P61_visuctr0(PC),a0;which channel? 0-3
	moveq	#10,d0		;maxvalue
	sub.w	(a0),d0		;-#frames/irqs since instrument trigger
	bpl.s	.ok0		;below minvalue?
	moveq	#0,d0		;then set to minvalue
.ok0:	
	MOVE.W	D0,AUDIOCHANLEVEL0	; RESET
_ok0:

	; KICKDRUM
	lea	P61_visuctr1(PC),a0;which channel? 0-3
	moveq	#14,d0		;maxvalue
	sub.w	(a0),d0		;-#frames/irqs since instrument trigger
	bpl.s	.ok1		;below minvalue?
	moveq	#0,d0		;then set to minvalue
	MOVE.W	#6,BPLCOLORINDEX	; FOR TIMING
.ok1:	
	MOVE.W	D0,AUDIOCHANLEVEL1	; RESET
_ok1:

	; BASS
	lea	P61_visuctr2(PC),a0;which channel? 0-3
	LEA	Palette+6,A1
	moveq	#15,d0		;maxvalue
	sub.w	(a0),d0		;-#frames/irqs since instrument trigger
	bpl.s	.ok2		;below minvalue?
	moveq	#0,d0		;then set to minvalue
.ok2:	
	MOVE.W	D0,AUDIOCHANLEVEL2	; RESET
	move.w	d0,(a1)		;poke blue color
_ok2:

	; GROOVE 1
	lea	P61_visuctr3(PC),a0;which channel? 0-3
	moveq	#14,d0		;maxvalue
	sub.w	(a0),d0		;-#frames/irqs since instrument trigger
	bpl.s	.ok3		;below minvalue?
	moveq	#0,d0		;then set to minvalue
.ok3:	
	MOVE.W	D0,AUDIOCHANLEVEL3	; RESET
_ok3:

	MOVEM.L (SP)+,D0-A6
	endc
	; MOD VISUALIZERS *****

	;*--- main loop end ---*
	;move.w	#$323,$180(a6)	;show rastertime left down to $12c
	BTST	#2,$DFF016	;POTINP - RMB pressed?
	bne.w	MainLoop		;then loop
	;*--- exit ---*
	;;    ---  Call P61_End  ---
	MOVEM.L D0-A6,-(SP)
	JSR P61_End
	MOVEM.L (SP)+,D0-A6
	RTS

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
	move.l	#h*bpls*64+bpl/2,$58(a6)	;blitter operation size
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
.INNERLOOP:
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
.INNERLOOP:
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
.INNERLOOP:
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

	BTST.b	#6,DMACONR	; for compatibility
.WBlit:
	BTST.B	#6,DMACONR
	BNE.S	.Wblit

	MOVE.L	A4,BLTDPTH
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
	BTST.b	#6,DMACONR	; for compatibility
.WBlit:
	BTST.B	#6,DMACONR
	BNE.S	.Wblit

	MOVE.W	#$FFFF,BLTAFWM	; BLTAFWM lo spiegheremo dopo
	MOVE.W	#$FFFF,BLTALWM	; BLTALWM lo spiegheremo dopo
	MOVE.W	#%0010100111110000,BLTCON0	; BLTCON0 (usa A+D); con shift di un pixel
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

	MOVE.L	#_TXTSCROLLBUF-2,BLTAPTH	; BLTAPT  (fisso alla figura sorgente)
	MOVE.L	#_TXTSCROLLBUF-2,BLTDPTH

	MOVE.W	#8*64+320/16,BLTSIZE	; BLTSIZE (via al blitter !)
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
	MOVE.W	FRAMESINDEX,D7
	CMP.W	#4,D7
	BNE.W	.SKIP
	LEA	TXTSCROLLBUF,A4
	LEA	FONT,A5
	LEA	TEXT,A6

	ADD.W	TEXTINDEX,A6
	CMP.L	#_TEXT,A6	; Siamo arrivati all'ultima word della TAB?
	BNE.S	.PROCEED
	MOVE.W	#0,TEXTINDEX	; Riparti a puntare dalla prima word
.PROCEED:
	MOVE.B	(A6),D2		; Prossimo carattere in d2
	SUB.B	#$20,D2		; TOGLI 32 AL VALORE ASCII DEL CARATTERE, IN
	MULU.W	#8,D2		; MOLTIPLICA PER 8 IL NUMERO PRECEDENTE,
	ADD.W	D2,A5
	MOVEQ	#0,D6		; RESET D6
	MOVE.B	#8-1,D6
.LOOP:
	ADD.W	#38,A4		; POSITIONING
	MOVE.B	(A5)+,(A4)+
	;ADD.W	#1,A4		; POSITIONING
	;ADD.W	#38,A4		; POSITIONING
	MOVE.B	#%00000000,(A4)+
	;ADD.W	#2,A4		; POSITIONING
	DBRA	D6,.LOOP
.SKIP:
	SUB.W	#1,D7
	CMP.W	#0,D7
	BEQ.W	.RESET
	MOVE.W	D7,FRAMESINDEX
	MOVEM.L	(SP)+,D0-D7/A0-A6	; FETCH FROM STACK
	RTS
.RESET:
	ADD.W	#1,TEXTINDEX
	MOVE.W	#4,D7
	MOVE.W	D7,FRAMESINDEX	; OTTIMIZZABILE
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
	;CMP.W	#26,D0
	;BEQ.W	.RESET
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

DITHERBGPLANE:
	MOVEM.L	D0-D7/A0-A6,-(SP)	; SAVE TO STACK
	LEA	KONEYBG,A3	; Indirizzo del bitplane destinazione in a3
	;ADD.W	#10239,A3		; NEXT BITPLANE (?)
	CLR	D4
	MOVE.B	#255,D4		; QUANTE LINEE
	;MOVE.L	#%10101010101010101010101010101010,D5
OUTERLOOP:			; NUOVA RIGA
	;MOVE.W	#0,D5		; RESET
	MOVE.L	#%10101010101010101010101010101010,D5	; RESET
	MOVE.W	AUDIOCHANLEVEL3,D1
	CMPI.W	#0,D1		; BEWARE RND ROUTINE WILL RESET D1
	BEQ.S	_nornd
	BSR.W	_RandomWord
_nornd:
	; TODO some EOR with audiochannel level to make fx "follow" volume a bit
	CLR	D6
	MOVE.B	#39,D6		; RESET D6
	;LSR.L	#3,D5
INNERLOOP:	; LOOP KE CICLA LA BITMAP

	MOVE.w	D5,(A3)
	;NOT	D5
	ADD.W	#1,A3
	;LSL.L	#1,D5
	DBRA	D6,INNERLOOP
	DBRA	D4,OUTERLOOP
	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	RTS

_RandomWord:	bsr	_RandomByte
		rol.w	#8,d5
_RandomByte:	move.b	$dff007,d5;$dff00a $dff00b for mouse pos
		move.b	$bfd800,d1
		eor.b	d1,d5
		rts

AUDIOCHANLEVEL0:	DC.W 0
AUDIOCHANLEVEL1:	DC.W 0
AUDIOCHANLEVEL2:	DC.W 0
AUDIOCHANLEVEL3:	DC.W 0

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
TXTSCROLLBUF:	DS.B (bpl)*8
_TXTSCROLLBUF:
FRAMESINDEX:	DC.W 4
KONEYBG:

	;INCBIN	"dithermirrorbg_3.raw"
	INCBIN	"glitchditherbg7_320256_3.raw"
FONT:
	DC.L	0,0	; SPACE CHAR
	INCBIN	"scummfnt_8x752.raw"
	EVEN
_FONT:
TEXT:
	DC.B "                     "
	DC.B "LOREM IPSUM DOLOR SIT AMET, CONSECTETUR ADIPISCING ELIT, SED DO EIUSMOD TEMPOR INCIDIDUNT UT LABORE ET DOLORE MAGNA ALIQUA. UT ENIM AD MINIM VENIAM. "
	DC.B "AT VERO EOS ET ACCUSAMUS ET IUSTO ODIO DIGNISSIMOS DUCIMUS QUI BLANDITIIS PRAESENTIUM VOLUPTATUM DELENITI ATQUE "
	DC.B "ORRUPTI QUOS DOLORES ET QUAS MOLESTIAS EXCEPTURI SINT OCCAECATI CUPIDITATE NON PROVIDENT, SIMILIQUE SUNT IN CULPA QUI OFFICIA DESERUNT MOLLITIA ANIMI, ID EST LABORUM ET DOLORUM FUGA. "
	DC.B "ET HARUM QUIDEM RERUM FACILIS EST ET EXPEDITA DISTINCTIO. NAM LIBERO TEMPORE, CUM SOLUTA NOBIS EST ELIGENDI OPTIO CUMQUE NIHIL IMPEDIT QUO MINUS ID QUOD "
	DC.B "MAXIME PLACEAT FACERE POSSIMUS, OMNIS VOLUPTAS ASSUMENDA EST, OMNIS DOLOR REPELLENDUS. "
	DC.B "TEMPORIBUS AUTEM QUIBUSDAM ET AUT OFFICIIS DEBITIS AUT RERUM NECESSITATIBUS SAEPE EVENIET UT ET VOLUPTATES. "
	DC.B "HOT LINKZ: WWW.KONEY.ORG - WWW.RETROACADEMY.IT - WWW.DISCOGS.COM             .EOF  "
	DC.B "                                                                              "
	EVEN
_TEXT:
TEXTINDEX:	DC.W 0

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

COPPERWAITS:
	DC.W $FE07,$FFFE
	DC.W $0180,$0FFF
	DC.W $FF07,$FFFE
	DC.W $0180,$0011	; SCROLLAREA BG COLOR
	DC.W $0182,$0AAA	; SCROLLING TEXT WHITE ON

	DC.W $FFDF,$FFFE	; allow VPOS>$ff

	DC.W $0807,$FFFE
	DC.W $0180,$0FFF
	DC.W $0907,$FFFE
	DC.W $0180,$0000
	DC.W $0182,$0333	; SCROLLING TEXT WHITE OFF

	DC.W $FFFF,$FFFE	;magic value to end copperlist
CopperE:

Module1:	INCBIN	"FatalDefrag.P61"	; code $9104

;*******************************************************************************
	SECTION ChipBuffers,BSS_C	;BSS doesn't count toward exe size
;*******************************************************************************

SCREEN1:	DS.B h*bwid	;Define storage for buffer 1
SCREEN2:	DS.B h*bwid	;two buffers

	END