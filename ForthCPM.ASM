;********************************************************************
; Write Your Own FORTH Interpreter By Richard Fritzson
; Kilobaud Microcomputing, February 1981 page 76 - 92
; Found in the public domain in the Internet Archive at:
; https://bit.ly/3R6KSyh
;********************************************************************
;DA******************************************************************
; CP/M DEFINITIONS
;********************************************************************
FBASE	EQU	6	;Points to CP/M top of memory
BDOS	EQU	5	;BDOS Entry Point
CONIN	EQU	1	;Console Input Function
CONOUT	EQU	2	;Console Output Function
CPMEXIT	EQU	0

;********************************************************************
; Listing 14. Main interpreter loop. Page 88
;********************************************************************
;DA	TITLE 'Threaded Code Interpreter for 8080'
; Richard Fritzson
; 29 January 1980 Version 1.0
;
; This version contains only the basic internal
; interpreter and a simple interactive console
; interpreter

	ORG	100H		;start up address
ENTRY	LHLD	FBASE		;DA Read top of CP/M memory
	DCX	H		;point to free space
	SHLD	MEMORY+2	;Update memory size
	LXI	SP,STACK	;initialize parameter stack
	CALL	DICMOVE		;move dictionary to high memory
	LXI	H,TOP-1		;set PC to top level loop
	SHLD	PC
	JMP	NEXT		;and start interpreter

; TOP - Top Level System Loop
; DESCRIPTION: TOP is an infinite
; loop which picks up the contents of the
; EXEC variable and executes it.

TOP	DW	EXEC,PEEKW	;get top level program
	DW	EXECUTE		;run it
	DW	JUMP, TOP-1	;and loop

; EXEC - address of top level routine

EXEC	DW	VARIABLE	;threaded code variable
	DW	INTERACT	;address of user interpreter

; Reserved Stack Space

	DS	128		;parameter stack
STACK	EQU	$
	PAGE

;********************************************************************
; Listing la. Example assemblyanguage routine. Page 76
;********************************************************************
; RDSEC - read a sector from the disk
; HL - track to read
; DE - sector to read
; BC - memory area to read to

;RDSEC	PUSH	B	; save memory address
;	PUSH	D	; save sector
;	MOV	B,H	; all subs expect arg in BC
;	MOV	C,L
;	CALL	SETTRK	; set track
;	POP	B	; BC gets sector
;	CALL	SETSEC	; select sector
;	POP	B	; BC gets memory address
;	CALL	SETDMA	; set memory address
;	CALL	READ	; READ the sector
;	RET

;********************************************************************
; Listing lb. Example use of uniform parameter passing on the stack.
; Page 76
;********************************************************************
; RDSEC - read a sector from the disk
; TOP (of stack) - track to read
; TOP-1		 - sector to read
; TOP-2		 - memory address to read to
; NOTE: This routine won't work because it uses the
; same stack for subroutine calling and parameter
; passing. It is here only to make a point.
;RDSEC	CALL	SETTRK	; SETTRK uses up top of stac
;	CALL	SETSEC	; SETSEC uses up top of stack
;	CALL	SETDMA	; SETDMA uses up top of stack
;	CALL	READ	; all arguments set, perform read
;	RET

;********************************************************************
; Listing lc. Sample assembly code compressed into threaded code.
;********************************************************************
; RDSEC - read a sector from the disk
; TOP (of stack) - track to read
; TOP-1		 - sector to read
; TOP-2		 - memory area to read to
; NOTE: This is a threaded code routine. It uses two
; separate stacks and so will work.

;RDSEC	DW	TCALL	; threaded code CALL
;	DW	SETTRK	; TCALL SETTRK, set track
;	DW	SETSEC	; TCALL SETSEC, set sector
;	DW	SETDMA	; TCALL SETDMA, set memory address
;	DW	READ	; TCALL READ, read sector
;	DW	TRET	; threaded code RETurn

;********************************************************************
; Listing 2. Sample code showing stack details. Page 77
;********************************************************************

