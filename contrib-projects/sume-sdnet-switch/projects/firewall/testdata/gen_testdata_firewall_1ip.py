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
# Copyright (c) 2019 Mateus Saquetti
# All rights reserved.
#
# This software was modified by Institute of Informatics of the Federal
# University of Rio Grande do Sul (INF-UFRGS)
#
# Description:
#              Adapted to run in P4VBox architecture
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
import sss_sdnet_tuples

DEF_PKT_SIZE = 256  # default packet size (in bytes)
HEADER_SIZE = 46    # size of Ether/IP/UDP headers
DEF_PKT_NUM = 24    # default number of packets to simulation
VLAN_NUM = 1        # number of vlans (number of p4 switch running in parallel)
VLAN_ID = 3         # id of vlan matching with IPI architecture ans nf_datapath.v

dst_host_map = {0:1, 1:0, 2:3, 3:2} # dictionary to map the sender and receiver Hosts H[0, 1, 2, 3] based in network topology
inv_nf_id_map = {0:"nf0", 1:"nf1", 2:"nf2", 3:"nf3"}

###########
# pkt generation tools
###########

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

nf_port_map = {"nf0":0b00000001, "nf1":0b00000100, "nf2":0b00010000, "nf3":0b01000000, "dma0":0b00000010, "none":0b00000000}
nf_id_map = {"nf0":0, "nf1":1, "nf2":2, "nf3":3}

sss_sdnet_tuples.clear_tuple_files()

def applyPkt(pkt, ingress, time):
    pktsApplied.append(pkt)
    sss_sdnet_tuples.sume_tuple_in['pkt_len'] = len(pkt)
    sss_sdnet_tuples.sume_tuple_in['src_port'] = nf_port_map[ingress]
    sss_sdnet_tuples.sume_tuple_expect['pkt_len'] = len(pkt)
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
MAC_addr_H[nf_id_map["nf0"]] = "08:11:11:11:11:08"
MAC_addr_H[nf_id_map["nf1"]] = "08:22:22:22:22:08"
MAC_addr_H[nf_id_map["nf2"]] = "08:33:33:33:33:08"
MAC_addr_H[nf_id_map["nf3"]] = "08:44:44:44:44:08"

IP_addr_H = {}
IP_addr_H[nf_id_map["nf0"]] = "10.1.1.1"
IP_addr_H[nf_id_map["nf1"]] = "10.2.2.2"
IP_addr_H[nf_id_map["nf2"]] = "10.3.3.3"
IP_addr_H[nf_id_map["nf3"]] = "10.4.4.4"

BLOCK_SPORT = 1234
BLOCK_DPORT = 8888

def get_rand_port():
    return random.randint(1, 0xffff)

def get_rand_block():
    rand_sport = get_rand_port()
    rand_dport = get_rand_port()
    while ((rand_sport == BLOCK_SPORT) or (rand_dport == BLOCK_DPORT)):
        rand_sport = get_rand_port()
        rand_dport = get_rand_port()
    rand_block = bool(random.getrandbits(1))
    if ( rand_block ):
        if ( bool(random.getrandbits(1)) ):
            rand_sport = BLOCK_SPORT
        else:
            rand_dport = BLOCK_DPORT

    return (rand_sport, rand_dport, rand_block)

block = False
vlan_prio = 0
src_ind = 0

# create some packets
for time in range(DEF_PKT_NUM):
    src_MAC = MAC_addr_H[src_ind]
    dst_MAC = MAC_addr_H[dst_host_map[src_ind]]
    src_IP = IP_addr_H[src_ind]
    dst_IP = IP_addr_H[dst_host_map[src_ind]]
    (sport, dport, block) = get_rand_block()

    pkt_app = Ether(src=src_MAC, dst=dst_MAC) / Dot1Q(vlan=VLAN_ID, prio=vlan_prio) / IP(src=src_IP, dst=dst_IP, ttl=20) / UDP(sport=sport, dport=dport) / ((DEF_PKT_SIZE - HEADER_SIZE)*"A")
    pkt_app = pad_pkt(pkt_app, DEF_PKT_SIZE)
    ingress = inv_nf_id_map[src_ind]
    applyPkt(pkt_app, ingress, time)

    pkt_exp = Ether(src=src_MAC, dst=dst_MAC) / Dot1Q(vlan=VLAN_ID, prio=vlan_prio) / IP(src=src_IP, dst=dst_IP, ttl=20) / UDP(sport=sport, dport=dport) / ((DEF_PKT_SIZE - HEADER_SIZE)*"A")
    pkt_exp = pad_pkt(pkt_exp, DEF_PKT_SIZE)
    egress = inv_nf_id_map[dst_host_map[src_ind]]
    if ( block ):
        egress = "none"
    expPkt(pkt_exp, egress, block)

    src_ind += 1
    vlan_prio += 1
    if (src_ind > 3):
        src_ind = 0
        vlan_prio = 0

write_pcap_files()
