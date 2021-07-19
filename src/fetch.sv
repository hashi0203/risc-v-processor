`default_nettype none
`include "def.sv"

module fetch
  ( input  wire        clk,
    input  wire        rstn,
    input  wire        enabled,
    input  wire [31:0] pc,

    output wire        completed,
    output reg  [31:0] pc_n,
    output wire [31:0] instr_raw );

  // fib
  reg [31:0] instr_mem [0:46] = '{
    32'b00000111010000000000000011101111,  //  0. jal ra,74 <main>
    32'b11111110000000010000000100010011,  //  1. addi sp(=r2),sp,-32
    32'b00000000000100010010111000100011,  //  2. sw ra(=r1),28(sp)
    32'b00000000100000010010110000100011,  //  3. sw s0(=r8),24(sp)
    32'b00000000100100010010101000100011,  //  4. sw s1(=r9),20(sp)
    32'b00000010000000010000010000010011,  //  5. addi s0,sp,32
    32'b11111110101001000010011000100011,  //  6. sw a0(=r10),-20(s0)
    32'b11111110110001000010011100000011,  //  7. lw a4(=r14),-20(s0)
    32'b00000000000100000000011110010011,  //  8. li a5(=r15),1
    32'b00000000111001111100011001100011,  //  9. blt a5,a4,30 <fib+0x2c>
    32'b00000000000100000000011110010011,  // 10. li a5,1
    32'b00000011000000000000000001101111,  // 11. j 5c <fib+0x58>
    32'b11111110110001000010011110000011,  // 12. lw a5,-20(s0)
    32'b11111111111101111000011110010011,  // 13. addi a5,a5,-1
    32'b00000000000001111000010100010011,  // 14. mv a0,a5
    32'b11111100100111111111000011101111,  // 15. jal ra,4 <fib>
    32'b00000000000001010000010010010011,  // 16. mv s1,a0
    32'b11111110110001000010011110000011,  // 17. lw a5,-20(s0)
    32'b11111111111001111000011110010011,  // 18. addi a5,a5,-2
    32'b00000000000001111000010100010011,  // 19. mv a0,a5
    32'b11111011010111111111000011101111,  // 20. jal ra,4 <fib>
    32'b00000000000001010000011110010011,  // 21. mv a5,a0
    32'b00000000111101001000011110110011,  // 22. add a5,s1,a5
    32'b00000000000001111000010100010011,  // 23. mv a0,a5
    32'b00000001110000010010000010000011,  // 24. lw ra,28(sp)
    32'b00000001100000010010010000000011,  // 25. lw s0,24(sp)
    32'b00000001010000010010010010000011,  // 26. lw s1,20(sp)
    32'b00000010000000010000000100010011,  // 27. addi sp,sp,32
    32'b00000000000000001000000001100111,  // 28. ret jalr 0 1 0 (pc = r1 にジャンプ)
    32'b11111111000000010000000100010011,  // 29. addi sp,sp,-16
    32'b00000000000100010010011000100011,  // 30. sw ra,12(sp)
    32'b00000000100000010010010000100011,  // 31. sw s0,8(sp)
    32'b00000001000000010000010000010011,  // 32. addi s0,sp,16
    32'b00000000101000000000010100010011,  // 33. li a0,10
    32'b0,
    32'b11110111110111111111000011101111,  // 34. jal ra,4 <fib>
    32'b00000000000000000000000001101111,  // 35. j 8c <main+0x18>
    32'b0, 32'b0, 32'b0, 32'b0, 32'b0,
    32'b00110000001000000000000001110011, 32'b0, 32'b0, 32'b0, 32'b0
  };

  // memory
  // reg [31:0] instr_mem [0:16] = '{
  //   32'b00000000010000000000000011101111,  //  0. jal ra,4 <main> r1 を 1 に書き換える
  //   32'b11111110000000010000000100010011,  //  1. addi sp(=r2),sp,-32
  //   32'b00000000100000010010111000100011,  //  2. sw s0(=r8),28(sp)(=28)
  //   32'b00000010000000010000010000010011,  //  3. addi s0,sp,32
  //   32'b00000000000100000000011110010011,  //  4. li a5(=r15),1
  //   32'b11111110111101000010001000100011,  //  5. sw a5,-28(s0)(=4)
  //   32'b00000000001000000000011110010011,  //  6. li a5,2 = addi a5 r0 2
  //   32'b11111110111101000010010000100011,  //  7. sw a5,-24(s0)(=8)
  //   32'b11111110010001000010011100000011,  //  8. lw a4(=r14),-28(s0)(=4)
  //   32'b11111110100001000010011110000011,  //  9. lw a5,-24(s0)(=8)
  //   32'b00000000111101110000011110110011,  // 10. add a5,a4,a5
  //   32'b11111110111101000010011000100011,  // 11. sw a5,-20(s0)(=12)
  //   32'b00000000000000000000011110010011,  // 12. li a5,0
  //   32'b00000000000001111000010100010011,  // 13. mv a0(=r10),a5 = addi a0 a5 0
  //   32'b00000001110000010010010000000011,  // 14. lw s0,28(sp)(=28)
  //   32'b00000010000000010000000100010011,  // 15. addi sp,sp,32
  //   32'b00000000000000001000000001100111   // 16. ret = jalr r1 0 (r1+0のアドレスにジャンプ)
  // };

  // add + jump
  // reg [31:0] instr_mem [0:9] = '{
  //   32'b00000000001000011000000110110011, // ADD 3(rs1) + 2(rs2) = 3(rd)
  //   32'b00000000001000011000000110110011, // ADD 3(rs1) + 2(rs2) = 3(rd)
  //   32'b00000000001000011000000110110011, // ADD 3(rs1) + 2(rs2) = 3(rd)
  //   32'b00000000001000011000000110110011, // ADD 3(rs1) + 2(rs2) = 3(rd)
  //   32'b00000000001000011000000110110011, // ADD 3(rs1) + 2(rs2) = 3(rd)
  //   32'b00000000001000011000000110110011,  // ADD 3(rs1) + 2(rs2) = 3(rd)
  //   32'b00000000001000011000000110110011,  // ADD 3(rs1) + 2(rs2) = 3(rd)
  //   32'b00000000010000011101001001100011,  // BGE 3(rs1) >= 4(rs2) -> 2(imm)
  //   32'b00000000001000011000001010110011,  // ADD 3(rs1) + 2(rs2) = 5(rd)
  //   32'b11111111100111111111000011101111   // JAL -2(imm) 1(rd)
  // };

  reg _completed;
  assign completed = _completed & !enabled;
  assign instr_raw = enabled ? instr_mem[pc] : 32'b0;

  always @(posedge clk) begin
    if(rstn) begin
      if (enabled) begin
        _completed <= 1;
        pc_n <= pc;
      end
    end else begin
      _completed <= 0;
      pc_n <= 0;
    end
  end
endmodule

`default_nettype wire
