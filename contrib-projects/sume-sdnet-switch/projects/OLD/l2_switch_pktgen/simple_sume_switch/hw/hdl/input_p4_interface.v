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
  localparam WRITE_PKT_PART0=2;
  localparam WRITE_PKT_PART1=3;

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

  wire [VLAN_WIDTH - 1:0]                   vlan_tdata;
  wire [(( VLAN_WIDTH/2 )) - 1:0]           vlan_prot_id;
  wire [(( VLAN_WIDTH/2 )) - 1:0]           vlan_info;
  wire [(( VLAN_WIDTH_ID/4 )) - 1:0]        vlan_info_prio;
  wire                                      vlan_info_drop;
  wire [VLAN_WIDTH_ID -1 :0]                vlan_info_id;

  reg [NUM_STATES-1:0]                      ipi_state;
  reg                                       ipi_writepart; // Part of packet identifier
  reg [(( VLAN_WIDTH/2 )) - 1:0]            ipi_vlan_prot_id;
  reg [VLAN_WIDTH_ID -1 :0]                 ipi_vlan_info_id;

  reg [C_S_AXIS_DATA_WIDTH - 1:0]           ipi_tdata_part0;
  reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]   ipi_tkeep_part0;
  reg [C_M_AXIS_TUSER_WIDTH-1:0]            ipi_tuser_part0;
  reg                                       ipi_tvalid_part0;
  reg                                       ipi_tlast_part0;
  reg [C_S_AXIS_DATA_WIDTH - 1:0]           ipi_tdata_part1;
  reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]   ipi_tkeep_part1;
  reg [C_M_AXIS_TUSER_WIDTH-1:0]            ipi_tuser_part1;
  reg                                       ipi_tvalid_part1;
  reg                                       ipi_tlast_part1;

  // ------------- Logic ------------

  assign vlan_tdata = s_axis_tdata [VLAN_THRESHOLD_BGN - 1:VLAN_THRESHOLD_END];
  assign vlan_prot_id = vlan_tdata [((VLAN_WIDTH/2)) - 1:0];
  assign vlan_info = vlan_tdata [VLAN_WIDTH - 1:(( VLAN_WIDTH/2 ))];
  assign vlan_info_prio = vlan_info [7:5];
  assign vlan_info_drop = vlan_info [4];
  assign vlan_info_id = {vlan_info[3:0], vlan_info[15: 8]};


  always @(posedge axis_aclk) begin
    if( ~axis_resetn ) begin
      s_axis_tready <= 0;

      ipi_vlan_prot_id <= 0;
      ipi_vlan_info_id <= 0;
      ipi_tdata_part0 <= 0;
      ipi_tkeep_part0 <= 0;
      ipi_tuser_part0 <= 0;
      ipi_tvalid_part0 <= 0;
      ipi_tlast_part0 <= 0;
      ipi_tdata_part1 <= 0;
      ipi_tkeep_part1 <= 0;
      ipi_tuser_part1 <= 0;
      ipi_tvalid_part1 <= 0;
      ipi_tlast_part1 <= 0;

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

      ipi_writepart <= 0;
      ipi_state = INI_PKT;
    end
    else begin
      case( ipi_state )

        INI_PKT: begin
          s_axis_tready <= 0;

          ipi_vlan_prot_id <= 0;
          ipi_vlan_info_id <= 0;
          ipi_tdata_part0 <= 0;
          ipi_tkeep_part0 <= 0;
          ipi_tuser_part0 <= 0;
          ipi_tvalid_part0 <= 0;
          ipi_tlast_part0 <= 0;
          ipi_tdata_part1 <= 0;
          ipi_tkeep_part1 <= 0;
          ipi_tuser_part1 <= 0;
          ipi_tvalid_part1 <= 0;
          ipi_tlast_part1 <= 0;

          m_axis_0_tdata  <= 0;
          m_axis_0_tkeep  <= 0;
          m_axis_0_tuser  <= 0;
          m_axis_0_tvalid <= 0;
          m_axis_0_tlast  <= 0;
          //m_axis_0_tready
          m_axis_1_tdata  <= 0;
          m_axis_1_tkeep  <= 0;
          m_axis_1_tuser  <= 0;
          m_axis_1_tvalid <= 0;
          m_axis_1_tlast  <= 0;
          //m_axis_1_tready
          m_axis_2_tdata  <= 0;
          m_axis_2_tkeep  <= 0;
          m_axis_2_tuser  <= 0;
          m_axis_2_tvalid <= 0;
          m_axis_2_tlast  <= 0;
          //m_axis_2_tready
          m_axis_3_tdata  <= 0;
          m_axis_3_tkeep  <= 0;
          m_axis_3_tuser  <= 0;
          m_axis_3_tvalid <= 0;
          m_axis_3_tlast  <= 0;
          //m_axis_3_tready

          ipi_writepart <= 0;
          ipi_state = WAIT_PKT;
        end

        WAIT_PKT: begin
          s_axis_tready <= 1;
          if( ( s_axis_tvalid == 1 ) && ( s_axis_tlast == 0 ) ) begin
            ipi_tdata_part0  <= s_axis_tdata;
            ipi_tuser_part0  <= s_axis_tuser;
            ipi_tkeep_part0  <= s_axis_tkeep;
            ipi_tvalid_part0 <= s_axis_tvalid;
            ipi_tlast_part0  <= s_axis_tlast;
            ipi_vlan_prot_id <= vlan_prot_id;
            ipi_vlan_info_id <= vlan_info_id;
          end
          else if( ( s_axis_tvalid == 1 ) && ( s_axis_tlast == 1 ) ) begin
            ipi_tdata_part1  <= s_axis_tdata;
            ipi_tuser_part1  <= s_axis_tuser;
            ipi_tkeep_part1  <= s_axis_tkeep;
            ipi_tvalid_part1 <= s_axis_tvalid;
            ipi_tlast_part1  <= s_axis_tlast;
            if ( ipi_vlan_prot_id == 16'h0081 ) begin // 0000 0000 1000 0001
              ipi_state = WRITE_PKT_PART0;
              s_axis_tready <= 0;
            end
            else begin
              ipi_state = INI_PKT;
            end
          end
          else begin
            ipi_state = ipi_state;
          end
        end // case: WAIT_PKT

        WRITE_PKT_PART0: begin
          s_axis_tready <= 0;
          if ( ipi_vlan_info_id == 12'h001 ) begin // 0000 0000 0001
            if ( m_axis_0_tready == 1 ) begin
              m_axis_0_tdata  <= ipi_tdata_part0;
              m_axis_0_tuser  <= ipi_tuser_part0;
              m_axis_0_tkeep  <= ipi_tkeep_part0;
              m_axis_0_tvalid <= ipi_tvalid_part0;
              m_axis_0_tlast  <= ipi_tlast_part0;

              ipi_state = WRITE_PKT_PART1;
            end
          end
          else if ( ipi_vlan_info_id == 12'h002 ) begin // 0000 0000 0002
            if ( m_axis_1_tready == 1 ) begin
              m_axis_1_tdata  <= ipi_tdata_part0;
              m_axis_1_tuser  <= ipi_tuser_part0;
              m_axis_1_tkeep  <= ipi_tkeep_part0;
              m_axis_1_tvalid <= ipi_tvalid_part0;
              m_axis_1_tlast  <= ipi_tlast_part0;

              ipi_state = WRITE_PKT_PART1;
            end
          end
          else if ( ipi_vlan_info_id == 12'h003 ) begin // 0000 0000 0002
            if ( m_axis_2_tready == 1 ) begin
              m_axis_2_tdata  <= ipi_tdata_part0;
              m_axis_2_tuser  <= ipi_tuser_part0;
              m_axis_2_tkeep  <= ipi_tkeep_part0;
              m_axis_2_tvalid <= ipi_tvalid_part0;
              m_axis_2_tlast  <= ipi_tlast_part0;

              ipi_state = WRITE_PKT_PART1;
            end
          end
          else if ( ipi_vlan_info_id == 12'h004 ) begin // 0000 0000 0002
            if ( m_axis_3_tready == 1 ) begin
              m_axis_3_tdata  <= ipi_tdata_part0;
              m_axis_3_tuser  <= ipi_tuser_part0;
              m_axis_3_tkeep  <= ipi_tkeep_part0;
              m_axis_3_tvalid <= ipi_tvalid_part0;
              m_axis_3_tlast  <= ipi_tlast_part0;

              ipi_state = WRITE_PKT_PART1;
            end
          end
          else begin
            ipi_state = INI_PKT;
          end
        end // case: WRITE_PKT_PART0

        WRITE_PKT_PART1: begin
          s_axis_tready <= 0;
          if ( ipi_vlan_info_id == 12'h001 ) begin // 0000 0000 0001
            m_axis_0_tdata  <= ipi_tdata_part1;
            m_axis_0_tuser  <= ipi_tuser_part1;
            m_axis_0_tkeep  <= ipi_tkeep_part1;
            m_axis_0_tvalid <= ipi_tvalid_part1;
            m_axis_0_tlast  <= ipi_tlast_part1;
          end
          else if ( ipi_vlan_info_id == 12'h002 ) begin // 0000 0000 0002
            m_axis_1_tdata  <= ipi_tdata_part1;
            m_axis_1_tuser  <= ipi_tuser_part1;
            m_axis_1_tkeep  <= ipi_tkeep_part1;
            m_axis_1_tvalid <= ipi_tvalid_part1;
            m_axis_1_tlast  <= ipi_tlast_part1;
          end
          else if ( ipi_vlan_info_id == 12'h003 ) begin // 0000 0000 0002
            m_axis_2_tdata  <= ipi_tdata_part1;
            m_axis_2_tuser  <= ipi_tuser_part1;
            m_axis_2_tkeep  <= ipi_tkeep_part1;
            m_axis_2_tvalid <= ipi_tvalid_part1;
            m_axis_2_tlast  <= ipi_tlast_part1;
          end
          else if ( ipi_vlan_info_id == 12'h004 ) begin // 0000 0000 0002
            m_axis_3_tdata  <= ipi_tdata_part1;
            m_axis_3_tuser  <= ipi_tuser_part1;
            m_axis_3_tkeep  <= ipi_tkeep_part1;
            m_axis_3_tvalid <= ipi_tvalid_part1;
            m_axis_3_tlast  <= ipi_tlast_part1;
          end
          ipi_state = INI_PKT;
          ipi_writepart <= 0;
        end // case: WRITE_PKT_PART1

      endcase // case(ipi_state)
    end


  end // always @ (*)

endmodule
