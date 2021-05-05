	; **** JOYSTICK TEST ****
	MOVEM.W	$DFF00C,D0	; FROM EAB
	ANDI.W	#$0303,D0
	MOVE.W	D0,D1
	ADD.W	D1,D1
	ADDI.W	#$0101,D0
	ADD.W	D1,D0
	BTST	#9,D0		; 9 LEFT
	BEQ.S	.notLeft
	SUBI.W	#2,ANGLE
	BSR.W	__START_STROBO
	.notLeft:
	BTST	#1,D0		; 1 RIGHT
	BEQ.S	.notRight
	ADDI.W	#2,ANGLE
	BSR.W	__STOP_STROBO
	.notRight:
	BTST	#10,D0		; 10 UP
	BEQ.S	.notDown
	SUBI.W	#2,Z_POS
	.notDown:
	BTST	#2,D0		; 2 DOWN
	BEQ.S	.notUp
	ADDI.W	#2,Z_POS
	.notUp:
	; **** JOYSTICK TEST ****