`timescale 1ns / 1ps

module tb_any_freq_divider();

    reg clk;
    reg rst_n;
    reg clk_en;

    wire div_clk;
    wire clk_valid;

    integer err_cnt;
    integer valid_cnt;
    integer cycle_cnt;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    any_freq_divider #(
        .DIVIDEND ( 8 ),
        .DIVISOR  ( 3 )
    ) u_any_freq_divider (
        .clk       ( clk       ),
        .rst_n     ( rst_n     ),
        .clk_en    ( clk_en    ),
        .div_clk   ( div_clk   ),
        .clk_valid ( clk_valid )
    );

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        $dumpfile("prj/icarus/tb_any_freq_divider.vcd");
        $dumpvars(0, tb_any_freq_divider);

        err_cnt   = 0;
        valid_cnt = 0;
        rst_n     = 1'b0;
        clk_en    = 1'b0;
        tick();
        tick();

        rst_n  = 1'b1;
        clk_en = 1'b1;
        for(cycle_cnt = 0; cycle_cnt < 32; cycle_cnt = cycle_cnt + 1) begin
            tick();
            if(clk_valid)
                valid_cnt = valid_cnt + 1;
        end

        if(valid_cnt !== 12) begin
            $error("any_freq_divider valid count mismatch: got %0d expected 12", valid_cnt);
            err_cnt = err_cnt + 1;
        end

        clk_en = 1'b0;
        tick();
        if(clk_valid !== 1'b0 || div_clk !== 1'b0) begin
            $error("any_freq_divider disable reset mismatch");
            err_cnt = err_cnt + 1;
        end

        if(err_cnt == 0)
            $display("PASS: any_freq_divider self-check passed.");
        else
            $fatal(1, "FAIL: any_freq_divider self-check failed, err_cnt = %0d", err_cnt);

        $finish;
    end

endmodule
