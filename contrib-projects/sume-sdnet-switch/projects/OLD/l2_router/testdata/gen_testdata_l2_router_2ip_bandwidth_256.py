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

####################
# Global variables #
####################
NUM_PKTS = 4096
LEN_PKT = 256
NUM_VLANS = 2
# Time between packets
ENTER_RATE = 0.440

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

nf_port_map = {"nf0":0b00000001, "nf1":0b00000100, "nf2":0b00010000, "nf3":0b01000000, "dma0":0b00000010}
nf_id_map = {"nf0":0, "nf1":1, "nf2":2, "nf3":3}
inv_nf_id_map = {0:"nf0", 1:"nf1", 2:"nf2", 3:"nf3"}

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

#######################
# Topology for router #
#######################
# Topology:
#                   Left                                       Right
# (MAC_addr_H0)             (MAC_addr_SPort0) (MAC_addr_SPort3)             (MAC_addr_H3)
# (IP_addr_H0)                    Port0             Port3                   (IP_addr_H3)
#           H0 ------------------- |                   | ------------------- H3
#                                  |    SUME_SWITCH    |
#           H1 ------------------- |                   | ------------------- H2
# (IP_addr_H1)                    Port1             Port2                   (IP_addr_H2)
# (MAC_addr_H1)             (MAC_addr_SPort1) (MAC_addr_SPort2)             (MAC_addr_H2)
#
#

MAC_addr_H = {}
MAC_addr_H[nf_id_map["nf0"]] = "00:00:00:01:00:01"
MAC_addr_H[nf_id_map["nf1"]] = "00:00:00:01:01:02"
MAC_addr_H[nf_id_map["nf2"]] = "00:00:00:01:02:03"
MAC_addr_H[nf_id_map["nf3"]] = "00:00:00:01:03:04"

MAC_addr_S = {}
MAC_addr_S[nf_id_map["nf0"]] = "00:00:01:00:00:01"
MAC_addr_S[nf_id_map["nf1"]] = "00:00:01:00:00:02"
MAC_addr_S[nf_id_map["nf2"]] = "00:00:01:00:00:03"
MAC_addr_S[nf_id_map["nf3"]] = "00:00:01:00:00:04"

IP_addr_H = {}
IP_addr_H[nf_id_map["nf0"]] = "192.168.0.1"
IP_addr_H[nf_id_map["nf1"]] = "192.168.0.2"
IP_addr_H[nf_id_map["nf2"]] = "192.168.0.3"
IP_addr_H[nf_id_map["nf3"]] = "192.168.0.4"

vlan_id = 1
vlan_prio = 0

# create pkgs
for i in numpy.arange(0, ((NUM_PKTS/(4.0*10.0))/ENTER_RATE), (0.1/ENTER_RATE)):

    pkt_src_host = 0
    pkt_dst_host = 0
    # Definig addresses to send and receive packets
    for j in range(4):
        pkt_src_host = j
        if pkt_src_host == 0:
            # H0 -> H3 | Apply: H0 -> SPort0 | Expected: SPort3 -> H3
            pkt_dst_host = 3
        elif pkt_src_host == 1:
            # H1 -> H2 | Apply: H1 -> SPort1 | Expected: SPort2 -> H2
            pkt_dst_host = 2
        elif pkt_src_host == 2:
            # H2 -> H1 | Apply: H2 -> SPort2 | Expected: SPort1 -> H1
            pkt_dst_host = 1
        elif pkt_src_host == 3:
            # H3 -> H0 | Apply: H3 -> SPort3 | Expected: SPort0 -> H0
            pkt_dst_host = 0

        # Deffining the addresses(IP[src,dst], MAC_applied[src,dst], MAC_expected[src,dst])
        src_IP = IP_addr_H[pkt_src_host]
        dst_IP = IP_addr_H[pkt_dst_host]

        if (vlan_id == 2 or vlan_id == 4):
            src_MAC_app = MAC_addr_H[pkt_src_host]
            dst_MAC_app = MAC_addr_S[pkt_src_host]
            src_MAC_exp = MAC_addr_S[pkt_dst_host]
            dst_MAC_exp = MAC_addr_H[pkt_dst_host]

            # create input pkts
            pkt_app = Ether(src=src_MAC_app, dst=dst_MAC_app) / Dot1Q(vlan=vlan_id, prio=vlan_prio) / IP(ttl=64, chksum=0x7ce7, src=src_IP, dst=dst_IP) / UDP(sport=10415, dport=8888) / ('a'*(LEN_PKT - 46))
            pkt_app = pad_pkt(pkt_app, LEN_PKT)
            ingress = inv_nf_id_map[pkt_src_host]
            applyPkt(pkt_app, ingress, i)
            # create expected pkts
            drop = False
            # router P4 code decrement the ttl but dont tach in chksum, them we need force ttl and chksum fields
            pkt_exp = Ether(src=src_MAC_exp, dst=dst_MAC_exp) / Dot1Q(vlan=vlan_id, prio=vlan_prio) / IP(ttl=63, chksum=0x7ce7, src=src_IP, dst=dst_IP) / UDP(sport=10415, dport=8888) / ('a'*(LEN_PKT - 46))
            pkt_exp = pad_pkt(pkt_exp, LEN_PKT)
            egress = inv_nf_id_map[pkt_dst_host]
            expPkt(pkt_exp, egress, drop)
        elif (vlan_id == 1 or vlan_id == 3):
            src_MAC_app = MAC_addr_H[pkt_src_host]
            dst_MAC_app = MAC_addr_H[pkt_dst_host]
            # create input pkts
            pkt_app = Ether(src=src_MAC_app, dst=dst_MAC_app) / Dot1Q(vlan=vlan_id, prio=vlan_prio) / IP(src=src_IP, dst=dst_IP) / UDP(sport=20415, dport=1234) / ('a'*(LEN_PKT - 46))
            pkt_app = pad_pkt(pkt_app, LEN_PKT)
            ingress = inv_nf_id_map[pkt_src_host]
            egress = inv_nf_id_map[pkt_dst_host]
            drop = False
            applyPkt(pkt_app, ingress, i)
            expPkt(pkt_app, egress, drop)

    if vlan_id < NUM_VLANS :
        vlan_id += 1
        # vlan_prio += 1
    else :
        vlan_id = 1
        # vlan_prio = 1

write_pcap_files()