; The interpreter's architecture: a program counter and a stack
PC	DW	0	; a 16 bit pointer into the MIDDLE off
			; the current instruction (not the
			; first byte, but the second)

RSTACK	DW	$+2	; the stack pointer points to the next
			; AVAILABLE stack position (not the
			; topmost occupied position)

	DS	80H	; reserved stack space

; RPUSH - push DE on stack
; ENTRY: DE - number to be pushed on stack
; EXIT: DE - is unchanged
; DESCRIPTION: this code is illustrative of how the
; stack works. However it is not used in the system and
; can be left out.

RPUSH	LHLD	RSTACK	; get stack pointer
	MOV	M,E	; store low byte
	INX	H	; bump pointer to next byte
	MOV	M,D	; store high byte
	INX	H	; bump pointer to next empty slot
	SHLD	RSTACK	; restore pointer
	RET

; RPOP - pop DE from stack
; ENTRY: No Register Values Expected
; EXIT: DE - top element of RSTACK
; DESCRIPTION: this code is illustrative of how the
; stack works. However it is not used in the system and
; can be left out.

RPOP	LHLD	RSTACK	; get stack pointer
	DCX	H	; rop to first stack position
	MOV	D,M	; get high byte
	DCX	H
	MOV	E,M	; get low byte
	SHLD	RSTACK	; restore stack pointer
	RET

;********************************************************************
; Listing 3. Main interpreter loop. Page 78
;********************************************************************

; NEXT - main internal interpreter loop
; ENTRY: PC - points into v instruction just completed
; EXIT:  PC - incremented by 2, points to next
;	      instruction
;	 DE - points to middle of first word of
;	      next routine (i.e. (PC)+1)
; DESCRIPTION : increments the PC; picks up the code
; word of the next routine and jumps to it.

NEXT	LHLD	PC	;increment program counter
	INX	H	;while loading DE with
	MOV	E,M	;next instruction
	INX	H
	MOV	D,M
	SHLD	PC
	XCHG 		;pick up word addressed
	MOV	E,M	;by next instruction (which
	INX	H	;is CODE, TCALL or some other
	MOV	D,M	;executable address)
	XCHG		;  and
	PCHL		;jump to it

;********************************************************************
; Listing 4a. TCALL instruction. Page 78
;********************************************************************
; TCALL - the threaded call routine
; ENTRY: DE - middle of first word of routine being called
; EXIT: No Register Values Returned
; DESCRIPTION: pushes the current contents of the PC
; onto the return stack; makes DE the new PC.

TCALL	LHLD	PC	;get old program counter
	XCHG		;replace with DE
	SHLD	PC
	LHLD	RSTACK	;push old PC on RSTACK
	MOV	M,E
	INX 	H
	MOV	M,D
	INX 	H
	SHLD	RSTACK
	JMP	NEXT	;back to interpreter

;********************************************************************
; Listing 4b. TRET instruction. Page 78
;********************************************************************
; TRET - the threaded code return
; DESCRIPTION: pops the top element of the
; return stack and puts it into the program counter.

TRET	DW	$+2	;CODE
	LHLD	RSTACK	;get stack poiner
	DCX	H	;high byte of top element
	MOV	D,M
	DCX	H	;low byte of top element
	MOV	E,M
	SHLD	RSTACK	;restore stack pointer
	XCHG		;store top of stack in PC
	SHLD	PC
	JMP	NEXT	;back to interpreter

;********************************************************************
; Listing 5. Simple arithmetic routines. Page 80
;********************************************************************
; Simple arithmetic routines
; INC - increment the top of the stack

INC	DW	$+2	;CODE
	POP	H	;get top
	INX 	H	;increment
	PUSH	H	;restore
	JMP	NEXT
	
; DEC - decrement the top of the stack
DEC	DW	$+2	;CODE
	POP	H	;get top
	DCX	H	;decrement
	PUSH	H	;restore
	JMP	NEXT

