
; low level routines (partly untested!!)
; run in DCPU-16 Studio

; adds 32 bit integers (works)
; A: address of first int
; B: address of second int
:int32_add
          SET PUSH, C      ; Save C
          ADD [A], [B]     ; Add lower parts
          SET C, O         ; Save overflow
          ADD A, 1
          ADD B, 1
          ADD [A], [B]     ; Add upper parts
          ADD [A], C       ; Add overflow
          SUB A, 1
          SUB B, 1
          SET C, POP       ; Restore C
          SET PC, POP      ; Jump back

; subtracts 32 bit integers (works)
; A: address of first int
; B: address of second int
:int32_sub
          SET PUSH, C      ; Save C
          SUB [A], [B]
          SET C, O
          ADD A, 1
          ADD B, 1
          ADD [A], C
          SUB [A], [B]
          SUB A, 1
          SUB B, 1
          SET C, POP
          SET PC, POP

; prints a text to stdout (untested)
; A: address of the text
:text_out
          SET PUSH, A
          SET PUSH, B
          SET PUSH, C
          SET PUSH, I
          SET PUSH, J

          SET B, text_color
          SET I, text_cursor

:text_out_loop
          SET C, [A]
          IFE C, 0x0000
              SET PC, text_out_end
          IFG 0x00FF, C
              AND C, 0x00FF
          AND C, B
          SET [I], C

          ADD A, 1
          ADD I, 1

          IFG 0x812C, I
              JSR scroll

          SET PC, text_out_loop

:text_out_scroll
          JSR scroll
          SET I, text_cursor

:text_out_end
          SET J, POP
          SET I, POP
          SET C, POP
          SET B, POP
          SET A, POP
          SET PC, POP

; Scrolls the screen one line (untested)
:scroll
          SET PUSH, X
          SET PUSH, Y

          SET X, 0x8000
          SET Y, 0x801E

:scroll_loop1
          SET [X], [Y]
          ADD X, 1
          ADD Y, 1
          IFE Y, 0x812C
              SET PC, scroll_loop2
          SET PC, scroll_loop1

:scroll_loop2
          SET [X], 0x1000
          ADD X, 1
          IFE X, 0x812C
              SET PC, scroll_end
          SET PC, scroll_loop2

:scroll_end
          SUB text_cursor, 0x1E
          SET Y, POP
          SET X, POP
          SET PC, POP

:text_out_end
		  SET B, POP
		  SET A, POP
		  SET PC, POP
	
:text_cursor data 0x8000
:text_color  data 0x1000
