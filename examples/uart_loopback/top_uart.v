`timescale 1ns / 1ps

module top_uart(
        input   wire    sys_clk   ,
        input   wire    sys_rst_n ,
        input   wire    uart_rxd  ,
        output  wire    uart_txd
    );

    wire       rx_tvalid;
    wire [7:0] rx_tdata;
    wire       rx_tready;
    wire       tx_tready;
    wire       start_error;
    wire       parity_error;
    wire       stop_error;

    uart_rx #(
        .CLK_FREQ   ( 50_000_000 ),
        .UART_BPS   ( 115200     ),
        .DATA_BIT   ( 8          ),
        .PARITY_BIT ( 0          ),
        .STOP_BIT   ( 1          )
    ) u_uart_rx (
        .clk          ( sys_clk      ),
        .rst_n        ( sys_rst_n    ),
        .m_axi_tvalid ( rx_tvalid    ),
        .m_axi_tdata  ( rx_tdata     ),
        .s_axi_tready ( rx_tready    ),
        .start_error  ( start_error  ),
        .parity_error ( parity_error ),
        .stop_error   ( stop_error   ),
        .uart_rxd     ( uart_rxd     )
    );

    uart_tx #(
        .CLK_FREQ   ( 50_000_000 ),
        .UART_BPS   ( 115200     ),
        .DATA_BIT   ( 8          ),
        .PARITY_BIT ( 0          ),
        .STOP_BIT   ( 1          )
    ) u_uart_tx (
        .clk          ( sys_clk    ),
        .rst_n        ( sys_rst_n  ),
        .s_axi_tvalid ( rx_tvalid  ),
        .s_axi_tdata  ( rx_tdata   ),
        .s_axi_tready ( tx_tready  ),
        .uart_txd     ( uart_txd   )
    );

endmodule
