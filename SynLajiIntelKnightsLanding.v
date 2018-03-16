`timescale 1ns / 1ps
`include "Core.vh"

// Brief: CPU Top Module, synchronized
// Author: EAirPeter
module SynLajiIntelKnightsLanding(
    clk, rst_n, en, regfile_req_dbg, datamem_addr_dbg,
    pc_dbg, regfile_data_dbg, datamem_data_dbg, display,
    halted, jumped, is_branch, branched, bubble
);
    parameter ProgPath = "C:/.Xilinx/benchmark.hex";
    input clk, rst_n, en;
    input [4:0] regfile_req_dbg;
    input [`DM_ADDR_BIT - 1:0] datamem_addr_dbg;
    output [31:0] pc_dbg;
    output [31:0] regfile_data_dbg;
    output [31:0] datamem_data_dbg;
    output [31:0] display;
    output halted, jumped, is_branch, branched, bubble;
// IF
    wire [`IM_ADDR_BIT - 1:0] pc, pc_4;
    wire halt;
    assign pc_dbg = {20'd0, pc, 2'd0};
    wire [31:0] inst;
    wire [`IM_ADDR_BIT - 1:0] pc_new;
    wire load_pc = jumped || branched;
    SynPC vPC(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .stall(bubble || halt),
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
    wire [`IM_ADDR_BIT - 1:0] pc_4_if_id;
    wire [31:0] inst_if_id;
    
    // TODO: add stall logic
    Pipline_IF_ID pp_IF_ID(  
        .clk(clk),
        .rst_n(rst_n),
        .clr(!load_pc),
        .en(en),
        .stall(bubble || halt),
        .pc_4(pc_4),
        .inst(inst),
        .pc_4_reg(pc_4_if_id),
        .inst_reg(inst_if_id)
    );
