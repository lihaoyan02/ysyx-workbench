`include "alu_opcodes.v"
module IDU #(INST_WIDTH = 32, REGADDR_WIDTH = 5, DATA_WIDTH = 32) (
	input [INST_WIDTH-1:0] inst_fetch,
	output reg [DATA_WIDTH-1:0] imm,
	output [REGADDR_WIDTH-1:0] rd,
	output [REGADDR_WIDTH-1:0] rs1, 	
	output [REGADDR_WIDTH-1:0] rs2,
	output reg [3:0] alu_ctrl,
	output reg imm_sel,  //choose imm in ALU
	output reg [2:0] wb_ctrl,
	output reg wb_en, //enable write back
	output reg lsu_en, //enable lsu
	output reg lsu_wen,
	output [2:0] lsu_ctrl,
	output reg ebreak_flag,
	output reg j_en,
	output [2:0] j_cond
);
localparam WB_IDLE = 3'b000, WB_ALU = 3'b001, WB_PC = 3'b010, 
	WB_IMM = 3'b011, WB_MEM = 3'b100;


	wire [6:0] opcode;
	wire [2:0] funct3;
	wire [6:0] funct7;
	wire [31:0] imm_I;
	wire [31:0] imm_U;
	wire [31:0] imm_S;
	wire [31:0] imm_J;
	wire [31:0] imm_B;
	assign opcode = inst_fetch[6:0];
	assign funct3 = inst_fetch[14:12];
	assign funct7 = inst_fetch[31:25];
	assign imm_I = {{20{inst_fetch[31]}}, inst_fetch[31:20]};
	assign imm_U = {inst_fetch[31:12], 12'b0};
	assign imm_S = {{20{inst_fetch[31]}}, inst_fetch[31:25], inst_fetch[11:7]};
	assign imm_J = {{12{inst_fetch[31]}}, inst_fetch[19:12], inst_fetch[20], inst_fetch[30:21], 1'b0};
	assign imm_B = {{20{inst_fetch[31]}}, inst_fetch[7], inst_fetch[30:25], inst_fetch[11:8], 1'b0};

	assign lsu_ctrl = funct3;

	import "DPI-C" function void unknow_inst(); 

		always @(*) begin
			// default value
			alu_ctrl = `ALU_IDLE;
			imm_sel = 1'b0; // if choose imm
			imm = 32'b0;
			wb_en = 0; // if wb
			wb_ctrl = WB_IDLE; //from where to wb
			j_en = 1'b0; // if jump
			j_cond = `J_UNCOND; // if conditional jump
			lsu_en = 1'b0;
			lsu_wen = 1'b0;
			ebreak_flag = 1'b0;

			case (opcode)
			7'b0010111: begin //auipc
				alu_ctrl = `ALU_ADD_PC;
				imm_sel = 1'b1;
				imm = imm_U;
				wb_en = 1;
				wb_ctrl = WB_ALU;
			end

			7'b0010011: begin //addi
				imm_sel = 1'b1;
				imm = imm_I;
				wb_en = 1'b1;
				wb_ctrl = WB_ALU;
				if (funct3 == 3'b000) begin //add
					alu_ctrl = `ALU_ADD;
				end
				else if (funct3==3'b011) begin //sltiu
					alu_ctrl = `ALU_LESS_U;
				end
				else if (funct3==3'b010) begin //slti
					alu_ctrl = `ALU_LESS;
				end
				else if (funct3==3'b111) begin //and
					alu_ctrl = `ALU_AND;
				end
				else if (funct3==3'b101 && funct7==7'b0000000) begin //slli
					alu_ctrl = `ALU_SHIFT_RIGHT_U;
				end
				else if (funct3==3'b001 && funct7==7'b0000000) begin //slli
					alu_ctrl = `ALU_SHIFT_LEFT;
				end
				else
					unknow_inst(); 
			end
			7'b1101111: begin //jal
				alu_ctrl = `ALU_ADD_PC;
				imm_sel = 1'b1;
				imm = imm_J;
				wb_en = 1'b1;
				wb_ctrl = WB_PC;
				j_en = 1'b1;
			end
			7'b1100011: begin //beq
				alu_ctrl = `ALU_ADD_PC;
				imm_sel = 1'b1;
				imm = imm_B;
				wb_en = 1'b0;
				j_en = 1'b1;
				if (funct3 == 3'b000) begin
					j_cond = `J_BEQ;
				end	
				else if (funct3 == 3'b001) begin //bne
					j_cond = `J_BNE;
				end
				else if (funct3 == 3'b101) begin //bge
					j_cond = `J_BGE;
				end
				else if (funct3 == 3'b110) begin //bge
					j_cond = `J_BLT_U;
				end
				else
					unknow_inst(); 
			end
			7'b1100111: begin //jalr
				if (funct3 == 3'b000) begin
					alu_ctrl = `ALU_ADD;
					imm_sel = 1'b1;
					imm = imm_I;
					wb_en = 1;
					wb_ctrl = WB_PC;
					j_en = 1'b1;
				end
				else
					unknow_inst(); 
			end
			7'b0110111: begin //lui
				imm = imm_U;
				wb_en = 1;
				wb_ctrl = WB_IMM;
			end
			7'b0110011: begin //add
				imm_sel = 1'b0;
				wb_en = 1'b1;
				wb_ctrl = WB_ALU;
				if(funct3==3'b0 && funct7 == 7'b0) begin
					alu_ctrl = `ALU_ADD;
				end
				else if(funct3==3'b000 && funct7 == 7'b0100000) begin //sub
					alu_ctrl = `ALU_SUB;
				end
				else if(funct3==3'b100 && funct7 == 7'b0000000) begin //XOR
					alu_ctrl = `ALU_XOR;
				end
				else if(funct3==3'b110 && funct7 == 7'b0000000) begin //or
					alu_ctrl = `ALU_OR;
				end
				else if(funct3==3'b011 && funct7 == 7'b0000000) begin //sltu
					alu_ctrl = `ALU_LESS_U;
				end
				else
					unknow_inst(); 
			end
			7'b0000011: begin //lw
				case (funct3)
					3'b010,3'b100: begin
						alu_ctrl = `ALU_ADD;
						imm_sel = 1'b1;
						imm = imm_I;
						lsu_en = 1'b1;
						lsu_wen = 1'b0;
						wb_en = 1'b1;
						wb_ctrl = WB_MEM;
					end
				default:
					unknow_inst(); 
				endcase
			end
			7'b0100011: begin //sb sw
				case (funct3)
					3'b000, 3'b010: begin
						alu_ctrl = `ALU_ADD;
						imm_sel = 1'b1;
						imm = imm_S;
						lsu_en = 1'b1;
						lsu_wen = 1'b1;
						wb_en = 1'b0;
					end
				default:
					unknow_inst(); 
				endcase
			end
			7'b1110011: begin //ebreak
				if(imm_I == 32'b1 && rs1 == 0 && 
					funct3 == 3'b0 && rd == 5'b0) begin
					ebreak_flag = 1;
				end
				else
					unknow_inst(); 
			end
			default:
					unknow_inst(); 
		endcase
	end

	assign rd = inst_fetch[11:7];
	assign rs1 = inst_fetch[19:15];
	assign rs2 = inst_fetch[24:20];
endmodule
