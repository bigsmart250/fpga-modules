`timescale 1ns / 1ps

/******************************************************************************
* Module Name  : freq_divider
* Author       : bigsmart250
* Version      : v2.0.0
* Description  : 整数时钟分频模块，输出分频时钟和有效标志。
******************************************************************************/
module freq_divider#(
        parameter integer DIV_COEF = 2,
        parameter [0:0]   POLARITY = 1'b1
    )(
        input   wire    clk       , // 输入时钟
        input   wire    rst_n     , // 复位信号，低有效
        input   wire    clk_en    , // 分频使能
        output  wire    div_clk   , // 分频时钟输出
        output  wire    clk_valid   // 输出有效标志
    );

    localparam integer SAFE_DIV_COEF = (DIV_COEF < 1) ? 1 : DIV_COEF;
    localparam integer CNT_WIDTH     = (SAFE_DIV_COEF <= 1) ? 1 : $clog2(SAFE_DIV_COEF);

    reg [CNT_WIDTH-1:0] cnt;
    reg                 div_clk_r;

    initial begin : p_param_check
        if(DIV_COEF < 1) begin
            $error("%m: DIV_COEF must be >= 1, current value is %0d", DIV_COEF);
            $finish;
        end
    end

    assign div_clk   = (SAFE_DIV_COEF == 1) ? (clk_en ? clk : !POLARITY) : div_clk_r;
    assign clk_valid = clk_en & rst_n;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cnt       <= {CNT_WIDTH{1'b0}};
            div_clk_r <= !POLARITY;
        end
        else if(!clk_en) begin
            cnt       <= {CNT_WIDTH{1'b0}};
            div_clk_r <= !POLARITY;
        end
        else if(SAFE_DIV_COEF == 1) begin
            cnt       <= {CNT_WIDTH{1'b0}};
            div_clk_r <= POLARITY;
        end
        else begin
            if(cnt >= SAFE_DIV_COEF - 1) begin
                cnt <= {CNT_WIDTH{1'b0}};
            end
            else begin
                cnt <= cnt + 1'b1;
            end

            if(cnt < (SAFE_DIV_COEF >> 1)) begin
                div_clk_r <= POLARITY;
            end
            else begin
                div_clk_r <= !POLARITY;
            end
        end
    end

endmodule
