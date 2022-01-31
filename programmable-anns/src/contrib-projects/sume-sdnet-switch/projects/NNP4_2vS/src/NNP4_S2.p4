//
// Copyright (c) 2020
// All rights reserved.
//
// This software was developed by Stanford University and the University of Cambridge Computer Laboratory
// under National Science Foundation under Grant No. CNS-0855268,
// the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
// by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
// as part of the DARPA MRC research programme.
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

#include <core.p4>
#include <sume_switch.p4>

// typedef bit<9>  egressSpec_t;
typedef bit<8>  egressSpec_t;
typedef bit<8>  dataNN_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

const egressSpec_t  PORT_RECIRCULATE = 13;

// Reg Test
// #define BUFFER 9
// #define BUFFER_CTR 8
// #define NEURON_TYPE 3
// #define NN_ID 4
// #define NEURON_ID 5
// #define BUFFER_SIZE 6
// #define NEXT_LAYER 7
// #define PREV_LAYER 8
#define SWITCH_ID 5
#define INDEX_VS 4

#define VLAN_TYPE 0x8100
#define TYPE_IPV4 0x0800
#define TYPE_PROBE 0x0812
#define PROBE_LEN 29
#define MAX_HOPS 10
// #define MAX_SIZE_INFRA 16
#define MAX_INFRA 16
#define MAX_PORTS 8

//Neural network parameters
#define MAX_NEURONS 5
#define MAX_BUFFER 5
#define PRECISION 64
#define TIME_DATA 64
#define REG_READ 8w0
#define REG_WRITE 8w1
#define REG_ADD    8w2
#define REG_SUB    8w3
#define REG_NULL   8w4
#define REG_READ_WRITE  8w5
#define REG_DATA 16
#define REG_WIDTH 4 // determines depth of const register
#define BUF_WIDTH 4 // determines depth of buffers register


// Registers
@Xilinx_MaxLatency(64)
@Xilinx_ControlWidth(REG_WIDTH)
extern void switchID_reg_rw(in bit<REG_WIDTH> index,
                            in dataNN_t newVal,
                            in bit<8> opCode,
                            out dataNN_t result);
@Xilinx_MaxLatency(64)
@Xilinx_ControlWidth(REG_WIDTH)
extern void prevLayer_reg_rw(in bit<REG_WIDTH> index,
                             in bit<REG_DATA> newVal,
                             in bit<8> opCode,
                             out bit<REG_DATA> result);
@Xilinx_MaxLatency(64)
@Xilinx_ControlWidth(REG_WIDTH)
extern void nextLayer_reg_rw(in bit<REG_WIDTH> index,
                             in bit<REG_DATA> newVal,
                             in bit<8> opCode,
                             out bit<REG_DATA> result);
@Xilinx_MaxLatency(64)
@Xilinx_ControlWidth(REG_WIDTH)
extern void bufferSize_reg_rw(in bit<REG_WIDTH> index,
                              in bit<REG_DATA> newVal,
                              in bit<8> opCode,
                              out bit<REG_DATA> result);
@Xilinx_MaxLatency(64)
@Xilinx_ControlWidth(REG_WIDTH)
extern void neuronType_reg_rw(in bit<REG_WIDTH> index,
                          in bit<REG_DATA> newVal,
                          in bit<8> opCode,
                          out bit<REG_DATA> result);
@Xilinx_MaxLatency(64)
@Xilinx_ControlWidth(REG_WIDTH)
extern void neuronID_reg_rw(in bit<REG_WIDTH> index,
                            in bit<REG_DATA> newVal,
                            in bit<8> opCode,
                            out bit<REG_DATA> result);
@Xilinx_MaxLatency(64)
@Xilinx_ControlWidth(REG_WIDTH)
extern void nnID_reg_rw(in bit<REG_WIDTH> index,
                        in bit<REG_DATA> newVal,
                        in bit<8> opCode,
                        out bit<REG_DATA> result);
@Xilinx_MaxLatency(64)
@Xilinx_ControlWidth(REG_WIDTH)
extern void swididmaskDebug1_reg_rw(in bit<REG_WIDTH> index,
                        in bit<REG_DATA> newVal,
                        in bit<8> opCode,
                        out bit<REG_DATA> result);
@Xilinx_MaxLatency(64)
@Xilinx_ControlWidth(REG_WIDTH)
extern void swididmaskDebug2_reg_rw(in bit<REG_WIDTH> index,
                        in bit<REG_DATA> newVal,
                        in bit<8> opCode,
                        out bit<REG_DATA> result);
// Buffers
@Xilinx_MaxLatency(64)
@Xilinx_ControlWidth(BUF_WIDTH)
extern void buffer_reg_rw(in bit<BUF_WIDTH> index,
                          in bit<REG_DATA> newVal,
                          in bit<8> opCode,
                          out bit<REG_DATA> result);
