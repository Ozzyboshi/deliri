
	Section	CODE,CODE_C

*****************************************************************************
	include	"startup1.s"	; con questo include mi risparmio di
				; riscriverla ogni volta!
*****************************************************************************


; Con DMASET decidiamo quali canali DMA aprire e quali chiudere

		;5432109876543210
DMASET	EQU	%1000001110000000	; copper e bitplane DMA abilitati
;		 -----a-bcdefghij

BORDER_DX equ 300
BORDER_SX equ 30
BORDER_UP equ 10
BORDER_DOWN equ 250

STEP equ 1

START:
	
;	 PUNTIAMO IL NOSTRO BITPLANE

	MOVE.L	#BITPLANE,d0
	LEA	BPLPOINTERS,A1
	move.w	d0,6(a1)
	swap	d0
	move.w	d0,2(a1)

	MOVE.W	#DMASET,$96(a5)		; DMACON - abilita bitplane, copper
					; e sprites.

	move.l	#COPPERLIST,$80(a5)	; Puntiamo la nostra COP
	move.w	d0,$88(a5)		; Facciamo partire la COP
	move.w	#0,$1fc(a5)		; Disattiva l'AGA
	move.w	#$c00,$106(a5)		; Disattiva l'AGA
	move.w	#$11,$10c(a5)		; Disattiva l'AGA

	lea	BITPLANE,a0	; Indirizzo del bitplane dove stampare

mouse:
	MOVE.L	#$1ff00,d1	; bit per la selezione tramite AND
	MOVE.L	#$13000,d2	; linea da aspettare = $130, ossia 304
Waity1:
	MOVE.L	4(A5),D0	; VPOSR e VHPOSR - $dff004/$dff006
	AND.L	D1,D0		; Seleziona solo i bit della pos. verticale
	CMP.L	D2,D0		; aspetta la linea $130 (304)
	BNE.S	Waity1

	bsr.w getDirection
	
	cmp.b #0,d0
	beq.s Left
	
	cmp.b #1,d0
	beq.s Right
	
	cmp.b #2,d0
	beq.s Up
	
	cmp.b #3,d0
	beq.s Down
	
Right:
	add.w #STEP,coordX
	cmpi.w #BORDER_DX,coordX
	bhi.s Left
	bra.s Print
Left:
	add.w #-STEP,coordX
	cmpi.w #BORDER_SX,coordX
	bls.s Right
	bra.s Print
	
Up:	add.w #-STEP,coordY
	cmpi.w #BORDER_UP,coordY
	bls.s Down
	bra.s Print
	
Down:
	add.w #STEP,coordY
	cmpi.w #BORDER_DOWN,coordY
	bhi.s Up
	bra.s Print
	
	moveq #0,d0

Print:
	move.w	coordX,d0		; Coordinata X
	move.w	coordY,d1		; Coordinata Y

	bsr.s	plotPIX		; stampa il punto alla coord. X=d0, Y=d1

	MOVE.L	#$1ff00,d1	; bit per la selezione tramite AND
	MOVE.L	#$13000,d2	; linea da aspettare = $130, ossia 304
Aspetta:
	MOVE.L	4(A5),D0	; VPOSR e VHPOSR - $dff004/$dff006
	AND.L	D1,D0		; Seleziona solo i bit della pos. verticale
	CMP.L	D2,D0		; aspetta la linea $130 (304)
	BEQ.S	Aspetta

	;btst	#6,$bfe001	; mouse premuto?
	;bne.w	mouse
	bra.w mouse
Finito:
	rts			; esci

; Start of walking
coordX:	dc.w 200
coordY: dc.w 200

getDirection:
	movem.l	d1-d7/a0-a6,-(SP)	; Salva i registri nello stack
	movea.l (counterDirection),a0
	add.l #2,counterDirection 
	moveq  #0,d0
	move.w (a0),d0
	
	;lsr.l  #8,d0
	;lsr.l #4,d0
	
	andi.l #3,d0
	;cmpi.w #4,d0
	;bls.s dxDirection
	;moveq #0,d0
	;bra.s endDirection
dxDirection:
	;moveq #1,d0
endDirection
	movem.l	(SP)+,d1-d7/a0-a6 ; Riprendi i vecchi valori dei registri
	rts
