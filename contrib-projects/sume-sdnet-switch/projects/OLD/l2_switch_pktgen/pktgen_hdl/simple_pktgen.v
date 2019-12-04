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

module simple_pktgen
#(
  //Slave AXI parameters
  parameter C_S_AXI_DATA_WIDTH    = 32,
  parameter C_S_AXI_ADDR_WIDTH    = 32,
  parameter C_BASEADDR            = 32'h00000000,

  // Master AXI Stream Data Width
  parameter C_M_AXIS_DATA_WIDTH=256,
  parameter C_S_AXIS_DATA_WIDTH=256,
  parameter C_M_AXIS_TUSER_WIDTH=128,
  parameter C_S_AXIS_TUSER_WIDTH=128
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
  input                                                           m_axis_0_tready

  // output reg [C_S_AXIS_DATA_WIDTH - 1:0]                          m_axis_1_tdata,
  // output reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_1_tkeep,
  // output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_1_tuser,
  // output reg                                                      m_axis_1_tvalid,
  // output reg                                                      m_axis_1_tlast,
  // input                                                           m_axis_1_tready,
  //
  // output reg [C_S_AXIS_DATA_WIDTH - 1:0]                          m_axis_2_tdata,
  // output reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_2_tkeep,
  // output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_2_tuser,
  // output reg                                                      m_axis_2_tvalid,
  // output reg                                                      m_axis_2_tlast,
  // input                                                           m_axis_2_tready,
  //
  // output reg [C_S_AXIS_DATA_WIDTH - 1:0]                          m_axis_3_tdata,
  // output reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]                  m_axis_3_tkeep,
  // output reg [C_M_AXIS_TUSER_WIDTH-1:0]                           m_axis_3_tuser,
  // output reg                                                      m_axis_3_tvalid,
  // output reg                                                      m_axis_3_tlast,
  // input                                                           m_axis_3_tready,


);

  // ------------ Functions -------------
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
  localparam NUM_PKTGEN = 2; // # of packet to generate
  localparam NUM_TIMER = 1000; // # of cycles
  localparam NUM_STATES = 5; // # of states of FSM

  localparam NUM_PKTGEN_WIDTH = log2(NUM_PKTGEN);
  localparam NUM_TIMER_WIDTH = log2(NUM_TIMER);
  localparam NUM_STATES_WIDTH = log2(NUM_STATES);

  localparam IDLE = 3'b000;
  localparam WAIT_TIMER = 3'b001;
  localparam PKT_GEN = 3'b010;
  localparam WRITE_PKT_PART0 = 3'b011;
  localparam WRITE_PKT_PART1 = 3'b100;

  // ------------- Regs/ wires -----------
  reg [NUM_PKTGEN_WIDTH:0]                  pktgen_counter; // assigned to pktout_reg
  reg [NUM_TIMER:0]                         pktgen_timer; // gap size
  reg [NUM_STATES_WIDTH:0]                  pktgen_state; // FSM states
  reg                                       pktgen_writepart; // Part of packet identifier

  reg [C_S_AXIS_DATA_WIDTH - 1:0]           pktgen_tdata;
  reg [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]   pktgen_tkeep;
  reg [C_M_AXIS_TUSER_WIDTH-1:0]            pktgen_tuser;
  reg                                       pktgen_tvalid;
  reg                                       pktgen_tlast;


  // ------------- Logic ------------
  always @(posedge axis_aclk) begin

    // check reset signal
    if ( ~axis_resetn )  begin

      pktgen_counter <= 0;
      pktgen_timer <= 0;
      pktgen_writepart <= 0;

      pktgen_tdata <= 0;
      pktgen_tkeep <= 0;
      pktgen_tuser <= 0;
      pktgen_tvalid <= 0;
      pktgen_tlast <= 0;

      m_axis_0_tuser <= 0;
      m_axis_0_tdata <= 0;
      m_axis_0_tkeep <= 0;
      m_axis_0_tvalid <= 0;
      m_axis_0_tlast <= 0;

      pktgen_state <= IDLE;

    end
    else begin

      case(pktgen_state)

        IDLE : begin

          pktgen_timer <= 0;
          pktgen_writepart <= 0;

          m_axis_0_tdata  <= 0;
          m_axis_0_tkeep  <= 0;
          m_axis_0_tuser  <= 0;
          m_axis_0_tvalid <= 0;
          m_axis_0_tlast  <= 0;

          m_axis_0_tuser <= 0;
          m_axis_0_tdata <= 0;
          m_axis_0_tkeep <= 0;
          m_axis_0_tvalid <= 0;
          m_axis_0_tlast <= 0;

          pktgen_state <= WAIT_TIMER;

        end // case: IDLE

        WAIT_TIMER : begin

          if( pktgen_timer < NUM_TIMER ) begin
            pktgen_timer <= pktgen_timer + 1;
            pktgen_state <= WAIT_TIMER;
          end
          else begin
            pktgen_timer <= 0;
            pktgen_state <= PKT_GEN;
          end

        end // case: WAIT_TIMER

        PKT_GEN : begin

          // ***************************************************************************************************
          // L2_SWITCH PACKET: From nf_interface_1 to nf_interface_2
          //                   00:00:00:00:01:01 > 00:00:00:00:01:02, length 64, vlan 1, p1
          // Part 0:
          // tdata: 000acc900114000001002e000045000801200081010100000000020100000000
          // tkeep: ffffffff
          // tuser: 00000000000000000000000000040040
          // Part 1:
          // tdata: 00000000000000000000000000000000000000000000fff700080201000a0101
          // tkeep: ffffffff
          // tuser: 00000000000000000000000000000000
          // ***************************************************************************************************
          if ( (pktgen_counter < NUM_PKTGEN) && (pktgen_writepart == 0) ) begin
            pktgen_tdata  <= 256'h000acc900114000001002e000045000801200081010100000000020100000000;
            pktgen_tkeep  <= 32'hffffffff;
            pktgen_tuser  <= 128'h00000000000000000000000000040040;
            pktgen_tvalid <= 1;
            pktgen_tlast  <= 0;

            pktgen_state <= WRITE_PKT_PART0;
          end
          else begin
            pktgen_state <= IDLE;
          end

        end // case: PKT_GEN

        WRITE_PKT_PART0 : begin

          if ( m_axis_0_tready == 0 ) begin
            pktgen_state = WRITE_PKT_PART0;
          end
          else if ( (pktgen_counter < NUM_PKTGEN) && (pktgen_writepart == 0) ) begin

            m_axis_0_tdata <= pktgen_tdata;
            m_axis_0_tuser <= pktgen_tuser;
            m_axis_0_tkeep <= pktgen_tkeep;
            m_axis_0_tvalid <= pktgen_tvalid;
            m_axis_0_tlast <= pktgen_tlast;

            pktgen_writepart <= pktgen_writepart + 1;
            pktgen_counter <= pktgen_counter;
            pktgen_state = WRITE_PKT_PART1;
          end
          else begin
            pktgen_state = IDLE;
          end

        end // case: WRITE_PKT_PART0

        WRITE_PKT_PART1 : begin

          if ( m_axis_0_tready == 0 ) begin
            pktgen_state = WRITE_PKT_PART1;
          end
          else if ( (pktgen_counter < NUM_PKTGEN) && (pktgen_writepart == 1) ) begin
            m_axis_0_tdata  <= 256'h00000000000000000000000000000000000000000000fff700080201000a0101;
            m_axis_0_tuser  <= 128'h00000000000000000000000000000000;
            m_axis_0_tkeep  <= 32'hffffffff;
            m_axis_0_tvalid <= 1;
            m_axis_0_tlast  <= 1;

            pktgen_writepart <= 0;
            pktgen_counter <= pktgen_counter +1;
          end

          pktgen_state = IDLE;
        end // case: WRITE_PKT_PART1

        default : begin
          pktgen_counter <= 0;
          pktgen_timer <= 0;

          pktgen_tdata <= 0;
          pktgen_tkeep <= 0;
          pktgen_tuser <= 0;
          pktgen_tvalid <= 0;
          pktgen_tlast <= 0;

          m_axis_0_tuser <= 0;
          m_axis_0_tdata <= 0;
          m_axis_0_tkeep <= 0;
          m_axis_0_tvalid <= 0;
          m_axis_0_tlast <= 0;

          pktgen_state <= IDLE;
        end // case: default

      endcase // case(state)
    end// else
  end// always @(posedge axis_aclk)


endmodule
