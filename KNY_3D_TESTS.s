; Lezione10n.s	Disegna una linea
	SECTION	CiriCop,CODE
	;Include	"DaWorkBench.s"	; togliere il ; prima di salvare con "WO"
;*****************************************************************************
	include	"startup1.s"	; Salva Copperlist Etc.
;*****************************************************************************

PIXELSIDE=8
MARGINX=(320/2)
MARGINY=(256/2)
TrigShift=7

VarTimesTrig macro ;3 = 1 * 2, where 2 is cos(Angle)^(TrigShift*2) or sin(Angle)^(TrigShift*2)
	move.l \1,\3
	muls \2,\3

	asr.l #TrigShift,\3 ;left >>= TrigShift
	asr.l #TrigShift,\3
	endm

	INCLUDE	"sincosin_table.i"	; VALUES

POINTS:
	DC.W 0,0,0,5	;
	DC.W 0,5,2,5	;
	DC.W 2,5,2,3	;
	DC.W 2,3,3,3	;
	DC.W 3,3,3,2	;
	DC.W 0,0,1,0	;
	DC.W 1,0,1,2	;
	DC.W 1,2,3,2	;
	DC.W 3,1,4,1	;
	DC.W 3,2,4,2	;
	DC.W 3,3,4,3	;
	DC.W 3,4,4,4	;
	DC.W 4,1,4,2	;
	DC.W 3,3,3,4	;
	DC.W 4,3,4,4	;
	DC.W 4,0,4,1	;
	DC.W 5,0,5,1	;
	DC.W 4,0,5,0	;
	DC.W 4,1,5,1	;
	DC.W 4,4,4,5	;
	DC.W 5,4,5,5	;
	DC.W 4,4,5,4	;
	DC.W 4,5,5,5	;
	DC.W 3,1,3,2	;

		;5432109876543210
DMASET	EQU	%1000001111000000	; copper,bitplane,blitter DMA

START:
	; ** POINTS TO COORDS **
	MOVE.W	#96-1,D1
	LEA	POINTS,A2
	.calcuCoords:
	MOVE.W	(A2),D0
	MULU	#PIXELSIDE,D0
	SUB.W	#(PIXELSIDE*5/2),D0	
	;ADD.W	#MARGIN,D0
	MOVE.W	D0,(A2)+
	DBRA	D1,.calcuCoords
	; ** POINTS TO COORDS **

	; Puntiamo la PIC "vuota"
	MOVE.L	#BITPLANE,d0	; dove puntare
	LEA	BPLPOINTERS,A1	; puntatori COP
	move.w	d0,6(a1)
	swap	d0
	move.w	d0,2(a1)

	lea	$dff000,a5	; CUSTOM REGISTER in a5
	MOVE.W	#DMASET,$96(a5)	; DMACON - abilita bitplane, copper
	move.l	#COPPER,$80(a5)	; Puntiamo la nostra COP
	move.w	d0,$88(a5)	; Facciamo partire la COP
	move.w	#0,$1fc(a5)	; Disattiva l'AGA
	move.w	#$c00,$106(a5)	; Disattiva l'AGA
	move.w	#$11,$10c(a5)	; Disattiva l'AGA

	bsr.w	InitLine		; inizializza line-mode

	move.w	#$ffff,d0		; linea continua
	bsr.w	SetPattern	; definisce pattern

	; **** ROTATING??? ****
	;lea.l	SinTbl(pc),a0
	;move.w	4(a0),d3
	;lea.l	CosTbl(pc),a0
	;move.w	4(a0),d4
	; Rotate around Z Axis:
	;VarTimesTrig d0,d4,d5	;left = rotatedX * cos
	;VarTimesTrig d1,d3,d6	;right = rotatedY * sin
	;move.l	d5,d7		;tmp = left - right
	;sub.l	d6,d7
	;VarTimesTrig d0,d3,d5	;left = rotatedX * sin
	;VarTimesTrig d1,d4,d6	;right = rotatedY * cos
	;move.l	d5,d1		;rotatedY = left + right
	;add.l	d6,d1
	;move.l	d7,d0		;rotatedX = tmp
	; **** ROTATING??? ****

	MOVE.W	#24-1,D7
	LEA	POINTS,A2
	.fetchCoordz:
	MOVE.W	D7,BUFFER7

	MOVE.W	(A2)+,D0		; X1
	MOVE.W	(A2)+,D1		; Y1

	; **** ROTATING??? ****
	lea.l	SinTbl(pc),a0
	ADD.W	ANGLE,A0
	move.w	(a0),d3
	lea.l	CosTbl(pc),a0
	ADD.W	ANGLE,A0
	move.w	(a0),d4
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
	; **** ROTATING??? ****

	MOVE.W	D0,BUFFER0
	MOVE.W	D1,BUFFER1

	MOVE.W	(A2)+,D0		; X2
	MOVE.W	(A2)+,D1		; Y2

	; **** ROTATING??? ****
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
	; **** ROTATING??? ****

	MOVE.W	D0,D2		; X2
	MOVE.W	D1,D3		; Y2
	MOVE.W	BUFFER0,D0
	MOVE.W	BUFFER1,D1

	BSR.W	Drawline
	MOVE.W	BUFFER7,D7
	DBRA	D7,.fetchCoordz

