`timescale 1ns / 1ps

module tb_uart_rx();

    localparam integer CLK_FREQ = 1_000_000;
    localparam integer UART_BPS = 100_000;
    localparam integer BAUD_DIV = CLK_FREQ / UART_BPS;

    reg clk;
    reg rst_n;
    reg uart_rxd;

    wire m_axi_tvalid;
    wire [7:0] m_axi_tdata;
    wire s_axi_tready;
    wire start_error;
    wire parity_error;
    wire stop_error;

    reg got_valid;
    reg [7:0] got_data;

    integer err_cnt;
    integer wait_cnt;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    uart_rx #(
        .CLK_FREQ   ( CLK_FREQ ),
        .UART_BPS   ( UART_BPS ),
        .DATA_BIT   ( 8        ),
        .PARITY_BIT ( 0        ),
        .STOP_BIT   ( 1        )
    ) u_uart_rx (
        .clk          ( clk          ),
        .rst_n        ( rst_n        ),
        .m_axi_tvalid ( m_axi_tvalid ),
        .m_axi_tdata  ( m_axi_tdata  ),
        .s_axi_tready ( s_axi_tready ),
        .start_error  ( start_error  ),
        .parity_error ( parity_error ),
        .stop_error   ( stop_error   ),
        .uart_rxd     ( uart_rxd     )
    );

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            got_valid <= 1'b0;
            got_data  <= 8'd0;
        end
        else if(m_axi_tvalid) begin
            got_valid <= 1'b1;
            got_data  <= m_axi_tdata;
        end
    end

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task wait_baud;
        integer i;
        begin
            for(i = 0; i < BAUD_DIV; i = i + 1)
                tick();
        end
    endtask

    task send_byte;
        input [7:0] data;
        integer i;
        begin
            uart_rxd = 1'b0;
            wait_baud();
            for(i = 0; i < 8; i = i + 1) begin
                uart_rxd = data[i];
                wait_baud();
            end
            uart_rxd = 1'b1;
            wait_baud();
        end
    endtask

    initial begin
        $dumpfile("prj/icarus/tb_uart_rx.vcd");
        $dumpvars(0, tb_uart_rx);

        err_cnt  = 0;
        rst_n    = 1'b0;
        uart_rxd = 1'b1;
        repeat(5) tick();

        rst_n = 1'b1;
        repeat(2) tick();
        send_byte(8'h3C);

        wait_cnt = 0;
        while(!got_valid && wait_cnt < 80) begin
            tick();
            wait_cnt = wait_cnt + 1;
        end

        if(got_valid !== 1'b1 || got_data !== 8'h3C) begin
            $error("uart_rx data mismatch: got_valid=%b got_data=%h", got_valid, got_data);
            err_cnt = err_cnt + 1;
        end
        if(start_error || parity_error || stop_error) begin
            $error("uart_rx unexpected error flags start=%b parity=%b stop=%b", start_error, parity_error, stop_error);
            err_cnt = err_cnt + 1;
        end

        if(err_cnt == 0)
            $display("PASS: uart_rx self-check passed.");
        else
            $fatal(1, "FAIL: uart_rx self-check failed, err_cnt = %0d", err_cnt);

        $finish;
    end

endmodule