counterDirection:
	dc.l $0000000A

	
*****************************************************************************
;			Routine di plot dei punti (dots)
*****************************************************************************

;	Parametri in entrata di PlotPIX:
;
;	a0 = Indirizzo bitplane destinazione
;	d0.w = Coordinata X (0-319)
;	d1.w = Coordinata Y (0-255)

;	       ,..,..,.,
;	   .:¦¾½¾½¾½¾½¾½¾¦.
;	   ¦::·        ·::|
;	   |   ______     |
;	  _|  ¯_______ ___l
;	 / j  /     ¬\_____)
;	( C| /    (°  )   ¯|
;	 \_) \_______/  °) ¦
;	   |         ¯\---÷'
;	  _j        C·_)  |
;	 (  _____________ `\
;	  \ \l_l__l_l_l_¡  /
;	   \ \_T_T_T_l_!j /
;	    \__¯ ¯ ¯ ¯ __/ xCz
;	      `--------'


LargSchermo	equ	40	; Larghezza dello schermo in bytes.

plotPIX:
	move.w	d0,d2		; Copia la coordinata X in d2


; Troviamo l'offset orizzontale, ossia la X

	lsr.w	#3,d0		; Intanto trova l'offset orizzontale,
				; dividendo per 8 la coordinata X. Essendo lo
				; schermo fatto di bits, sappiamo che una
				; linea orizzontale e' larga 320 pixel, ossia
				; 320/8=40 bytes. Avendo la coordinata X che
				; va da 0 a 320, cioe' in bits, la dobbiamo
				; convertire in bytes, dividendola per 8.
				; In questo modo abbiamo il byte entro cui
				; settare il nostro bit.

; Ora troviamo l'offset verticale, ossia la Y:

	mulu.w	#LargSchermo,d1	; moltiplica la larghezza di una linea per il
				; numero di linee, trovando l'offset
				; verticale dall'inizio dello schermo

; Infine troviamo l'offset dall'inizio dello schermo del byte dove si trova il
; punto (ossia il bit), che setteremo con l'istruzione BSET:

	add.w	d1,d0	; Somma lo scostamento verticale a quello orizzontale

; Ora abbiamo in d0 l'offset, in bytes, dall'inizio dello schermo per trovare
; il byte dove si trova il punto da settare. Abbiamo quindi da scegliere quale
; degli 8 bit del byte va settato.

; Ora troviamo quale bit del byte dobbiamo settare:

	and.w	#%111,d2	; Seleziona solo i primi 3 bit di X, ossia
				; l'offset (scostamento) nel byte,
				; ricavando in d2 il bit da settare
				; (in realta' sarebbe il resto della divisione
				;  per 8, fatta in precedenza)

	not.w	d2		; Opportunamente nottato

; Ora abbiamo in d0 l'offset dall'inizio dello schermo per trovare il byte,
; in d2 il numero di bit da settare all'interno di quel bit, e in a0
; l'indirizzo del bitplane. Con una sola istruzione possiamo settare il bit:

	bset.b	d2,(a0,d0.w)	; Setta il bit d2 del byte distante d0 bytes
				; dall'inizio dello schermo.
	rts			; Esci.


COPPERLIST:

	dc.w	$8E,$2c81	; DiwStrt
	dc.w	$90,$2cc1	; DiwStop
	dc.w	$92,$0038	; DdfStart
	dc.w	$94,$00d0	; DdfStop
	dc.w	$102,0		; BplCon1
	dc.w	$104,$24	; BplCon2 - Tutti gli sprite sopra i bitplane
	dc.w	$108,0		; Bpl1Mod
	dc.w	$10a,0		; Bpl2Mod
		    ; 5432109876543210
	dc.w	$100,%0001001000000000	; 1 bitplane LOWRES 320x256

BPLPOINTERS:
	dc.w $e0,0,$e2,0	;primo	 bitplane

	dc.w	$0180,$000	; color0 - SFONDO
	dc.w	$0182,$1af	; color1 - SCRITTE

	dc.w	$FFFF,$FFFE	; Fine della copperlist



;	SECTION	MIOPLANE,BSS_C

BITPLANE:
	ds.b	40*256	; un bitplane lowres 320x256

	end

