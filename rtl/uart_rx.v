`timescale 1ns / 1ps

/******************************************************************************
* Module Name  : uart_rx
* Author       : bigsmart250
* Version      : v2.0.0
* Description  : UART 接收模块，输出单周期 AXI-Stream valid 脉冲。
******************************************************************************/
module uart_rx #(
        parameter integer CLK_FREQ   = 50_000_000,
        parameter integer UART_BPS   = 115200,
        parameter integer DATA_BIT   = 8,
        parameter integer PARITY_BIT = 0, // 0=无校验，1=奇校验，2=偶校验
        parameter integer STOP_BIT   = 1
    )(
        input   wire                    clk          , // 系统时钟
        input   wire                    rst_n        , // 复位信号，低有效
        output  reg                     m_axi_tvalid , // 接收数据有效，单周期脉冲
        output  reg  [DATA_BIT-1:0]     m_axi_tdata  , // 接收数据
        output  wire                    s_axi_tready , // 接收空闲标志
        output  reg                     start_error  , // 起始位错误
        output  reg                     parity_error , // 校验错误
        output  reg                     stop_error   , // 停止位错误
        input   wire                    uart_rxd       // UART RX 引脚
    );

    localparam integer SAFE_DATA_BIT = (DATA_BIT < 1) ? 1 : DATA_BIT;
    localparam integer BAUD_DIV      = (CLK_FREQ / UART_BPS < 1) ? 1 : (CLK_FREQ / UART_BPS);
    localparam integer HALF_DIV      = (BAUD_DIV < 2) ? 1 : (BAUD_DIV >> 1);
    localparam integer BAUD_WIDTH    = (BAUD_DIV <= 1) ? 1 : $clog2(BAUD_DIV);
    localparam integer BIT_WIDTH     = $clog2(SAFE_DATA_BIT + 4);

    localparam [2:0] ST_IDLE   = 3'd0;
    localparam [2:0] ST_START  = 3'd1;
    localparam [2:0] ST_DATA   = 3'd2;
    localparam [2:0] ST_PARITY = 3'd3;
    localparam [2:0] ST_STOP   = 3'd4;

    reg [2:0]                 state;
    reg [2:0]                 uart_rxd_d;
    reg [BAUD_WIDTH-1:0]      baud_cnt;
    reg [BIT_WIDTH-1:0]       bit_cnt;
    reg [SAFE_DATA_BIT-1:0]   rx_data_r;
    reg [1:0]                 stop_cnt;

    wire rxd_sync;
    wire sample_tick;
    wire baud_tick;
    wire use_parity;
    wire parity_expect;

    assign rxd_sync      = uart_rxd_d[2];
    assign sample_tick   = (baud_cnt >= HALF_DIV - 1);
    assign baud_tick     = (baud_cnt >= BAUD_DIV - 1);
    assign use_parity    = (PARITY_BIT != 0);
    assign parity_expect = (PARITY_BIT == 1) ? ~(^rx_data_r) : (^rx_data_r);
    assign s_axi_tready  = (state == ST_IDLE);

    initial begin : p_param_check
        if(CLK_FREQ < UART_BPS) begin
            $error("%m: CLK_FREQ must be >= UART_BPS");
            $finish;
        end
        if(DATA_BIT < 1) begin
            $error("%m: DATA_BIT must be >= 1");
            $finish;
        end
        if((PARITY_BIT < 0) || (PARITY_BIT > 2)) begin
            $error("%m: PARITY_BIT must be 0, 1, or 2");
            $finish;
        end
        if((STOP_BIT != 1) && (STOP_BIT != 2)) begin
            $error("%m: STOP_BIT must be 1 or 2");
            $finish;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            uart_rxd_d <= 3'b111;
        else
            uart_rxd_d <= {uart_rxd_d[1:0], uart_rxd};
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state        <= ST_IDLE;
            baud_cnt     <= {BAUD_WIDTH{1'b0}};
            bit_cnt      <= {BIT_WIDTH{1'b0}};
            rx_data_r    <= {SAFE_DATA_BIT{1'b0}};
            m_axi_tvalid <= 1'b0;
            m_axi_tdata  <= {SAFE_DATA_BIT{1'b0}};
            start_error  <= 1'b0;
            parity_error <= 1'b0;
            stop_error   <= 1'b0;
            stop_cnt     <= 2'd0;
        end
        else begin
            m_axi_tvalid <= 1'b0;

            case(state)
                ST_IDLE: begin
                    baud_cnt     <= {BAUD_WIDTH{1'b0}};
                    bit_cnt      <= {BIT_WIDTH{1'b0}};
                    stop_cnt     <= 2'd0;
                    start_error  <= 1'b0;
                    parity_error <= 1'b0;
                    stop_error   <= 1'b0;
                    if(!rxd_sync)
                        state <= ST_START;
                end

                ST_START: begin
                    if(sample_tick) begin
                        if(rxd_sync) begin
                            start_error <= 1'b1;
                            state       <= ST_IDLE;
                        end
                        else begin
                            state    <= ST_DATA;
                            baud_cnt <= {BAUD_WIDTH{1'b0}};
                        end
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                ST_DATA: begin
                    if(sample_tick)
                        rx_data_r[bit_cnt] <= rxd_sync;
                    if(baud_tick) begin
                        baud_cnt <= {BAUD_WIDTH{1'b0}};
                        if(bit_cnt >= SAFE_DATA_BIT - 1) begin
                            bit_cnt <= {BIT_WIDTH{1'b0}};
                            state   <= use_parity ? ST_PARITY : ST_STOP;
                        end
                        else begin
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                ST_PARITY: begin
                    if(sample_tick && (rxd_sync != parity_expect))
                        parity_error <= 1'b1;
                    if(baud_tick) begin
                        baud_cnt <= {BAUD_WIDTH{1'b0}};
                        state    <= ST_STOP;
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                ST_STOP: begin
                    if(sample_tick && !rxd_sync)
                        stop_error <= 1'b1;
                    if(baud_tick) begin
                        baud_cnt <= {BAUD_WIDTH{1'b0}};
                        if(stop_cnt >= STOP_BIT - 1) begin
                            state        <= ST_IDLE;
                            m_axi_tvalid <= ~(start_error | parity_error | stop_error | !rxd_sync);
                            m_axi_tdata  <= rx_data_r;
                        end
                        else begin
                            stop_cnt <= stop_cnt + 1'b1;
                        end
                    end
                    else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
