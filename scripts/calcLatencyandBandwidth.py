#!/usr/bin/env python

#
# Copyright (c) 2019 Mateus Saquetti
# All rights reserved.
#
# This software was developed by Institute of Informatics of the Federal
# University of Rio Grande do Sul (INF-UFRGS)
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

import argparse

args = None

def calcLatency(t_beg, t_end, clk_max_p):
    global args
    # clk_max_p = period of clock max of critical path in ns
    time = t_end - t_beg
    t_rount_trip = 2*time
    # 5 ns = 1/(defult_clock=200MHz)/1000000
    # number of clock cycles from the input port to the output port
    n_of_clock_cycles = t_rount_trip / 5
    latency_ns = n_of_clock_cycles*clk_max_p
    latency = latency_ns/1000

    print("Packet processing time: "+ str(time))
    print("Packet round trip time: "+ str(t_rount_trip))
    print("Packet number of clock cycles: "+ str(n_of_clock_cycles))
    print("Packet latency time[ns]: "+ str(latency_ns))
    print("Packet latency time[us]: "+ str(latency))
    print("\n")

def calcBandwidth(t_beg, t_end, clk_max_p, n_pkt, tam_pkt_bytes):
    global args
    time_total = t_end - t_beg
    time_pkt = time_total/n_pkt
    inv_time_pkt = 1/time_pkt
    freq_process = inv_time_pkt * 1000000
    freq_process_bytes = freq_process*tam_pkt_bytes
    freq_process_bits = freq_process_bytes*8
    # critical_period = (clock_base in GigaHertz)^-1 / period of clock max of critical path in ns (clock_base == 200 MHz)
    critical_period = (1.0/(200.0/1000.0)) / clk_max_p
    bandwidth_bps = freq_process_bits*critical_period
    bandwidth = bandwidth_bps/1000

    print("Total packets: "+ str(n_pkt))
    print("Packets length: "+ str(tam_pkt_bytes) +" bytes")
    print("Processing start: "+ str(t_beg) +" ns")
    print("End Processing:: "+ str(t_end) +" ns")
    print("Packet processing total time: "+ str(time_total))
    print("Average processing time per package: "+ str(time_pkt))
    # print("(Time processing per Packet)^-1: "+ str(inv_time_pkt))
    # print("Processing frequency: "+ str(freq_process))
    # print("Processing frequency bytes: "+ str(freq_process_bytes))
    # print("Processing frequency bits: "+ str(freq_process_bits))
    print("Total data: "+ str(n_pkt*tam_pkt_bytes) +" bytes")
    # print("Bandwidth: "+ str(bandwidth_bps) +" bps")
    print("Bandwidth: "+ str(bandwidth) +" Mbps")

def getArgs():
    global args
    parser = argparse.ArgumentParser(prog="calcLatencyBandwidth", usage="%(prog)s p4_switch [options] [--help]", description="Calc latency and bandwidth.")
    parser.add_argument("switch", type=str, metavar="<string>", help="The name of P4 switch to virtualize. ")
    parser.add_argument("--clock_p", type=str, metavar="<float>", default="1.826", help="The period of clock max of critical path in ns.")
    parser.add_argument("--bandwidth", action="store_true", help="Calc only bandwidth.")
    parser.add_argument("--packets",type=str, metavar="<integer>", default="64", help="Number of total packets to calc bandwidth.")
    parser.add_argument("--lenght",type=str, metavar="<integer>", default="256", help="Lenght of packets to calc bandwidth.")
    parser.add_argument("--dt3", action="store_true", help="Calc bandwidth to Dataset 3.")
    parser.add_argument("--latency", action="store_true", help="Calc only latency.")
    args = parser.parse_args()

