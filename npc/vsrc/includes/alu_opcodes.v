`ifndef ALU_OPCODES_VH
`define ALU_OPCODES_VH

`define ALU_IDLE 4'b0000
`define ALU_ADD	4'b0001
`define ALU_ADD_PC 4'b0010
`define ALU_SUB 4'b0011
`define ALU_LESS_U 4'b0100
`define ALU_LESS 4'b0101
`define ALU_SHIFT_LEFT 4'b0110
`define ALU_AND 4'b0111
`define ALU_OR 4'b1000
`define ALU_XOR 4'b1001
`define ALU_SHIFT_RIGHT_U 4'b1010
`define ALU_SHIFT_RIGHT 4'b1011
`define ALU_XXXXXX 4'b1100

`define J_UNCOND 3'b000
`define J_BEQ 3'b001
`define J_BNE 3'b010
`define J_BGE 3'b011
`define J_BGE_U 3'b100
`define J_BLT_U 3'b101

`endif