@Xilinx_MaxLatency(64)
@Xilinx_ControlWidth(REG_WIDTH)
extern void bufferCtr_reg_multi_raws(in bit<REG_WIDTH> index_0,
                                 in bit<REG_DATA> data_0,
                                 in bit<8> opCode_0,
                                 in bit<REG_WIDTH> index_1,
                                 in bit<REG_DATA> data_1,
                                 in bit<8> opCode_1,
                                 in bit<REG_WIDTH> index_2,
                                 in bit<REG_DATA> data_2,
                                 in bit<8> opCode_2,
                                 out bit<REG_DATA> result);


// timestamp generation
@Xilinx_MaxLatency(1)
@Xilinx_ControlWidth(0)
extern void tin_timestamp(in bit<1> valid,
                          out bit<TIME_DATA> result);
@Xilinx_MaxLatency(1)
@Xilinx_ControlWidth(0)
extern void tout_timestamp(in bit<1> valid,
                          out bit<TIME_DATA> result);

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/
header ethernet_t {
    macAddr_t   dstAddr;
    macAddr_t   srcAddr;
    bit<16>     etherType;
}

// standard Vlan header
header vlan_h {
    bit<3> prio;
    bit<1> dropEligible;
    bit<12> vlanId;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     totalLen;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     fragOffset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdrChecksum;
    ip4Addr_t   srcAddr;
    ip4Addr_t   dstAddr;
}

header probe_t {
    bit<8>  occup;              //set to 1 when occupied.
    bit<8>  nnid;               // Src neuron id
    bit<8>  op;
    bit<MAX_INFRA>  neurondst;  // 16
    bit<64> info;               //collected info
    bit<128> data;              // informacao solicitada no pacote
    //bit<64> r2;               // informacao solicitada no pacote
}

struct parser_metadata_t {
    bit<8>  remaining;
}

struct user_metadata_t {
    bit<8> egress_spec;
    bit<8> op;
    bit<2> encap;
    parser_metadata_t parser_metadata;
}

// digest data to be sent to CPU if desired. MUST be 256 bits!
struct digest_data_t {
    bit<256>  unused;
}

// List of all recognized headers
struct Parsed_packet {
    ethernet_t  ethernet;
    vlan_h      vlan;
    ipv4_t      ipv4;
    probe_t     probe;
}

/*************************************************************************
************************* P A R S E R  ***********************************
*************************************************************************/
@Xilinx_MaxPacketRegion(16384)
parser TopParser(packet_in pkt_in,
                 out Parsed_packet hdr,
                 out user_metadata_t user_metadata,
                 out digest_data_t digest_data,
                 inout sume_metadata_t sume_metadata) {
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt_in.extract(hdr.ethernet);
        user_metadata.egress_spec = 0;
        user_metadata.op = 0;
        user_metadata.encap = 0;
        user_metadata.parser_metadata.remaining = 0;
        digest_data.unused = 0;
        transition select(hdr.ethernet.etherType) {
            VLAN_TYPE: parse_vlan;
            default: accept;
        }
    }

    state parse_vlan {
        pkt_in.extract(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt_in.extract(hdr.ipv4);
        transition select(hdr.ipv4.diffserv) {
            200: parse_probe;
            default: accept;
        }
    }

    state parse_probe {
        pkt_in.extract(hdr.probe);
        //getting the syns maybe here.
        transition accept;
    }

}

