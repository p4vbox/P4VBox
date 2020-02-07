ovs-ofctl del-flows br0 -O openflow13

# no VLAN commands:
ovs-ofctl add-flow br0 "in_port=1, actions=output:49" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, actions=output:1" -O openflow13
ovs-ofctl add-flow br0 "in_port=2, actions=output:50" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, actions=output:2" -O openflow13
ovs-ofctl add-flow br0 "in_port=13, actions=output:51" -O openflow13
ovs-ofctl add-flow br0 "in_port=51, actions=output:13" -O openflow13
ovs-ofctl add-flow br0 "in_port=14, actions=output:52" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, actions=output:14" -O openflow13

# # VLAN = 1 commands:
# ovs-ofctl add-flow br0 "in_port=1, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=49, actions=pop_vlan,output:1" -O openflow13
# ovs-ofctl add-flow br0 "in_port=2, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
# ovs-ofctl add-flow br0 "in_port=50, actions=pop_vlan,output:2" -O openflow13
#
# # VLAN = 2 commands:
# ovs-ofctl add-flow br0 "in_port=13, actions=push_vlan:0x8100,mod_vlan_vid:2,output:51" -O openflow13
# ovs-ofctl add-flow br0 "in_port=51, actions=pop_vlan,output:13" -O openflow13
# ovs-ofctl add-flow br0 "in_port=14, actions=push_vlan:0x8100,mod_vlan_vid:2,output:52" -O openflow13
# ovs-ofctl add-flow br0 "in_port=52, actions=pop_vlan,output:14" -O openflow13

# Bandwidth Test
# ovs-ofctl del-flows br0 -O openflow13
# ovs-ofctl add-flow br0 "in_port=1,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
# ovs-ofctl add-flow br0 "in_port=2,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
# ovs-ofctl add-flow br0 "in_port=3,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
# ovs-ofctl add-flow br0 "in_port=4,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=11,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
# ovs-ofctl add-flow br0 "in_port=12,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=13,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
# ovs-ofctl add-flow br0 "in_port=14,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=23,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
# ovs-ofctl add-flow br0 "in_port=24,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=25,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
# ovs-ofctl add-flow br0 "in_port=26,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
# ovs-ofctl add-flow br0 "in_port=27,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
# ovs-ofctl add-flow br0 "in_port=28,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
# ovs-ofctl add-flow br0 "in_port=37,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
# ovs-ofctl add-flow br0 "in_port=38,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
# ovs-ofctl add-flow br0 "in_port=39,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
# ovs-ofctl add-flow br0 "in_port=40,dl_dst=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=1,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=2,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=3,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=4,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=11,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=12,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=13,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=14,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=23,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=24,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=25,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=26,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=27,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=28,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=37,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=38,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=39,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=40,dl_dst=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.1,ip,actions=pop_vlan,output:1" -O openflow13
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.2,ip,actions=pop_vlan,output:2" -O openflow13
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.3,ip,actions=pop_vlan,output:3" -O openflow13
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.4,ip,actions=pop_vlan,output:4" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.10,ip,actions=pop_vlan,output:13" -O openflow13
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.11,ip,actions=pop_vlan,output:14" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.20,ip,actions=pop_vlan,output:25" -O openflow13
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.21,ip,actions=pop_vlan,output:26" -O openflow13
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.22,ip,actions=pop_vlan,output:27" -O openflow13
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.23,ip,actions=pop_vlan,output:28" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.30,ip,actions=pop_vlan,output:37" -O openflow13
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.31,ip,actions=pop_vlan,output:38" -O openflow13
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.32,ip,actions=pop_vlan,output:39" -O openflow13
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.33,ip,actions=pop_vlan,output:40" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.40,ip,actions=pop_vlan,output:11" -O openflow13
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.41,ip,actions=pop_vlan,output:12" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.50,ip,actions=pop_vlan,output:23" -O openflow13
# ovs-ofctl add-flow br0 "in_port=49,nw_dst=10.1.0.51,ip,actions=pop_vlan,output:24" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.1,ip,actions=pop_vlan,output:1" -O openflow13
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.2,ip,actions=pop_vlan,output:2" -O openflow13
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.3,ip,actions=pop_vlan,output:3" -O openflow13
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.4,ip,actions=pop_vlan,output:4" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.10,ip,actions=pop_vlan,output:13" -O openflow13
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.11,ip,actions=pop_vlan,output:14" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.20,ip,actions=pop_vlan,output:25" -O openflow13
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.21,ip,actions=pop_vlan,output:26" -O openflow13
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.22,ip,actions=pop_vlan,output:27" -O openflow13
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.23,ip,actions=pop_vlan,output:28" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.30,ip,actions=pop_vlan,output:37" -O openflow13
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.31,ip,actions=pop_vlan,output:38" -O openflow13
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.32,ip,actions=pop_vlan,output:39" -O openflow13
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.33,ip,actions=pop_vlan,output:40" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.40,ip,actions=pop_vlan,output:11" -O openflow13
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.41,ip,actions=pop_vlan,output:12" -O openflow13
#
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.50,ip,actions=pop_vlan,output:23" -O openflow13
# ovs-ofctl add-flow br0 "in_port=50,nw_dst=10.1.0.51,ip,actions=pop_vlan,output:24" -O openflow13



ovs-ofctl dump-flows br0 -O openflow13
exit
