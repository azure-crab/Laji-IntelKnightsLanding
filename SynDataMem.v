`timescale 1ns / 1ps
`include "Core.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/12/2018 06:23:57 PM
// Design Name: 
// Module Name: SynDataMem
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SynDataMem(clk, rst_n, en, op, w_en, addr_dbg, addr, data_in, data_dbg, data);
    input clk;
    input rst_n;
    input en;
    input [`DM_OP_BIT - 1:0] op;
    input w_en;             // Write Enable
    input [31:0] addr_dbg;  // Address of the data for debugging
    input [31:0] addr;
    input [31:0] data_in;
    output reg [31:0] data_dbg; // Data to be displayed for debugging
    output reg [31:0] data;
    reg [31:0] mem[1023:0];
    reg [9:0] effAddr,effDbgAddr;
    integer i;
    always @ (*)
    begin
        effDbgAddr <= addr_dbg[11:2];
        effAddr <= addr[11:2]; 
        if(en && rst_n)
        begin
             data_dbg <= mem[effDbgAddr];
             case (op)
                                 `DM_OP_WD : data <= mem[effAddr];
                                 `DM_OP_UH : 
                                 begin
                                     case (addr[1])
                                         0 : data <= {16'h0,mem[effAddr][15:0]};
                                         1 : data <= {16'h0,mem[effAddr][31:16]};
                                     endcase
                                 end
                                 `DM_OP_UB : 
                                 begin
                                     case (addr[1:0])
                                         0 : data <= {24'h0,mem[effAddr][7:0]};
                                         1 : data <= {24'h0,mem[effAddr][15:8]};
                                         2 : data <= {24'h0,mem[effAddr][23:16]};
                                         3 : data <= {24'h0,mem[effAddr][31:24]};
                                     endcase
                                 end
                                 `DM_OP_SH :
                                 begin
                                     case (addr[1])
                                         0 : data <= {{16{mem[effAddr][15]}},mem[effAddr][15:0]};
                                         1 : data <= {{16{mem[effAddr][31]}},mem[effAddr][31:16]};
                                     endcase
                                 end                    
                                 `DM_OP_SB : 
                                 begin
                                     case (addr[1:0])
                                         0 : data <= {{24{mem[effAddr][7]}},mem[effAddr][7:0]};
                                         1 : data <= {{24{mem[effAddr][15]}},mem[effAddr][15:8]};
                                         2 : data <= {{24{mem[effAddr][23]}},mem[effAddr][23:16]};
                                         3 : data <= {{24{mem[effAddr][31]}},mem[effAddr][31:24]};
                                     endcase
                                 end
                                 default : data <= 0;
                                 endcase
        end
        else
        begin data <= 0; data_dbg <= 0; end
    end
    
    always @(posedge clk)
    begin
        if(en)
         begin
               if(w_en)
                begin
                    case (op)
                    `DM_OP_SB,`DM_OP_UB : 
                    begin
                        case(addr[1:0])
                            0: mem[effAddr] <= {mem[effAddr][31:8],data_in[7:0]};
                            1: mem[effAddr] <= {mem[effAddr][31:16],data_in[7:0],mem[effAddr][7:0]};
                            2: mem[effAddr] <= {mem[effAddr][31:24],data_in[7:0],mem[effAddr][15:0]};
                            3: mem[effAddr] <= {data_in[7:0],mem[effAddr][23:0]};
                        endcase
                    end
                    `DM_OP_SH, `DM_OP_UH : 
                    begin
                        case(addr[1])
                            0: mem[effAddr] <= {mem[effAddr][31:16],data_in[15:0]};
                            1: mem[effAddr] <= {data_in[15:0],mem[effAddr][15:0]};
                        endcase
                    end
                    `DM_OP_WD : mem[effAddr] <= data_in;
                endcase
                end
            end
        end
endmodule