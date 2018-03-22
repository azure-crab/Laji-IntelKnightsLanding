`timescale 1ns / 1ps
`include "Core.vh"

// Brief: CPU Top Module, synchronized
// Author: EAirPeter
module SynLajiIntelKnightsLanding(
    clk, rst_n, en, regfile_req_dbg, datamem_addr_dbg,
    pc_dbg, regfile_data_dbg, datamem_data_dbg, display,
    halted, jumped, is_branch, branched, bubble, load_use,
    bht_hit, bht_failed,
    int0, int1, int2
);
    parameter ProgPath = "C:/.Xilinx/benchmark.hex";
    input clk, rst_n, en;
    input [4:0] regfile_req_dbg;
    input [`DM_ADDR_BIT - 1:0] datamem_addr_dbg;
    input int0, int1, int2;
    output [31:0] pc_dbg;
    output [31:0] regfile_data_dbg;
    output [31:0] datamem_data_dbg;
    output [31:0] display;
    output halted, jumped, is_branch, branched, bubble, load_use, bht_hit, bht_failed;
// IF
    wire [`IM_ADDR_BIT - 1:0] pc, pc_4;
    wire [`IM_ADDR_BIT - 1:0] pc_if_id;
    wire [`IM_ADDR_BIT - 1:0] pc_id_ex;
    wire [`IM_ADDR_BIT - 1:0] pc_4_id_ex;
    wire halt;
    assign pc_dbg = {20'd0, pc, 2'd0};
    wire [31:0] inst;
    wire [`IM_ADDR_BIT - 1:0] g_addr;   // from wtg
    wire isbj = jumped || is_branch;
    wire jinted;
    reg bht_failed;
    
    always @(*) begin
        bht_failed = 0;
        if (jumped || branched)
            bht_failed = g_addr != pc_if_id;
        else if (isbj)
            bht_failed = pc_4_id_ex != pc_if_id;
        // ?????????????????????????????isbj
    end
    
    SynPC vPC(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .stall(bubble || halt),
        .isbj(isbj),                         // ???????????BHT???
        .gone(jumped || branched || jinted), // ??????????/?????????????pc???g_addr????s_addr
        .keep_pc(!(bht_failed || jinted)),   // ????????pc?BHT??????/?????jint
        .pc_before_g(pc_id_ex),              // WTG?????????????????BHT
        .g_addr(g_addr),                     // ?????????????
        .s_addr(pc_4_id_ex),                 // ???????????
        .bht_hit(bht_hit),
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
    Pipline_IF_ID pp_IF_ID(  
        .clk(clk),
        .rst_n(rst_n),
        .clr(!(bht_failed || jinted)),
        .en(en),
        .stall(bubble || halt),
        .pc_4(pc_4),
        .inst(inst),
        .pc_4_reg(pc_4_if_id),
        .inst_reg(inst_if_id),
        .pc(pc),
        .pc_reg(pc_if_id)
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

    wire [`WTG_OP_BIT - 1:0] wtg_op;
    wire [`ALU_OP_BIT - 1:0] alu_op;
    wire [`DM_OP_BIT - 1:0] datamem_op;
    wire datamem_w_en;
    wire syscall_en;
    wire regfile_w_en;
    wire [`MUX_RF_REQA_BIT - 1:0] mux_regfile_req_a;
    wire [`MUX_RF_REQB_BIT - 1:0] mux_regfile_req_b;    
    wire [`MUX_RF_REQW_BIT - 1:0] mux_regfile_req_w;
    wire [`MUX_RF_PRE_DATAW_BIT - 1:0] mux_regfile_pre_data_w;
    wire [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_data_w;
    wire [`MUX_ALU_DATAY_BIT - 1:0] mux_alu_data_y;
    // for bubble and redirect
    wire ex_collision_a, dm_collision_a;
    wire ex_collision_b, dm_collision_b;
    wire [`MUX_EX_REDIR_DATAA_BIT - 1:0] mux_redirected_regfile_data_a;
    wire [`MUX_EX_REDIR_DATAB_BIT - 1:0] mux_redirected_regfile_data_b;
    // for interrupt
    wire [3:0] cp0_w_en, cp0_w_en_id_ex, cp0_w_en_ex_dm, cp0_w_en_dm_wb;
    wire inting, inting_id_ex, inting_ex_dm, inting_dm_wb;
    wire int;
    wire [2:0] ints;
    wire [3:0] cp0_w_data;
    wire [`MUX_CP0_DATA_BIT - 1:0] mux_cp0_data;
    wire [31:0] irs;
    CmbControl vCtl(
        .opcode(opcode),
        .rs(rs),
        .rt(rt),
        .rd(rd),
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
        .mux_regfile_pre_data_w(mux_regfile_pre_data_w),
        .mux_regfile_data_w(mux_regfile_data_w),
        .mux_alu_data_y(mux_alu_data_y),
        // for bubble and redirect
        .load_use(load_use),
        .ex_collision_a(ex_collision_a),
        .dm_collision_a(dm_collision_a),
        .ex_collision_b(ex_collision_b),
        .dm_collision_b(dm_collision_b),
        .bubble(bubble),
        .mux_redirected_regfile_data_a(mux_redirected_regfile_data_a),
        .mux_redirected_regfile_data_b(mux_redirected_regfile_data_b),
        // for interrupt
        .cp0_w_en(cp0_w_en),
        .cp0_w_data(cp0_w_data),
        .cp0_w_collision((|cp0_w_en_id_ex) || (|cp0_w_en_ex_dm) || (|cp0_w_en_dm_wb)),
        .int(int && !(inting_id_ex || inting_ex_dm || inting_dm_wb)),                   // only get interrupt when no interrupt handling
        .ints(ints),
        .inting(inting),
        .irs(irs[2:0]),
        .mux_cp0_data(mux_cp0_data)
    );

    wire irs_set_en, irs_clr_en, ie_w_en, epc_w_en;
    wire [2:0] irs_w_mask;
    wire ie_w_data;
    wire [31:0] epc_w_data;
    wire [31:0] ie, epc;
    SynCoprocessor vCP0(
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .int0(int0),
        .int1(int1),
        .int2(int2),
        .irs_set_en(irs_set_en),
        .irs_clr_en(irs_clr_en),
        .irs_w_mask(irs_w_mask),
        .ie_w_en(ie_w_en),
        .ie_w_data(ie_w_data),
        .epc_w_en(epc_w_en),
        .epc_w_data(epc_w_data),
        .int(int),
        .ints(ints),
        .irs(irs),
        .ie(ie),
        .epc(epc)
    );

    reg [4:0] regfile_req_a, regfile_req_b;    // combinatorial
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
    
    wire regfile_w_en_id_ex;
    wire [4:0] regfile_req_w_id_ex;
    wire regfile_w_en_ex_dm;
    wire [4:0] regfile_req_w_ex_dm;
    wire [`MUX_RF_PRE_DATAW_BIT - 1:0] mux_regfile_pre_data_w_id_ex;
    wire [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_data_w_id_ex;
    assign ex_collision_a = regfile_w_en_id_ex && (regfile_req_w_id_ex != 0) && (regfile_req_w_id_ex == regfile_req_a);
    assign ex_collision_b = regfile_w_en_id_ex && (regfile_req_w_id_ex != 0) && (regfile_req_w_id_ex == regfile_req_b);
    assign dm_collision_a = regfile_w_en_ex_dm && (regfile_req_w_ex_dm != 0) && (regfile_req_w_ex_dm == regfile_req_a);
    assign dm_collision_b = regfile_w_en_ex_dm && (regfile_req_w_ex_dm != 0) && (regfile_req_w_ex_dm == regfile_req_b);
    assign load_use = (mux_regfile_data_w_id_ex == `MUX_RF_DATAW_DM) && (ex_collision_a || ex_collision_b);
    // SynDataCollisionDetector vDCD(
    //     .clk(clk),
    //     .rst_n(rst_n),
    //     .en(en),
    //     .stalled(bubble || halt || jumped || branched),
    //     .dm_load(mux_regfile_data_w),
    //     .regfile_req_a(regfile_req_a),
    //     .regfile_req_b(regfile_req_b),
    //     .regfile_req_w((regfile_w_en) ? regfile_req_w : 5'b0),
    //     .load_use(load_use),
    //     .ex_collision_a(ex_collision_a),
    //     .dm_collision_a(dm_collision_a),
    //     .ex_collision_b(ex_collision_b),
    //     .dm_collision_b(dm_collision_b)
    // );

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

    reg [4:0] regfile_req_w;
    reg [31:0] cp0_data;
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
        case (mux_cp0_data)
            `MUX_CP0_DATA_IE:
                cp0_data = ie;
            `MUX_CP0_DATA_EPC:
                cp0_data = epc;
            default:
                cp0_data = 0;
        endcase
    end
// ID/EX
// for now just treat read DM -> rt & write rt-> DM as load-use
    wire [4:0] shamt_id_ex;
    wire [31:0] ext_out_sign_id_ex, ext_out_zero_id_ex;
    wire [`WTG_OP_BIT - 1:0] wtg_op_id_ex;
    wire [`ALU_OP_BIT - 1:0] alu_op_id_ex;
    wire [`MUX_ALU_DATAY_BIT - 1:0] mux_alu_data_y_id_ex;
    wire [`DM_OP_BIT - 1:0] datamem_op_id_ex;
    wire datamem_w_en_id_ex;
    wire syscall_en_id_ex;
    wire [`MUX_EX_REDIR_DATAA_BIT - 1:0] mux_redirected_regfile_data_a_id_ex; 
    wire [`MUX_EX_REDIR_DATAB_BIT - 1:0] mux_redirected_regfile_data_b_id_ex;
    wire [31:0] regfile_data_a_id_ex, regfile_data_b_id_ex;
    wire [3:0] cp0_w_data_id_ex;
    wire [31:0] cp0_data_id_ex;
    wire [2:0] ints_id_ex;
    Pipline_ID_EX pp_ID_EX( 
        .clk(clk), 
        .rst_n(rst_n),
        .clr(!(bht_failed || jinted || bubble || halt)),
        .en(en),
        .pc(pc_if_id),
        .pc_reg(pc_id_ex),
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
        .regfile_data_b_reg(regfile_data_b_id_ex),
        .cp0_w_en(cp0_w_en),
        .cp0_w_en_reg(cp0_w_en_id_ex),
        .cp0_w_data(cp0_w_data),
        .cp0_w_data_reg(cp0_w_data_id_ex),
        .cp0_data(cp0_data),
        .cp0_data_reg(cp0_data_id_ex),
        .inting(inting),
        .inting_reg(inting_id_ex),
        .ints(ints),
        .ints_reg(ints_id_ex)
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
        .pc_new(g_addr),
        .jumped(jumped),
        .is_branch(is_branch),
        .branched(branched),
        .jinted(jinted),
        .ints(ints_id_ex),
        .epc(epc)
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
            `MUX_RF_PRE_DATAW_PC4:
                regfile_pre_data_w = {pc_4_id_ex, 2'b00};
            `MUX_RF_PRE_DATAW_ALU:
                regfile_pre_data_w = alu_data_res;
            `MUX_RF_PRE_DATAW_CP0:
                regfile_pre_data_w = cp0_data_id_ex;
            `MUX_RF_PRE_DATAW_RFB:
                regfile_pre_data_w = redirected_regfile_data_b;
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
    wire [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_data_w_ex_dm;
    wire [3:0] cp0_w_data_ex_dm;
    wire [`IM_ADDR_BIT-1:0] pc_ex_dm;
    Pipline_EX_DM pp_EX_DM( 
        .pc(pc_id_ex),
        .pc_reg(pc_ex_dm),
        .clk(clk),
        .rst_n(rst_n),
        .clr('b1),
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
        .halt_reg(halt_ex_dm),
        .cp0_w_en(cp0_w_en_id_ex),
        .cp0_w_en_reg(cp0_w_en_ex_dm),
        .cp0_w_data(cp0_w_data_id_ex),
        .cp0_w_data_reg(cp0_w_data_ex_dm),
        .inting(inting_id_ex),
        .inting_reg(inting_ex_dm)
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
    wire [3:0] cp0_w_data_dm_wb;
    wire [`IM_ADDR_BIT-1:0] pc_dm_wb;
    Pipline_DM_WB pp_DM_WB( 
        .pc(pc_ex_dm),
        .pc_reg(pc_dm_wb),
        .clk(clk),
        .rst_n(rst_n),
        .clr('b1),
        .en(en),
        .halt(halt_ex_dm),
        .halt_reg(halt_dm_wb),
        .regfile_w_en(regfile_w_en_ex_dm),
        .regfile_w_en_reg(regfile_w_en_dm_wb),
        .regfile_req_w(regfile_req_w_ex_dm),
        .regfile_req_w_reg(regfile_req_w_dm_wb),
        .regfile_data_w(regfile_data_w),
        .regfile_data_w_reg(regfile_data_w_dm_wb),
        .cp0_w_en(cp0_w_en_ex_dm),
        .cp0_w_en_reg(cp0_w_en_dm_wb),
        .cp0_w_data(cp0_w_data_ex_dm),
        .cp0_w_data_reg(cp0_w_data_dm_wb),
        .inting(inting_ex_dm),
        .inting_reg(inting_dm_wb)
        );
// -------------------------------- WB ---------------------------------
    // if ie_w_en && epc_w_en, so it must be interrupt implicit instruction, so load pc, 
    // else (!ie_w_en) must be user instruction, load regfile_data_w
    assign epc_w_data = (ie_w_en) ? {{(30-`IM_ADDR_BIT){1'b0}}, pc_dm_wb,2'b00} : regfile_data_w_dm_wb;
    assign {irs_set_en, irs_clr_en, ie_w_en, epc_w_en} = cp0_w_en_dm_wb;
    assign {irs_w_mask, ie_w_data} = cp0_w_data_dm_wb;
    assign halted = halt_dm_wb;
    assign regfile_w_en_wb = regfile_w_en_dm_wb;
    assign regfile_req_w_wb = regfile_req_w_dm_wb;
    assign regfile_data_w_wb = regfile_data_w_dm_wb;
endmodule
