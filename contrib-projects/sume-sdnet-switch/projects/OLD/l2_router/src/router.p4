//
// Copyright (c) 2018 Mateus Saquetti
// All rights reserved.
//
// This software was developed by Institute of Informatics of the Federal
// University of Rio Grande do Sul (INF-UFRGS)
//
// Description:
//              Simple router for SUME switch
// Create Date:
//              10.06.2018
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

typedef bit<48> EthAddr_t;
typedef bit<32> IPv4Addr_t;

#define VLAN_TYPE   0x8100
#define IPV4_TYPE 0x0800

// standard Ethernet header
header Ethernet_h {
    EthAddr_t dstAddr;
    EthAddr_t srcAddr;
    bit<16> etherType;
}

// standard Vlan header
header Vlan_h {
    bit<3> prio;
    bit<1> dropEligible;
    bit<12> vlanId;
    bit<16> etherType;
}

// IPv4 header without options
header IPv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> tos;
    bit<16> totalLen;
    bit<16> identification;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdrChecksum;
    IPv4Addr_t srcAddr;
    IPv4Addr_t dstAddr;
}


// List of all recognized headers
struct Parsed_packet {
    Ethernet_h ethernet;
    Vlan_h vlan;
    IPv4_h ipv4;
}

struct routing_metadata_t {
    bit<32> nhop_ipv4;
}

// user defined metadata: can be used to shared information between
// TopParser, TopPipe, and TopDeparser
struct user_metadata_t {
    routing_metadata_t routing_metadata;
}

// digest data to be sent to CPU if desired. MUST be 256 bits!
struct digest_data_t {
    bit<256>  unused;
}

// Parser Implementation
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
        digest_data.unused =0;
        user_metadata.routing_metadata.nhop_ipv4 = 32w0;
        transition select(hdr.ethernet.etherType) {
            VLAN_TYPE: parse_vlan;
            default: reject;
        }
    }

    state parse_vlan {
        pkt_in.extract(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        pkt_in.extract(hdr.ipv4);
        transition accept;
    }
}

control TopPipe(inout Parsed_packet hdr,
                inout user_metadata_t user_metadata,
                inout digest_data_t digest_data,
                inout sume_metadata_t sume_metadata) {
    // control verifyChecksum
    // apply {
    //     verify_checksum(true, {
    //         hdr.ipv4.version,
    //         hdr.ipv4.ihl,
    //         hdr.ipv4.diffserv,
    //         hdr.ipv4.totalLen,
    //         hdr.ipv4.identification,
    //         hdr.ipv4.flags,
    //         hdr.ipv4.fragOffset,
    //         hdr.ipv4.ttl,
    //         hdr.ipv4.protocol,
    //         hdr.ipv4.srcAddr,
    //         hdr.ipv4.dstAddr },
    //         hdr.ipv4.hdrChecksum,
    //         HashAlgorithm.csum16);
    // }

    action set_dmac(bit<48> dmac, bit<8> port) {
        hdr.ethernet.dstAddr = dmac;
        sume_metadata.dst_port = port;
    }
    action drop() {
        // mark_to_drop();
        sume_metadata.drop = 1;
    }
    action set_nhop(bit<32> nhop_ipv4) {
        user_metadata.routing_metadata.nhop_ipv4 = nhop_ipv4;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    action set_smac(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
    }
    table forward_table {
        actions = {
            set_dmac;
            drop;
        }
        key = {
            user_metadata.routing_metadata.nhop_ipv4: exact;
        }
        size = 64;
    }
    table ipv4_nhop {
        actions = {
            set_nhop;
            drop;
        }
        key = {
            hdr.ipv4.dstAddr: exact;
        }
        size = 64;
    }
    table send_frame {
        actions = {
            set_smac;
            drop;
        }
        key = {
            sume_metadata.dst_port: exact;
        }
        size = 64;
    }
    apply {
        if (hdr.ipv4.isValid() && hdr.ipv4.ttl > 8w0) {
            ipv4_nhop.apply();
            forward_table.apply();
            send_frame.apply();
        }
    }

    // control egress
    // apply {
    // }
    //
    // // control computeChecksum
    // apply {
    //     update_checksum(true, {
    //         hdr.ipv4.version,
    //         hdr.ipv4.ihl,
    //         hdr.ipv4.diffserv,
    //         hdr.ipv4.totalLen,
    //         hdr.ipv4.identification,
    //         hdr.ipv4.flags,
    //         hdr.ipv4.fragOffset,
    //         hdr.ipv4.ttl,
    //         hdr.ipv4.protocol,
    //         hdr.ipv4.srcAddr,
    //         hdr.ipv4.dstAddr },
    //         hdr.ipv4.hdrChecksum,
    //         HashAlgorithm.csum16);
    // }

}

// Deparser Implementation
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
    }
}

// Instantiate the switch
SimpleSumeSwitch( TopParser(), TopPipe(), TopDeparser() ) main;
