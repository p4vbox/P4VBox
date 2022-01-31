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

typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

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
    // vlan_h      vlan;
    ipv4_t      ipv4;
}

/*************************************************************************
************************* P A R S E R  ***********************************
*************************************************************************/
@Xilinx_MaxPacketRegion(16384)
parser TopParser(packet_in pkt_in,
                 out Parsed_packet hdr,
                 out user_metadata_t user_metadata,
                 out digest_data_t digest_data,
                 inout sume_metadata_t sume_metadata)
{
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
            // 0x8100: parse_vlan;
            0x0800: parse_ipv4;
            default: accept;
        }
    }

    // state parse_vlan {
    //     pkt_in.extract(hdr.vlan);
    //     transition select(hdr.vlan.etherType) {
    //         0x0800: parse_ipv4;
    //         default: accept;
    //     }
    // }

    state parse_ipv4 {
        pkt_in.extract(hdr.ipv4);
        transition accept;
    }

}

/*************************************************************************
**************  P I P E L I N E   P R O C E S S I N G   ******************
*************************************************************************/
control TopPipe(inout Parsed_packet hdr,
                inout user_metadata_t user_metadata,
                inout digest_data_t digest_data,
                inout sume_metadata_t sume_metadata)
{
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

    // Tables
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

    apply
    {

        if ( hdr.ipv4.isValid() ) {
            forward_table.apply();
            send_frame.apply();
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
        // pkt_out.emit(hdr.vlan);
        pkt_out.emit(hdr.ipv4);
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
