//////////////////////////////////////////////////////////////////////////////////
// Affiliation: Universidade Federal do Rio Grande do Sul (UFRGS)
// Author: Mateus Saquetti Pereira de Carvalho Tirone
//
// Create Date: 06.11.2018 14:44:14
// Module Name: input_p4_interface
// Revision: 12/12/2018
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module input_p4_interface
#(
  //Slave AXI parameters
  parameter C_S_AXI_DATA_WIDTH    = 32,
  parameter C_S_AXI_ADDR_WIDTH    = 32,
  parameter C_BASEADDR            = 32'h00000000,

  // Master AXI Stream Data Width
  parameter C_M_AXIS_DATA_WIDTH=256,
  parameter C_S_AXIS_DATA_WIDTH=256,
  parameter C_M_AXIS_TUSER_WIDTH=128,
  parameter C_S_AXIS_TUSER_WIDTH=128,
  parameter NUM_QUEUES=5,
  parameter DIGEST_WIDTH =80
)
(
  // Global Ports
  input                                                           axis_aclk,
  input                                                           axis_resetn,

  // Master Stream Ports (interface to nf_sume_sdnet_ips)
  output reg [C_S_AXIS_DATA_WIDTH - 1:0]                          m_axis_0_tdata,
  output reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_0_tkeep,
  output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_0_tuser,
  output reg                                                      m_axis_0_tvalid,
  output reg                                                      m_axis_0_tlast,
  input                                                           m_axis_0_tready,

  output reg [C_S_AXIS_DATA_WIDTH - 1:0]                          m_axis_1_tdata,
  output reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_1_tkeep,
  output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_1_tuser,
  output reg                                                      m_axis_1_tvalid,
  output reg                                                      m_axis_1_tlast,
  input                                                           m_axis_1_tready,

  output reg [C_S_AXIS_DATA_WIDTH - 1:0]                          m_axis_2_tdata,
  output reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_2_tkeep,
  output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_2_tuser,
  output reg                                                      m_axis_2_tvalid,
  output reg                                                      m_axis_2_tlast,
  input                                                           m_axis_2_tready,

  output reg [C_S_AXIS_DATA_WIDTH - 1:0]                          m_axis_3_tdata,
  output reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_3_tkeep,
  output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_3_tuser,
  output reg                                                      m_axis_3_tvalid,
  output reg                                                      m_axis_3_tlast,
  input                                                           m_axis_3_tready,

  // Slave Stream Ports (interface to input_arbiter)
  input   [C_M_AXIS_DATA_WIDTH - 1:0]                             s_axis_tdata,
  input   [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]                     s_axis_tkeep,
  input   [C_M_AXIS_TUSER_WIDTH-1:0]                              s_axis_tuser,
  input                                                           s_axis_tvalid,
  input                                                           s_axis_tlast,
  output reg                                                      s_axis_tready,

  // Slave AXI Ports
  input                                                           S_AXI_ACLK,
  input                                                           S_AXI_ARESETN
);

  // ------------ Internal Params --------

  localparam VLAN_WIDTH=32;
  localparam VLAN_WIDTH_ID=12;
  localparam VLAN_THRESHOLD_BGN=128;
  localparam VLAN_THRESHOLD_END=96;

  localparam NUM_STATES=3;
  localparam INI_PKT=0;
  localparam WAIT_PKT=1;
  localparam WR_PKT=2;

  // ------------- Regs/ wires -----------
  /* Format of tdata signal:
   *    [127:96]          vlan_tdata;     // Dot1Q<32 bits>
   * Format of vlan_tdata signal:
   *    [15:0]            vlan_prot_id;   // Protocol Identifier<32 bits>
   *    [31:16]           vlan_info;      // Tag Information<32 bits>
   * Format of vlan_info signal:
   *    [7:5]             vlan_info_prio; // Priority<3 bits>
   *    [4]               vlan_info_drop; // Drop Eligible<1 bit>
   *    {[3:0], [15: 8]}  vlan_info_id;   // VLAN Identifier<12 bits>
   */

  wire [VLAN_WIDTH - 1:0] vlan_tdata;
  wire [(( VLAN_WIDTH/2 )) - 1:0] vlan_prot_id;
  wire [(( VLAN_WIDTH/2 )) - 1:0] vlan_info;
  wire [(( VLAN_WIDTH_ID/4 )) - 1:0] vlan_info_prio;
  wire vlan_info_drop;
  wire [VLAN_WIDTH_ID -1 :0] vlan_info_id;

  reg [NUM_STATES-1:0]                state_next;
  reg [NUM_STATES-1:0]                state;


  // ------------- Logic ------------

  assign vlan_tdata = s_axis_tdata [VLAN_THRESHOLD_BGN - 1:VLAN_THRESHOLD_END];
  assign vlan_prot_id = vlan_tdata [((VLAN_WIDTH/2)) - 1:0];
  assign vlan_info = vlan_tdata [VLAN_WIDTH - 1:(( VLAN_WIDTH/2 ))];
  assign vlan_info_prio = vlan_info [7:5];
  assign vlan_info_drop = vlan_info [4];
  assign vlan_info_id = {vlan_info[3:0], vlan_info[15: 8]};


  always @(*) begin
    state_next     = state;
    s_axis_tready  = 0;

    case(state)

      INI_PKT: begin
        // s_axis_tready = (~axis_resetn) ? 0 : 1;
        s_axis_tready = 0;

        m_axis_0_tdata  <= 0;
        m_axis_0_tkeep  <= 0;
        m_axis_0_tuser  <= 0;
        m_axis_0_tvalid <= 0;
        m_axis_0_tlast  <= 0;

        m_axis_1_tdata  <= 0;
        m_axis_1_tkeep  <= 0;
        m_axis_1_tuser  <= 0;
        m_axis_1_tvalid <= 0;
        m_axis_1_tlast  <= 0;

        m_axis_2_tdata  <= 0;
        m_axis_2_tkeep  <= 0;
        m_axis_2_tuser  <= 0;
        m_axis_2_tvalid <= 0;
        m_axis_2_tlast  <= 0;

        m_axis_3_tdata  <= 0;
        m_axis_3_tkeep  <= 0;
        m_axis_3_tuser  <= 0;
        m_axis_3_tvalid <= 0;
        m_axis_3_tlast  <= 0;

        state_next = WAIT_PKT;
      end

     /* cycle between input queues until one is not empty */
      WAIT_PKT: begin
        s_axis_tready = 0;
        if(s_axis_tvalid) begin
          if (vlan_prot_id == 16'h0081) begin // 0000 0000 1000 0001
            state_next = WR_PKT;
          end
          else begin
            state_next = INI_PKT;
          end
        end
      end // case: WAIT_PKT

     /* wait until eop */
      WR_PKT: begin
        s_axis_tready = 1;
        if(s_axis_tvalid) begin
          if (vlan_prot_id == 16'h0081) begin // 0000 0000 1000 0001
            if (vlan_info_id == 12'h001) begin // 0000 0000 0001
              m_axis_0_tdata  <= s_axis_tdata;
              m_axis_0_tuser  <= s_axis_tuser;
              m_axis_0_tvalid <= s_axis_tvalid;
              m_axis_0_tkeep  <= s_axis_tkeep;
              m_axis_0_tlast  <= s_axis_tlast;
            end
            else if (vlan_info_id == 12'h002) begin // 0000 0000 0002
              m_axis_1_tdata  <= s_axis_tdata;
              m_axis_1_tuser  <= s_axis_tuser;
              m_axis_1_tvalid <= s_axis_tvalid;
              m_axis_1_tkeep  <= s_axis_tkeep;
              m_axis_1_tlast  <= s_axis_tlast;
            end
            else if (vlan_info_id == 12'h003) begin // 0000 0000 0002
              m_axis_2_tdata  <= s_axis_tdata;
              m_axis_2_tuser  <= s_axis_tuser;
              m_axis_2_tvalid <= s_axis_tvalid;
              m_axis_2_tkeep  <= s_axis_tkeep;
              m_axis_2_tlast  <= s_axis_tlast;
            end
            else if (vlan_info_id == 12'h004) begin // 0000 0000 0002
              m_axis_3_tdata  <= s_axis_tdata;
              m_axis_3_tuser  <= s_axis_tuser;
              m_axis_3_tvalid <= s_axis_tvalid;
              m_axis_3_tkeep  <= s_axis_tkeep;
              m_axis_3_tlast  <= s_axis_tlast;
            end
          end
          if(s_axis_tlast) begin
            state_next = INI_PKT;
          end
        end// if(s_axis_tvalid)
      end // case: WR_PKT

    endcase // case(state)
  end // always @ (*)


  always @(posedge axis_aclk) begin
    if(~axis_resetn) begin
      state <= INI_PKT;
    end
    else begin
      state <= state_next;
    end
  end

endmodule
