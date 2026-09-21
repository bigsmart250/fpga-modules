# ring_buffer / packet — AXI-Stream FIFO 与数据源

## ring_buffer — AXI-Stream 同步 FIFO

标准 AXI-Stream 主从接口的同步 FIFO，支持同拍读写（full 时写侧仍可通过读腾位，tready 组合了 read_fire）。已在 Zynq xc7z020 上板验证（串口收包 → FIFO → 回发链路，见 `examples/uart_fifo_demo`）。

### 参数

| 参数 | 默认值 | 说明 |
|---|---|---|
| `DATA_WIDTH` | 8 | 数据位宽 |
| `DATA_DEPTH` | 16 | 深度，最小 2 |

### 端口

| 方向 | 信号 | 说明 |
|---|---|---|
| in | `s_axi_aclk` / `s_axi_aresetn` | 时钟 / 低有效异步复位 |
| in | `s_axi_tvalid` / `s_axi_tdata` | 写侧 |
| out | `s_axi_tready` | 非满可写（空拍读腾位时也拉高） |
| out | `m_axi_tvalid` / `m_axi_tdata` | 读侧，非空即有数据 |
| in | `m_axi_tready` | 读侧握手 |
| out | `w_addr` / `r_addr` | 读写指针（调试观察用） |
| out | `full` / `empty` | 状态标志 |

### ⚠ 已知可移植性问题

端口列表中使用了在模块体内才定义的 `localparam ADDR_WIDTH`。Vivado 可综合，但不符合 IEEE 1800 对 ANSI 端口引用的规则，部分工具（iverilog/yosys 对此敏感）可能报错。修复方式是把 `ADDR_WIDTH` 提升为 parameter port（`#(parameter ADDR_WIDTH = ...)` 由上层传入）或改用非 ANSI 端口风格。

## packet — 按包号输出的 AXI-Stream 数据源

输入一个包号（`s_axi_tdata`），从"虚拟 ROM"中按 `m_axi_tdata = packet_num * PACKET_SIZE + cnt` 连续输出 `PACKET_SIZE` 个字节，用于构造测试数据流（配合 ring_buffer 做 AXI-Stream 链路联调）。

### 参数

| 参数 | 默认值 | 说明 |
|---|---|---|
| `DATA_WIDTH` | 8 | 输出数据位宽 |
| `PACKET_NUM` | 4 | 包数量 |
| `PACKET_SIZE` | 4 | 每包字节数 |

### 端口

标准 AXI-Stream 主从（写侧收包号、读侧吐数据），另有内部握手状态机 IDLE/SEND 两态。

## 例程

- tb：`sim/tb_ring_buffer.v`、`sim/tb_packet.v`
- 上板例程：`examples/uart_fifo_demo`（含 XDC 约束，串口收包入 FIFO 再回发）
