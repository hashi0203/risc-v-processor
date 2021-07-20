# RISC-V Processor

Implementation of RISC-V Processor in `System Verilog`.


## ISA
- Unprivileged
	- RV32I (jump, branch, load/store, arithmetic/logical operations, ecall, ebreak)
	- RV32 Zicsr (CSR operations)
	- RV32M (mul, div, rem)
- Privileged
	- Trap-Return Instructions (mret)

ISA is published in [RISC-V official page](https://riscv.org/technical/specifications/).<br>
Unprivileged Instructions are based on "[Volume 1, Unprivileged Spec v. 20191213](https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMAFDQC/riscv-spec-20191213.pdf)."<br>
Privileged Instructions are based on "[Volume 2, Privileged Spec v. 20190608](https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMFDQC-and-Priv-v1.11/riscv-privileged-20190608.pdf)."


## Structure

- 4-stage pipeline (`Fetch`, `Decode`, `Execute`, `Write)`
- Forwarding (`E -> D`, `W -> D`)
- Branch prediction (`Two-level adaptive predictor`)
- Register (32 entries, 32 bit)
- Memory (1024 entries, 32 bit)
	- Use just registers for ease of implementation
- CSR (Control and Status Register)
- Exception/Interrupt handling (only `User` and `Machine` mode without `Supervisor` mode)


## Installation

1. This repository

	```bash
	$ git clone https://github.com/hashi0203/riscv-processor.git
	```

2. RISC-V Cross Compiler

	If you just want to run the processor, you can skip this process.<br>
	If you want to run your `original test program`, you should follow this process.

	We use [riscv-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain) as a cross compiler.<br>
	Basically, you can follow the instructions in the GitHub.

	```bash
	$ git clone https://github.com/riscv/riscv-gnu-toolchain
	$ ./configure --prefix=/opt/riscv32 --with-arch=rv32ima --with-abi=ilp32d
	$ make linux
	```

	You can change `--prefix=/opt/riscv32` to the path you want to install this compiler.

	You also have to update `PATH`.

	```
	export PATH=/opt/riscv32/bin:$PATH
	```


## Usage

If you just want to run the processor, you can skip 1 and 2.<br>
If you want to run your `original test program`, you should follow 1 to 3.

1. Make a test program for processor in [test-programs](./test-programs).
	- Make a test program in C (e.g., [fib.c](./test-programs/fib.c), [memory.c](./test-programs/memory.c)).
	- Compile the program by the following command (change "fib" to the file name (without extension) you have made).

	```bash
	$ cd /path/to/test-programs
	$ make ARG=fib
	```

	- Output files are explained later in [Files in test-programs](#files-in-test-programs) chapter.

2. Change the test program for processor.
	- Update instruction memory (`instr_mem`) in [fetch.sv](./src/fetch.sv).
		- Make sure to change `63` in line 14 to `the number of lines - 1`.
	- Update `final_pc` (line 20) and `privilege_jump_addr` (line 21) in [core.sv](./src/core.sv).
		- If you don't expect exception or interruption, you don't have to set `privilege_jump_addr`.
	- Set `max_itr`, `ext_intr` and `timer_intr` in [test_core.sv](./src/test_core.sv).
		- If `max_itr` is small, the program may not finish.
		- If you don't expect external or timer interruption, you don't have to set `ext_intr` and `timer_intr`.

3. Run the processor.
	- We use Vivado simulator commands (`xvlog`, `xelab`, and `xsim`).
	- You just have to run the following command.
		- All the `.sv` files in [src](./src) will be compiled.

	```bash
	$ cd /path/to/src
	$ make
	```


## Advanced Usage

When you make test programs, you can also write or edit RISC-V assembly code.<br>
For example, [fib-ebreak.S](./test-programs/fib-ebreak.S) and [fib-csr.S](./test-programs/fib-csr.S) are obtained by editing [fib.S](./test-programs/fib.S).<br>
When editing assemblies, you have to make sure that edited part should be `above` the following three lines.

```
	.size	main, .-main
	.ident	"GCC: (GNU) 10.2.0"
	.section	.note.GNU-stack,"",@progbits
```

After creating test programs in assembly, edit the [Makefile](./test-programs/Makefile) by commenting out line 28 and 29.

```
# $(ARG).S: $(ARG).c
# 	$(CC) $(CFLAGS) -S -o $(ARG).S $(ARG).c
```

Then, compile it by using `make` command.

```bash
$ cd /path/to/test-programs
$ make ARG=fib-ebreak
```


## Files in [test-programs](./test-programs)

- [start.S](./test-programs/start.S)
	- disable default initial routine
	- no need to edit
- [link.ld](./test-programs/link.ld)
	- set start pc (program counter) to 0
	- no need to edit


### Explanation when using [fib.c](./test-programs/fib.c)
- [fib.c](./test-programs/fib.c)
	- test program in C
- [fib.S](./test-programs/fib.S)
	- test program in assembly
	- automatically generated by `make` command
- [fib.hex](./test-programs/fib.hex)
	- test program in hexadecimal
	- automatically generated by `make` command
- [fib.b](./test-programs/fib.b)
	- test program in binary
	- used to test processor by editing [fetch.sv](./src/fetch.sv)
	- automatically generated by `make` command
- [fib.dump](./test-programs/fib.dump)
	- disassembled test program (almost same as [fib.S](./test-programs/fib.S))
	- automatically generated by `make` command

`.hex` and `.dump` are used for debugging.


## Reference
- [riscv-gnu-toolchain](https://github.com/riscv/riscv-gnu-toolchain) (Cross Compiler)
	- to cross-compile the C programs to binary.
- [RISC-Vを使用したアセンブリ言語入門 〜2. アセンブリ言語を見てみよう〜](https://qiita.com/widedream/items/15dbe3a2203811fa7297)
	- to see how to compile programs by using `riscv-gnu-toolchain`.
- [RISC-Vクロスコンパイラで生成したバイナリを自作RISC-V上で実行する](https://kivantium.hateblo.jp/entry/2020/07/24/225016)
	- to see how to compile C programs to binary.
	- to validate the compile result.
- [RV32I, RV64I Instructions](https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html)
	- to see the detailed explanation of RISC-V ISA.
- [RISC-Vについて(CPU実験その2)](https://progrunner.hatenablog.jp/entry/2017/12/03/221829)
	- to see the detailed explanation of RISC-V ISA.
- [RV32I インストラクション・セット](https://qiita.com/zacky1972/items/48bf61bfe3ef2b8ce557)
	- to see the detailed explanation of RISC-V ISA.
- [分岐先アドレスを予測する](https://news.mynavi.jp/article/architecture-174/)
	- to see how to implement branch prediction.
- [cpuex2019-7th/core](https://github.com/cpuex2019-7th/core)
	- to see how to implement processor.
- [RISC-Vの特権命令まとめ](https://msyksphinz.hatenablog.com/entry/advent20161205)
	- to see how the CSR instructions work.
- [RISC-VでLinuxを動かすためのレジスタ制御](https://www.aps-web.jp/academy/risc-v/584/)
	- to see how the CSR instructions work.
- [RISC-Vにおけるprivilege modeの遷移(xv6-riscvを例にして)](https://cstmize.hatenablog.jp/entry/2019/09/26/RISC-V%E3%81%AB%E3%81%8A%E3%81%91%E3%82%8Bprivilege_mode%E3%81%AE%E9%81%B7%E7%A7%BB%28xv6-riscv%E3%82%92%E4%BE%8B%E3%81%AB%E3%81%97%E3%81%A6%29#fn:21)
	- to see how to handle exception and interrupt.
- [RISC-Vとx86のsystem callの内部実装の違い(xv6を例に)](https://cstmize.hatenablog.jp/entry/2019/10/01/RISC-V%E3%81%A8x86%E3%81%AEsystem_call%E3%81%AE%E5%86%85%E9%83%A8%E5%AE%9F%E8%A3%85%E3%81%AE%E9%81%95%E3%81%84%28xv6%E3%82%92%E4%BE%8B%E3%81%AB%29)
	-	to see the behavior of system call instructions.
- [xv6-riscv](https://github.com/mit-pdos/xv6-riscv) (simple OS)
	- to check exception/interrupt behavior.
- [cpuex2019-yokyo/core](https://github.com/cpuex2019-yokyo/core/)
	- to see how to implement privileged instructions.