; TADD - add the top two elements of the stack
TADD	DW	$+2	;CODE
	POP	H	;first element
	POP	D	;second element
	DAD	D	;add 'em
	PUSH	H	;push result
	JMP	NEXT
	
; MINUS - negate top of stack
MINUS	DW	$+2	;CODE
	POP	H	;get top
	CALL	MINUSH	;negate H
	PUSH	H	;push it
	JMP	NEXT

MINUSH	DCX	H	;good ole 2s co
	MOV	A,H
	CMA
	MOV	H,A
	MOV	A,L
	CMA
	MOV	L,A
	RET

; TSUB - subtract TOP from TOP-1
TSUB	DW	TCALL	;threaded code
	DW	MINUS	;negate top
	DW	TADD	;and add
	DW	TRET

;********************************************************************
; Listing 6. Peek and Poke instructions. Page 80
;********************************************************************
; PeekB - retrieve a byte from memory
; ENTRY: TOP   - address
; EXIT:  TOP   - byte at address

PEEKB	DW	$+2	;CODE
	POP	H	;get address
	MOV	E,M	;get byte
	MVI	D,0
	PUSH	D	;save
	JMP	NEXT

; PeekW - retrieve a word from memory
; ENTRY: TOP   - address
; EXIT:  TOP   - word at address

PEEKW	DW	$+2	;CODE
	POP	H	;get address
	MOV	E,M	;get word
	INX	H
	MOV	D,M
	PUSH	D	;save
	JMP	NEXT

; PokeB - store byte in memory
; ENTRY: TOP   - address
;	 TOP-1 - byte to store
; EXIT:  No Values Returned

POKEB	DW	$+2	;CODE
	POP	H	;get address
	POP	D	;get byte
	MOV	M,E	;store
	JMP	NEXT
	
; PokeW - store word in memory
; ENTRY: TOP   - address
;	 TOP-1 - word to store
; EXIT:  No Values returned

POKEW	DW	$+2	;CODE
	POP	H	;get address
	POP	D	;get word
	MOV	M,E	;store word
	INX	H
	MOV	M,D
	JMP	NEXT

;********************************************************************
; Listing 7. Standard threaded-code functions. Page 81
;********************************************************************
; Some standard threaded code functions
; TPUSH - push the next word onto the stack

TPUSH	DW	$+2	;CODE
	LHLD	PC	;get program counter
	INX	H	;advance to next word
	MOV	E,M	;and pick up contents
	INX	H
	MOV	D,M
	SHLD	PC	;store new program counter
	PUSH	D	;push word onto param stack
	JMP	NEXT	;continue

; TPOP - drop the top of the parameter stack
TPOP	DW	$+2	;CODE
	POP	H	;pop one element
	JMP	NEXT	;and continue

; SWAP - exchange top two elements of the stack
SWAP	DW	$+2	;CODE
	POP	H	;get one element
	XTHL		;exchange
	PUSH	H	;put back
	JMP	NEXT	;and continue

; DUP - duplicate the top of the stack
; DESCRIPTION: often used before functions which
; consume the top of the stack (e.g. conditional jumps)

DUP	DW	$+2	;CODE
	POP	H	;get top
	PUSH	H 	;save it twice
	PUSH	H
	JMP 	NEXT
		
; CLEAR - clear the stack

CLEAR	DW	$+2	;CODE
	LXI	SP,STACK ; reset stack pointer
	JMP	NEXT

;********************************************************************
; Listing 8. Threaded-code jumps. Page 81
;********************************************************************
; Threaded Code Jumps

; All Jumps are to absolute locations
; All Conditional jumps consume the
; elements of the stack that they test.

JUMP	DW	$+2	;CODE
JUMP1	LHLD	PC	;get program counter
	INX	H	;get next word
	MOV	E,M
	INX	H
	MOV	D,M
	XCHG		;make it the PC
	SHLD	PC
	JMP	NEXT

; IFZ - jump if top is zero

