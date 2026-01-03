module IDU #(INST_WIDTH = 32, REGADDR_WIDTH = 5, DATA_WIDTH = 32) (
	input [INST_WIDTH-1:0] inst_fetch,
	output reg [DATA_WIDTH-1:0] imm,
	output [REGADDR_WIDTH-1:0] rd,
	output [REGADDR_WIDTH-1:0] rs1, 	
	output [REGADDR_WIDTH-1:0] rs2,
	output reg [2:0] alu_ctrl,
	output reg imm_sel,
	output reg [2:0] wb_ctrl,
	output reg wb_en,
	output reg ebreak_flag,
	output reg j_pc
);
localparam ALU_IDLE = 3'b000, ALU_ADD = 3'b001;
localparam WB_IDLE = 3'b000, WB_ALU = 3'b001, WB_PC = 3'b010, 
	WB_IMM = 3'b011;


	wire [6:0] opcode;
	wire [2:0] funct3;
	wire [31:0] imm_I;
	wire [31:0] imm_U;
	assign opcode = inst_fetch[6:0];
	assign funct3 = inst_fetch[14:12];
	assign imm_I = {{20{inst_fetch[31]}},inst_fetch[31:20]};
	assign imm_U = {inst_fetch[31:12], 12'b0};

		always @(*) begin
			// default value
			alu_ctrl = ALU_IDLE;
			imm_sel = 1'b0;
			imm = {DATA_WIDTH{1'b0}};
			wb_en = 0;
			wb_ctrl = WB_IDLE;
			j_pc = 1'b0;
			ebreak_flag = 1'b0;

			case (opcode)
			7'b0010011: begin //addi
				if (funct3 == 3'b000) begin
					alu_ctrl = ALU_ADD;
					imm_sel = 1'b1;
					imm = imm_I;
					wb_en = 1'b1;
					wb_ctrl = WB_ALU;
				end
				else
					$finish;
			end
			7'b1100111: begin //jalr
				if (funct3 == 3'b000) begin
					alu_ctrl = ALU_ADD;
					imm_sel = 1'b1;
					imm = imm_I;
					wb_en = 1;
					wb_ctrl = WB_PC;
					j_pc = 1;
				end
				else
					$finish;
			end
			7'b0110111: begin //lui
				imm = imm_U;
				wb_en = 1;
				wb_ctrl = WB_IMM;
			end
			7'b1110011: begin //ebreak
				if(imm_I == 32'b1 && rs1 == 0 && 
					funct3 == 3'b0 && rd == 5'b0) begin
					ebreak_flag = 1;
				end
				else
					$finish;
			end
			default: ;
		endcase
	end

	assign rd = inst_fetch[11:7];
	assign rs1 = inst_fetch[19:15];
	assign rs2 = inst_fetch[24:20];
endmodule
