#include <core.p4>
#include <sume_switch.p4>
// #include <v1model.p4>

struct routing_metadata_t {
    bit<32> nhop_ipv4;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

struct user_metadata_t {
    routing_metadata_t routing_metadata;
    // bit<8> unused;
}

// digest data to be sent to CPU if desired. MUST be 256 bits!
struct digest_data_t {
    bit<256>  unused;
}

struct Parsed_packet {
    ethernet_t ethernet;
    ipv4_t     ipv4;
}

@Xilinx_MaxPacketRegion(16384)
parser TopParser(packet_in packet,
                 out Parsed_packet hdr,
                 out user_metadata_t meta,
                 out digest_data_t digest_data,
                 inout sume_metadata_t sume_metadata) {
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        digest_data.unused =0;
        // meta.unused = 0;
        meta.routing_metadata.nhop_ipv4 = 32w0;
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
    state start {
        transition parse_ethernet;
    }
}

control TopPipe(inout Parsed_packet hdr,
                inout user_metadata_t meta,
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
        meta.routing_metadata.nhop_ipv4 = nhop_ipv4;
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
            meta.routing_metadata.nhop_ipv4: exact;
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

@Xilinx_MaxPacketRegion(16384)
control TopDeparser(packet_out packet,
                    in Parsed_packet hdr,
                    in user_metadata_t user_metadata,
                    inout digest_data_t digest_data,
                    inout sume_metadata_t sume_metadata) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

SimpleSumeSwitch(
	TopParser(),
	TopPipe(),
	TopDeparser()
) main;