def main():
    global args
    getArgs()
    n_packets=0
    len_packets=0

    # latency times:
    lat_time_beg_l2_switch = 10816.5
    lat_time_end_l2_switch = 11588.0
    lat_time_beg_router = 10816.5
    lat_time_end_router = 11952.0
    lat_time_beg_firewall = 10816.5
    lat_time_end_firewall = 11944.0
    lat_time_beg_l2_router = 12824.5
    lat_time_end_l2_router = 13996.0

    # Bandwidth times:
    ban_time_beg_l2_switch = 10816.5
    # ban_time_end_l2_switch = 270368.0 # Dataset 1 => packets: 16384   | length: 64        | RATE: 1.825  | bandwidth: 88.498 G | OPI queue = 1
    # ban_time_end_l2_switch = 269616.0 # Dataset 2 => packets: 4096    | length: 256       | RATE: 0.440  | bandwidth: 88.755 G | OPI queue = 1
    # ban_time_end_l2_switch = 269788.0 # Dataset 3 => peckets: 699 + 1 | length: 1500 + 76 | RATE: 0.075  | bandwidth: 88.817 G | OPI queue = 4

    ban_time_beg_router = 10816.5
    # ban_time_end_router = 294216.0    # Dataset 1 => packets: 16384   | length: 64        | RATE: 1.607  | bandwidth: 81.051 G | OPI queue = 2
	# ban_time_end_router = 293584.0    # Dataset 2 => packets: 4096    | length: 256       | RATE: 0.402  | bandwidth: 81.232 G | OPI queue = 4
    # ban_time_end_router = 293840.0    # Dataset 3 => peckets: 699 + 1 | length: 1500 + 76 | RATE: 0.068  | bandwidth: 81.269 G | OPI queue = 4

    ban_time_beg_firewall = 10816.5
    # ban_time_end_firewall = 292264.0  # Dataset 1 => packets: 16384   | length: 64        | RATE: 1.6100 | bandwidth: 81.613 G | OPI queue = 1
    # ban_time_end_firewall = 292276.0  # Dataset 2 => packets: 4096    | length: 256       | RATE: 0.4020 | bandwidth: 81.609 G | OPI queue = 4
    # ban_time_end_firewall = 292292.0  # Dataset 3 => peckets: 699 + 1 | length: 1500 + 76 | RATE: 0.0685 | bandwidth: 81.716 G | OPI queue = 4

    ban_time_beg_l2_router = 10816.5
    # ban_time_end_l2_router = 270752.0 # Dataset 1 => packets: 16384   | length: 64        | RATE: 1.825  | bandwidth: 88.367 G | OPI queue = 2
    # ban_time_end_l2_router = 270000.0 # Dataset 2 => packets: 4096    | length: 256       | RATE: 0.440  | bandwidth: 88.624 G | OPI queue = 2
    # ban_time_end_l2_router = 269980.0 # Dataset 3 => peckets: 699 + 1 | length: 1500 + 76 | RATE: 0.0750 | bandwidth: 88.751 G | OPI queue = 4

    # definning switch:
    if ( args.switch == 'l2_switch' ):
        lat_time_beg = lat_time_beg_l2_switch
        lat_time_end = lat_time_end_l2_switch
        ban_time_beg = ban_time_beg_l2_switch
        ban_time_end = ban_time_end_l2_switch
    elif ( args.switch == 'router' ):
        lat_time_beg = lat_time_beg_router
        lat_time_end = lat_time_end_router
        ban_time_beg = ban_time_beg_router
        ban_time_end = ban_time_end_router
    elif ( args.switch == 'firewall' ):
        lat_time_beg = lat_time_beg_firewall
        lat_time_end = lat_time_end_firewall
        ban_time_beg = ban_time_beg_firewall
        ban_time_end = ban_time_end_firewall
    elif ( args.switch == 'l2_router' ):
        lat_time_beg = lat_time_beg_l2_router
        lat_time_end = lat_time_end_l2_router
        ban_time_beg = ban_time_beg_l2_router
        ban_time_end = ban_time_end_l2_router

    # period of clock max of critical path in ns
    clock_p_old = 1.893
    clock_p_new = 1.826
    clock_p = float(args.clock_p)
    # clock_p = clock_p_old
    print("Clock period: "+ str(clock_p))

    n_packets = int(args.packets)
    len_packets = int(args.lenght)

    if ( args.latency ):
        calcLatency(lat_time_beg, lat_time_end, clock_p)
    elif ( args.bandwidth ):
        calcBandwidth(ban_time_beg, ban_time_end, clock_p, n_packets, len_packets)
    else:
        calcLatency(lat_time_beg, lat_time_end, clock_p)
        calcBandwidth(ban_time_beg, ban_time_end, clock_p, n_packets, len_packets)


if __name__ == "__main__":
    main()
