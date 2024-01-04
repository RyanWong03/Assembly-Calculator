.globl main 
.data
test_string: .asciiz "3a"

.text
main:
    la $a0, test_string
    jal decode
    or $0, $0, $0
    add $a0, $0, $v0
    addi $v0, $0, 1
    syscall

    addi $v0, $0, 10
    syscall 