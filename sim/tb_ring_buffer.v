`timescale 1ns / 1ps

module tb_ring_buffer();

    localparam integer DATA_WIDTH = 8;
    localparam integer DATA_DEPTH = 4;
    localparam integer ADDR_WIDTH = $clog2(DATA_DEPTH);

    reg clk;
    reg rst_n;
    reg s_axi_tvalid;
    reg [DATA_WIDTH-1:0] s_axi_tdata;
    reg m_axi_tready;

    wire s_axi_tready;
    wire m_axi_tvalid;
    wire [DATA_WIDTH-1:0] m_axi_tdata;
    wire [ADDR_WIDTH-1:0] w_addr;
    wire [ADDR_WIDTH-1:0] r_addr;
    wire full;
    wire empty;

    integer err_cnt;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    ring_buffer #(
        .DATA_WIDTH ( DATA_WIDTH ),
        .DATA_DEPTH ( DATA_DEPTH )
    ) u_ring_buffer (
        .s_axi_aclk    ( clk          ),
        .s_axi_aresetn ( rst_n        ),
        .s_axi_tvalid  ( s_axi_tvalid ),
        .s_axi_tdata   ( s_axi_tdata  ),
        .s_axi_tready  ( s_axi_tready ),
        .m_axi_tvalid  ( m_axi_tvalid ),
        .m_axi_tdata   ( m_axi_tdata  ),
        .m_axi_tready  ( m_axi_tready ),
        .w_addr        ( w_addr       ),
        .r_addr        ( r_addr       ),
        .full          ( full         ),
        .empty         ( empty        )
    );

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task push;
        input [DATA_WIDTH-1:0] data;
        begin
            s_axi_tdata  = data;
            s_axi_tvalid = 1'b1;
            m_axi_tready = 1'b0;
            tick();
            if(!s_axi_tready) begin
                $error("push blocked unexpectedly at %0t", $time);
                err_cnt = err_cnt + 1;
            end
            s_axi_tvalid = 1'b0;
        end
    endtask

    task pop;
        input [DATA_WIDTH-1:0] exp_data;
        begin
            if(!m_axi_tvalid || m_axi_tdata !== exp_data) begin
                $error("pop mismatch at %0t: valid=%b data=%h expected=%h", $time, m_axi_tvalid, m_axi_tdata, exp_data);
                err_cnt = err_cnt + 1;
            end
            m_axi_tready = 1'b1;
            tick();
            m_axi_tready = 1'b0;
        end
    endtask

    initial begin
        $dumpfile("prj/icarus/tb_ring_buffer.vcd");
        $dumpvars(0, tb_ring_buffer);

        err_cnt      = 0;
        rst_n        = 1'b0;
        s_axi_tvalid = 1'b0;
        s_axi_tdata  = 8'd0;
        m_axi_tready = 1'b0;
        tick();
        if(!empty || full) begin
            $error("reset empty/full mismatch");
            err_cnt = err_cnt + 1;
        end

        rst_n = 1'b1;
        push(8'h11);
        push(8'h22);
        pop(8'h11);
        push(8'h33);
        pop(8'h22);
        pop(8'h33);

        if(!empty) begin
            $error("fifo should be empty at end");
            err_cnt = err_cnt + 1;
        end

        if(err_cnt == 0)
            $display("PASS: ring_buffer self-check passed.");
        else
            $fatal(1, "FAIL: ring_buffer self-check failed, err_cnt = %0d", err_cnt);

        $finish;
    end

endmodule
