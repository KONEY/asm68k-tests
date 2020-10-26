;*** MiniStartup by Photon ***
	INCDIR	"NAS:AMIGA/CODE/KONEY/"
	SECTION	"Code",CODE
	INCLUDE	"PhotonsMiniWrapper1.04!.S"
	INCLUDE	"Blitter-Register-List.S"	;use if you like ;)
	;INCLUDE	"PT12_OPTIONS.i"
	;INCLUDE	"P6112-Play-stripped.i"
;********** Constants **********
w=	336		;screen width, height, depth
h=	256
bpls=	4		;handy values:
bpl=	w/16*2		;byte-width of 1 bitplane line (40)
bwid=	bpls*bpl		;byte-width of 1 pixel line (all bpls)
bwid2=	bpls*(w-16)/16*2
blitsize=	h*64+w/16	;
blitsize2=	h*64*2+w/16	;16404
bplsize=	bpl*h		;
bplsize2=	(w-16)/16*2*h	;10240
blitsizeHF=h*bpls/2*64+w/16
blitsizeHF2=h*bpls/2*64+(w-16)/16
;*************

;********** Demo **********	;Demo-specific non-startup code below.
Demo:	;a4=VBR, a6=Custom Registers Base addr
	;*--- init ---*
	move.l	#VBint,$6c(a4)
	move.w	#%1110000000100000,INTENA
	;** SOMETHING INSIDE HERE IS NEEDED TO MAKE MOD PLAY! **
	;move.w	#%1110000000000000,INTENA	; Master and lev6	; NO COPPER-IRQ!

	move.w	#$87c0,DMACON
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

	; #### CPU INTENSIVE TASKS BEFORE STARTING MUSIC
	BSR.W	__InitCopperPalette
	;BSR.W	__BLITINPLACE	; FIRST BLITTATA
	BSR.W	__ADD_BLITTER_WORD
	; #### CPU INTENSIVE TASKS BEFORE STARTING MUSIC

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
	move.l	#bpl*h,d0
	lea	BplPtrs+2,a1
	moveq	#bpls-1,d1
	bsr.w	PokePtrs
	;*--- ...draw into the other(a2) ---*
	move.l	a2,a1
	;bsr	ClearScreen

	MOVE.L	KONEYBG,DrawBuffer

	; do stuff here :)

	BSR.W	__SCROLL_BG	; SHIFT DATI BUFFER?

	;*--- main loop end ---*

	ENDING_CODE:
	BTST	#6,$BFE001
	BNE.S	.DontShowRasterTime
	MOVE.W	#$FF0,$180(A6)	; show rastertime left down to $12c
	;BSR.W	__SCROLL_BG	; SHIFT DATI BUFFER?
	.DontShowRasterTime:
	BTST	#2,$DFF016	; POTINP - RMB pressed?
	BNE.W	MainLoop		; then loop
	;*--- exit ---*
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

__InitCopperPalette:
	MOVEM.L	D0-A6,-(SP)	; SAVE TO STACK
	LEA.L	PALETTEBUFFERED,A2
	LEA.L	Palette,A3
	MOVE.L	#15,D0
	.FillLoop:
	MOVE.L	(A2)+,(A3)+
	DBRA	D0,.FillLoop
	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	RTS

__BLITINPLACE:
	MOVEM.L	D0-D7/A0-A6,-(SP)	; SAVE TO STACK
	;LEA	BG1,A3
	MOVE.L	KONEYBG,A3
	MOVE.L	ScrollBuffer,A4
	BTST.B	#6,DMACONR		; for compatibility
	bsr	WaitBlitter

	MOVE.L	A3,BLTAPTH		; BLTAPT  (fisso alla figura sorgente)
	MOVE.L	A4,BLTDPTH
	MOVE.W	#$FFFF,BLTAFWM		; BLTAFWM lo spiegheremo dopo
	MOVE.W	#$FFFF,BLTALWM		; BLTALWM lo spiegheremo dopo
	MOVE.W	#%0000100111110000,BLTCON0	; BLTCON0 (usa A+D)
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1 lo spiegheremo dopo
	MOVE.W	#0,BLTAMOD		; BLTAMOD =0 perche` il rettangolo
	MOVE.W	#0,BLTDMOD		; BLTDMOD 40-4=36 il rettangolo

	MOVE.W	#blitsize,BLTSIZE		; BLTSIZE (via al blitter !)
	;MOVE.W	#blitsize2,BLTSIZE		; BLTSIZE (via al blitter !)
	;MOVE.W	#blitsize2,BLTSIZE		; BLTSIZE (via al blitter !)
	;MOVE.W	#blitsize2,BLTSIZE		; BLTSIZE (via al blitter !)

	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	RTS

