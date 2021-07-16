`default_nettype none
`include "def.sv"

module write
  ( input  wire         clk,
    input  wire         rstn,
    input  wire         enabled,

    input  instructions instr,
    input  wire [31:0]  reg_data,
    input  wire [31:0]  csr_data,

    output wire         reg_w_enabled,
    output wire [4:0]   reg_w_addr,
    output wire [31:0]  reg_w_data,
    output wire         csr_w_enabled,
    output wire [11:0]  csr_w_addr,
    output wire [31:0]  csr_w_data,
    output wire         completed );

  reg _completed;
  assign completed = _completed & !enabled;

  assign reg_w_enabled = enabled && (instr.rd != 5'b0);
  assign reg_w_addr = instr.rd;
  assign reg_w_data = reg_data;

  assign csr_w_enabled = enabled && (instr.is_csr);
  assign csr_w_addr = instr.imm;
  assign csr_w_data = csr_data;

  always @(posedge clk) begin
    if (rstn) begin
      if(enabled) begin
        _completed <= 1;
      end
    end else begin
      _completed <= 0;
    end
  end
endmodule

`default_nettype wire
