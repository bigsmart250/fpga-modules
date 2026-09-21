`timescale 1ns / 1ps

module top_buffer(
        input   sys_clk  ,
        input   sys_rst_n,
        input   uart_rxd ,
        output  uart_txd
    );

    parameter DATA_WIDTH = 8                 ;
    parameter DATA_DEPTH = 4                 ;
    parameter ADDR_WIDTH = $clog2(DATA_DEPTH);
    // outports wire
    wire                  	m_rx_tvalid;
    wire [DATA_WIDTH-1:0] 	m_rx_tdata ;

    // outports wire
    wire                  	s_rbuf_tready;
    wire                  	m_rbuf_tvalid;
    wire [DATA_WIDTH-1:0] 	m_rbuf_tdata;
    wire [ADDR_WIDTH-1:0] 	rbuf_w_addr;
    wire [ADDR_WIDTH-1:0] 	rbuf_r_addr;
    wire                  	rbuf_full  ;
    wire                  	rbuf_empty ;

    // outports wire
    wire                  	s_tx_tready;

    uart_rx #(
                .CLK_FREQ   	( 50000000     ),
                .UART_BPS   	( 115200       ),
                .DATA_WIDTH 	( DATA_WIDTH   ))
            u_uart_rx(
                .s_axi_aclk    	( sys_clk        ),
                .s_axi_aresetn 	( sys_rst_n      ),
                .m_axi_tvalid  	( m_rx_tvalid    ),
                .m_axi_tdata   	( m_rx_tdata     ),
                .uart_rxd      	( uart_rxd       )
            );

    ring_buffer #(
                    .DATA_WIDTH 	( DATA_WIDTH ),
                    .DATA_DEPTH 	( DATA_DEPTH ))
                u_ring_buffer(
                    .s_axi_aclk    	( sys_clk        ),
                    .s_axi_aresetn 	( sys_rst_n      ),
                    .s_axi_tvalid  	( m_rx_tvalid    ),
                    .s_axi_tdata   	( m_rx_tdata     ),
                    .s_axi_tready  	( s_rbuf_tready  ),
                    .m_axi_tvalid  	( m_rbuf_tvalid  ),
                    .m_axi_tdata   	( m_rbuf_tdata   ),
                    .m_axi_tready  	( s_tx_tready    ),
                    .w_addr        	( rbuf_w_addr    ),
                    .r_addr        	( rbuf_r_addr    ),
                    .full          	( rbuf_full      ),
                    .empty         	( rbuf_empty     )
                );

    uart_tx #(
                .CLK_FREQ   	( 50000000   ),
                .UART_BPS   	( 115200     ),
                .DATA_WIDTH 	( DATA_WIDTH ))
            u_uart_tx(
                .s_axi_aclk    	( sys_clk        ),
                .s_axi_aresetn 	( sys_rst_n      ),
                .s_axi_tvalid  	( m_rbuf_tvalid  ),
                .s_axi_tdata   	( m_rbuf_tdata   ),
                .s_axi_tready  	( s_tx_tready    ),
                .uart_txd      	( uart_txd       )
            );

endmodule
