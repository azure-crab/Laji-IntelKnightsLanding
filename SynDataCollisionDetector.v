module SynDataCollisionDetector(clk, rst_n, en, stalled, dm_load,
                                regfile_req_a, regfile_req_b, regfile_req_w,
                                load_use,
                                ex_collision_a, dm_collision_a,
                                ex_collision_b, dm_collision_b);
    input clk, rst_n, en, stalled, dm_load;
    input[4:0] regfile_req_a, regfile_req_b, regfile_req_w;
    output load_use, ex_collision_a, dm_collision_a, ex_collision_b, dm_collision_b;
    reg[4:0] ex_regfile_req_w, dm_regfile_req_w;
    reg dm_load_reg;

    assign ex_collision_a = ex_regfile_req_w != 0 && (regfile_req_a == ex_regfile_req_w);
    assign dm_collision_a = dm_regfile_req_w != 0 && (regfile_req_a == dm_regfile_req_w);
    assign ex_collision_b = ex_regfile_req_w != 0 && (regfile_req_b == ex_regfile_req_w);
    assign dm_collision_b = dm_regfile_req_w != 0 && (regfile_req_b == dm_regfile_req_w);
    assign load_use = (ex_collision_a || ex_collision_b) && dm_load_reg;
    always @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            ex_regfile_req_w <= 0;
            dm_regfile_req_w <= 0;
            dm_load_reg <= 0;
        end
        else if (!en) begin
            ex_regfile_req_w <= ex_regfile_req_w;
            dm_regfile_req_w <= dm_regfile_req_w;
            dm_load_reg <= dm_load_reg;
        end
        else if (stalled) begin
            dm_load_reg <= 0;
            ex_regfile_req_w <= 0;
            dm_regfile_req_w <= ex_regfile_req_w;
        end
        else begin
            dm_load_reg <= dm_load;
            ex_regfile_req_w <= regfile_req_w;
            dm_regfile_req_w <= ex_regfile_req_w;
        end
    end
endmodule