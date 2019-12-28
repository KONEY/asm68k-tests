;*** MiniStartup by Photon ***
	INCDIR	"NAS:AMIGA/CODE/KONEY/"
	INCLUDE	"PhotonsMiniWrapper1.04!.S"
;********** Constants **********

;INCLUDE "Blitter-Register-List.S"	;use if you like ;)

w=320		;screen width, height, depth
h=256
bpls=3		;handy values:
bpl=w/16*2	;byte-width of 1 bitplane line
bwid=bpls*bpl	;byte-width of 1 pixel line (all bpls)

;********** Macros **********

WAITBLIT:macro
	tst.w	(a6)	;for compatibility with A1000
.wb\@:	
	btst	#6,2(a6)
	bne.s	.wb\@
	endm

;********** Demo **********		;Demo-specific non-startup code below.

Demo:	;a4=VBR, a6=Custom Registers Base addr
	;*--- init ---*
	move.l	#VBint,$6c(a4)
	move.w	#$c020,$9a(a6)
	move.w	#$87c0,$96(a6)
	;*--- clear screens ---*
	;lea	Screen1,a1
	;bsr.w	ClearScreen
	;lea	Screen2,a1
	bsr.w	ClearScreen
	bsr	WaitBlitter
	;*--- start copper ---*
	;lea	Screen1,a0
	moveq	#bpl,d0
	lea	BplPtrs+2,a1
	moveq	#bpls-1,d1
	bsr.w	PokePtrs

	move.l	#Copper,$80(a6)

;********************  main loop  ********************
MainLoop:
	LEA	Screen1,a1	;Then, the screen
	bsr.s	ClearScreen	;clear, Yoda pls.
	bsr.s	WaitBlitter	;Wait out blit: we plot to same area

	;MOVEQ	#18,d0		;Read 18
	move.w	#$12c,d0		;No buffering, so wait until raster
	bsr.w	WaitRaster	;is below the Display Window.
	;move.w	#$888,$182(a6)	;show rastertime left down to $12c

	bsr.w	PRINT_BG		;Stampa le linee di testo sullo schermo
	; do stuff here :)

	;*--- main loop end ---*
	;move.w	#$888,$180(a6)	;show rastertime left down to $12c

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

PRINT_BG:	
	MOVEM.L	D0-D1,-(SP)	; SAVE TO STACK
	CLR	D0
	MOVE.L	#TESTBG,D0	; in d0 mettiamo l'indirizzo della PIC, ossia dove inizia il primo bitplane
	LEA	BplPtrs,A1	; in a1 mettiamo l'indirizzo dei		; puntatori ai planes della COPPERLIST
	MOVEQ	#bpls-1,D1	; numero di bitplanes -1 (qua sono 3)		; per eseguire il ciclo col DBRA

.POINTBP:
	MOVE.W	D0,6(A1)		; copia la word BASSA dell'indirizzo del plane	; nella word giusta nella copperlist
	SWAP	D0		; scambia le 2 word di d0 (es: 1234 > 3412)	; mettendo la word ALTA al posto di quella
				; BASSA, permettendone la copia col move.w!!
	MOVE.W	D0,2(A1)		; copia la word ALTA dell'indirizzo del plane	; nella word giusta nella copperlist
	SWAP	D0		; scambia le 2 word di d0 (es: 3412 > 1234)	; rimettendo a posto l'indirizzo.
	;LSR	#1,D0		; GLITCHA!
	ADD.L	#40*256,D0	; Aggiungiamo 10240 ad D0, facendolo puntare	; al secondo bitplane (si trova dopo il primo)
				; (cioe' aggiungiamo la lunghezza di un plane)
				; Nei cicli seguenti al primo faremo puntare	; al terzo, al quarto bitplane eccetera.
	ADDQ.W	#8,A1		; a1 ora contiene l'indirizzo dei prossimi	; bplpointers nella copperlist da scrivere.
	DBRA	D1,.POINTBP	; Rifai D1 volte POINTBP (D1=num of bitplanes)
	MOVEM.L	(SP)+,D0-D1	; FETCH FROM STACK
	RTS

;*******************************************************************************
	SECTION	ChipData,DATA_C		;declared data that must be in chipmem
;*******************************************************************************

TESTBG:
	incbin	"ditherkoneybg320256.raw"	; qua carichiamo la figura in RAW,

Copper:
	dc.w $1fc,0	;Slow fetch mode, remove if AGA demo.
	dc.w $8e,$2c81	;238h display window top, left
	dc.w $90,$2cc1	;and bottom, right.
	dc.w $92,$38	;Standard bitplane dma fetch start
	dc.w $94,$d0	;and stop for standard screen.

	dc.w $106,$0c00	; (AGA compat. if any Dual Playf. mode)
	DC.W $108,0	; Bpl1Mod
	DC.W $10A,0	; Bpl2Mod

	;dc.w $102,0	;Scroll register (and playfield pri)
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

Screen1:	ds.b h*bwid		;Define storage for buffer 1

	END