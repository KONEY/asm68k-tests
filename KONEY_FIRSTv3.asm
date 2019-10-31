; KONEY FIRST TEST

start:
	move.l	$4.w,a6		; Execbase in a6
	jsr	-$78(a6)	; Disable - ferma il multitasking
	lea	$dff180,a1	; flash dest in reg0
	lea	$dff182,a2	; flash dest in reg1
mousx:
	btst	#6,$bfe001	; LMB pressed?
	bne.s	moudx		; if FALSE go and check RMB
	beq.s	quit		; if TRUE quit to OS
moudx:
	move.l	a1,a0		; per sikurezza	
	move.l	$dff006,(a0)	; metti VHPOSR in COLOR00 (lampeggio!!)
	btst	#2,$dff016	; POTINP - RMB pressed?
	beq.s	flash2		; Flash su txt
	bra	flash1	
flash2:
	exg	a1,a2		; swap 2 addr registers
flash1:
	bra.s	mousx		; BACK
quit:
	move.l	4.w,a6		; Execbase in a6
	jsr	-$7e(a6)	; Enable - riabilita il Multitasking
	rts

	END