__SCROLL_BG:
	MOVEM.L	D0-A6,-(SP)	; SAVE TO STACK
	MOVE.L	KONEYBG,A4
	BTST.B	#6,DMACONR	; for compatibility
	bsr	WaitBlitter

	MOVE.L	A4,BLTAPTH	; BLTAPT  (fisso alla figura sorgente)
	MOVE.L	A4,BLTDPTH
	MOVE.W	#$FFFF,BLTAFWM	; BLTAFWM lo spiegheremo dopo
	MOVE.W	#$FFFF,BLTALWM	; BLTALWM lo spiegheremo dopo
	MOVE.W	#%0001100111110000,BLTCON0	; BLTCON0 (usa A+D); con shift di un pixel
	MOVE.W	#%0000000000000000,BLTCON1	; BLTCON1 BIT 12 DESC MODE
	MOVE.W	#0,BLTAMOD	; BLTAMOD =0 perche` il rettangolo
	MOVE.W	#0,BLTDMOD	; BLTDMOD 40-4=36 il rettangolo

	MOVE.W	#blitsize2,BLTSIZE	; BLTSIZE (via al blitter !)
	bsr	WaitBlitter
	MOVE.W	#blitsize2,BLTSIZE	; BLTSIZE (via al blitter !)

	; PATCH FIRST WORD COLUMN
	bsr	WaitBlitter
	MOVE.L	A4,BLTDPTH
	MOVE.L	A4,BLTCPTH	; destination data (from the C channel)
	ADD.L	#40,A4
	MOVE.L	A4,BLTBPTH
	;MOVE.L	A4,BLTAPTH	; BLTAPT  (fisso alla figura sorgente)
	MOVE.W	#$8000,BLTAFWM	; BLTAFWM lo spiegheremo dopo
	MOVE.W	#%0000011111001010,BLTCON0	; BLTCON0 (usa A+D); con shift di un pixel
	MOVE.W	#40,BLTBMOD	; BLTAMOD =0 perche` il rettangolo
	MOVE.W	#40,BLTCMOD	; BLTAMOD =0 perche` il rettangolo
	MOVE.W	#40,BLTDMOD	; BLTDMOD 40-4=36 il rettangolo

	MOVE.W	#%1000000000000001,BLTSIZE	; BLTSIZE (via al blitter !)
	bsr	WaitBlitter
	MOVE.W	#%1000000000000001,BLTSIZE	; BLTSIZE (via al blitter !)

	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	RTS

; FILLS A BUFFER WITH RANDOM DATA
__FILLRNDBG:
	MOVEM.L	D0-A6,-(SP)	; SAVE TO STACK
	MOVE.L	GLITCHER_DEST,A4	; SOURCE DATA
	MOVE.L	GLITCHER_DPH,D1	; UGUALI PER TUTTI I BITPLANE
	.BITPLANESLOOP:
	CLR	D4
	MOVE.B	#h-1,D4		; QUANTE LINEE
	.OUTERLOOP:		; NUOVA RIGA
	CLR	D6
	MOVE.B	#bpl-1,D6		; RESET D6
	.INNERLOOP:
	BSR.S	_RandomWord
	MOVE.B	D5,(A4)+
	DBRA	D6,.INNERLOOP
	DBRA	D4,.OUTERLOOP
	DBRA	D1,.BITPLANESLOOP
	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	RTS

