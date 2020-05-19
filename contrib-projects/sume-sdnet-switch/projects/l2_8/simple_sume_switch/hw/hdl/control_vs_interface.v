//
// Copyright (c) 2019 Mateus Saquetti
// All rights reserved.
//
// This software was modified by Institute of Informatics of the Federal
// University of Rio Grande do Sul (INF-UFRGS)
//
//  File:
//        control_p4_interface_ip.v
//
//  Module:
//        control_p4_interface_ip
//
//  Description:
//        This is a simple module to manager signals between the virtual
//        switches and the control
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

module control_vs_interface_ip #
(
    parameter C_BASE_ADDRESS        = 32'h00000000,
    parameter C_S_AXI_DATA_WIDTH    = 32,
    parameter C_S_AXI_ADDR_WIDTH    = 32
)
(
    // AXI Lite Control ports
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     M_AXI_AWADDR,  // M_AXI_AWADDR = M_AXI_ARADDR = adress to write or read, always iqual
    input                                     M_AXI_AWVALID, // M_AXI_AWVALID = control signal to write
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     M_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   M_AXI_WSTRB,
    input                                     M_AXI_WVALID,
    input                                     M_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     M_AXI_ARADDR,  // M_AXI_AWADDR = M_AXI_ARADDR = adress to write or read, always iqual
    input                                     M_AXI_ARVALID, // M_AXI_ARVALID = control signal to read
    input                                     M_AXI_RREADY,
    output                                    M_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     M_AXI_RDATA,
    output     [1 : 0]                        M_AXI_RRESP,
    output                                    M_AXI_RVALID,
    output                                    M_AXI_WREADY,
    output     [1 : 0]                        M_AXI_BRESP,
    output                                    M_AXI_BVALID,
    output                                    M_AXI_AWREADY,
    // AXI Lite nf_sume_sdnet0 ports
    output     [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_vS0_AWADDR,
    output                                    S_AXI_vS0_AWVALID,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_vS0_WDATA,
    output     [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_vS0_WSTRB,
    output                                    S_AXI_vS0_WVALID,
    output                                    S_AXI_vS0_BREADY,
    output     [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_vS0_ARADDR,
    output                                    S_AXI_vS0_ARVALID,
    output                                    S_AXI_vS0_RREADY,
    input                                     S_AXI_vS0_ARREADY,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_vS0_RDATA,
    input      [1 : 0]                        S_AXI_vS0_RRESP,
    input                                     S_AXI_vS0_RVALID,
    input                                     S_AXI_vS0_WREADY,
    input      [1 : 0]                        S_AXI_vS0_BRESP,
    input                                     S_AXI_vS0_BVALID,
    input                                     S_AXI_vS0_AWREADY,
    // AXI Lite nf_sume_sdnet1 ports
    output     [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_vS1_AWADDR,
    output                                    S_AXI_vS1_AWVALID,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_vS1_WDATA,
    output     [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_vS1_WSTRB,
    output                                    S_AXI_vS1_WVALID,
    output                                    S_AXI_vS1_BREADY,
    output     [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_vS1_ARADDR,
    output                                    S_AXI_vS1_ARVALID,
    output                                    S_AXI_vS1_RREADY,
    input                                     S_AXI_vS1_ARREADY,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_vS1_RDATA,
    input      [1 : 0]                        S_AXI_vS1_RRESP,
    input                                     S_AXI_vS1_RVALID,
    input                                     S_AXI_vS1_WREADY,
    input      [1 : 0]                        S_AXI_vS1_BRESP,
    input                                     S_AXI_vS1_BVALID,
    input                                     S_AXI_vS1_AWREADY,
    // AXI Lite nf_sume_sdnet2 ports
    output     [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_vS2_AWADDR,
    output                                    S_AXI_vS2_AWVALID,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_vS2_WDATA,
    output     [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_vS2_WSTRB,
    output                                    S_AXI_vS2_WVALID,
    output                                    S_AXI_vS2_BREADY,
    output     [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_vS2_ARADDR,
    output                                    S_AXI_vS2_ARVALID,
    output                                    S_AXI_vS2_RREADY,
    input                                     S_AXI_vS2_ARREADY,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_vS2_RDATA,
    input      [1 : 0]                        S_AXI_vS2_RRESP,
    input                                     S_AXI_vS2_RVALID,
    input                                     S_AXI_vS2_WREADY,
    input      [1 : 0]                        S_AXI_vS2_BRESP,
    input                                     S_AXI_vS2_BVALID,
    input                                     S_AXI_vS2_AWREADY,
    // AXI Lite nf_sume_sdnet3 ports
    output     [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_vS3_AWADDR,
    output                                    S_AXI_vS3_AWVALID,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_vS3_WDATA,
    output     [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_vS3_WSTRB,
    output                                    S_AXI_vS3_WVALID,
    output                                    S_AXI_vS3_BREADY,
    output     [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_vS3_ARADDR,
    output                                    S_AXI_vS3_ARVALID,
    output                                    S_AXI_vS3_RREADY,
    input                                     S_AXI_vS3_ARREADY,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_vS3_RDATA,
    input      [1 : 0]                        S_AXI_vS3_RRESP,
    input                                     S_AXI_vS3_RVALID,
    input                                     S_AXI_vS3_WREADY,
    input      [1 : 0]                        S_AXI_vS3_BRESP,
    input                                     S_AXI_vS3_BVALID,
    input                                     S_AXI_vS3_AWREADY,
    // AXI Lite nf_sume_sdnet3 ports
    output     [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_vS4_AWADDR,
    output                                    S_AXI_vS4_AWVALID,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_vS4_WDATA,
    output     [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_vS4_WSTRB,
    output                                    S_AXI_vS4_WVALID,
    output                                    S_AXI_vS4_BREADY,
    output     [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_vS4_ARADDR,
    output                                    S_AXI_vS4_ARVALID,
    output                                    S_AXI_vS4_RREADY,
    input                                     S_AXI_vS4_ARREADY,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_vS4_RDATA,
    input      [1 : 0]                        S_AXI_vS4_RRESP,
    input                                     S_AXI_vS4_RVALID,
    input                                     S_AXI_vS4_WREADY,
    input      [1 : 0]                        S_AXI_vS4_BRESP,
    input                                     S_AXI_vS4_BVALID,
    input                                     S_AXI_vS4_AWREADY,
    // AXI Lite nf_sume_sdnet3 ports
    output     [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_vS5_AWADDR,
    output                                    S_AXI_vS5_AWVALID,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_vS5_WDATA,
    output     [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_vS5_WSTRB,
    output                                    S_AXI_vS5_WVALID,
    output                                    S_AXI_vS5_BREADY,
    output     [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_vS5_ARADDR,
    output                                    S_AXI_vS5_ARVALID,
    output                                    S_AXI_vS5_RREADY,
    input                                     S_AXI_vS5_ARREADY,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_vS5_RDATA,
    input      [1 : 0]                        S_AXI_vS5_RRESP,
    input                                     S_AXI_vS5_RVALID,
    input                                     S_AXI_vS5_WREADY,
    input      [1 : 0]                        S_AXI_vS5_BRESP,
    input                                     S_AXI_vS5_BVALID,
    input                                     S_AXI_vS5_AWREADY,
    // AXI Lite nf_sume_sdnet3 ports
    output     [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_vS6_AWADDR,
    output                                    S_AXI_vS6_AWVALID,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_vS6_WDATA,
    output     [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_vS6_WSTRB,
    output                                    S_AXI_vS6_WVALID,
    output                                    S_AXI_vS6_BREADY,
    output     [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_vS6_ARADDR,
    output                                    S_AXI_vS6_ARVALID,
    output                                    S_AXI_vS6_RREADY,
    input                                     S_AXI_vS6_ARREADY,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_vS6_RDATA,
    input      [1 : 0]                        S_AXI_vS6_RRESP,
    input                                     S_AXI_vS6_RVALID,
    input                                     S_AXI_vS6_WREADY,
    input      [1 : 0]                        S_AXI_vS6_BRESP,
    input                                     S_AXI_vS6_BVALID,
    input                                     S_AXI_vS6_AWREADY,
    // AXI Lite nf_sume_sdnet3 ports
    output     [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_vS7_AWADDR,
    output                                    S_AXI_vS7_AWVALID,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_vS7_WDATA,
    output     [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_vS7_WSTRB,
    output                                    S_AXI_vS7_WVALID,
    output                                    S_AXI_vS7_BREADY,
    output     [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_vS7_ARADDR,
    output                                    S_AXI_vS7_ARVALID,
    output                                    S_AXI_vS7_RREADY,
    input                                     S_AXI_vS7_ARREADY,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_vS7_RDATA,
    input      [1 : 0]                        S_AXI_vS7_RRESP,
    input                                     S_AXI_vS7_RVALID,
    input                                     S_AXI_vS7_WREADY,
    input      [1 : 0]                        S_AXI_vS7_BRESP,
    input                                     S_AXI_vS7_BVALID,
    input                                     S_AXI_vS7_AWREADY,
    // General ports
    input                                     M_AXI_ACLK,
    input                                     M_AXI_ARESETN

);

    // AXI4LITE signals
    // intern signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0]      axi_awaddr;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0]      axi_araddr;
    // extern signals
    reg                                 axi_awready;
    reg                                 axi_wready;
    reg [1 : 0]                         axi_bresp;
    reg                                 axi_bvalid;
    reg                                 axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0]      axi_rdata;
    reg [1 : 0]                         axi_rresp;
    reg                                 axi_rvalid;
    reg [C_S_AXI_DATA_WIDTH-1 : 0]      axi_rdata_0;
    reg [C_S_AXI_DATA_WIDTH-1 : 0]      axi_rdata_1;
    reg [C_S_AXI_DATA_WIDTH-1 : 0]      axi_rdata_2;
    reg [C_S_AXI_DATA_WIDTH-1 : 0]      axi_rdata_3;
    reg [C_S_AXI_DATA_WIDTH-1 : 0]      axi_rdata_4;
    reg [C_S_AXI_DATA_WIDTH-1 : 0]      axi_rdata_5;
    reg [C_S_AXI_DATA_WIDTH-1 : 0]      axi_rdata_6;
    reg [C_S_AXI_DATA_WIDTH-1 : 0]      axi_rdata_7;

    // Master Output Connections assignments
    assign M_AXI_AWREADY    = axi_awready;
    assign M_AXI_WREADY     = axi_wready;
    assign M_AXI_BRESP      = axi_bresp;
    assign M_AXI_BVALID     = axi_bvalid;

    assign M_AXI_ARREADY    = axi_arready;
    assign M_AXI_RDATA      = axi_rdata;
    assign M_AXI_RRESP      = axi_rresp;
    assign M_AXI_RVALID     = axi_rvalid;

    // Dummy Master Output Connections
    // assign M_AXI_AWREADY    = S_AXI_vS0_AWREADY; // write signal
    // assign M_AXI_WREADY     = S_AXI_vS0_WREADY; // write signal
    // assign M_AXI_BRESP      = S_AXI_vS0_BRESP;
    // assign M_AXI_BVALID     = S_AXI_vS0_BVALID; // write signal
    // assign M_AXI_ARREADY    = S_AXI_vS0_ARREADY; // read signal
    // assign M_AXI_RDATA      = S_AXI_vS0_RDATA;   // read signal
    // assign M_AXI_RRESP      = S_AXI_vS0_RRESP;
    // assign M_AXI_RVALID     = S_AXI_vS0_RVALID;  // read signal

    // Slaves Output Connections assignments
    assign S_AXI_vS0_AWADDR   = M_AXI_AWADDR;
    assign S_AXI_vS0_AWVALID  = M_AXI_AWVALID;
    assign S_AXI_vS0_WDATA    = M_AXI_WDATA;
    assign S_AXI_vS0_WSTRB    = M_AXI_WSTRB;
    assign S_AXI_vS0_WVALID   = M_AXI_WVALID;
    assign S_AXI_vS0_BREADY   = M_AXI_BREADY;
    assign S_AXI_vS0_ARADDR   = M_AXI_ARADDR;
    assign S_AXI_vS0_ARVALID  = M_AXI_ARVALID;
    assign S_AXI_vS0_RREADY   = M_AXI_RREADY;
    assign S_AXI_vS1_AWADDR   = M_AXI_AWADDR;
    assign S_AXI_vS1_AWVALID  = M_AXI_AWVALID;
    assign S_AXI_vS1_WDATA    = M_AXI_WDATA;
    assign S_AXI_vS1_WSTRB    = M_AXI_WSTRB;
    assign S_AXI_vS1_WVALID   = M_AXI_WVALID;
    assign S_AXI_vS1_BREADY   = M_AXI_BREADY;
    assign S_AXI_vS1_ARADDR   = M_AXI_ARADDR;
    assign S_AXI_vS1_ARVALID  = M_AXI_ARVALID;
    assign S_AXI_vS1_RREADY   = M_AXI_RREADY;
    assign S_AXI_vS2_AWADDR   = M_AXI_AWADDR;
    assign S_AXI_vS2_AWVALID  = M_AXI_AWVALID;
    assign S_AXI_vS2_WDATA    = M_AXI_WDATA;
    assign S_AXI_vS2_WSTRB    = M_AXI_WSTRB;
    assign S_AXI_vS2_WVALID   = M_AXI_WVALID;
    assign S_AXI_vS2_BREADY   = M_AXI_BREADY;
    assign S_AXI_vS2_ARADDR   = M_AXI_ARADDR;
    assign S_AXI_vS2_ARVALID  = M_AXI_ARVALID;
    assign S_AXI_vS2_RREADY   = M_AXI_RREADY;
    assign S_AXI_vS3_AWADDR   = M_AXI_AWADDR;
    assign S_AXI_vS3_AWVALID  = M_AXI_AWVALID;
    assign S_AXI_vS3_WDATA    = M_AXI_WDATA;
    assign S_AXI_vS3_WSTRB    = M_AXI_WSTRB;
    assign S_AXI_vS3_WVALID   = M_AXI_WVALID;
    assign S_AXI_vS3_BREADY   = M_AXI_BREADY;
    assign S_AXI_vS3_ARADDR   = M_AXI_ARADDR;
    assign S_AXI_vS3_ARVALID  = M_AXI_ARVALID;
    assign S_AXI_vS3_RREADY   = M_AXI_RREADY;
    assign S_AXI_vS4_AWADDR   = M_AXI_AWADDR;
    assign S_AXI_vS4_AWVALID  = M_AXI_AWVALID;
    assign S_AXI_vS4_WDATA    = M_AXI_WDATA;
    assign S_AXI_vS4_WSTRB    = M_AXI_WSTRB;
    assign S_AXI_vS4_WVALID   = M_AXI_WVALID;
    assign S_AXI_vS4_BREADY   = M_AXI_BREADY;
    assign S_AXI_vS4_ARADDR   = M_AXI_ARADDR;
    assign S_AXI_vS4_ARVALID  = M_AXI_ARVALID;
    assign S_AXI_vS4_RREADY   = M_AXI_RREADY;
    assign S_AXI_vS5_AWADDR   = M_AXI_AWADDR;
    assign S_AXI_vS5_AWVALID  = M_AXI_AWVALID;
    assign S_AXI_vS5_WDATA    = M_AXI_WDATA;
    assign S_AXI_vS5_WSTRB    = M_AXI_WSTRB;
    assign S_AXI_vS5_WVALID   = M_AXI_WVALID;
    assign S_AXI_vS5_BREADY   = M_AXI_BREADY;
    assign S_AXI_vS5_ARADDR   = M_AXI_ARADDR;
    assign S_AXI_vS5_ARVALID  = M_AXI_ARVALID;
    assign S_AXI_vS5_RREADY   = M_AXI_RREADY;
    assign S_AXI_vS6_AWADDR   = M_AXI_AWADDR;
    assign S_AXI_vS6_AWVALID  = M_AXI_AWVALID;
    assign S_AXI_vS6_WDATA    = M_AXI_WDATA;
    assign S_AXI_vS6_WSTRB    = M_AXI_WSTRB;
    assign S_AXI_vS6_WVALID   = M_AXI_WVALID;
    assign S_AXI_vS6_BREADY   = M_AXI_BREADY;
    assign S_AXI_vS6_ARADDR   = M_AXI_ARADDR;
    assign S_AXI_vS6_ARVALID  = M_AXI_ARVALID;
    assign S_AXI_vS6_RREADY   = M_AXI_RREADY;
    assign S_AXI_vS7_AWADDR   = M_AXI_AWADDR;
    assign S_AXI_vS7_AWVALID  = M_AXI_AWVALID;
    assign S_AXI_vS7_WDATA    = M_AXI_WDATA;
    assign S_AXI_vS7_WSTRB    = M_AXI_WSTRB;
    assign S_AXI_vS7_WVALID   = M_AXI_WVALID;
    assign S_AXI_vS7_BREADY   = M_AXI_BREADY;
    assign S_AXI_vS7_ARADDR   = M_AXI_ARADDR;
    assign S_AXI_vS7_ARVALID  = M_AXI_ARVALID;
    assign S_AXI_vS7_RREADY   = M_AXI_RREADY;


    // Implement axi_awready generation
    always @( posedge M_AXI_ACLK )
    begin
      if ( M_AXI_ARESETN == 1'b0 )
        begin
          axi_awready <= 1'b0;
        end
      else
        begin
          if (~axi_awready && M_AXI_AWVALID && M_AXI_WVALID && S_AXI_vS0_AWREADY)
            begin
              // slave is ready to accept write address when
              // there is a valid write address and write data
              // on the write address and data bus. This design
              // expects no outstanding transactions.
              axi_awready <= 1'b1;
            end
          else
            begin
              axi_awready <= 1'b0;
            end
        end
    end

    // Implement axi_awaddr latching
    always @( posedge M_AXI_ACLK )
    begin
      if ( M_AXI_ARESETN == 1'b0 )
        begin
          axi_awaddr <= 0;
        end
      else
        begin
          if (~axi_awready && M_AXI_AWVALID && M_AXI_WVALID)
            begin
              // Write Address latching
              axi_awaddr <= M_AXI_AWADDR ^ C_BASE_ADDRESS;
            end
        end
    end

    // Implement axi_wready generation
    always @( posedge M_AXI_ACLK )
    begin
      if ( M_AXI_ARESETN == 1'b0 )
        begin
          axi_wready <= 1'b0;
        end
      else
        begin
          if (~axi_wready && M_AXI_WVALID && M_AXI_AWVALID && S_AXI_vS0_WREADY)
            begin
              // slave is ready to accept write data when
              // there is a valid write address and write data
              // on the write address and data bus. This design
              // expects no outstanding transactions.
              axi_wready <= 1'b1;
            end
          else
            begin
              axi_wready <= 1'b0;
            end
        end
    end

    // Implement write response logic generation
    always @( posedge M_AXI_ACLK )
    begin
      if ( M_AXI_ARESETN == 1'b0 )
        begin
          axi_bvalid  <= 0;
          axi_bresp   <= 2'b0;
        end
      else
        begin
          if (axi_awready && M_AXI_AWVALID && ~axi_bvalid && axi_wready && M_AXI_WVALID)
            begin
              // indicates a valid write response is available
              axi_bvalid <= 1'b1;
              axi_bresp  <= 2'b0; // OKAY response
            end                   // work error responses in future
          else
            begin
              if (M_AXI_BREADY && axi_bvalid)
                //check if bready is asserted while bvalid is high)
                //(there is a possibility that bready is always asserted high)
                begin
                  axi_bvalid <= 1'b0;
                end
            end
        end
    end

    // Implement axi_arready generation
    always @( posedge M_AXI_ACLK )
    begin
      if ( M_AXI_ARESETN == 1'b0 )
        begin
          axi_arready <= 1'b0;
          axi_araddr  <= 32'b0;
        end
      else
        begin
          if (~axi_arready && M_AXI_ARVALID && S_AXI_vS0_ARREADY)
            begin
              // indicates that the slave has acceped the valid read address
              // Read address latching
              axi_arready <= 1'b1;
              axi_araddr  <= M_AXI_ARADDR ^ C_BASE_ADDRESS;
            end
          else
            begin
              axi_arready <= 1'b0;
            end
        end
    end


    // Implement axi_rvalid generation
    always @( posedge M_AXI_ACLK )
    begin
      if ( M_AXI_ARESETN == 1'b0 )
        begin
          axi_rvalid <= 0;
          axi_rresp  <= 0;
        end
      else
        begin
          if (axi_arready && M_AXI_ARVALID && ~axi_rvalid)
            begin
              // Valid read data is available at the read data bus
              axi_rvalid <= 1'b1;
              axi_rresp  <= 2'b0; // OKAY response
            end
          else if (axi_rvalid && M_AXI_RREADY)
            begin
              // Read data is accepted by the master
              axi_rvalid <= 1'b0;
            end
        end
    end

    // Output register or memory read data
    always @( posedge M_AXI_ACLK )
    begin
      if ( M_AXI_ARESETN == 1'b0 )
        begin
          axi_rdata_0  <= 0;
          axi_rdata_1  <= 0;
          axi_rdata_2  <= 0;
          axi_rdata_3  <= 0;
          axi_rdata_4  <= 0;
          axi_rdata_5  <= 0;
          axi_rdata_6  <= 0;
          axi_rdata_7  <= 0;
        end
      else
        begin
          // When there is a valid read address (M_AXI_ARVALID) with
          // acceptance of read address by the slave (axi_arready),
          // output the read dada
          if (S_AXI_vS0_RDATA != 32'h0)
            begin
              axi_rdata_0 <= S_AXI_vS0_RDATA;
            end
          if (S_AXI_vS1_RDATA != 32'h0)
            begin
              axi_rdata_1 <= S_AXI_vS1_RDATA;
            end
          if (S_AXI_vS2_RDATA != 32'h0)
            begin
              axi_rdata_2 <= S_AXI_vS2_RDATA;
            end
          if (S_AXI_vS3_RDATA != 32'h0)
            begin
              axi_rdata_3 <= S_AXI_vS3_RDATA;
            end
          if (S_AXI_vS4_RDATA != 32'h0)
            begin
              axi_rdata_4 <= S_AXI_vS4_RDATA;
            end
          if (S_AXI_vS5_RDATA != 32'h0)
            begin
              axi_rdata_5 <= S_AXI_vS5_RDATA;
            end
          if (S_AXI_vS6_RDATA != 32'h0)
            begin
              axi_rdata_6 <= S_AXI_vS6_RDATA;
            end
          if (S_AXI_vS7_RDATA != 32'h0)
            begin
              axi_rdata_7 <= S_AXI_vS7_RDATA;
            end
        end
    end

    // Output register or memory read data
    always @( posedge M_AXI_ACLK )
    begin
      if ( M_AXI_ARESETN == 1'b0 )
        begin
          axi_rdata  <= 0;
        end
      else
        begin
          // When there is a valid read address (M_AXI_ARVALID) with
          // acceptance of read address by the slave (axi_arready),
          // output the read dada
          if (S_AXI_vS7_RDATA != 32'h0)
          begin
              axi_rdata <= S_AXI_vS7_RDATA;     // register read data /* some new changes here */
          end
          else if (S_AXI_vS6_RDATA != 32'h0)
          begin
              axi_rdata <= S_AXI_vS6_RDATA;     // register read data /* some new changes here */
          end
          else if (S_AXI_vS5_RDATA != 32'h0)
          begin
              axi_rdata <= S_AXI_vS5_RDATA;     // register read data /* some new changes here */
          end
          else if (S_AXI_vS4_RDATA != 32'h0)
          begin
              axi_rdata <= S_AXI_vS4_RDATA;     // register read data /* some new changes here */
          end
          else if (S_AXI_vS3_RDATA != 32'h0)
          begin
              axi_rdata <= S_AXI_vS3_RDATA;     // register read data /* some new changes here */
          end
          else if (S_AXI_vS2_RDATA != 32'h0)
          begin
              axi_rdata <= S_AXI_vS2_RDATA;     // register read data /* some new changes here */
          end
          else if (S_AXI_vS1_RDATA != 32'h0)
          begin
              axi_rdata <= S_AXI_vS1_RDATA;     // register read data /* some new changes here */
          end
          else if (S_AXI_vS0_RDATA != 32'h0)
          begin
              axi_rdata <= S_AXI_vS0_RDATA;     // register read data /* some new changes here */
          end
          else
          begin
              axi_rdata <= 32'h0;
          end
        end
    end

endmodule
