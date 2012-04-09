; clear screen (for emulator)
JSR clear


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

; Copy the API.
SET A, 0x1000
JSR mem_reserve

SET B, A
SET A, api_start
SET C, api_end
SUB C, A
JSR mem_copy

; OS ready message
SET A, text_start_ok
JSR text_out

SET A, app01
SET B, app01_end
SUB B, app01
JSR proc_load

; The kernel constantly polls the keyboard.
:kernel_loop

    ;IFN [0x9000], 0 ; Could be done IN the driver. But is faster this way.
        JSR driver_keyboard

    JSR proc_suspend
    SET PC, kernel_loop

; START OF THE KEYBOARD DRIVER
:driver_keyboard
    SET PUSH, A
    SET PUSH, B

    XOR [entropy], [0x9000]     ; collect entropy for random

    SET A, keyboard_buffers

:driver_keyboard_loop
; Check to see if we have a buffer registered at this spot
    IFN [A], 0
        JSR driver_keyboard_save_to_buffer
; Increment to the next buffer as long as we aren't at the end
    ADD A, 1
    IFN A, keyboard_buffers_end
        SET PC, driver_keyboard_loop

    SET [0x9000], 0

SET B, POP
    SET A, POP
    SET PC, POP

:driver_keyboard_save_to_buffer
SET B, [A]
SET [B], [0x9000]
SET PC, POP

; END OF THE KEYBOARD DRIVER



SET PC, stop

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

      SET X, 0x8000 ; Set X to the video memory
      SET Y, 0x8020 ; Set Y to the second line in the video memory

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


:get_pos
      SET PUSH, B

      IFG A, 31
          SET PC, get_pos_clip
      IFG B, 15
          SET PC, get_pos_clip

      MUL B, 32
      ADD B, 0x8000
      ADD B, A

      SET A, B

:get_pos_skip
      SET B, POP
      SET PC, POP

:get_pos_clip
      SET A, 0x0000
      SET PC, get_pos_skip


:char_put
      SET PUSH, A

      JSR get_pos
      SET [A], C

      SET A, POP
      SET PC, POP


; Converts a Number into a Decimal String
; A: Number
; B: StrBuffer (length 5)
:int2dec
      SET PUSH, A
      SET PUSH, B

      ADD B, 4

:int2dec_loop
      SET C, A
      MOD C, 10

      IFE C, 0 ;0
          SET [B], 0x0030
      IFE C, 1 ;1
          SET [B], 0x0031
      IFE C, 2 ;2
          SET [B], 0x0032
      IFE C, 3 ;3
          SET [B], 0x0033
      IFE C, 4 ;4
          SET [B], 0x0034
      IFE C, 5 ;5
          SET [B], 0x0035
      IFE C, 6 ;6
          SET [B], 0x0036
      IFE C, 7 ;7
          SET [B], 0x0037
      IFE C, 8 ;8
          SET [B], 0x0038
      IFE C, 9 ;9
          SET [B], 0x0039

      DIV A, 10
      SUB B, 1
      IFE A, 0
          SET PC, int2dec_end
      IFG A, 9
          SET PC, int2dec_loop

      SET C, A
      SET PC, int2dec_loop

:int2dec_end
      SET B, POP
      SET A, POP
      SET PC, POP

; Converts a Number into a Hexadecimal String
; A: Number
; B: StrBuffer (length 4)
:int2hex
      SET PUSH, A
      SET PUSH, B

      ADD B, 3

:int2hex_loop
      SET C, A
      MOD C, 16

      IFE C, 0 ;0
          SET [B], 0x0030
      IFE C, 1 ;1
          SET [B], 0x0031
      IFE C, 2 ;2
          SET [B], 0x0032
      IFE C, 3 ;3
          SET [B], 0x0033
      IFE C, 4 ;4
          SET [B], 0x0034
      IFE C, 5 ;5
          SET [B], 0x0035
      IFE C, 6 ;6
          SET [B], 0x0036
      IFE C, 7 ;7
          SET [B], 0x0037
      IFE C, 8 ;8
          SET [B], 0x0038
      IFE C, 9 ;9
          SET [B], 0x0039
      IFE C, 10 ;A
          SET [B], 0x0041
      IFE C, 11 ;B
          SET [B], 0x0042
      IFE C, 12 ;C
          SET [B], 0x0043
      IFE C, 13 ;D
          SET [B], 0x0044
      IFE C, 14 ;E
          SET [B], 0x0045
      IFE C, 15 ;F
          SET [B], 0x0046

      DIV A, 16
      SUB B, 1
      IFE A, 0
          SET PC, int2hex_end
      IFG A, 15
          SET PC, int2hex_loop

      SET C, A
      SET PC, int2hex_loop

