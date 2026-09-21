`timescale 1ns / 1ps

module tb_edge_detection();

    reg clk;
    reg rst_n;
    reg sig;

    wire [2:0] edge_comb2;
    wire [2:0] edge_reg2;
    wire [2:0] edge_comb3;
    wire [2:0] edge_reg3;

    integer err_cnt;

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    edge_detection #(.SYNC_STAGES(2), .OUTPUT_REG(0)) u_comb2 (
        .clk(clk), .rst_n(rst_n), .sig(sig),
        .pos_edge(edge_comb2[2]), .neg_edge(edge_comb2[1]), .both_edge(edge_comb2[0])
    );

    edge_detection #(.SYNC_STAGES(2), .OUTPUT_REG(1)) u_reg2 (
        .clk(clk), .rst_n(rst_n), .sig(sig),
        .pos_edge(edge_reg2[2]), .neg_edge(edge_reg2[1]), .both_edge(edge_reg2[0])
    );

    edge_detection #(.SYNC_STAGES(3), .OUTPUT_REG(0)) u_comb3 (
        .clk(clk), .rst_n(rst_n), .sig(sig),
        .pos_edge(edge_comb3[2]), .neg_edge(edge_comb3[1]), .both_edge(edge_comb3[0])
    );

    edge_detection #(.SYNC_STAGES(3), .OUTPUT_REG(1)) u_reg3 (
        .clk(clk), .rst_n(rst_n), .sig(sig),
        .pos_edge(edge_reg3[2]), .neg_edge(edge_reg3[1]), .both_edge(edge_reg3[0])
    );

    task tick_check;
        input [11:0] exp_edges;
        reg   [11:0] got_edges;
        begin
            @(posedge clk);
            #1;
            got_edges = {edge_comb2, edge_reg2, edge_comb3, edge_reg3};
            if(got_edges !== exp_edges) begin
                $error("edge mismatch at %0t: got %b expected %b", $time, got_edges, exp_edges);
                err_cnt = err_cnt + 1;
            end
        end
    endtask

    task drive_sig;
        input value;
        begin
            @(negedge clk);
            sig = value;
        end
    endtask

    initial begin
        $dumpfile("prj/icarus/tb_edge_detection.vcd");
        $dumpvars(0, tb_edge_detection);

        err_cnt = 0;
        rst_n   = 1'b0;
        sig     = 1'b0;

        repeat(3) tick_check({3'b000, 3'b000, 3'b000, 3'b000});
        rst_n = 1'b1;
        tick_check({3'b000, 3'b000, 3'b000, 3'b000});
        tick_check({3'b000, 3'b000, 3'b000, 3'b000});

        drive_sig(1'b1);
        tick_check({3'b101, 3'b000, 3'b000, 3'b000});
        tick_check({3'b000, 3'b101, 3'b101, 3'b000});
        tick_check({3'b000, 3'b000, 3'b000, 3'b101});
        tick_check({3'b000, 3'b000, 3'b000, 3'b000});

        drive_sig(1'b0);
        tick_check({3'b011, 3'b000, 3'b000, 3'b000});
        tick_check({3'b000, 3'b011, 3'b011, 3'b000});
        tick_check({3'b000, 3'b000, 3'b000, 3'b011});
        tick_check({3'b000, 3'b000, 3'b000, 3'b000});

        if(err_cnt == 0)
            $display("PASS: edge_detection self-check passed.");
        else
            $fatal(1, "FAIL: edge_detection self-check failed, err_cnt = %0d", err_cnt);

        $finish;
    end

endmodule
