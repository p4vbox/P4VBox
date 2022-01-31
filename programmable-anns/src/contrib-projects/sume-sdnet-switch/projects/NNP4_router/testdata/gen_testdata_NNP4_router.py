#!/usr/bin/env python

#
# Copyright (c) 2017 Stephen Ibanez
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
# as part of the DARPA MRC research programme.
#

# All rights reserved.
#


#
# Description:
#              Adapted to run in PvS architecture
# Create Date:
#              31.05.2019
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  NetFPGA licenses this
# file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#   http://www.netfpga-cic.org
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@
#


from nf_sim_tools import *
import random, numpy
from collections import OrderedDict
from probe_hdrs import *
import sss_sdnet_tuples

###########
# define #
##########

DEF_PKT_SIZE = 256  # default packet size (in bytes)
HEADER_SIZE = 46    # headers size: Ether/IP/UDP
DEF_PKT_NUM = 24    # default packets number to simulation
DEF_HOST_NUM = 4    # default hosts number in network topology
LEN_PROBE = len(ProbeData())
src_host = 0        # packets sender host
vlan_id = 0         # vlan identifier to matching with IPI architecture and nf_datapath.v
vlan_prio = 0       # vlan priority
extra_len = 0

dst_host_map = {0:1, 1:0, 2:3, 3:2}                   # map the sender and receiver Hosts H[0, 1, 2, 3] based in network topology
inv_nf_id_map = {0:"nf0", 1:"nf1", 2:"nf2", 3:"nf3"}  # map the keys of dictionary nf_id_map
vlan_id_map = {"nnp4":1}             # map the vlans of parrallel switches

port_slicing = {}                                     # map the slicing of ports of SUME nf[0, 1, 2, 3] based in network topology
port_slicing[0] = "nnp4"
port_slicing[1] = "nnp4"
port_slicing[2] = "nnp4"
port_slicing[3] = "nnp4"

########################
# pkt generation tools #
########################

pktsApplied = []
pktsExpected = []

# Pkt lists for SUME simulations
nf_applied = OrderedDict()
nf_applied[0] = []
nf_applied[1] = []
nf_applied[2] = []
nf_applied[3] = []
nf_expected = OrderedDict()
nf_expected[0] = []
nf_expected[1] = []
nf_expected[2] = []
nf_expected[3] = []

nf_port_map = {"nf0":0b00000001, "nf1":0b00000100, "nf2":0b00010000, "nf3":0b01000000, "none":0b00000000}
nf_id_map = {"nf0":0, "nf1":1, "nf2":2, "nf3":3}

sss_sdnet_tuples.clear_tuple_files()

def applyPkt(pkt, ingress, time, extra_len):
    pktsApplied.append(pkt)
    sss_sdnet_tuples.sume_tuple_in['pkt_len'] = len(pkt)
    sss_sdnet_tuples.sume_tuple_in['src_port'] = nf_port_map[ingress]
    sss_sdnet_tuples.sume_tuple_expect['pkt_len'] = len(pkt) + extra_len
    sss_sdnet_tuples.sume_tuple_expect['src_port'] = nf_port_map[ingress]
    pkt.time = time
    nf_applied[nf_id_map[ingress]].append(pkt)

def expPkt(pkt, egress, drop):
    pktsExpected.append(pkt)
    sss_sdnet_tuples.sume_tuple_expect['dst_port'] = nf_port_map[egress]
    sss_sdnet_tuples.sume_tuple_expect['drop'] = drop
    sss_sdnet_tuples.write_tuples()
    if egress in ["nf0","nf1","nf2","nf3"] and drop == False:
        nf_expected[nf_id_map[egress]].append(pkt)
    elif egress == 'bcast' and drop == False:
        nf_expected[0].append(pkt)
        nf_expected[1].append(pkt)
        nf_expected[2].append(pkt)
        nf_expected[3].append(pkt)

def write_pcap_files():
    wrpcap("src.pcap", pktsApplied)
    wrpcap("dst.pcap", pktsExpected)

    for i in nf_applied.keys():
        if (len(nf_applied[i]) > 0):
            wrpcap('nf{0}_applied.pcap'.format(i), nf_applied[i])

    for i in nf_expected.keys():
        if (len(nf_expected[i]) > 0):
            wrpcap('nf{0}_expected.pcap'.format(i), nf_expected[i])

    for i in nf_applied.keys():
        print "nf{0}_applied times: ".format(i), [p.time for p in nf_applied[i]]

