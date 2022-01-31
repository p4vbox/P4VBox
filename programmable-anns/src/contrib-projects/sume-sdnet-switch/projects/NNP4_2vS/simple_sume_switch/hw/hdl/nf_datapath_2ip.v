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

    localparam C_AXIS_TUSER_DIGEST_WIDTH = 304;
    localparam Q_SIZE_WIDTH = 16;
    //internal connectivity
    //(opi = output_p4_interface)
      //nf_sume_sdnet1->opi
    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_0_opi_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_0_opi_tkeep;
    (* mark_debug = "true" *) wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     s_axis_0_opi_tuser;
    (* mark_debug = "true" *) wire                                     s_axis_0_opi_tvalid;
    (* mark_debug = "true" *) wire                                     s_axis_0_opi_tready;
    (* mark_debug = "true" *) wire                                     s_axis_0_opi_tlast;
      //nf_sume_sdnet2->opi
    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_1_opi_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_1_opi_tkeep;
    (* mark_debug = "true" *) wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     s_axis_1_opi_tuser;
    (* mark_debug = "true" *) wire                                     s_axis_1_opi_tvalid;
    (* mark_debug = "true" *) wire                                     s_axis_1_opi_tready;
    (* mark_debug = "true" *) wire                                     s_axis_1_opi_tlast;
      //nf_sume_sdnet3->opi
    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_2_opi_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_2_opi_tkeep;
    (* mark_debug = "true" *) wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     s_axis_2_opi_tuser;
    (* mark_debug = "true" *) wire                                     s_axis_2_opi_tvalid;
    (* mark_debug = "true" *) wire                                     s_axis_2_opi_tready;
    (* mark_debug = "true" *) wire                                     s_axis_2_opi_tlast;
      //nf_sume_sdnet4->opi
    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_3_opi_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_3_opi_tkeep;
    (* mark_debug = "true" *) wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     s_axis_3_opi_tuser;
    (* mark_debug = "true" *) wire                                     s_axis_3_opi_tvalid;
    (* mark_debug = "true" *) wire                                     s_axis_3_opi_tready;
    (* mark_debug = "true" *) wire                                     s_axis_3_opi_tlast;

    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]                  nf0_q_size_opi_out;
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]                  nf1_q_size_opi_out;
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]                  nf2_q_size_opi_out;
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]                  nf3_q_size_opi_out;
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]                  dma_q_size_opi_out;
      //opi->sss_output_queues
    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_opi_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_opi_tkeep;
    (* mark_debug = "true" *) wire [C_AXIS_TUSER_DIGEST_WIDTH-1:0]     m_axis_opi_tuser;
    (* mark_debug = "true" *) wire                                     m_axis_opi_tvalid;
    (* mark_debug = "true" *) wire                                     m_axis_opi_tready;
    (* mark_debug = "true" *) wire                                     m_axis_opi_tlast;

    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]                  nf0_q_size_opi_in;
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]                  nf1_q_size_opi_in;
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]                  nf2_q_size_opi_in;
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]                  nf3_q_size_opi_in;
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]                  dma_q_size_opi_in;
    //(ipi = input_p4_interface)
      //input_arbiter->ipi
    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         s_axis_ipi_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_ipi_tkeep;
    (* mark_debug = "true" *) wire [C_M_AXIS_TUSER_WIDTH-1:0]          s_axis_ipi_tkuser;
    (* mark_debug = "true" *) wire                                     s_axis_ipi_tvalid;
    (* mark_debug = "true" *) wire                                     s_axis_ipi_tready;
    (* mark_debug = "true" *) wire                                     s_axis_ipi_tlast;
      //ipi->nf_sume_sdnet1
    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_0_ipi_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_0_ipi_tkeep;
    (* mark_debug = "true" *) wire [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_0_ipi_tuser;
    (* mark_debug = "true" *) wire                                     m_axis_0_ipi_tvalid;
    (* mark_debug = "true" *) wire                                     m_axis_0_ipi_tready;
    (* mark_debug = "true" *) wire                                     m_axis_0_ipi_tlast;
      //ipi->nf_sume_sdnet2
    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_1_ipi_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_1_ipi_tkeep;
    (* mark_debug = "true" *) wire [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_1_ipi_tuser;
    (* mark_debug = "true" *) wire                                     m_axis_1_ipi_tvalid;
    (* mark_debug = "true" *) wire                                     m_axis_1_ipi_tready;
    (* mark_debug = "true" *) wire                                     m_axis_1_ipi_tlast;
      //ipi->nf_sume_sdnet3
    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_2_ipi_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_2_ipi_tkeep;
    (* mark_debug = "true" *) wire [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_2_ipi_tuser;
    (* mark_debug = "true" *) wire                                     m_axis_2_ipi_tvalid;
    (* mark_debug = "true" *) wire                                     m_axis_2_ipi_tready;
    (* mark_debug = "true" *) wire                                     m_axis_2_ipi_tlast;
      //ipi->nf_sume_sdnet4
    (* mark_debug = "true" *) wire [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_3_ipi_tdata;
    (* mark_debug = "true" *) wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_3_ipi_tkeep;
    (* mark_debug = "true" *) wire [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_3_ipi_tuser;
    (* mark_debug = "true" *) wire                                     m_axis_3_ipi_tvalid;
    (* mark_debug = "true" *) wire                                     m_axis_3_ipi_tready;
    (* mark_debug = "true" *) wire                                     m_axis_3_ipi_tlast;
      //cpi->nf_sume_sdnet0
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S1_AXI_0_AWADDR;
    (* mark_debug = "true" *) wire                                     S1_AXI_0_AWVALID;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S1_AXI_0_WDATA;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH/8-1 : 0]        S1_AXI_0_WSTRB;
    (* mark_debug = "true" *) wire                                     S1_AXI_0_WVALID;
    (* mark_debug = "true" *) wire                                     S1_AXI_0_BREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S1_AXI_0_ARADDR;
    (* mark_debug = "true" *) wire                                     S1_AXI_0_ARVALID;
    (* mark_debug = "true" *) wire                                     S1_AXI_0_RREADY;
    (* mark_debug = "true" *) wire                                     S1_AXI_0_ARREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S1_AXI_0_RDATA;
    (* mark_debug = "true" *) wire [1 : 0]                             S1_AXI_0_RRESP;
    (* mark_debug = "true" *) wire                                     S1_AXI_0_RVALID;
    (* mark_debug = "true" *) wire                                     S1_AXI_0_WREADY;
    (* mark_debug = "true" *) wire [1 : 0]                             S1_AXI_0_BRESP;
    (* mark_debug = "true" *) wire                                     S1_AXI_0_BVALID;
    (* mark_debug = "true" *) wire                                     S1_AXI_0_AWREADY;
      //cpi->nf_sume_sdnet1
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S1_AXI_1_AWADDR;
    (* mark_debug = "true" *) wire                                     S1_AXI_1_AWVALID;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S1_AXI_1_WDATA;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH/8-1 : 0]        S1_AXI_1_WSTRB;
    (* mark_debug = "true" *) wire                                     S1_AXI_1_WVALID;
    (* mark_debug = "true" *) wire                                     S1_AXI_1_BREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S1_AXI_1_ARADDR;
    (* mark_debug = "true" *) wire                                     S1_AXI_1_ARVALID;
    (* mark_debug = "true" *) wire                                     S1_AXI_1_RREADY;
    (* mark_debug = "true" *) wire                                     S1_AXI_1_ARREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S1_AXI_1_RDATA;
    (* mark_debug = "true" *) wire [1 : 0]                             S1_AXI_1_RRESP;
    (* mark_debug = "true" *) wire                                     S1_AXI_1_RVALID;
    (* mark_debug = "true" *) wire                                     S1_AXI_1_WREADY;
    (* mark_debug = "true" *) wire [1 : 0]                             S1_AXI_1_BRESP;
    (* mark_debug = "true" *) wire                                     S1_AXI_1_BVALID;
    (* mark_debug = "true" *) wire                                     S1_AXI_1_AWREADY;
      //cpi->nf_sume_sdnet2
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S1_AXI_2_AWADDR;
    (* mark_debug = "true" *) wire                                     S1_AXI_2_AWVALID;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S1_AXI_2_WDATA;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH/8-1 : 0]        S1_AXI_2_WSTRB;
    (* mark_debug = "true" *) wire                                     S1_AXI_2_WVALID;
    (* mark_debug = "true" *) wire                                     S1_AXI_2_BREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S1_AXI_2_ARADDR;
    (* mark_debug = "true" *) wire                                     S1_AXI_2_ARVALID;
    (* mark_debug = "true" *) wire                                     S1_AXI_2_RREADY;
    (* mark_debug = "true" *) wire                                     S1_AXI_2_ARREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S1_AXI_2_RDATA;
    (* mark_debug = "true" *) wire [1 : 0]                             S1_AXI_2_RRESP;
    (* mark_debug = "true" *) wire                                     S1_AXI_2_RVALID;
    (* mark_debug = "true" *) wire                                     S1_AXI_2_WREADY;
    (* mark_debug = "true" *) wire [1 : 0]                             S1_AXI_2_BRESP;
    (* mark_debug = "true" *) wire                                     S1_AXI_2_BVALID;
    (* mark_debug = "true" *) wire                                     S1_AXI_2_AWREADY;
      //cpi->nf_sume_sdnet1
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S1_AXI_3_AWADDR;
    (* mark_debug = "true" *) wire                                     S1_AXI_3_AWVALID;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S1_AXI_3_WDATA;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH/8-1 : 0]        S1_AXI_3_WSTRB;
    (* mark_debug = "true" *) wire                                     S1_AXI_3_WVALID;
    (* mark_debug = "true" *) wire                                     S1_AXI_3_BREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_ADDR_WIDTH-1 : 0]          S1_AXI_3_ARADDR;
    (* mark_debug = "true" *) wire                                     S1_AXI_3_ARVALID;
    (* mark_debug = "true" *) wire                                     S1_AXI_3_RREADY;
    (* mark_debug = "true" *) wire                                     S1_AXI_3_ARREADY;
    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1 : 0]          S1_AXI_3_RDATA;
    (* mark_debug = "true" *) wire [1 : 0]                             S1_AXI_3_RRESP;
    (* mark_debug = "true" *) wire                                     S1_AXI_3_RVALID;
    (* mark_debug = "true" *) wire                                     S1_AXI_3_WREADY;
    (* mark_debug = "true" *) wire [1 : 0]                             S1_AXI_3_BRESP;
    (* mark_debug = "true" *) wire                                     S1_AXI_3_BVALID;
    (* mark_debug = "true" *) wire                                     S1_AXI_3_AWREADY;

    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]    nf0_q_size;
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]    nf1_q_size;
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]    nf2_q_size;
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]    nf3_q_size;
    (* mark_debug = "true" *) wire [Q_SIZE_WIDTH-1:0]    dma_q_size;


    //Input Arbiter
      input_arbiter_drr_ip
    input_arbiter_drr_v1_0 (
      .axis_aclk(axis_aclk),
      .axis_resetn(axis_resetn),
      // input_arbiter->input_p4_interface
      .m_axis_tdata (s_axis_ipi_tdata),
      .m_axis_tkeep (s_axis_ipi_tkeep),
      .m_axis_tuser (s_axis_ipi_tkuser),
      .m_axis_tvalid(s_axis_ipi_tvalid),
      .m_axis_tready(s_axis_ipi_tready),
      .m_axis_tlast (s_axis_ipi_tlast),
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
      .S_AXI_ACLK (axi_aclk),
      .S_AXI_ARESETN(axi_resetn),
      .pkt_fwd()
    );

    //Input P4 Interface
     input_p4_interface
    input_p4_interface_0 (
      // Global Ports
      .axis_aclk(axis_aclk),
      .axis_resetn(axis_resetn),
      // Master Stream Ports (interface to nf_sume_sdnet_ips)
      .m_axis_0_tdata (m_axis_0_ipi_tdata),
      .m_axis_0_tkeep (m_axis_0_ipi_tkeep),
      .m_axis_0_tuser (m_axis_0_ipi_tuser),//part of tuser
      .m_axis_0_tvalid(m_axis_0_ipi_tvalid),
      .m_axis_0_tlast (m_axis_0_ipi_tlast),
      .m_axis_0_tready(m_axis_0_ipi_tready),

      .m_axis_1_tdata (m_axis_1_ipi_tdata),
      .m_axis_1_tkeep (m_axis_1_ipi_tkeep),
      .m_axis_1_tuser (m_axis_1_ipi_tuser),//part of tuser
      .m_axis_1_tvalid(m_axis_1_ipi_tvalid),
      .m_axis_1_tlast (m_axis_1_ipi_tlast),
      .m_axis_1_tready(m_axis_1_ipi_tready),

      .m_axis_2_tdata (m_axis_2_ipi_tdata),
      .m_axis_2_tkeep (m_axis_2_ipi_tkeep),
      .m_axis_2_tuser (m_axis_2_ipi_tuser),//part of tuser
      .m_axis_2_tvalid(m_axis_2_ipi_tvalid),
      .m_axis_2_tlast (m_axis_2_ipi_tlast),
      .m_axis_2_tready(m_axis_2_ipi_tready),

      .m_axis_3_tdata (m_axis_3_ipi_tdata),
      .m_axis_3_tkeep (m_axis_3_ipi_tkeep),
      .m_axis_3_tuser (m_axis_3_ipi_tuser),//part of tuser
      .m_axis_3_tvalid(m_axis_3_ipi_tvalid),
      .m_axis_3_tlast (m_axis_3_ipi_tlast),
      .m_axis_3_tready(m_axis_3_ipi_tready),
      // Slave Stream Ports (interface to input_arbiter)
      .s_axis_tdata (s_axis_ipi_tdata),
      .s_axis_tkeep (s_axis_ipi_tkeep),
      .s_axis_tuser (s_axis_ipi_tkuser),//part of tuser
      .s_axis_tvalid(s_axis_ipi_tvalid),
      .s_axis_tlast (s_axis_ipi_tlast),
      .s_axis_tready(s_axis_ipi_tready),
      // Slave AXI Ports
      .S_AXI_ACLK (axi_aclk),
      .S_AXI_ARESETN(axi_resetn)
    );

    // Control P4 Interface
      control_p4_interface_ip
    control_p4_interface_0  (
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
      .S_AXI_0_AWADDR(S1_AXI_0_AWADDR),
      .S_AXI_0_AWVALID(S1_AXI_0_AWVALID),
      .S_AXI_0_WDATA(S1_AXI_0_WDATA),
      .S_AXI_0_WSTRB(S1_AXI_0_WSTRB),
      .S_AXI_0_WVALID(S1_AXI_0_WVALID),
      .S_AXI_0_BREADY(S1_AXI_0_BREADY),
      .S_AXI_0_ARADDR(S1_AXI_0_ARADDR),
      .S_AXI_0_ARVALID(S1_AXI_0_ARVALID),
      .S_AXI_0_RREADY(S1_AXI_0_RREADY),
      .S_AXI_0_ARREADY(S1_AXI_0_ARREADY),
      .S_AXI_0_RDATA(S1_AXI_0_RDATA),
      .S_AXI_0_RRESP(S1_AXI_0_RRESP),
      .S_AXI_0_RVALID(S1_AXI_0_RVALID),
      .S_AXI_0_WREADY(S1_AXI_0_WREADY),
      .S_AXI_0_BRESP(S1_AXI_0_BRESP),
      .S_AXI_0_BVALID(S1_AXI_0_BVALID),
      .S_AXI_0_AWREADY(S1_AXI_0_AWREADY),
      // AXI4LITE Control Slave 1
      .S_AXI_1_AWADDR(S1_AXI_1_AWADDR),
      .S_AXI_1_AWVALID(S1_AXI_1_AWVALID),
      .S_AXI_1_WDATA(S1_AXI_1_WDATA),
      .S_AXI_1_WSTRB(S1_AXI_1_WSTRB),
      .S_AXI_1_WVALID(S1_AXI_1_WVALID),
      .S_AXI_1_BREADY(S1_AXI_1_BREADY),
      .S_AXI_1_ARADDR(S1_AXI_1_ARADDR),
      .S_AXI_1_ARVALID(S1_AXI_1_ARVALID),
      .S_AXI_1_RREADY(S1_AXI_1_RREADY),
      .S_AXI_1_ARREADY(S1_AXI_1_ARREADY),
      .S_AXI_1_RDATA(S1_AXI_1_RDATA),
      .S_AXI_1_RRESP(S1_AXI_1_RRESP),
      .S_AXI_1_RVALID(S1_AXI_1_RVALID),
      .S_AXI_1_WREADY(S1_AXI_1_WREADY),
      .S_AXI_1_BRESP(S1_AXI_1_BRESP),
      .S_AXI_1_BVALID(S1_AXI_1_BVALID),
      .S_AXI_1_AWREADY(S1_AXI_1_AWREADY),
      // AXI4LITE Control Slave 2
      .S_AXI_2_AWADDR(S1_AXI_2_AWADDR),
      .S_AXI_2_AWVALID(S1_AXI_2_AWVALID),
      .S_AXI_2_WDATA(S1_AXI_2_WDATA),
      .S_AXI_2_WSTRB(S1_AXI_2_WSTRB),
      .S_AXI_2_WVALID(S1_AXI_2_WVALID),
      .S_AXI_2_BREADY(S1_AXI_2_BREADY),
      .S_AXI_2_ARADDR(S1_AXI_2_ARADDR),
      .S_AXI_2_ARVALID(S1_AXI_2_ARVALID),
      .S_AXI_2_RREADY(S1_AXI_2_RREADY),
      .S_AXI_2_ARREADY(S1_AXI_2_ARREADY),
      .S_AXI_2_RDATA(S1_AXI_2_RDATA),
      .S_AXI_2_RRESP(S1_AXI_2_RRESP),
      .S_AXI_2_RVALID(S1_AXI_2_RVALID),
      .S_AXI_2_WREADY(S1_AXI_2_WREADY),
      .S_AXI_2_BRESP(S1_AXI_2_BRESP),
      .S_AXI_2_BVALID(S1_AXI_2_BVALID),
      .S_AXI_2_AWREADY(S1_AXI_2_AWREADY),
      // AXI4LITE Control Slave 3
      .S_AXI_3_AWADDR(S1_AXI_3_AWADDR),
      .S_AXI_3_AWVALID(S1_AXI_3_AWVALID),
      .S_AXI_3_WDATA(S1_AXI_3_WDATA),
      .S_AXI_3_WSTRB(S1_AXI_3_WSTRB),
      .S_AXI_3_WVALID(S1_AXI_3_WVALID),
      .S_AXI_3_BREADY(S1_AXI_3_BREADY),
      .S_AXI_3_ARADDR(S1_AXI_3_ARADDR),
      .S_AXI_3_ARVALID(S1_AXI_3_ARVALID),
      .S_AXI_3_RREADY(S1_AXI_3_RREADY),
      .S_AXI_3_ARREADY(S1_AXI_3_ARREADY),
      .S_AXI_3_RDATA(S1_AXI_3_RDATA),
      .S_AXI_3_RRESP(S1_AXI_3_RRESP),
      .S_AXI_3_RVALID(S1_AXI_3_RVALID),
      .S_AXI_3_WREADY(S1_AXI_3_WREADY),
      .S_AXI_3_BRESP(S1_AXI_3_BRESP),
      .S_AXI_3_BVALID(S1_AXI_3_BVALID),
      .S_AXI_3_AWREADY(S1_AXI_3_AWREADY),
      // AXILITE clock
      .M_AXI_ACLK (axi_aclk),
      .M_AXI_ARESETN(axi_resetn)
    );


    // SUME SDNet Module 0
      nf_sdnet_vSwitch0_ip
    sdnet_vSwitch0  (
      .axis_aclk(axis_aclk),
      .axis_resetn(axis_resetn),
      //nf_sume_sdnet->output_p4_interface->sss_output_queues
      .m_axis_tdata (s_axis_0_opi_tdata),
      .m_axis_tkeep (s_axis_0_opi_tkeep),
      .m_axis_tuser (s_axis_0_opi_tuser),
      .m_axis_tvalid(s_axis_0_opi_tvalid),
      .m_axis_tready(s_axis_0_opi_tready),
      .m_axis_tlast (s_axis_0_opi_tlast),
      //input_arbiter->input_p4_interface->nf_sume_sdnet
      .s_axis_tdata (m_axis_0_ipi_tdata),
      .s_axis_tkeep (m_axis_0_ipi_tkeep),
      .s_axis_tuser ({dma_q_size_opi_in,
                      nf3_q_size_opi_in,
                      nf2_q_size_opi_in,
                      nf1_q_size_opi_in,
                      nf0_q_size_opi_in,
                      m_axis_0_ipi_tuser[C_M_AXIS_TUSER_WIDTH-DIGEST_WIDTH-1:0]}),
      .s_axis_tvalid(m_axis_0_ipi_tvalid),
      .s_axis_tready(m_axis_0_ipi_tready),
      .s_axis_tlast (m_axis_0_ipi_tlast),

      .S_AXI_AWADDR(S1_AXI_0_AWADDR),
      .S_AXI_AWVALID(S1_AXI_0_AWVALID),
      .S_AXI_WDATA(S1_AXI_0_WDATA),
      .S_AXI_WSTRB(S1_AXI_0_WSTRB),
      .S_AXI_WVALID(S1_AXI_0_WVALID),
      .S_AXI_BREADY(S1_AXI_0_BREADY),
      .S_AXI_ARADDR(S1_AXI_0_ARADDR),
      .S_AXI_ARVALID(S1_AXI_0_ARVALID),
      .S_AXI_RREADY(S1_AXI_0_RREADY),
      .S_AXI_ARREADY(S1_AXI_0_ARREADY),
      .S_AXI_RDATA(S1_AXI_0_RDATA),
      .S_AXI_RRESP(S1_AXI_0_RRESP),
      .S_AXI_RVALID(S1_AXI_0_RVALID),
      .S_AXI_WREADY(S1_AXI_0_WREADY),
      .S_AXI_BRESP(S1_AXI_0_BRESP),
      .S_AXI_BVALID(S1_AXI_0_BVALID),
      .S_AXI_AWREADY(S1_AXI_0_AWREADY),
      .S_AXI_ACLK (axi_aclk),
      .S_AXI_ARESETN(axi_resetn)
    );


    // SUME SDNet Module 1
      nf_sdnet_vSwitch1_ip
    sdnet_vSwitch1  (
      .axis_aclk(axis_aclk),
      .axis_resetn(axis_resetn),
      //nf_sume_sdnet->output_p4_interface->sss_output_queues
      .m_axis_tdata (s_axis_1_opi_tdata),
      .m_axis_tkeep (s_axis_1_opi_tkeep),
      .m_axis_tuser (s_axis_1_opi_tuser),
      .m_axis_tvalid(s_axis_1_opi_tvalid),
      .m_axis_tready(s_axis_1_opi_tready),
      .m_axis_tlast (s_axis_1_opi_tlast),
      //input_arbiter->input_p4_interface->nf_sume_sdnet
      .s_axis_tdata (m_axis_1_ipi_tdata),
      .s_axis_tkeep (m_axis_1_ipi_tkeep),
      .s_axis_tuser ({dma_q_size_opi_in,
                      nf3_q_size_opi_in,
                      nf2_q_size_opi_in,
                      nf1_q_size_opi_in,
                      nf0_q_size_opi_in,
                      m_axis_1_ipi_tuser[C_M_AXIS_TUSER_WIDTH-DIGEST_WIDTH-1:0]}),
      .s_axis_tvalid(m_axis_1_ipi_tvalid),
      .s_axis_tready(m_axis_1_ipi_tready),
      .s_axis_tlast (m_axis_1_ipi_tlast),

      .S_AXI_AWADDR(S1_AXI_1_AWADDR),
      .S_AXI_AWVALID(S1_AXI_1_AWVALID),
      .S_AXI_WDATA(S1_AXI_1_WDATA),
      .S_AXI_WSTRB(S1_AXI_1_WSTRB),
      .S_AXI_WVALID(S1_AXI_1_WVALID),
      .S_AXI_BREADY(S1_AXI_1_BREADY),
      .S_AXI_ARADDR(S1_AXI_1_ARADDR),
      .S_AXI_ARVALID(S1_AXI_1_ARVALID),
      .S_AXI_RREADY(S1_AXI_1_RREADY),
      .S_AXI_ARREADY(S1_AXI_1_ARREADY),
      .S_AXI_RDATA(S1_AXI_1_RDATA),
      .S_AXI_RRESP(S1_AXI_1_RRESP),
      .S_AXI_RVALID(S1_AXI_1_RVALID),
      .S_AXI_WREADY(S1_AXI_1_WREADY),
      .S_AXI_BRESP(S1_AXI_1_BRESP),
      .S_AXI_BVALID(S1_AXI_1_BVALID),
      .S_AXI_AWREADY(S1_AXI_1_AWREADY),
      .S_AXI_ACLK (axi_aclk),
      .S_AXI_ARESETN(axi_resetn)
    );


    // // SUME SDNet Module 2
    //   nf_sdnet_vSwitch2_ip
    // sdnet_vSwitch2  (
    //   .axis_aclk(axis_aclk),
    //   .axis_resetn(axis_resetn),
    //   //nf_sume_sdnet->output_p4_interface->sss_output_queues
    //   .m_axis_tdata (s_axis_2_opi_tdata),
    //   .m_axis_tkeep (s_axis_2_opi_tkeep),
    //   .m_axis_tuser (s_axis_2_opi_tuser),
    //   .m_axis_tvalid(s_axis_2_opi_tvalid),
    //   .m_axis_tready(s_axis_2_opi_tready),
    //   .m_axis_tlast (s_axis_2_opi_tlast),
    //   //input_arbiter->input_p4_interface->nf_sume_sdnet
    //   .s_axis_tdata (m_axis_2_ipi_tdata),
    //   .s_axis_tkeep (m_axis_2_ipi_tkeep),
    //   .s_axis_tuser ({dma_q_size_opi_in,
    //                   nf3_q_size_opi_in,
    //                   nf2_q_size_opi_in,
    //                   nf1_q_size_opi_in,
    //                   nf0_q_size_opi_in,
    //                   m_axis_2_ipi_tuser[C_M_AXIS_TUSER_WIDTH-DIGEST_WIDTH-1:0]}),
    //   .s_axis_tvalid(m_axis_2_ipi_tvalid),
    //   .s_axis_tready(m_axis_2_ipi_tready),
    //   .s_axis_tlast (m_axis_2_ipi_tlast),
    //
    //   .S_AXI_AWADDR(S1_AXI_2_AWADDR),
    //   .S_AXI_AWVALID(S1_AXI_2_AWVALID),
    //   .S_AXI_WDATA(S1_AXI_2_WDATA),
    //   .S_AXI_WSTRB(S1_AXI_2_WSTRB),
    //   .S_AXI_WVALID(S1_AXI_2_WVALID),
    //   .S_AXI_BREADY(S1_AXI_2_BREADY),
    //   .S_AXI_ARADDR(S1_AXI_2_ARADDR),
    //   .S_AXI_ARVALID(S1_AXI_2_ARVALID),
    //   .S_AXI_RREADY(S1_AXI_2_RREADY),
    //   .S_AXI_ARREADY(S1_AXI_2_ARREADY),
    //   .S_AXI_RDATA(S1_AXI_2_RDATA),
    //   .S_AXI_RRESP(S1_AXI_2_RRESP),
    //   .S_AXI_RVALID(S1_AXI_2_RVALID),
    //   .S_AXI_WREADY(S1_AXI_2_WREADY),
    //   .S_AXI_BRESP(S1_AXI_2_BRESP),
    //   .S_AXI_BVALID(S1_AXI_2_BVALID),
    //   .S_AXI_AWREADY(S1_AXI_2_AWREADY),
    //   .S_AXI_ACLK (axi_aclk),
    //   .S_AXI_ARESETN(axi_resetn)
    // );
    //
    //
    // // SUME SDNet Module 3
    //   nf_sdnet_vSwitch3_ip
    // sdnet_vSwitch3  (
    //   .axis_aclk(axis_aclk),
    //   .axis_resetn(axis_resetn),
    //   //nf_sume_sdnet->output_p4_interface->sss_output_queues
    //   .m_axis_tdata (s_axis_3_opi_tdata),
    //   .m_axis_tkeep (s_axis_3_opi_tkeep),
    //   .m_axis_tuser (s_axis_3_opi_tuser),
    //   .m_axis_tvalid(s_axis_3_opi_tvalid),
    //   .m_axis_tready(s_axis_3_opi_tready),
    //   .m_axis_tlast (s_axis_3_opi_tlast),
    //   //input_arbiter->input_p4_interface->nf_sume_sdnet
    //   .s_axis_tdata (m_axis_3_ipi_tdata),
    //   .s_axis_tkeep (m_axis_3_ipi_tkeep),
    //   .s_axis_tuser ({dma_q_size_opi_in,
    //                   nf3_q_size_opi_in,
    //                   nf2_q_size_opi_in,
    //                   nf1_q_size_opi_in,
    //                   nf0_q_size_opi_in,
    //                   m_axis_3_ipi_tuser[C_M_AXIS_TUSER_WIDTH-DIGEST_WIDTH-1:0]}),
    //   .s_axis_tvalid(m_axis_3_ipi_tvalid),
    //   .s_axis_tready(m_axis_3_ipi_tready),
    //   .s_axis_tlast (m_axis_3_ipi_tlast),
    //
    //   .S_AXI_AWADDR(S1_AXI_3_AWADDR),
    //   .S_AXI_AWVALID(S1_AXI_3_AWVALID),
    //   .S_AXI_WDATA(S1_AXI_3_WDATA),
    //   .S_AXI_WSTRB(S1_AXI_3_WSTRB),
    //   .S_AXI_WVALID(S1_AXI_3_WVALID),
    //   .S_AXI_BREADY(S1_AXI_3_BREADY),
    //   .S_AXI_ARADDR(S1_AXI_3_ARADDR),
    //   .S_AXI_ARVALID(S1_AXI_3_ARVALID),
    //   .S_AXI_RREADY(S1_AXI_3_RREADY),
    //   .S_AXI_ARREADY(S1_AXI_3_ARREADY),
    //   .S_AXI_RDATA(S1_AXI_3_RDATA),
    //   .S_AXI_RRESP(S1_AXI_3_RRESP),
    //   .S_AXI_RVALID(S1_AXI_3_RVALID),
    //   .S_AXI_WREADY(S1_AXI_3_WREADY),
    //   .S_AXI_BRESP(S1_AXI_3_BRESP),
    //   .S_AXI_BVALID(S1_AXI_3_BVALID),
    //   .S_AXI_AWREADY(S1_AXI_3_AWREADY),
    //   .S_AXI_ACLK (axi_aclk),
    //   .S_AXI_ARESETN(axi_resetn)
    // );

    (* mark_debug = "true" *) wire [C_S_AXI_DATA_WIDTH-1:0] bytes_dropped;
    (* mark_debug = "true" *) wire [5-1:0] pkt_dropped;