:int2hex_end
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
      SHR [entropy], 1

      BOR [A], 0x0003
      SUB A, mem_table
      MUL A, 2048
      SET PC, mem_alloc_end

:mem_alloc_upper
      SHL [entropy], 1

      BOR [A], 0x0300
      SUB A, mem_table
      MUL A, 2048
      ADD A, 1024
      SET PC, mem_alloc_end

; Frees the memory previously reserved
; A: Address of or in the memory to be freed
:mem_free
      SET PUSH, A
      SET PUSH, B

      SET B, A ; Make the Address the start address
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

      SET B, A ; Make the Address the start address
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

      XOR [entropy], C

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





; Returns the version of AtlasOS
; Takes: ---
; Returns:
; A: main version
; B: subversion
:os_version
      SET A, [os_version_main]
      SET B, [os_version_sub]

; Returns the ID of the current process
; Takes: ---
; Returns:
; A: process ID
:proc_id
      SET A, [proc_current]
      SET PC, POP

; Returns the start address of the current process
; Takes: ---
; Returns:
; A: start address
:proc_get_addr
      JSR proc_id

:proc_get_addr_of
      JSR proc_get_info

      ADD A, 10
      SET A, [A]
      SET PC, POP

; Returns the flags of the current process
; Takes: ---
; Returns:
; A: flags
:proc_get_flags
      JSR proc_id

:proc_get_flags_of
      JSR proc_get_info_of

      ADD A, 11
      SET A, [A]
      SET PC, POP

; Returns the address of the process info structure
; Takes: ---
; Returns:
; A: address
:proc_get_info
      JSR proc_id

:proc_get_info_of
      MUL A, 12
      ADD A, proc_buffer
      SET PC, POP

; Sets the flags of the current process
; Takes:
; A: flags
; Returns: ---
:proc_set_flags
      SET PUSH, A
      JSR proc_get_info
      ADD A, 11
      IFN A, 11
          SET [A], PEEK
      SET A, POP
      SET PC, POP

; Sets the flags of a process
; Takes:
; A: process ID
; B: flags
; Returns: ---
:proc_set_flags_of
      SET PUSH, A
      JSR proc_get_info_of
      ADD A, 11
      IFN A, 11
          SET [A], B
      SET A, POP
      SET PC, POP






; Sets the active flag of the process
; Takes:
; A: process ID
; Returns: ---
:proc_set_flag_active_of
      SET PUSH, B
      SET PUSH, A

      JSR proc_get_flags_of
      BOR A, 0x0001
      SET B, A
      SET A, POP
      JSR proc_set_flags_of

      SET B, POP
      SET PC, POP

; Resets the active flag of the process
; Takes:
; A: process ID
; Returns: ---
:proc_reset_flag_active_of
      SET PUSH, B
      SET PUSH, A

      JSR proc_get_flags_of
      AND A, 0xFFFE
      SET B, A
      SET A, POP
      JSR proc_set_flags_of

      SET B, POP
      SET PC, POP

; Toggles the active flag of the process
; Takes:
; A: process ID
; Returns:
; A: 1 - active, 0 - inactive
:proc_flag_is_active_of
      JSR proc_get_flags_of
      AND A, 0x0001
      SET PC, POP

















; Generates a list of all process IDs and hands it over to a callback-function
; Takes:
; A: address of the callback-function (Takes: A: process ID, Returns: ---)
; Returns: ---
:proc_callback_list
      SET PUSH, B
      SET PUSH, A

      SET B, proc_table

:proc_callback_list_loop
      SET A, [B]
      IFN A, 0
          JSR PEEK
      ADD B, 12
      IFN B, proc_table_end
          SET PC, proc_callback_list_loop

      SET A, POP
      SET B, POP
      SET PC, POP

