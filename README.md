# "一生一芯"工程项目

这是"一生一芯"的工程项目. 通过运行
```bash
bash init.sh subproject-name
```
进行初始化, 具体请参考[实验讲义][lecture note].

[lecture note]: https://ysyx.oscc.cc/docs/


# YSYX Workbench —— RISC-V Processor Design & SoC Development

基于南京大学「一生一芯（YSYX）」课程，独立完成从 CPU、Cache、SoC 到软件运行环境的全栈设计，实现支持 RT-Thread 的 RISC-V 五级流水线处理器。

## Project Overview

本项目基于 一生一芯（YSYX） 课程，完整实践处理器设计流程，从 ISA、RTL、SoC、外设、仿真环境到操作系统运行，完成了一套支持 RV32E 指令集的 RISC-V 五级流水线处理器，并能够运行 RT-Thread 操作系统。

# 项目涵盖：

- RISC-V CPU 微架构设计
- Cache 设计
- SoC 集成
- 仿真器开发
- 外设控制器
- RTL 综合与 STA
- 软件运行环境

## Project Highlights
### CPU Design

自主设计 RV32E 五级流水线 CPU，包括：

- IF / ID / EX / MEM / WB
- Forwarding (Bypass)
- Pipeline Hazard Detection
- Dynamic Branch Prediction (BTB + BHT)
- Exception / Interrupt
- CSR
- Timer
### Cache Design

实现可配置 Direct-Mapped Instruction Cache：

支持

- Configurable Cache Size
- Configurable Block Size
- Cache Hit/Miss Handling
- Cache Performance Counter
### SoC Design

将 CPU 接入 ysyxSoC：

完成

- AXI4 Master Interface
- APB Peripheral
- UART
- GPIO
- VGA
- PS/2 Keyboard
- Timer
- AXI delayer
- APB delayer

并能够在NVBoard运行：

- RT-Thread

调试支持：

- Waveform
- Single Step
- Trace
- Watchpoint
- Differential Test (Spike)
- Performance Counter

### NEMU

完成 RV32I 指令集模拟器：

实现：

- Expression Evaluator
- Watchpoint
- Trace
- DiffTest
- Device Simulation

支持：

- UART
- Timer
- Keyboard
- VGA