# Digital IDE 项目格式说明

本仓库的开发流程基于 VSCode 插件 **Digital IDE**。每个模块是一个独立的最小工程，格式统一，复制任意一个模块目录作为模板即可新建自己的模块。本文以本仓库的开发工程为例，说明目录结构与配置。

## 单模块工程结构

以 `edge_detection` 为例（开发时的原始工程）：

```
edge_detection/
├── .vscode/
│   └── property.json        # Digital IDE 工程配置（核心）
├── user/                    # ★ 你只写这个目录
│   ├── src/                 # 设计源码（.v）
│   ├── sim/                 # testbench（.v）
│   ├── data/                # 约束文件（.xdc）、原理图等资料
│   └── bd/                  # Block Design（可选，基本不用）
└── prj/                     # ★ 插件/工具自动生成，全部可删可忽略
    ├── xilinx/              # Vivado 工程（template.xpr 及运行产物）
    └── netlist/             # yosys 语法检查/网表脚本（.ys）与输出（.json）
```

要点：

- **只维护 `user/` 目录**。`prj/` 整体是产物，删除后由插件重新生成；
- `user/src` 与 `user/sim` 一一对应：一个设计文件配一个同名 tb（`xxx.v` ↔ `tb_xxx.v`）；
- 约束文件放 `user/data`，插件建 Vivado 工程时会自动挂接。

## property.json 字段

```json
{
    "toolChain": "xilinx",
    "prjName": {
        "PL": "template"
    },
    "soc": {
        "core": "none"
    },
    "device": "xc7z020clg400-2"
}
```

| 字段 | 含义 |
|---|---|
| `toolChain` | 综合工具链。`xilinx` = 调用 Vivado；也支持 `quartus` / `gowin` 等 |
| `prjName.PL` | FPGA 工程名，插件在 `prj/<toolChain>/` 下以该名字建工程 |
| `soc.core` | SoC 软核/硬核配置，纯 PL 工程填 `none`（Zynq 纯 PL 玩法也填 none） |
| `device` | 目标器件完整型号，直接决定 Vivado 工程的 part |

## netlist 目录（.ys 脚本）

`prj/netlist/*.ys` 是 yosys 脚本，用于不启动 Vivado 的快速语法/层次检查。`{workspace}` 是占位符，指向模块工程根目录：

```ys
read_verilog -sv -formal -overwrite {workspace}/user/src/xxx.v
design -reset-vlog; proc;
write_json {workspace}/prj/netlist/xxx.json
```

`read_verilog` 报错即说明代码有语法/位宽问题，比开 Vivado 快得多。插件保存时会自动执行。

## 日常工作流

1. `user/src` 写设计，`user/sim` 写 tb；
2. 保存触发 yosys 检查（netlist）；
3. 插件内启动 iverilog 仿真看波形；
4. 需要上板/综合时，插件一键生成并打开 Vivado 工程（`prj/xilinx/template.xpr`）；
5. 版本管理只提交 `user/` 与 `.vscode/property.json`。

## 如何用本仓库的模块

不需要整个工程时，直接取 `rtl/` 下的 `.v` 文件加入你的工程即可，模块间零耦合、无依赖文件。