; proc_suspend
:proc_suspend
      SET [proc_buffer], [proc_current] ; Buffer the registers of the current process
      SET [proc_buffer_a], A
      SET [proc_buffer_b], B
      SET [proc_buffer_c], C
      SET [proc_buffer_x], X
      SET [proc_buffer_y], Y
      SET [proc_buffer_z], Z
      SET [proc_buffer_i], I
      SET [proc_buffer_j], J
      SET [proc_buffer_sp], SP

      ; Restore the Stackpointer so we can call subroutines
      SET SP, [proc_table10]

      ; Copy the buffered state to the table
      JSR proc_get_info
      SET B, A
      SET A, proc_buffer

      SET C, 12

      JSR mem_copy

      ; Process saved, now restore the next proc
      SET A, B

:proc_kill_me_hook
      ADD A, 12
:proc_suspend_loop
      IFE A, proc_table_end
          SET A, proc_table
      SET X, [A]
      IFN X, 0x0000
          SET PC, proc_suspend_invoke
      ADD A, 12
      SET PC, proc_suspend_loop

:proc_suspend_invoke
      ; Copy the process information to the registers
      SET B, proc_buffer
      JSR mem_copy

      SET [proc_current], [proc_buffer]
      SET A, [proc_buffer_a]
      SET B, [proc_buffer_b]
      SET C, [proc_buffer_c]
      SET X, [proc_buffer_x]
      SET Y, [proc_buffer_y]
      SET Z, [proc_buffer_z]
      SET I, [proc_buffer_i]
      SET J, [proc_buffer_j]
      SET SP, [proc_buffer_sp]
      SET PC, POP ; Jump into the Programm

; Loads a new process into memory
; A: Begin of the BLOB
; B: Length of the BLOB
:proc_load
      SET PUSH, B
      SET PUSH, C
      SET PUSH, X
      SET PUSH, Y

      SET X, proc_table

:proc_load_loop
      IFE [X], 0x0000
          SET PC, proc_load_to

      ADD X, 12
      IFN X, proc_table_end
          SET PC, proc_load_loop

:proc_load_error
      SET A, text_proc_load_error
      JSR text_out
      SET A, 0

:proc_load_end
      SET Y, POP
      SET X, POP
      SET C, POP
      SET B, POP
      SET PC, POP

:proc_load_to
      ; Calculate the ProcID
      SET [X], X
      SUB [X], proc_table
      DIV [X], 12
      ADD [X], 1

      ; X = ProcInfo Addr

      ; Finaly load the Process
      SET C, B
      SET Y, A
      JSR mem_alloc

      IFE A, 0
          SET PC, proc_load_error

      SET B, A
      SET A, Y
      JSR mem_copy

      SET A, [X] ; A return the ProcID

      ADD X, 1 ; A
      SET [X], 0
      ADD X, 1 ; B
      SET [X], 0
      ADD X, 1 ; C
      SET [X], 0
      ADD X, 1 ; X
      SET [X], 0
      ADD X, 1 ; Y
      SET [X], 0
      ADD X, 1 ; Z
      SET [X], 0
      ADD X, 1 ; I
      SET [X], 0
      ADD X, 1 ; J
      SET [X], 0
      ADD X, 1 ; SP
      SET [X], B
      ADD [X], 1023
      SET Y, [X] ; Save stack address
      ADD X, 1
      SET [X], B
      ADD X, 1 ; Flags
      SET [X], 0x0001

      SET [Y], B ; "Push" the "return" address on the stack

      SET PC, proc_load_end

:proc_kill_me
      JSR proc_id       ; Save process ID
      SET X, A
      JSR proc_get_info_of ; Save process info address
      SET Y, A
      ADD A, 10         ; Save memory page
      SET Z, [A]

      SET A, Y          ; Delete the process info entry
      SET B, 12
      JSR mem_clear

      SET A, Z          ; Free the process memory page
      JSR mem_free      ; ! It will not be cleared !

      SET A, Y          ; Restore the pointer to the info entry
      SET C, 12
      SET PC, proc_kill_me_hook

