COPJMP1	EQU	$0088
COPJMP2	EQU	$008a
COP1LCH	EQU	$dff080
COP2LCH	EQU	$dff084

Init:	;Very small startup by Photon/Scoopex youtube tutorial
	move.l	4.w,a6		; execbase
	clr.l	d0
	move.l	#gfxname,a1
	jsr	-408(a6)	; oldopenlibrary()
	move.l	d0,a6
	move.l	38(a6),d4	; original copper pointer

	jsr	-414(a6)	; closelibrary()

	move	$df001c,d5	; save INTENA
	move	#$7fff,$dff09a	; disable all bits in INTENA

	move.l	#Picture,D0
	lea	Copper\.Bitpointer+6,A0
	move.w	D0,(a0)
	swap	D0
	sub.l	#4,A0
	move.w	D0,(a0)

	move.l	#Copper,COP1LCH	; set copper 1 address

Set_CopperJumps_in_Copper_List:
	lea.l	Copper\.COPJMP1-2,a0	; set copper 2 to CopJmp1 in copper list
	move.l	#Copper\.CopJmp1,d0
	move.w	d0,(a0)
	swap	d0
	move.w	d0,-4(a0)	

	lea.l	Copper\.COPJMP2-2,a0	; set copper 2 to CopJmp2 in copper list
	move.l	#Copper\.CopJmp2,d0
	move.w	d0,(a0)
	swap	d0
	move.w	d0,-4(a0)	

	lea.l	Copper\.COPJMP3-2,a0	; set copper 2 to CopJmp3 in copper list
	move.l	#Copper\.CopJmp3,d0
	move.w	d0,(a0)
	swap	d0
	move.w	d0,-4(a0)	

;*****************************
mainloop:
wframe:
	btst	#0,$dff005
	bne	wframe
	cmp.b	#$2c,$dff006
	bne	wframe

waitmouse:
	btst	#6,$bfe001
	bne	mainloop
;*****************************

exit:
	move.l	d4,$dff080	; restore copper pointer
	or	#$C000,d5	; Shift bit 14 and 15.
	move	d5,$dff09a	; set INTENA
	rts

gfxname:
	dc.b	"graphics.library",0

	SECTION Copper,DATA_C
Copper:
	dc.l	$008E2C81,$00902CC1	;DIWSTRT and DIWSTOP
	dc.l	$00920038,$009400d0	;DDFSTRT and DDFSTOP
	dc.l	$01001200,$01020000	;blitcon 0 and 1 (1200 = 1 bpl)
	dc.l	$01060000,$010C0011		;blitcon 3 and 4
	.Bitpointer:
	dc.l	$00E00000,$00E20000

	dc.w	$0108,0000,$010A,0000	; bitplan modulo (0 = no interlieve)
	dc.l	$01FC0000			;Fetchmode Register

	.Colors:	
	dc.w	$0180,$0000,$0182,$0FFF	; set colors 

	.CopperBarStart:
	dc.w	$2c01,$ff00		; wait for line $2C

	dc.w	$0084,$0000,$0086,$0000	;Set COP2LCH
	.COPJMP1:				;split 1
	dc.w	$003f,$80fe
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$0000
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$0000
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$0000
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$0000
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$0000
	dc.w	$0180,$0000

	dc.w	$7fe1,$7fff		; If line is reach, skip next command
	dc.w	COPJMP2,$0		; Jump to CopJmp1 as set in COP2LCH

	dc.w	$0084,$0000,$0086,$0000	;Set COP2LCH
	.COPJMP2:			;split 2
	dc.w	$803f,$80fe
	dc.w	$0180,$0000
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$00f0
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$00f0
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$00f0
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$00f0
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$00f0
	;dc.w	$0180,$0000

	dc.w	$ff01,$7fff		; If last pal line is reached, skip next command
	dc.w	COPJMP2,$0		; Jump to CopJmp2 as set in COP2LCH

	dc.w	$803f,$80fe		;set last line before PAL split
	dc.w	$0180,$0000
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$00f0
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$00f0
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$00f0
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$00f0
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$00f0
	;dc.w	$ffe1,$fffe		; wait for PAL split. (not needed)

	dc.w	$0084,$0000,$0086,$0000	;Set COP2LCH
	.COPJMP3:			;Split 3
	dc.w	$003f,$80fe
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$0000
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$0000
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$0000
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$0000
	dc.w	$0180,$000f,$0180,$00ff,$0180,$00f0,$0180,$0ff0
	dc.w	$0180,$0f00,$0180,$0f0f,$0180,$0fff,$0180,$0000
	dc.w	$0180,$0000

	dc.w	$2be1,$7fff
	dc.w	COPJMP2,$0		; Jump to CopJmp3 as set in COP2LCH

	dc.w	$ffff,$fffe		; END COPPER
Picture:
	ds.b	10240
