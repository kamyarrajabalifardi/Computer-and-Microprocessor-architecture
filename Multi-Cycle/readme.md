Multi-Cycle Architecture
----
In this project we tried to implement the multi-cycle architecture of MIPS processor which uses less resources in comparison with single-cycle approach.
All of the functions, such as unsigned multiplication and floating point operations, are implemented from scratch. For instance, we took advantage of **Booth encoding** for multiplication. 

All of the functions written below are covered in this project:

* ***R-format:*** `add`, `addu`, `sub`, `subu`, `and`, `or`, `xor`, `nor`, `slt`, `sltu`, `sll`, `srl`, `sra`, `sllv`, `srlv`, `srav`, `jr`, `jalr`, `mult`, `multu` , `mfhi`, `mflo`, `div`, `divu`
* ***I-format:*** `addi`, `addiu`, `slti`, `sltiu`, `andi`, `ori`, `xori`, `lui`, `lw`, `lh`, `lhu`, `lb`, `lbu`, `sw`, `sb`, `sh`, `beq`, `bne`
* ***J-format:*** `j`, `jal`
* ***Floating point Coproc1:*** `add.s`, `sub.s`, `mul.s`, `div.s`, `neg.s`, `abs.s`, `lwc1`, `swc1`

The schema of the whole datapath is shown below:
<p align="center">
  <img width = "700" src="https://user-images.githubusercontent.com/46090276/204658533-8c83a410-183d-41b0-93e8-0f9e7b405536.png" alt="Material Bread logo">
</p>


In order to exectue operations `sh`, `sb`, and `sw` we change the memory unit by using MUX and DEMUX modules.
<p align="center">
  <img src="https://user-images.githubusercontent.com/46090276/204656962-97fb6151-8de0-4247-bf5b-cfe8de50cda3.JPG" alt="Material Bread logo">
</p>

DataPath of the floating point unit is shown in the figure below.
<p align="center">
  <img src="https://user-images.githubusercontent.com/46090276/204654950-e078c1a1-33e4-4838-a9da-ea2a685b1962.png" alt="Material Bread logo">
</p>

References
----
1) Computer Organization and Design, 5th Edition, David A. Petterson, John L. Hennessy
