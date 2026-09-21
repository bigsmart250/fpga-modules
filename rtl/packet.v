`timescale 1ns / 1ps

/******************************************************************************
* Module Name  : packet
* Description  : 简单包 ROM 发送模块，输入包号后按 AXI-Stream 输出该包内容。
******************************************************************************/
module packet#(
        parameter integer DATA_WIDTH  = 8,
        parameter integer PACKET_NUM  = 4,
        parameter integer PACKET_SIZE = 4,
        parameter integer PNUM_WIDTH  = (PACKET_NUM <= 1) ? 1 : $clog2(PACKET_NUM)
    )(
        input   wire                        s_axi_aclk    ,
        input   wire                        s_axi_aresetn ,
        input   wire                        s_axi_tvalid  ,
        input   wire [PNUM_WIDTH-1:0]       s_axi_tdata   ,
        output  wire                        s_axi_tready  ,
        output  wire                        m_axi_tvalid  ,
        output  wire [DATA_WIDTH-1:0]       m_axi_tdata   ,
        input   wire                        m_axi_tready
    );

    localparam integer SAFE_PACKET_NUM  = (PACKET_NUM  < 1) ? 1 : PACKET_NUM;
    localparam integer SAFE_PACKET_SIZE = (PACKET_SIZE < 1) ? 1 : PACKET_SIZE;
    localparam integer PSIZE_WIDTH      = (SAFE_PACKET_SIZE <= 1) ? 1 : $clog2(SAFE_PACKET_SIZE + 1);

    localparam [1:0] ST_IDLE = 2'd0;
    localparam [1:0] ST_SEND = 2'd1;

    reg [1:0] state;
    reg [PNUM_WIDTH-1:0] packet_num;
    reg [PSIZE_WIDTH-1:0] packet_cnt;

    wire send_fire;

    assign s_axi_tready = (state == ST_IDLE);
    assign m_axi_tvalid = (state == ST_SEND);
    assign m_axi_tdata  = packet_num * SAFE_PACKET_SIZE + packet_cnt;
    assign send_fire    = m_axi_tvalid & m_axi_tready;

    initial begin : p_param_check
        if(DATA_WIDTH < 1 || PACKET_NUM < 1 || PACKET_SIZE < 1) begin
            $error("%m: DATA_WIDTH/PACKET_NUM/PACKET_SIZE must be >= 1");
            $finish;
        end
        if(PNUM_WIDTH < 1) begin
            $error("%m: PNUM_WIDTH must be >= 1");
            $finish;
        end
    end

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if(!s_axi_aresetn) begin
            state      <= ST_IDLE;
            packet_num <= {PNUM_WIDTH{1'b0}};
            packet_cnt <= {PSIZE_WIDTH{1'b0}};
        end
        else begin
            case(state)
                ST_IDLE: begin
                    packet_cnt <= {PSIZE_WIDTH{1'b0}};
                    if(s_axi_tvalid) begin
                        packet_num <= s_axi_tdata;
                        state      <= ST_SEND;
                    end
                end

                ST_SEND: begin
                    if(send_fire) begin
                        if(packet_cnt >= SAFE_PACKET_SIZE - 1) begin
                            state      <= ST_IDLE;
                            packet_cnt <= {PSIZE_WIDTH{1'b0}};
                        end
                        else begin
                            packet_cnt <= packet_cnt + 1'b1;
                        end
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
