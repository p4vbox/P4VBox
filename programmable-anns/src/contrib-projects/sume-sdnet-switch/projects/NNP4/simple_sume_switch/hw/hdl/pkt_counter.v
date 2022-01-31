//
//  File:
//        pkt_count.v
//
//  Module:
//        pkt_count
//
//  Author: Mateus Saquetti
//
//  Description:
//        Packet counter by secound
//

`timescale 1ps / 1ps

module pkt_counter
#(
    // Master AXI Stream Data Width
    parameter C_M_AXIS_DATA_WIDTH=256,
    parameter C_S_AXIS_DATA_WIDTH=256,
    parameter C_M_AXIS_TUSER_WIDTH=128,
    parameter C_S_AXIS_TUSER_WIDTH=128,
    // AXI Registers Data Width
    parameter C_S_AXI_DATA_WIDTH    = 32,
    parameter C_S_AXI_ADDR_WIDTH    = 12,
    parameter C_BASEADDR            = 32'h00000000,
    // Internal
    parameter REG_DEPTH=32
)
(
    // Inputs
    input clk_200,
    input resetn,
    input resetn_sw,
    input axis_tvalid,
    input axis_tlast,
    // Outputs
    output [REG_DEPTH-1 : 0] packet_counter
);
  // ------------ Internal Params --------

  // ------------- Regs/ wires -----------
  reg [REG_DEPTH-1 : 0] store_counter;
  reg [REG_DEPTH-1 : 0] counter;
  reg [REG_DEPTH-1 : 0] timer;

  reg [1:0] axis_tlast_old;

  // ------------- Logic ------------
  assign packet_counter = store_counter;


  always @(posedge clk_200) begin
    if ( ~resetn ) begin
      axis_tlast_old <= 0;
    end
    else begin
      axis_tlast_old <= axis_tlast;
    end;
  end // always @(posedge axis_aclk)

  always @(posedge clk_200) begin
    if ( ~resetn ) begin
      counter <= 0;
      timer <= 0;
      store_counter <= 0;
    end
    else begin
     if (timer >= 32'hBEBC200) begin
//       if (timer >= 32'h106E) begin //sim
        timer <= 0;
        store_counter <= counter;
        counter <= 0;
      end
      else begin
        timer = timer + 1'h1;
        if (~axis_tlast_old && axis_tlast && axis_tvalid) begin
          counter = counter + 1'h1;
        end
        else begin
          counter <= counter;
        end
      end
    end
  end // always @(posedge axis_aclk)


endmodule