/*************************************************************************
**************  P I P E L I N E   P R O C E S S I N G   ******************
*************************************************************************/
control TopPipe(inout Parsed_packet hdr,
                inout user_metadata_t user_metadata,
                inout digest_data_t digest_data,
                inout sume_metadata_t sume_metadata) {

// Metadata used for Neural Network
    dataNN_t nnID;
    dataNN_t neuronType;
    dataNN_t bufferSize;
    dataNN_t neuronID;
    dataNN_t switchID;
    bit<MAX_INFRA> prevLayer;
    bit<MAX_INFRA> nextLayer;
    bit<TIME_DATA> tin_time;
    bit<TIME_DATA> tout_time;
    bit<REG_DATA> regReturn;
    bit<REG_DATA> newVal;
    bit<REG_DATA> swididmaskDebug1;
    bit<REG_DATA> swididmaskDebug2;
    bit<REG_DATA> newVal_buffer;
    dataNN_t opCode; // REG_READ or REG_WRITE
    bit<REG_DATA> bufferCtr;
    bit<REG_DATA> bufferCtr_read;
    bit<REG_DATA> buffer_read;
    bit<BUF_WIDTH> index_buffer;
    bit<REG_WIDTH> index_0; bit<REG_DATA> data_0; bit<8> opCode_0;
    bit<REG_WIDTH> index_1; bit<REG_DATA> data_1; bit<8> opCode_1;
    bit<REG_WIDTH> index_2; bit<REG_DATA> data_2; bit<8> opCode_2;

// Actions
    action set_dmac(bit<48> dmac, bit<8> port, bit<2> encap) {
        hdr.ethernet.dstAddr = dmac;
        sume_metadata.dst_port = port;
        user_metadata.encap = encap;
    }
    action set_smac(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
    }
    action drop() {
        sume_metadata.drop = 1;
        sume_metadata.dst_port = 0;
    }
    action set_nn_param(bit<MAX_INFRA> prev_layers_value, bit<MAX_INFRA> next_layers_value, bit<8> buffer_size_value, bit<8> neuronid, bit<8> nn_id_value, bit<8> neuron_type_value){
        nnID = nn_id_value;
        neuronType = neuron_type_value;
        prevLayer = prev_layers_value;
        nextLayer = next_layers_value;
        bufferSize = buffer_size_value;
        neuronID = neuronid;
    }

// Tables
    table switch_init {
        key = { switchID: exact; }
        actions = {
            set_nn_param;
            NoAction;
        }
        size = 64;
        default_action = NoAction;
    }
    table forward_table {
        key = { hdr.ipv4.dstAddr: exact; }
        actions = {
            set_dmac;
            drop;
        }
        size = 64;
        default_action = drop;
    }
    table send_frame {
        key = { sume_metadata.dst_port: exact; }
        actions = {
            set_smac;
            drop;
        }
        size = 64;
        default_action = drop;
    }

    apply {
        // Get tin timestamp
        tin_time = 0;
        tout_time = 0;
        tin_timestamp(1,tin_time);
        // Default Initialization
        switchID = 0;
        nnID = 0;
        neuronType = 0;
        prevLayer = 0;
        nextLayer = 0;
        bufferSize = 0;
        neuronID = 0;
        opCode = REG_WRITE;
        regReturn = 0;
        newVal = 0;
        index_0 = INDEX_VS; data_0 = 0; opCode_0 = REG_READ_WRITE;
        index_1 = INDEX_VS; data_1 = 0; opCode_1 = REG_READ;
        index_2 = INDEX_VS; data_2 = 0; opCode_2 = REG_READ;
        bufferCtr = 0;
        bufferCtr_read = 0;
        index_buffer = INDEX_VS;
        newVal_buffer = 0;
        swididmaskDebug1 = 0;
        swididmaskDebug2 = 0;

        if ( hdr.ipv4.isValid() ) {
            forward_table.apply();
            send_frame.apply();

            dataNN_t switchID_read;
            switchID_reg_rw(0, 0, REG_READ, switchID_read);
            switchID = switchID_read;
            switch_init.apply();

            newVal = (bit<REG_DATA>) prevLayer;
            prevLayer_reg_rw(INDEX_VS, newVal, opCode, regReturn);
            newVal = (bit<REG_DATA>) nextLayer;
            nextLayer_reg_rw(INDEX_VS, newVal, opCode, regReturn);
            newVal = (bit<REG_DATA>) bufferSize;
            bufferSize_reg_rw(INDEX_VS, newVal, opCode, regReturn);
            newVal = (bit<REG_DATA>) neuronID;
            neuronID_reg_rw(INDEX_VS, newVal, opCode, regReturn);
            newVal = (bit<REG_DATA>) nnID;
            nnID_reg_rw(INDEX_VS, newVal, opCode, regReturn);
            newVal = (bit<REG_DATA>) neuronType;
            neuronType_reg_rw(INDEX_VS, newVal, opCode, regReturn);

            bufferCtr_reg_multi_raws(index_0,
                                     data_0,
                                     opCode_0,
                                     index_1,
                                     data_1,
                                     opCode_1,
                                     index_2,
                                     data_2,
                                     opCode_2,
                                     bufferCtr_read);
            bufferCtr = bufferCtr_read;

            // First: verify if packet has been encapsulated (i.e. it is a possible candidate)

            if(hdr.ipv4.diffserv == 200){

            	// Verify if the packet has already some data. If so, just check if is destinated to this sw
                if (hdr.probe.occup == (bit<8>) 1){
                	// Verify if the packet is destined to this switch
                    // Each switch has a decimal ID (from 1 to MAX_INFRA)
                    // The header neurondst has the nth bit set to 1 if the nth neuron is a destination
                    bit<MAX_INFRA> swididmask = (bit<MAX_INFRA>) ((bit<8>) 1 << switchID);
                    swididmaskDebug1 = swididmask;
                    swididmaskDebug2 = hdr.probe.neurondst;

                    if( ( hdr.probe.neurondst & swididmask ) ==  swididmask ){
                    	// Store the data
                        // Read source neuron ID, to use it as index
                        index_buffer = (bit<BUF_WIDTH>) hdr.probe.nnid;
                        newVal_buffer = (bit<REG_DATA>) hdr.probe.data;

                        // Mark as received in the buffer
                        bufferCtr = ((bit<16>) (bufferCtr)) | ((bit<16>) ((bit<8>) 1 << hdr.probe.nnid));
// bufferCtr.write(0, bufferCtr);

                        // Mark packet as free
                        hdr.probe.occup = 0;
                    }
                }
                if (hdr.probe.occup == (bit<8>) 0){
                    //Need to verify: Do I have something to encap? Check the buffer?
                    //to encap something, I do need the check If data was alredy received.
                    bit<MAX_INFRA> prev_neurons = (bit<MAX_INFRA>) prevLayer;

                    if(prev_neurons == (bit<MAX_INFRA>) bufferCtr){
                        //Set new destination
                        hdr.probe.neurondst = (bit<MAX_INFRA>) nextLayer;

                        //Set src neuron
    	                hdr.probe.nnid = neuronID;

                        //Reset buffer
// bufferCtr.write(0, 0);

                        hdr.probe.occup = (bit<8>) 1;
                    }
                }

                if(user_metadata.encap == 2){          // de-encap
                	hdr.ipv4.diffserv = 0;
                    hdr.probe.setInvalid();
                }
            }

            // If not encapsulated, we verify if it is supposed to
            // encap: 0 (don't do anything); encap:1 (encapsulate NN info); encap:2 (de-encaps NN info).
            if(user_metadata.encap == 1){ ///encap --
                // Calcualte the actual size required
                // Ether(16) + IPv4(20) + UDP(8) == 42  + additional header for NN (now it is 29B)
                // Header NN=13B (depend dos parametros)
                if(sume_metadata.pkt_len < 1428){ // pkt_len - the size of the packet (not including the Ethernet preamble or FCS) in bytes.
                    hdr.probe.setValid();

                    //set "encapsulation". This flag is used to infor the SW that the packet is carrying NN informartion
                    hdr.ipv4.diffserv = 200;
                    //mark as used
                    hdr.probe.occup = (bit<8>) 1;
                    //read neuron id
                    hdr.probe.nnid = neuronID;
                    hdr.probe.op = (bit<8>) 0;
                    hdr.probe.neurondst = (bit<16>) nextLayer;
                    hdr.probe.nnid = neuronID;

                    // Yet need to set the neuron's output
                    bit<128> scaledUpData;
                    // action moved to here || scale_up(hdr.probe.info, scaledUpData); //making scale_up
                    scaledUpData = (bit<128>) ((bit<128>) hdr.probe.info * (1 << PRECISION));
                    hdr.probe.data = scaledUpData;
                    tout_timestamp(1, tout_time);
                    hdr.probe.info = (bit<64>) (tout_time - tin_time);
                    sume_metadata.pkt_len = sume_metadata.pkt_len + PROBE_LEN;
                }
            }
            swididmaskDebug1_reg_rw(0, swididmaskDebug1, REG_WRITE, regReturn);
            swididmaskDebug2_reg_rw(0, swididmaskDebug2, REG_WRITE, regReturn);
            buffer_reg_rw(index_buffer, newVal_buffer, REG_WRITE, regReturn);
        }
    }

}

