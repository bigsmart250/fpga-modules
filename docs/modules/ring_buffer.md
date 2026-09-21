# ring_buffer — AXI-Stream 同步 FIFO

标准 AXI-Stream 主从接口的同步 FIFO，支持同拍读写（full 时写侧仍可通过读腾位，tready 组合了 read_fire）。已在 Zynq xc7z020 上板验证（串口收包 → FIFO → 回发链路，见 `examples/uart_fifo_demo`）。

## 参数

| 参数 | 默认值 | 说明 |
|---|---|---|
| `DATA_WIDTH` | 8 | 数据位宽 |
| `DATA_DEPTH` | 16 | 深度，最小 2 |
| `ADDR_WIDTH` | 自动推导 | 地址位宽，由 `DATA_DEPTH` 推导，一般无需手动指定 |

## 端口

| 方向 | 信号 | 说明 |
|---|---|---|
| in | `s_axi_aclk` / `s_axi_aresetn` | 时钟 / 低有效异步复位 |
| in | `s_axi_tvalid` / `s_axi_tdata` | 写侧 |
| out | `s_axi_tready` | 非满可写（同拍读腾位时也拉高） |
| out | `m_axi_tvalid` / `m_axi_tdata` | 读侧，非空即有数据 |
| in | `m_axi_tready` | 读侧握手 |
| out | `w_addr` / `r_addr` | 读写指针（调试观察用） |
| out | `full` / `empty` | 状态标志 |

## 时序要点

- 写满/读空的判断基于内部计数器 `data_cnt`，同拍读写时计数不变，两侧握手均按组合逻辑放行；
- `m_axi_tdata = buffer[r_ptr]` 为组合读（first-word fall-through 风格），`m_axi_tvalid` 非空即高，下游拉 `tready` 即当拍取走；
- 上板例程：`examples/uart_fifo_demo`（含 XDC 约束，串口收包入 FIFO 再回发），tb 见 `sim/tb_ring_buffer.v`。

## ⚠ 已知可移植性问题

（已于仓库版修复）早期版本曾在端口列表中引用模块体内定义的 `localparam ADDR_WIDTH`，Vivado 可综合但不符合 IEEE 1800。现 `ADDR_WIDTH` 已提升为由 `DATA_DEPTH` 推导的 parameter port。
