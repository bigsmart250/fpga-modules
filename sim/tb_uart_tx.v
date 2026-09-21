`timescale 1ns / 1ps

module tb_uart_tx();

    localparam integer CLK_FREQ = 1_000_000;
    localparam integer UART_BPS = 100_000;
    localparam integer BAUD_DIV = CLK_FREQ / UART_BPS;

    reg clk;
    reg rst_n;
    reg s_axi_tvalid;
    reg [7:0] s_axi_tdata;

    wire s_axi_tready;
    wire uart_txd;

    integer err_cnt;
    integer bit_idx;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    uart_tx #(
        .CLK_FREQ   ( CLK_FREQ ),
        .UART_BPS   ( UART_BPS ),
        .DATA_BIT   ( 8        ),
        .PARITY_BIT ( 0        ),
        .STOP_BIT   ( 1        )
    ) u_uart_tx (
        .clk          ( clk          ),
        .rst_n        ( rst_n        ),
        .s_axi_tvalid ( s_axi_tvalid ),
        .s_axi_tdata  ( s_axi_tdata  ),
        .s_axi_tready ( s_axi_tready ),
        .uart_txd     ( uart_txd     )
    );

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task wait_cycles;
        input integer num;
        integer i;
        begin
            for(i = 0; i < num; i = i + 1)
                tick();
        end
    endtask

    task check_line;
        input exp_value;
        begin
            if(uart_txd !== exp_value) begin
                $error("uart_txd mismatch at %0t: got %b expected %b", $time, uart_txd, exp_value);
                err_cnt = err_cnt + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("prj/icarus/tb_uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);

        err_cnt      = 0;
        rst_n        = 1'b0;
        s_axi_tvalid = 1'b0;
        s_axi_tdata  = 8'hA5;
        repeat(3) tick();

        rst_n = 1'b1;
        tick();
        s_axi_tvalid = 1'b1;
        tick();
        s_axi_tvalid = 1'b0;

        wait_cycles(BAUD_DIV / 2);
        check_line(1'b0);
        wait_cycles(BAUD_DIV);
        for(bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
            check_line(s_axi_tdata[bit_idx]);
            wait_cycles(BAUD_DIV);
        end
        check_line(1'b1);

        if(err_cnt == 0)
            $display("PASS: uart_tx self-check passed.");
        else
            $fatal(1, "FAIL: uart_tx self-check failed, err_cnt = %0d", err_cnt);

        $finish;
    end

endmodule
