;	KONEY - SIMPLE DITHERING LOOP
	SECTION		CiriCop,CODE

Inizio:
	CLR	D0
	CLR	D4
	CLR	D5
	CLR	D6		; CLEAR D6 FOR LOOP
	MOVE.B	#6,D6		; PUT FONT HEIGHT IN D6 FOR LATER LOOP
	move.l	4.w,a6		; Execbase in a6
	jsr	-$78(a6)	; Disable - ferma il multitasking
	lea	GfxName(PC),a1	; Indirizzo del nome della lib da aprire in a1
	jsr	-$198(a6)	; OpenLibrary
	move.l	d0,GfxBase	; salvo l'indirizzo base GFX in GfxBase
	move.l	d0,a6
	move.l	$26(a6),OldCop	; salviamo l'indirizzo della copperlist vecchia

	;PUNTIAMO IL NOSTRO BITPLANE

	MOVE.L	#BITPLANE,d0	; in d0 mettiamo l'indirizzo della PIC,
	LEA	BPLPOINTERS,A1	; puntatori nella COPPERLIST
	move.w	d0,6(a1)	; copia la word BASSA dell'indirizzo del plane
	swap	d0		; scambia le 2 word di d0 (es: 1234 > 3412)
	move.w	d0,2(a1)	; copia la word ALTA dell'indirizzo del plane

	move.l	#COPPERLIST,$dff080	; Puntiamo la nostra COP
	move.w	d0,$dff088		; Facciamo partire la COP
	move.w	#0,$dff1fc		; Disattiva l'AGA
	move.w	#$c00,$dff106		; Disattiva l'AGA

	bsr.w	PRINT		; Stampa le linee di testo sullo schermo

mouse:
	;move.w	$dff006,$dff182	; metti VHPOSR in COLOR00 (lampeggio!!)
	btst	#6,$bfe001	; tasto sinistro del mouse premuto?
	bne.s	mouse		; se no, torna a mouse:

	move.l	OldCop(PC),$dff080	; Puntiamo la cop di sistema
	move.w	d0,$dff088		; facciamo partire la vecchia cop

	move.l	4.w,a6
	jsr	-$7e(a6)	; Enable - riabilita il Multitasking
	move.l	GfxBase(PC),a1	; Base della libreria da chiudere
	jsr	-$19e(a6)	; Closelibrary - chiudo la graphics lib
	rts			; USCITA DAL PROGRAMMA

;	Dati

GfxName:
	dc.b		"graphics.library",0,0	
GfxBase:			; Qua ci va l'indirizzo di base per gli Offset
	dc.l	0		; della graphics.library
OldCop:			; Qua ci va l'indirizzo della vecchia COP di sistema
	dc.l	0
			;	Routine che stampa caratteri larghi 8x8 pixel
PRINT:
	LEA	BITPLANE,A3	; Indirizzo del bitplane destinazione in a3
	CLR	D4
	MOVE.B	#255,D4		; QUANTE LINEE
	MOVE.L	#%10101010101010101010101010101010,D5

OUTERLOOP:		; NUOVA RIGA
	CLR	D6
	MOVE.B	#39,D6		; RESET D6
	;LSR.L	#3,D5
	NOT	D5

INNERLOOP:	; LOOP KE CICLA LA BITMAP
	MOVE.B	D5,(A3)
	ADD.W	#1,A3
	;LSL.L	#1,D5
	DBRA	D6,INNERLOOP
	DBRA	D4,OUTERLOOP

	RTS

	SECTION	GRAPHIC,DATA_C

COPPERLIST:
	dc.w	$120,$0000,$122,$0000,$124,$0000,$126,$0000,$128,$0000 ; SPRITE
	dc.w	$12a,$0000,$12c,$0000,$12e,$0000,$130,$0000,$132,$0000
	dc.w	$134,$0000,$136,$0000,$138,$0000,$13a,$0000,$13c,$0000
	dc.w	$13e,$0000

	dc.w	$8E,$2c81	; DiwStrt
	dc.w	$90,$2cc1	; DiwStop
	dc.w	$92,$0038	; DdfStart
	dc.w	$94,$00d0	; DdfStop
	dc.w	$102,0		; BplCon1
	dc.w	$104,0		; BplCon2
	dc.w	$108,0		; Bpl1Mod
	dc.w	$10A,0		; Bpl2Mod
			; 5432109876543210
	dc.w	$100,%0001001000000000	; 1 bitplane LOWRES 320x256

BPLPOINTERS:
	dc.w 	$e0,$0000,$e2,$0000	;primo	 bitplane

	dc.w	$0180,$222	; color0 - SFONDO
	dc.w	$0182,$aaa	; color1 - SCRITTE
	dc.w	$FFFF,$FFFE	; Fine della copperlist

	SECTION	MIOPLANE,BSS_C	; Le SECTION BSS devono essere fatte di
				; soli ZERI!!! si usa il DS.b per definire
				; quanti zeri contenga la section.

BITPLANE:
	ds.b		40*256	; un bitplane lowres 320x256

	END