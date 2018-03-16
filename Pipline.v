`timescale 1ns / 1ps
`include "Core.vh"

module Pipline_IF_ID(clk, rst_n, clr, en, 
                    pc_4, pc_4_reg,
                    inst, inst_reg);
    input clk;
    input rst_n;
    input clr;
    input en;
    input [`IM_ADDR_BIT - 1:0] pc_4;
    input [31:0] inst;
    output reg [`IM_ADDR_BIT - 1:0] pc_4_reg;
    output reg [31:0] inst_reg;
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            pc_4_reg <= 0;
            inst_reg <= 0;
        end
        else if (!clr) begin
            pc_4_reg <= 0;
            inst_reg <= 0;
        end
        else if (!en) begin
            pc_4_reg <= pc_4_reg;
            inst_reg <= inst_reg;
        end
        else begin
            pc_4_reg <= pc_4;
            inst_reg <= inst;
        end
    end
endmodule

module Pipline_ID_EX(clk, rst_n, clr, en,
                    pc_4,                      pc_4_reg,
                    shamt,                     shamt_reg,
                    ext_out_sign,              ext_out_sign_reg,
                    ext_out_zero,              ext_out_zero_reg,
                    wtg_op,                    wtg_op_reg,
                    alu_op,                    alu_op_reg,
                    mux_alu_data_y,            mux_alu_data_y_reg,
                    datamem_op,                datamem_op_reg,
                    datamem_w_en,              datamem_w_en_reg,
                    syscall_en,                syscall_en_reg,
                    regfile_req_w,             regfile_req_w_reg,
                    regfile_w_en,              regfile_w_en_reg,
                    mux_regfile_pre_data_w,    mux_regfile_pre_data_w_reg,
                    mux_regfile_data_w,        mux_regfile_data_w_reg,
                    mux_redirected_regfile_data_a,     mux_redirected_regfile_data_a_reg,
                    mux_redirected_regfile_data_b,     mux_redirected_regfile_data_b_reg,
                    regfile_data_a,            regfile_data_a_reg,
                    regfile_data_b,            regfile_data_b_reg
);
    input clk;
    input rst_n;
    input clr;
    input en;
    input [`IM_ADDR_BIT - 1:0] pc_4;
    input [4:0] shamt;
    input [31:0] ext_out_sign, ext_out_zero;
    input [`WTG_OP_BIT - 1:0] wtg_op;
    input [`ALU_OP_BIT - 1:0] alu_op;
    input [`MUX_ALU_DATAY_BIT - 1:0] mux_alu_data_y;
    input [`DM_OP_BIT - 1:0] datamem_op;
    input datamem_w_en;
    input syscall_en;
    input [4:0] regfile_req_w;    // combinatorial
    input [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_pre_data_w, mux_regfile_data_w;
    input [`MUX_EX_REDIR_DATAA_BIT - 1:0] mux_redirected_regfile_data_a; 
    input [`MUX_EX_REDIR_DATAB_BIT - 1:0] mux_redirected_regfile_data_b;
    input [31:0] regfile_data_a, regfile_data_b;
    input regfile_w_en;

    output reg [`IM_ADDR_BIT - 1:0] pc_4_reg;
    output reg [4:0] shamt_reg;
    output reg [31:0] ext_out_sign_reg, ext_out_zero_reg;
    output reg [`WTG_OP_BIT - 1:0] wtg_op_reg;
    output reg [`ALU_OP_BIT - 1:0] alu_op_reg;
    output reg [`MUX_ALU_DATAY_BIT - 1:0] mux_alu_data_y_reg;
    output reg [`DM_OP_BIT - 1:0] datamem_op_reg;
    output reg datamem_w_en_reg;
    output reg syscall_en_reg;
    output reg [4:0] regfile_req_w_reg;    // combinatorial
    output reg [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_pre_data_w_reg, mux_regfile_data_w_reg;
    output reg [`MUX_EX_REDIR_DATAA_BIT - 1:0] mux_redirected_regfile_data_a_reg; 
    output reg [`MUX_EX_REDIR_DATAB_BIT - 1:0] mux_redirected_regfile_data_b_reg;
    output reg [31:0] regfile_data_a_reg, regfile_data_b_reg;
    output reg regfile_w_en_reg;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            pc_4_reg<=0;
            shamt_reg<=0;
            ext_out_sign_reg<=0;
            ext_out_zero_reg<=0;
            wtg_op_reg<=0;
            alu_op_reg<=0;
            mux_alu_data_y_reg<=0;
            datamem_op_reg<=0;
            datamem_w_en_reg<=0;
            syscall_en_reg<=0;
            regfile_req_w_reg<=0;
            regfile_w_en_reg<=0;
            mux_regfile_pre_data_w_reg<=0;
            mux_regfile_data_w_reg<=0;
            mux_redirected_regfile_data_a_reg<=0;
            mux_redirected_regfile_data_b_reg<=0;
            regfile_data_a_reg<=0;
            regfile_data_b_reg<=0;
        end
        else if (!clr) begin
            pc_4_reg<=0;
            shamt_reg<=0;
            ext_out_sign_reg<=0;
            ext_out_zero_reg<=0;
            wtg_op_reg<=0;
            alu_op_reg<=0;
            mux_alu_data_y_reg<=0;
            datamem_op_reg<=0;
            datamem_w_en_reg<=0;
            syscall_en_reg<=0;
            regfile_req_w_reg<=0;
            regfile_w_en_reg<=0;
            mux_regfile_pre_data_w_reg<=0;
            mux_regfile_data_w_reg<=0;
            mux_redirected_regfile_data_a_reg<=0;
            mux_redirected_regfile_data_b_reg<=0;
            regfile_data_a_reg<=0;
            regfile_data_b_reg<=0;
        end
        else if (!en) begin
            pc_4_reg<=                      pc_4_reg;
            shamt_reg<=                     shamt_reg;
            ext_out_sign_reg<=              ext_out_sign_reg;
            ext_out_zero_reg<=              ext_out_zero_reg;
            wtg_op_reg<=                    wtg_op_reg;
            alu_op_reg<=                    alu_op_reg;
            mux_alu_data_y_reg<=            mux_alu_data_y_reg;
            datamem_op_reg<=                datamem_op_reg;
            datamem_w_en_reg<=              datamem_w_en_reg;
            syscall_en_reg<=                syscall_en_reg;
            regfile_req_w_reg<=             regfile_req_w_reg;
            regfile_w_en_reg<=              regfile_w_en_reg;
            mux_regfile_pre_data_w_reg<=    mux_regfile_pre_data_w_reg;
            mux_regfile_data_w_reg<=        mux_regfile_data_w_reg;
            mux_redirected_regfile_data_a_reg<=     mux_redirected_regfile_data_a_reg;
            mux_redirected_regfile_data_b_reg<=     mux_redirected_regfile_data_b_reg;
            regfile_data_a_reg<=            regfile_data_a_reg;
            regfile_data_b_reg<=            regfile_data_b_reg;
        end
        else begin
            pc_4_reg<=                      pc_4;
            shamt_reg<=                     shamt;
            ext_out_sign_reg<=              ext_out_sign;
            ext_out_zero_reg<=              ext_out_zero;
            wtg_op_reg<=                    wtg_op;
            alu_op_reg<=                    alu_op;
            mux_alu_data_y_reg<=            mux_alu_data_y;
            datamem_op_reg<=                datamem_op;
            datamem_w_en_reg<=              datamem_w_en;
            syscall_en_reg<=                syscall_en;
            regfile_req_w_reg<=             regfile_req_w;
            regfile_w_en_reg<=              regfile_w_en;
            mux_regfile_pre_data_w_reg<=    mux_regfile_pre_data_w;
            mux_regfile_data_w_reg<=        mux_regfile_data_w;
            mux_redirected_regfile_data_a_reg<=     mux_redirected_regfile_data_a;
            mux_redirected_regfile_data_b_reg<=     mux_redirected_regfile_data_b;
            regfile_data_a_reg<=            regfile_data_a;
            regfile_data_b_reg<=            regfile_data_b;
        end
    end
endmodule

module Pipline_EX_DM(clk, rst_n, clr, en,
                    alu_data_res,               alu_data_res_reg,
                    datamem_op,                 datamem_op_reg,
                    datamem_w_en,               datamem_w_en_reg,
                    regfile_data_b,             regfile_data_b_reg,
                    regfile_w_en,               regfile_w_en_reg,
                    regfile_req_w,              regfile_req_w_reg,
                    regfile_pre_data_w,         regfile_pre_data_w_reg,
                    mux_regfile_data_w,         mux_regfile_data_w_reg,
                    halt,                       halt_reg);
    input clk;
    input rst_n;
    input clr;
    input en;

    input [31:0] alu_data_res;
    input [31:0] regfile_data_b;
    input [`DM_OP_BIT - 1:0] datamem_op;
    input datamem_w_en;
    input halt;
    input regfile_w_en;
    input [4:0] regfile_req_w;
    input [31:0] regfile_pre_data_w;
    input [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_data_w;

    output reg [31:0] alu_data_res_reg;
    output reg [31:0] regfile_data_b_reg;
    output reg [`DM_OP_BIT - 1:0] datamem_op_reg;
    output reg datamem_w_en_reg;
    output reg halt_reg;
    output reg regfile_w_en_reg;
    output reg [4:0] regfile_req_w_reg;
    output reg [31:0] regfile_pre_data_w_reg;
    output reg [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_data_w_reg;

    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            alu_data_res_reg<=0;
            datamem_op_reg<=0;
            datamem_w_en_reg<=0;
            regfile_data_b_reg<=0;
            regfile_w_en_reg<=0;
            regfile_req_w_reg<=0;
            regfile_pre_data_w_reg<=0;
            mux_regfile_data_w_reg<=0;
            halt_reg<=0;
        end
        else if (!clr) begin
            alu_data_res_reg<=0;
            datamem_op_reg<=0;
            datamem_w_en_reg<=0;
            regfile_data_b_reg<=0;
            regfile_w_en_reg<=0;
            regfile_req_w_reg<=0;
            regfile_pre_data_w_reg<=0;
            mux_regfile_data_w_reg<=0;
            halt_reg<=0;
        end
        else if(!en) begin
            alu_data_res_reg<=              alu_data_res_reg;
            datamem_op_reg<=                datamem_op_reg;
            datamem_w_en_reg<=              datamem_w_en;
            regfile_data_b_reg<=            regfile_data_b_reg;
            regfile_w_en_reg<=              regfile_w_en_reg;
            regfile_req_w_reg<=             regfile_req_w_reg;
            regfile_pre_data_w_reg<=        regfile_pre_data_w_reg;
            mux_regfile_data_w_reg<=        mux_regfile_data_w_reg;
            halt_reg<=                      halt_reg;
        end
        else begin
            alu_data_res_reg<=              alu_data_res;
            datamem_op_reg<=                datamem_op;
            datamem_w_en_reg<=              datamem_w_en;
            regfile_data_b_reg<=            regfile_data_b;
            regfile_w_en_reg<=              regfile_w_en;
            regfile_req_w_reg<=             regfile_req_w;
            regfile_pre_data_w_reg<=        regfile_pre_data_w;
            mux_regfile_data_w_reg<=        mux_regfile_data_w;
            halt_reg<=                      halt;
        end
    end
endmodule

module Pipline_DM_WB(clk, rst_n, clr, en,
                    halt,           halt_reg,
                    regfile_w_en,   regfile_w_en_reg,
                    regfile_req_w,  regfile_req_w_reg,
                    regfile_data_w, regfile_data_w_reg);
    input clk;
    input rst_n;
    input clr;
    input en;

    input [31:0] regfile_data_w;
    input halt;
    input regfile_w_en;
    input [4:0] regfile_req_w;

    output reg [31:0] regfile_data_w_reg;
    output reg halt_reg;
    output reg regfile_w_en_reg;
    output reg [4:0] regfile_req_w_reg;

    always @(posedge clk) begin
        if (!rst_n) begin
            halt_reg<=0;
            regfile_w_en_reg<=0;
            regfile_req_w_reg<=0;
            regfile_data_w_reg<=0;
        end
        else if (!clr) begin
            halt_reg<=0;
            regfile_w_en_reg<=0;
            regfile_req_w_reg<=0;
            regfile_data_w_reg<=0;
        end
        else if (!en) begin
            halt_reg<=          halt_reg;
            regfile_w_en_reg<=  regfile_w_en_reg;
            regfile_req_w_reg<= regfile_req_w_reg;
            regfile_data_w_reg<=regfile_data_w_reg;
        end
        else begin
            halt_reg<=          halt;
            regfile_w_en_reg<=  regfile_w_en;
            regfile_req_w_reg<= regfile_req_w;
            regfile_data_w_reg<=regfile_data_w;
        end
    end
endmodule