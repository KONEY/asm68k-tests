;*** TESTS FOR HD !
;*** MiniStartup by Photon ***
	INCDIR	"NAS:AMIGA/CODE/KONEY/"
	SECTION	"Code",CODE
	INCLUDE	"Blitter-Register-List.S"
	INCLUDE	"PhotonsMiniWrapper1.04!.S"
;********** Constants **********
w=640		;screen width, height, depth
h=512
bpls=3		;handy values:
bpl=w/16*2	;byte-width of 1 bitplane line (80)
bwid=bpls*bpl	;byte-width of 1 pixel line (all bpls)

;********** Demo **********	; Demo-specific non-startup code below.
Demo:	;a4=VBR, a6=Custom Registers Base addr
	;*--- init ---*
	move.l	#VBint,$6c(a4)
	move.w	#%1110000000100000,INTENA
	;** SOMETHING INSIDE HERE IS NEEDED TO MAKE MOD PLAY! **
	;move.w	#%1110000000000000,INTENA	; Master and lev6	; NO COPPER-IRQ!
	move.w	#%1000011111000000,DMACON

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
	bsr	WaitBlitter

	; ** CODE FOR HI-RES **************************************
	;MOVE.L	#$1FF00,D1	; bit per la selezione tramite AND
	;MOVE.L	#$01000,D2	; linea da aspettare = $010
	;Waity1:
	;MOVE.L	VPOSR,D0		; VPOSR e VHPOSR - $dff004/$dff006
	;AND.L	D1,D0		; Seleziona solo i bit della pos. verticale
	;CMP.L	#0,D0		; aspetta la linea $010
	;BNE.S	Waity1

	MOVE.L	KONEYBG,D3	; Indirizzo bitplane
	;BTST.B	#15-8,VPOSR	; VPOSR LOF bit?
	MOVE.W	IsLineEven,D7	; GET ODD/EVEN BIT
	NOT.W	D7		; CHANGE IT
	MOVE.W	D7,IsLineEven	; PUT IT BACK
	CMPI.W	#0,D7		; IF 0 SKIP A LINE
	BEQ.S	.skipLine		; Se si, tocca alle linee dispari
	ADD.L	#bpl,D3		; Oppure aggiungi la lunghezza di una linea,
	.skipLine:

	; ** CODE FOR HI-RES **************************************
	MOVE.L	D3,DrawBuffer

	; do stuff here :)

	;CLR.W	$100		; DEBUG | w 0 100 2
	CLR.W	$100		; THIS IS NEEDED FOR HI-RES... LOL!!

	;*--- main loop end ---*
	BTST	#6,$BFE001
	BNE.S	.DontShowRasterTime
	MOVE.W	#$0F0,$180(A6)	; show rastertime left down to $12c
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
	move.w	d2,(a1)		; high word of address
	move.w	a0,4(a1)		; low word of address
	addq.w	#8,a1		; skip two copper instructions
	add.l	d0,a0		; next ptr
	dbf	d1,.bpll
	rts

ClearScreen:			; a1=screen destination address to clear
	bsr	WaitBlitter
	clr.w	$66(a6)		; destination modulo
	move.l	#$01000000,$40(a6)	; set operation type in BLTCON0/1
	move.l	a1,$54(a6)	; destination address
	move.l	#h*bpls*64+bpl/2,$58(a6)	;blitter operation size
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

	RTS

;********** Fastmem Data **********
IsLineEven:	DC.W 0
KONEYBG:		DC.L BG1		; INIT BG
DrawBuffer:	DC.L SCREEN2	; pointers to buffers to be swapped
ViewBuffer:	DC.L SCREEN1

;*******************************************************************************
	SECTION "ChipData",DATA_C	;declared data that must be in chipmem
;*******************************************************************************

BG1:	INCBIN	"klogo_hd.raw"

Copper:
	DC.W $1FC,0	;Slow fetch mode, remove if AGA demo.
	DC.W $8E,$2C81	;238h display window top, left
	DC.W $90,$2CC1	;and bottom, right.
	DC.W $92,$3C	;Standard bitplane dma fetch start
	DC.W $94,$D4	;and stop for standard screen.

	DC.W $106,$0C00	;(AGA compat. if any Dual Playf. mode)
	DC.W $108,bpl	;bwid-bpl	;modulos
	DC.W $10A,bpl	;bwid-bpl	;RISULTATO = 80 ?

	DC.W $102,0	;SCROLL REGISTER (AND PLAYFIELD PRI)
	DC.W $104,0	;BplCon2
	;DC.W $100,bpls*$1000+$200	;enable bitplanes
	DC.W $100,%1011001000000100	; BPLCON0 1011 0010 0000 0100

Palette:	DC.W $0180,$0FFF,$0182,$0CCC,$0184,$0999,$0186,$0666
	DC.W $0188,$0444,$018A,$0333,$018C,$0222,$018E,$0000

BplPtrs:	DC.W $E0,0
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
	DC.W $F6,0



	DC.W $FFFF,$FFFE	;magic value to end copperlist
_Copper:

;*******************************************************************************
	SECTION "ChipBuffers",BSS_C	;BSS doesn't count toward exe size
;*******************************************************************************

SCREEN1:		DS.B h*bwid	; Define storage for buffer 1
SCREEN2:		DS.B h*bwid	; two buffers

	END