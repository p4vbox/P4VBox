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

module output_p4_interface
#(
    // Number of parallel switches
    parameter NUM_QUEUES=2,
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

    parameter DIGEST_WIDTH =80,
    parameter Q_SIZE_WIDTH = 16
)
(
    // Part 1: System side signals
    // Global Ports
    input axis_aclk,
    input axis_resetn,

    // Master Stream Ports (interface to data path)
    output [C_M_AXIS_DATA_WIDTH - 1:0]                            m_axis_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]                    m_axis_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0]                             m_axis_tuser,
    output                                                        m_axis_tvalid,
    input                                                         m_axis_tready,
    output                                                        m_axis_tlast,

    // Slave Stream Ports (interface to SDNet queues)
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

    // stats nf queues
  	// input [Q_SIZE_WIDTH:0]                                      nf0_q_size_in,
  	// input [Q_SIZE_WIDTH:0]                                      nf1_q_size_in,
  	// input [Q_SIZE_WIDTH:0]                                      nf2_q_size_in,
  	// input [Q_SIZE_WIDTH:0]                                      nf3_q_size_in,
  	// input [Q_SIZE_WIDTH:0]                                      dma_q_size_in,
  	// output [Q_SIZE_WIDTH:0]                                     nf0_q_size_out,
  	// output [Q_SIZE_WIDTH:0]                                     nf1_q_size_out,
  	// output [Q_SIZE_WIDTH:0]                                     nf2_q_size_out,
  	// output [Q_SIZE_WIDTH:0]                                     nf3_q_size_out,
  	// output [Q_SIZE_WIDTH:0]                                     dma_q_size_out,
    // stats pkg queues

    output reg                                                    pkt_fwd

);

  // Original Logic to output
    //part of s_axis_tuser from nf_sume_sdnet (IN)
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

  wire [NUM_QUEUES-1:0]               nearly_full;
  wire [NUM_QUEUES-1:0]               empty;
  wire [C_M_AXIS_DATA_WIDTH-1:0]        in_tdata      [NUM_QUEUES-1:0];
  wire [((C_M_AXIS_DATA_WIDTH/8))-1:0]  in_tkeep      [NUM_QUEUES-1:0];
  wire [C_M_AXIS_TUSER_WIDTH-1:0]             in_tuser      [NUM_QUEUES-1:0];
  wire [NUM_QUEUES-1:0] 	       in_tvalid;
  wire [NUM_QUEUES-1:0]               in_tlast;
  wire [C_M_AXIS_TUSER_WIDTH-1:0]             fifo_out_tuser[NUM_QUEUES-1:0];
  wire [C_M_AXIS_DATA_WIDTH-1:0]        fifo_out_tdata[NUM_QUEUES-1:0];
  wire [((C_M_AXIS_DATA_WIDTH/8))-1:0]  fifo_out_tkeep[NUM_QUEUES-1:0];
  wire [NUM_QUEUES-1:0] 	       fifo_out_tlast;
  wire                                fifo_tvalid;
  wire                                fifo_tlast;
  reg [NUM_QUEUES-1:0]                rd_en;

  wire [NUM_QUEUES_WIDTH-1:0]         cur_queue_plus1;
  reg [NUM_QUEUES_WIDTH-1:0]          cur_queue;
  reg [NUM_QUEUES_WIDTH-1:0]          cur_queue_next;

  // SI: debug
  wire [NUM_QUEUES_WIDTH-1:0]  in_arb_cur_queue;
  assign in_arb_cur_queue = cur_queue;

  reg [NUM_STATES-1:0]                state;
  reg [NUM_STATES-1:0]                state_next;

  // SI: debug
  wire [NUM_STATES-1:0]  in_arb_state;
  assign in_arb_state = state;

  reg				       pkt_fwd_next;

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


  assign m_axis_tuser = fifo_out_tuser[cur_queue];
  assign m_axis_tdata = fifo_out_tdata[cur_queue];
  assign m_axis_tlast = fifo_out_tlast[cur_queue];
  assign m_axis_tkeep = fifo_out_tkeep[cur_queue];
  assign m_axis_tvalid = ~empty[cur_queue];


  always @(*) begin
    state_next      = state;
    cur_queue_next  = cur_queue;
    rd_en           = 0;
    pkt_fwd_next    = 0;

    case(state)

      /* cycle between input queues until one is not empty */
      IDLE: begin
          if(!empty[cur_queue]) begin
            if(m_axis_tready) begin
              state_next = WR_PKT;
              rd_en[cur_queue] = 1;
	            pkt_fwd_next = 1;
            end
          end
          else begin
            cur_queue_next = cur_queue_plus1;
          end
      end

      /* wait until eop */
      WR_PKT: begin
        /* if this is the last word then write it and get out */
        if(m_axis_tready & m_axis_tlast) begin
          state_next = IDLE;
          rd_en[cur_queue] = 1;
          cur_queue_next = cur_queue_plus1;
        end
        /* otherwise read and write as usual */
        else if (m_axis_tready & !empty[cur_queue]) begin
          rd_en[cur_queue] = 1;
        end
      end // case: WR_PKT

    endcase // case(state)
  end // always @ (*)

  always @(posedge axis_aclk) begin
    if(~axis_resetn) begin
       state <= IDLE;
       cur_queue <= 0;
       pkt_fwd <= 0;
    end
    else begin
       state <= state_next;
       cur_queue <= cur_queue_next;
       pkt_fwd <= pkt_fwd_next;
    end
  end



endmodule
