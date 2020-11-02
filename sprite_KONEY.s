SPRT_K:	
	DC.B	$A4	; Posizione verticale di inizio sprite (da $2c a $f2)
	DC.B	$7A	; Posizione orizzontale di inizio sprite (da $40 a $d8)
	DC.B	$B3	; $50+13=$5d	; posizione verticale di fine sprite
	DC.B	$00
	DC.W	$E00E,$E00E,$E00E,$E00E,$E00E,$E00E
	DC.W	$E070,$E070,$E070,$E070,$E070,$E070
	DC.W	$FF80,$FF80,$FF80,$FF80,$FF80,$FF80
	DC.W	$FC70,$FC70,$FC70,$FC70,$FC70,$FC70
	DC.W	$FC0E,$FC0E,$FC0E,$FC0E,$FC0E,$FC0E
	DC.W	0,0	; 2 word azzerate definiscono la fine dello sprite.
SPRT_O:	
	DC.B	$A4	; Posizione verticale di inizio sprite (da $2c a $f2)
	DC.B	$83	; Posizione orizzontale di inizio sprite (da $40 a $d8)
	DC.B	$B3	; $50+13=$5d	; posizione verticale di fine sprite
	DC.B	$00
	DC.W	$FFFE,$FFFE,$FFFE,$FFFE,$FFFE,$FFFE
	DC.W	$E00E,$E00E,$E00E,$E00E,$E00E,$E00E
	DC.W	$FC0E,$FC0E,$FC0E,$FC0E,$FC0E,$FC0E
	DC.W	$FC0E,$FC0E,$FC0E,$FC0E,$FC0E,$FC0E
	DC.W	$FFFE,$FFFE,$FFFE,$FFFE,$FFFE,$FFFE
	DC.W	0,0	; 2 word azzerate definiscono la fine dello sprite.
SPRT_N:	
	DC.B	$A4	; Posizione verticale di inizio sprite (da $2c a $f2)
	DC.B	$8C	; Posizione orizzontale di inizio sprite (da $40 a $d8)
	DC.B	$B3	; $50+13=$5d	; posizione verticale di fine sprite
	DC.B	$00
	DC.W	$FFFE,$FFFE,$FFFE,$FFFE,$FFFE,$FFFE
	DC.W	$E00E,$E00E,$E00E,$E00E,$E00E,$E00E
	DC.W	$FC0E,$FC0E,$FC0E,$FC0E,$FC0E,$FC0E
	DC.W	$FC0E,$FC0E,$FC0E,$FC0E,$FC0E,$FC0E
	DC.W	$FC0E,$FC0E,$FC0E,$FC0E,$FC0E,$FC0E
	DC.W	0,0	; 2 word azzerate definiscono la fine dello sprite.

SPRT_E:	
	DC.B	$A4	; Posizione verticale di inizio sprite (da $2c a $f2)
	DC.B	$95	; Posizione orizzontale di inizio sprite (da $40 a $d8)
	DC.B	$B3	; $50+13=$5d	; posizione verticale di fine sprite
	DC.B	$00
	DC.W	$FFFE,$FFFE,$FFFE,$FFFE,$FFFE,$FFFE
	DC.W	$E000,$E000,$E000,$E000,$E000,$E000
	DC.W	$FFFE,$FFFE,$FFFE,$FFFE,$FFFE,$FFFE
	DC.W	$FC00,$FC00,$FC00,$FC00,$FC00,$FC00
	DC.W	$FFFE,$FFFE,$FFFE,$FFFE,$FFFE,$FFFE
	DC.W	0,0	; 2 word azzerate definiscono la fine dello sprite.
SPRT_Y:	
	DC.B	$A4	; Posizione verticale di inizio sprite (da $2c a $f2)
	DC.B	$9E	; Posizione orizzontale di inizio sprite (da $40 a $d8)
	DC.B	$B3	; $50+13=$5d	; posizione verticale di fine sprite
	DC.B	$00
	DC.W	$FC7E,$FC7E,$FC7E,$FC7E,$FC7E,$FC7E
	DC.W	$1FF0,$1FF0,$1FF0,$1FF0,$1FF0,$1FF0
	DC.W	$0380,$0380,$0380,$0380,$0380,$0380
	DC.W	$03F0,$03F0,$03F0,$03F0,$03F0,$03F0
	DC.W	$03F0,$03F0,$03F0,$03F0,$03F0,$03F0
	DC.W	0,0	; 2 word azzerate definiscono la fine dello sprite.