#####################
# generate testdata #
#####################

MAC_addr_H = {}
MAC_addr_H[nf_id_map["nf0"]] = "08:00:00:00:01:11"
MAC_addr_H[nf_id_map["nf1"]] = "08:00:00:00:02:22"
MAC_addr_H[nf_id_map["nf2"]] = "08:00:00:00:03:33"
MAC_addr_H[nf_id_map["nf3"]] = "08:00:00:00:04:44"

IP_addr_H = {}
IP_addr_H[nf_id_map["nf0"]] = "10.0.1.1"
IP_addr_H[nf_id_map["nf1"]] = "10.0.2.2"
IP_addr_H[nf_id_map["nf2"]] = "10.0.3.3"
IP_addr_H[nf_id_map["nf3"]] = "10.0.4.4"

MAC_addr_S = {}
MAC_addr_S[nf_id_map["nf0"]] = "05:00:00:00:01:05"
MAC_addr_S[nf_id_map["nf1"]] = "05:00:00:00:02:05"
MAC_addr_S[nf_id_map["nf2"]] = "05:00:00:00:03:05"
MAC_addr_S[nf_id_map["nf3"]] = "05:00:00:00:04:05"


def get_rand_port():
    return random.randint(1, 0xffff)

sport = get_rand_port()
dport = get_rand_port()

# create some packets
# for time in range(DEF_PKT_NUM):
total_packets = 0
for time in numpy.arange(0, DEF_PKT_NUM, 0.048):
    total_packets += 1
    vlan_id = vlan_id_map[port_slicing[src_host]]
    src_IP = IP_addr_H[src_host]
    dst_IP = IP_addr_H[dst_host_map[src_host]]

    if( vlan_id == vlan_id_map["nnp4"] ):
        src_MAC = MAC_addr_H[src_host]
        dst_MAC = MAC_addr_H[dst_host_map[src_host]]
        # pkt_app = Ether(src=src_MAC, dst=dst_MAC) / Dot1Q(vlan=vlan_id, prio=vlan_prio) / IP(src=src_IP, dst=dst_IP, ttl=64, chksum=0x7ce7) / ((DEF_PKT_SIZE - HEADER_SIZE)*"A")
        pkt_app = Ether(src=src_MAC, dst=dst_MAC) / IP(src=src_IP, dst=dst_IP, ttl=64, chksum=0x7ce7) / ((DEF_PKT_SIZE - HEADER_SIZE)*"A")
        src_MAC = MAC_addr_S[dst_host_map[src_host]]
        dst_MAC = MAC_addr_H[dst_host_map[src_host]]

        # pkt_exp = Ether(src=src_MAC, dst=dst_MAC) / Dot1Q(vlan=vlan_id, prio=vlan_prio) / IP(src=src_IP, dst=dst_IP, ttl=64, chksum=0x7ce7) / ((DEF_PKT_SIZE - HEADER_SIZE)*"A")
        pkt_exp = Ether(src=src_MAC, dst=dst_MAC) / IP(src=src_IP, dst=dst_IP, ttl=64, chksum=0x7ce7) / ((DEF_PKT_SIZE - HEADER_SIZE)*"A")
        extra_len = 0
    else:
        print("\nERROR: vlan_id not mapped!\n")
        exit(1)

    pkt_app = pad_pkt(pkt_app, DEF_PKT_SIZE)
    ingress = inv_nf_id_map[src_host]
    applyPkt(pkt_app, ingress, time, extra_len)
    pkt_exp = pad_pkt(pkt_exp, DEF_PKT_SIZE)
    egress = inv_nf_id_map[dst_host_map[src_host]]
    drop = False
    if (drop):
        egress = "none"
    expPkt(pkt_exp, egress, drop)

    src_host += 1
    vlan_prio += 1
    if ( src_host > (DEF_HOST_NUM-1) ):
        src_host = 0
        vlan_prio = 0

print("\n\n        Total Packets = " + str(total_packets) + "\n\n")
write_pcap_files()
