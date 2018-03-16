module SynDataCollisionDetector(clk, rst, en,
                                regfile_req_a, regfile_req_b, regfile_req_w, 
                                ex_collision_a, dm_collision_a,
                                ex_collision_b, dm_collision_b);
    input clk, rst, en;
    input[4:0] regfile_req_a, regfile_req_b, regfile_req_w;
    output ex_collision_a, dm_collision_a, ex_collision_b, dm_collision_b;
    reg[4:0] ex_regfile_req_w, dm_regfile_req_w;

    assign ex_collision_a = (regfile_req_a == ex_regfile_req_w);
    assign dm_collision_a = (regfile_req_a == dm_regfile_req_w);
    assign ex_collision_b = (regfile_req_b == ex_regfile_req_w);
    assign dm_collision_b = (regfile_req_b == dm_regfile_req_w);
    always @(posedge clk, negedge rst) begin
        if (!rst) begin
            ex_regfile_req_w <= 0;
            dm_regfile_req_w <= 0;
        end
        else if (!en) begin
            ex_regfile_req_w <= ex_regfile_req_w;
            dm_regfile_req_w <= dm_regfile_req_w;
        end
        else begin
            ex_regfile_req_w <= regfile_req_w;
            dm_regfile_req_w <= ex_regfile_req_w;
        end
    end
endmodule