IFZ	DW	$+2	;CODE
	POP	H	;get top
	MOV	A,H	;test for zero
	ORA	L
	JZ	JUMP1	;if yes, jump
SKIP	LHLD	PC	;else simply skip next word
	INX	H
	INX	H
	SHLD	PC
	JMP	NEXT

; IFNZ - jump if top not zero

IFNZ	DW	$+2 	;CODE
	POP	H	;get top
	MOV	A,H	;test for zero
	ORA	L
	JNZ	JUMP1	;if not, jump
	JMP	SKIP	;else don't

; IFEQ - jump if TOP =» TOP-1

IFEQ	DW	$+2	;CODE
	POP	H	;get top
	CALL	MINUSH	;negate it
	POP	D	;get top-1
	DAD	D	;add 'em
	MOV	A,H	;test for zero
	ORA	L
	JZ	JUMP1	;if equal, jump
	JMP	SKIP	;otherwise, don't

;********************************************************************
; Listing 9. Implementing constants and variables. Page 82
;********************************************************************
; Implementation of Constants and Variables in a
; threaded code system

; CONSTANT - code address for constants
; ENTRY: DE - points to middle of code word for
;	      constant
; DESCRIPTION: picks up the contents of the word
; following the code word and pushes it onto the stack.

CONSTANT
	XCHG		;HL <- address of code word
	INX	H	;get constant
	MOV	E,M
	INX	H
	MOV	D,M
	PUSH	D	;push it on the parameter stack
	JMP	NEXT	;return to interpreter	

; Some common constants

ZERO	DW	CONSTANT	;threaded code constant
	DW	0
	
ONE	DW	CONSTANT	;threaded code constant
	DW	1
	
NEGONE	DW	CONSTANT	;threaded code constant
	DW	-1
	
MEMORY	DW	CONSTANT	;last available byte
	DW	8*1024-1	;8K system

; VARIABLE - code address for variables
; ENTRY: DE - points to middle of code word for
;	      variable
; DESCRIPTION: pushes address of word following code
; word onto the stack.

VARIABLE
	INX	D	;increment to variable address
	PUSH	D	;store on parameter stack
	JMP	NEXT	;return to inerpreter

;********************************************************************
; Listing 10. Interaction algorithm in threaded language. Page 84
;********************************************************************
; Top Level External Interpreter Version 1.0
;
; This routine reads one line of reverse
; polish notation from the console and executes it.
INTERACT
	DW	TCALL		;threaded code
	DW	PROMPT		;prompt the user and
	DW	READLINE	;read a console line

SLOOP	DW	SCAN		;scan for next word
	DW	IFZ,EXIT-1	;if end of line, quit
	DW	LOOKUP		;else lookup word in dictionar'
	DW	IFZ, NUMBER-1	;if not found, try number
	DW	EXECUTE		;else execute it
	DW	JUMP,SLOOP-1 	;and continue scanning
	
NUMBER	DW	CONAXB		;try converting to number
	DW	IFNZ,SLOOP-1	;if succesful, leave on stack
				;and continue scanning

	DW	TPUSH,ERRMSG	;else push error message
	DW	PRINTS		;and print it
	DW	PRINTS		;then print string
	DW	TRET		;and return
	
EXIT	DW	DUP,CONBXA	;copy and convert top of stack
	DW	PRINTS		;print it
	DW	TRET		;return
ERRMSG	DB	13,'Not Defined: '

;********************************************************************
; Listing 11. Dictionary lookup routine. Page 84 and 85
;********************************************************************
; LOOKUP - the dictionary lookup routine
; ENTRY: TOP   - pointer to string to be looked up
; EXIT:  TOP   - -1 if string found in dictionary
;	          0 if string not found
;	 TOP-1 - pointer to code of found subroutine
;			or
;		 string pointer if not found
; DESCRIPTION: performs a linear search of the
; dictionary. Returns the code address if the string
; is found, or else the string pointer if not found.
; threaded code

LOOKUP	DW	TCALL		;threaded code
	DW	NAMES,PEEKW	;get top of dictionary

