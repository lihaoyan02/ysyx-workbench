`include "alu_opcodes.v"
module IDU #(XLEN = 32, REGADDR_WIDTH = 5) (
	input clk,
	input rst,

	input if_id_valid,
	output id_if_ready,
	input [XLEN-1:0] if_id_pc,
	input [XLEN-1:0] if_id_inst,
	
	output id_ex_valid,
	input ex_id_ready,
	output [XLEN-1:0] id_ex_pc,
	output [XLEN-1:0] id_ex_inst,

	// exu control signal
	output [3:0] id_ex_alu_ctrl,
	output [1:0] id_ex_alu_op_ctrl,
	output [XLEN-1:0] id_ex_imm,
	output [REGADDR_WIDTH-1:0] id_ex_rd,
	output [REGADDR_WIDTH-1:0] id_rf_rs1, 	
	output [REGADDR_WIDTH-1:0] id_rf_rs2,
	output id_ex_j_en,
	output [2:0] id_ex_j_cond,
	
	// lsu control signal
	output id_ex_lsu_en, //enable lsu
	output id_ex_lsu_wen,
	output [2:0] id_ex_lsu_ctrl,

	// wbu control signal
	output [2:0] id_ex_wb_ctrl,
	output id_ex_wb_en, //enable write back
	output id_ex_ebreak_flag,
	
	// fence.i control signal
	// output reg icache_flush,

	// csr control signal
	output id_csr_valid,
	output id_csr_wen,
	output id_csr_event,
	output [11:0] id_csr_addr,

	input [REGADDR_WIDTH-1:0] ex_ls_rd,
	input [REGADDR_WIDTH-1:0] ls_wb_rd,

	input ex_glb_flush

);

	import "DPI-C" function void unknow_inst(); 
	import "DPI-C" function void performance_counter(int category); 

	localparam WB_IDLE = 3'b000, WB_ALU = 3'b001, WB_PC = 3'b010, 
		WB_IMM = 3'b011, WB_MEM = 3'b100;
/*------------------------data hazard--------------------------------*/
wire data_hazard;
assign data_hazard = (ex_ls_rd != 0) &  ((ex_ls_rd==id_rf_rs1) | (ex_ls_rd==id_rf_rs1)) |
					(ls_wb_rd != 0) &  ((ls_wb_rd==id_rf_rs1) | (ls_wb_rd==id_rf_rs1));

/*----------------------output assignment----------------------------*/
	assign id_if_ready = (~id_ex_valid | (id_ex_valid & ex_id_ready)) & (~idu_ebreak_flag) & (~data_hazard);
	assign id_ex_valid = idu_valid;
	assign id_ex_pc = idu_pc;
	assign id_ex_inst = idu_inst;
	assign id_ex_alu_ctrl = idu_alu_ctrl;
	assign id_ex_alu_op_ctrl = idu_alu_op_ctrl;
	assign id_ex_imm = idu_imm;
	assign id_ex_rd = idu_rd;
	assign id_rf_rs1 = idu_rs1;
	assign id_rf_rs2 = idu_rs2;
	assign id_ex_j_en = idu_j_en;
	assign id_ex_j_cond = idu_j_cond;
	assign id_ex_lsu_en = idu_lsu_en;
	assign id_ex_lsu_wen = idu_lsu_wen;
	assign id_ex_lsu_ctrl = idu_lsu_ctrl;
	assign id_ex_wb_ctrl = idu_wb_ctrl;
	assign id_ex_wb_en = idu_wb_en;
	assign id_ex_ebreak_flag = idu_ebreak_flag;
	assign id_csr_valid = idu_csr_valid;
	assign id_csr_wen = idu_csr_wen;
	assign id_csr_event = idu_csr_event;
	assign id_csr_addr = idu_csr_addr;

	wire [6:0] opcode;
	wire [2:0] funct3;
	wire [6:0] funct7;
	wire [31:0] imm_I;
	wire [31:0] imm_U;
	wire [31:0] imm_S;
	wire [31:0] imm_J;
	wire [31:0] imm_B;

	assign opcode = if_id_inst[6:0];
	assign funct3 = if_id_inst[14:12];
	assign funct7 = if_id_inst[31:25];
	assign imm_I = {{20{if_id_inst[31]}}, if_id_inst[31:20]};
	assign imm_U = {if_id_inst[31:12], 12'b0};
	assign imm_S = {{20{if_id_inst[31]}}, if_id_inst[31:25], if_id_inst[11:7]};
	assign imm_J = {{12{if_id_inst[31]}}, if_id_inst[19:12], if_id_inst[20], if_id_inst[30:21], 1'b0};
	assign imm_B = {{20{if_id_inst[31]}}, if_id_inst[7], if_id_inst[30:25], if_id_inst[11:8], 1'b0};

	reg [31:0] imm;
	reg [4:0] rd, rs1, rs2;
	reg [3:0] alu_ctrl;
	reg [1:0] alu_op_ctrl;
	reg [2:0] wb_ctrl;
	reg wb_en;
	reg lsu_en;
	reg lsu_wen;
	reg [2:0] lsu_ctrl;
	reg ebreak_flag;
	reg j_en;
	reg [2:0] j_cond;
	reg csr_event;
	reg csr_wen;
	reg [11:0] csr_addr;
	// reg icache_flush_nxt;

	integer decode_cat;
	localparam ALU_CAT = 3, LSU_CAT = 4, CSR_CAT = 5, JUMP_CAT = 6, OTHER_CAT = 10;

	/*--------------define register------------------*/
	reg idu_valid;
	reg [XLEN-1:0] idu_pc;
	reg [XLEN-1:0] idu_inst;
	// registers for exu control signal
	reg [3:0] idu_alu_ctrl;
	reg [1:0] idu_alu_op_ctrl;
	reg [XLEN-1:0] idu_imm;
	reg [REGADDR_WIDTH-1:0] idu_rd;
	reg [REGADDR_WIDTH-1:0] idu_rs1; 	
	reg [REGADDR_WIDTH-1:0] idu_rs2;
	reg idu_j_en;
	reg [2:0] idu_j_cond;
	// registers for lsu control signal
	reg idu_lsu_en; //enable lsu
	reg idu_lsu_wen;
	reg [2:0] idu_lsu_ctrl;
	// registers for wbu control signal
	reg [2:0] idu_wb_ctrl;
	reg idu_wb_en; //enable write back
	reg idu_ebreak_flag;
	// registers for csr control signal
	reg idu_csr_valid;
	reg idu_csr_wen;
	reg idu_csr_event;
	reg [11:0] idu_csr_addr;

	always @(posedge clk) begin
		if (rst) begin
			idu_valid <= 0;
		end
		else if (ex_glb_flush) begin
			idu_valid <= 0;
		end
		else if (if_id_valid & id_if_ready) begin
			idu_valid <= 1;
		end
		else if (id_ex_valid & ex_id_ready) begin
			idu_valid <= 0;
		end
	end

	always @(posedge clk) begin
		if (rst) begin
			idu_csr_valid <= 0;
		end
		else if (ex_glb_flush) begin
			idu_csr_valid <= 0;
		end
		else if (if_id_valid & id_if_ready) begin
			idu_csr_valid <= 1;
		end
		else begin
			idu_csr_valid <= 0;
		end
	end

	always @(posedge clk) begin
		if (rst) begin
			idu_pc <= 0;
			idu_inst <= 0;
			idu_alu_ctrl <= `ALU_IDLE;
			idu_alu_op_ctrl <= `OP_RS1_RS2;
			idu_imm <= 0;
			idu_rd <= 0;
			idu_rs1 <= 0;
			idu_rs2 <= 0;
			idu_j_en <= 0;
			idu_j_cond <= `J_UNCOND;

			
			idu_lsu_en <= 0;
			idu_lsu_wen <= 0;
			idu_lsu_ctrl <= 0;

			idu_wb_ctrl <= WB_IDLE;
			idu_wb_en <= 0;
			idu_ebreak_flag <= 0;
			
			idu_csr_wen <= 0;
			idu_csr_event <= 0;
			idu_csr_addr <= 0;
			// icache_flush <= 0;
		end
		else if (if_id_valid & id_if_ready) begin
			performance_counter(decode_cat);
			idu_pc <= if_id_pc;
			idu_inst <= if_id_inst;

			idu_alu_ctrl <= alu_ctrl;
			idu_alu_op_ctrl <= alu_op_ctrl;
			idu_imm <= imm;
			idu_rd <= rd;
			idu_rs1 <= rs1;
			idu_rs2 <= rs2;
			idu_j_en <= j_en;
			idu_j_cond <= j_cond;

			idu_lsu_en <= lsu_en;
			idu_lsu_wen <= lsu_wen;
			idu_lsu_ctrl <= lsu_ctrl;

			idu_wb_ctrl <= wb_ctrl;
			idu_wb_en <= wb_en;
			idu_ebreak_flag <= ebreak_flag;
			
			idu_csr_wen <= csr_wen;
			idu_csr_event <= csr_event;
			idu_csr_addr <= csr_addr;
			
			
			// icache_flush <= icache_flush_nxt;
		end
	end

	/*-----------------decoder------------------*/
	always @(*) begin		
		// default value
		rd = if_id_inst[11:7];
		rs1 = if_id_inst[19:15];
		rs2 = if_id_inst[24:20];

		
		alu_ctrl = `ALU_IDLE;
		alu_op_ctrl = `OP_RS1_RS2; // if choose imm
		imm = 32'b0;
		wb_en = 0; // if wb
		wb_ctrl = WB_IDLE; //from where to wb
		j_en = 1'b0; // if jump
		j_cond = `J_UNCOND; // if conditional jump				
		ebreak_flag = 1'b0;	
		lsu_en = 1'b0;
		lsu_wen = 1'b0;
		lsu_ctrl = funct3;
		csr_event = 1'b0;
		csr_wen = 1'b0;
		csr_addr = if_id_inst[31:20];
		if (if_id_valid) begin
			case (opcode)
				7'b0010111: begin //auipc
					decode_cat = ALU_CAT;
					alu_ctrl = `ALU_ADD;
					alu_op_ctrl = `OP_PC_IMM;
					imm = imm_U;
					wb_en = 1;
					wb_ctrl = WB_ALU;
				end
				7'b0110111: begin //lui
					decode_cat = OTHER_CAT;
					imm = imm_U;
					wb_en = 1;
					wb_ctrl = WB_IMM;
				end
				7'b0010011: begin
					decode_cat = ALU_CAT;
					alu_op_ctrl = `OP_RS1_IMM;
					imm = imm_I;
					wb_en = 1'b1;
					wb_ctrl = WB_ALU;
					if (funct3 == 3'b000) begin //addi
						alu_ctrl = `ALU_ADD;
					end
					else if (funct3==3'b011) begin //sltiu
						alu_ctrl = `ALU_LESS_U;
					end
					else if (funct3==3'b100) begin //xori
						alu_ctrl = `ALU_XOR;
					end
					else if (funct3==3'b110) begin //ori
						alu_ctrl = `ALU_OR;
					end
					else if (funct3==3'b111) begin //andi
						alu_ctrl = `ALU_AND;
					end
					else if (funct3==3'b010) begin //slti
						alu_ctrl = `ALU_LESS;
					end
					else if (funct3==3'b101 && funct7==7'b0000000) begin //srli
						alu_ctrl = `ALU_SHIFT_RIGHT_U;
					end
					else if (funct3==3'b101 && funct7==7'b0100000) begin //srai
						alu_ctrl = `ALU_SHIFT_RIGHT;
					end
					else if (funct3==3'b001 && funct7==7'b0000000) begin //slli
						alu_ctrl = `ALU_SHIFT_LEFT;
					end
					else
						unknow_inst(); 
				end
				7'b0110011: begin 
					decode_cat = ALU_CAT;
					alu_op_ctrl = `OP_RS1_RS2;
					wb_en = 1'b1;
					wb_ctrl = WB_ALU;
					if(funct3==3'b0 && funct7 == 7'b0000000) begin //add
						alu_ctrl = `ALU_ADD;
					end
					else if(funct3==3'b000 && funct7 == 7'b0100000) begin //sub
						alu_ctrl = `ALU_SUB;
					end
					else if(funct3==3'b100 && funct7 == 7'b0000000) begin //xor
						alu_ctrl = `ALU_XOR;
					end
					else if(funct3==3'b110 && funct7 == 7'b0000000) begin //or
						alu_ctrl = `ALU_OR;
					end
					else if(funct3==3'b111 && funct7 == 7'b0000000) begin //and
						alu_ctrl = `ALU_AND;
					end
					else if(funct3==3'b101 && funct7 == 7'b0000000) begin //srl
						alu_ctrl = `ALU_SHIFT_RIGHT_U;
					end
					else if(funct3==3'b101 && funct7 == 7'b0100000) begin //sra
						alu_ctrl = `ALU_SHIFT_RIGHT;
					end
					else if(funct3==3'b010 && funct7 == 7'b0000000) begin //slt
						alu_ctrl = `ALU_LESS;
					end
					else if(funct3==3'b011 && funct7 == 7'b0000000) begin //sltu
						alu_ctrl = `ALU_LESS_U;
					end
					else if(funct3==3'b001 && funct7 == 7'b0000000) begin //sll
						alu_ctrl = `ALU_SHIFT_LEFT;
					end
					else
						unknow_inst(); 
				end
				7'b1101111: begin //jal
					decode_cat = JUMP_CAT;
					alu_ctrl = `ALU_ADD;
					alu_op_ctrl = `OP_PC_IMM;
					imm = imm_J;
					wb_en = 1'b1;
					wb_ctrl = WB_PC;
					j_en = 1'b1;
				end
				7'b1100111: begin //jalr
					if (funct3 == 3'b000) begin
						decode_cat = JUMP_CAT;
						alu_ctrl = `ALU_ADD;
						alu_op_ctrl = `OP_RS1_IMM;
						imm = imm_I;
						wb_en = 1;
						wb_ctrl = WB_PC;
						j_en = 1'b1;
					end
					else
						unknow_inst(); 
				end
				7'b1100011: begin 
					decode_cat = JUMP_CAT;
					alu_ctrl = `ALU_ADD;
					alu_op_ctrl = `OP_PC_IMM;
					imm = imm_B;
					wb_en = 1'b0;
					j_en = 1'b1;
					if (funct3 == 3'b000) begin //beq
						j_cond = `J_BEQ;
					end	
					else if (funct3 == 3'b001) begin //bne
						j_cond = `J_BNE;
					end
					else if (funct3 == 3'b111) begin //bgeu
						j_cond = `J_BGE_U;
					end
					else if (funct3 == 3'b101) begin //bge
						j_cond = `J_BGE;
					end
					else if (funct3 == 3'b110) begin //bltu
						j_cond = `J_BLT_U;
					end
					else if (funct3 == 3'b100) begin //blt
						j_cond = `J_BLT;
					end
					else
						unknow_inst(); 
				end
				7'b0000011: begin //lw, lbu, lb
					decode_cat = LSU_CAT;
					case (funct3)
						3'b000,3'b001,3'b010,3'b100,3'b101: begin
							alu_ctrl = `ALU_ADD;
							alu_op_ctrl = `OP_RS1_IMM;
							imm = imm_I;
							lsu_en = 1'b1;
							lsu_wen = 1'b0;
							wb_en = 1'b1;
							wb_ctrl = WB_MEM;
						end
					default: begin
						$display("unknow opcode =7'b0000011");
						unknow_inst(); 
					end
					endcase
				end
				7'b0100011: begin //sb sw sj
					decode_cat = LSU_CAT;
					case (funct3)
						3'b000, 3'b010, 3'b001: begin
							alu_ctrl = `ALU_ADD;
							alu_op_ctrl = `OP_RS1_IMM;
							imm = imm_S;
							lsu_en = 1'b1;
							lsu_wen = 1'b1;
							wb_en = 1'b0;
						end
					default: begin
						$display("unknow opcode =7'b0100011");
						unknow_inst(); 
					end
					endcase
				end
				7'b1110011: begin //ebreak
					decode_cat = CSR_CAT;
					if(imm_I == 32'b1 && rs1 == 0 && 
						funct3 == 3'b0 && rd == 5'b0) begin
						ebreak_flag = 1;
					end
					/*------ecall------*/
					else if(if_id_inst[31:7] == 25'b0) begin
						csr_addr = 12'h305; //mtvec
						csr_event = 1'b1;
						alu_ctrl = `ALU_OP2;
						alu_op_ctrl = `OP_RS1_CSR;
						j_en = 1'b1;
					end
					/*------mret------*/
					else if(if_id_inst[31:7] == 25'b001100000010_00000_000_00000) begin
						csr_addr = 12'h341; //mepc
						alu_ctrl = `ALU_OP2;
						alu_op_ctrl = `OP_RS1_CSR;
						j_en = 1'b1;
					end
					/*------csrrw------*/
					else if(funct3 == 3'b001) begin
						alu_ctrl = `ALU_OP2;
						alu_op_ctrl = `OP_RS1_CSR;
						csr_wen = 1'b1;
						wb_en = 1'b1;
						wb_ctrl = WB_ALU;
					end
					/*------csrrs------*/
					else if(funct3 == 3'b010) begin 
						alu_ctrl = `ALU_OR;
						alu_op_ctrl = `OP_RS1_CSR;
						csr_wen = 1'b0;
						wb_en = 1'b1;
						wb_ctrl = WB_ALU;
					end
					else begin
						$display("unknow opcode =7'b1110011");
						unknow_inst(); 
					end
				end
				// 7'b0001111: begin
				// 	if(funct3 == 3'b001 & if_id_inst[31:20]==0) begin
				// 		icache_flush_nxt = 1;
				// 	end
				// 	else begin
				// 		$display("unknow opcode =7'b0001111");
				// 		unknow_inst(); 
				// 	end
				// end
				default: begin
					$display("unknow opcode");
					unknow_inst(); 
				end				
			endcase
		end
	end


endmodule
