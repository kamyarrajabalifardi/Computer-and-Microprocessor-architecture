# MIPS

This is a Verilog implementation of MIPS processor.

# What is MIPS?

MIPS is a processor with load/store architecture. In other words, every
instruction in MIPS ISA must use register operands except for load and
store instruction. It’s categorized as a Reduced Instruction Set
Architecture (RISC) processor. Early versions of the processor started
with 32-bit architecture and later evolved into 64-bit versions. We
implement the 32-bit version. In this version, all instructions have a
fixed 32-bit length. PIC microcontrollers use MIPS as their CPU.
[This](https://en.wikipedia.org/wiki/MIPS_architecture) link can give
you more information about the history and different versions of the
processor. \# What is Verilog? Verilog is a C-like Hardware Description
Language (HDL). Using HDL, electronic and digital circuits can be
described at a high level, for example, Register-Transfer Level
([RTL](https://en.wikipedia.org/wiki/Register-transfer_level)). Verilog
style is similar to C in many cases, like control flow operations,
arithmetic operators, and preprocessor statements. However, it has
things like the `<=` operator (non-blocking assignment), initial, and
always blocks that don’t make sense in a software language like C.

# Multi-Cycle?

There may be multiple strategies to implement a digital circuit (i.e. to
realize the function of the circuit through a bunch of hardware gates
and modules). These options often represent a trade-off. For instance,
you may provide more resources, say ALUs, to do a certain operation
faster at the cost of more silicon area. In (Hennessy and Patterson
2011), two schemes have been discussed: Single-Cycle and Multi-Cycle. In
Single-Cycle, as the name suggests, every instruction is executed in one
clock. However, in Multi-Cycle each instruction is allowed to last for
multiple clocks. Why would one want to prefer Multi-Cycle over
Single-Cycle? Well as mentioned earlier, it’s a trade-off like almost
any engineering problem. Multi-Cycle lets you use fewer resources than
the Single-Cycle case. As an example, for a `store` instruction in
Single-Cycle you need two memory ports: one to fetch the instruction and
another to write the data. Though, in Multi-Cycle you can break the
execution into `Fetch - Execute`stages so that only one memory access is
needed in a clock. So in Multi-Cycle execution flow is done through
different stages and the same resource can be used for various purposes.
In addition to the processor, the integer ALU multiplication and
division modules are designed serially using the simple add/sub + shift
operations, hence minimizing the resource usage. Alternatively, we could
have implemented a parallel multiplier to do the multiplication in a
single clock and use more area.

# References

Hennessy, John L, and David A Patterson. 2011. *Computer Architecture: A
Quantitative Approach*. Elsevier.
