;vasmm68k_mot -nosym -devpac -kick1hunks -Fhunkexe -o C RotateCube.s  
	Section Cube2,code_c
	INCLUDE	"Blitter-Register-List.S"
ZScaleShift=7
XScreenOrigin=150
YScreenOrigin=110
ZCenterIn3DSpace=170
PointOffs=55
TrigShift=7
PointCnt=8
LineCnt=5

VarTimesTrig macro ;3 = 1 * 2, where 2 is cos(Angle)^(TrigShift*2) or sin(Angle)^(TrigShift*2)
	move.l \1,\3
	muls \2,\3

	asr.l #TrigShift,\3 left >>= TrigShift
	asr.l #TrigShift,\3
	endm

;************** Start Up Code from *********************
; http://www.palbo.dk/dataskolen/maskinsprog/DISK1.LHA
;***************************************************

	move.w	#$4000,INTENA

	or.b	#%10000000,$bfd100
	and.b	#%10000111,$bfd100

	move.w	#$01a0,DMACON

	move.w	#$1200,BPLCON0
	move.w	#$0000,BPLCON1
	move.w	#$003f,BPLCON2
	move.w	#0,$dff108
	move.w	#0,$dff10a
	move.w	#$2c81,$dff08e
	move.w	#$f4c1,$dff090
	move.w	#$38c1,$dff090
	move.w	#$0038,$dff092
	move.w	#$00d0,$dff094

	lea.l	screen,a1
	lea.l	bplcop,a2
	move.l	a1,d1
	move.w	d1,6(a2)
	swap	d1
	move.w	d1,2(a2)

	lea.l	copper,a1
	move.l	a1,COP1LC
	move.w	$dff088,d0
	move.w	#$81a0,DMACON

	move.w	#0,Angle

wait:
	move.l	$dff004,d0
	asr.l	#8,d0
	and.l	#$1ff,d0
	cmp.w	#0,d0
	bne	wait

wait2:
	move.l	VPOSR,d0
	asr.l	#8,d0
	and.l	#$1ff,d0
	cmp.w	#1,d0
	bne	wait2

	bsr	RotateCube

	btst	#6,$bfe001
	bne	wait

	move.w	#$0080,DMACON

	move.l	$04,a6
	move.l	156(a6),a1
	move.l	38(a1),COP1LC

	move.w	#$8080,DMACON

	move.w	#$c000,INTENA
	rts

;***************************************************

RotateCube:
	bsr	ClearScreen
	cmp.w	#CosTblSz,Angle
	bne	.AngleOK
	move.w	#0,Angle
	.AngleOK:
	bsr	CalculatePoints
	bsr	DrawCube

	add.w	#2,Angle  ;Add 2 since sin/cos table is in words
	rts

;***************************************************

CalculatePoints:	;Rotates, projects, and put points into XYScreenCoords
	move.w	Angle,d0
	lea.l	SinTbl(pc),a0
	move.w	(a0,d0),d3
	lea.l	CosTbl(pc),a0
	move.w	(a0,d0),d4
	lea.l	XYZin3D(pc),a0
	lea.l	XYScreenCoords(pc),a1
	move.b	#PointCnt,LoopCntr
.loopAllPoints:
	; d0=X, d1=Y, d2=Z, d3=sin, d4=cos, d5=left, d6=right, d7=tmp
	; a0=XYZin3D, a1=XYScreenCoords, a2-a6=[]
	move.w	(a0)+,d0		;X in 3D, relative to cube's origin
	move.w	(a0)+,d1		;Y in 3D, relative to cube's origin
	move.w	(a0)+,d2		;Z in 3D, relative to cube's origin

	; Rotate around Z Axis:
	VarTimesTrig d0,d4,d5	;left = rotatedX * cos
	VarTimesTrig d1,d3,d6	;right = rotatedY * sin

	move.l	d5,d7		;tmp = left - right
	sub.l	d6,d7

	VarTimesTrig d0,d3,d5	;left = rotatedX * sin
	VarTimesTrig d1,d4,d6	;right = rotatedY * cos

	move.l	d5,d1		;rotatedY = left + right
	add.l	d6,d1

	move.l	d7,d0		;rotatedX = tmp

	; Adjust for where point is in space:
	add.w	#ZCenterIn3DSpace,d2

	; Project onto 2D:
	lsl.w	#ZScaleShift,d0	;Faster to shift than to multiply
	divs	d2,d0

	lsl.w	#ZScaleShift,d1	;Faster to shift than to multiply
	divs	d2,d1

	; Convert to screen coordinates:
	add.w	#XScreenOrigin,d0
	add.w	#YScreenOrigin,d1

	; Store off coordinates:
	move.w	d0,(a1)+
	move.w	d1,(a1)+

	sub.b	#1,LoopCntr
	bne	.loopAllPoints
	rts

