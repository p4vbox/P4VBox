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
    IPv4_h ip;
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
parser TopParser(packet_in b,
                 out Parsed_packet p,
                 out user_metadata_t user_metadata,
                 out digest_data_t digest_data,
                 inout sume_metadata_t sume_metadata) {
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        b.extract(p.ethernet);
        user_metadata.unused = 0;
        digest_data.unused = 0;
        transition select(p.ethernet.etherType) {
            VLAN_TYPE: parse_vlan;
            default: reject;
        }
    }

    state parse_vlan {
        b.extract(p.vlan);
        transition select(p.vlan.etherType) {
            IPV4_TYPE: parse_ipv4;
            default: reject;
        }
    }

    state parse_ipv4 {
        b.extract(p.ip);
        transition accept;
    }
}

// match-action pipeline
control TopPipe(inout Parsed_packet p,
                inout user_metadata_t user_metadata,
                inout digest_data_t digest_data,
                inout sume_metadata_t sume_metadata) {



    apply {

    }
}

// Deparser Implementation
@Xilinx_MaxPacketRegion(16384)
control TopDeparser(packet_out b,
                    in Parsed_packet p,
                    in user_metadata_t user_metadata,
                    inout digest_data_t digest_data,
                    inout sume_metadata_t sume_metadata) {
    apply {
        b.emit(p.ethernet);
        b.emit(p.vlan);
        b.emit(p.ip);
    }
}


// Instantiate the switch
SimpleSumeSwitch(TopParser(), TopPipe(), TopDeparser()) main;
