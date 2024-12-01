	;; Program to practice mathematical operations in x86-64 assembly.
	global _start
	section .bss
sum_buffer:	resb 22

	section .data
main_prompt:	db "**********Welcome to the x86-64 asm calculator.*********", 0xA
	db "To use this calculator, enter in your first number, and press Enter.", 0xA
	db "Then enter in your operation (+, -), and press Enter.", 0xA
	db "Finally, enter in your second number and press Enter.", 0xA
	db "The result of num1 op num2 will be displayed.", 0xA, 0
main_prompt_len:	equ $ - main_prompt

	;;22 bytes because the largest signed 64-bit number is 19 digits long. Add one for the negative sign, one for the enter key, and one for the NULL byte.
first_number_buffer:	db 22 dup (0)
operation_buffer:	db 3 dup (0)
second_number_buffer:	db 22 dup (0)

result_str:	db "The result is: ", 0
result_str_len: equ $ - result_str

	;; File descriptors
stdin:	equ 0x0
stdout:	equ 0x1
stderr:	equ 0x2

	;; ASCII characters
ascii_plus:	equ 0x2B
ascii_minus:	equ 0x2D
ascii_enter:	equ 0xA

result:		db 22 dup (0)
	section .text
	
_start:
	CALL main
	RET 

	;; My main subroutine. I don't like _start lol.
main:	
	;; Output the main prompt, which gets displayed at the start of the program.
	LEA rsi, [main_prompt]
	MOV rdx, main_prompt_len
	CALL output_string

	;; Get the user's first number.
	MOV rdi, stdin
	LEA rsi, [first_number_buffer]
	MOV rdx, 22
	CALL read_string

	;; Get the user's operation.
	MOV rdi, stdin
	LEA rsi, [operation_buffer]
	MOV rdx, 3
	CALL read_string

	;; Get the user's second number.
	MOV rdi, stdin
	LEA rsi, [second_number_buffer]
	MOV rdx, 22
	CALL read_string

	;; Check if operation is '+'
	MOV sil, byte [operation_buffer]
	CMP sil, ascii_plus
	JE add_op

	MOV rdi, 0		;Exit(1); Invalid operation code
	JNE exit_program

add_op:
	LEA rdi, [first_number_buffer]
	CALL string2int
	MOV rsi, rax

	LEA rdi, [second_number_buffer]
	CALL string2int

	ADD rsi, rax
	MOV rdi, rsi
	LEA rsi, [result]
	MOV rdx, 22
	CALL int2string

	LEA rsi, [result_str]
	CALL output_string

	LEA rsi, [result]
	CALL output_string
	
	;; read_string reads a user input string from a file (fd passed into rdi) and stores it in memory at the pointer passed into rsi.
	;; This also takes in a parameter that determines how many characters to read (passed into rdx).
read_string:
	MOV rax, 0		;Code for system call read
	SYSCALL
	RET

	;; output_string outputs a string to stdout. The pointer to the string is passed inro rsi. The length of the string must also be passed into rdx.
output_string:
	MOV rdi, stdout
	MOV rax, 1		;Code for write system call.
	SYSCALL
	RET
	
int2string:			;Converts an integer (passed into rdi) to a string and stores it into the input buffer (passed into rsi).
	PUSH rsi		;Push rsi onto the stack, so we can restore it before we return.

	;; If integer is 0, it's not negative.
	CMP rdi, 0
	JGE i2s_positive

i2s_negative:
	MOV dl, 0x2D		;ASCII minus '-'
	MOV byte [rsi], dl	;Store minus sign into buffer.
	ADD rsi, 1		;Increment buffer pointer by 1 byte.
	NEG rdi			;Take's two's complement of rdi and stores it back in rdi. RSB equivalent in ARM.

i2s_positive:
	MOV rdx, 0		;Holds number of digits.
	MOV rcx, 10		;Will be used for multiplication and division later.

	;If zero, store 0 in buffer and return.
	CMP rdi, 0
	JE i2s_zero

i2s_digits:
	;; If integer is 0, store the digits into the input buffer in reverse order.
	CMP rdi, 0
	JE i2s_reverse_digits

	;Dividing rdi/rcx, quotient goes into r8.
	PUSH rdx
	MOV rdx, 0 		;Top 64 bits of dividend go into rdx.
	MOV rax, rdi		;Bottom 64 bits of dividend go into rax.
	;; Divisor is already in rcx, from i2s_positive, which is the correct register.
	DIV rcx			;rdx:rax (rdi) / rcx; Quotient stored in rax.
	POP rdx

	;; MLS r8, rax, rcx, rdi equivalent in ARM
	PUSH rax
	IMUL rax, rcx
	PUSH rdi
	SUB rdi, rax
	MOV r8, rdi
	POP rdi
	POP rax

	PUSH r8
	MOV rdi, rax
	ADD rdx, 1
	JMP i2s_digits

i2s_zero:
	MOV dl, 0x30
	MOV byte [rsi], dl	;Store 0 in buffer
	ADD rsi, 1
	JMP i2s_end

i2s_reverse_digits:
	POP r8
	ADD r8b, 0x30
	MOV byte [rsi], r8b	;Store characterized number into input buffer
	ADD rsi, 1
	SUB rdx, 1		;Decrement digit counter
	CMP rdx, 0
	JNE i2s_reverse_digits	;If there are digits remaining, continue

i2s_end:
	;; Store null terminator at end of string.
	MOV dl, 0
	MOV byte [rsi], dl
	POP rsi			;Restore pointer address.
	RET

	;; Exits the program; Error code passed into rdi
exit_program:
	MOV rax, 60
	SYSCALL

	;; Takes in a pointer to a string representng an integer, in rdi.
	;; Converts the string to an integer and returns it in rax.
string2int:
	MOV rsi, 0		;Negative number flag
	MOV r8, 10		;10 is used for multiplication step to preserve the digits place value.
	MOV rdx, 0		;Accumulator; Will store final result.
	XOR rcx, rcx		;Clear out rcx so it doesn't interfere with reg cl.
	
	;; Check if number is negative.
	MOV cl, byte [rdi]
	CMP cl, ascii_minus
	JNE s2i_positive

s2i_negative:
	MOV rsi, 1		;Set negative flag
	INC rdi			;Go past negative sign in memory.

s2i_positive:
	;; If we reached the enter character, stop converting.
	MOV cl, byte [rdi]
	CMP cl, ascii_enter
	JE s2i_fin_conv

	;; Convert the characterized number to an integer, preserving its place value.
	SUB cl, 0x30
	MOV rax, rdx
	MUL r8			;Multiply digit by 10 to preserve place value.
	ADD rax, rcx
	INC rdi
	JMP s2i_positive

s2i_fin_conv:
	;; If number isn't negative, return, else convert to negative number.
	CMP rsi, 0
	JE s2i_return

	NEG rax

s2i_return:
	ret
