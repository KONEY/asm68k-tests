	; Lezione6c2.s	STAMPIAMO VARIE RIGHE DI TESTO SULLO SCHERMO!!!
;	- con font in binario MODIFICABILE FACILMENTE!!

	SECTION	CiriCop,CODE

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

;	 PUNTIAMO IL NOSTRO BITPLANE

	move.w	$444,$dff180	; metti VHPOSR in COLOR00 (lampeggio!!)
	move.w	$111,$dff182	; metti VHPOSR in COLOR00 (lampeggio!!)
	move.w	$fff,$dff184	; metti VHPOSR in COLOR00 (lampeggio!!)
	move.w	$999,$dff186	; metti VHPOSR in COLOR00 (lampeggio!!)

	MOVE.L	#BITPLANE,d0	; in d0 mettiamo l'indirizzo della PIC,
	LEA		BPLPOINTERS,A1	; puntatori nella COPPERLIST
	move.w	d0,6(a1)	; copia la word BASSA dell'indirizzo del plane
	swap	d0		; scambia le 2 word di d0 (es: 1234 > 3412)
	move.w	d0,2(a1)	; copia la word ALTA dell'indirizzo del plane

	move.l	#COPPERLIST,$dff080	; Puntiamo la nostra COP
	move.w	d0,$dff088		; Facciamo partire la COP
	move.w	#0,$dff1fc		; Disattiva l'AGA
	move.w	#$c00,$dff106		; Disattiva l'AGA

	bsr.w	print		; Stampa le linee di testo sullo schermo

mouse:
	;move.w	$dff006,$dff182	; metti VHPOSR in COLOR00 (lampeggio!!)
	btst	#6,$bfe001	; tasto sinistro del mouse premuto?
	bne.s	mouse		; se no, torna a mouse:

	move.l	OldCop(PC),$dff080	; Puntiamo la cop di sistema
	move.w	d0,$dff088		; facciamo partire la vecchia cop

	move.l	4.w,a6
	jsr	-$7e(a6)	; Enable - riabilita il Multitasking
	move.l	gfxbase(PC),a1	; Base della libreria da chiudere
	jsr	-$19e(a6)	; Closelibrary - chiudo la graphics lib
	rts			; USCITA DAL PROGRAMMA

;	Dati

GfxName:
	dc.b	"graphics.library",0,0	

GfxBase:		; Qua ci va l'indirizzo di base per gli Offset
	dc.l	0	; della graphics.library

OldCop:			; Qua ci va l'indirizzo della vecchia COP di sistema
	dc.l	0

;	Routine che stampa caratteri larghi 8x8 pixel

PRINT:
	LEA	BITPLANE,A3	; Indirizzo del bitplane destinazione in a3
	MOVE.W	0,D4
	MOVE.L	#KONEY,A2

	;MOVE.L	(A2)+,(A3,D4)

	MOVE.L	#%01010101010101010101010101010101,(A3)
	MOVE.L	#%11111111111111111111111111111111,200(A3)

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
	dc.w	$10a,0		; Bpl2Mod
		;QUESTO GLITCHA
		    ; 5432109876543210
	dc.w	$4A,%0001001000000000	; 1 bitplane LOWRES 320x256

BPLPOINTERS:
	dc.w 	$e0,$0000,$e2,$0000	;primo	 bitplane

	dc.w	$0180,$444	; color0 - SFONDO
	dc.w	$0182,$fff	; color1 - SCRITTE
	dc.w	$FFFF,$FFFE	; Fine della copperlist

;	Il FONT caratteri 8x8

;	caratteri:  !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ
;	ATTENZIONE! non ci sono: [\]^_`abcdefghijklmnopqrstuvwxyz{|}~

; CONSIGLIO: Per scorrere in basso usate il cursore giu' + SHIFT e fate una
; pagina alla volta!!!

SATANA:	DC.L	%10101010101010101010101010101010
	DC.L	%01010101010101010101010101010101
	DC.L	%10101010101010101010101010101010
	DC.L	%01010101010101010101010101010101
	DC.L	%10101010101010101010101010101010


KONEY:
	DC.L	%10001011111011111011111011011001
	DC.L	%10010010001010001010000001110001
	DC.L	%11100011001011001011111000100001
	DC.L	%11010011001011001011000000110001
	DC.L	%11001011001011001011111000110001


	SECTION	MIOPLANE,BSS_C	; Le SECTION BSS devono essere fatte di
				; soli ZERI!!! si usa il DS.b per definire
				; quanti zeri contenga la section.

BITPLANE:
	ds.b	40*256	; un bitplane lowres 320x256

	end

Questo listato e' uguale a Lezione6c.s, ma il font e' "FATTO A MANO", infatti
anziche' caricarlo e' nel listato in forma di dc.b in binario

		;12345678
; "A"
	dc.b	%01111111	;1
	dc.b	%00000011	;2
	dc.b	%01100011	;3
	dc.b	%01111111	;4
	dc.b	%01100011	;5
	dc.b	%01100011	;6
	dc.b	%01100011	;7
	dc.b	%00000000	;8

Questa per esempio e' la "A". Attenzione a non usare caratteri minuscoli nel
testo, perche' non sono nel font, in quanto chi lo ha fatto si deve essere
stancato alla "Z" maiuscola. In realta' non c'erano nemmeno molti simboli
come "*;<>=" e li ho aggiunti io. Ora apparira' piu' chiara anche come e'
fatto il font! E intuirete che per fare un font di 16x16 dovete fare cosi':


		;1234567890123456
; "A"
	dc.w	%0000111111111100	;1
	dc.w	%0011111111111111	;2
	dc.w	%0011110000001111	;3
	dc.w	%0011110000001111	;4
	dc.w	%0011110000001111	;5
	dc.w	%0011110000001111	;6
	dc.w	%0011111111111111	;7
	dc.w	%0011111111111111	;8
	dc.w	%0011110000001111	;9
	dc.w	%0011110000001111	;10
	dc.w	%0011110000001111	;11
	dc.w	%0011110000001111	;12
	dc.w	%0011110000001111	;13
	dc.w	%0011110000001111	;14
	dc.w	%0000000000000000	;15
	dc.w	%0000000000000000	;16

Ma conviene disegnarlo e convertirlo in RAW!

In questo listato vi consiglio di modificare il FONT, aggiungendo disegnini e
simboli strani. Potreste farvi il FONT personale!

