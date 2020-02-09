;*** More blitter test. TEXT scrolling from R to L :)
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
	;move.w	#$323,$180(a6)	;show rastertime left down to $12c
	BTST	#2,$DFF016	;POTINP - RMB pressed?
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
	CMP.W	#8,D7
	BNE.W	.SKIP
	LEA	TXTSCROLLBUF,A4
	LEA	FONT,A5
	LEA	TEXT,A6
	ADD.W	TEXTINDEX,A6
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
	MOVE.W	#8,D7
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
	;DCB.W	8,$5E
_DUMMYTXT:
TXTSCROLLBUF:	DS.B (bpl)*8
_TXTSCROLLBUF:
FRAMESINDEX:	DC.W 8
KONEYBG:

	INCBIN	"dithermirrorbg_3.raw"
	;INCBIN	"glitchbg320256_3.raw"
	;DS.B h*bwid	
FONT:
	DC.L	%00000000000000000000000000000000
	DC.B	%00000000,%00000000,%00000000,%00000000
	INCBIN	"scummfnt_8x752.raw"
	EVEN
_FONT:
TEXT:
	DC.B "WELCOME TO ****FATAL_DEFRAG****  KONEY FIRST AMIGA HARDCORE RELEASE!!! THIS "
	DC.B "INTRO IS BEST VIEWED ON A REAL AMIGA WITH A REAL CRT AND WITH HUGE LOUDSPEAKERS! "
	DC.B "OK REAL SCROLLTEXT STARTS HERE: I ALWAYS WANTED TO CODE THE AMIGA BUT I NEVER "
	DC.B "STARTED BECAUSE I MOSTLY FOCUSED ON MUSIC MAKING. BUT IN 2019 IT HAS BEEN 30 YEARS SINCE "
	DC.B "I GOT MY FIRST AMIGA (A500 1.2 IN 1989!) AND THESE DAYS I DO MY LIVING WITH PHP CODING "
	DC.B "AND MUSIC... SIMPLY MY LACK OF AMIGA HARDWARE CODING KNOWLEDGE BECAME UNACCEPTABLE "
	DC.B "ANYMORE. ALSO I HAVE A GOOD AMOUNT OF HARDCORE MODULES MADE ON OCTAMED SOUNDSTUDIO AND RELEASED ON "
	DC.B "VINYL WHICH I ALWAYS WANTED TO USE IN AMIGA INTROZ! SO I STARTED LEARNING 68K AND "
	DC.B "BLITTER AND COPPER BY READING ONLINE BOOKS AND WATCHING YOUTUBE TUTORIALS AND SLOWLY "
	DC.B "STARTED TO PUT TOGETHER THIS PIECE OF CODE HERE. OBVIOUSLY I KNOW IT'S NOT SUPER COOL AS "
	DC.B "PAST OR FROM THESE DAYS DEMOSCENE RELEASES BUT HEY, I'VE JUST STARTED AND AMIGA ISN'T "
	DC.B "THE EASIEST HARDWARE AROUND! BUT I WOULD SAY MUSIC IS COOL OR AT LEAST THIS IS WHAT "
	DC.B "PEOPLE WHO OWN THE VINYL HAVE TOLD ME OVER THE YEARS. IT'S AN INDUSTRIAL HARDCORE TRACK "
	DC.B "GRINDING YOUR BRAIN AT 210 BPM, RELEASED BACK IN 1998 ON ZERO-MUSIC HARD WHICH IS ONE OF "
	DC.B "THE MOST ICONIC HARDCORE LABELS. BUT NOW LET'S SPEND A FEW WORDS SPEAKING ABOUT THE BEST "
	DC.B "COMPUTER EVER: THE AMIGA!!!! AND NO WORDS FOR THE WORST COMPUTER EVER... THE SHITTINTOSH! "
	DC.B "WELL NOW I'D LIKE TO SEND OUT A MESSAGE TO ALL AMIGA CODERS AROUND ME SO VENICE, ITALY: "
	DC.B "LET'S GATHER! LET'S MEET AND MAKE AMIGA SHIT TOGETHER!"
	DC.B "    -------    AKNOWLEDGMENTS: I'D LIKE TO MENTION THIS PEOPLE FOR INDIRECTLY HELPING ME "
	DC.B "IN MY MACHINE CODE JOURNEY: RANDY/RAM JAM FOR HIS AMIGA ASSEMBLER COURSE, PHOTON/SCOOPEX "
	DC.B "FOR HIS AMIGA HARDWARE PROGRAMMING VIDEO TUTORIAL, DA JORMAS FOR INSPIRING ME FOR MORE "
	DC.B "THAN 20 YEARS IN BOTH AMIGA CODING AND MUSIC AND OCTAMED SOUNDSTUDIO FOR BEING THE BEST "
	DC.B "MUSIC PROGRAM EVER!! "
	DC.B " - GREETINGS: AT THIS POINT IT'S A COMMON PRACTICE TO SHOUT OUT GREETINGS SO HERE WE ARE: "
	DC.B "FABBROZ AND ALL THE RETROACADEMY FACEBOOK GROUP FOR THE FANTASTIC RETRO-EVENTS, "
	DC.B "MARCO HDG RICCI FOR HELPING ME OUT DURING MY HARD TIMES WITH ASSEMBLER, THE ASM CODING "
	DC.B "SECTION USERS @ ENGLISH AMIGA BOARD WHO HELPED ME, KCMA/T-PLUS AND THE DESTROYER FOR BEING "
	DC.B "ACTIVE AMIGACORE ARTISTS, NO NEW STYLE FACEBOOK GROUP FOR THROWING THE BEST OLDSCHOOL "
	DC.B "HARDCORE PARTIES IN ITALY.  ----   "
	DC.B "HOT LINKZ: WWW.KONEY.ORG - WWW.RETROACADEMY.IT - WWW.DISCOGS.COM	    .EOF   "
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

	DC.W $FE07,$FFFE
	DC.W $0180,$0FFF
	DC.W $FF07,$FFFE
	DC.W $0180,$0133	; SCROLLAREA BG COLOR
	DC.W $0182,$0AAA	; SCROLLING TEXT WHITE ON

	DC.W $FFDF,$FFFE	; allow VPOS>$ff

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