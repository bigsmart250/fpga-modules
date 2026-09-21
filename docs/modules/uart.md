# uart_tx / uart_rx — AXI-Stream 接口 UART

接口为 AXI-Stream 风格握手（`tvalid` / `tready`），不是完整 AXI4 总线。`uart_tx` 是 AXI-Stream 从机（收字节），`uart_rx` 是 AXI-Stream 主机（发字节）。

## uart_tx

### 参数

| 参数 | 默认值 | 说明 |
|---|---|---|
| `CLK_FREQ` | 50_000_000 | 系统时钟频率 Hz，须 ≥ `UART_BPS` |
| `UART_BPS` | 115200 | 波特率 |
| `DATA_BIT` | 8 | 数据位宽（1~8） |
| `PARITY_BIT` | 0 | 0=无校验，1=奇校验，2=偶校验 |
| `STOP_BIT` | 1 | 停止位 1 或 2 |

### 端口

| 方向 | 信号 | 说明 |
|---|---|---|
| in | `s_axi_tvalid` / `s_axi_tdata` | 待发送字节及有效标志 |
| out | `s_axi_tready` | 空闲时为 1，握手即锁存数据开始发送 |
| out | `uart_txd` | 串行输出，LSB first，空闲为高 |

## uart_rx

### 参数

同 `uart_tx`（同一组参数，两端配置必须一致）。

### 端口

| 方向 | 信号 | 说明 |
|---|---|---|
| out | `m_axi_tvalid` / `m_axi_tdata` | 收到完整帧后输出，**单周期脉冲**（不是持续 valid） |
| out | `s_axi_tready` | 状态机处于 IDLE 时为 1（此时不会丢数据） |
| out | `start_error` / `parity_error` / `stop_error` | 起始位/校验位/停止位错误标志，帧内任一错误则该帧数据不输出 |
| in | `uart_rxd` | 串行输入 |

## 时序与使用要点

- 接收端内部 3 级打拍同步 + 中点采样（半波特率位置），起始位二次确认防毛刺；
- **`m_axi_tvalid` 是单周期脉冲**：下游若是持续 valid 的 AXI-Stream 逻辑，需自行缓存（可直接接 `ring_buffer`）；
- 任一错误位置位时整帧丢弃，只留标志位供上层统计；
- 完整回环例程：`examples/uart_loopback`（rx 直接接 tx）；带 FIFO 的收发例程：`examples/uart_fifo_demo`；
- 例程 tb：`sim/tb_uart_tx.v`、`sim/tb_uart_rx.v`。