:proc_kill
      SET PUSH, A
      SET PUSH, B
      SET PUSH, Y
      SET PUSH, Z

      JSR proc_get_info_of ; Save process info address
      SET Y, A
      ADD A, 10         ; Save memory page
      SET Z, [A]

      SET A, Y          ; Delete the process info entry
      SET B, 12
      JSR mem_clear

      SET A, Z          ; Free the process memory page
      JSR mem_free      ; ! It will not be cleared !

      SET Z, POP
      SET Y, POP
      SET B, POP
      SET A, POP
      SET PC, POP

; ##############################################################



; PUSHes all registers to the stack
:pusha
     SET [pushpop_buffer], POP ; Save jump-back-address

     SET PUSH, A
     SET PUSH, B
     SET PUSH, C
     SET PUSH, X
     SET PUSH, Y
     SET PUSH, Z
     SET PUSH, I
     SET PUSH, J

     SET PC, [pushpop_buffer] ; jump back

; POPs all registers from the stack
:popa
     SET [pushpop_buffer], POP ; Save jump-back-address

     SET J, POP
     SET I, POP
     SET Z, POP
     SET Y, POP
     SET X, POP
     SET C, POP
     SET B, POP
     SET A, POP

     SET PC, [pushpop_buffer] ; jump back

:pushpop_buffer dat 0x0000




; Driver functions

; Registers a new keyboard buffer
; Takes:
; A: Address of the buffer
:keyboard_register
    SET PUSH, A

    SET A, keyboard_buffers

:keyboard_register_loop
    IFE [A], 0
        SET PC, keyboard_register_set
    ADD A, 1
    IFN A, keyboard_buffers_end
        SET PC, keyboard_register_loop

:keyboard_register_end
    SET A, POP
    SET PC, POP

:keyboard_register_set
    SET [A], PEEK
    SET PC, keyboard_register_end


; Unregisters a keyboard buffer
; Takes:
; A: Address of the buffer
:keyboard_unregister
    SET PUSH, A

    SET A, keyboard_buffers

:keyboard_unregister_loop
    IFE [A], PEEK
        SET PC, keyboard_unregister_unset
    ADD A, 1
    IFN A, keyboard_buffers_end
        SET PC, keyboard_unregister_loop

:keyboard_unregister_end
    SET A, POP
    SET PC, POP

:keyboard_unregister_unset
    SET [A], 0x0000
    SET PC, keyboard_register_end


; Copies a string from a source to a destination
; Takes:
; A: source address
; B: destination address
:strcpy
    SET PUSH, A
    SET PUSH, B

:strcpy_loop
    IFE A, 0
        SET PC, strcpy_end
    SET [B], [A]
    ADD A, 1
    ADD B, 1
    SET PC, strcpy_loop

:strcpy_end
    SET B, POP
    SET A, POP

; Copies a string from a source to a destination with length limitation
; Takes:
; A: source
; B: destination
; C: length
:strncpy
    SET PUSH, A
    SET PUSH, B
    SET PUSH, C

    ADD C, B
:strncpy_loop1
    IFE A, 0
        SET PC, strncpy_loop2
    SET [B], [A]
    ADD A, 1
    ADD B, 1
    IFE B, C
        SET PC, strncpy_end
    SET PC, strncpy_loop1

:strncpy_loop2
    SET [B], 0
    ADD B, 1
    IFN B, C
        SET PC, strncpy_loop2

:strncpy_end
    SET C, POP
    SET B, POP
    SET A, POP

; Compares strings and stores the result in C
; Takes:
; A: source #1
; B: source #2
:strcmp
    SET PUSH, A
    SET PUSH, B

:strcmp_loop
    SET C, 0

    IFE [A], [B]
    JSR strcmp_checkend

    IFE C, 1
        SET PC, strcmp_end

    IFN [A], [B]
        SET PC, strcmp_end

    ADD A, 1
    ADD B, 1
    SET PC, strcmp_loop

:strcmp_checkend
    IFE [A], 0
        SET C, 1
    SET PC, POP

:strcmp_end
    SET B, POP
    SET A, POP
    SET PC, POP

