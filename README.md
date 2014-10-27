FPGA-microprocessor
===================

VHDL code for a simple microprocessor. Codes for a Modelsim simulation and for a Xilinx Spartan 3 FPGA board are included.


Details
-------------------

The machine executes an instruction in 4 clock cycles (FETCH, DECODE, EXECUTE and STORE).

The first cycle (FETCH) retrieves the instruction from the instruction memory (IM) at the location specified by the program counter (PC). It then loads the instruction into the instruction register (IR).
The second cycle (DECODE) decodes the IR (which has the 16-bit instruction) into the opcode (4-bit), RA, RB, and RD (address registers, each 4 bits wide).
The third cycle (EXECUTE) carries out the instruction using the ALU for the specific opcode and stores the result in the W register.
The fourth cycle (STORE) writes the result of the EXECUTE cycle to the data memory register file (RF).

The PC stores the address for the next instruction to be executed.
The IM is 16 bits wide, with 256 locations. The PC register is 8 bits wide.
The data memory register file (RF) has 16 locations and is 8 bits wide.

The processor has 5 basic instructions as follows:

| Opcode | Task to be executed |
| ---- | ---- |
| 0001 | LDI |
| 0010 | ADD |
| 0011 | SUB |
| 0100 | OR |
| 1000 | XOR |
| 1001 | JMP |
| 0000 | HALT |

LDI: Loads the 8-bit data (RA & RB) into the destination register address
ADD: Adds the RF data in RA and RB locations and stores it in RD
SUB: Subtracts the RF data in RB from RA locations and stores it in RD
OR: performs a logical OR on the RF data in RA and RB and stores it in RD
XOR: performs a logical XOR on the RF data in RA and RB and stores it in RD
JMP: Jumps to the given address location (RA & RB) for the next instruction, executes it, and returns to the next PC location

Architecture
-------------------

![alt tag](https://raw.github.com/ajaykarpur/FPGA-microprocessor/master/architecture.jpg)
