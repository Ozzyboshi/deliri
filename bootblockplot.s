	SECTION CODE,CODE_C
	include exec/io.i
	include exec/exec_lib.i
	include devices/trackdisk.i
bootblock:
	dc.b    "DOS",0
	dc.l    0
	dc.l    880

bootEntry:
	;;  a6 = Exec base
	;;  a1 = trackdisk.device I/O request pointer

	lea     $70000,a5 ; main.s entry point 
	;move.w	 #$7000.w,a5
	;; move.l #$ff000,a7
	
	;; Load the progam from the floppy using trackdisk.device

	;move.l  #mainEnd-mainStart,IO_LENGTH(a1)
	move.l #11776,IO_LENGTH(a1)
	move.l  a5,IO_DATA(a1)
	;move.l  #mainStart-bootblock,IO_OFFSET(a1)	
	move.l #1024,IO_OFFSET(a1)
	jsr     _LVODoIO(a6)

	;; Turn off drive motor
	move.l  #0,IO_LENGTH(a1)
	move.w  #TD_MOTOR,IO_COMMAND(a1)
	jsr     _LVODoIO(a6)
	
	jmp     (a5)	; -> main.s entry point
endBootBlock:
	
	;; Pad the remainder of the bootblock
	;ds.b    1024,0
	;cnop	0,256
	

mainStart:
	;incbin  "ram:plotfat.bin"
	;dcb.b    512,0
mainEnd:
	end