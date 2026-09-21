`timescale 1ns / 1ps

/******************************************************************************
* Module Name  : uart_tx
* Author       : Bigsmart
* Version      : v3.0.0
* Description  : UART 发送模块，AXI-Stream 风格输入，LSB first。
******************************************************************************/
module uart_tx #(
        parameter integer CLK_FREQ   = 50_000_000,
        parameter integer UART_BPS   = 115_200,
        parameter integer DATA_WIDTH = 8
    )(
        input   wire                    s_axi_aclk   , // 系统时钟
        input   wire                    s_axi_aresetn, // 复位信号，低有效
        input   wire                    s_axi_tvalid , // 输入数据有效
        input   wire [DATA_WIDTH-1:0]   s_axi_tdata  , // 输入并行数据
        output  wire                    s_axi_tready , // 空闲可接收
        output  wire                    uart_txd       // UART 串行输出
    );

    localparam integer SAFE_BAUD_DIV = (CLK_FREQ / UART_BPS < 2) ? 2 : (CLK_FREQ / UART_BPS);
    localparam integer BAUD_WIDTH    = $clog2(SAFE_BAUD_DIV);
    localparam integer FRAME_BITS    = DATA_WIDTH + 2;
    localparam integer FRAME_WIDTH   = DATA_WIDTH + 2;
    localparam integer BIT_WIDTH     = $clog2(FRAME_BITS + 1);

    reg [BAUD_WIDTH-1:0]  baud_cnt;
    reg [BIT_WIDTH-1:0]   bit_cnt;
    reg [FRAME_WIDTH-1:0] shifter;
    reg                   busy;

    wire handshake;

    assign handshake    = s_axi_tvalid & s_axi_tready;
    assign s_axi_tready = ~busy;
    assign uart_txd     = busy ? shifter[0] : 1'b1;

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
        if(!s_axi_aresetn) begin
            baud_cnt <= {BAUD_WIDTH{1'b0}};
            bit_cnt  <= {BIT_WIDTH{1'b0}};
            shifter  <= {FRAME_WIDTH{1'b1}};
            busy     <= 1'b0;
        end
        else if(handshake) begin
            baud_cnt <= {BAUD_WIDTH{1'b0}};
            bit_cnt  <= {{(BIT_WIDTH-1){1'b0}}, 1'b1};
            shifter  <= {1'b1, s_axi_tdata, 1'b0};
            busy     <= 1'b1;
        end
        else if(busy) begin
            if(baud_cnt >= SAFE_BAUD_DIV - 1) begin
                baud_cnt <= {BAUD_WIDTH{1'b0}};
                shifter  <= {1'b1, shifter[FRAME_WIDTH-1:1]};
                if(bit_cnt >= FRAME_BITS) begin
                    bit_cnt <= {BIT_WIDTH{1'b0}};
                    busy    <= 1'b0;
                end
                else begin
                    bit_cnt <= bit_cnt + 1'b1;
                end
            end
            else begin
                baud_cnt <= baud_cnt + 1'b1;
            end
        end
    end

endmodule
