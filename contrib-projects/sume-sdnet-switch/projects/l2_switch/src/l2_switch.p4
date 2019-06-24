#include <core.p4>
#include <sume_switch.p4>
// #include <v1model.p4>

#define VLAN_TYPE   0x8100

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header Vlan_h {
    bit<3> prio;
    bit<1> dropEligible;
    bit<12> vlanId;
    bit<16> etherType;
}

struct user_metadata_t{
    bit<8> unused;
}

// digest data to be sent to CPU if desired. MUST be 256 bits!
struct digest_data_t {
    bit<256>  unused;
}

struct Parsed_packet {
    ethernet_t ethernet;
    Vlan_h vlan;

}

@Xilinx_MaxPacketRegion(16384)
parser TopParser(packet_in packet,
                 out Parsed_packet hdr,
                 out user_metadata_t meta,
                 out digest_data_t digest_data,
                 inout sume_metadata_t sume_metadata) {
    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        meta.unused = 0;
        digest_data.unused =0;
        transition select(hdr.ethernet.etherType) {
            VLAN_TYPE: parse_vlan;
            default: reject;
        }
    }

    state parse_vlan {
        packet.extract(hdr.vlan);
        transition accept;
    }
}

control TopPipe(inout Parsed_packet hdr,
                inout user_metadata_t meta,
                inout digest_data_t digest_data,
                inout sume_metadata_t sume_metadata) {
    // control verifyChecksum
    //apply {
    //}

    action forward(bit<8> port) {
        sume_metadata.dst_port = port;
    }
    table dmac {
        actions = {
            forward;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
        }
        size = 64;
    }
    apply {
        dmac.apply();
    }

    // control egress
    //apply {
    //}

    // control computeChecksum
    //apply {
    //}
}

@Xilinx_MaxPacketRegion(16384)
control TopDeparser(packet_out packet,
                    in Parsed_packet hdr,
                    in user_metadata_t user_metadata,
                    inout digest_data_t digest_data,
                    inout sume_metadata_t sume_metadata) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.vlan);
    }
}

SimpleSumeSwitch( TopParser(), TopPipe(), TopDeparser() ) main;
