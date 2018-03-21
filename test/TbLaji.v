`timescale 1ns / 1ps

`include "Test.vh"

module TbLaji();
    reg clk = 1'b1;
    always #5 clk <= !clk;
    reg rst_n = 1'b0;
    reg resume = 1'b0;
    reg [15:0] swt = 16'b11;
    reg int1 = 0;
    reg int2 = 0;
    reg int3 = 0;
    wire [7:0] seg_n;
    wire [7:0] an_n;
    initial begin
        `cp(1) rst_n = 1'b1;
        #1000 int1 = 1;
        `cp(10) int1 = 0;
        #1000 int2 = 1;
        `cp(10) int2 = 0;
        #1000 int3 = 1;
        `cp(10) int3 = 0;
    end
    TopLajiIntelKnightsLanding vDUT(
        .clk(clk),
        .rst_n(rst_n),
        .resume(resume),
        .swt(swt),
        .seg_n(seg_n),
        .an_n(an_n),
        .int0(int1),
        .int1(int2),
        .int2(int3)
    );
endmodule