;***************************************************

DrawCube:
	jsr	INITLINE
	lea.l	Edges(pc),a0
	lea.l	XYScreenCoords(pc),a1
	moveq	#LineCnt-1,d5
	.loopEdges:
	move.w	(a0)+,d4		;source point index
	move.w	(a1,d4),d0	;get x1
	move.w	2(a1,d4),d1	;get y1

	move.w	(a0)+,d4		;dest point index
	move.w	(a1,d4),d2	;get x2
	move.w	2(a1,d4),d3	;get y2

	; **** MOCKED VALUES ****
	;MOVE.W	#0,D0		; X1
	;MOVE.W	#255,D1		; Y1
	;MOVE.B	#255,D2	; X2
	;MOVE.B	0,D3	; Y2
	; **** MOCKED VALUES ****

	jsr	DRAWLINE

	dbf	d5,.loopEdges
	rts

;***************************************************

ClearScreen:
	.WAIT:	
	BTST	#$E,$dff002
	BNE.S	.WAIT
	move.w	#$09f0,BLTCON0	;A**,Shift 0, A -> D
	move.w	#0,BLTCON1	;Everything Normal
	move.w	#0,BLTAMOD	;Init modulo Sou. A
	move.w	#0,BLTDMOD	;Init modulo Dest D
	move.l	#Empty,BLTAPTH	;Source
	move.l	#screen,BLTDPTH	;Dest
	move.w	#(ScreenHeight*64)+(ScreenWidth/16),BLTSIZE	;Start Blitter (Blitsize)
	rts

;***************************************************

copper:
	dc.w $2c01,$fffe
	dc.w $0100,$1200

bplcop:
	dc.w $00e0,$0000
	dc.w $00e2,$0000

	dc.w $0180,$099A
	dc.w $0182,$0000

	dc.w $ffdf,$fffe
	dc.w $2c01,$fffe
	dc.w $0100,$0200
	dc.w $ffff,$fffe

ScreenHeight=256
ScreenWidth=320
ScreenWidthBytes=ScreenWidth/8
BplSize=ScreenWidthBytes*ScreenHeight

screen:	dcb.b BplSize,0
Empty:	dcb.b BplSize,0

LoopCntr:	dc.b 0
	even

Angle:	dc.w 0

XYZin3D:	dc.w -PointOffs,PointOffs,PointOffs	;a 0 Relative to cube's origin
	dc.w PointOffs,PointOffs,PointOffs	;b 1
	dc.w PointOffs,PointOffs,-PointOffs	;c 2
	dc.w -PointOffs,PointOffs,-PointOffs	;d 3
	dc.w -PointOffs,-PointOffs,PointOffs	;e 4
	dc.w PointOffs,-PointOffs,PointOffs	;f 5
	dc.w PointOffs,-PointOffs,-PointOffs	;g 6
	dc.w -PointOffs,-PointOffs,-PointOffs	;h 7

XYScreenCoords:	dcb.w PointCnt*2,0

