`timescale 1ns / 1ps

/******************************************************************************
* Module Name  : tb_packet
* Description  : packet 自检 TB，验证包号选择、连续输出和 ready 反压保持。
******************************************************************************/
module tb_packet();

    localparam integer DATA_WIDTH  = 8;
    localparam integer PACKET_NUM  = 4;
    localparam integer PACKET_SIZE = 5;
    localparam integer PNUM_WIDTH  = 2;

    reg                    clk;
    reg                    rst_n;
    reg                    s_axi_tvalid;
    reg [PNUM_WIDTH-1:0]   s_axi_tdata;
    reg                    m_axi_tready;

    wire                   s_axi_tready;
    wire                   m_axi_tvalid;
    wire [DATA_WIDTH-1:0]  m_axi_tdata;

    integer err_cnt;
    integer idx;
    integer base_data;

    packet #(
        .DATA_WIDTH  ( DATA_WIDTH  ),
        .PACKET_NUM  ( PACKET_NUM  ),
        .PACKET_SIZE ( PACKET_SIZE )
    ) u_packet (
        .s_axi_aclk    ( clk          ),
        .s_axi_aresetn ( rst_n        ),
        .s_axi_tvalid  ( s_axi_tvalid ),
        .s_axi_tdata   ( s_axi_tdata  ),
        .s_axi_tready  ( s_axi_tready ),
        .m_axi_tvalid  ( m_axi_tvalid ),
        .m_axi_tdata   ( m_axi_tdata  ),
        .m_axi_tready  ( m_axi_tready )
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task request_packet;
        input [PNUM_WIDTH-1:0] packet_id;
        begin
            s_axi_tdata  = packet_id;
            s_axi_tvalid = 1'b1;
            if(!s_axi_tready) begin
                $error("s_axi_tready should be high in IDLE at %0t", $time);
                err_cnt = err_cnt + 1;
            end
            tick();
            s_axi_tvalid = 1'b0;
        end
    endtask

    task check_packet;
        input [PNUM_WIDTH-1:0] packet_id;
        begin
            base_data = packet_id * PACKET_SIZE;
            request_packet(packet_id);

            if(s_axi_tready) begin
                $error("s_axi_tready should drop while sending at %0t", $time);
                err_cnt = err_cnt + 1;
            end

            // 反压时 m_axi_tvalid 和 m_axi_tdata 必须保持稳定。
            m_axi_tready = 1'b0;
            repeat(2) begin
                tick();
                if(!m_axi_tvalid || m_axi_tdata !== base_data[DATA_WIDTH-1:0]) begin
                    $error("backpressure hold mismatch: data=%h expected=%h", m_axi_tdata, base_data[DATA_WIDTH-1:0]);
                    err_cnt = err_cnt + 1;
                end
            end

            for(idx = 0; idx < PACKET_SIZE; idx = idx + 1) begin
                if(!m_axi_tvalid || m_axi_tdata !== (base_data + idx)) begin
                    $error("packet data mismatch idx=%0d got=%h expected=%h", idx, m_axi_tdata, (base_data + idx));
                    err_cnt = err_cnt + 1;
                end
                m_axi_tready = 1'b1;
                tick();
            end

            m_axi_tready = 1'b0;
            tick();
            if(m_axi_tvalid || !s_axi_tready) begin
                $error("packet should return to IDLE at %0t", $time);
                err_cnt = err_cnt + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("prj/icarus/tb_packet.vcd");
        $dumpvars(0, tb_packet);

        err_cnt      = 0;
        rst_n        = 1'b0;
        s_axi_tvalid = 1'b0;
        s_axi_tdata  = {PNUM_WIDTH{1'b0}};
        m_axi_tready = 1'b0;

        repeat(3) tick();
        rst_n = 1'b1;
        tick();

        if(!s_axi_tready || m_axi_tvalid) begin
            $error("reset/idle AXIS state mismatch");
            err_cnt = err_cnt + 1;
        end

        check_packet(2'd0);
        check_packet(2'd3);

        if(err_cnt == 0)
            $display("PASS: packet self-check passed.");
        else
            $fatal(1, "FAIL: packet self-check failed, err_cnt = %0d", err_cnt);

        $finish;
    end

endmodule