//    assign nf0_q_size = 'd12;
//    assign nf1_q_size = 'd13;
//    assign nf2_q_size = 'd14;
//    assign nf3_q_size = 'd15;
//    assign dma_q_size = 'd16;

    //Output P4 Interface
      output_p4_interface
    output_p4_interface_0 (
      // Global Ports
      .axis_aclk(axis_aclk),
      .axis_resetn(axis_resetn),
      // Master Stream Ports (interface to nf_sume_sdnet_ips)
      .m_axis_tdata   (m_axis_opi_tdata),
      .m_axis_tkeep   (m_axis_opi_tkeep),
      .m_axis_tuser   (m_axis_opi_tuser),
      .m_axis_tvalid  (m_axis_opi_tvalid),
      .m_axis_tlast   (m_axis_opi_tlast),
      .m_axis_tready  (m_axis_opi_tready),
      // Slave Stream Ports (interface to input_arbiter)
      .s_axis_0_tdata (s_axis_0_opi_tdata),
      .s_axis_0_tkeep (s_axis_0_opi_tkeep),
      .s_axis_0_tuser (s_axis_0_opi_tuser),
      .s_axis_0_tvalid(s_axis_0_opi_tvalid),
      .s_axis_0_tlast (s_axis_0_opi_tlast),
      .s_axis_0_tready(s_axis_0_opi_tready),

      .s_axis_1_tdata (s_axis_1_opi_tdata),
      .s_axis_1_tkeep (s_axis_1_opi_tkeep),
      .s_axis_1_tuser (s_axis_1_opi_tuser),
      .s_axis_1_tvalid(s_axis_1_opi_tvalid),
      .s_axis_1_tlast (s_axis_1_opi_tlast),
      .s_axis_1_tready(s_axis_1_opi_tready),

      .s_axis_2_tdata (s_axis_2_opi_tdata),
      .s_axis_2_tkeep (s_axis_2_opi_tkeep),
      .s_axis_2_tuser (s_axis_2_opi_tuser),
      .s_axis_2_tvalid(s_axis_2_opi_tvalid),
      .s_axis_2_tlast (s_axis_2_opi_tlast),
      .s_axis_2_tready(s_axis_2_opi_tready),

      .s_axis_3_tdata (s_axis_3_opi_tdata),
      .s_axis_3_tkeep (s_axis_3_opi_tkeep),
      .s_axis_3_tuser (s_axis_3_opi_tuser),
      .s_axis_3_tvalid(s_axis_3_opi_tvalid),
      .s_axis_3_tlast (s_axis_3_opi_tlast),
      .s_axis_3_tready(s_axis_3_opi_tready),
      //Queue size ports
      // .nf0_q_size_in(nf0_q_size_opi_out),
      // .nf1_q_size_in(nf1_q_size_opi_out),
      // .nf2_q_size_in(nf2_q_size_opi_out),
      // .nf3_q_size_in(nf3_q_size_opi_out),
      // .dma_q_size_in(dma_q_size_opi_out),
      //
      // .nf0_q_size_out(nf0_q_size_opi_in),
      // .nf1_q_size_out(nf1_q_size_opi_in),
      // .nf2_q_size_out(nf2_q_size_opi_in),
      // .nf3_q_size_out(nf3_q_size_opi_in),
      // .dma_q_size_out(dma_q_size_opi_in),

      .s_axis_4_tdata (),
      .s_axis_4_tkeep (),
      .s_axis_4_tuser (),
      .s_axis_4_tvalid(),
      .s_axis_4_tready(),
      .s_axis_4_tlast (),
      .pkt_fwd()
    );


      pkt_counter
    packet_counter_inst (
        .clk_200                (axis_aclk),
        .resetn                 (axis_resetn),
        .resetn_sw              (),
        .axis_tvalid            (m_axis_opi_tvalid),
        .axis_tlast             (m_axis_opi_tlast),
        .packet_counter         (S2_AXI_RDATA)
    );
    //Output queues
      sss_output_queues_ip
    bram_output_queues_1 (
      .axis_aclk(axis_aclk),
      .axis_resetn(axis_resetn),
      .s_axis_tdata   (m_axis_opi_tdata),
      .s_axis_tkeep   (m_axis_opi_tkeep),
      .s_axis_tuser   (m_axis_opi_tuser),
      .s_axis_tvalid  (m_axis_opi_tvalid),
      .s_axis_tready  (m_axis_opi_tready),
      .s_axis_tlast   (m_axis_opi_tlast),

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

      .nf0_q_size(nf0_q_size_opi_in),
      .nf1_q_size(nf1_q_size_opi_in),
      .nf2_q_size(nf2_q_size_opi_in),
      .nf3_q_size(nf3_q_size_opi_in),
      .dma_q_size(dma_q_size_opi_in),

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
      .S_AXI_RDATA(),
      .S_AXI_RRESP(S2_AXI_RRESP),
      .S_AXI_RVALID(S2_AXI_RVALID),
      .S_AXI_WREADY(S2_AXI_WREADY),
      .S_AXI_BRESP(S2_AXI_BRESP),
      .S_AXI_BVALID(S2_AXI_BVALID),
      .S_AXI_AWREADY(S2_AXI_AWREADY),
      .S_AXI_ACLK (axi_aclk),
      .S_AXI_ARESETN(axi_resetn)
    );

endmodule