Edges:	;multiply w/ 2 since word=2 bytes & w/ 2 since both X & Y stored in XYScreenCoords
	;dc.w 2*2*2,3*2*2	;a->b
	;dc.w 3*2*2,7*2*2	;b->c
	;dc.w 7*2*2,6*2*2	;c->d
	;dc.w 6*2*2,2*2*2	;d->a
	;dc.w 2*2*2,7*2*2	;a->c	DIAG
	;dc.w 3*2*2,6*2*2	;b->d	DIAG

	;dc.w 0*2*2,4*2*2	; LEFT
	DC.B 0,0,0,16	; LEFT
	DC.B 0,16,0,20	; TOP
	DC.B 0,20,0,4	; RIGHT
	DC.B 0,4,0,0	; BOTTOM

	DC.w 3*2*2,0	; LEFT

	;dc.w 3*2*2,0*2*2	;d->a
	;dc.w 0*2*2,1*2*2	;a->b
	;dc.w 0*2*2,4*2*2	;a->e
	;dc.w 4*2*2,5*2*2	;e->f
	;dc.w 5*2*2,6*2*2	;f->g

	;dc.w 7*2*2,4*2*2	;h->e
	;dc.w 1*2*2,5*2*2	;b->f
	;dc.w 1*2*2,2*2*2	;b->c

SinTbl:	dc.w 0,572,1143,1713,2280,2845,3406,3964,4516,5063
	dc.w 5604,6138,6664,7182,7692,8192,8682,9162,9630,10087
	dc.w 10531,10963,11381,11786,12176,12551,12911,13255,13583,13894
	dc.w 14189,14466,14726,14968,15191,15396,15582,15749,15897,16026
	dc.w 16135,16225,16294,16344,16374
CosTbl:	dc.w 16384,16374,16344,16294,16225,16135,16026,15897,15749,15582
	dc.w 15396,15191,14968,14726,14466,14189,13894,13583,13255,12911
	dc.w 12551,12176,11786,11381,10963,10531,10087,9630,9162,8682
	dc.w 8192,7692,7182,6664,6138,5604,5063,4516,3964,3406
	dc.w 2845,2280,1713,1143,572,0,-572,-1143,-1713,-2280
	dc.w -2845,-3406,-3964,-4516,-5063,-5604,-6138,-6664,-7182,-7692
	dc.w -8192,-8682,-9162,-9630,-10087,-10531,-10963,-11381,-11786,-12176
	dc.w -12551,-12911,-13255,-13583,-13894,-14189,-14466,-14726,-14968,-15191
	dc.w -15396,-15582,-15749,-15897,-16026,-16135,-16225,-16294,-16344,-16374
	dc.w -16384,-16374,-16344,-16294,-16225,-16135,-16026,-15897,-15749,-15582
	dc.w -15396,-15191,-14968,-14726,-14466,-14189,-13894,-13583,-13255,-12911
	dc.w -12551,-12176,-11786,-11381,-10963,-10531,-10087,-9630,-9162,-8682
	dc.w -8192,-7692,-7182,-6664,-6138,-5604,-5063,-4516,-3964,-3406
	dc.w -2845,-2280,-1713,-1143,-572,0,572,1143,1713,2280
	dc.w 2845,3406,3964,4516,5063,5604,6138,6664,7182,7692
	dc.w 8192,8682,9162,9630,10087,10531,10963,11381,11786,12176
	dc.w 12551,12911,13255,13583,13894,14189,14466,14726,14968,15191
	dc.w 15396,15582,15749,15897,16026,16135,16225,16294,16344,16374
EndCosTbl:

CosTblSz=EndCosTbl-CosTbl

;************** Drawline code from ************************
; http://coppershade.org/asmskool/SOURCES/full-examples/Promax-Asm-One-Examples/LineDraw.S
;**********************************************************

SINGLE=0

INITLINE:
	.WAIT:	
	BTST	#$E,$DFF002
	BNE.S	.WAIT

	MOVEQ	#-1,D1
	MOVE.L	D1,BLTAFWM		; FirstLastMask
	MOVE.W	#$8000,BLTADAT		; BLT data A
	MOVE.W	#ScreenWidthBytes,BLTCMOD	; Tot.Screen Width
	;MOVE.W	#AAAA,BLTBDAT		; LINE TEXTURE
	MOVE.W	#$FFFF,BLTBDAT		; LINE TEXTURE
	LEA.L	screen,A5
	RTS

