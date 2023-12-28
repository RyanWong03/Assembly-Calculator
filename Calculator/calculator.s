#Basic calculator that can perform basic arithmetic operations on integers ONLY.
#These operations include
	#Addition
	#Subtraction
	#Multiplication
	#Division
	#Exponential
	#Modulus
	#Factorial

.globl main
.data 0x10000000
prompt_first_num:	.asciiz "Enter an integer: "
.data 0x10000100
prompt_operation:	.asciiz "Enter an operation (+ (addition), - (subtraction), * (multiplication), / (division), % (modulus), ^ (exponent), ! (factorial)): "
.data 0x10000300
prompt_second_num:	.asciiz "Enter a second integer: "
.data 0x10000400
prompt_next_operation: .asciiz "Enter another operation or press the Enter key to quit: "
.data 0x10000500
result_string:	.asciiz " = "
.data 0x10000600
remainder_string:	.asciiz " with a remainder of "
.data 0x10000700
operation:	.space 2 #2 bytes of continguous memory to store the operation in
.data 0x10000710
factorial_error: .asciiz "ERROR: Can't compute the factorial of a negative number. Please try again.\n"
.data 0x10000800
division_error: .asciiz "ERROR: Can't divide by zero. Please try again.\n"
.data 0x10000900
overflow_error: .asciiz "ERROR: Arithmetic overflow. Please try again.\n"
.data 0x1000A000
modulus_error: .asciiz "ERROR: Can't modulus by zero. Please try again.\n"
.data 0x1000B000
quit_prompt:	.asciiz "\nPress Enter to quit, or any other key + Enter to continue.\n"
.data 0x1000B800
key_pressed: .space 3 #Stores the key pressed for continuation or quitting.

.text
#Error handling routines
#We have 5 instances of errors. Taking the factorial of a negative number, dividing by zero, modulus by zero, taking the square root of a negative number
# and integer overflow (number is larger than the maximum 32-bit signed integer).
error_overflow:
	#Print the error string out for overflow_error.
	lui $a0, 0x1000
	addi $a0, $a0, 0x900
	addi $v0, $0, 4
	syscall
	
	j calculator
	or $0, $0, $0
error_factorial:
	#Print the error string out for factorial_error.
	lui $a0, 0x1000
	addi $a0, $a0, 0x710
	addi $v0, $0, 4
	syscall

	j calculator
	or $0, $0, $0
error_division:
	#Print the error string out for division_error.
	lui $a0, 0x1000
	addi $a0, $a0, 0x800
	addi $v0, $0, 4
	syscall

	j calculator
	or $0, $0, $0
error_modulus:
	#Print the error string out for modulus_error.
	lui $a0, 0x1000
	ori $a0, $a0, 0xA000 #addi does not work with this hex value because for some reason it is ~40k...
	addi $v0, $0, 4
	syscall
	
	j calculator
	or $0, $0, $0
#Subroutine to print the expression when printing the result. Example: User inputs 2, +, 5. This subroutine should print "2+5 = " to the console.
#It will take in 3 arguments from $a1-$a3. The first argument is for the first integer. The second is for the operator. The third is for the second integer.
print_expression:
	add $a0, $0, $a1
	addi $v0, $0, 1 #System call code to print integer to the console.
	syscall

	add $a0, $0, $a2
	addi $v0, $0, 11 #System call code to print a character to the console
	syscall

	#Only print the second integer if it exists. There are no second integers on factorials and square roots.
	#We can check this based off the operation the user inputted.
	beq $t0, 0x21, continue #Checks if the operator was "!"
	or $0, $0, $0

	#make sure to add some bs symbol for square roots and beq for that as well

second_integer:
	add $a0, $0, $a3
	addi $v0, $0, 1 #System call code to print integer to the console.
	syscall

continue:
	lui $a0, 0x1000
	addi $a0, $a0, 0x500
	addi $v0, $0, 4
	syscall

	jr $ra
	or $0, $0, $0

calculator:	
	lui $a0, 0x1000 #Loading the address of prompt_first_num into $a0. We want to print this prompt to the console.
	addi $v0, $0, 4 #System call code to print a string to the console.
	syscall

	addi $v0, $0, 5 #System call code to read integer from the console. This will contain the first number.
	syscall

	#Store the value of the first number into a register. 
	#This must be done so we don't lose the number when we make another system call (which we will do multiple times)
	add $s0, $0, $v0
	
