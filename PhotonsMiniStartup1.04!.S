;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000
*** MiniStartup by Photon ***
	INCDIR	"NAS:AMIGA/CODE/KONEY/"
	INCLUDE "PhotonsMiniWrapper1.04!.S"
********** Constants **********

;	INCLUDE "Blitter-Register-List.S"	;use if you like ;)

w	=320				;screen width, height, depth
h	=256
bpls	=3					;handy values:
bpl	=w/16*2				;byte-width of 1 bitplane line
bwid	=bpls*bpl			;byte-width of 1 pixel line (all bpls)

********** Macros **********

WAITBLIT:macro
	tst.w (a6)			;for compatibility with A1000
.wb\@:	btst #6,2(a6)
	bne.s .wb\@
	endm

********** Demo **********		;Demo-specific non-startup code below.

Demo:					;a4=VBR, a6=Custom Registers Base addr
	*--- init ---*
	move.l #VBint,$6c(a4)
	move.w #$c020,$9a(a6)
	move.w #$87c0,$96(a6)
	*--- clear screens ---*
	lea Screen,a1
	bsr.w ClearScreen
	lea Screen2,a1
	bsr.w ClearScreen
	bsr WaitBlitter
	*--- start copper ---*
	lea Screen,a0
	moveq #bpl,d0
	lea BplPtrs+2,a1
	moveq #bpls-1,d1
	bsr.w PokePtrs

	move.l #Copper,$80(a6)

********************  main loop  ********************
MainLoop:
	move.w #$12c,d0			;No buffering, so wait until raster
	bsr.w WaitRaster			;is below the Display Window.
	*--- swap buffers ---*
	movem.l DrawBuffer(PC),a2-a3
	exg a2,a3
	movem.l a2-a3,DrawBuffer	;draw into a2, show a3
	*--- show one... ---*
	move.l a3,a0
	moveq #bpl,d0
	lea BplPtrs+2,a1
	moveq #bpls-1,d1
	bsr.w PokePtrs
	*--- ...draw into the other(a2) ---*
	move.l a2,a1
	bsr ClearScreen
	bsr WaitBlitter

; do stuff here :)

	*--- main loop end ---*
	move.w #$323,$180(a6)		;show rastertime left down to $12c
	btst #6,$bfe001				;Left mouse button not pressed?
	bne.w MainLoop				;then loop
	*--- exit ---*
	rts

********** Demo Routines **********

PokePtrs:				;Generic, poke ptrs into copper list
.bpll:	move.l a0,d2
	swap d2
	move.w d2,(a1)		;high word of address
	move.w a0,4(a1)		;low word of address
	addq.w #8,a1			;skip two copper instructions
	add.l d0,a0			;next ptr
	dbf d1,.bpll
	rts

ClearScreen:						;a1=screen destination address to clear
	bsr WaitBlitter
	clr.w $66(a6)					;destination modulo
	move.l #$01000000,$40(a6)	;set operation type in BLTCON0/1
	move.l a1,$54(a6)			;destination address
	move.w #h*bpls*64+bpl/2,$58(a6)	;blitter operation size
	rts

VBint:						;Blank template VERTB interrupt
	movem.l d0/a6,-(sp)		;Save used registers
	lea $dff000,a6
	btst #5,$1f(a6)			;check if it's our vertb int.
	beq.s .notvb
	*--- do stuff here ---*
	moveq #$20,d0			;poll irq bit
	move.w d0,$9c(a6)
	move.w d0,$9c(a6)
.notvb:	movem.l (sp)+,d0/a6	;restore
	rte

********** Fastmem Data **********
DrawBuffer:	dc.l Screen2		;pointers to buffers to be swapped
ViewBuffer:	dc.l Screen

*******************************************************************************
	SECTION ChipData,DATA_C		;declared data that must be in chipmem
*******************************************************************************

Copper:
	dc.w $1fc,0			;Slow fetch mode, remove if AGA demo.
	dc.w $8e,$2c81		;238h display window top, left
	dc.w $90,$2cc1		;and bottom, right.
	dc.w $92,$38			;Standard bitplane dma fetch start
	dc.w $94,$d0			;and stop for standard screen.

	dc.w $106,$0c00		;(AGA compat. if any Dual Playf. mode)
	dc.w $108,bwid-bpl	;modulos
	dc.w $10a,bwid-bpl

	dc.w $102,0			;Scroll register (and playfield pri)

Palette:					;Some kind of palette (3 bpls=8 colors)
	dc.w $180,$000		;black
	dc.w $182,$00f		;blue
	dc.w $184,$0f0		;green
	dc.w $186,$0ff		;cyan
	dc.w $188,$f00		;red
	dc.w $18a,$f0f		;magenta
	dc.w $18c,$ff0		;yellow
	dc.w $18e,$fff		;white

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
	dc.w $f6,0			;full 6 ptrs, in case you increase bpls
	dc.w $100,bpls*$1000+$200	;enable bitplanes

	dc.w $ffdf,$fffe		;allow VPOS>$ff
	dc.w $ffff,$fffe		;magic value to end copperlist

CopperE:
*******************************************************************************
	SECTION ChipBuffers,BSS_C	;BSS doesn't count toward exe size
*******************************************************************************

Screen:	ds.b h*bwid			;Define storage for buffer 1
Screen2:ds.b h*bwid			;two buffers

	END
