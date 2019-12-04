//////////////////////////////////////////////////////////////////////////////////
// This software was developed by Institute of Informatics of the Federal
// University of Rio Grande do Sul (INF-UFRGS)
//
// File:
//      sss_p4_proj.p4
//
// P4 Switch Module:
//      template
//
// Author:
//       Mateus Saquetti
//
// Description:
//       This is a template for P4VBox switch
//
// Create Date:
//       20.05.2019
//
// Additional Comments:
//
//
//////////////////////////////////////////////////////////////////////////////////

#include <core.p4>
#include <sume_switch.p4>

typedef bit<48> EthAddr_t;
typedef bit<32> IPv4Addr_t;
typedef bit<16> Layer4Addr_t;

#define VLAN_TYPE 0x8100
#define IPV4_TYPE 0x0800
#define TCP_TYPE 6
#define UDP_TYPE 17

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

header Layer4_h {
    Layer4Addr_t srcAddr;
    Layer4Addr_t dstAddr;
}

// List of all recognized headers
struct Parsed_packet {
    Ethernet_h ethernet;
    Vlan_h vlan;
    IPv4_h ip;
    Layer4_h l4;
}

// user defined metadata: can be used to shared information between
// TopParser, TopPipe, and TopDeparser
struct user_metadata_t {
    bit<8>  unused;
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
        user_metadata.unused = 0;
        digest_data.unused = 0;
        transition select(hdr.ethernet.etherType) {
            VLAN_TYPE: parse_vlan;
            default: reject;
        }
    }

    state parse_vlan {
        pkt_in.extract(hdr.vlan);
        transition select(hdr.vlan.etherType) {
            IPV4_TYPE: parse_ipv4;
            default: reject;
        }
    }

    state parse_ipv4 {
        pkt_in.extract(hdr.ip);
        transition select(hdr.ip.protocol) {
            TCP_TYPE: parser_l4;
            UDP_TYPE: parser_l4;
            default: reject;
        }
    }

    state parser_l4 {
        pkt_in.extract(hdr.l4);
        transition accept;
    }
}

// match-action pipeline
control TopPipe(inout Parsed_packet hdr,
                inout user_metadata_t user_metadata,
                inout digest_data_t digest_data,
                inout sume_metadata_t sume_metadata) {

    action drop() {
        // About drop field: This field is now deprecated and will be remove
        // in a future version. To drop a packet set dst_port = 0.
        // Source: https://github.com/NetFPGA/P4-NetFPGA-public/wiki/Workflow-Overview#testing-p4-programs
        sume_metadata.drop = 1;
        // Effectively dropping the package
        sume_metadata.dst_port = 0;
    }
    action no_operation() {
    }
    action forward(bit<8> port) {
        sume_metadata.dst_port = port;
    }
    table firewall_dst {
        actions = {
            drop;
            no_operation;
        }
        key = {
            hdr.l4.dstAddr: exact;
        }
        size = 64;
        default_action = no_operation;
    }
    table firewall_src {
        actions = {
            drop;
            no_operation;
        }
        key = {
            hdr.l4.srcAddr: exact;
        }
        size = 64;
        default_action = no_operation;
    }
    table forward_table {
        actions = {
            forward;
        }
        key = {
            sume_metadata.src_port: exact;
        }
        size = 64;
    }

    apply {
        forward_table.apply();
        if (hdr.l4.isValid()) {
            firewall_src.apply();
            firewall_dst.apply();

        }
    }


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
        pkt_out.emit(hdr.ip);
        pkt_out.emit(hdr.l4);
    }
}


// Instantiate the switch
SimpleSumeSwitch( TopParser(), TopPipe(), TopDeparser() ) main;
