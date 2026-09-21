`timescale 1ns / 1ps

module tb_freq_divider();

    reg clk;
    reg rst_n;
    reg clk_en;

    wire div_clk;
    wire clk_valid;

    integer err_cnt;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    freq_divider #(
        .DIV_COEF ( 4    ),
        .POLARITY ( 1'b1 )
    ) u_freq_divider (
        .clk       ( clk       ),
        .rst_n     ( rst_n     ),
        .clk_en    ( clk_en    ),
        .div_clk   ( div_clk   ),
        .clk_valid ( clk_valid )
    );

    task tick_check;
        input exp_clk;
        input exp_valid;
        begin
            @(posedge clk);
            #1;
            if({div_clk, clk_valid} !== {exp_clk, exp_valid}) begin
                $error("freq_divider mismatch at %0t: got %b%b expected %b%b", $time, div_clk, clk_valid, exp_clk, exp_valid);
                err_cnt = err_cnt + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("prj/icarus/tb_freq_divider.vcd");
        $dumpvars(0, tb_freq_divider);

        err_cnt = 0;
        rst_n   = 1'b0;
        clk_en  = 1'b0;
        tick_check(0, 0);
        tick_check(0, 0);

        rst_n  = 1'b1;
        clk_en = 1'b1;
        tick_check(1, 1);
        tick_check(1, 1);
        tick_check(0, 1);
        tick_check(0, 1);
        tick_check(1, 1);

        clk_en = 1'b0;
        tick_check(0, 0);

        if(err_cnt == 0)
            $display("PASS: freq_divider self-check passed.");
        else
            $fatal(1, "FAIL: freq_divider self-check failed, err_cnt = %0d", err_cnt);

        $finish;
    end

endmodule
