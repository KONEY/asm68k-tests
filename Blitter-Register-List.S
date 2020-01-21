;********** relevant blitter registers **********
;base reg $dff000

BLTDDAT	= 0	;result of the last word. used for bob collision detection and 
		;MFM decoding
DMACONR	= 2	;bit 14=blitter busy flag

;blitter operation setup
BLTCON0	= $dff040
BLTCON1	= $dff042
BLTAFWM	= $dff044
BLTALWM	= $dff046

;sources, destination, and size
BLTCPTH	= $dff048
BLTCPTL	= $dff04a
BLTBPTH	= $dff04c
BLTBPTL	= $dff04e
BLTAPTH	= $dff050
BLTAPTL	= $dff052
BLTDPTH	= $dff054
BLTDPTL	= $dff056

BLTSIZE	= $dff058

;ECS/AGA registers
BLTCON0L = $dff05a
BLTSIZV	= $dff05c
BLTSIZH	= $dff05e

;modulos
BLTCMOD	= $dff060	
BLTBMOD	= $dff062
BLTAMOD	= $dff064
BLTDMOD	= $dff066

;data to replace sources
BLTCDAT	= $dff070	
BLTBDAT	= $dff072
BLTADAT	= $dff074

;bit 6: enable blitter DMA - bit 10: give blitter priority over the CPU
DMACON	= $dff096	