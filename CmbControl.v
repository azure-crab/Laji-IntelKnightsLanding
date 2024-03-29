`timescale 1ns / 1ps

`include "Core.vh"

// Brief: Control Module, synchronized
// Author: FluorineDog
module CmbControl(
    opcode, rt, funct, 
    load_use, ex_collision_a, dm_collision_a, ex_collision_b, dm_collision_b, bubble,
    op_wtg, w_en_regfile, op_alu, op_datamem, w_en_datamem, syscall_en,
    mux_regfile_req_a, mux_regfile_req_b, mux_regfile_req_w,
    mux_regfile_pre_data_w, mux_regfile_data_w, mux_alu_data_y, 
    mux_redirected_regfile_data_a, mux_redirected_regfile_data_b
);
    input [5:0] opcode;
    input [4:0] rt;
    input [5:0] funct;
    input load_use;
    input ex_collision_a, dm_collision_a;
    input ex_collision_b, dm_collision_b;
    output bubble;
    output reg [`WTG_OP_BIT - 1:0] op_wtg;
    output reg w_en_regfile;
    output reg [`ALU_OP_BIT - 1:0] op_alu; // alias to alu to increase Hamming Distance 
    output reg [`DM_OP_BIT - 1:0] op_datamem;
    output reg w_en_datamem;
    output reg syscall_en;
    output [`MUX_RF_REQA_BIT - 1:0] mux_regfile_req_a;
    output [`MUX_RF_REQB_BIT - 1:0] mux_regfile_req_b;    
    output reg [`MUX_RF_REQW_BIT - 1:0] mux_regfile_req_w;
    output reg [`MUX_RF_DATAW_BIT - 1:0] mux_regfile_data_w;
    output reg [`MUX_ALU_DATAY_BIT - 1:0] mux_alu_data_y;

    output reg [`MUX_RF_PRE_DATAW_BIT - 1:0] mux_regfile_pre_data_w;
    output reg [`MUX_EX_REDIR_DATAA_BIT - 1:0] mux_redirected_regfile_data_a;
    output reg [`MUX_EX_REDIR_DATAB_BIT - 1:0] mux_redirected_regfile_data_b;

    // when its syscall, both of these two mux signal will be 1 (see Core.vh)
    assign mux_regfile_req_a = syscall_en;
    assign mux_regfile_req_b = syscall_en;

    // bubble
    assign bubble = load_use;

    always@(*) begin
        // for redirect
        mux_redirected_regfile_data_a = `MUX_EX_REDIR_A_OLD;
        mux_redirected_regfile_data_b = `MUX_EX_REDIR_B_OLD;
        if (ex_collision_a) mux_redirected_regfile_data_a = `MUX_EX_REDIR_A_EX;
        else if (dm_collision_a) mux_redirected_regfile_data_a = `MUX_EX_REDIR_A_DM;
        if (ex_collision_b) mux_redirected_regfile_data_b = `MUX_EX_REDIR_B_EX;
        else if (dm_collision_b) mux_redirected_regfile_data_b = `MUX_EX_REDIR_B_DM;

        op_wtg = `WTG_OP_NOP;
        op_alu = `ALU_OP_AND;
        op_datamem = `DM_OP_WD;  
        w_en_regfile = 1;
        w_en_datamem = 0;
        syscall_en = 0;

        mux_regfile_req_w = `MUX_RF_REQW_RT;
        mux_regfile_pre_data_w = `MUX_RF_DATAW_ALU;
        mux_regfile_data_w = `MUX_RF_DATAW_EX;
        mux_alu_data_y = `MUX_ALU_DATAY_EXTS;
        case(opcode)
            6'b000000:  begin 
                mux_regfile_req_w   = `MUX_RF_REQW_RD;
                mux_regfile_data_w  = `MUX_RF_DATAW_EX;
                mux_alu_data_y      = `MUX_ALU_DATAY_RFB;
                case(funct)
                    6'b000000:  op_alu = `ALU_OP_SLL;       // sll
                    6'b000010:  op_alu = `ALU_OP_SRL;       // srl
                    6'b000011:  op_alu = `ALU_OP_SRA;       // sra
                    6'b000100:  op_alu = `ALU_OP_SLLV;      // sllv
                    6'b000110:  op_alu = `ALU_OP_SRLV;      // srlv
                    6'b000111:  op_alu = `ALU_OP_SRAV;      // srav
                    6'b001000:  begin                       // jr
                        op_wtg = `WTG_OP_J32;
                        w_en_regfile = 0;
                    end
                    6'b001100:  begin                       // syscall
                        syscall_en = 1;
                        w_en_regfile = 0;
                    end
                    6'b100000:  op_alu = `ALU_OP_ADD;       // add
                    6'b100001:  op_alu = `ALU_OP_ADD;       // addu
                    6'b100010:  op_alu = `ALU_OP_SUB;       // sub
                    6'b100011:  op_alu = `ALU_OP_SUB;       // subu
                    6'b100100:  op_alu = `ALU_OP_AND;       // and
                    6'b100101:  op_alu = `ALU_OP_OR;        // or
                    6'b100110:  op_alu = `ALU_OP_XOR;       // xor
                    6'b100111:  op_alu = `ALU_OP_NOR;       // nor
                    6'b101010:  op_alu = `ALU_OP_SLT;       // slt
                    6'b101011:  op_alu = `ALU_OP_SLTU;      // sltu
                endcase
            end

            6'b000001:  begin
                w_en_regfile = 0;
                case(rt[0])
                    1'b0: begin op_wtg = `WTG_OP_BLTZ; end  // bltz
                    // no longer supported
                    // 1'b1: begin op_wtg = `WTG_OP_BGEZ; end  // bgez
                endcase
            end
            6'b000010:  begin   op_wtg = `WTG_OP_J26;  w_en_regfile = 0; end    // j
            6'b000011:  begin   op_wtg = `WTG_OP_J26;                           // jal
                mux_regfile_req_w = `MUX_RF_REQW_31;
                mux_regfile_pre_data_w = `MUX_RF_DATAW_PC4;
                mux_regfile_data_w = `MUX_RF_DATAW_EX;
            end
            6'b000100:  begin   op_wtg = `WTG_OP_BEQ;  w_en_regfile = 0; end    // beq
            6'b000101:  begin   op_wtg = `WTG_OP_BNE;  w_en_regfile = 0; end    // bne
            // 6'b000110:  begin   op_wtg = `WTG_OP_BLEZ; w_en_regfile = 0; end    // blez
            // 6'b000111:  begin   op_wtg = `WTG_OP_BGTZ; w_en_regfile = 0; end    // bgtz

            6'b001000:          op_alu = `ALU_OP_ADD;       // addi
            6'b001001:          op_alu = `ALU_OP_ADD;       // addiu
            6'b001010:          op_alu = `ALU_OP_SLT;       // slti
            6'b001011:          op_alu = `ALU_OP_SLTU;      // sltiu

            6'b001100:  begin   op_alu = `ALU_OP_AND; mux_alu_data_y = `MUX_ALU_DATAY_EXTZ; end     // andi
            6'b001101:  begin   op_alu = `ALU_OP_OR;  mux_alu_data_y = `MUX_ALU_DATAY_EXTZ; end     // ori
            6'b001110:  begin   op_alu = `ALU_OP_XOR; mux_alu_data_y = `MUX_ALU_DATAY_EXTZ; end     // xori

            6'b001111:  begin   op_alu = `ALU_OP_LUI; mux_regfile_data_w = `MUX_RF_DATAW_EX; end   // lui

            6'b100000:  begin   op_alu = `ALU_OP_ADD; mux_regfile_data_w = `MUX_RF_DATAW_DM; op_datamem = `DM_OP_SB; end    // lb
            6'b100001:  begin   op_alu = `ALU_OP_ADD; mux_regfile_data_w = `MUX_RF_DATAW_DM; op_datamem = `DM_OP_SH; end    // lh
            6'b100011:  begin   op_alu = `ALU_OP_ADD; mux_regfile_data_w = `MUX_RF_DATAW_DM; op_datamem = `DM_OP_WD; end    // lw
            6'b100100:  begin   op_alu = `ALU_OP_ADD; mux_regfile_data_w = `MUX_RF_DATAW_DM; op_datamem = `DM_OP_UB; end    // lbu
            6'b100101:  begin   op_alu = `ALU_OP_ADD; mux_regfile_data_w = `MUX_RF_DATAW_DM; op_datamem = `DM_OP_UH; end    // lhu

            6'b101000:  begin   op_alu = `ALU_OP_ADD; op_datamem = `DM_OP_SB; w_en_datamem = 1; w_en_regfile = 0; end       // sb
            6'b101001:  begin   op_alu = `ALU_OP_ADD; op_datamem = `DM_OP_SH; w_en_datamem = 1; w_en_regfile = 0; end       // sh
            6'b101011:  begin   op_alu = `ALU_OP_ADD; op_datamem = `DM_OP_WD; w_en_datamem = 1; w_en_regfile = 0; end       // sw
          endcase
      end
endmodule
