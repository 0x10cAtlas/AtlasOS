
; low level routines
; runs best in DCPU-16 Studio (http://badsector.github.com/dcpustud/)

; Test the console-routines, then halt.
SET A, test_text
JSR text_out

SET PC, stop

; adds 32 bit integers (working)
; A: address of first int
; B: address of second int
:int32_add
      SET PUSH, C ; Save C
      ADD [A], [B] ; Add lower parts
      SET C, O ; Save overflow
      ADD A, 1
      ADD B, 1
      ADD [A], [B] ; Add upper parts
      ADD [A], C ; Add overflow
      SUB A, 1
      SUB B, 1
      SET C, POP ; Restore C
      SET PC, POP ; Jump back

; subtracts 32 bit integers (working)
; A: address of first int
; B: address of second int
:int32_sub
      SET PUSH, C ; Save C
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

; prints a text to stdout (working)
; A: address of the text
:text_out
      SET PUSH, A
      SET PUSH, B
      SET PUSH, C
      SET PUSH, I

      SET B, [video_col]
      SET I, [video_cur]

:text_out_loop
      SET C, [A]
      IFE C, 0x0000
          SET PC, text_out_end
      IFE C, 0x00A0
          SET PC, text_out_nl
      IFG C, 0x00FF
          AND C, 0x00FF
      BOR C, B
      SET [I], C
      ADD A, 1
      ADD I, 1
      IFE I, 0x8200
          SET PC, text_out_scroll
      SET PC, text_out_loop

:text_out_scroll
      SET [video_cur], I
      JSR scroll
      SET I, [video_cur]
      SET PC, text_out_loop

:text_out_nl
      SET [video_cur], I
      JSR newline
      SET I, [video_cur]
      ADD A, 1
      SET PC, text_out_loop

:text_out_end
      SET I, POP
      SET C, POP
      SET B, POP
      SET A, POP
      SET PC, POP

; Linefeed (working)
:newline
      SET PUSH, A
      SET PUSH, B

      SET A, 0x0020
      SET B, [video_cur]
     ; SUB B, 0x8000
      MOD B, A
      SUB A, B
      ADD [video_cur], A
      IFE [video_cur], 0x8200
          JSR scroll

      SET B, POP
      SET A, POP
      SET PC, POP

; Scrolls the screen one line (working)
:scroll
      SET PUSH, X
      SET PUSH, Y

      SET X, 0x8000
      SET Y, 0x8020

:scroll_loop1
      SET [X], [Y]
      ADD X, 1
      ADD Y, 1
      IFE Y, 0x8200
          SET PC, scroll_loop2
      SET PC, scroll_loop1

:scroll_loop2
      SET [X], [video_col]
      ADD X, 1
      IFE X, 0x8200
          SET PC, scroll_end
      SET PC, scroll_loop2

:scroll_end
      SUB [video_cur], 0x20
      SET Y, POP
      SET X, POP
      SET PC, POP

; Clears the screen and sets the cursor to the first line (working)
:clear
      SET PUSH, A
      SET PUSH, B

      SET A, [video_mem]
      SET B, [video_col]

:clear_loop
      SET [A], B
      ADD A, 1
      IFE A, 0x8200
          SET PC, clear_end
      SET PC, clear_loop

:clear_end
      SET [video_cur], [video_mem]
      SET B, POP
      SET A, POP
      SET PC, POP

; Halts the CPU
:stop SET PC, stop

:data
:video_mem dat 0x8000
:video_col dat 0x7000
:video_cur dat 0x8000

:test_text dat "AtlasOS v0.1", 0xA0, "Since there is no Keyboard-Controller yet this OS is pretty useless!", 0xA0, "Hope you enjoy it ;)", 0x00

:kernel_end