SEARCH	DW	DUP,PEEKB	;get char count of next entry
	DW	IFZ,FAIL-1	;if end of dictionary

	DW	MATCH		;else attempt a match
	DW	IFNZ,SUCCEED-1	;if succesful match

	DW	FIRST,TADD	;else skip string
	DW	TPUSH,2,TADD	;and pointer
	DW	JUMP,SEARCH-1	;and try next entry

FAIL	DW	TPOP		;drop dictionary pointer
	DW	ZERO		;leave a zero on the stack
	DW	TRET		;and quit
	
SUCCEED	DW	SWAP,TPOP	;drop string pointer
	DW	FIRST,TADD,PEEKW ;get code pointer
	DW	NEGONE		;push a minus one
	DW	TRET		;and return

; Names - address of dictionary names

NAMES	DW	VARIABLE	;threaded code variable
	DW	NAMEBEG		;beginning of names
	
; MATCH - match strings
; ENTRY: TOP   - ptr to string
;	 TOP-1 - ptr to another string
; EXIT:  TOP   - -1 if strings are the same
;		  0 if strings do not match
;	 TOP-1 - ptr to first string
;	 TOP-2 - ptr to second string
; DESCRIPTION: written in assembly to speed things up.

MATCH	DW	$+2	;C0DE
	POP	H	;first string
	POP	D	;second string
	PUSH	D	;leave on stack
	PUSH	H
	LDAX	D	;get 2nd count
	CMP	M	;compare with first
	JNZ	MATCHF	;if no match
			;else try string matching
	MOV	B, A	;B holds byte count
MATCH1	INX	H	;next byte
	INX	D
	LDAX	D
	CMP	M
	JNZ	MATCHF	;if no match
	DCR	B	;else dec count
	JNZ	MATCH1	;if more to compare
	LXI	H,-1	;else push success
	PUSH	H
	JMP	NEXT

MATCHF	LXI	H,0	;failure
	PUSH	H
	JMP	NEXT

;********************************************************************
; Listing 12. Execute function. Page 86
;********************************************************************
; EXECUTE - execute routine at top of stack
; ENTRY: TOP   - address of routine to be executed
; EXIT:  DE - middle of word addressed by top
; DESCRIPTION: The address is of a threaded code
; interpreter routine, so the contents of the
; first word is an executable address. EXECUTE
; gets that address and jumps to it, leaving DE
; in the same state that the main interpreter
; loop (NEXT) would have.

EXECUTE	DW	$+2		;CODE
	POP	H		;get address
	MOV	E,M		;get first word
	INX	H
	MOV	D,M
	XCHG			;and jump to it
	PCHL

;********************************************************************
; Listing 13. Readline program. Page 86 and 88
;********************************************************************
; READLINE - fill console buffer
; DESCRIPTION: reads characters from the console, echoing them
; to the screen and storing them in the console buffer,
; beginning in the third character of the buffer.
; Stops on encountering a carriage return and stores a
; final zero after the other characters.
; Takes appropriate action for a backspace character.

READLINE
	DW	TCALL		;threaded code
	DW	ZERO		;mark buffer as unscanned
	DW	CONBUF,POKEB

	DW	CONBUF,INC,INC	;push first byte of buffer

RLOOP	DW	DUP		;duplicate buffer pointer
	DW	CIN		;get character
;DA	DW	DUP,COUT	;echo to screen

	DW	DUP,TPUSH,08H	;compare with backspace
	DW	IFEQ,BKSP-1

	DW	DUP,TPUSH,0DH	;compare with carriage return
	DW	IFEQ,EOL-1

	DW	SWAP,POKEB	;if neither, store in buffer
	DW	INC		;increment buffer pointer
	DW	JUMP,RLOOP-1	;and keep reading
	
BKSP	DW	TPOP,TPOP	;drop BS and buffer ptr copy
	DW	DEC		;backup pointer
	DW	TPUSH,20H,COUT	;print a space
	DW	TPUSH,08H,COUT	;and another backspace
	DW	JUMP,RLOOP-1
	
