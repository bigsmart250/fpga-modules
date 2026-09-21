# fpga-modules

个人 FPGA 通用模块库。基于 VSCode **Digital IDE** 插件的项目格式开发，模块统一采用 **AXI-Stream 风格握手接口（tvalid / tready）**，全部带参数自检（`initial` 中 `$error`）与自检测 testbench。

> 本仓库所有代码均为本人独立编写，不含任何第三方例程代码。

## 模块列表

| 模块 | 功能 | 接口 | 验证状态 |
|---|---|---|---|
| `edge_detection` | 异步信号同步 + 边沿检测，输出上升/下降/双沿单周期脉冲 | 电平/脉冲 | 仿真验证 |
| `freq_divider` | 整数分频，输出分频时钟与使能标志，极性可配 | 电平 | 仿真验证 |
| `any_freq_divider` | 相位累加器实现的任意比例分频使能发生器 | 电平 | 仿真验证 |
| `uart_tx` | UART 发送，支持 1/2 停止位、奇/偶校验 | AXI-Stream 从 | 仿真验证 |
| `uart_rx` | UART 接收，带起始/校验/停止位错误标志 | AXI-Stream 主 | 仿真验证 |
| `ring_buffer` | AXI-Stream 同步 FIFO，支持同拍读写 | AXI-Stream 主从 | 仿真 + 上板（Zynq 7020） |
| `packet` | 按包号输出 ROM 包内容的 AXI-Stream 数据源 | AXI-Stream 主从 | 仿真验证 |

## 仓库结构

```
fpga-modules/
├── rtl/                       # 最终交付的模块源码（拿走即用）
├── sim/                       # 与 rtl 一一对应的自检测 testbench
├── examples/                  # 可综合的完整小工程
│   ├── uart_loopback/         #   串口回环：uart_rx -> uart_tx
│   └── uart_fifo_demo/        #   串口收包入 FIFO 再回发（含 XDC 约束）
├── docs/
│   ├── digital-ide.md         # Digital IDE 项目格式与配置说明
│   └── modules/               # 各模块详细手册（参数/端口/时序）
└── LICENSE
```

## 快速开始

### 方式一：Digital IDE 插件（推荐，与本人开发流程一致）

1. VSCode 安装 **Digital IDE** 插件；
2. `git clone` 本仓库后，将某个模块目录（或按 `docs/digital-ide.md` 新建）用插件打开；
3. 插件右键菜单即可完成语法检查（yosys）、仿真（iverilog）、综合（Vivado 调用）。

项目格式与 `property.json` 各字段含义见 **[docs/digital-ide.md](docs/digital-ide.md)**。

### 方式二：命令行仿真（iverilog）

```bash
cd sim
mkdir -p ../prj/icarus    # tb 的 VCD 波形输出目录，必须先创建
iverilog -g2012 -o tb_ring_buffer.vvp tb_ring_buffer.v ../rtl/ring_buffer.v
vvp tb_ring_buffer.vvp    # 输出 PASS 即通过
```

### 方式三：Vivado / 其他工具

把 `rtl/` 下需要的 `.v` 文件加入工程即可，无其他依赖。目标器件无关（本人在 `xc7z020clg400-2` 上板验证过 ring_buffer 链路）。

## 设计约定

使用前请先了解以下统一约定：

- **复位**：全部低有效异步复位（`rst_n` / `s_axi_aresetn`）；
- **握手**：AXI-Stream 语义，`tvalid & tready` 同拍成交；
- **脉冲**：文档中标注"单周期脉冲"的输出，高电平只维持一个时钟周期；
- **参数自检**：参数非法时仿真期直接 `$error` + `$finish`，避免带病综合；
- **安全位宽**：所有计数器位宽由 `$clog2` 自动推导，非法参数在 localparam 中钳位兜底。

## 各模块手册

- [edge_detection](docs/modules/edge_detection.md)
- [freq_divider / any_freq_divider](docs/modules/freq_divider.md)
- [uart_tx / uart_rx](docs/modules/uart.md)
- [ring_buffer / packet](docs/modules/ring_buffer.md)

## Roadmap

- [ ] I2C Master（计划以全新重写版本加入，当前版本基于教程代码改造，不适合开源）
- [ ] SPI Master / Slave
- [ ] 异步 FIFO（双时钟域）
- [ ] 各模块 WaveDrom 时序图

## 更新与反馈

个人项目，随做随更。有问题欢迎提 Issue；PR 前请先跑通对应模块的 testbench。

## License

[MIT](LICENSE)
