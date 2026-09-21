`timescale 1ns / 1ps

/******************************************************************************
* Module Name  : uart_rx
* Author       : Bigsmart
* Version      : v3.0.0
* Description  : UART 接收模块，输出 AXI-Stream 风格单周期 valid。
******************************************************************************/
module uart_rx #(
        parameter integer CLK_FREQ   = 50_000_000,
        parameter integer UART_BPS   = 115_200,
        parameter integer DATA_WIDTH = 8
    )(
        input   wire                        s_axi_aclk   , // 系统时钟
        input   wire                        s_axi_aresetn, // 复位信号，低有效
        output  reg                         m_axi_tvalid , // 接收数据有效，保持 1 个时钟周期
        output  reg  [DATA_WIDTH-1:0]       m_axi_tdata  , // 接收数据
        input   wire                        uart_rxd       // UART 串行输入
    );

    localparam integer SAFE_BAUD_DIV = (CLK_FREQ / UART_BPS < 2) ? 2 : (CLK_FREQ / UART_BPS);
    localparam integer BAUD_WIDTH    = $clog2(SAFE_BAUD_DIV);
    localparam integer BIT_WIDTH     = (DATA_WIDTH <= 1) ? 1 : $clog2(DATA_WIDTH);

    localparam [1:0] ST_IDLE  = 2'd0;
    localparam [1:0] ST_START = 2'd1;
    localparam [1:0] ST_DATA  = 2'd2;
    localparam [1:0] ST_STOP  = 2'd3;

    reg [1:0]                  state;
    reg [BAUD_WIDTH-1:0]       baud_cnt;
    reg [BIT_WIDTH-1:0]        bit_cnt;
    reg [DATA_WIDTH-1:0]       rx_shift;
    reg [2:0]                  rxd_sync;

    wire start_edge;
    wire baud_last;
    wire baud_half;

    assign start_edge = rxd_sync[2] & ~rxd_sync[1];
    assign baud_last  = (baud_cnt >= SAFE_BAUD_DIV - 1);
    assign baud_half  = (baud_cnt >= SAFE_BAUD_DIV / 2 - 1);

    initial begin : p_param_check
        if(CLK_FREQ < UART_BPS * 2) begin
            $error("%m: CLK_FREQ must be at least 2 * UART_BPS");
            $finish;
        end
        if(DATA_WIDTH < 1) begin
            $error("%m: DATA_WIDTH must be >= 1");
            $finish;
        end
    end

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if(!s_axi_aresetn)
            rxd_sync <= 3'b111;
        else
            rxd_sync <= {rxd_sync[1:0], uart_rxd};
    end

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if(!s_axi_aresetn) begin
            state        <= ST_IDLE;
            baud_cnt     <= {BAUD_WIDTH{1'b0}};
            bit_cnt      <= {BIT_WIDTH{1'b0}};
            rx_shift     <= {DATA_WIDTH{1'b0}};
            m_axi_tvalid <= 1'b0;
            m_axi_tdata  <= {DATA_WIDTH{1'b0}};
        end
        else begin
            m_axi_tvalid <= 1'b0;
            case(state)
                ST_IDLE: begin
                    baud_cnt <= {BAUD_WIDTH{1'b0}};
                    bit_cnt  <= {BIT_WIDTH{1'b0}};
                    if(start_edge)
                        state <= ST_START;
                end

                ST_START: begin
                    if(baud_half) begin
                        baud_cnt <= {BAUD_WIDTH{1'b0}};
                        if(rxd_sync[2] == 1'b0)
                            state <= ST_DATA;
                        else
                            state <= ST_IDLE;
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                ST_DATA: begin
                    if(baud_last) begin
                        baud_cnt          <= {BAUD_WIDTH{1'b0}};
                        rx_shift[bit_cnt] <= rxd_sync[2];
                        if(bit_cnt >= DATA_WIDTH - 1) begin
                            bit_cnt <= {BIT_WIDTH{1'b0}};
                            state   <= ST_STOP;
                        end
                        else begin
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                ST_STOP: begin
                    if(baud_last) begin
                        baud_cnt     <= {BAUD_WIDTH{1'b0}};
                        state        <= ST_IDLE;
                        m_axi_tvalid <= 1'b1;
                        m_axi_tdata  <= rx_shift;
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
