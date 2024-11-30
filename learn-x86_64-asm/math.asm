	;; Program to practice mathematical operations in x86-64 assembly.
	global _start
	section .bss
sum_buffer:	resb 10		;Reserve 10 bytes of uninitialized data

	section .text
_start:
	;; Adding two numbers where they are in registers already
	mov rdi, 15
	mov rsi, 10
	add rdi, rsi		;rdi += rsi (15 + 10 = 25)

	;; Before we print the integer, it needs to be converted to a string first.
	mov rdi, rdi		;Does nothing, but just want to show usage of loading integer value into rdi as the first argument.
	lea rsi, [sum_buffer]	;Load the effective address of sum_buffer into rsi.
	call int2string		;Call the subroutine, converting the integer in rdi into a string and storing it in memory at the address in rsi.

	mov rax, 1		;Write system call. We want to write the sum to stdout
	mov rdi, 1		;File descriptor (fd) for stdout is 1.
	;Buffer to output is already stored in rsi.
	mov rdx, 2		;"25" has 2 characters.
	syscall

	mov rax, 60		;Exit system call code.
	mov rdi, 0		;Exit(0) basically.
	syscall

int2string:			;Converts an integer (passed into rdi) to a string and stores it into the input buffer (passed into rsi).
	push rsi		;Push rsi onto the stack, so we can restore it before we return.

	;; If integer is 0, it's not negative.
	cmp rdi, 0
	jge i2s_positive

i2s_negative:
	mov dl, 0x2D		;ASCII minus '-'
	mov byte [rsi], dl	;Store minus sign into buffer.
	add rsi, 1		;Increment buffer pointer by 1 byte.
	neg rdi			;Take's two's complement of rdi and stores it back in rdi. RSB equivalent in ARM.

i2s_positive:
	mov rdx, 0		;Holds number of digits.
	mov rcx, 10		;Will be used for multiplication and division later.

	;If zero, store 0 in buffer and return.
	cmp rdi, 0
	je i2s_zero

i2s_digits:
	;; If integer is 0, store the digits into the input buffer in reverse order.
	cmp rdi, 0
	je i2s_reverse_digits

	;Dividing rdi/rcx, quotient goes into r8.
	push rdx
	mov rdx, 0 		;Top 64 bits of dividend go into rdx.
	mov rax, rdi		;Bottom 64 bits of dividend go into rax.
	;; Divisor is already in rcx, from i2s_positive, which is the correct register.
	div rcx			;rdx:rax (rdi) / rcx; Quotient stored in rax.
	pop rdx

	;; MLS r8, rax, rcx, rdi equivalent in ARM
	push rax
	imul rax, rcx
	push rdi
	sub rdi, rax
	mov r8, rdi
	pop rdi
	pop rax

	push r8
	mov rdi, rax
	add rdx, 1
	jmp i2s_digits

i2s_zero:
	mov dl, 0x30
	mov byte [rsi], dl	;Store 0 in buffer
	add rsi, 1
	jmp i2s_end

i2s_reverse_digits:
	pop r8
	add r8b, 0x30
	mov byte [rsi], r8b	;Store characterized number into input buffer
	add rsi, 1
	sub rdx, 1		;Decrement digit counter
	cmp rdx, 0
	jne i2s_reverse_digits	;If there are digits remaining, continue

i2s_end:
	;; Store null terminator at end of string.
	mov dl, 0
	mov byte [rsi], dl
	pop rsi			;Restore pointer address.
	ret
