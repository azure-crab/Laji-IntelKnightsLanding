`timescale 1ns / 1ps

`include "Core.vh"

// Brief: CPU Top Module, synchronized
// Author: EAirPeter
module SynLajiIntelKnightsLanding(
    clk, rst_n, en, regfile_req_dbg, datamem_addr_dbg,
    pc_dbg, regfile_data_dbg, datamem_data_dbg, display,
    halt, jumped, is_branch, branched
);
    parameter ProgPath = "C:/.Xilinx/benchmark.hex";
    input clk, rst_n, en;
    input [4:0] regfile_req_dbg;
    input [`DM_ADDR_BIT - 1:0] datamem_addr_dbg;
    output [31:0] pc_dbg;
    output [31:0] regfile_data_dbg;
    output [31:0] datamem_data_dbg;
    output [31:0] display;
    output halt, jumped, is_branch, branched;

// IF
    wire [`IM_ADDR_BIT - 1:0] pc, pc_4;
    wire [31:0] inst;
    wire [`IM_ADDR_BIT - 1:0] pc_new;
    wire load_pc = jumped || branched;
    SynPC vPC(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .load_pc(load_pc),
        .pc_new(pc_new),
        .pc(pc),
        .pc_4(pc_4)
    );
    CmbInstMem #(
        .ProgPath(ProgPath)
    ) vIM(
        .addr(pc),
        .inst(inst)
    );


// IF/ID
// pc_4, inst


// ID
    wire [5:0] opcode, funct;
    wire [4:0] rs, rt, rd, shamt;
    wire [15:0] imm16;

    assign pc_dbg = {20'd0, pc, 2'd0};

    CmbDecoder vDec(
        .inst(inst),
        .opcode(opcode),
        .rs(rs),
        .rt(rt),
        .rd(rd),
        .shamt(shamt),
        .funct(funct),
        .imm16(imm16)
    );

    wire [31:0] ext_out_sign, ext_out_zero;
    CmbExt vExt(
        .imm16(imm16),
        .out_sign(ext_out_sign),
        .out_zero(ext_out_zero)
    );

    wire [`WTG_OP_BIT - 1:0] wtg_op;
    wire [`ALU_OP_BIT - 1:0] alu_op;
    wire [`DM_OP_BIT - 1:0] datamem_op;
    wire datamem_w_en;
    wire syscall_en;
    wire regfile_w_en;
    wire [`MUX_RF_REQA_BIT - 1:0] mux_regfile_req_a;
    wire [`MUX_RF_REQB_BIT - 1:0] mux_regfile_req_b;    
    wire [`MUX_RF_REQW_BIT - 1:0] mux_regfile_req_w;
    wire [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_data_w;
    wire [`MUX_ALU_DATAY_BIT - 1:0] mux_alu_data_y;
    CmbControl vCtl(
        .opcode(opcode),
        .rt(rt),
        .funct(funct),
        .op_wtg(wtg_op),
        .w_en_regfile(regfile_w_en),
        .op_alu(alu_op),
        .op_datamem(datamem_op),
        .w_en_datamem(datamem_w_en),
        .syscall_en(syscall_en),
        .mux_regfile_req_a(mux_regfile_req_a),
        .mux_regfile_req_b(mux_regfile_req_b),
        .mux_regfile_req_w(mux_regfile_req_w),
        .mux_regfile_data_w(mux_regfile_data_w),
        .mux_alu_data_y(mux_alu_data_y)
    );

    always @(*) begin
        case (mux_regfile_req_a)
            `MUX_RF_REQA_RS:
                regfile_req_a = rs;
            `MUX_RF_REQA_SYS:
                regfile_req_a = 5'd2;
            default:
                regfile_req_a = 5'd0;
        endcase
        case (mux_regfile_req_b)
            `MUX_RF_REQB_RT:
                regfile_req_b = rt;
            `MUX_RF_REQB_SYS:
                regfile_req_b = 5'd4;
            default:
                regfile_req_b = 5'd0;
        endcase
        case (mux_regfile_req_w)
            `MUX_RF_REQW_RD:
                regfile_req_w = rd;
            `MUX_RF_REQW_RT:
                regfile_req_w = rt;
            `MUX_RF_REQW_31:
                regfile_req_w = 5'd31;
            default:
                regfile_req_w = 5'd0;
        endcase
    end
    wire [31:0] regfile_data_a, regfile_data_b;
    reg [4:0] regfile_req_a, regfile_req_b, regfile_req_w;    // combinatorial
    reg [31:0] regfile_data_w;  // combinatorial
    SynRegFile vRF(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .w_en(regfile_w_en),
        .req_dbg(regfile_req_dbg),
        .req_w(regfile_req_w),
        .req_a(regfile_req_a),
        .req_b(regfile_req_b),
        .data_dbg(regfile_data_dbg),
        .data_w(regfile_data_w),
        .data_a(regfile_data_a),
        .data_b(regfile_data_b)
    );

    always @(*) begin
        case (mux_regfile_data_w)
            `MUX_RF_DATAW_ALU:
                regfile_data_w = alu_data_res;
            `MUX_RF_DATAW_DM:
                regfile_data_w = datamem_data;
            `MUX_RF_DATAW_PC4:
                regfile_data_w = pc_4;
            default:
                regfile_data_w = 32'd0;
        endcase
        case (mux_alu_data_y)
            `MUX_ALU_DATAY_RFB:
                alu_data_y = regfile_data_b;
            `MUX_ALU_DATAY_EXTS:
                alu_data_y = ext_out_sign;
            `MUX_ALU_DATAY_EXTZ:
                alu_data_y = ext_out_zero;
            default:
                alu_data_y = 32'd0;
        endcase
    end

// ID/EX
// 

// EX
    CmbWTG vWTG(
        .op(wtg_op),
        .imm(imm16[`IM_ADDR_BIT - 1:0]),
        .data_x(regfile_data_a),
        .data_y(regfile_data_b),
        .pc_4(pc_4),
        .pc_new(pc_new),
        .jumped(jumped),
        .is_branch(is_branch),
        .branched(branched)
    );

    reg [31:0] alu_data_y;      // combinatorial
    wire [31:0] alu_data_res;
    CmbALU vALU(
        .op(alu_op),
        .data_x(regfile_data_a),
        .data_y(alu_data_y),
        .shamt(shamt),
        .data_res(alu_data_res)
    );
    SynSyscall vSys(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .syscall_en(syscall_en),
        .data_v0(regfile_data_a),
        .data_a0(regfile_data_b),
        .display(display),
        .halt(halt)
    );

// EX/DM

// DM
    wire [31:0] datamem_data;
    SynDataMem vDM(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .op(datamem_op),
        .w_en(datamem_w_en),
        .addr_dbg(datamem_addr_dbg),
        .addr(alu_data_res[`DM_ADDR_BIT - 1:0]),
        .data_in(regfile_data_b),
        .data_dbg(datamem_data_dbg),
        .data(datamem_data)
    );

// DM/WB

// WB
endmodule