// /************************************************************************
// *************   C H E C K S U M    C O M P U T A T I O N   ***************
// *************************************************************************/
//
// control MyComputeChecksum(inout headers  hdr, inout metadata user_metadata) {
//     apply {
// 	update_checksum(
// 	    hdr.ipv4.isValid(),
//             { hdr.ipv4.version,
//     	      hdr.ipv4.ihl,
//               hdr.ipv4.diffserv,
//               hdr.ipv4.totalLen,
//               hdr.ipv4.identification,
//               hdr.ipv4.flags,
//               hdr.ipv4.fragOffset,
//               hdr.ipv4.ttl,
//               hdr.ipv4.protocol,
//               hdr.ipv4.srcAddr,
//               hdr.ipv4.dstAddr },
//             hdr.ipv4.hdrChecksum,
//             HashAlgorithm.csum16);
//     }
// }

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/
@Xilinx_MaxPacketRegion(16384)
control TopDeparser(packet_out pkt_out,
                    in Parsed_packet hdr,
                    in user_metadata_t user_metadata,
                    inout digest_data_t digest_data,
                    inout sume_metadata_t sume_metadata) {
    apply {
        pkt_out.emit(hdr.ethernet);
        pkt_out.emit(hdr.vlan);
        pkt_out.emit(hdr.ipv4);
        pkt_out.emit(hdr.probe);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/
SimpleSumeSwitch(
    TopParser(),
    TopPipe(),
    TopDeparser()
) main;