; Reads a line of chars from the keyboard
; A: String buffer address
; B: Length
; C: Keybuffer
:read_line
     SET PUSH, B
     SET PUSH, C
     SET PUSH, A

     JSR mem_clear ; Clear the buffer

     ; Store the starting location
     ; Maybe find a push/pop way to do this so we don't tie up a register
     SET X, A

     ADD B, A

:read_line_loop
     IFE [C], 0
         SET PC, read_line_skip
     IFE [C], 0xA
         SET PC, read_line_end
     IFE [C], 0x8
         SET PC, read_line_backspace
     IFE A, B
         SET PC, read_line_skip

     SET [A], [C]

; Put the character on-screen so the user can see what is being typed
; Maybe have this toggleable?
     SET PUSH, A
     SET PUSH, B
     SET B, [A]
     BOR B, 0x7400
     SET A, B
     SET B, [video_cur]
     SET [B], A
     ADD [video_cur], 1
     SET B, POP
     SET A, POP

     ADD A, 1

:read_line_skip
     JSR proc_suspend
     SET PC, read_line_loop

:read_line_backspace
; Ensure we don't backspace past the beginning
     IFE A, PEEK
     SET PC, read_line_skip

     SET PUSH, A
     SET PUSH, B
     SUB [video_cur], 1
     SET B, [video_cur]
     SET [B], 0
     SET B, POP
     SET A, POP
     SUB A, 1
     SET PC, read_line_skip

;
:read_line_end
; Add the null terminator
     SET [A], 0
; Pop everything back out
     SET A, POP
     SET C, POP
     SET B, POP
     SET PC, POP

; Sleeps for some cycles
; A: number of process cycles to wait
:sleep
     IFE A, 0
     SET PC, POP
     SUB A, 1
     JSR proc_suspend
     SET PC, sleep

; Returns a randomized number
:random
     MUL [entropy], 0x1235
     ADD [entropy], 1
     MUL A, [entropy]
     SET A, O
     SET PC, POP

; Halts the CPU
:stop SET PC, stop

:data

; OS Variables
:os_version_main dat 0x0000
:os_version_sub dat 0x0002

:video_mem dat 0x8000
:video_col dat 0x7000
:video_cur dat 0x8000

:text_start dat "AtlasOS v0.3 starting... ", 0x00
:text_start_ok dat "OK", 0xA0, 0x00
:text_cmd dat "$>", 0xA0, 0x00
:text_proc_load_error dat "Error loading process...", 0xA0, 0x00

:mem_table
       dat 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
:mem_table_end

:proc_current dat 0x0001
:proc_buffer dat 0x0000
:proc_buffer_a dat 0x0000
:proc_buffer_b dat 0x0000
:proc_buffer_c dat 0x0000
:proc_buffer_x dat 0x0000
:proc_buffer_y dat 0x0000
:proc_buffer_z dat 0x0000
:proc_buffer_i dat 0x0000
:proc_buffer_j dat 0x0000
:proc_buffer_sp dat 0x0000
:proc_buffer_mem dat 0x0000
:proc_buffer_flags dat 0x0000
:proc_table
       dat 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
:proc_table10
       dat 0xFFFF, 0x0000, 0xFFFD ; OS-Proc
       dat 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000 ; 1st proc
       dat 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000 ; 2nd proc
       dat 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000 ; 3rd proc
       dat 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000 ; 4th proc
       dat 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000 ; 5th proc
:proc_table_end

:keyboard_buffers
dat 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
:keyboard_buffers_end

:entropy dat 0x0000

:api_start ; API starts at 0x1000
       SET PC, os_version ; Returns the version of AtlasOS
       SET PC, proc_id ; Returns the ID of the current process
       SET PC, proc_suspend ; Suspends the process and starts the next
       SET PC, proc_get_addr ; Returns the address of the current processes memory
       SET PC, proc_get_flags ; Returns the flags of the current process
       SET PC, proc_kill_me ; Kills the current process
       SET PC, proc_kill ; Kills a process
       SET PC, mem_alloc ; Allocates another 1024 words
       SET PC, mem_free ; Frees allocated memory
       SET PC, mem_clear ; Clears memory
       SET PC, pusha ; Pushes all registers to the stack
       SET PC, popa ; Pops all registers from the stack
       SET PC, strcpy ; Copies a string
       SET PC, strncpy ; Copies a string with length limitation
       SET PC, text_out ; Displays a text on the screen
       SET PC, newline ; Linefeed
       SET PC, scroll ; Scrolls the screen one line
       SET PC, clear ; Clears the screen
       SET PC, char_put ; Puts a chat on the screen
       SET PC, read_line ; Reads a line from the keyboard to a buffer
       SET PC, random ; Gets a random number
       SET PC, keyboard_register ; Registers a specific memory location as keyboard buffer
       SET PC, keyboard_unregister ; Unregisters a specific memory location
       SET PC, int2dec ; Converts a value into the decimal representation
       SET PC, int2hex ; Converts a value into the hexadecimal representation
