//
// Copyright (c) 2019 Mateus Saquetti
// All rights reserved.
//
// This software was modified by Institute of Informatics of the Federal
// University of Rio Grande do Sul (INF-UFRGS)
//
// Description:
//        Created to run in P4VBox architecture
//
// @NETFPGA_LICENSE_HEADER_START@
//
// Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
// license agreements.  See the NOTICE file distributed with this work for
// additional information regarding copyright ownership.  NetFPGA licenses this
// file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
// "License"); you may not use this file except in compliance with the
// License.  You may obtain a copy of the License at:
//
//   http://www.netfpga-cic.org
//
// Unless required by applicable law or agreed to in writing, Work distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@
//


`timescale 1ns / 1ps

module input_vs_interface
#(
  //Slave AXI parameters
  parameter C_S_AXI_DATA_WIDTH    = 32,
  parameter C_S_AXI_ADDR_WIDTH    = 32,
  parameter C_BASEADDR            = 32'h00000000,
  // Master AXI Stream Data Width
  parameter C_M_AXIS_DATA_WIDTH   = 256,
  parameter C_S_AXIS_DATA_WIDTH   = 256,
  parameter C_M_AXIS_TUSER_WIDTH  = 128,
  parameter C_S_AXIS_TUSER_WIDTH  = 128
  // parameter NUM_QUEUES=5,
  // parameter DIGEST_WIDTH =80
)
(
  // Global Ports
  input                                                           axis_aclk,
  input                                                           axis_resetn,
  // Master Stream Ports (interface to vS0 ... vSN)
  output reg [C_M_AXIS_DATA_WIDTH - 1:0]                          m_axis_0_tdata,
  output reg [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_0_tkeep,
  output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_0_tuser,
  output reg                                                      m_axis_0_tvalid,
  output reg                                                      m_axis_0_tlast,
  input                                                           m_axis_0_tready,

  output reg [C_M_AXIS_DATA_WIDTH - 1:0]                          m_axis_1_tdata,
  output reg [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_1_tkeep,
  output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_1_tuser,
  output reg                                                      m_axis_1_tvalid,
  output reg                                                      m_axis_1_tlast,
  input                                                           m_axis_1_tready,

  output reg [C_M_AXIS_DATA_WIDTH - 1:0]                          m_axis_2_tdata,
  output reg [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_2_tkeep,
  output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_2_tuser,
  output reg                                                      m_axis_2_tvalid,
  output reg                                                      m_axis_2_tlast,
  input                                                           m_axis_2_tready,

  output reg [C_M_AXIS_DATA_WIDTH - 1:0]                          m_axis_3_tdata,
  output reg [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_3_tkeep,
  output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_3_tuser,
  output reg                                                      m_axis_3_tvalid,
  output reg                                                      m_axis_3_tlast,
  input                                                           m_axis_3_tready,
  // Slave Stream Ports (interface to RX queues)
  input [C_S_AXIS_DATA_WIDTH - 1:0]                               s_axis_0_tdata,
  input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                       s_axis_0_tkeep,
  input [C_S_AXIS_TUSER_WIDTH-1:0]                                s_axis_0_tuser,
  input                                                           s_axis_0_tvalid,
  output                                                          s_axis_0_tready,
  input                                                           s_axis_0_tlast,

  input [C_S_AXIS_DATA_WIDTH - 1:0]                               s_axis_1_tdata,
  input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                       s_axis_1_tkeep,
  input [C_S_AXIS_TUSER_WIDTH-1:0]                                s_axis_1_tuser,
  input                                                           s_axis_1_tvalid,
  output                                                          s_axis_1_tready,
  input                                                           s_axis_1_tlast,

  input [C_S_AXIS_DATA_WIDTH - 1:0]                               s_axis_2_tdata,
  input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                       s_axis_2_tkeep,
  input [C_S_AXIS_TUSER_WIDTH-1:0]                                s_axis_2_tuser,
  input                                                           s_axis_2_tvalid,
  output                                                          s_axis_2_tready,
  input                                                           s_axis_2_tlast,

  input [C_S_AXIS_DATA_WIDTH - 1:0]                               s_axis_3_tdata,
  input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                       s_axis_3_tkeep,
  input [C_S_AXIS_TUSER_WIDTH-1:0]                                s_axis_3_tuser,
  input                                                           s_axis_3_tvalid,
  output                                                          s_axis_3_tready,
  input                                                           s_axis_3_tlast,

  input [C_S_AXIS_DATA_WIDTH - 1:0]                               s_axis_4_tdata,
  input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                       s_axis_4_tkeep,
  input [C_S_AXIS_TUSER_WIDTH-1:0]                                s_axis_4_tuser,
  input                                                           s_axis_4_tvalid,
  output                                                          s_axis_4_tready,
  input                                                           s_axis_4_tlast,
  // Slave AXI Ports
  input                                                           S_AXI_ACLK,
  input                                                           S_AXI_ARESETN,
  input      [C_S_AXI_ADDR_WIDTH-1 : 0]                           S_AXI_AWADDR,
  input                                                           S_AXI_AWVALID,
  input      [C_S_AXI_DATA_WIDTH-1 : 0]                           S_AXI_WDATA,
  input      [C_S_AXI_DATA_WIDTH/8-1 : 0]                         S_AXI_WSTRB,
  input                                                           S_AXI_WVALID,
  input                                                           S_AXI_BREADY,
  input      [C_S_AXI_ADDR_WIDTH-1 : 0]                           S_AXI_ARADDR,
  input                                                           S_AXI_ARVALID,
  input                                                           S_AXI_RREADY,
  output                                                          S_AXI_ARREADY,
  output     [C_S_AXI_DATA_WIDTH-1 : 0]                           S_AXI_RDATA,
  output     [1 : 0]                                              S_AXI_RRESP,
  output                                                          S_AXI_RVALID,
  output                                                          S_AXI_WREADY,
  output     [1 :0]                                               S_AXI_BRESP,
  output                                                          S_AXI_BVALID,
  output                                                          S_AXI_AWREADY,

  // stats
   output reg                                                     pkt_fwd
);

  // ------------ Internal Params --------

  localparam VLAN_WIDTH=32;
  localparam VLAN_WIDTH_ID=12;
  localparam VLAN_THRESHOLD_BGN=128;
  localparam VLAN_THRESHOLD_END=96;

  localparam NUM_STATES=3;
  localparam WAIT_PKT=0;
  localparam WRITE_PKT_BEG=1;
  localparam WRITE_PKT_END=2;
  localparam END_PKT=3;

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

  wire [C_M_AXIS_DATA_WIDTH - 1:0]          m_axis_tdata;
  wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]  m_axis_tkeep;
  wire [C_M_AXIS_TUSER_WIDTH-1:0]           m_axis_tuser;
  wire                                      m_axis_tvalid;
  wire                                      m_axis_tlast;

  wire [VLAN_WIDTH - 1:0]                   vlan_tdata;
  wire [(( VLAN_WIDTH/2 )) - 1:0]           vlan_prot_id;
  wire [(( VLAN_WIDTH/2 )) - 1:0]           vlan_info;
  wire [(( VLAN_WIDTH_ID/4 )) - 1:0]        vlan_info_prio;
  wire                                      vlan_info_drop;
  wire [VLAN_WIDTH_ID -1 :0]                vlan_info_id;

  reg                                       m_axis_tready;
  reg [NUM_STATES-1:0]                      ipi_state;
  reg                                       ipi_end_pkt;
  reg [(( VLAN_WIDTH/2 )) - 1:0]            ipi_vlan_prot_id;
  reg [VLAN_WIDTH_ID -1 :0]                 ipi_vlan_info_id;

  reg [C_S_AXIS_DATA_WIDTH - 1:0]           ipi_tdata;
  reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]   ipi_tkeep;
  reg [C_M_AXIS_TUSER_WIDTH-1:0]            ipi_tuser;
  reg                                       ipi_tvalid;
  reg                                       ipi_tlast;
  reg [C_S_AXIS_DATA_WIDTH - 1:0]           ipi_tdata_next;
  reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]   ipi_tkeep_next;
  reg [C_M_AXIS_TUSER_WIDTH-1:0]            ipi_tuser_next;
  reg                                       ipi_tvalid_next;
  reg                                       ipi_tlast_next;

  // ------------- Logic ------------

  assign vlan_tdata = m_axis_tdata [VLAN_THRESHOLD_BGN - 1:VLAN_THRESHOLD_END];
  assign vlan_prot_id = vlan_tdata [((VLAN_WIDTH/2)) - 1:0];
  assign vlan_info = vlan_tdata [VLAN_WIDTH - 1:(( VLAN_WIDTH/2 ))];
  assign vlan_info_prio = vlan_info [7:5];
  assign vlan_info_drop = vlan_info [4];
  assign vlan_info_id = {vlan_info[3:0], vlan_info[15: 8]};


  always @(posedge axis_aclk) begin
    if( axis_resetn ) begin
      case( ipi_state )

        WAIT_PKT: begin
          m_axis_tready <= 1;

          ipi_end_pkt <= 0;
          ipi_vlan_prot_id <= vlan_prot_id;
          ipi_vlan_info_id <= vlan_info_id;

          ipi_tdata  <= m_axis_tdata;
          ipi_tuser  <= m_axis_tuser;
          ipi_tkeep  <= m_axis_tkeep;
          ipi_tvalid <= m_axis_tvalid;
          ipi_tlast  <= m_axis_tlast;
          ipi_tdata_next <= 0;
          ipi_tkeep_next <= 0;
          ipi_tuser_next <= 0;
          ipi_tvalid_next<= 0;
          ipi_tlast_next <= 0;

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

          if ( m_axis_tvalid ) begin
            ipi_state = WRITE_PKT_BEG;
          end
          else begin
            ipi_state = WAIT_PKT;
          end
        end

        WRITE_PKT_BEG: begin
          m_axis_tready <= 1;

          ipi_tdata_next  <= m_axis_tdata;
          ipi_tuser_next  <= m_axis_tuser;
          ipi_tkeep_next  <= m_axis_tkeep;
          ipi_tvalid_next <= m_axis_tvalid;
          ipi_tlast_next  <= m_axis_tlast;

          if ( ipi_vlan_prot_id == 16'h0081 ) begin // 0000 0000 1000 0001
            ipi_state = WRITE_PKT_END;
            if ( ipi_vlan_info_id == 12'h001 ) begin // 0000 0000 0001
              if ( m_axis_0_tready == 1 ) begin
                m_axis_0_tdata  <= ipi_tdata;
                m_axis_0_tuser  <= ipi_tuser;
                m_axis_0_tkeep  <= ipi_tkeep;
                m_axis_0_tvalid <= ipi_tvalid;
                m_axis_0_tlast  <= ipi_tlast;
              end
            end
            else if ( ipi_vlan_info_id == 12'h002 ) begin // 0000 0000 0002
              if ( m_axis_1_tready == 1 ) begin
                m_axis_1_tdata  <= ipi_tdata;
                m_axis_1_tuser  <= ipi_tuser;
                m_axis_1_tkeep  <= ipi_tkeep;
                m_axis_1_tvalid <= ipi_tvalid;
                m_axis_1_tlast  <= ipi_tlast;
              end
            end
            else if ( ipi_vlan_info_id == 12'h003 ) begin // 0000 0000 0003
              if ( m_axis_2_tready == 1 ) begin
                m_axis_2_tdata  <= ipi_tdata;
                m_axis_2_tuser  <= ipi_tuser;
                m_axis_2_tkeep  <= ipi_tkeep;
                m_axis_2_tvalid <= ipi_tvalid;
                m_axis_2_tlast  <= ipi_tlast;
              end
            end
            else if ( ipi_vlan_info_id == 12'h004 ) begin // 0000 0000 0004
              if ( m_axis_3_tready == 1 ) begin
                m_axis_3_tdata  <= ipi_tdata;
                m_axis_3_tuser  <= ipi_tuser;
                m_axis_3_tkeep  <= ipi_tkeep;
                m_axis_3_tvalid <= ipi_tvalid;
                m_axis_3_tlast  <= ipi_tlast;
              end
            end
            else begin
              ipi_state = WAIT_PKT;
            end
          end
          else begin
            ipi_state = WAIT_PKT;
          end
          if ( m_axis_tlast ) begin
            ipi_state = WRITE_PKT_END;
            m_axis_tready <= 0;
            ipi_end_pkt <= 1;
          end
          else begin
            if( ipi_end_pkt ) begin
              ipi_state = WAIT_PKT;
              m_axis_tready <= 1;
            end
          end

        end // case: WRITE_PKT_BEG

        WRITE_PKT_END: begin
          m_axis_tready <= 1;

          ipi_tdata <= m_axis_tdata;
          ipi_tuser <= m_axis_tuser;
          ipi_tkeep <= m_axis_tkeep;
          ipi_tvalid <= m_axis_tvalid;
          ipi_tlast <= m_axis_tlast;


          ipi_state = WRITE_PKT_BEG;
          if ( ipi_vlan_info_id == 12'h001 ) begin // 0000 0000 0001
            if ( m_axis_0_tready == 1 ) begin
              m_axis_0_tdata  <= ipi_tdata_next;
              m_axis_0_tuser  <= ipi_tuser_next;
              m_axis_0_tkeep  <= ipi_tkeep_next;
              m_axis_0_tvalid <= ipi_tvalid_next;
              m_axis_0_tlast  <= ipi_tlast_next;
            end
          end
          else if ( ipi_vlan_info_id == 12'h002 ) begin // 0000 0000 0002
            if ( m_axis_1_tready == 1 ) begin
              m_axis_1_tdata  <= ipi_tdata_next;
              m_axis_1_tuser  <= ipi_tuser_next;
              m_axis_1_tkeep  <= ipi_tkeep_next;
              m_axis_1_tvalid <= ipi_tvalid_next;
              m_axis_1_tlast  <= ipi_tlast_next;
            end
          end
          else if ( ipi_vlan_info_id == 12'h003 ) begin // 0000 0000 0002
            if ( m_axis_2_tready == 1 ) begin
              m_axis_2_tdata  <= ipi_tdata_next;
              m_axis_2_tuser  <= ipi_tuser_next;
              m_axis_2_tkeep  <= ipi_tkeep_next;
              m_axis_2_tvalid <= ipi_tvalid_next;
              m_axis_2_tlast  <= ipi_tlast_next;
            end
          end
          else if ( ipi_vlan_info_id == 12'h004 ) begin // 0000 0000 0002
            if ( m_axis_3_tready == 1 ) begin
              m_axis_3_tdata  <= ipi_tdata_next;
              m_axis_3_tuser  <= ipi_tuser_next;
              m_axis_3_tkeep  <= ipi_tkeep_next;
              m_axis_3_tvalid <= ipi_tvalid_next;
              m_axis_3_tlast  <= ipi_tlast_next;
            end
          end
          else begin
            ipi_state = WAIT_PKT;
          end
          if ( m_axis_tlast ) begin
            ipi_state = WRITE_PKT_BEG;
            m_axis_tready <= 0;
            ipi_end_pkt <= 1;
          end
          else begin
            if( ipi_end_pkt ) begin
              ipi_state = WAIT_PKT;
              m_axis_tready <= 1;
            end
          end
        end // case: WRITE_PKT_END

      endcase // case(ipi_state)
    end
    else begin // if ( axis_resetn )
      m_axis_tready <= 0;

      ipi_vlan_prot_id <= 0;
      ipi_vlan_info_id <= 0;
      ipi_tdata <= 0;
      ipi_tkeep <= 0;
      ipi_tuser <= 0;
      ipi_tvalid <= 0;
      ipi_tlast <= 0;
      ipi_tdata_next <= 0;
      ipi_tkeep_next <= 0;
      ipi_tuser_next <= 0;
      ipi_tvalid_next <= 0;
      ipi_tlast_next <= 0;

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

      ipi_end_pkt <= 0;
      ipi_state = WAIT_PKT;
    end // if ( axis_resetn )

  end // always @(posedge axis_aclk)

  //Input Arbiter IP
    input_arbiter_drr_ip
  input_arbiter_drr_v1_0 (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),
    // input_arbiter->input_p4_interface
    .m_axis_tdata (m_axis_tdata),
    .m_axis_tkeep (m_axis_tkeep),
    .m_axis_tuser (m_axis_tuser),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tlast (m_axis_tlast),
    // RX queues->input_arbiter
    .s_axis_0_tdata (s_axis_0_tdata),
    .s_axis_0_tkeep (s_axis_0_tkeep),
    .s_axis_0_tuser (s_axis_0_tuser),
    .s_axis_0_tvalid(s_axis_0_tvalid),
    .s_axis_0_tready(s_axis_0_tready),
    .s_axis_0_tlast (s_axis_0_tlast),

    .s_axis_1_tdata (s_axis_1_tdata),
    .s_axis_1_tkeep (s_axis_1_tkeep),
    .s_axis_1_tuser (s_axis_1_tuser),
    .s_axis_1_tvalid(s_axis_1_tvalid),
    .s_axis_1_tready(s_axis_1_tready),
    .s_axis_1_tlast (s_axis_1_tlast),

    .s_axis_2_tdata (s_axis_2_tdata),
    .s_axis_2_tkeep (s_axis_2_tkeep),
    .s_axis_2_tuser (s_axis_2_tuser),
    .s_axis_2_tvalid(s_axis_2_tvalid),
    .s_axis_2_tready(s_axis_2_tready),
    .s_axis_2_tlast (s_axis_2_tlast),

    .s_axis_3_tdata (s_axis_3_tdata),
    .s_axis_3_tkeep (s_axis_3_tkeep),
    .s_axis_3_tuser (s_axis_3_tuser),
    .s_axis_3_tvalid(s_axis_3_tvalid),
    .s_axis_3_tready(s_axis_3_tready),
    .s_axis_3_tlast (s_axis_3_tlast),

    .s_axis_4_tdata (s_axis_4_tdata),
    .s_axis_4_tkeep (s_axis_4_tkeep),
    .s_axis_4_tuser (s_axis_4_tuser),
    .s_axis_4_tvalid(s_axis_4_tvalid),
    .s_axis_4_tready(s_axis_4_tready),
    .s_axis_4_tlast (s_axis_4_tlast),
    // Control
    .S_AXI_AWADDR(S_AXI_AWADDR),
    .S_AXI_AWVALID(S_AXI_AWVALID),
    .S_AXI_WDATA(S_AXI_WDATA),
    .S_AXI_WSTRB(S_AXI_WSTRB),
    .S_AXI_WVALID(S_AXI_WVALID),
    .S_AXI_BREADY(S_AXI_BREADY),
    .S_AXI_ARADDR(S_AXI_ARADDR),
    .S_AXI_ARVALID(S_AXI_ARVALID),
    .S_AXI_RREADY(S_AXI_RREADY),
    .S_AXI_ARREADY(S_AXI_ARREADY),
    .S_AXI_RDATA(S_AXI_RDATA),
    .S_AXI_RRESP(S_AXI_RRESP),
    .S_AXI_RVALID(S_AXI_RVALID),
    .S_AXI_WREADY(S_AXI_WREADY),
    .S_AXI_BRESP(S_AXI_BRESP),
    .S_AXI_BVALID(S_AXI_BVALID),
    .S_AXI_AWREADY(S_AXI_AWREADY),
    .S_AXI_ACLK (S_AXI_ACLK),
    .S_AXI_ARESETN(S_AXI_ARESETN),
    .pkt_fwd()
  );

endmodule