; USES D0/D1/D2/D3/D4/D7/A5/A6
DRAWLINE:
	SUB.W	D3,D1
	MULU	#ScreenWidthBytes,D3 ; ScreenWidth * D3

	MOVEQ	#$F,D4
	AND.W	D2,D4		; Get lowest bits from D2

	;--------- SELECT OCTANT ---------

	SUB.W	D2,D0
	BLT.S	DRAW_DONT0146
	TST.W	D1
	BLT.S	DRAW_DONT04

	CMP.W	D0,D1
	BGE.S	DRAW_SELECT0
	MOVEQ	#$11+SINGLE,D7	; Select Oct 4
	BRA.S	DRAW_OCTSELECTED

DRAW_SELECT0:
	MOVEQ	#1+SINGLE,D7	; Select Oct 0
	EXG	D0,D1
	BRA.S	DRAW_OCTSELECTED
DRAW_DONT04:
	NEG.W	D1
	CMP.W	D0,D1
	BGE.S	DRAW_SELECT1
	MOVEQ	#$19+SINGLE,D7	; Select Oct 6
	BRA.S	DRAW_OCTSELECTED
DRAW_SELECT1:
	MOVEQ	#5+SINGLE,D7	; Select Oct 1
	EXG	D0,D1
	BRA.S	DRAW_OCTSELECTED
DRAW_DONT0146:
	NEG.W	D0
	TST.W	D1
	BLT.S	DRAW_DONT25
	CMP.W	D0,D1
	BGE.S	DRAW_SELECT2
	MOVEQ	#$15+SINGLE,D7	; Select Oct 5
	BRA.S	DRAW_OCTSELECTED
DRAW_SELECT2:
	MOVEQ	#9+SINGLE,D7	; Select Oct 2
	EXG	D0,D1
	BRA.S	DRAW_OCTSELECTED
DRAW_DONT25:
	NEG.W	D1
	CMP.W	D0,D1
	BGE.S	DRAW_SELECT3
	MOVEQ	#$1D+SINGLE,D7	; Select Oct 7
	BRA.S	DRAW_OCTSELECTED
DRAW_SELECT3:
	MOVEQ	#$D+SINGLE,D7	; Select Oct 3
	EXG	D0,D1

;---------   CALCULATE START   ---------
DRAW_OCTSELECTED:
	ADD.W	D1,D1		; 2*dy
	ASR.W	#3,D2		; x=x/8
	EXT.L	D2
	ADD.L	D2,D3		; d3 = x+y*40 = screen pos
	MOVE.W	D1,D2		; d2 = 2*dy
	SUB.W	D0,D2		; d2 = 2*dy-dx
	BGE.S	DRAW_DONTSETSIGN
	ORI.W	#$40,D7		; dx < 2*dy

DRAW_DONTSETSIGN:
	;---------   SET BLITTER   ---------
	.WAIT:
	BTST	#$E,$DFF002	; Wait on the blitter
	BNE.S	.WAIT

	; **** MOCKED VALUES ****
	;MOVE.W	#520,D2		; BLTAPTL
	;MOVE.W	#1020,D1		; BLTBMOD
	;MOVE.W	#0,D5		; BLTAMOD
	; **** MOCKED VALUES ****

	MOVE.W	D2,BLTAPTL	; 2*dy-dx
	MOVE.W	D1,BLTBMOD	; 2*d2
	SUB.W	D0,D2		; d2 = 2*dy-dx-dx
	MOVE.W	D2,BLTAMOD	; 2*dy-2*dx

	;---------   MAKE LENGTH   ---------

	ASL.W	#6,D0		; d0 = 64*dx
	ADD.W	#$0042,D0	; d0 = 64*(dx+1)+2

	;---------   MAKE CONTROL 0+1   ---------

	ROR.W	#4,D4
	ORI.W	#%101111101010,D4	; $B4A - DMA + Minterm
	SWAP	D7
	MOVE.W	D4,D7
	SWAP	D7
	ADD.L	A5,D3		; SCREEN PTR

	MOVE.L	D7,BLTCON0	; BLTCON0 + BLTCON1
	MOVE.L	D3,BLTCPTH	; Source C
	MOVE.L	D3,BLTDPTH	; Destination D
	MOVE.W	D0,BLTSIZE	; Size
	CLR.W	$100		; DEBUG | w 0 100 2
	RTS