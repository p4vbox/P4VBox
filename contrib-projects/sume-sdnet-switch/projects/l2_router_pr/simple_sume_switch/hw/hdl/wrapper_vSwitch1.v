`timescale 1ns / 1ps

module wrapper_vSwitch
#(
    //Master AXI Stream Data Width
    parameter                                                      C_M_AXIS_DATA_WIDTH = 256,
    parameter                                                      C_S_AXIS_DATA_WIDTH = 256,
    parameter                                                      C_M_AXIS_TUSER_WIDTH = 128,
    parameter                                                      C_S_AXIS_TUSER_WIDTH = 128,
    // AXI Registers Data Width
    parameter                                                      C_S_AXI_DATA_WIDTH = 32,
    parameter                                                      C_S_AXI_ADDR_WIDTH = 12,
    // SDNet Address Width
    parameter                                                      SDNET_ADDR_WIDTH = 12,
    parameter                                                      DIGEST_WIDTH = 256
)
(
    // AXIS CLK & RST SIGNALS
    input                                                           axis_aclk,
    input                                                           axis_resetn, // Need to invert this for the SDNet block (this is active low)
    // AXIS PACKET OUTPUT INTERFACE
    output          [C_M_AXIS_DATA_WIDTH - 1:0]                     m_axis_tdata,
    output          [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0]             m_axis_tkeep,
    output          [C_M_AXIS_TUSER_WIDTH-1:0]                      m_axis_tuser,
    output 	                                                        m_axis_tvalid,
    input                                                           m_axis_tready,
    output                                                          m_axis_tlast,
    // AXIS PACKET INPUT INTERFACE
    input           [C_S_AXIS_DATA_WIDTH - 1:0]                     s_axis_tdata,
    input           [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]             s_axis_tkeep,
    input           [C_S_AXIS_TUSER_WIDTH-1:0]                      s_axis_tuser,
    input                                                           s_axis_tvalid,
    output                                                          s_axis_tready,
    input                                                           s_axis_tlast,
    // AXI CLK & RST SIGNALS
    input                                                           S_AXI_ACLK,
    input                                                           S_AXI_ARESETN, // Need to invert this for the SDNet block (this is active low)
    // AXI-LITE CONTROL INTERFACE
    input           [C_S_AXI_ADDR_WIDTH-1 : 0]                      S_AXI_AWADDR,
    input                                                           S_AXI_AWVALID,
    input           [C_S_AXI_DATA_WIDTH-1 : 0]                      S_AXI_WDATA,
    input           [C_S_AXI_DATA_WIDTH/8-1 : 0]                    S_AXI_WSTRB,
    input                                                           S_AXI_WVALID,
    input                                                           S_AXI_BREADY,
    input           [C_S_AXI_ADDR_WIDTH-1 : 0]                      S_AXI_ARADDR,
    input                                                           S_AXI_ARVALID,
    input                                                           S_AXI_RREADY,
    output                                                          S_AXI_ARREADY,
    output          [C_S_AXI_DATA_WIDTH-1 : 0]                      S_AXI_RDATA,
    output          [1 : 0]                                         S_AXI_RRESP,
    output                                                          S_AXI_RVALID,
    output                                                          S_AXI_WREADY,
    output          [1 :0]                                          S_AXI_BRESP,
    output                                                          S_AXI_BVALID,
    output                                                          S_AXI_AWREADY
);

    nf_sdnet_vSwitch1_ip
  sdnet_vSwitch1  (
    .axis_aclk(axis_aclk),
    .axis_resetn(axis_resetn),
    // Master from vS to IvSI
    .m_axis_tdata (m_axis_tdata),
    .m_axis_tkeep (m_axis_tkeep),
    .m_axis_tuser (m_axis_tuser),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(m_axis_tready),
    .m_axis_tlast (m_axis_tlast),
    // Slave from IvSI to vS
    .s_axis_tdata (s_axis_tdata),
    .s_axis_tkeep (s_axis_tkeep),
    .s_axis_tuser (s_axis_tuser),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tlast (s_axis_tlast),
    // Slave from CvSI to vS
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

endmodule // wrapper_vSwitch
