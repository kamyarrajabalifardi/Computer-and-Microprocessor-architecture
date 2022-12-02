#addi $ra, $0, 512
#addi $sp, $0, 256
#lwc1 $f0,0($sp)
#lwc1 $f1, -4($sp)
#lwc1 $f2, -8($sp)
add.s $f3, $f1, $f0
sub.s $f4, $f3, $f2
neg.s $f5, $f4
abs.s $f6, $f5
div.s $f7, $f6, $f0
mul.s $f8, $f7, $f1
swc1 $f8, -12($sp)
jr $ra