skip_first_number: #Just a label for convenience when we run this loop infinite times (until the user quits).
	lui $a0, 0x1000
	addi $a0, $a0, 0x100 #Loading the address of prompt_operation into $a0. We want to print this prompt to the console.
	addi $v0, $0, 4 #System call code to print a string to the console.
	syscall

	addi $a0, $a0, 0x600 #Loading the address of operation. This is where we will store the mathematical operation the user enters in.
	addi $a1, $0, 3 #Maximum number of characters we want to read from the standard input.
	addi $v0, $0, 8 #System call code to read a string from the console.
	syscall

	lui $a0, 0x1000
	addi $a0, $a0, 0x700 #Loading the address of operation. This is where we mathematical operation is stored in.
	lb $t0, 0($a0) #Loading the operation from memory at the address $a0 points to into a temporary register.

	#If the user enters factorial, we don't want to ask for a second integer because we don't need a second integer.
	#So we'll just go straight to computing the factorial
	beq $t0, 0x21, factorial #Checks if the operator was "!"
	or $0, $0, $0

	lui $a0, 0x1000
	addi $a0, $a0, 0x300 #Loading the address of prompt_second_num into $a0. We want to print this prompt to the console.
	addi $v0, $0, 4 #System call code to print a string to the console.
	syscall

	addi $v0, $0, 5 #System call code to read integer from the console. This will contain the second number.
	syscall

	add $s1, $0, $v0 #Store the value of the second number into a register. We are doing the same thing we did with the first number.

	#Now we'll check which operation the user entered based on the ones that require 2 numbers to compute.	
	beq $t0, 0x2B, Add #Checks if the operator was "+"
	beq $t0, 0x2D, subtract #Checks if the operator was "-"
	beq $t0, 0x2A, multiply #Checks if the operator was "*"
	beq $t0, 0x2F, divide #Checks if the operator was "/"
	beq $t0, 0x5E, exponent #Checks if the operator was "^"
	beq $t0, 0x25, modulus #Checks if the operator was "%"
	or $0, $0, $0
	#print string saying something went wrong, please try again and jump back to calculator label

Add:
	add $v1, $s0, $s1 #Sum of the two numbers the user inputted.
	j calculation_finished #This avoids us executing code in the other operation labels (subtract, etc).
	or $0, $0, $0 #jump delay slot

subtract:
	#make sure to handle overflow. if user enters in the max 32 bit value signed and they subtract a number < 0, handle that. just print a message like "integer overflow"
	sub $v1, $s0, $s1 #Difference of the two numbers the user inputted.
	j calculation_finished #This avoids us executing code in the other operation labels (multiply, etc).
	or $0, $0, $0 #jump delay slot

multiply:
	mult $s0, $s1 #Multiply the two numbers together
	mfhi $t1 #Move the upper 32 bits of the product into a register
	slt $t1, $t1, 1
	beq $t1, $0 error_overflow 
	mflo $v1 #Move the lower 32 bits of the product into a register

	j calculation_finished
	or $0, $0, $0

divide:
	#Is the user trying to divide by 0?
	beq $s1, $0, error_division
	#Although division by 0 is undefined, it will not cause any errors. However, we still don't want the user to be able to do it.
	#The division instruction will fill the branch delay slot just to optimize the code. 
	div $s0, $s1 #Divide the two numbers together
	mfhi $v1 #Move the remainder into a register
	mflo $t2 #Move the quotient into a register
	
	#This is not a leaf routine, so we must push the return address onto the stack to avoid an infinite loop.
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#Passing in the three arguments to print_expression
	add $a1, $0, $s0
	add $a2, $0, $t0
	add $a3, $0, $s1

	jal print_expression
	or $0, $0, $0

	#We want to print the quotient out, then the remainder string, then the remainder. 
	add $a0, $0, $t2 
	addi $v0, $0, 1
	syscall

	lui $a0, 0x1000
	addi $a0, 0x600 #Loading the address of remainder_string into $a0. We want to print this string to the console.
	addi $v0, $0, 4 #System call code to print a string to the console.
	syscall

	add $a0, $0, $v1
	addi $v0, $0, 1
	syscall

	#Since this is not a leaf routine, we have pushed the return address onto the stack earlier in this subroutine
	#Therfore to avoid the infinite loop, we must pop the return address off the stack before returning.
	lw $ra, 0($sp)
	or $0, $0, $0
	addi $sp, $sp, 4

	jr $ra
	or $0, $0, $0
