# $s0 is first set to 0. After any instruction, a "beq" is provided to check the result with the desired result. If for an instruction, the result is not what we expect, then $0 is set to another nnumber.
#
# these two are reserved for changing %sp and $ra
addi $sp, $0, 256
addi $ra, $0, 512
add $s0, $0, $0 # This should never change
#addiu $t1, $0, 456789
lui $t1, 0x6
ori $t1, 0xf855
sh $t1, 0($sp)
lhu $t1, 0($sp)
#addi $t2, $0, 63573
lui $t2, 0
ori $t2, 0xf855
beq $t2, $t1, plzgo0
addi $s0, $0, 1
plzgo0:
lh $t1, 0($sp)
addi $t2, $0, -1963
beq $t1, $t2, plzgo1
addi $s0, $0, 2
plzgo1:
#addi $t1, $0, 74751
lui $t1, 1
ori $t1, 0x23ff
sb $t1, 0($sp)
lbu $t1, 0($sp)
addi $t2, $0, 255
beq $t1, $t2, plzgo2
addi $s0, $0, 3
plzgo2:
lb $t1, 0($sp)
addi $t2, $0, -1
beq $t1, $t2, plzgo3
addi $s0, $0, 4
plzgo3:
addi $t1, $0, 28
addi $t2, $0, 7
divu $t1, $t2
mflo $t2
addi $t3, $0, 4
beq $t2, $t3, plzgo4
addi $s0, $0, 5
plzgo4:
addi $t1, $0, 28
addi $t2, $0, -7
div $t1, $t2
mflo $t2
addi $t3, $0, -4
beq $t2, $t3, plzgo5
addi $s0, $0, 6
plzgo5:
jr $ra