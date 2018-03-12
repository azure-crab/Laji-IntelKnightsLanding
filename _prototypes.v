// Pots
// SynLaji      TopLaji         EAirPeter
// SynDataMem   CmbExt          cuishaobo
// CmbControl   CmbDecoder      FluorineDog
// SynRegFile   SynPC           G-H-Y
// CmbALU       CmbSyscall      KailinLi
// CmbWTG       SynInstMem      azure-crab

`include "core.vh"

// Brief: Program Counter, sychronized
// Description: Update program counter
// Author: G-H-Y
module SynPC(clk, rst_n, en, pc_new, pc, pc_4);
    input clk;
    input rst_n;
    input en;
    input [31:0] pc_new;
    output [31:0] pc;
    output [31:0] pc_4;
endmodule

// Brief: Instruction Memory, synchronized
// Description: Fetch instruction from memory
// Author: azure-crab
module SynInstMem(clk, rst_n, addr, inst);
    input clk;
    input rst_n;
    input [31:0] addr;
    output [31:0] inst;
endmodule

// Brief: Instruction Decoder, combinatorial
// Author: FluorineDog
module CmbDecoder(inst, opcode, rs, rt, rd, shamt, funct, imm16, imm26);
    input [31:0] inst;
    output [5:0] opcode;
    output [4:0] rs;
    output [4:0] rt;
    output [4:0] rd;
    output [4:0] shamt;
    output [5:0] funct;
    output [15:0] imm16;
    output [25:0] imm26;
endmodule

// Brief: Bit Extender, combinatorial
// Author: cuishaobo
module CmbExt(imm16, out_sign, out_zero);
    input [15:0] imm16;
    output [31:0] out_sign;
    output [31:0] out_zero;
endmodule

// Brief: Register File, synchronized
// Author: G-H-Y
module SynRegFile(clk, rst_n, req_dbg, req_w, req_a, req_b, data_dbg, data_w, data_a, data_b, data_v0, data_a0);
    input clk;
    input rst_n;
    input en;
    input [4:0] req_dbg;
    input [4:0] req_w;
    input [4:0] req_a;
    input [4:0] req_b;
    output [31:0] data_dbg;
    output [31:0] data_w;
    output [31:0] data_a;
    output [31:0] data_b;
    output [31:0] data_v0;      // For syscall
    output [31:0] data_a0;      // For syscall
endmodule

// Brief: Where To Go, combinatorial
// Description: Compute the value about to be updated into PC
// Author: azure-crab
module CmbWTG(op, off32, imm26, data_x, data_y, pc_4, pc_new, branched);
    input [`WTG_OP_BIT - 1:0] op;
    input [31:0] off32;
    input [25:0] imm26;
    input [31:0] data_x;
    input [31:0] data_y;
    input [31:0] pc_4;
    output [31:0] pc_new;
    output branched;        // True on successful conditional branch
endmodule

// Brief: Arithmetic Logic Unit, combinatorial
// Author: KailinLi
module CmbALU(op, data_x, data_y, shamt, data_res);
    input [`ALU_OP_BIT - 1:0] op;
    input [31:0] data_x;
    input [31:0] data_y;
    input [4:0] shamt;      // Separate input for shift 
    output [31:0] data_res;
endmodule

// Brief: Data Memory, combinatorial
// Author: cuishaobo
module SynDataMem(clk, rst_n, en, op, w_en, addr_dbg, addr, data_dbg, data);
    input clk;
    input rst_n;
    input en;
    input [`DM_OP_BIT - 1:0] op;
    input w_en;             // Write Enable
    input [31:0] addr_dbg;  // Address of the data for debugging
    input [31:0] addr;
    output [31:0] data_dbg; // Data to be displayed for debugging
    output [31:0] data;
endmodule

// Brief: Syscall Module, synchronized
// Description: If $v0 is 34, display content of $a0 on the 7-segment display;
//              Otherwise pause the execution of the program
// Author: KailinLi
module CmbSyscall(syscall_en, data_v0, data_a0, display, display_en, halt);
    input syscall_en;       
    input [31:0] data_v0;
    input [31:0] data_a0;
    output [31:0] display;
    output display_en;
    output halt;
endmodule

// Brief: Control Module, synchronized
// Author: FluorineDog
module CmbControl(opcode, rt, funct, op_wtg, op_alu, op_datamem, mux_regfile_req_w, mux_regfile_data_w, mux_alu_data_y);
    input [5:0] opcode;
    input [4:0] rt;
    input [5:0] funct;
    output [`WTG_OP_BIT - 1:0] op_wtg;
    output [`ALU_OP_BIT - 1:0] op_alu;
    output [`DM_OP_BIT - 1:0] op_datamem;
    output [`MUX_RF_REQW_BIT - 1:0] mux_regfile_req_w;
    output [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_data_w;
    output [`MUX_ALU_DATAY_BIT - 1:0] mux_alu_data_y;
endmodule

// Brief: CPU Top Module, synchronized
// Author: EAirPeter
module SynLajiIntelKnightsLanding(clk, rst_n, en, regfile_req_dbg, datamem_addr_dbg, regfile_data_dbg, datamem_data_dbg, display, display_en, halt);
    input clk;
    input rst_n;
    input en;
    input [4:0] regfile_req_dbg;
    input [31:0] datamem_addr_dbg;
    output [31:0] regfile_data_dbg;
    output [31:0] datamem_data_dbg;
    output [31:0] display;
    output display_en;
    output halt;
endmodule

// Brief: Top Module, including I/O
// Author: EAirPeter
module TopLajiIntelKnightsLanding;