EOL	DW	TPOP,TPOP	;drop CR and buffer ptr copy
	DW	ZERO,SWAP,POKEB	;store final zero
	DW	TPUSH,0AH,COUT	;print a line feed
	DW	TRET		;and return


; Console Buffer
; DESCRIPTION: First byte contains the scan pointer which
; points to the next byte to be scanned. The remaining bytes
; contain characters read from the console.

CONBUF	DW	VARIABLE	;threaded code variable
	DS	101D		;long enough for most screens
; PROMPT - prompt the user
; DESCRIPTION: clears to a new line and prints a hyphen
PROMPT	DW	TCALL		;threaded code
	DW	TPUSH,PRMSG	;push prompt message
	DW	PRINTS		;and print it
	DW	TRET
	
PRMSG	DB	3,0DH,0AH,'-'

; PRINTS - prints string
; ENTRY : TOP - points to string
; DECRIPTION: Uses first byte of string as a character count.

PRINTS	DW	TCALL		;threaded code
	DW	FIRST		;get count
PRINTS1	DW	DUP,IFZ,PRINTX-1 ;if done return
	DW	SWAP,FIRST	;else get next character
	DW	COUT		;print it
	DW	SWAP,DEC	;decrement count
	DW	JUMP,PRINTS1-1	;and keep looping

PRINTX	DW	TPOP,TPOP	;drop count and pointer
	DW	TRET		;then return
	
; FIRST - get next byte of string on stack
; ENTRY: TOP   - ptr to string
; EXIT:  TOP   - first character of string
;	 TOP-1 - ptr to rest of string
; DESCRIPTION: useful for advancing through strings a byte
; at a time.

FIRST	DW	$+2	;C0DE
	POP	H	;get pointer
	MOV	C,M	;BC <- character
	MVI	B,0
	INX	H	;bump pointer
	PUSH	H	;restore pointer
	PUSH	B	;add character
	JMP	NEXT	;continue
	
; ENTRY: TOP - character to print
; DESCRIPTION: uses operating system to print character

COUT	DW	$+2	;C0DE
	POP	B	;C <- character
	MOV	E,C	;E <- character
	MVI	C,CONOUT
	CALL	BDOS	;print it
	JMP	NEXT	;return

; CIN - character input routine
; EXIT: TOP - character read from console
; DESCRIPTION: Uses operating system

CIN	DW	$+2	;CODE
	MVI	C,CONIN
	CALL	BDOS	;print it
	MOV	L,A	;HL <- character
	MVI	H,0
	PUSH	H	;push on stack
	JMP	NEXT	;return

;********************************************************************
; Listing 15. Page 89, 90, and 92
;********************************************************************
; SCAN - Scan for next word
; ENTRY: No Values Expected
; EXIT:  TOP   - -1 if word found, 0 if word not found
;	 TOP-1 - ptr to word if found (else nothing)
; DESCRIPTION: first byte of buffer contains a counter of
; characters already scanned. The next word is moved to the
; beginning of the line with a leading byte count.

SCAN	DW	$+2		;CODE
	LXI	H,CONBUF+2	;BC <- character co
	MOV	C,M
	MVI	B,0
	INR	M		;test for end of line already
	JZ	SCANX		;if yes
	INX	H		;HL <- scanning start point
	DAD	B
	MOV	B,C		;B <- character count
SCAN1	INX	H		;increment pointer
	INR	B		;increment count
	MOV	A,M		;get next character
	ORA	A		;test for end of line
	JZ	SCANX		;if yes,
	CPI	20H		;else, check for blank
	JZ	SCAN1		;if yes, skip it

	LXI	D,CONBUF+3	;else begin moving word
	MVI	C,0		;C <- size of string