__ADD_BLITTER_WORD:
	MOVEM.L	D0-A6,-(SP)	; SAVE TO STACK
	LEA	BG1_DATA,A0
	LEA	BG1,A1
	;ADD.W	#h*bpls,A0		; POSITIONING THE SOURCE
	MOVE.L	#h*bpls-1,D1	; LINES
	.OUTERLOOP:
	MOVE.L	#(w-16)/16-1,D0	; SIZE OF SOURCE IN WORDS
	.INNERLOOP:
	;CLR.W	$100		; DEBUG | w 0 100 2
	MOVE.W	(A0)+,(A1)+
	DBRA	D0,.INNERLOOP
	MOVE.W	#0,(A1)+		; THE EXTRA WORD
	DBRA.W	D1,.OUTERLOOP

	MOVEM.L	(SP)+,D0-A6	; FETCH FROM STACK
	RTS

_RandomWord:	bsr	_RandomByte
		rol.w	#8,d5
_RandomByte:	move.b	$dff007,d5	;$dff00a $dff00b for mouse pos
		move.b	$bfd800,d3
		eor.b	d3,d5
		rts

;********** Fastmem Data **********
DrawBuffer:	DC.L SCREEN2	; pointers to buffers to be swapped
ViewBuffer:	DC.L SCREEN1	;
ScrollBuffer:	DC.L SCREEN3	;
KONEYBG:		DC.L BG1		; INIT BG

GLITCHER_SRC:	DC.L 0
GLITCHER_DEST:	DC.L 0
GLITCHER_DPH:	DC.L 0

PALETTEBUFFERED:
	DC.W $0180,$0031,$0182,$0000,$0184,$0111,$0186,$0122
	DC.W $0188,$0333,$018A,$0444,$018C,$0555,$018E,$0556
	DC.W $0190,$0666,$0192,$0888,$0194,$0999,$0196,$0AAA
	DC.W $0198,$09AA,$019A,$0FFF,$019C,$0FFF,$019E,$0FFF

	;*******************************************************************************
	SECTION	ChipData,DATA_C	;declared data that must be in chipmem
	;*******************************************************************************

BG1:	DS.W h*bpls
BG1_DATA:	INCBIN	"onePlane_10.raw"
	INCBIN	"ditherkoneybg320256.raw"
	;INCBIN	"BLITTER_MARGIN.raw"

Copper:
	DC.W $1FC,0	;Slow fetch mode, remove if AGA demo.
	DC.W $8E,$2C81	;238h display window top, left | DIWSTRT - 11.393
	DC.W $90,$2CC1	;and bottom, right.	| DIWSTOP - 11.457
	DC.W $92,$38	;Standard bitplane dma fetch start
	DC.W $94,$D0	;and stop for standard screen.

	DC.W $106,$0C00	;(AGA compat. if any Dual Playf. mode)
	DC.W $108,2	;bwid-bpl	;modulos
	DC.W $10A,2	;bwid-bpl	;RISULTATO = 80 ?

	DC.W $102,0	;SCROLL REGISTER (AND PLAYFIELD PRI)

Palette:	;Some kind of palette (3 bpls=8 colors)
	DC.W $0180,0,$0182,0,$0184,0,$0186,0
	DC.W $0188,0,$018A,0,$018C,0,$018E,0
	DC.W $0190,0,$0192,0,$0194,0,$0196,0
	DC.W $0198,0,$019A,0,$019C,0,$019e,0

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

	;DC.W $0807,$FFFE
	;DC.W $0180,$0FFF
	;DC.W $0907,$FFFE
	;DC.W $0180,$0000
	;DC.W $0182,$0333	; SCROLLING TEXT WHITE OFF

	DC.W $FFFF,$FFFE	;magic value to end copperlist
_Copper:

;*******************************************************************************
	SECTION ChipBuffers,BSS_C	;BSS doesn't count toward exe size
;*******************************************************************************

SCREEN1:		DS.B h*bwid	; Define storage for buffer 1
SCREEN2:		DS.B h*bwid	; two buffers
SCREEN3:		DS.B h*bwid	; two buffers

END