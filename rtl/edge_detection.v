`timescale 1ns / 1ps

/******************************************************************************
* Module Name  : edge_detection
* Author       : bigsmart250
* Version      : v1.4.0
* Create Date  : 2025-12-20
* Description  : 异步单比特信号同步与边沿检测模块，输出上升沿、下降沿、
*                双边沿脉冲。
******************************************************************************/
module edge_detection#(
        parameter integer SYNC_STAGES = 2, // 同步打拍级数，常用 2 或 3
        parameter integer OUTPUT_REG  = 1  // 1=寄存输出，0=组合输出
    )(
        input   wire    clk       , // 时钟信号
        input   wire    rst_n     , // 复位信号，低有效
        input   wire    sig       , // 输入异步信号
        output  wire    pos_edge  , // 上升沿检测结果，单周期脉冲
        output  wire    neg_edge  , // 下降沿检测结果，单周期脉冲
        output  wire    both_edge   // 双沿检测结果，单周期脉冲
    );

    localparam integer STAGES = (SYNC_STAGES < 2) ? 2 : SYNC_STAGES;

    initial begin : p_param_check
        if(SYNC_STAGES < 2) begin
            $error("%m: SYNC_STAGES must be >= 2, current value is %0d", SYNC_STAGES);
            $finish;
        end
        if((OUTPUT_REG != 0) && (OUTPUT_REG != 1)) begin
            $error("%m: OUTPUT_REG must be 0 or 1, current value is %0d", OUTPUT_REG);
            $finish;
        end
    end

    reg [STAGES-1:0] sync_pipe;

    wire sig_now;
    wire sig_prev;
    wire pos_edge_next;
    wire neg_edge_next;
    wire both_edge_next;

    assign sig_now        = sync_pipe[STAGES-2];
    assign sig_prev       = sync_pipe[STAGES-1];
    assign pos_edge_next  = ~sig_prev &  sig_now;
    assign neg_edge_next  =  sig_prev & ~sig_now;
    assign both_edge_next =  sig_prev ^  sig_now;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            sync_pipe <= {STAGES{1'b0}};
        else
            sync_pipe <= {sync_pipe[STAGES-2:0], sig};
    end

    generate
        if(OUTPUT_REG) begin : gen_output_reg
            reg pos_edge_r;
            reg neg_edge_r;
            reg both_edge_r;

            assign pos_edge  = pos_edge_r;
            assign neg_edge  = neg_edge_r;
            assign both_edge = both_edge_r;

            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    pos_edge_r  <= 1'b0;
                    neg_edge_r  <= 1'b0;
                    both_edge_r <= 1'b0;
                end
                else begin
                    pos_edge_r  <= pos_edge_next;
                    neg_edge_r  <= neg_edge_next;
                    both_edge_r <= both_edge_next;
                end
            end
        end
        else begin : gen_output_comb
            assign pos_edge  = pos_edge_next;
            assign neg_edge  = neg_edge_next;
            assign both_edge = both_edge_next;
        end
    endgenerate

endmodule
