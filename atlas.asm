
; clear screen (for emulator)
JSR clear

SET [0xE000], proc01_start
SET [0xD000], proc02_start

; low level routines
; runs best in DCPU-16 Studio (http://badsector.github.com/dcpustud/)

; Bootmessage
SET A, text_start
JSR text_out

; Reserve kernel-memory
SET A, 0
:kernel_mem
IFG A, kernel_end
    SET PC, kernel_mem_end
JSR mem_reserve
ADD A, 1024
SET PC, kernel_mem
:kernel_mem_end

; Reserve video-memory
SET A, 0x8000
JSR mem_reserve

; Reserve stack-memory
SET A, 0xFFFF
JSR mem_reserve

; OS ready message
SET A, text_start_ok
JSR text_out

SET A, text_cmd
JSR text_out


:wait_loop
;    SET PC, wait_loop


:kernel_loop

    ; The Kernel does nothing so far...

    JSR proc_suspend
    SET PC, kernel_loop

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
      SET [video_cur], I
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

; Finds free memory and reserves it
; Return:
; A: Start address of the newly allocated memory
:mem_alloc
      SET PUSH, B

      SET A, mem_table
:mem_alloc_loop
      SET B, [A]
      AND B, 0x00FF
      IFE B, 0x0000
          SET PC, mem_alloc_lower
      SET B, [A]
      AND B, 0xFF00
      IFE B, 0x0000
          SET PC, mem_alloc_upper
      ADD A, 1
      IFN A, mem_table_end
          SET PC, mem_alloc_loop
      SET A, 0x00

:mem_alloc_end
      SET B, POP
      SET PC, POP

:mem_alloc_lower
      BOR [A], 0x0003
      SUB A, mem_table
      MUL A, 1024
      SET PC, mem_alloc_end

:mem_alloc_upper
      BOR [A], 0x0300
      SUB A, mem_table
      MUL A, 1024
      ADD A, 1024
      SET PC, mem_alloc_end

; Frees the memory previously reserved
; A: Address of or in the memory to be freed
:mem_free
      SET PUSH, A
      SET PUSH, B

      SET B, A     ; Make the Address the start address
      MOD B, 1024
      SUB A, B

      DIV A, 1024
      SET B, A
      DIV A, 2
      AND B, 1
      ADD A, mem_table
      IFN B, 0
          SET PC, mem_free_upper
      SET B, [A]
      AND B, 0x00FF
      IFN B, 0x0001
          AND [A], 0xFF00
      SET PC, mem_free_end

:mem_free_upper
      SET B, [A]
      AND B, 0xFF00
      IFN B, 0x0100
          AND [A], 0x00FF

:mem_free_end
      SET B, POP
      SET A, POP
      SET PC, POP

; mem_reserve
; A: Address of or in the memory to reserve
:mem_reserve
      SET PUSH, A
      SET PUSH, B

      SET B, A     ; Make the Address the start address
      MOD B, 1024
      SUB A, B

      DIV A, 1024
      SET B, A
      DIV A, 2
      AND B, 1
      ADD A, mem_table
      IFN B, 0
          SET PC, mem_reserve_upper
      AND [A], 0xFF00
      BOR [A], 0x0001
      SET PC, mem_reserve_end

:mem_reserve_upper
      AND [A], 0x00FF
      BOR [A], 0x0100

:mem_reserve_end
      SET B, POP
      SET A, POP
      SET PC, POP

; mem_clear
; A: From Addr
; B: Length
:mem_clear
      SET PUSH, A
      SET PUSH, B

      ADD B, A

:mem_clear_loop
      SET [A], 0
      ADD A, 1
      IFN A, B
          SET PC, mem_clear_loop

      SET B, POP
      SET A, POP
      SET PC, POP

; A: source
; B: dest
; C: length
:mem_copy
      SET PUSH, A
      SET PUSH, B
      SET PUSH, C

      ; Calulate the last address
      ADD C, A

:mem_copy_loop
      SET [B], [A]
      ADD A, 1
      ADD B, 1
      IFN A, C
          SET PC, mem_copy_loop

      SET C, POP
      SET B, POP
      SET A, POP
      SET PC, POP

; ##############################################################

; proc_suspend
:proc_suspend
      SET [proc_buffer], [proc_current] ; Buffer the registers of the current process
      SET [proc_buffer1], A
      SET [proc_buffer2], B
      SET [proc_buffer3], C
      SET [proc_buffer4], X
      SET [proc_buffer5], Y
      SET [proc_buffer6], Z
      SET [proc_buffer7], I
      SET [proc_buffer8], J
;      SET [proc_buffer9], PC
      SET [proc_buffer10], SP

      ; Restore the Stackpointer so we can call subroutines
      SET SP, [proc_table10]

      ; Copy the buffered state to the table
      SET A, proc_buffer

      SET B, [proc_current]
      MUL B, 12
      ADD B, proc_buffer

      SET C, 12

      JSR mem_copy

      ; Process saved, now restore the next proc
      SET A, B
      ADD A, 12
:proc_suspend_loop
      IFE A, proc_table_end
          SET A, proc_table
      SET X, [A]
      IFN X, 0x0000
          SET PC, proc_suspend_invoke
      ADD A, 1
      SET PC, proc_suspend_loop

:proc_suspend_invoke
      ; Copy the Processinformation to the buffer
      SET B, proc_buffer
      JSR mem_copy

      SET [proc_current], [proc_buffer]
      SET A, [proc_buffer1]
      SET B, [proc_buffer2]
      SET C, [proc_buffer3]
      SET X, [proc_buffer4]
      SET Y, [proc_buffer5]
      SET Z, [proc_buffer6]
      SET I, [proc_buffer7]
      SET J, [proc_buffer8]
      SET SP, [proc_buffer10]
      SET PC, POP             ; Jump into the Programm

; ##############################################################

; Halts the CPU
:stop SET PC, stop

:data
:video_mem dat 0x8000
:video_col dat 0x7000
:video_cur dat 0x8000

:text_start dat "AtlasOS v0.1 starting... ", 0x00
:text_start_ok dat "OK", 0xA0, 0x00
:text_cmd dat "$>", 0xA0, 0x00

:mem_table
       dat 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
:mem_table_end

:proc_current
       dat 0x0001
:proc_buffer
       dat 0x0000
:proc_buffer1
       dat 0x0000
:proc_buffer2
       dat 0x0000
:proc_buffer3
       dat 0x0000
:proc_buffer4
       dat 0x0000
:proc_buffer5
       dat 0x0000
:proc_buffer6
       dat 0x0000
:proc_buffer7
       dat 0x0000
:proc_buffer8
       dat 0x0000
:proc_buffer9
       dat 0x0000
:proc_buffer10
       dat 0x0000
:proc_buffer11
       dat 0x0000
:proc_table
       dat 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
:proc_table10
       dat 0xFFFF, 0xFFFF ; OS-Proc
       dat 0x0002, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0xE000, 0x0000 ; First proc
       dat 0x0003, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0xD000, 0x0000 ; Second proc
:proc_table_end

:kernel_end






; First Process
:proc01

:proc01_start
       JSR mem_alloc
       SET B, A
       SET A, proc01_msg1
       JSR text_out
       JSR proc_suspend
       SET A, B
       JSR mem_free
       SET A, proc01_msg2
       JSR text_out
       JSR proc_suspend
       SET PC, proc01_start

:proc01_msg1
       dat "Memory allocated!", 0xA0, 0x00
:proc01_msg2
       dat "Memory freed!", 0xA0, 0x00

:proc02
:proc02_start
       SET A, proc02_msg1
       JSR text_out
       JSR proc_suspend
       SET PC, proc02_start

:proc02_msg1
       dat "Hello", 0xA0, 0x00