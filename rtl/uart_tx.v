`timescale 1ns / 1ps

/******************************************************************************
* Module Name  : uart_tx
* Author       : bigsmart250
* Version      : v2.1.0
* Description  : AXI-Stream 输入 UART 发送模块，LSB first。
******************************************************************************/
module uart_tx #(
        parameter integer CLK_FREQ   = 50_000_000,
        parameter integer UART_BPS   = 115200,
        parameter integer DATA_BIT   = 8,
        parameter integer PARITY_BIT = 0, // 0=无校验，1=奇校验，2=偶校验
        parameter integer STOP_BIT   = 1
    )(
        input   wire                    clk          , // 系统时钟
        input   wire                    rst_n        , // 复位信号，低有效
        input   wire                    s_axi_tvalid , // 输入数据有效
        input   wire [DATA_BIT-1:0]     s_axi_tdata  , // 输入并行数据
        output  wire                    s_axi_tready , // 空闲可接收
        output  wire                    uart_txd       // UART TX 引脚
    );

    localparam integer SAFE_DATA_BIT = (DATA_BIT < 1) ? 1 : DATA_BIT;
    localparam integer BAUD_DIV      = (CLK_FREQ / UART_BPS < 1) ? 1 : (CLK_FREQ / UART_BPS);
    localparam integer BAUD_WIDTH    = (BAUD_DIV <= 1) ? 1 : $clog2(BAUD_DIV);
    localparam integer FRAME_BITS    = 1 + SAFE_DATA_BIT + ((PARITY_BIT == 0) ? 0 : 1) + STOP_BIT;
    localparam integer FRAME_WIDTH   = SAFE_DATA_BIT + 4;
    localparam integer BIT_WIDTH     = $clog2(FRAME_WIDTH + 1);

    reg [BAUD_WIDTH-1:0]    baud_cnt;
    reg [BIT_WIDTH-1:0]     bit_cnt;
    reg [FRAME_WIDTH-1:0]   shifter;
    reg                     busy;

    wire parity_bit;
    wire handshake;

    assign parity_bit   = (PARITY_BIT == 1) ? ~(^s_axi_tdata) : (^s_axi_tdata);
    assign handshake    = s_axi_tvalid & s_axi_tready;
    assign s_axi_tready = ~busy;
    assign uart_txd     = busy ? shifter[0] : 1'b1;

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
        if(!rst_n) begin
            baud_cnt <= {BAUD_WIDTH{1'b0}};
            bit_cnt  <= {BIT_WIDTH{1'b0}};
            shifter  <= {FRAME_WIDTH{1'b1}};
            busy     <= 1'b0;
        end
        else if(handshake) begin
            baud_cnt <= {BAUD_WIDTH{1'b0}};
            bit_cnt  <= {{(BIT_WIDTH-1){1'b0}}, 1'b1};
            busy     <= 1'b1;
            if(PARITY_BIT == 0)
                shifter <= {{(FRAME_WIDTH-SAFE_DATA_BIT-2){1'b1}}, 1'b1, s_axi_tdata, 1'b0};
            else
                shifter <= {{(FRAME_WIDTH-SAFE_DATA_BIT-3){1'b1}}, 1'b1, parity_bit, s_axi_tdata, 1'b0};
        end
        else if(busy) begin
            if(baud_cnt >= BAUD_DIV - 1) begin
                baud_cnt <= {BAUD_WIDTH{1'b0}};
                shifter  <= {1'b1, shifter[FRAME_WIDTH-1:1]};
                if(bit_cnt >= FRAME_BITS) begin
                    busy    <= 1'b0;
                    bit_cnt <= {BIT_WIDTH{1'b0}};
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
