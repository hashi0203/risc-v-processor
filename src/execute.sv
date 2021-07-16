`default_nettype none
`include "def.sv"

module execute
  ( input  wire         clk,
    input  wire         rstn,

    input  wire         enabled,
    input  instructions instr,
    input  reg [31:0]   rs1,
    input  reg [31:0]   rs2,
    input  reg [31:0]   csr,

    output wire         completed,
    output instructions instr_out,
    // output reg [31:0]   rs1_out,
    // output reg [31:0]   rs2_out,

    output wire [31:0]  rd,
    output wire [31:0]  csrd,
    output wire         is_jump,
    output wire [31:0]  jump_dest );

  wire [31:0] alu_rd;
  wire        alu_completed;
  alu _alu
    ( .clk(clk),
      .rstn(rstn),
      .enabled(enabled),
      .instr(instr),
      .rs1(rs1),
      .rs2(rs2),
      .csr(csr),
      .completed(alu_completed),
      .rd(alu_rd) );

  // wire _completed = ((instr_n.rv32f && fpu_completed)
  //                     || (!instr_n.rv32f && alu_completed));
  wire _completed = 1;
  assign completed = _completed & !enabled;

  wire [31:0] r_data;
  memory _memory
    ( .clk(clk),
      .rstn(rstn),
      .base(rs1),
      .offset(instr.imm),

      .r_enabled(instr.is_load),
      .r_data(r_data),
      .w_enabled(instr.is_store),
      .w_data(rs2) );

  assign rd        = instr.is_load ? r_data :
                     instr.is_csr ? csr :
                     alu_rd;
  assign csrd      = instr.is_csr ? alu_rd : csr;
  assign is_jump   = instr.jal || instr.jalr || (instr.is_conditional_jump && alu_rd == 32'b1);
  assign jump_dest = instr.jal  ? $signed(instr.pc) + $signed($signed(instr.imm) >>> 2) :
                     instr.jalr ? $signed(rs1) + $signed($signed(instr.imm) >>> 2) :
                     instr.is_conditional_jump && alu_rd == 32'b1 ? $signed(instr.pc) + $signed($signed(instr.imm) >>> 2) :
                     instr.pc + 1;

  always @(posedge clk) begin
    if (rstn) begin
      if (enabled) begin
        instr_out <= instr;
      end
    end
  end
endmodule

`default_nettype wire