:api_end

; BASH-like Process
:app01
:app01_start
SET I, app01_loop_end ; Calculate the length of the back-jump
SUB I, app01_loop

; Register our buffer with the driver
SET A, input_buffer
JSR keyboard_register

:app01_loop
; Display the prompt
set a, text_prompt
jsr text_out

; Reset the basics
set [ack_command], 0 ; reset command recognized

; Read a line from the keyboard
SET A, input_text_buffer
SET B, 32
SET C, input_buffer
SET X, 0
JSR read_line

; Check for the 'clear' command
set a, command_clear
set b, input_text_buffer
jsr strcmp
ife c, 1
jsr clearf

; Check for the 'version' command
set a, command_version
set b, input_text_buffer
jsr strcmp
ife c, 1
jsr versionf

; Check for the 'load' command
set a, command_load
set b, input_text_buffer
jsr strcmp
ife c, 1
jsr loadf

; Check for the 'kill' command
set a, command_kill
set b, input_text_buffer
jsr strcmp
ife c, 1
jsr killf


ifn [ack_command], 1
jsr unrecognizedf

JSR proc_suspend
    SUB PC, I
:app01_loop_end
; Command functions
:unrecognizedf
jsr newline
set a, text_unrecognized
jsr text_out
set pc, pop

:versionf
set [ack_command], 1 ; acknowledge recognized command
jsr newline
set a, text_versionoutput
jsr text_out
set pc, pop

:clearf
set [ack_command], 1 ; acknowledge recognized command
jsr clear
set pc, pop

:loadf
set [ack_command], 1 ; acknowledge recognized command
jsr newline
SET A, app02
SET B, app02_end
SUB B, app02
JSR proc_load
SET [last_proc], A   ; Save the process id
JSR proc_suspend
set pc, pop

:killf
     SET [ack_command], 1 ; acknowledge recognized command
     JSR newline
     SET A, [last_proc]
     JSR proc_kill
     JSR proc_suspend
     SET PC, POP

; Data
:input_text_buffer reserve 32 dat 0x00
:input_buffer dat 0x0000
:ack_command dat 0x00
:command_clear dat "clear", 0
:command_version dat "version", 0
:command_load dat "load", 0
:command_kill dat "kill", 0

:last_proc dat 0x0000

:text_unrecognized dat "Unrecognized command", 0xA0, 0x00
:text_versionoutput dat "Atlas-Shell v0.1", 0xA0, 0x00
:text_prompt dat "$> ", 0x00

:app01_end

:app02
SET X, 1
SET Y, 1

SET I, app02_loop_end
SUB I, app02_loop

SET J, 200

SET A, 0
SET B, 0
SET C, 0

:app02_loop

; Restore the old character
SET C, Z
IFN C, 0
    IFN C, 0x744F
        JSR char_put

SUB J, 1
IFE J, 0
    JSR proc_kill_me

ADD A, X
ADD B, Y

IFE A, 31
SET X, 0xFFFF

IFE B, 15
SET Y, 0xFFFF

IFE A, 0
SET X, 1

IFE B, 0
SET Y, 1

; Save the character before we write so we can restore later
SET PUSH, B
MUL B, 32
ADD B, A
ADD B, [video_mem]
SET Z, [B]
SET B, POP

SET C, 0x744F
JSR char_put

; Wait a bit so the 'ball' moves slower
SET PUSH, A
SET A, 8
JSR sleep
SET A, POP

JSR proc_suspend
SUB PC, I
:app02_loop_end
:app02_end


:kernel_end