SCAN2	INX	D
	STAX	D
	INR	C		;inc word size
	INR	B		;inc scanned char count
	INX	H		;get next byte
	MOV	A,M
	ORA	A		;test for end of line
	JNZ	SCAN3		;if not,
	;MVI	B,-1		;else set eol flag
	MVI	B,0FFH		;DA else set eol flag
	MVI	A,20H		;and change EOL to delimiter
SCAN3	CPI	20H		;check for space
	JNZ	SCAN2		;if not yet

	LXI	H,CONBUF+2	;else save scanned char count
	MOV	M,B
	INX	H		;and word size
	MOV	M,C
	PUSH	H		;and return word pointer
	LXI	H,-1
	PUSH	H
	JMP	NEXT

;SCANX	MVI	A,-1		;hit end of line
SCANX	MVI	A,0FFH		;DA hit end of line
	STA	CONBUF+2	;mark buffer empty
	LXI	H,0		;return a zero
	PUSH	H
	JMP	NEXT

; CONBXA - convert binary to ascii
; ENTRY: TOP - 16 bit positive integer
; EXIT:  TOP - address of converted ASCII string
; DESCRIPTION: pushes the digits of the number
; on to the stack, least significant digits first.
; Then pops them up and stores them in a local
; buffer.

CONBXA	DW	TCALL		;threaded code
	DW	NEGONE,SWAP	;mark end of string with -1	
CONB1	DW	TPUSH,10,DIV	;divide number by ten
	DW	SWAP		;put quotient on top
	DW	DUP
	DW	IFNZ,CONB1-1	;continue until Q = 0
	
	DW	TPOP		;then drop quotient,
	DW	ZERO		;store zero in first
	DW	NBUFR,POKEB	;byte of buffer,
				;and store string
CONB2	DW	DUP,NEGONE	;test for end of string
	DW	IFEQ,CONB3-1	;if yes
	DW	NBUFR,PEEKB	;else, increment byte count
	DW	INC
	DW	NBUFR,POKEB
	DW	TPUSH,'0',TADD	;convert digit to ascii
				;and store in next location
	DW	NBUFR
	DW	NBUFR,PEEKB,TADD
	DW	POKEB
	DW	JUMP,CONB2-1	;repeat

CONB3	DW	TPOP		;drop end of string marker
	DW	NBUFR		;push return buffer address
	DW	TRET		;and return
	
NBUFR	DW	VARIABLE	;threaded variable
	DS	10		;plenty long enough

; CONAXB - convert ASCII decimal string to binary
; Entry: TOP   - pointer to string
; Exit:  TOP   - -1 if converted to binary
; 		  0 if not 
;	 TOP-1 - value of number if converted
;		 ptr to string if not
; DESCRIPTION: converts only positive, unsigned
; integers. Written in assembly because I had it around
; and didn't want to rewrite it in threaded code. 

CONAXB	DW	$+2	;CODE
	POP	D	;get string pointer
	PUSH	D	;but leave on stack
	LDAX	D	;get byte count
	MOV	B,A
	LXI	H,0	;starting value
	
CONA1	INX	D
	LDAX	D	;get next character
	CPI	'0'	;test for digit
	JC	CONAX	;if not
	CPI	'9'+1
	JNC	CONAX	;if not
	SUI	'0'	;convert to binary
	PUSH	D	;save pointer
	DAD	H	;multiply current value by 10
	PUSH	H
	DAD	H
	DAD	H
	POP	D
	DAD	D
	MOV	E,A	;add new binary digi
	MVI	D,0
	DAD	D
	POP	D	;restore pointer
	DCR	B	;dec count
	JNZ	CONA1	;continue until done
	POP	D	;then drop pointer,
	PUSH	H	;push number
	LXI	H,-1	;and -1
	PUSH	H
	JMP	NEXT

CONAX	LXI	H,0	;failure: push a zero
	PUSH	H
	JMP	NEXT
	
; DIV - 16 bit divide
; ENTRY: TOP   - divisor
;	 TOP-1 - dividend
; EXIT:	 TOP   - remainder
;	 TOP-1 - quotient
; DESCRIPTION: performs a 32 bit by 16 bit division for
; positive integers only. The quotient must be resolved
; in 16 bits.

