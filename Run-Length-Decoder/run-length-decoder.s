.globl decode
.globl realloc_loop

.data
###########################################################################################################################
#Local variables for the subroutine "decode"                                                                              #
#int return_sum = 0;                                                                                                      #
return_sum: .word 0 #Sum of all the numbers in the string.                                                                #
#int multi_digit_number = 0;                                                                                              #
multi_digit_number: .word 0 #Stores the value of multi-digit numbers to prevent "123" from resulting in 6 instead of 123. #
#int decoded_string_index = 0;                                                                                            #
decoded_string_index: .word 0 #Tracks the current index of the decoded string.                                            #
#int resizes = 0;                                                                                                         #
resizes: .word 0 #Tracks how many times we resize our decoded string array. This is to make resizing the array easier.    #
###########################################################################################################################

#Strings to print
malformed_string: .asciiz "Error. Malformed string.\n"
decoded_string: .asciiz "\n"

.text
#Helper routine to handle the event of a malformed string.
string_is_malformed:
    #printf("Error. Malformed string.\n");
    la $a0, malformed_string
    addi $v0, $0, 4
    syscall

    #return -1;
    addi $v0, $0, -1
    jr $ra
    or $0, $0, $0
#Helper subroutine to calculate the length of a null-terminated string. Does the same thing as strlen() in C.
#The address of the string should be passed into register a0.
strlen:
    addi $v1, $0, 0 #Register that will track the length of the string. This will store the return value.
    add $t2, $0, $a0 #Store the address in another register, so we don't modify the original address.
    strlen_loop:
        addi $v1, $v1, 1 #Increment the length of the string by 1
        lb $t0, 0($t2)
        addi $t2, $t2, 1 #t2 += sizeof(char)
        bne $t0, 0x0, strlen_loop #If we have not yet reached the null terminator yet, keep looping through the string
        or $0, $0, $0
    #Since we are incrementing the length of the string even when we reach the null terminator,
    #we need to subtract 1 from the length since the null terminator doesn't count as a valid character.
    jr $ra
    addi $v1, $v1, -1

#Subroutine to determine if the character is a number or not. The character should be passed into register a0.
isnumber:
    #Subtract the character's ascii value with the ascii value of 0. This will extract the digit itself because 0-9 are ordered one after another on the ascii table.
    addi $t0, $0, 0x30 #Ascii value of 0 in hexadecimal
    sub $t1, $a0, $t0
    slti $v1, $t1, 10 #If the difference is less than 10, we have a digit from 0 to 9. $v1 will contain the boolean return value (0 = false, 1 = true).
    jr $ra
    or $0, $0, $0 #Jump delay slot

