`timescale 1ns / 1ps

/******************************************************************************
* Module Name  : any_freq_divider
* Author       : bigsmart250
* Version      : v2.0.0
* Description  : 基于相位累加器的任意比例时钟使能发生器。
* Notes        : 平均每 DIVIDEND 个输入使能周期产生 DIVISOR 个 clk_valid 脉冲。
******************************************************************************/
module any_freq_divider#(
        parameter integer DIVIDEND = 10,
        parameter integer DIVISOR  = 1
    )(
        input   wire    clk       , // 输入时钟
        input   wire    rst_n     , // 复位信号，低有效
        input   wire    clk_en    , // 输入使能
        output  reg     div_clk   , // 每次 clk_valid 翻转一次
        output  reg     clk_valid   // 单周期输出有效脉冲
    );

    localparam integer SAFE_DIVIDEND = (DIVIDEND < 1) ? 1 : DIVIDEND;
    localparam integer SAFE_DIVISOR  = (DIVISOR  < 1) ? 1 : DIVISOR;
    localparam integer ACC_WIDTH     = $clog2(SAFE_DIVIDEND + SAFE_DIVISOR + 1);

    reg [ACC_WIDTH-1:0] acc;
    reg [ACC_WIDTH-1:0] acc_next;

    initial begin : p_param_check
        if(DIVIDEND < 1) begin
            $error("%m: DIVIDEND must be >= 1, current value is %0d", DIVIDEND);
            $finish;
        end
        if(DIVISOR < 1) begin
            $error("%m: DIVISOR must be >= 1, current value is %0d", DIVISOR);
            $finish;
        end
        if(DIVISOR > DIVIDEND) begin
            $error("%m: DIVISOR must be <= DIVIDEND, current DIVISOR=%0d DIVIDEND=%0d", DIVISOR, DIVIDEND);
            $finish;
        end
    end

    always @(*) begin
        acc_next = acc + SAFE_DIVISOR[ACC_WIDTH-1:0];
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            acc       <= {ACC_WIDTH{1'b0}};
            div_clk   <= 1'b0;
            clk_valid <= 1'b0;
        end
        else if(!clk_en) begin
            acc       <= {ACC_WIDTH{1'b0}};
            div_clk   <= 1'b0;
            clk_valid <= 1'b0;
        end
        else if(acc_next >= SAFE_DIVIDEND[ACC_WIDTH-1:0]) begin
            acc       <= acc_next - SAFE_DIVIDEND[ACC_WIDTH-1:0];
            div_clk   <= ~div_clk;
            clk_valid <= 1'b1;
        end
        else begin
            acc       <= acc_next;
            clk_valid <= 1'b0;
        end
    end

endmodule
