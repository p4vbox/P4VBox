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

`timescale 1ns / 1ps

module output_vs_interface
#(
  // Master AXI Stream Data Width
  parameter C_M_AXIS_DATA_WIDTH=256,
  parameter C_S_AXIS_DATA_WIDTH=256,
  // parameter C_M_AXIS_TUSER_WIDTH=128,
  // parameter C_S_AXIS_TUSER_WIDTH=128,
  parameter C_M_AXIS_TUSER_WIDTH=304,
  parameter C_S_AXIS_TUSER_WIDTH=304,
  // AXI Registers Data Width
  parameter C_S_AXI_DATA_WIDTH    = 32,
  parameter C_S_AXI_ADDR_WIDTH    = 12,
  parameter C_BASEADDR            = 32'h00000000,
  // Number of virtual switches
  parameter NUM_QUEUES=4,
  parameter DIGEST_WIDTH =80,
  parameter Q_SIZE_WIDTH = 16,
  // SI
  parameter QUEUE_DEPTH_BITS = 16
)
(
  // Global Ports
  input                                                         axis_aclk,
  input                                                         axis_resetn,
  // Master Stream Ports (interface to TX queues)
  output [C_M_AXIS_DATA_WIDTH - 1:0]                            m_axis_0_tdata,
  output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]                    m_axis_0_tkeep,
  output [C_M_AXIS_TUSER_WIDTH-1:0]                             m_axis_0_tuser,
  output                                                        m_axis_0_tvalid,
  input                                                         m_axis_0_tready,
  output                                                        m_axis_0_tlast,

  output [C_M_AXIS_DATA_WIDTH - 1:0]                            m_axis_1_tdata,
  output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]                    m_axis_1_tkeep,
  output [C_M_AXIS_TUSER_WIDTH-1:0]                             m_axis_1_tuser,
  output                                                        m_axis_1_tvalid,
  input                                                         m_axis_1_tready,
  output                                                        m_axis_1_tlast,

  output [C_M_AXIS_DATA_WIDTH - 1:0]                            m_axis_2_tdata,
  output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]                    m_axis_2_tkeep,
  output [C_M_AXIS_TUSER_WIDTH-1:0]                             m_axis_2_tuser,
  output                                                        m_axis_2_tvalid,
  input                                                         m_axis_2_tready,
  output                                                        m_axis_2_tlast,

  output [C_M_AXIS_DATA_WIDTH - 1:0]                            m_axis_3_tdata,
  output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]                    m_axis_3_tkeep,
  output [C_M_AXIS_TUSER_WIDTH-1:0]                             m_axis_3_tuser,
  output                                                        m_axis_3_tvalid,
  input                                                         m_axis_3_tready,
  output                                                        m_axis_3_tlast,

  output [C_M_AXIS_DATA_WIDTH - 1:0]                            m_axis_4_tdata,
  output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]                    m_axis_4_tkeep,
  output [C_M_AXIS_TUSER_WIDTH-1:0]                             m_axis_4_tuser,
  output                                                        m_axis_4_tvalid,
  input                                                         m_axis_4_tready,
  output                                                        m_axis_4_tlast,
  // Slave Stream Ports (interface to vS0 ... vSN)
  input [C_S_AXIS_DATA_WIDTH - 1:0]                             s_axis_0_tdata,
  input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                     s_axis_0_tkeep,
  input [C_S_AXIS_TUSER_WIDTH-1:0]                              s_axis_0_tuser,
  input                                                         s_axis_0_tvalid,
  output                                                        s_axis_0_tready,
  input                                                         s_axis_0_tlast,

  input [C_S_AXIS_DATA_WIDTH - 1:0]                             s_axis_1_tdata,
  input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                     s_axis_1_tkeep,
  input [C_S_AXIS_TUSER_WIDTH-1:0]                              s_axis_1_tuser,
  input                                                         s_axis_1_tvalid,
  output                                                        s_axis_1_tready,
  input                                                         s_axis_1_tlast,

  input [C_S_AXIS_DATA_WIDTH - 1:0]                             s_axis_2_tdata,
  input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                     s_axis_2_tkeep,
  input [C_S_AXIS_TUSER_WIDTH-1:0]                              s_axis_2_tuser,
  input                                                         s_axis_2_tvalid,
  output                                                        s_axis_2_tready,
  input                                                         s_axis_2_tlast,

  input [C_S_AXIS_DATA_WIDTH - 1:0]                             s_axis_3_tdata,
  input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                     s_axis_3_tkeep,
  input [C_S_AXIS_TUSER_WIDTH-1:0]                              s_axis_3_tuser,
  input                                                         s_axis_3_tvalid,
  output                                                        s_axis_3_tready,
  input                                                         s_axis_3_tlast,

  input [C_S_AXIS_DATA_WIDTH - 1:0]                             s_axis_4_tdata,
  input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                     s_axis_4_tkeep,
  input [C_S_AXIS_TUSER_WIDTH-1:0]                              s_axis_4_tuser,
  input                                                         s_axis_4_tvalid,
  output                                                        s_axis_4_tready,
  input                                                         s_axis_4_tlast,
  // stats
  output [QUEUE_DEPTH_BITS:0]                                   nf0_q_size,
  output [QUEUE_DEPTH_BITS:0]                                   nf1_q_size,
  output [QUEUE_DEPTH_BITS:0]                                   nf2_q_size,
  output [QUEUE_DEPTH_BITS:0]                                   nf3_q_size,
  output [QUEUE_DEPTH_BITS:0]                                   dma_q_size,

  output  [C_S_AXI_DATA_WIDTH-1:0]                              bytes_stored,
  output  [NUM_QUEUES-1:0]                                      pkt_stored,

  output [C_S_AXI_DATA_WIDTH-1:0]                               bytes_removed_0,
  output [C_S_AXI_DATA_WIDTH-1:0]                               bytes_removed_1,
  output [C_S_AXI_DATA_WIDTH-1:0]                               bytes_removed_2,
  output [C_S_AXI_DATA_WIDTH-1:0]                               bytes_removed_3,
  output [C_S_AXI_DATA_WIDTH-1:0]                               bytes_removed_4,
  output                                                        pkt_removed_0,
  output                                                        pkt_removed_1,
  output                                                        pkt_removed_2,
  output                                                        pkt_removed_3,
  output                                                        pkt_removed_4,

  output [C_S_AXI_DATA_WIDTH-1:0]                               bytes_dropped,
  output [NUM_QUEUES-1:0]                                       pkt_dropped,
  // Slave AXI Ports
  input                                                         S_AXI_ACLK,
  input                                                         S_AXI_ARESETN,
  input      [C_S_AXI_ADDR_WIDTH-1 : 0]                         S_AXI_AWADDR,
  input                                                         S_AXI_AWVALID,
  input      [C_S_AXI_DATA_WIDTH-1 : 0]                         S_AXI_WDATA,
  input      [C_S_AXI_DATA_WIDTH/8-1 : 0]                       S_AXI_WSTRB,
  input                                                         S_AXI_WVALID,
  input                                                         S_AXI_BREADY,
  input      [C_S_AXI_ADDR_WIDTH-1 : 0]                         S_AXI_ARADDR,
  input                                                         S_AXI_ARVALID,
  input                                                         S_AXI_RREADY,
  output                                                        S_AXI_ARREADY,
  output     [C_S_AXI_DATA_WIDTH-1 : 0]                         S_AXI_RDATA,
  output     [1 : 0]                                            S_AXI_RRESP,
  output                                                        S_AXI_RVALID,
  output                                                        S_AXI_WREADY,
  output     [1 :0]                                             S_AXI_BRESP,
  output                                                        S_AXI_BVALID,
  output                                                        S_AXI_AWREADY
);

  // Original Logic to output
    //part of tuser from nf_sume_sdnet (IN)
  // assign nf0_q_size_out = nf0_q_size_in;
  // assign nf1_q_size_out = nf1_q_size_in;
  // assign nf2_q_size_out = nf2_q_size_in;
  // assign nf3_q_size_out = nf3_q_size_in;
  // assign dma_q_size_out = dma_q_size_in;

  // ------------ Begin Queues Logic --------

  function integer log2;
    input integer number;
    begin
      log2=0;
      while(2**log2<number) begin
        log2=log2+1;
      end
    end
  endfunction // log2

  // ------------ Internal Params --------

  localparam  NUM_QUEUES_WIDTH = log2(NUM_QUEUES);


  localparam NUM_STATES = 1;
  localparam IDLE = 0;
  localparam WR_PKT = 1;

  localparam MAX_PKT_SIZE = 2000; // In bytes
  localparam IN_FIFO_DEPTH_BIT = log2(MAX_PKT_SIZE/(C_M_AXIS_DATA_WIDTH / 8));

  // ------------- Regs/ wires -----------
  wire [C_M_AXIS_DATA_WIDTH - 1:0]                      axis_tdata;
  wire [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]              axis_tkeep;
  wire [C_M_AXIS_TUSER_WIDTH-1:0]                       axis_tuser;
  wire                                                  axis_tvalid;
  wire                                                  axis_tready;
  wire                                                  axis_tlast;
  wire [NUM_QUEUES-1:0]                                 nearly_full;
  wire [NUM_QUEUES-1:0]                                 empty;
  wire [C_M_AXIS_DATA_WIDTH-1:0]                        in_tdata      [NUM_QUEUES-1:0];
  wire [((C_M_AXIS_DATA_WIDTH/8))-1:0]                  in_tkeep      [NUM_QUEUES-1:0];
  wire [C_M_AXIS_TUSER_WIDTH-1:0]                       in_tuser      [NUM_QUEUES-1:0];
  wire [NUM_QUEUES-1:0] 	                              in_tvalid;
  wire [NUM_QUEUES-1:0]                                 in_tlast;
  wire [C_M_AXIS_TUSER_WIDTH-1:0]                       fifo_out_tuser[NUM_QUEUES-1:0];
  wire [C_M_AXIS_DATA_WIDTH-1:0]                        fifo_out_tdata[NUM_QUEUES-1:0];
  wire [((C_M_AXIS_DATA_WIDTH/8))-1:0]                  fifo_out_tkeep[NUM_QUEUES-1:0];
  wire [NUM_QUEUES-1:0] 	                              fifo_out_tlast;
  wire                                                  fifo_tvalid;
  wire                                                  fifo_tlast;
  reg [NUM_QUEUES-1:0]                                  rd_en;

  wire [NUM_QUEUES_WIDTH-1:0]                           cur_queue_plus1;
  reg [NUM_QUEUES_WIDTH-1:0]                            cur_queue;
  reg [NUM_QUEUES_WIDTH-1:0]                            cur_queue_next;

  wire [NUM_QUEUES_WIDTH-1:0]                           in_arb_cur_queue;
  // SI: debug
  assign in_arb_cur_queue = cur_queue;

  reg [NUM_STATES-1:0]                state;
  reg [NUM_STATES-1:0]                state_next;

  // SI: debug
  wire [NUM_STATES-1:0]  in_arb_state;
  assign in_arb_state = state;

  // ------------ Modules -------------

  generate
    genvar i;
    for(i=0; i<NUM_QUEUES; i=i+1) begin: in_opi_queues
      fallthrough_small_fifo
      #(
        .WIDTH(C_M_AXIS_DATA_WIDTH+C_M_AXIS_TUSER_WIDTH+C_M_AXIS_DATA_WIDTH/8+1),
        .MAX_DEPTH_BITS(IN_FIFO_DEPTH_BIT)
      )
      in_opi_fifo
      (// Outputs
        .dout                           ({fifo_out_tlast[i], fifo_out_tuser[i], fifo_out_tkeep[i], fifo_out_tdata[i]}),
        .full                           (),
        .nearly_full                    (nearly_full[i]),
        .prog_full                      (),
        .empty                          (empty[i]),
        // Inputs
        .din                            ({in_tlast[i], in_tuser[i], in_tkeep[i], in_tdata[i]}),
        .wr_en                          (in_tvalid[i] & ~nearly_full[i]),
        .rd_en                          (rd_en[i]),
        .reset                          (~axis_resetn),
        .clk                            (axis_aclk)
      );
    end
  endgenerate

  // ------------- Logic ------------

  assign in_tdata[0]        = s_axis_0_tdata;
  assign in_tkeep[0]        = s_axis_0_tkeep;
  assign in_tuser[0]        = s_axis_0_tuser;
  assign in_tvalid[0]       = s_axis_0_tvalid;
  assign in_tlast[0]        = s_axis_0_tlast;
  assign s_axis_0_tready    = !nearly_full[0];

  assign in_tdata[1]        = s_axis_1_tdata;
  assign in_tkeep[1]        = s_axis_1_tkeep;
  assign in_tuser[1]        = s_axis_1_tuser;
  assign in_tvalid[1]       = s_axis_1_tvalid;
  assign in_tlast[1]        = s_axis_1_tlast;
  assign s_axis_1_tready    = !nearly_full[1];

  assign in_tdata[2]        = s_axis_2_tdata;
  assign in_tkeep[2]        = s_axis_2_tkeep;
  assign in_tuser[2]        = s_axis_2_tuser;
  assign in_tvalid[2]       = s_axis_2_tvalid;
  assign in_tlast[2]        = s_axis_2_tlast;
  assign s_axis_2_tready    = !nearly_full[2];

  assign in_tdata[3]        = s_axis_3_tdata;
  assign in_tkeep[3]        = s_axis_3_tkeep;
  assign in_tuser[3]        = s_axis_3_tuser;
  assign in_tvalid[3]       = s_axis_3_tvalid;
  assign in_tlast[3]        = s_axis_3_tlast;
  assign s_axis_3_tready    = !nearly_full[3];

  assign in_tdata[4]        = s_axis_4_tdata;
  assign in_tkeep[4]        = s_axis_4_tkeep;
  assign in_tuser[4]        = s_axis_4_tuser;
  assign in_tvalid[4]       = s_axis_4_tvalid;
  assign in_tlast[4]        = s_axis_4_tlast;
  assign s_axis_4_tready    = !nearly_full[4];

  assign cur_queue_plus1    = (cur_queue == NUM_QUEUES-1) ? 0 : cur_queue + 1;


  assign axis_tuser = fifo_out_tuser[cur_queue];
  assign axis_tdata = fifo_out_tdata[cur_queue];
  assign axis_tlast = fifo_out_tlast[cur_queue];
  assign axis_tkeep = fifo_out_tkeep[cur_queue];
  assign axis_tvalid = ~empty[cur_queue];


  always @(*) begin
    state_next      = state;
    cur_queue_next  = cur_queue;
    rd_en           = 0;

    case(state)

      /* cycle between input queues until one is not empty */
      IDLE: begin
          if(!empty[cur_queue]) begin
            if(axis_tready) begin
              state_next = WR_PKT;
              rd_en[cur_queue] = 1;
            end
          end
          else begin
            cur_queue_next = cur_queue_plus1;
          end
      end

      /* wait until eop */
      WR_PKT: begin
        /* if this is the last word then write it and get out */
        if(axis_tready & axis_tlast) begin
          state_next = IDLE;
          rd_en[cur_queue] = 1;
          cur_queue_next = cur_queue_plus1;
        end
        /* otherwise read and write as usual */
        else if (axis_tready & !empty[cur_queue]) begin
          rd_en[cur_queue] = 1;
        end
      end // case: WR_PKT

    endcase // case(state)
  end // always @ (*)

  always @(posedge axis_aclk) begin
    if(~axis_resetn) begin
       state <= IDLE;
       cur_queue <= 0;
    end
    else begin
       state <= state_next;
       cur_queue <= cur_queue_next;
    end
  end

  //Output queues
    sss_output_queues_ip
  bram_output_queues_1 (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),
    .s_axis_tdata   (axis_tdata),
    .s_axis_tkeep   (axis_tkeep),
    .s_axis_tuser   (axis_tuser),
    .s_axis_tvalid  (axis_tvalid),
    .s_axis_tready  (axis_tready),
    .s_axis_tlast   (axis_tlast),

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
    .S_AXI_ARESETN(S_AXI_ARESETN)
  );

endmodule