DIV	DW	$+2	;CODE
	POP	B	;BC <- divisor
	POP	D	;HLDE <- dividend
	LXI	H,0
	CALL	DIV1	;do division
	PUSH	D	;push quotient
	PUSH	H	;push remainder
	JMP	NEXT
	
DIV1	DCX	B	;negate BC
	MOV	A,B
	CMA
	MOV	B,A
	MOV	A,C
	CMA
	MOV	C,A
	MVI	A,16D	;iteration count
DIV2	DAD	H	;shift HLDE
	PUSH	PSW	;save overflow
	XCHG
	DAD	H
	XCHG
	JNC	DIV3
	INR	L
DIV3	POP	PSW	;get overflow
	JC	DIV5	;if overflow, force subtraction
	PUSH	H	;else,save dividend
	
	DAD	B	;attempt subtraction
	JC	DIV4	;if it goes
	POP	H	;else restore dividend
	JMP	DIV6
DIV4	INR	E	;increment quotient
	INX	SP	;drop old dividend
	INX	SP
	JMP	DIV6
DIV5	DAD	B	;force subtraction
	INR	E	;inc quotient
DIV6	DCR	A	;decrement count
	JNZ	DIV2	;repeat until done
	RET
	
;DA Word used to exit Forth to CP/M
EXITOS	DW	$+2	;CODE
	JMP	CPMEXIT	;DA Exit Forth to CP/M
	
; The Names in the dictionary
; Notice that the actual printed names are chosen for typing
; convenience and do not necessarily match the internal names
; which must conform to the assembler's rules. Also, not all
; functions have been included here.

NAMEBEG	EQU	$
 DB	1,'+'
 DW		TADD
 DB	1,'-'
 DW		TSUB
 DB	4,'/MOD'
 DW		DIV
 DB	7,'EXECUTE'
 DW		EXECUTE
 DB	5,'CLEAR'
 DW		CLEAR
 DB	5,'MATCH'
 DW		MATCH
 DB	6,'LOOKUP'
 DW		LOOKUP
 DB	4,'EXEC'
 DW		EXEC
 DB	6,'MEMORY'
 DW		MEMORY
 DB	6,'CONBXA'
 DW		CONBXA
 DB	3,'INC'
 DW		INC
 DB	3,'DEC'
 DW		DEC
 DB	5,'MINUS'
 DW		MINUS
 DB	5,'PEEKW'
 DW		PEEKW
 DB	5,'PEEKB'
 DW		PEEKB
 DB	5,'POKEW'
 DW		POKEW
 DB	5,'POKEB'
 DW		POKEB
 DB	3,'POP'
 DW		TPOP
 DB	4,'SWAP'
 DW 		SWAP
 DB	3,'DUP'
 DW		DUP
 DB	5,'FIRST'
 DW		FIRST
 DB	4,'EXITOS'
 DW		EXIT
 DB	0		;end of dictionary
NAMEEND EQU	$-1

DICSIZE EQU	NAMEEND-NAMEBEG+1	;dictionary size in bytes

; Initialization Code
; Execcuted on startup of system but eventually overwritten by
; the expanding dictionary

; DICMOVE - moves the dictionary names
; 	    to the top of available memory

DICMOVE	LHLD	MEMORY+2	;DE <- top of memory
	XCHG
	LXI	H,NAMEEND	;HL <- source (end of names)
	LXI	B,DICSIZE	;BC <- byte count
				;transfer loop
DIC1	MOV	A,M		;get next byte
	STAX	D		;move it
	DCX	H		;dec source pointer
	DCX	D		;dec target pointer
	DCX	B		;dec count
	MOV	A,B		;test for zero
	ORA	C
	JNZ	DIC1		;not yet

	XCHG			;set dictionary variable
	INX	H
	SHLD	NAMES+2

	RET			;DA
	END	ENTRY