mouse:
	btst	#6,$bfe001	; mouse premuto?
	bne.s	mouse
	rts

;******************************************************************************
; Questa routine effettua il disegno della linea. prende come parametri gli
; estremi della linea P1 e P2, e l'indirizzo del bitplane su cui disegnarla.
; D0 - X1 (coord. X di P1)
; D1 - Y1 (coord. Y di P1)
; D2 - X2 (coord. X di P2)
; D3 - Y2 (coord. Y di P2)
; A0 - indirizzo bitplane
;******************************************************************************
;	    ("`-/")_.-'"``-._
;	     . . `; -._    )-;-,_`)
;	FL  (v_,)'  _  )`-.\  ``-'
;	   _.- _..-_/ / ((.'
;	 ((,.-'   ((,/

Drawline:
	LEA	bitplane,A0
	ADD.W	#MARGINX,D0
	ADD.W	#MARGINY,D1
	ADD.W	#MARGINX,D2
	ADD.W	#MARGINY,D3
	; * scelta ottante
	sub.w	d0,d2		; D2=X2-X1
	bmi.s	DRAW4		; se negativo salta, altrimenti D2=DiffX
	sub.w	d1,d3		; D3=Y2-Y1
	bmi.s	DRAW2		; se negativo salta, altrimenti D3=DiffY
	cmp.w	d3,d2		; confronta DiffX e DiffY
	bmi.s	DRAW1		; se D2<D3 salta..
				; .. altrimenti D3=DY e D2=DX
	moveq	#$10,d5		; codice ottante
	bra.s	DRAWL
DRAW1:
	exg.l	d2,d3		; scambia D2 e D3, in modo che D3=DY e D2=DX
	moveq	#0,d5		; codice ottante
	bra.s	DRAWL
DRAW2:
	neg.w	d3		; rende D3 positivo
	cmp.w	d3,d2		; confronta DiffX e DiffY
	bmi.s	DRAW3		; se D2<D3 salta..
				; .. altrimenti D3=DY e D2=DX
	moveq	#$18,d5		; codice ottante
	bra.s	DRAWL
DRAW3:
	exg.l	d2,d3		; scambia D2 e D3, in modo che D3=DY e D2=DX
	moveq	#$04,d5		; codice ottante
	bra.s	DRAWL
DRAW4:
	neg.w	d2		; rende D2 positivo
	sub.w	d1,d3		; D3=Y2-Y1
	bmi.s	DRAW6		; se negativo salta, altrimenti D3=DiffY
	cmp.w	d3,d2		; confronta DiffX e DiffY
	bmi.s	DRAW5		; se D2<D3 salta..
				; .. altrimenti D3=DY e D2=DX
	moveq	#$14,d5		; codice ottante
	bra.s	DRAWL
DRAW5:
	exg.l	d2,d3		; scambia D2 e D3, in modo che D3=DY e D2=DX
	moveq	#$08,d5		; codice ottante
	bra.s	DRAWL
DRAW6:
	neg.w	d3		; rende D3 positivo
	cmp.w	d3,d2		; confronta DiffX e DiffY
	bmi.s	DRAW7		; se D2<D3 salta..
				; .. altrimenti D3=DY e D2=DX
	moveq	#$1c,d5		; codice ottante
	bra.s	DRAWL
DRAW7:
	exg.l	d2,d3		; scambia D2 e D3, in modo che D3=DY e D2=DX
	moveq	#$0c,d5		; codice ottante

; Quando l'esecuzione raggiunge questo punto, abbiamo:
; D2 = DX
; D3 = DY
; D5 = codice ottante

DRAWL:
	mulu.w	#40,d1		; offset Y
	add.l	d1,a0		; aggiunge l'offset Y all'indirizzo

	move.w	d0,d1		; copia la coordinata X
	and.w	#$000F,d0	; seleziona i 4 bit piu` bassi della X..
	ror.w	#4,d0		; .. e li sposta nei bit da 12 a 15
	or.w	#$0BCA,d0	; con un OR ottengo il valore da scrivere
				; in BLTCON0. Con questo valore di LF ($4A)
				; si disegnano linee in EOR con lo sfondo.

	lsr.w	#4,d1		; cancella i 4 bit bassi della X
	add.w	d1,d1		; ottiene l'offset X in bytes
	add.w	d1,a0		; aggiunge l'offset X all'indirizzo

	move.w	d2,d1		; copia DX in D1
	addq.w	#1,d1		; D1=DX+1
	lsl.w	#$06,d1		; calcola in D1 il valore da mettere in BLTSIZE
	addq.w	#$0002,d1		; aggiunge la larghezza, pari a 2 words

	lsl.w	#$02,d3		; D3=4*DY
	add.w	d2,d2		; D2=2*DX

	btst	#6,2(a5)
WaitLine:
	btst	#6,2(a5)		; aspetta blitter fermo
	bne	WaitLine

	move.w	d3,$62(a5)	; BLTBMOD=4*DY
	sub.w	d2,d3		; D3=4*DY-2*DX
	move.w	d3,$52(a5)	; BLTAPTL=4*DY-2*DX
				; prepara valore da scrivere in BLTCON1
	or.w	#$0001,d5		; setta bit 0 (attiva line-mode)
	tst.w	d3
	bpl.s	OK1		; se 4*DY-2*DX>0 salta..
	or.w	#$0040,d5	; altrimenti setta il bit SIGN
OK1:
	move.w	d0,$40(a5)	; BLTCON0
	move.w	d5,$42(a5)	; BLTCON1
	sub.w	d2,d3		; D3=4*DY-4*DX
	move.w	d3,$64(a5)	; BLTAMOD=4*DY-4*DX
	move.l	a0,$48(a5)	; BLTCPT - indirizzo schermo
	move.l	a0,$54(a5)	; BLTDPT - indirizzo schermo
	move.w	d1,$58(a5)	; BLTSIZE
	rts

;******************************************************************************
; Questa routine setta i registri del blitter che non devono essere
; cambiati tra una line e l'altra
;******************************************************************************

InitLine:
	btst	#6,2(a5)		; dmacon
WBlit_Init:
	btst	#6,2(a5)		; dmaconr - attendi che il blitter abbia finito
	bne.s	Wblit_Init

	moveq.l	#-1,d5
	move.l	d5,$44(a5)	; BLTAFWM/BLTALWM = $FFFF
	move.w	#$8000,$74(a5)	; BLTADAT = $8000
	move.w	#40,$60(a5)	; BLTCMOD = 40
	move.w	#40,$66(a5)	; BLTDMOD = 40
	rts

;******************************************************************************
; Questa routine definisce il pattern che deve essere usato per disegnare
; le linee. In pratica si limita a settare il registro BLTBDAT.
; D0 - contiene il pattern della linea 
;******************************************************************************

SetPattern:
	btst	#6,2(a5)		; dmaconr
WBlit_Set:
	btst	#6,2(a5)		; dmaconr - attendi che il blitter abbia finito
	bne.s	Wblit_Set

	move.w	d0,$72(a5)	; BLTBDAT = pattern della linea!
	rts

;****************************************************************************
ANGLE:	DC.W 24
BUFFER0:	DC.W 0
BUFFER1:	DC.W 0
BUFFER7:	DC.W 0

	SECTION	GRAPHIC,DATA_C

COPPER:
	dc.w	$8E,$2c81		; DiwStrt
	dc.w	$90,$2cc1		; DiwStop
	dc.w	$92,$38		; DdfStart
	dc.w	$94,$d0		; DdfStop
	dc.w	$102,0		; BplCon1
	dc.w	$104,0		; BplCon2
	dc.w	$108,0		; Bpl1Mod
	dc.w	$10a,0		; Bpl2Mod

	dc.w	$100,$1200	; Bplcon0 - 1 bitplane lowres

BPLPOINTERS:
	dc.w	$e0,$0000,$e2,$0000	;primo	 bitplane

	dc.w	$180,$002		; color0
	dc.w	$182,$FFF		; color1
	dc.w	$FFFF,$FFFE	; Fine della copperlist

;****************************************************************************

	Section	IlMioPlane,bss_C

BITPLANE:
	ds.b	40*256		; bitplane azzerato lowres

	end

;****************************************************************************

In questo esempio presentiamo il tracciamento di linee. Esso viene realizzato
mediante 3 diverse routines.
La routine "InitLine" setta i registri il cui contenuto e` indipendente dai
parametri della linea (gli estremi) e che pertanto possono essere setati una
volta sola all'inizio del programma.
La routine "SetPattern" definisce il pattern da usare per una linea. Ogni
volta che si desidera usare un pattern diverso si deve eseguire questa 
routine. Al contrario, se ci sono diverse linee da tracciare con lo stesso
pattern questa routine puo` essere eseguita una sola volta.
La routine "Drawline" e` la routine che disegna effetivamente la linea ed
e` anche la piu` complessa. All'inizio vengono calcolati DX e DY e in base alle
coordinate degli estremi, e viene determinato il codice ottante da usare.
Per compiere queste operazioni sono necessari una serie di sottrazioni e di
confronti che prendono in esame tutti i possibili casi.
Successivamente vengono calcolati i valori da inserire negli altri registri,
come spiegato nei commenti.
Notate che viene usato LF=$4A, il che provoca un EOR tra la linea e lo sfondo.
Lo potete notare osservando le 2 linee che si intersecano: l'intersezione e`
un pixel di valore 0. Se provate a porre LF=$CA noterete che l'intersezione
e` invece un pixel di valore 1.

