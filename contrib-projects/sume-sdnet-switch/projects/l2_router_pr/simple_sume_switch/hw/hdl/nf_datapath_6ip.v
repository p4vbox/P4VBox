`timescale 1ns / 1ps
//-
// Copyright (c) 2015 Noa Zilberman
// All rights reserved.
//
// This software was developed by Stanford University and the University of Cambridge Computer Laboratory
// under National Science Foundation under Grant No. CNS-0855268,
// the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
// by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
// as part of the DARPA MRC research programme.
//
//  File:
//        nf_datapath.v
//
//  Module:
//        nf_datapath
//
//  Author: Noa Zilberman
//
//  Description:
//        NetFPGA user data path wrapper, wrapping input arbiter, output port lookup and output queues
//
// Copyright (c) 2019 Mateus Saquetti
// All rights reserved.
//
// This software was modified by Institute of Informatics of the Federal
// University of Rio Grande do Sul (INF-UFRGS)
//
// Description:
//        Adapted to run in P4VBox architecture
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


module nf_datapath #(
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
    //Datapath clock
    input                                     axis_aclk,
    input                                     axis_resetn,
    //Registers clock
    input                                     axi_aclk,
    input                                     axi_resetn,

    // Slave AXI Ports
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S0_AXI_AWADDR,
    input                                     S0_AXI_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S0_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S0_AXI_WSTRB,
    input                                     S0_AXI_WVALID,
    input                                     S0_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S0_AXI_ARADDR,
    input                                     S0_AXI_ARVALID,
    input                                     S0_AXI_RREADY,
    output                                    S0_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S0_AXI_RDATA,
    output     [1 : 0]                        S0_AXI_RRESP,
    output                                    S0_AXI_RVALID,
    output                                    S0_AXI_WREADY,
    output     [1 :0]                         S0_AXI_BRESP,
    output                                    S0_AXI_BVALID,
    output                                    S0_AXI_AWREADY,

    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S1_AXI_AWADDR,
    input                                     S1_AXI_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S1_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S1_AXI_WSTRB,
    input                                     S1_AXI_WVALID,
    input                                     S1_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S1_AXI_ARADDR,
    input                                     S1_AXI_ARVALID,
    input                                     S1_AXI_RREADY,
    output                                    S1_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S1_AXI_RDATA,
    output     [1 : 0]                        S1_AXI_RRESP,
    output                                    S1_AXI_RVALID,
    output                                    S1_AXI_WREADY,
    output     [1 :0]                         S1_AXI_BRESP,
    output                                    S1_AXI_BVALID,
    output                                    S1_AXI_AWREADY,

    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S2_AXI_AWADDR,
    input                                     S2_AXI_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S2_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S2_AXI_WSTRB,
    input                                     S2_AXI_WVALID,
    input                                     S2_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S2_AXI_ARADDR,
    input                                     S2_AXI_ARVALID,
    input                                     S2_AXI_RREADY,
    output                                    S2_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S2_AXI_RDATA,
    output     [1 : 0]                        S2_AXI_RRESP,
    output                                    S2_AXI_RVALID,
    output                                    S2_AXI_WREADY,
    output     [1 :0]                         S2_AXI_BRESP,
    output                                    S2_AXI_BVALID,
    output                                    S2_AXI_AWREADY,


    // Slave Stream Ports (interface from Rx queues)
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_0_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_0_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_0_tuser,
    input                                     s_axis_0_tvalid,
    output                                    s_axis_0_tready,
    input                                     s_axis_0_tlast,
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_1_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_1_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_1_tuser,
    input                                     s_axis_1_tvalid,
    output                                    s_axis_1_tready,
    input                                     s_axis_1_tlast,
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_2_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_2_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_2_tuser,
    input                                     s_axis_2_tvalid,
    output                                    s_axis_2_tready,
    input                                     s_axis_2_tlast,
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_3_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_3_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_3_tuser,
    input                                     s_axis_3_tvalid,
    output                                    s_axis_3_tready,
    input                                     s_axis_3_tlast,
    input [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_4_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_4_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0]          s_axis_4_tuser,
    input                                     s_axis_4_tvalid,
    output                                    s_axis_4_tready,
    input                                     s_axis_4_tlast,


    // Master Stream Ports (interface to TX queues)
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_0_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_0_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_0_tuser,
    output                                     m_axis_0_tvalid,
    input                                      m_axis_0_tready,
    output                                     m_axis_0_tlast,
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_1_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_1_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_1_tuser,
    output                                     m_axis_1_tvalid,
    input                                      m_axis_1_tready,
    output                                     m_axis_1_tlast,
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_2_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_2_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_2_tuser,
    output                                     m_axis_2_tvalid,
    input                                      m_axis_2_tready,
    output                                     m_axis_2_tlast,
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_3_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_3_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_3_tuser,
    output                                     m_axis_3_tvalid,
    input                                      m_axis_3_tready,
    output                                     m_axis_3_tlast,
    output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_4_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_4_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_4_tuser,
    output                                     m_axis_4_tvalid,
    input                                      m_axis_4_tready,
    output                                     m_axis_4_tlast
    );

    // ------------ Internal Params --------
    localparam C_AXIS_TUSER_DIGEST_WIDTH = 304;
    localparam Q_SIZE_WIDTH = 16;

    // ------------ Internal Connectivity --------
    // Buses from IvSI to each vS instance
    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_vS0_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_vS0_tkeep;
    (* mark_debug = "true" *) wire [C_M_AXIS_TUSER_WIDTH-1:0]          s_axis_vS0_tuser;
    (* mark_debug = "true" *) wire                                     s_axis_vS0_tvalid;
    (* mark_debug = "true" *) wire                                     s_axis_vS0_tready;
    (* mark_debug = "true" *) wire                                     s_axis_vS0_tlast;

    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_vS1_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_vS1_tkeep;
    (* mark_debug = "true" *) wire [C_M_AXIS_TUSER_WIDTH-1:0]          s_axis_vS1_tuser;
    (* mark_debug = "true" *) wire                                     s_axis_vS1_tvalid;
    (* mark_debug = "true" *) wire                                     s_axis_vS1_tready;
    (* mark_debug = "true" *) wire                                     s_axis_vS1_tlast;

    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_vS2_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_vS2_tkeep;
    (* mark_debug = "true" *) wire [C_M_AXIS_TUSER_WIDTH-1:0]          s_axis_vS2_tuser;
    (* mark_debug = "true" *) wire                                     s_axis_vS2_tvalid;
    (* mark_debug = "true" *) wire                                     s_axis_vS2_tready;
    (* mark_debug = "true" *) wire                                     s_axis_vS2_tlast;

    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_vS3_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_vS3_tkeep;
    (* mark_debug = "true" *) wire [C_M_AXIS_TUSER_WIDTH-1:0]          s_axis_vS3_tuser;
    (* mark_debug = "true" *) wire                                     s_axis_vS3_tvalid;
    (* mark_debug = "true" *) wire                                     s_axis_vS3_tready;
    (* mark_debug = "true" *) wire                                     s_axis_vS3_tlast;

    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_vS4_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_vS4_tkeep;
    (* mark_debug = "true" *) wire [C_M_AXIS_TUSER_WIDTH-1:0]          s_axis_vS4_tuser;
    (* mark_debug = "true" *) wire                                     s_axis_vS4_tvalid;
    (* mark_debug = "true" *) wire                                     s_axis_vS4_tready;
    (* mark_debug = "true" *) wire                                     s_axis_vS4_tlast;

    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_vS5_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_vS5_tkeep;
    (* mark_debug = "true" *) wire [C_M_AXIS_TUSER_WIDTH-1:0]          s_axis_vS5_tuser;
    (* mark_debug = "true" *) wire                                     s_axis_vS5_tvalid;
    (* mark_debug = "true" *) wire                                     s_axis_vS5_tready;
    (* mark_debug = "true" *) wire                                     s_axis_vS5_tlast;

    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_vS6_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_vS6_tkeep;
    (* mark_debug = "true" *) wire [C_M_AXIS_TUSER_WIDTH-1:0]          s_axis_vS6_tuser;
    (* mark_debug = "true" *) wire                                     s_axis_vS6_tvalid;
    (* mark_debug = "true" *) wire                                     s_axis_vS6_tready;
    (* mark_debug = "true" *) wire                                     s_axis_vS6_tlast;

    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_vS7_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_vS7_tkeep;
    (* mark_debug = "true" *) wire [C_M_AXIS_TUSER_WIDTH-1:0]          s_axis_vS7_tuser;
    (* mark_debug = "true" *) wire                                     s_axis_vS7_tvalid;
    (* mark_debug = "true" *) wire                                     s_axis_vS7_tready;
    (* mark_debug = "true" *) wire                                     s_axis_vS7_tlast;
    // Buses from vS instances to OvSI
    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_vS0_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_vS0_tkeep;
    (* mark_debug = "true" *) wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     m_axis_vS0_tuser;
    (* mark_debug = "true" *) wire                                     m_axis_vS0_tvalid;
    (* mark_debug = "true" *) wire                                     m_axis_vS0_tready;
    (* mark_debug = "true" *) wire                                     m_axis_vS0_tlast;

    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_vS1_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_vS1_tkeep;
    (* mark_debug = "true" *) wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     m_axis_vS1_tuser;
    (* mark_debug = "true" *) wire                                     m_axis_vS1_tvalid;
    (* mark_debug = "true" *) wire                                     m_axis_vS1_tready;
    (* mark_debug = "true" *) wire                                     m_axis_vS1_tlast;

    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_vS2_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_vS2_tkeep;
    (* mark_debug = "true" *) wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     m_axis_vS2_tuser;
    (* mark_debug = "true" *) wire                                     m_axis_vS2_tvalid;
    (* mark_debug = "true" *) wire                                     m_axis_vS2_tready;
    (* mark_debug = "true" *) wire                                     m_axis_vS2_tlast;

    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_vS3_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_vS3_tkeep;
    (* mark_debug = "true" *) wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     m_axis_vS3_tuser;
    (* mark_debug = "true" *) wire                                     m_axis_vS3_tvalid;
    (* mark_debug = "true" *) wire                                     m_axis_vS3_tready;
    (* mark_debug = "true" *) wire                                     m_axis_vS3_tlast;

    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_vS4_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_vS4_tkeep;
    (* mark_debug = "true" *) wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     m_axis_vS4_tuser;
    (* mark_debug = "true" *) wire                                     m_axis_vS4_tvalid;
    (* mark_debug = "true" *) wire                                     m_axis_vS4_tready;
    (* mark_debug = "true" *) wire                                     m_axis_vS4_tlast;

    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_vS5_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_vS5_tkeep;
    (* mark_debug = "true" *) wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     m_axis_vS5_tuser;
    (* mark_debug = "true" *) wire                                     m_axis_vS5_tvalid;
    (* mark_debug = "true" *) wire                                     m_axis_vS5_tready;
    (* mark_debug = "true" *) wire                                     m_axis_vS5_tlast;

    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_vS6_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_vS6_tkeep;
    (* mark_debug = "true" *) wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     m_axis_vS6_tuser;
    (* mark_debug = "true" *) wire                                     m_axis_vS6_tvalid;
    (* mark_debug = "true" *) wire                                     m_axis_vS6_tready;
    (* mark_debug = "true" *) wire                                     m_axis_vS6_tlast;

    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_vS7_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_vS7_tkeep;
    (* mark_debug = "true" *) wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     m_axis_vS7_tuser;
    (* mark_debug = "true" *) wire                                     m_axis_vS7_tvalid;
    (* mark_debug = "true" *) wire                                     m_axis_vS7_tready;
    (* mark_debug = "true" *) wire                                     m_axis_vS7_tlast;
    // Buses from Control to CvSI
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S_AXI_vS0_AWADDR;
    (* mark_debug = "true" *) wire                                     S_AXI_vS0_AWVALID;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S_AXI_vS0_WDATA;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH/8-1 : 0]        S_AXI_vS0_WSTRB;
    (* mark_debug = "true" *) wire                                     S_AXI_vS0_WVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS0_BREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S_AXI_vS0_ARADDR;
    (* mark_debug = "true" *) wire                                     S_AXI_vS0_ARVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS0_RREADY;
    (* mark_debug = "true" *) wire                                     S_AXI_vS0_ARREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S_AXI_vS0_RDATA;
    (* mark_debug = "true" *) wire [1 : 0]                             S_AXI_vS0_RRESP;
    (* mark_debug = "true" *) wire                                     S_AXI_vS0_RVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS0_WREADY;
    (* mark_debug = "true" *) wire [1 : 0]                             S_AXI_vS0_BRESP;
    (* mark_debug = "true" *) wire                                     S_AXI_vS0_BVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS0_AWREADY;

    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S_AXI_vS1_AWADDR;
    (* mark_debug = "true" *) wire                                     S_AXI_vS1_AWVALID;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S_AXI_vS1_WDATA;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH/8-1 : 0]        S_AXI_vS1_WSTRB;
    (* mark_debug = "true" *) wire                                     S_AXI_vS1_WVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS1_BREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S_AXI_vS1_ARADDR;
    (* mark_debug = "true" *) wire                                     S_AXI_vS1_ARVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS1_RREADY;
    (* mark_debug = "true" *) wire                                     S_AXI_vS1_ARREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S_AXI_vS1_RDATA;
    (* mark_debug = "true" *) wire [1 : 0]                             S_AXI_vS1_RRESP;
    (* mark_debug = "true" *) wire                                     S_AXI_vS1_RVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS1_WREADY;
    (* mark_debug = "true" *) wire [1 : 0]                             S_AXI_vS1_BRESP;
    (* mark_debug = "true" *) wire                                     S_AXI_vS1_BVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS1_AWREADY;

    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S_AXI_vS2_AWADDR;
    (* mark_debug = "true" *) wire                                     S_AXI_vS2_AWVALID;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S_AXI_vS2_WDATA;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH/8-1 : 0]        S_AXI_vS2_WSTRB;
    (* mark_debug = "true" *) wire                                     S_AXI_vS2_WVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS2_BREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S_AXI_vS2_ARADDR;
    (* mark_debug = "true" *) wire                                     S_AXI_vS2_ARVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS2_RREADY;
    (* mark_debug = "true" *) wire                                     S_AXI_vS2_ARREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S_AXI_vS2_RDATA;
    (* mark_debug = "true" *) wire [1 : 0]                             S_AXI_vS2_RRESP;
    (* mark_debug = "true" *) wire                                     S_AXI_vS2_RVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS2_WREADY;
    (* mark_debug = "true" *) wire [1 : 0]                             S_AXI_vS2_BRESP;
    (* mark_debug = "true" *) wire                                     S_AXI_vS2_BVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS2_AWREADY;

    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S_AXI_vS3_AWADDR;
    (* mark_debug = "true" *) wire                                     S_AXI_vS3_AWVALID;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S_AXI_vS3_WDATA;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH/8-1 : 0]        S_AXI_vS3_WSTRB;
    (* mark_debug = "true" *) wire                                     S_AXI_vS3_WVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS3_BREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S_AXI_vS3_ARADDR;
    (* mark_debug = "true" *) wire                                     S_AXI_vS3_ARVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS3_RREADY;
    (* mark_debug = "true" *) wire                                     S_AXI_vS3_ARREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S_AXI_vS3_RDATA;
    (* mark_debug = "true" *) wire [1 : 0]                             S_AXI_vS3_RRESP;
    (* mark_debug = "true" *) wire                                     S_AXI_vS3_RVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS3_WREADY;
    (* mark_debug = "true" *) wire [1 : 0]                             S_AXI_vS3_BRESP;
    (* mark_debug = "true" *) wire                                     S_AXI_vS3_BVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS3_AWREADY;

    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S_AXI_vS4_AWADDR;
    (* mark_debug = "true" *) wire                                     S_AXI_vS4_AWVALID;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S_AXI_vS4_WDATA;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH/8-1 : 0]        S_AXI_vS4_WSTRB;
    (* mark_debug = "true" *) wire                                     S_AXI_vS4_WVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS4_BREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S_AXI_vS4_ARADDR;
    (* mark_debug = "true" *) wire                                     S_AXI_vS4_ARVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS4_RREADY;
    (* mark_debug = "true" *) wire                                     S_AXI_vS4_ARREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S_AXI_vS4_RDATA;
    (* mark_debug = "true" *) wire [1 : 0]                             S_AXI_vS4_RRESP;
    (* mark_debug = "true" *) wire                                     S_AXI_vS4_RVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS4_WREADY;
    (* mark_debug = "true" *) wire [1 : 0]                             S_AXI_vS4_BRESP;
    (* mark_debug = "true" *) wire                                     S_AXI_vS4_BVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS4_AWREADY;

    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S_AXI_vS5_AWADDR;
    (* mark_debug = "true" *) wire                                     S_AXI_vS5_AWVALID;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S_AXI_vS5_WDATA;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH/8-1 : 0]        S_AXI_vS5_WSTRB;
    (* mark_debug = "true" *) wire                                     S_AXI_vS5_WVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS5_BREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S_AXI_vS5_ARADDR;
    (* mark_debug = "true" *) wire                                     S_AXI_vS5_ARVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS5_RREADY;
    (* mark_debug = "true" *) wire                                     S_AXI_vS5_ARREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S_AXI_vS5_RDATA;
    (* mark_debug = "true" *) wire [1 : 0]                             S_AXI_vS5_RRESP;
    (* mark_debug = "true" *) wire                                     S_AXI_vS5_RVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS5_WREADY;
    (* mark_debug = "true" *) wire [1 : 0]                             S_AXI_vS5_BRESP;
    (* mark_debug = "true" *) wire                                     S_AXI_vS5_BVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS5_AWREADY;

    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S_AXI_vS6_AWADDR;
    (* mark_debug = "true" *) wire                                     S_AXI_vS6_AWVALID;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S_AXI_vS6_WDATA;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH/8-1 : 0]        S_AXI_vS6_WSTRB;
    (* mark_debug = "true" *) wire                                     S_AXI_vS6_WVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS6_BREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S_AXI_vS6_ARADDR;
    (* mark_debug = "true" *) wire                                     S_AXI_vS6_ARVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS6_RREADY;
    (* mark_debug = "true" *) wire                                     S_AXI_vS6_ARREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S_AXI_vS6_RDATA;
    (* mark_debug = "true" *) wire [1 : 0]                             S_AXI_vS6_RRESP;
    (* mark_debug = "true" *) wire                                     S_AXI_vS6_RVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS6_WREADY;
    (* mark_debug = "true" *) wire [1 : 0]                             S_AXI_vS6_BRESP;
    (* mark_debug = "true" *) wire                                     S_AXI_vS6_BVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS6_AWREADY;

    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S_AXI_vS7_AWADDR;
    (* mark_debug = "true" *) wire                                     S_AXI_vS7_AWVALID;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S_AXI_vS7_WDATA;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH/8-1 : 0]        S_AXI_vS7_WSTRB;
    (* mark_debug = "true" *) wire                                     S_AXI_vS7_WVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS7_BREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S_AXI_vS7_ARADDR;
    (* mark_debug = "true" *) wire                                     S_AXI_vS7_ARVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS7_RREADY;
    (* mark_debug = "true" *) wire                                     S_AXI_vS7_ARREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S_AXI_vS7_RDATA;
    (* mark_debug = "true" *) wire [1 : 0]                             S_AXI_vS7_RRESP;
    (* mark_debug = "true" *) wire                                     S_AXI_vS7_RVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS7_WREADY;
    (* mark_debug = "true" *) wire [1 : 0]                             S_AXI_vS7_BRESP;
    (* mark_debug = "true" *) wire                                     S_AXI_vS7_BVALID;
    (* mark_debug = "true" *) wire                                     S_AXI_vS7_AWREADY;
    // Signals from OvSI to vS Array
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]                  nf0_q_size;
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]                  nf1_q_size;
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]                  nf2_q_size;
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]                  nf3_q_size;
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]                  dma_q_size;

    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1:0]            bytes_dropped;
    (* mark_debug = "true" *) wire [5-1:0]                             pkt_dropped;

//    assign nf0_q_size = 'd12;
//    assign nf1_q_size = 'd13;
//    assign nf2_q_size = 'd14;
//    assign nf3_q_size = 'd15;
//    assign dma_q_size = 'd16;


    //Input vS Interface
     input_vs_interface
    IvSI (
      // Global Ports
      .axis_aclk(axis_aclk),
      .axis_resetn(axis_resetn),
      // Master Stream Ports (interface to vS Array)
      .m_axis_0_tdata (s_axis_vS0_tdata),
      .m_axis_0_tkeep (s_axis_vS0_tkeep),
      .m_axis_0_tuser (s_axis_vS0_tuser),
      .m_axis_0_tvalid(s_axis_vS0_tvalid),
      .m_axis_0_tlast (s_axis_vS0_tlast),
      .m_axis_0_tready(s_axis_vS0_tready),

      .m_axis_1_tdata (s_axis_vS1_tdata),
      .m_axis_1_tkeep (s_axis_vS1_tkeep),
      .m_axis_1_tuser (s_axis_vS1_tuser),
      .m_axis_1_tvalid(s_axis_vS1_tvalid),
      .m_axis_1_tlast (s_axis_vS1_tlast),
      .m_axis_1_tready(s_axis_vS1_tready),

      .m_axis_2_tdata (s_axis_vS2_tdata),
      .m_axis_2_tkeep (s_axis_vS2_tkeep),
      .m_axis_2_tuser (s_axis_vS2_tuser),
      .m_axis_2_tvalid(s_axis_vS2_tvalid),
      .m_axis_2_tlast (s_axis_vS2_tlast),
      .m_axis_2_tready(s_axis_vS2_tready),

      .m_axis_3_tdata (s_axis_vS3_tdata),
      .m_axis_3_tkeep (s_axis_vS3_tkeep),
      .m_axis_3_tuser (s_axis_vS3_tuser),
      .m_axis_3_tvalid(s_axis_vS3_tvalid),
      .m_axis_3_tlast (s_axis_vS3_tlast),
      .m_axis_3_tready(s_axis_vS3_tready),

      .m_axis_4_tdata (s_axis_vS4_tdata),
      .m_axis_4_tkeep (s_axis_vS4_tkeep),
      .m_axis_4_tuser (s_axis_vS4_tuser),
      .m_axis_4_tvalid(s_axis_vS4_tvalid),
      .m_axis_4_tlast (s_axis_vS4_tlast),
      .m_axis_4_tready(s_axis_vS4_tready),

      .m_axis_5_tdata (s_axis_vS5_tdata),
      .m_axis_5_tkeep (s_axis_vS5_tkeep),
      .m_axis_5_tuser (s_axis_vS5_tuser),
      .m_axis_5_tvalid(s_axis_vS5_tvalid),
      .m_axis_5_tlast (s_axis_vS5_tlast),
      .m_axis_5_tready(s_axis_vS5_tready),

      .m_axis_6_tdata (s_axis_vS6_tdata),
      .m_axis_6_tkeep (s_axis_vS6_tkeep),
      .m_axis_6_tuser (s_axis_vS6_tuser),
      .m_axis_6_tvalid(s_axis_vS6_tvalid),
      .m_axis_6_tlast (s_axis_vS6_tlast),
      .m_axis_6_tready(s_axis_vS6_tready),

      .m_axis_7_tdata (s_axis_vS7_tdata),
      .m_axis_7_tkeep (s_axis_vS7_tkeep),
      .m_axis_7_tuser (s_axis_vS7_tuser),
      .m_axis_7_tvalid(s_axis_vS7_tvalid),
      .m_axis_7_tlast (s_axis_vS7_tlast),
      .m_axis_7_tready(s_axis_vS7_tready),
      // Slave Stream Ports (interface to Rx queues)
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
      .S_AXI_ACLK (axi_aclk),
      .S_AXI_ARESETN(axi_resetn),
      .S_AXI_AWADDR(S0_AXI_AWADDR),
      .S_AXI_AWVALID(S0_AXI_AWVALID),
      .S_AXI_WDATA(S0_AXI_WDATA),
      .S_AXI_WSTRB(S0_AXI_WSTRB),
      .S_AXI_WVALID(S0_AXI_WVALID),
      .S_AXI_BREADY(S0_AXI_BREADY),
      .S_AXI_ARADDR(S0_AXI_ARADDR),
      .S_AXI_ARVALID(S0_AXI_ARVALID),
      .S_AXI_RREADY(S0_AXI_RREADY),
      .S_AXI_ARREADY(S0_AXI_ARREADY),
      .S_AXI_RDATA(S0_AXI_RDATA),
      .S_AXI_RRESP(S0_AXI_RRESP),
      .S_AXI_RVALID(S0_AXI_RVALID),
      .S_AXI_WREADY(S0_AXI_WREADY),
      .S_AXI_BRESP(S0_AXI_BRESP),
      .S_AXI_BVALID(S0_AXI_BVALID),
      .S_AXI_AWREADY(S0_AXI_AWREADY),

      .pkt_fwd()
    );

    // Control P4 Interface
      control_vs_interface_ip
    CvSI  (
      // AXI4LITE Control Master
      .M_AXI_AWADDR(S1_AXI_AWADDR),
      .M_AXI_AWVALID(S1_AXI_AWVALID),
      .M_AXI_WDATA(S1_AXI_WDATA),
      .M_AXI_WSTRB(S1_AXI_WSTRB),
      .M_AXI_WVALID(S1_AXI_WVALID),
      .M_AXI_BREADY(S1_AXI_BREADY),
      .M_AXI_ARADDR(S1_AXI_ARADDR),
      .M_AXI_ARVALID(S1_AXI_ARVALID),
      .M_AXI_RREADY(S1_AXI_RREADY),
      .M_AXI_ARREADY(S1_AXI_ARREADY),
      .M_AXI_RDATA(S1_AXI_RDATA),
      .M_AXI_RRESP(S1_AXI_RRESP),
      .M_AXI_RVALID(S1_AXI_RVALID),
      .M_AXI_WREADY(S1_AXI_WREADY),
      .M_AXI_BRESP(S1_AXI_BRESP),
      .M_AXI_BVALID(S1_AXI_BVALID),
      .M_AXI_AWREADY(S1_AXI_AWREADY),
      // AXI4LITE Control Slave 0
      .S_AXI_vS0_AWADDR(S_AXI_vS0_AWADDR),
      .S_AXI_vS0_AWVALID(S_AXI_vS0_AWVALID),
      .S_AXI_vS0_WDATA(S_AXI_vS0_WDATA),
      .S_AXI_vS0_WSTRB(S_AXI_vS0_WSTRB),
      .S_AXI_vS0_WVALID(S_AXI_vS0_WVALID),
      .S_AXI_vS0_BREADY(S_AXI_vS0_BREADY),
      .S_AXI_vS0_ARADDR(S_AXI_vS0_ARADDR),
      .S_AXI_vS0_ARVALID(S_AXI_vS0_ARVALID),
      .S_AXI_vS0_RREADY(S_AXI_vS0_RREADY),
      .S_AXI_vS0_ARREADY(S_AXI_vS0_ARREADY),
      .S_AXI_vS0_RDATA(S_AXI_vS0_RDATA),
      .S_AXI_vS0_RRESP(S_AXI_vS0_RRESP),
      .S_AXI_vS0_RVALID(S_AXI_vS0_RVALID),
      .S_AXI_vS0_WREADY(S_AXI_vS0_WREADY),
      .S_AXI_vS0_BRESP(S_AXI_vS0_BRESP),
      .S_AXI_vS0_BVALID(S_AXI_vS0_BVALID),
      .S_AXI_vS0_AWREADY(S_AXI_vS0_AWREADY),
      // AXI4LITE Control Slave 1
      .S_AXI_vS1_AWADDR(S_AXI_vS1_AWADDR),
      .S_AXI_vS1_AWVALID(S_AXI_vS1_AWVALID),
      .S_AXI_vS1_WDATA(S_AXI_vS1_WDATA),
      .S_AXI_vS1_WSTRB(S_AXI_vS1_WSTRB),
      .S_AXI_vS1_WVALID(S_AXI_vS1_WVALID),
      .S_AXI_vS1_BREADY(S_AXI_vS1_BREADY),
      .S_AXI_vS1_ARADDR(S_AXI_vS1_ARADDR),
      .S_AXI_vS1_ARVALID(S_AXI_vS1_ARVALID),
      .S_AXI_vS1_RREADY(S_AXI_vS1_RREADY),
      .S_AXI_vS1_ARREADY(S_AXI_vS1_ARREADY),
      .S_AXI_vS1_RDATA(S_AXI_vS1_RDATA),
      .S_AXI_vS1_RRESP(S_AXI_vS1_RRESP),
      .S_AXI_vS1_RVALID(S_AXI_vS1_RVALID),
      .S_AXI_vS1_WREADY(S_AXI_vS1_WREADY),
      .S_AXI_vS1_BRESP(S_AXI_vS1_BRESP),
      .S_AXI_vS1_BVALID(S_AXI_vS1_BVALID),
      .S_AXI_vS1_AWREADY(S_AXI_vS1_AWREADY),
      // AXI4LITE Control Slave 2
      .S_AXI_vS2_AWADDR(S_AXI_vS2_AWADDR),
      .S_AXI_vS2_AWVALID(S_AXI_vS2_AWVALID),
      .S_AXI_vS2_WDATA(S_AXI_vS2_WDATA),
      .S_AXI_vS2_WSTRB(S_AXI_vS2_WSTRB),
      .S_AXI_vS2_WVALID(S_AXI_vS2_WVALID),
      .S_AXI_vS2_BREADY(S_AXI_vS2_BREADY),
      .S_AXI_vS2_ARADDR(S_AXI_vS2_ARADDR),
      .S_AXI_vS2_ARVALID(S_AXI_vS2_ARVALID),
      .S_AXI_vS2_RREADY(S_AXI_vS2_RREADY),
      .S_AXI_vS2_ARREADY(S_AXI_vS2_ARREADY),
      .S_AXI_vS2_RDATA(S_AXI_vS2_RDATA),
      .S_AXI_vS2_RRESP(S_AXI_vS2_RRESP),
      .S_AXI_vS2_RVALID(S_AXI_vS2_RVALID),
      .S_AXI_vS2_WREADY(S_AXI_vS2_WREADY),
      .S_AXI_vS2_BRESP(S_AXI_vS2_BRESP),
      .S_AXI_vS2_BVALID(S_AXI_vS2_BVALID),
      .S_AXI_vS2_AWREADY(S_AXI_vS2_AWREADY),
      // AXI4LITE Control Slave 3
      .S_AXI_vS3_AWADDR(S_AXI_vS3_AWADDR),
      .S_AXI_vS3_AWVALID(S_AXI_vS3_AWVALID),
      .S_AXI_vS3_WDATA(S_AXI_vS3_WDATA),
      .S_AXI_vS3_WSTRB(S_AXI_vS3_WSTRB),
      .S_AXI_vS3_WVALID(S_AXI_vS3_WVALID),
      .S_AXI_vS3_BREADY(S_AXI_vS3_BREADY),
      .S_AXI_vS3_ARADDR(S_AXI_vS3_ARADDR),
      .S_AXI_vS3_ARVALID(S_AXI_vS3_ARVALID),
      .S_AXI_vS3_RREADY(S_AXI_vS3_RREADY),
      .S_AXI_vS3_ARREADY(S_AXI_vS3_ARREADY),
      .S_AXI_vS3_RDATA(S_AXI_vS3_RDATA),
      .S_AXI_vS3_RRESP(S_AXI_vS3_RRESP),
      .S_AXI_vS3_RVALID(S_AXI_vS3_RVALID),
      .S_AXI_vS3_WREADY(S_AXI_vS3_WREADY),
      .S_AXI_vS3_BRESP(S_AXI_vS3_BRESP),
      .S_AXI_vS3_BVALID(S_AXI_vS3_BVALID),
      .S_AXI_vS3_AWREADY(S_AXI_vS3_AWREADY),
      // AXI4LITE Control Slave 4
      .S_AXI_vS4_AWADDR(S_AXI_vS4_AWADDR),
      .S_AXI_vS4_AWVALID(S_AXI_vS4_AWVALID),
      .S_AXI_vS4_WDATA(S_AXI_vS4_WDATA),
      .S_AXI_vS4_WSTRB(S_AXI_vS4_WSTRB),
      .S_AXI_vS4_WVALID(S_AXI_vS4_WVALID),
      .S_AXI_vS4_BREADY(S_AXI_vS4_BREADY),
      .S_AXI_vS4_ARADDR(S_AXI_vS4_ARADDR),
      .S_AXI_vS4_ARVALID(S_AXI_vS4_ARVALID),
      .S_AXI_vS4_RREADY(S_AXI_vS4_RREADY),
      .S_AXI_vS4_ARREADY(S_AXI_vS4_ARREADY),
      .S_AXI_vS4_RDATA(S_AXI_vS4_RDATA),
      .S_AXI_vS4_RRESP(S_AXI_vS4_RRESP),
      .S_AXI_vS4_RVALID(S_AXI_vS4_RVALID),
      .S_AXI_vS4_WREADY(S_AXI_vS4_WREADY),
      .S_AXI_vS4_BRESP(S_AXI_vS4_BRESP),
      .S_AXI_vS4_BVALID(S_AXI_vS4_BVALID),
      .S_AXI_vS4_AWREADY(S_AXI_vS4_AWREADY),
      // AXI4LITE Control Slave 5
      .S_AXI_vS5_AWADDR(S_AXI_vS5_AWADDR),
      .S_AXI_vS5_AWVALID(S_AXI_vS5_AWVALID),
      .S_AXI_vS5_WDATA(S_AXI_vS5_WDATA),
      .S_AXI_vS5_WSTRB(S_AXI_vS5_WSTRB),
      .S_AXI_vS5_WVALID(S_AXI_vS5_WVALID),
      .S_AXI_vS5_BREADY(S_AXI_vS5_BREADY),
      .S_AXI_vS5_ARADDR(S_AXI_vS5_ARADDR),
      .S_AXI_vS5_ARVALID(S_AXI_vS5_ARVALID),
      .S_AXI_vS5_RREADY(S_AXI_vS5_RREADY),
      .S_AXI_vS5_ARREADY(S_AXI_vS5_ARREADY),
      .S_AXI_vS5_RDATA(S_AXI_vS5_RDATA),
      .S_AXI_vS5_RRESP(S_AXI_vS5_RRESP),
      .S_AXI_vS5_RVALID(S_AXI_vS5_RVALID),
      .S_AXI_vS5_WREADY(S_AXI_vS5_WREADY),
      .S_AXI_vS5_BRESP(S_AXI_vS5_BRESP),
      .S_AXI_vS5_BVALID(S_AXI_vS5_BVALID),
      .S_AXI_vS5_AWREADY(S_AXI_vS5_AWREADY),
      // AXI4LITE Control Slave 6
      .S_AXI_vS6_AWADDR(S_AXI_vS6_AWADDR),
      .S_AXI_vS6_AWVALID(S_AXI_vS6_AWVALID),
      .S_AXI_vS6_WDATA(S_AXI_vS6_WDATA),
      .S_AXI_vS6_WSTRB(S_AXI_vS6_WSTRB),
      .S_AXI_vS6_WVALID(S_AXI_vS6_WVALID),
      .S_AXI_vS6_BREADY(S_AXI_vS6_BREADY),
      .S_AXI_vS6_ARADDR(S_AXI_vS6_ARADDR),
      .S_AXI_vS6_ARVALID(S_AXI_vS6_ARVALID),
      .S_AXI_vS6_RREADY(S_AXI_vS6_RREADY),
      .S_AXI_vS6_ARREADY(S_AXI_vS6_ARREADY),
      .S_AXI_vS6_RDATA(S_AXI_vS6_RDATA),
      .S_AXI_vS6_RRESP(S_AXI_vS6_RRESP),
      .S_AXI_vS6_RVALID(S_AXI_vS6_RVALID),
      .S_AXI_vS6_WREADY(S_AXI_vS6_WREADY),
      .S_AXI_vS6_BRESP(S_AXI_vS6_BRESP),
      .S_AXI_vS6_BVALID(S_AXI_vS6_BVALID),
      .S_AXI_vS6_AWREADY(S_AXI_vS6_AWREADY),
      // AXI4LITE Control Slave 7
      .S_AXI_vS7_AWADDR(S_AXI_vS7_AWADDR),
      .S_AXI_vS7_AWVALID(S_AXI_vS7_AWVALID),
      .S_AXI_vS7_WDATA(S_AXI_vS7_WDATA),
      .S_AXI_vS7_WSTRB(S_AXI_vS7_WSTRB),
      .S_AXI_vS7_WVALID(S_AXI_vS7_WVALID),
      .S_AXI_vS7_BREADY(S_AXI_vS7_BREADY),
      .S_AXI_vS7_ARADDR(S_AXI_vS7_ARADDR),
      .S_AXI_vS7_ARVALID(S_AXI_vS7_ARVALID),
      .S_AXI_vS7_RREADY(S_AXI_vS7_RREADY),
      .S_AXI_vS7_ARREADY(S_AXI_vS7_ARREADY),
      .S_AXI_vS7_RDATA(S_AXI_vS7_RDATA),
      .S_AXI_vS7_RRESP(S_AXI_vS7_RRESP),
      .S_AXI_vS7_RVALID(S_AXI_vS7_RVALID),
      .S_AXI_vS7_WREADY(S_AXI_vS7_WREADY),
      .S_AXI_vS7_BRESP(S_AXI_vS7_BRESP),
      .S_AXI_vS7_BVALID(S_AXI_vS7_BVALID),
      .S_AXI_vS7_AWREADY(S_AXI_vS7_AWREADY),
      // AXILITE clock
      .M_AXI_ACLK (axi_aclk),
      .M_AXI_ARESETN(axi_resetn)
    );


    // vS Array (Virtual Switch 0)
      nf_sdnet_vSwitch0_ip
    sdnet_vSwitch0  (
      .axis_aclk(axis_aclk),
      .axis_resetn(axis_resetn),
      // Master from vS to IvSI
      .m_axis_tdata (m_axis_vS0_tdata),
      .m_axis_tkeep (m_axis_vS0_tkeep),
      .m_axis_tuser (m_axis_vS0_tuser),
      .m_axis_tvalid(m_axis_vS0_tvalid),
      .m_axis_tready(m_axis_vS0_tready),
      .m_axis_tlast (m_axis_vS0_tlast),
      // Slave from IvSI to vS
      .s_axis_tdata (s_axis_vS0_tdata),
      .s_axis_tkeep (s_axis_vS0_tkeep),
      .s_axis_tuser ({dma_q_size,
                      nf3_q_size,
                      nf2_q_size,
                      nf1_q_size,
                      nf0_q_size,
                      s_axis_vS0_tuser[C_M_AXIS_TUSER_WIDTH-DIGEST_WIDTH-1:0]}),
      .s_axis_tvalid(s_axis_vS0_tvalid),
      .s_axis_tready(s_axis_vS0_tready),
      .s_axis_tlast (s_axis_vS0_tlast),
      // Slave from CvSI to vS
      .S_AXI_AWADDR(S_AXI_vS0_AWADDR),
      .S_AXI_AWVALID(S_AXI_vS0_AWVALID),
      .S_AXI_WDATA(S_AXI_vS0_WDATA),
      .S_AXI_WSTRB(S_AXI_vS0_WSTRB),
      .S_AXI_WVALID(S_AXI_vS0_WVALID),
      .S_AXI_BREADY(S_AXI_vS0_BREADY),
      .S_AXI_ARADDR(S_AXI_vS0_ARADDR),
      .S_AXI_ARVALID(S_AXI_vS0_ARVALID),
      .S_AXI_RREADY(S_AXI_vS0_RREADY),
      .S_AXI_ARREADY(S_AXI_vS0_ARREADY),
      .S_AXI_RDATA(S_AXI_vS0_RDATA),
      .S_AXI_RRESP(S_AXI_vS0_RRESP),
      .S_AXI_RVALID(S_AXI_vS0_RVALID),
      .S_AXI_WREADY(S_AXI_vS0_WREADY),
      .S_AXI_BRESP(S_AXI_vS0_BRESP),
      .S_AXI_BVALID(S_AXI_vS0_BVALID),
      .S_AXI_AWREADY(S_AXI_vS0_AWREADY),
      .S_AXI_ACLK (axi_aclk),
      .S_AXI_ARESETN(axi_resetn)
    );


    // vS Array (Virtual Switch 1)
      nf_sdnet_vSwitch1_ip
    sdnet_vSwitch1  (
      .axis_aclk(axis_aclk),
      .axis_resetn(axis_resetn),
      // Master from vS to IvSI
      .m_axis_tdata (m_axis_vS1_tdata),
      .m_axis_tkeep (m_axis_vS1_tkeep),
      .m_axis_tuser (m_axis_vS1_tuser),
      .m_axis_tvalid(m_axis_vS1_tvalid),
      .m_axis_tready(m_axis_vS1_tready),
      .m_axis_tlast (m_axis_vS1_tlast),
      // Slave from IvSI to vS
      .s_axis_tdata (s_axis_vS1_tdata),
      .s_axis_tkeep (s_axis_vS1_tkeep),
      .s_axis_tuser ({dma_q_size,
                      nf3_q_size,
                      nf2_q_size,
                      nf1_q_size,
                      nf0_q_size,
                      s_axis_vS1_tuser[C_M_AXIS_TUSER_WIDTH-DIGEST_WIDTH-1:0]}),
      .s_axis_tvalid(s_axis_vS1_tvalid),
      .s_axis_tready(s_axis_vS1_tready),
      .s_axis_tlast (s_axis_vS1_tlast),
      // Slave from CvSI to vS
      .S_AXI_AWADDR(S_AXI_vS1_AWADDR),
      .S_AXI_AWVALID(S_AXI_vS1_AWVALID),
      .S_AXI_WDATA(S_AXI_vS1_WDATA),
      .S_AXI_WSTRB(S_AXI_vS1_WSTRB),
      .S_AXI_WVALID(S_AXI_vS1_WVALID),
      .S_AXI_BREADY(S_AXI_vS1_BREADY),
      .S_AXI_ARADDR(S_AXI_vS1_ARADDR),
      .S_AXI_ARVALID(S_AXI_vS1_ARVALID),
      .S_AXI_RREADY(S_AXI_vS1_RREADY),
      .S_AXI_ARREADY(S_AXI_vS1_ARREADY),
      .S_AXI_RDATA(S_AXI_vS1_RDATA),
      .S_AXI_RRESP(S_AXI_vS1_RRESP),
      .S_AXI_RVALID(S_AXI_vS1_RVALID),
      .S_AXI_WREADY(S_AXI_vS1_WREADY),
      .S_AXI_BRESP(S_AXI_vS1_BRESP),
      .S_AXI_BVALID(S_AXI_vS1_BVALID),
      .S_AXI_AWREADY(S_AXI_vS1_AWREADY),
      .S_AXI_ACLK (axi_aclk),
      .S_AXI_ARESETN(axi_resetn)
    );


    // vS Array (Virtual Switch 2)
      nf_sdnet_vSwitch2_ip
    sdnet_vSwitch2  (
      .axis_aclk(axis_aclk),
      .axis_resetn(axis_resetn),
      // Master from vS to IvSI
      .m_axis_tdata (m_axis_vS2_tdata),
      .m_axis_tkeep (m_axis_vS2_tkeep),
      .m_axis_tuser (m_axis_vS2_tuser),
      .m_axis_tvalid(m_axis_vS2_tvalid),
      .m_axis_tready(m_axis_vS2_tready),
      .m_axis_tlast (m_axis_vS2_tlast),
      // Slave from IvSI to vS
      .s_axis_tdata (s_axis_vS2_tdata),
      .s_axis_tkeep (s_axis_vS2_tkeep),
      .s_axis_tuser ({dma_q_size,
                      nf3_q_size,
                      nf2_q_size,
                      nf1_q_size,
                      nf0_q_size,
                      s_axis_vS2_tuser[C_M_AXIS_TUSER_WIDTH-DIGEST_WIDTH-1:0]}),
      .s_axis_tvalid(s_axis_vS2_tvalid),
      .s_axis_tready(s_axis_vS2_tready),
      .s_axis_tlast (s_axis_vS2_tlast),
      // Slave from CvSI to vS
      .S_AXI_AWADDR(S_AXI_vS2_AWADDR),
      .S_AXI_AWVALID(S_AXI_vS2_AWVALID),
      .S_AXI_WDATA(S_AXI_vS2_WDATA),
      .S_AXI_WSTRB(S_AXI_vS2_WSTRB),
      .S_AXI_WVALID(S_AXI_vS2_WVALID),
      .S_AXI_BREADY(S_AXI_vS2_BREADY),
      .S_AXI_ARADDR(S_AXI_vS2_ARADDR),
      .S_AXI_ARVALID(S_AXI_vS2_ARVALID),
      .S_AXI_RREADY(S_AXI_vS2_RREADY),
      .S_AXI_ARREADY(S_AXI_vS2_ARREADY),
      .S_AXI_RDATA(S_AXI_vS2_RDATA),
      .S_AXI_RRESP(S_AXI_vS2_RRESP),
      .S_AXI_RVALID(S_AXI_vS2_RVALID),
      .S_AXI_WREADY(S_AXI_vS2_WREADY),
      .S_AXI_BRESP(S_AXI_vS2_BRESP),
      .S_AXI_BVALID(S_AXI_vS2_BVALID),
      .S_AXI_AWREADY(S_AXI_vS2_AWREADY),
      .S_AXI_ACLK (axi_aclk),
      .S_AXI_ARESETN(axi_resetn)
    );


    // vS Array (Virtual Switch 3)
      nf_sdnet_vSwitch3_ip
    sdnet_vSwitch3  (
      .axis_aclk(axis_aclk),
      .axis_resetn(axis_resetn),
      // Master from vS to IvSI
      .m_axis_tdata (m_axis_vS3_tdata),
      .m_axis_tkeep (m_axis_vS3_tkeep),
      .m_axis_tuser (m_axis_vS3_tuser),
      .m_axis_tvalid(m_axis_vS3_tvalid),
      .m_axis_tready(m_axis_vS3_tready),
      .m_axis_tlast (m_axis_vS3_tlast),
      // Slave from IvSI to vS
      .s_axis_tdata (s_axis_vS3_tdata),
      .s_axis_tkeep (s_axis_vS3_tkeep),
      .s_axis_tuser ({dma_q_size,
                      nf3_q_size,
                      nf2_q_size,
                      nf1_q_size,
                      nf0_q_size,
                      s_axis_vS3_tuser[C_M_AXIS_TUSER_WIDTH-DIGEST_WIDTH-1:0]}),
      .s_axis_tvalid(s_axis_vS3_tvalid),
      .s_axis_tready(s_axis_vS3_tready),
      .s_axis_tlast (s_axis_vS3_tlast),
      // Slave from CvSI to vS
      .S_AXI_AWADDR(S_AXI_vS3_AWADDR),
      .S_AXI_AWVALID(S_AXI_vS3_AWVALID),
      .S_AXI_WDATA(S_AXI_vS3_WDATA),
      .S_AXI_WSTRB(S_AXI_vS3_WSTRB),
      .S_AXI_WVALID(S_AXI_vS3_WVALID),
      .S_AXI_BREADY(S_AXI_vS3_BREADY),
      .S_AXI_ARADDR(S_AXI_vS3_ARADDR),
      .S_AXI_ARVALID(S_AXI_vS3_ARVALID),
      .S_AXI_RREADY(S_AXI_vS3_RREADY),
      .S_AXI_ARREADY(S_AXI_vS3_ARREADY),
      .S_AXI_RDATA(S_AXI_vS3_RDATA),
      .S_AXI_RRESP(S_AXI_vS3_RRESP),
      .S_AXI_RVALID(S_AXI_vS3_RVALID),
      .S_AXI_WREADY(S_AXI_vS3_WREADY),
      .S_AXI_BRESP(S_AXI_vS3_BRESP),
      .S_AXI_BVALID(S_AXI_vS3_BVALID),
      .S_AXI_AWREADY(S_AXI_vS3_AWREADY),
      .S_AXI_ACLK (axi_aclk),
      .S_AXI_ARESETN(axi_resetn)
    );


    // vS Array (Virtual Switch 4)
      nf_sdnet_vSwitch4_ip
    sdnet_vSwitch4  (
      .axis_aclk(axis_aclk),
      .axis_resetn(axis_resetn),
      // Master from vS to IvSI
      .m_axis_tdata (m_axis_vS4_tdata),
      .m_axis_tkeep (m_axis_vS4_tkeep),
      .m_axis_tuser (m_axis_vS4_tuser),
      .m_axis_tvalid(m_axis_vS4_tvalid),
      .m_axis_tready(m_axis_vS4_tready),
      .m_axis_tlast (m_axis_vS4_tlast),
      // Slave from IvSI to vS
      .s_axis_tdata (s_axis_vS4_tdata),
      .s_axis_tkeep (s_axis_vS4_tkeep),
      .s_axis_tuser ({dma_q_size,
                      nf3_q_size,
                      nf2_q_size,
                      nf1_q_size,
                      nf0_q_size,
                      s_axis_vS4_tuser[C_M_AXIS_TUSER_WIDTH-DIGEST_WIDTH-1:0]}),
      .s_axis_tvalid(s_axis_vS4_tvalid),
      .s_axis_tready(s_axis_vS4_tready),
      .s_axis_tlast (s_axis_vS4_tlast),
      // Slave from CvSI to vS
      .S_AXI_AWADDR(S_AXI_vS4_AWADDR),
      .S_AXI_AWVALID(S_AXI_vS4_AWVALID),
      .S_AXI_WDATA(S_AXI_vS4_WDATA),
      .S_AXI_WSTRB(S_AXI_vS4_WSTRB),
      .S_AXI_WVALID(S_AXI_vS4_WVALID),
      .S_AXI_BREADY(S_AXI_vS4_BREADY),
      .S_AXI_ARADDR(S_AXI_vS4_ARADDR),
      .S_AXI_ARVALID(S_AXI_vS4_ARVALID),
      .S_AXI_RREADY(S_AXI_vS4_RREADY),
      .S_AXI_ARREADY(S_AXI_vS4_ARREADY),
      .S_AXI_RDATA(S_AXI_vS4_RDATA),
      .S_AXI_RRESP(S_AXI_vS4_RRESP),
      .S_AXI_RVALID(S_AXI_vS4_RVALID),
      .S_AXI_WREADY(S_AXI_vS4_WREADY),
      .S_AXI_BRESP(S_AXI_vS4_BRESP),
      .S_AXI_BVALID(S_AXI_vS4_BVALID),
      .S_AXI_AWREADY(S_AXI_vS4_AWREADY),
      .S_AXI_ACLK (axi_aclk),
      .S_AXI_ARESETN(axi_resetn)
    );


    // vS Array (Virtual Switch 5)
      nf_sdnet_vSwitch5_ip
    sdnet_vSwitch5  (
      .axis_aclk(axis_aclk),
      .axis_resetn(axis_resetn),
      // Master from vS to IvSI
      .m_axis_tdata (m_axis_vS5_tdata),
      .m_axis_tkeep (m_axis_vS5_tkeep),
      .m_axis_tuser (m_axis_vS5_tuser),
      .m_axis_tvalid(m_axis_vS5_tvalid),
      .m_axis_tready(m_axis_vS5_tready),
      .m_axis_tlast (m_axis_vS5_tlast),
      // Slave from IvSI to vS
      .s_axis_tdata (s_axis_vS5_tdata),
      .s_axis_tkeep (s_axis_vS5_tkeep),
      .s_axis_tuser ({dma_q_size,
                      nf3_q_size,
                      nf2_q_size,
                      nf1_q_size,
                      nf0_q_size,
                      s_axis_vS5_tuser[C_M_AXIS_TUSER_WIDTH-DIGEST_WIDTH-1:0]}),
      .s_axis_tvalid(s_axis_vS5_tvalid),
      .s_axis_tready(s_axis_vS5_tready),
      .s_axis_tlast (s_axis_vS5_tlast),
      // Slave from CvSI to vS
      .S_AXI_AWADDR(S_AXI_vS5_AWADDR),
      .S_AXI_AWVALID(S_AXI_vS5_AWVALID),
      .S_AXI_WDATA(S_AXI_vS5_WDATA),
      .S_AXI_WSTRB(S_AXI_vS5_WSTRB),
      .S_AXI_WVALID(S_AXI_vS5_WVALID),
      .S_AXI_BREADY(S_AXI_vS5_BREADY),
      .S_AXI_ARADDR(S_AXI_vS5_ARADDR),
      .S_AXI_ARVALID(S_AXI_vS5_ARVALID),
      .S_AXI_RREADY(S_AXI_vS5_RREADY),
      .S_AXI_ARREADY(S_AXI_vS5_ARREADY),
      .S_AXI_RDATA(S_AXI_vS5_RDATA),
      .S_AXI_RRESP(S_AXI_vS5_RRESP),
      .S_AXI_RVALID(S_AXI_vS5_RVALID),
      .S_AXI_WREADY(S_AXI_vS5_WREADY),
      .S_AXI_BRESP(S_AXI_vS5_BRESP),
      .S_AXI_BVALID(S_AXI_vS5_BVALID),
      .S_AXI_AWREADY(S_AXI_vS5_AWREADY),
      .S_AXI_ACLK (axi_aclk),
      .S_AXI_ARESETN(axi_resetn)
    );


    //Output P4 Interface
      output_vs_interface
    OvSI (
      // Global Ports
      .axis_aclk(axis_aclk),
      .axis_resetn(axis_resetn),
      // Master Stream Ports (interface to TX queues)
      .m_axis_0_tdata (m_axis_0_tdata),
      .m_axis_0_tkeep (m_axis_0_tkeep),
      .m_axis_0_tuser (m_axis_0_tuser),
      .m_axis_0_tvalid(m_axis_0_tvalid),
      .m_axis_0_tready(m_axis_0_tready),
      .m_axis_0_tlast (m_axis_0_tlast),

      .m_axis_1_tdata (m_axis_1_tdata),
      .m_axis_1_tkeep (m_axis_1_tkeep),
      .m_axis_1_tuser (m_axis_1_tuser),
      .m_axis_1_tvalid(m_axis_1_tvalid),
      .m_axis_1_tready(m_axis_1_tready),
      .m_axis_1_tlast (m_axis_1_tlast),

      .m_axis_2_tdata (m_axis_2_tdata),
      .m_axis_2_tkeep (m_axis_2_tkeep),
      .m_axis_2_tuser (m_axis_2_tuser),
      .m_axis_2_tvalid(m_axis_2_tvalid),
      .m_axis_2_tready(m_axis_2_tready),
      .m_axis_2_tlast (m_axis_2_tlast),

      .m_axis_3_tdata (m_axis_3_tdata),
      .m_axis_3_tkeep (m_axis_3_tkeep),
      .m_axis_3_tuser (m_axis_3_tuser),
      .m_axis_3_tvalid(m_axis_3_tvalid),
      .m_axis_3_tready(m_axis_3_tready),
      .m_axis_3_tlast (m_axis_3_tlast),

      .m_axis_4_tdata (m_axis_4_tdata),
      .m_axis_4_tkeep (m_axis_4_tkeep),
      .m_axis_4_tuser (m_axis_4_tuser),
      .m_axis_4_tvalid(m_axis_4_tvalid),
      .m_axis_4_tready(m_axis_4_tready),
      .m_axis_4_tlast (m_axis_4_tlast),
      // Slave Stream Ports (interface to vS Array)
      .s_axis_0_tdata (m_axis_vS0_tdata),
      .s_axis_0_tkeep (m_axis_vS0_tkeep),
      .s_axis_0_tuser (m_axis_vS0_tuser),
      .s_axis_0_tvalid(m_axis_vS0_tvalid),
      .s_axis_0_tready(m_axis_vS0_tready),
      .s_axis_0_tlast (m_axis_vS0_tlast),

      .s_axis_1_tdata (m_axis_vS1_tdata),
      .s_axis_1_tkeep (m_axis_vS1_tkeep),
      .s_axis_1_tuser (m_axis_vS1_tuser),
      .s_axis_1_tvalid(m_axis_vS1_tvalid),
      .s_axis_1_tready(m_axis_vS1_tready),
      .s_axis_1_tlast (m_axis_vS1_tlast),

      .s_axis_2_tdata (m_axis_vS2_tdata),
      .s_axis_2_tkeep (m_axis_vS2_tkeep),
      .s_axis_2_tuser (m_axis_vS2_tuser),
      .s_axis_2_tvalid(m_axis_vS2_tvalid),
      .s_axis_2_tready(m_axis_vS2_tready),
      .s_axis_2_tlast (m_axis_vS2_tlast),

      .s_axis_3_tdata (m_axis_vS3_tdata),
      .s_axis_3_tkeep (m_axis_vS3_tkeep),
      .s_axis_3_tuser (m_axis_vS3_tuser),
      .s_axis_3_tvalid(m_axis_vS3_tvalid),
      .s_axis_3_tready(m_axis_vS3_tready),
      .s_axis_3_tlast (m_axis_vS3_tlast),

      .s_axis_4_tdata (m_axis_vS4_tdata),
      .s_axis_4_tkeep (m_axis_vS4_tkeep),
      .s_axis_4_tuser (m_axis_vS4_tuser),
      .s_axis_4_tvalid(m_axis_vS4_tvalid),
      .s_axis_4_tready(m_axis_vS4_tready),
      .s_axis_4_tlast (m_axis_vS4_tlast),

      .s_axis_5_tdata (m_axis_vS5_tdata),
      .s_axis_5_tkeep (m_axis_vS5_tkeep),
      .s_axis_5_tuser (m_axis_vS5_tuser),
      .s_axis_5_tvalid(m_axis_vS5_tvalid),
      .s_axis_5_tready(m_axis_vS5_tready),
      .s_axis_5_tlast (m_axis_vS5_tlast),

      .s_axis_6_tdata (m_axis_vS6_tdata),
      .s_axis_6_tkeep (m_axis_vS6_tkeep),
      .s_axis_6_tuser (m_axis_vS6_tuser),
      .s_axis_6_tvalid(m_axis_vS6_tvalid),
      .s_axis_6_tready(m_axis_vS6_tready),
      .s_axis_6_tlast (m_axis_vS6_tlast),

      .s_axis_7_tdata (m_axis_vS7_tdata),
      .s_axis_7_tkeep (m_axis_vS7_tkeep),
      .s_axis_7_tuser (m_axis_vS7_tuser),
      .s_axis_7_tvalid(m_axis_vS7_tvalid),
      .s_axis_7_tready(m_axis_vS7_tready),
      .s_axis_7_tlast (m_axis_vS7_tlast),
      // TX Queues and stats signals (interface to vS Array)
      .nf0_q_size(nf0_q_size),
      .nf1_q_size(nf1_q_size),
      .nf2_q_size(nf2_q_size),
      .nf3_q_size(nf3_q_size),
      .dma_q_size(dma_q_size),

      .bytes_stored(),
      .pkt_stored(),
      .bytes_removed_0(),
      .bytes_removed_1(),
      .bytes_removed_2(),
      .bytes_removed_3(),
      .bytes_removed_4(),
      .pkt_removed_0(),
      .pkt_removed_1(),
      .pkt_removed_2(),
      .pkt_removed_3(),
      .pkt_removed_4(),
      .bytes_dropped(bytes_dropped),
      .pkt_dropped(pkt_dropped),
      // Slave AXI-Lite Ports (interface to Control)
      .S_AXI_ACLK (axi_aclk),
      .S_AXI_ARESETN(axi_resetn),
      .S_AXI_AWADDR(S2_AXI_AWADDR),
      .S_AXI_AWVALID(S2_AXI_AWVALID),
      .S_AXI_WDATA(S2_AXI_WDATA),
      .S_AXI_WSTRB(S2_AXI_WSTRB),
      .S_AXI_WVALID(S2_AXI_WVALID),
      .S_AXI_BREADY(S2_AXI_BREADY),
      .S_AXI_ARADDR(S2_AXI_ARADDR),
      .S_AXI_ARVALID(S2_AXI_ARVALID),
      .S_AXI_RREADY(S2_AXI_RREADY),
      .S_AXI_ARREADY(S2_AXI_ARREADY),
      .S_AXI_RDATA(S2_AXI_RDATA),
      .S_AXI_RRESP(S2_AXI_RRESP),
      .S_AXI_RVALID(S2_AXI_RVALID),
      .S_AXI_WREADY(S2_AXI_WREADY),
      .S_AXI_BRESP(S2_AXI_BRESP),
      .S_AXI_BVALID(S2_AXI_BVALID),
      .S_AXI_AWREADY(S2_AXI_AWREADY)
    );

endmodule
