`timescale 1ns / 1ps

/******************************************************************************
* Module Name  : ring_buffer
* Author       : Bigsmart
* Version      : v3.0.0
* Description  : AXI-Stream 风格同步 FIFO，支持同拍读写。
******************************************************************************/
module ring_buffer#(
        parameter integer DATA_WIDTH = 8,
        parameter integer DATA_DEPTH = 16,
        parameter integer ADDR_WIDTH = $clog2((DATA_DEPTH < 2) ? 2 : DATA_DEPTH) // 由 DATA_DEPTH 推导，一般无需手动指定
    )(
        input   wire                        s_axi_aclk    ,
        input   wire                        s_axi_aresetn ,
        input   wire                        s_axi_tvalid  ,
        input   wire [DATA_WIDTH-1:0]       s_axi_tdata   ,
        output  wire                        s_axi_tready  ,
        output  wire                        m_axi_tvalid  ,
        output  wire [DATA_WIDTH-1:0]       m_axi_tdata   ,
        input   wire                        m_axi_tready  ,
        output  wire [ADDR_WIDTH-1:0]       w_addr        ,
        output  wire [ADDR_WIDTH-1:0]       r_addr        ,
        output  wire                        full          ,
        output  wire                        empty
    );

    localparam integer SAFE_DEPTH  = (DATA_DEPTH < 2) ? 2 : DATA_DEPTH;
    localparam integer COUNT_WIDTH = $clog2(SAFE_DEPTH + 1);

    reg [DATA_WIDTH-1:0] buffer [0:SAFE_DEPTH-1];
    reg [ADDR_WIDTH-1:0] w_ptr;
    reg [ADDR_WIDTH-1:0] r_ptr;
    reg [COUNT_WIDTH-1:0] data_cnt;

    wire write_fire;
    wire read_fire;

    assign full         = (data_cnt == SAFE_DEPTH);
    assign empty        = (data_cnt == 0);
    assign s_axi_tready = ~full | read_fire;
    assign m_axi_tvalid = ~empty;
    assign m_axi_tdata  = buffer[r_ptr];
    assign w_addr       = w_ptr;
    assign r_addr       = r_ptr;
    assign write_fire   = s_axi_tvalid & s_axi_tready;
    assign read_fire    = m_axi_tvalid & m_axi_tready;

    initial begin : p_param_check
        if(DATA_WIDTH < 1) begin
            $error("%m: DATA_WIDTH must be >= 1");
            $finish;
        end
        if(DATA_DEPTH < 2) begin
            $error("%m: DATA_DEPTH must be >= 2");
            $finish;
        end
        if(ADDR_WIDTH < $clog2(SAFE_DEPTH)) begin
            $error("%m: ADDR_WIDTH too small for DATA_DEPTH");
            $finish;
        end
    end

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if(!s_axi_aresetn) begin
            w_ptr    <= {ADDR_WIDTH{1'b0}};
            r_ptr    <= {ADDR_WIDTH{1'b0}};
            data_cnt <= {COUNT_WIDTH{1'b0}};
        end
        else begin
            if(write_fire) begin
                buffer[w_ptr] <= s_axi_tdata;
                w_ptr <= (w_ptr == SAFE_DEPTH - 1) ? {ADDR_WIDTH{1'b0}} : w_ptr + 1'b1;
            end

            if(read_fire) begin
                r_ptr <= (r_ptr == SAFE_DEPTH - 1) ? {ADDR_WIDTH{1'b0}} : r_ptr + 1'b1;
            end

            case({write_fire, read_fire})
                2'b10: data_cnt <= data_cnt + 1'b1;
                2'b01: data_cnt <= data_cnt - 1'b1;
                default: data_cnt <= data_cnt;
            endcase
        end
    end

endmodule
