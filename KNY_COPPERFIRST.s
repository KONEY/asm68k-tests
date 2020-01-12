;*** MiniStartup by Photon ***
	INCDIR	"NAS:AMIGA/CODE/KONEY/"
	INCLUDE "PhotonsMiniWrapper1.04!.S"
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

	;bsr.s	DBLBMP

;********************  main loop  ********************
MainLoop:
	lea	Screen,a1		;Then, the screen
	bsr.s	ClearScreen	;clear, Yoda pls.
	bsr.s	WaitBlitter	;Wait out blit: we plot to same area

	moveq	#18,d0		;Read 18
	;lea	Points(PC),a0	;points from the source data,
	lea	Screen,a1		;and to the destination screen
	bsr.w	PRINT2X		; Stampa le linee di testo sullo schermo

	move.w	#$12c,d0		;No buffering, so wait until raster
	bsr.w	WaitRaster	;is below the Display Window.
	;move.w	#$888,$182(a6)	;show rastertime left down to $12c

	; do stuff here :)
	MOVE.W	#$6007+$0100,WAITRAS2	;POKE THE COPPER

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
	move.w	d0,$9c(a6)
.notvb:	
	movem.l	(sp)+,d0/a6		;restore
	rte

DBLBMP:
	MOVE.L	#KONEY,A1
	MOVE.L	#KONEY2x,A5
	LEA	CARRIAGESTABLE,A3
	MOVEQ	#0,D6
	MOVEQ	#9,D6		; QUANTE BYTE?

_DBLBMP:				; LOGICA PER RADDOPPIARE LA BITMAP
	MOVEQ	#0,D0
	MOVE.W	(A1)+,D0
	;MOVE.W	#%1010101010101010,D0	; MOCKED BITS

	;****************
	MOVEQ	#0,D1
	MOVEQ	#0,D2
	MOVEQ	#15,D7
_LOOP:	
	BTST	D7,D0
	BEQ.S	_NEXT
	MOVE.W	D7,D2
	ADD.W	D2,D2
	BSET	D2,D1
	ADDQ.W	#1,D2
	BSET	D2,D1
_NEXT:	
	DBRA	D7,_LOOP
	;*****************

	MOVE.L	D1,(A5)
	ADD.L	#8,A5		; POSITIONING
	MOVE.L	D1,(A5)
	SUB.W	#4,A5		; POSITIONING
	ADD.W	(A3)+,A5		; POSITIONING

	;ADDQ.W	#2,A5		; POSITIONING
	DBRA	D6,_DBLBMP
	RTS

PRINT2X:				; routine che stampa
	MOVE.L	#KONEY2X,A5
	CLR	D6		; RESET D6
	MOVE.B	#9,D6			
	ADD.W	#9200,A1		; POSITIONING

LOOP:				; LOOP KE CICLA LA BITMAP
	ADD.W	#16,A1		; POSITIONING
	MOVE.L	(A5)+,(A1)	; QUESTA ISTRUZIONE FA ESPLODERE TUTTO
	ADD.W	#4,A1		; POSITIONING
	MOVE.L	(A5)+,(A1)	; QUESTA ISTRUZIONE FA ESPLODERE TUTTO
	ADD.W	#20,A1		; POSITIONING
	DBRA	D6,LOOP
	RTS

;*******************************************************************************
	SECTION ChipData,DATA_C	;declared data that must be in chipmem
;*******************************************************************************

KONEY:
	DC.L %10001011111011111011111011011000
	DC.L %10010010001010001010000001110000
	DC.L %11100011001011001011111000100000
	DC.L %11010011001011001011000000110000
	DC.L %11001011111011001011111000110000

KONEY2X:
	incbin	"koney10x64.raw"	
	;DS.L 32*2*10	;la bitmap sopra raddoppiata

CARRIAGESTABLE:
	DC.W 0,8,0,8,0,8,0,8,0,8

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

	DC.W $180,$333
	DC.W $2007,$FFFE
	DC.W $180,$444
	DC.W $2507,$FFFE
	DC.W $180,$555
	DC.W $2A07,$FFFE
	DC.W $180,$666
	DC.W $3207,$FFFE
	DC.W $180,$777
	DC.W $3707,$FFFE
	DC.W $180,$888
	DC.W $3C07,$FFFE
	DC.W $180,$888
	DC.W $3F07,$FFFE
	DC.W $180,$999

WAITRAS1:
	DC.W $6007,$FFFE
	DC.W $180,$000
WAITRAS2:
	DC.W $6107,$FFFE
	DC.W $180,$AAA

	DC.W $6807,$FFFE
	DC.W $182,$000
	DC.W $6907,$FFFE
	DC.W $182,$566

	DC.W $7207,$FFFE
	DC.W $180,$FFF
	DC.W $7307,$FFFE
	DC.W $180,$EEE
	DC.W $7407,$FFFE
	DC.W $180,$DDD
	DC.W $7507,$FFFE
	DC.W $180,$CCC
	DC.W $7607,$FFFE
	DC.W $180,$BBB
	DC.W $7707,$FFFE
	DC.W $180,$AAA
	DC.W $7807,$FFFE
	DC.W $180,$999
	DC.W $7907,$FFFE
	DC.W $180,$888
	DC.W $7A07,$FFFE
	DC.W $180,$777
	DC.W $7B07,$FFFE
	DC.W $180,$666
	DC.W $7C07,$FFFE
	DC.W $180,$666
	DC.W $7D07,$FFFE
	DC.W $180,$555
	DC.W $7E07,$FFFE
	DC.W $180,$444
	DC.W $7F07,$FFFE
	DC.W $180,$333

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
	DC.W $F6,0		;FULL 6 PTRS, IN CASE YOU INCREASE BPLS
	DC.W $100,BPLS*$1000+$200	;ENABLE BITPLANES

	DC.W $FFDF,$FFFE		;ALLOW VPOS>$FF
	DC.W $FFFF,$FFFE		;MAGIC VALUE TO END COPPERLIST

CopperE:
;*******************************************************************************
	SECTION	ChipBuffers,BSS_C	;BSS doesn't count toward exe size
;*******************************************************************************

Screen:	ds.b	h*bwid		;Define storage for buffer 1
Screen2:	ds.b	h*bwid		;two buffers

	END