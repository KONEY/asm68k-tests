;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000
; This program shows how to use the proplayer routines in an assembler
; program.
	INCDIR	"NAS:AMIGA/CODE/KONEY/"
; It loads a file, named 'module' (you can change this if you want),
; and plays it until you press the left mouse button.
; link with modplayer.o and loadmod.o

	;xref	_LoadModule
	;xref	_UnLoadModule
	;xref	_PlayModule
	;xref	_InitPlayer
	;xref	_RemPlayer

	SECTION	"Code",CODE

	movem.l	d0-d7/a0-a6,-(sp)
	jsr	_InitPlayer
	lea	easymod,a0
	jsr	_PlayModule

	;CLR.W	$100		; DEBUG | w 0 100 2
	waitmb:
	MOVE.W	#$A0F,$DFF180	; show rastertime left down to $12c
	BTST	#6,$BFE001
	bne.s	waitmb

	jsr	_RemPlayer
	movem.l	(sp)+,d0-d7/a0-a6
	rts

	INCLUDE "med/proplayer.a"

	section "ChipData",data_c		;,chip ;for A68k
easymod:	INCBIN "med/octamed_test.med"	;<<<<< MODULE NAME HERE!

	end