// -------------------------------- ID ---------------------------------
    wire [5:0] opcode, funct;
    wire [4:0] rs, rt, rd, shamt;
    wire [15:0] imm16;
    CmbDecoder vDec(
        .inst(inst_if_id),
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

    wire ex_collision_a, dm_collision_a;
    wire ex_collision_b, dm_collision_b;
    
    wire [`WTG_OP_BIT - 1:0] wtg_op;
    wire [`ALU_OP_BIT - 1:0] alu_op;
    wire [`DM_OP_BIT - 1:0] datamem_op;
    wire datamem_w_en;
    wire syscall_en;
    wire regfile_w_en;
    wire [`MUX_RF_REQA_BIT - 1:0] mux_regfile_req_a;
    wire [`MUX_RF_REQB_BIT - 1:0] mux_regfile_req_b;    
    wire [`MUX_RF_REQW_BIT - 1:0] mux_regfile_req_w;
    wire [`MUX_EX_REDIR_DATAA_BIT - 1:0] mux_redirected_regfile_data_a;
    wire [`MUX_EX_REDIR_DATAB_BIT - 1:0] mux_redirected_regfile_data_b;
    wire [`MUX_RF_PRE_DATAW_BIT - 1:0] mux_regfile_pre_data_w;
    wire [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_data_w;
    wire [`MUX_ALU_DATAY_BIT - 1:0] mux_alu_data_y;
    CmbControl vCtl(
        .opcode(opcode),
        .rt(rt),
        .funct(funct),
        .ex_collision_a(ex_collision_a),
        .dm_collision_a(dm_collision_a),
        .ex_collision_b(ex_collision_b),
        .dm_collision_b(dm_collision_b),
        .bubble(bubble),
        .op_wtg(wtg_op),
        .w_en_regfile(regfile_w_en),
        .op_alu(alu_op),
        .op_datamem(datamem_op),
        .w_en_datamem(datamem_w_en),
        .syscall_en(syscall_en),
        .mux_regfile_req_a(mux_regfile_req_a),
        .mux_regfile_req_b(mux_regfile_req_b),
        .mux_regfile_req_w(mux_regfile_req_w),
        .mux_regfile_pre_data_w(mux_regfile_pre_data_w),
        .mux_regfile_data_w(mux_regfile_data_w),
        .mux_alu_data_y(mux_alu_data_y),
        .mux_redirected_regfile_data_a(mux_redirected_regfile_data_a),
        .mux_redirected_regfile_data_b(mux_redirected_regfile_data_b)
    );

    reg [4:0] regfile_req_a, regfile_req_b, regfile_req_w;    // combinatorial
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
    end

    SynDataCollisionDetector vDCD(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .stalled(bubble || halt),
        .regfile_req_a(regfile_req_a),
        .regfile_req_b(regfile_req_b),
        .regfile_req_w((regfile_w_en) ? regfile_req_w : 0),
        .ex_collision_a(ex_collision_a),
        .dm_collision_a(dm_collision_a),
        .ex_collision_b(ex_collision_b),
        .dm_collision_b(dm_collision_b)
    );

    wire regfile_w_en_wb;
    wire [4:0] regfile_req_w_wb;
    wire [31:0] regfile_data_w_wb;
    wire [31:0] regfile_data_a, regfile_data_b;
    SynRegFile vRF(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .w_en(regfile_w_en_wb),
        .req_dbg(regfile_req_dbg),
        .req_w(regfile_req_w_wb),
        .req_a(regfile_req_a),
        .req_b(regfile_req_b),
        .data_dbg(regfile_data_dbg),
        .data_w(regfile_data_w_wb),
        .data_a(regfile_data_a),
        .data_b(regfile_data_b)
    );
    always @(*) begin
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
// ID/EX
// for now just treat read DM -> rt & write rt-> DM as load-use
    wire [`IM_ADDR_BIT - 1:0] pc_4_id_ex;
    wire [4:0] shamt_id_ex;
    wire [31:0] ext_out_sign_id_ex, ext_out_zero_id_ex;
    wire [`WTG_OP_BIT - 1:0] wtg_op_id_ex;
    wire [`ALU_OP_BIT - 1:0] alu_op_id_ex;
    wire [`MUX_ALU_DATAY_BIT - 1:0] mux_alu_data_y_id_ex;
    wire [`DM_OP_BIT - 1:0] datamem_op_id_ex;
    wire datamem_w_en_id_ex;
    wire syscall_en_id_ex;
    wire [4:0] regfile_req_w_id_ex;    // combinatorial
    wire [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_pre_data_w_id_ex, mux_regfile_data_w_id_ex;
    wire [`MUX_EX_REDIR_DATAA_BIT - 1:0] mux_redirected_regfile_data_a_id_ex; 
    wire [`MUX_EX_REDIR_DATAB_BIT - 1:0] mux_redirected_regfile_data_b_id_ex;
    wire [31:0] regfile_data_a_id_ex, regfile_data_b_id_ex;
    wire regfile_w_en_id_ex;
    Pipline_ID_EX pp_ID_EX( 
        .clk(clk), 
        .rst_n(rst_n),
        .clr(!(load_pc || bubble || halt)),
        .en(en),
        .pc_4(pc_4_if_id),
        .pc_4_reg(pc_4_id_ex),
        .shamt(shamt),
        .shamt_reg(shamt_id_ex),
        .ext_out_sign(ext_out_sign),
        .ext_out_sign_reg(ext_out_sign_id_ex),
        .ext_out_zero(ext_out_zero),
        .ext_out_zero_reg(ext_out_zero_id_ex),
        .wtg_op(wtg_op),
        .wtg_op_reg(wtg_op_id_ex),
        .alu_op(alu_op),
        .alu_op_reg(alu_op_id_ex),
        .mux_alu_data_y(mux_alu_data_y),
        .mux_alu_data_y_reg(mux_alu_data_y_id_ex),
        .datamem_op(datamem_op),
        .datamem_op_reg(datamem_op_id_ex),
        .datamem_w_en(datamem_w_en),
        .datamem_w_en_reg(datamem_w_en_id_ex),
        .syscall_en(syscall_en),
        .syscall_en_reg(syscall_en_id_ex),
        .regfile_req_w(regfile_req_w),
        .regfile_req_w_reg(regfile_req_w_id_ex),
        .regfile_w_en(regfile_w_en),
        .regfile_w_en_reg(regfile_w_en_id_ex),
        .mux_regfile_pre_data_w(mux_regfile_pre_data_w),
        .mux_regfile_pre_data_w_reg(mux_regfile_pre_data_w_id_ex),
        .mux_regfile_data_w(mux_regfile_data_w),
        .mux_regfile_data_w_reg(mux_regfile_data_w_id_ex),
        .mux_redirected_regfile_data_a(mux_redirected_regfile_data_a),
        .mux_redirected_regfile_data_a_reg(mux_redirected_regfile_data_a_id_ex),
        .mux_redirected_regfile_data_b(mux_redirected_regfile_data_b),
        .mux_redirected_regfile_data_b_reg(mux_redirected_regfile_data_b_id_ex),
        .regfile_data_a(regfile_data_a),
        .regfile_data_a_reg(regfile_data_a_id_ex),
        .regfile_data_b(regfile_data_b),
        .regfile_data_b_reg(regfile_data_b_id_ex)
);
// -------------------------------- EX ---------------------------------
    reg [31:0] redirected_regfile_data_a, redirected_regfile_data_b;
    wire [31:0] regfile_pre_data_w_ex_dm;
    wire [31:0] regfile_data_w_dm_wb;
    always @(*) begin
        redirected_regfile_data_a = regfile_data_a_id_ex;
        redirected_regfile_data_b = regfile_data_b_id_ex;
        case(mux_redirected_regfile_data_a_id_ex)
            `MUX_EX_REDIR_A_EX: 
                redirected_regfile_data_a = regfile_pre_data_w_ex_dm;
            `MUX_EX_REDIR_A_DM:
                redirected_regfile_data_a = regfile_data_w_dm_wb;
            // `MUX_EX_REDIR_A_OLD
            default: ;
        endcase
        case(mux_redirected_regfile_data_b_id_ex)
            `MUX_EX_REDIR_B_EX: 
                redirected_regfile_data_b = regfile_pre_data_w_ex_dm;
            `MUX_EX_REDIR_B_DM:
                redirected_regfile_data_b = regfile_data_w_dm_wb;
            // `MUX_EX_REDIR_B_OLD
            default: ;
        endcase 
    end

    CmbWTG vWTG(
        .op(wtg_op_id_ex),
        .imm(ext_out_sign_id_ex[`IM_ADDR_BIT - 1:0]),
        .data_x(redirected_regfile_data_a),
        .data_y(redirected_regfile_data_b),
        .pc_4(pc_4_id_ex),
        .pc_new(pc_new),
        .jumped(jumped),
        .is_branch(is_branch),
        .branched(branched)
    );
    
    reg [31:0] alu_data_y;      // combinatorial
    always @(*) begin
        case (mux_alu_data_y_id_ex)
            `MUX_ALU_DATAY_RFB:
                alu_data_y = redirected_regfile_data_b;
            `MUX_ALU_DATAY_EXTS:
                alu_data_y = ext_out_sign_id_ex;
            `MUX_ALU_DATAY_EXTZ:
                alu_data_y = ext_out_zero_id_ex;
            default:
                alu_data_y = 32'd0;
        endcase
    end
    wire [31:0] alu_data_res;
    CmbALU vALU(
        .op(alu_op_id_ex),
        .data_x(redirected_regfile_data_a),
        .data_y(alu_data_y),
        .shamt(shamt_id_ex),
        .data_res(alu_data_res)
    );
    SynSyscall vSys(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .syscall_en(syscall_en_id_ex),
        .data_v0(redirected_regfile_data_a),
        .data_a0(redirected_regfile_data_b),
        .display(display),
        .halt(halt)
    );

    reg [31:0] regfile_pre_data_w;
    always @(*) begin
        regfile_pre_data_w = alu_data_res;
        case (mux_regfile_pre_data_w_id_ex)
            `MUX_RF_DATAW_PC4:
                regfile_pre_data_w = {pc_4_id_ex, 2'b00};
            // MUX_RF_DATAW_ALU
            default: ;
        endcase
    end
// EX/DM
// ALU.alu_data_res
// RF.regfile_data_b
// SYS.halt
// MUX.regfile_pre_data_w
// regfile_req_w
    wire [31:0] alu_data_res_ex_dm;
    wire [31:0] regfile_data_b_ex_dm;
    wire [`DM_OP_BIT - 1:0] datamem_op_ex_dm;
    wire datamem_w_en_ex_dm;
    wire halt_ex_dm;
    wire regfile_w_en_ex_dm;
    wire [4:0] regfile_req_w_ex_dm;
    wire [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_data_w_ex_dm;
    Pipline_EX_DM pp_EX_DM( 
        .clk(clk),
        .rst_n(rst_n),
        .clr(1),
        .en(en),
        .alu_data_res(alu_data_res),
        .alu_data_res_reg(alu_data_res_ex_dm),
        .datamem_op(datamem_op_id_ex),
        .datamem_op_reg(datamem_op_ex_dm),
        .datamem_w_en(datamem_w_en_id_ex),
        .datamem_w_en_reg(datamem_w_en_ex_dm),
        .regfile_data_b(redirected_regfile_data_b),
        .regfile_data_b_reg(regfile_data_b_ex_dm),
        .regfile_w_en(regfile_w_en_id_ex),
        .regfile_w_en_reg(regfile_w_en_ex_dm),
        .regfile_req_w(regfile_req_w_id_ex),
        .regfile_req_w_reg(regfile_req_w_ex_dm),
        .regfile_pre_data_w(regfile_pre_data_w),
        .regfile_pre_data_w_reg(regfile_pre_data_w_ex_dm),
        .mux_regfile_data_w(mux_regfile_data_w_id_ex),
        .mux_regfile_data_w_reg(mux_regfile_data_w_ex_dm),
        .halt(halt),
        .halt_reg(halt_ex_dm)
    );
// -------------------------------- DM ---------------------------------
    wire [31:0] datamem_data;
    SynDataMem vDM(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .op(datamem_op_ex_dm),
        .w_en(datamem_w_en_ex_dm),
        .addr_dbg(datamem_addr_dbg),
        .addr(alu_data_res_ex_dm[`DM_ADDR_BIT - 1:0]),
        .data_in(regfile_data_b_ex_dm),
        .data_dbg(datamem_data_dbg),
        .data(datamem_data)
    );

// DM/WB
// MUX.regfile_data_w
// regfile_req_w
    reg [31:0] regfile_data_w;
    always @(*) begin
        regfile_data_w = regfile_pre_data_w_ex_dm;
        case (mux_regfile_data_w_ex_dm)
            `MUX_RF_DATAW_DM:
                regfile_data_w = datamem_data;
            // MUX_RF_DATAW_EX
            default: ;
        endcase
    end
    wire halt_dm_wb;
    wire regfile_w_en_dm_wb;
    wire [4:0] regfile_req_w_dm_wb;
    Pipline_DM_WB pp_DM_WB( 
        .clk(clk),
        .rst_n(rst_n),
        .clr(1),
        .en(en),
        .halt(halt_ex_dm),
        .halt_reg(halt_dm_wb),
        .regfile_w_en(regfile_w_en_ex_dm),
        .regfile_w_en_reg(regfile_w_en_dm_wb),
        .regfile_req_w(regfile_req_w_ex_dm),
        .regfile_req_w_reg(regfile_req_w_dm_wb),
        .regfile_data_w(regfile_data_w),
        .regfile_data_w_reg(regfile_data_w_dm_wb)
        );
// -------------------------------- WB ---------------------------------
    assign halted = halt_dm_wb;
    assign regfile_w_en_wb = regfile_w_en_dm_wb;
    assign regfile_req_w_wb = regfile_req_w_dm_wb;
    assign regfile_data_w_wb = regfile_data_w_dm_wb;
endmodule