#This is highly inefficient, but as of right now, I do not know any other way to implement factorial. I will work on optimizing this at a later date. q
factorial:
	#This is basically repetitive multiplication on n-=1 as long as n > 0.
	#Example: 3! = 3 * 2 * 1 = 6

	#Before we start calculating the factorial, we need to do some background checks. We need to make sure the number the user inputted is >= 0.
	#If the number if negative, we need to print an error message and prompt the user to enter another number.
	slt $t5, $s0, $0
	beq $t5, 1, error_factorial
	or $0, $0, $0
	bne $s0, $0, non_zero_factorial

zero_factorial:
	addi $v1, $0, 1
	j calculation_finished
	or $0, $0, $0

non_zero_factorial:
	addi $t5, $0, 0 #Loop counter
	addi $v1, $0, 1 #Product of previous 2 numbers, needs to be initialized at 1 to avoid 0 * 1 for the first expression.

factorial_loop:
	addi $t5, $t5, 1 #Increment the loop counter
	mult $t5, $v1 #Multiplying the #lower 32 bits
	mflo $v1
	mfhi $t9
	
	#If the product is bigger than the maximum 32 bit integer (signed), we need to stop because we have arithmetic overflow.
	slt $t9, $t9, 1
	beq $t9, $0 error_overflow
	or $0, $0, $0 
	#If no overflow, continue looping
	bne $t5, $s0, factorial_loop
	or $0, $0, $0

	j calculation_finished
	or $0, $0, $0

exponent:
	#Exponents are basically multiplying the base n amount of times. Example: 2^5 = 32 because 2 x 2 x 2 x 2 x 2 = 32.
	#We will only allow positive exponents just because this calculator will not support decimals just yet.
	#If user enters a negative exponent just display string saying "Negative exponents are unsupported currently."
	bne $s1, $0, non_zero_exponent

zero_exponent:
	addi $v1, $0, 1
	j calculation_finished
	or $0, $0, $0

non_zero_exponent:
	addi $t1, $0, 1 #Loop counter
	add $v1, $0, $s0 #This will store the product of the previous 2 multiplications.

exponent_loop:
	addi $t1, $t1, 1 #Increment the loop counter
	mult $s0, $v1
	mfhi $t3
	bne $t3, $0, error_overflow
	mflo $v1
	bne $t1, $s1, exponent_loop
	or $0, $0, $0
	j calculation_finished
	or $0, $0, $0
modulus:
	#Modulus is basically the remainder of a / b. Example: 10 % 4 = 2, 5 % 5 = 0.
	#Is the user trying to modulo by 0?
	beq $s1, $0, error_modulus
	#Although modulus by 0 is undefined, it will not cause any errors. However, we still don't want the user to be able to do it.
	#The division instruction will fill the branch delay slot just to optimize the code. 
	div $s0, $s1 #Divide the two numbers together
	mfhi $v1 #Move the remainder into a register

calculation_finished:
	#This is not a leaf routine, so we must push the return address onto the stack to avoid an infinite loop.
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#Passing in the three arguments to print_expression
	add $a1, $0, $s0
	add $a2, $0, $t0
	add $a3, $0, $s1
	jal print_expression
	or $0, $0, $0

	#Now print the integer
	add $a0, $0, $v1 #$v1 stores the result, moving it to $a0 because we have to.
	addi $v0, $0, 1 #System call code to print an integer to the console
	syscall

	#Since this is not a leaf routine, we have pushed the return address onto the stack earlier in this subroutine.
	#Therfore to avoid the infinite loop, we must pop the return address off the stack before returning.
	lw $ra, 0($sp)
	or $0, $0, $0
	addi $sp, $sp, 4

	jr $ra #return to main
	or $0, $0, $0

main:
	jal calculator
	or $0, $0, $0

	lui $a0, 0x1000
	ori $a0, $a0, 0xB000
	addi $v0, $0, 4
	syscall

	addi $a0, $a0, 0x800 #Loading the address of key_pressed. This is where we will store the key the user pressed.
	addi $a1, $0, 3 #Maximum number of characters we want to read from the standard input.
	addi $v0, $0, 8 #System call code to read a string from the console.
	syscall

	lb $t1, 0($a0)
	or $0, $0, $0
	beq $t1, 0xA, user_quit #If the user only pressed the enter key, quit.
	add $s0, $0, $v1 #Move the result into the first number slot
	j skip_first_number
	or $0, $0, $0

user_quit:
	addi $v0, $0, 10 #System call code to exit the program
	syscall