#Subroutine to actually decode the run length string. Example: "1a3t" should produce "attt". This subroutine also detects malformed strings.
#The address of the string should be passed into register a0.
decode:
    #char *decoded_string = malloc(strlen(str)); //Empty array to store decoded string.
    jal strlen
    #add $t1, $0, $a0 #Store the address of the string temporarily. We need to use register a0 for a system call.
    #store address of the string into $s6
    addi $sp, $sp, -4
    sw $s6, 0($sp)
    add $s6, $0, $a0
    add $t7, $0, $a0 #Storing the address of the string. We will reference this whenever we need to get to the beginning of the string.
    add $t2, $0, $v1 #Store the string length in a temporary register. We will need to use it multiple times in this subroutine.

    addi $v0, $0, 9 #System call code for sbrk
    add $a0, $0, $v1 #$v1 holds the length of the string passed into $a0.
    syscall

    add $t9, $0, $v0 #store the address returned from sbrk for later use when deallocating.
    
    #Base case. If the first char isn't even a number, it is already invalid.
    #if(!isnumber(str[0]))
    lb $a0, 0($s6)
    jal isnumber
    or $0, $0, $0
    beq $v1, $0, string_is_malformed
    or $0, $0, $0

    #Since we know the first character is a number, we can loop through the rest of the string.
    #for(int i = 0; i < strlen(str); i++)
    addi $t3, $0, 0 #int i = 0;
    outer_loop:
        #if(!isnumber(str[i]))
        lb $a0, 0($s6)
        jal isnumber
        or $0, $0, $0
        beq $v1, $0, non_number
        or $0, $0, $0

        non_number:
            #If the char isn't a number and it's not the last char, and the next char is not a number. "5ac" is invalid. "5a2c" is valid.
            #t5 = if(i + 1 < strlen(str))
            addi $t4, $t3, 1 #t4 = i + 1
            slt $t5, $t4, $t2

            #if(!isnumber(str[i + 1]))
            addi $s6, $s6, 1
            lb $a0, 0($s6)
            jal isnumber
            addi $s6, $s6, -1
            #We need a 1 to result from the evaluation of the and statement (read the comment). In order for this to happen both values need to be a 1.
            #We need to invert the return value of isnumber to see if it is true or false. We can do this with xor'ing each bit with a 1.
            xori $v1, $v1, 1
            and $t5, $t5, $v1 #(i + 1 < strlen(str)) && (!isnumber(str[i + 1]))
            beq $t5, 1, string_is_malformed
            or $0, $0, $0
            #else
            #return_sum += multi_digit_number //if we encounter a non-number, add the temp value to the sum of numbers.
            la $a0, multi_digit_number
            la $a1, return_sum
            lw $t0, 0($a0)
            lw $t4, 0($a1)
            or $0, $0, $0 #load delay slot. The add instruction under depends on the result of the lw instruction right above.
            add $t4, $t4, $t0
            sw $t4, 0($a1)

            #for(int j = 0; j < multi_digit_number; j++)
            #By the MIPS software convention, preserve the saved registers.
            addi $sp, $sp, -4
            sw $s0, 0($sp)
            addi $s0, $0, 0 #j = 0
            inner_loop:
                la $a1, decoded_string_index
                lw $t4, 0($a1)
                or $0, $0, $0 #load delay slot, dependency in $t4
                bgt $t4, $t2, resize_array
                or $0, $0, $0 #branch delay slot
                blt $t4, $t2, no_resize_array
                or $0, $0, $0 #branch delay slot

                resize_array:
                    #resizes++;
                    la $a1, resizes
                    lw $t5, 0($a1)
                    or $0, $0, $0 #load delay slot, dependency in $t5
                    addi $t5, $t5, 1 
                    sw $t5, 0($a1)

                    #char *new_decoded_string = realloc(decoded_string, resizes * strlen(str) * 2); //If we run out of space, increase the size. Kind of like an array buffer.
                    mult $t5, $t2 #resizes * strlen(str)
                    mflo $t6
                    add $t6, $t6, $t6 #(resizes * strlen(str)) * 2

                    addi $v0, $0, 9 #System call code for sbrk
                    add $a0, $0, $t6 #Amount to sbrk
                    syscall

                    add $a0, $0, $t7
                    jal strlen
                    addi $t6, $0, 0 #Loop counter

                    #Now $v0 stores the address for the new re-allocated pointer. We now need to move the data from the old allocated pointer to $v0.
                    realloc_loop:
                        lb $t8, 0($t9)
                        addi $t6, $t6, 1
                        sb $t8, 0($v0)
                        addi $v0, $v0, 1
                        addi $t9, $t9, 1
                        bne $t6, $v1, realloc_loop
                        or $0, $0, $0
                        #Don't need to worry about freeing the old pointer right now.
                    sub $v0, $v0, $v1 #Get back to the start of the re-alloced pointer
                    sub $t9, $t9, $v1 #Get back to the start of the old pointer
                    move 	$t9, $v0

                no_resize_array:
                    #decoded_string[decoded_string_index++] = str[i];
                    addi $t4, $t4, 1
                    la $a1, decoded_string_index
                    sw $t4, 0($a1)
                    addi $t9, $t9, 1
                    lb $t4, 0($s6)
                    sb $t4, 0($t9)

                endifelse:
                    addi $s0, $s0, 1
                    bne $s0, $t0, inner_loop
                    or $0, $0, $0 
            #multi_digit_number = 0;
            la $a1, multi_digit_number
            addi $t4, $0, 0
            sw $t4, 0($a1)
        #else
        is_number:
            #if(str[i + 1] == ' ' || i + 1 == strlen(str))
            addi $s6, $s6, 1
            lb $s0, 0($s6) #s0 = str[i + 1]
            or $0, $0, $0
            beq $s0, 0x20, string_is_malformed #0x20 is the ascii value for a space char
            addi $s6, $s6, -1
            #is i + 1 == strlen(str)?
            addi $s0, $t3, 1
            beq $s0, $t2, string_is_malformed
            or $0, $0, $0
            
            #else
            #Keeping track of the number that precedes the character(s). This also prevents multi-digit numbers from being seen as characters.
            #For example: "123" should be interpreted as 123 and not 6 (1 + 2 + 3).
            #multi_digit_number = multi_digit_number * 10 + (int)(str[i] - '0');
            la $a1, multi_digit_number
            lb $s0, 0($a1) #$s0 = multi_digit_number
            addi $sp, $sp, -4
            sw $s1, 0($sp)
            addi $s1, $0, 10
            mult $s0, $s1 #s0 * 10
            mflo $s1
            lb $t8, 0($s6)
            addi $t6, $0, 0x30 #ascii value for 0
            sub $t8, $t8, $t6 #(int)(str[i] - '0)
            add $s1, $s1, $t8 #multi_digit_number * 10 + (int)(str[i] - '0');
            sw $s1, 0($a1)
    
    #Now we need to restore the saved registers from the stack.
    lw $s1, 0($sp)
    or $0, $0, $0
    addi $sp, $sp, 4
    lw $s0, 0($sp)
    or $0, $0, $0
    addi $sp, $sp, 4
    lw $s6, 0($sp)
    or $0, $0, $0
    addi $sp, $sp, 4

    #printf("%s", decoded_string);
    la $t8, decoded_string_index
    lw $t5, 0($t8)
    addi $v0, $0, 4
    sub $t9, $t9, $t5
    add $a0, $0, $t9
    syscall

    #return return_sum
    la $t5, return_sum
    lw $t6, 0($t5)
    or $0, $0, $0
    add $v0, $0, $t6
    jr $ra
    or $0, $0, $0