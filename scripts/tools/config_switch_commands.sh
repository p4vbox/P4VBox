ovs-ofctl del-flows br0 -O openflow13
ovs-ofctl add-flow br0 "in_port=1, dl_src=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
ovs-ofctl add-flow br0 "in_port=2, dl_src=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
ovs-ofctl add-flow br0 "in_port=3, dl_src=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
ovs-ofctl add-flow br0 "in_port=4, dl_src=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
ovs-ofctl add-flow br0 "in_port=5, dl_src=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
ovs-ofctl add-flow br0 "in_port=6, dl_src=08:22:22:22:22:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
ovs-ofctl add-flow br0 "in_port=7, dl_src=08:11:11:11:11:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
ovs-ofctl add-flow br0 "in_port=1, dl_src=08:33:33:33:33:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:52" -O openflow13
ovs-ofctl add-flow br0 "in_port=2, dl_src=08:44:44:44:44:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:51" -O openflow13
ovs-ofctl add-flow br0 "in_port=3, dl_src=08:33:33:33:33:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:52" -O openflow13
ovs-ofctl add-flow br0 "in_port=4, dl_src=08:44:44:44:44:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:51" -O openflow13
ovs-ofctl add-flow br0 "in_port=5, dl_src=08:33:33:33:33:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:52" -O openflow13
ovs-ofctl add-flow br0 "in_port=6, dl_src=08:44:44:44:44:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:51" -O openflow13
ovs-ofctl add-flow br0 "in_port=7, dl_src=08:33:33:33:33:08, actions=push_vlan:0x8100,mod_vlan_vid:1,output:52" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, nw_dst=10.0.0.1,ip,actions=pop_vlan,output:1" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, nw_dst=10.0.0.2,ip,actions=pop_vlan,output:2" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, nw_dst=10.0.0.3,ip,actions=pop_vlan,output:3" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, nw_dst=10.0.0.4,ip,actions=pop_vlan,output:4" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, nw_dst=10.0.0.20,ip,actions=pop_vlan,output:5" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, nw_dst=10.0.0.21,ip,actions=pop_vlan,output:6" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, nw_dst=10.0.0.30,ip,actions=pop_vlan,output:1" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, nw_dst=10.0.0.31,ip,actions=pop_vlan,output:2" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, nw_dst=10.0.0.32,ip,actions=pop_vlan,output:3" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, nw_dst=10.0.0.33,ip,actions=pop_vlan,output:8" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, nw_dst=10.0.0.40,ip,actions=pop_vlan,output:4" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, nw_dst=10.0.0.41,ip,actions=pop_vlan,output:5" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, nw_dst=10.0.0.42,ip,actions=pop_vlan,output:6" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, nw_dst=10.0.0.43,ip,actions=pop_vlan,output:7" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, nw_dst=10.0.0.1,ip,actions=pop_vlan,output:1" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, nw_dst=10.0.0.2,ip,actions=pop_vlan,output:2" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, nw_dst=10.0.0.3,ip,actions=pop_vlan,output:3" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, nw_dst=10.0.0.4,ip,actions=pop_vlan,output:4" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, nw_dst=10.0.0.20,ip,actions=pop_vlan,output:5" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, nw_dst=10.0.0.21,ip,actions=pop_vlan,output:6" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, nw_dst=10.0.0.30,ip,actions=pop_vlan,output:1" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, nw_dst=10.0.0.31,ip,actions=pop_vlan,output:2" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, nw_dst=10.0.0.32,ip,actions=pop_vlan,output:3" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, nw_dst=10.0.0.33,ip,actions=pop_vlan,output:8" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, nw_dst=10.0.0.40,ip,actions=pop_vlan,output:4" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, nw_dst=10.0.0.41,ip,actions=pop_vlan,output:5" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, nw_dst=10.0.0.42,ip,actions=pop_vlan,output:6" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, nw_dst=10.0.0.43,ip,actions=pop_vlan,output:7" -O openflow13
ovs-ofctl add-flow br0 "in_port=51, nw_dst=10.0.0.1,ip,ip,actions=pop_vlan,output:1" -O openflow13
ovs-ofctl add-flow br0 "in_port=51, nw_dst=10.0.0.2,ip,ip,actions=pop_vlan,output:2" -O openflow13
ovs-ofctl add-flow br0 "in_port=51, nw_dst=10.0.0.3,ip,ip,actions=pop_vlan,output:3" -O openflow13
ovs-ofctl add-flow br0 "in_port=51, nw_dst=10.0.0.4,ip,ip,actions=pop_vlan,output:4" -O openflow13
ovs-ofctl add-flow br0 "in_port=51, nw_dst=10.0.0.20,ip,ip,actions=pop_vlan,output:5" -O openflow13
ovs-ofctl add-flow br0 "in_port=51, nw_dst=10.0.0.21,ip,ip,actions=pop_vlan,output:6" -O openflow13
ovs-ofctl add-flow br0 "in_port=51,nw_dst=10.0.0.30,ip,ip,actions=pop_vlan,output:1" -O openflow13
ovs-ofctl add-flow br0 "in_port=51,nw_dst=10.0.0.31,ip,ip,actions=pop_vlan,output:2" -O openflow13
ovs-ofctl add-flow br0 "in_port=51, nw_dst=10.0.0.32,ip,ip,actions=pop_vlan,output:3" -O openflow13
ovs-ofctl add-flow br0 "in_port=51, nw_dst=10.0.0.33,ip,ip,actions=pop_vlan,output:8" -O openflow13
ovs-ofctl add-flow br0 "in_port=51, nw_dst=10.0.0.40,ip,ip,actions=pop_vlan,output:4" -O openflow13
ovs-ofctl add-flow br0 "in_port=51, nw_dst=10.0.0.41,ip,ip,actions=pop_vlan,output:5" -O openflow13
ovs-ofctl add-flow br0 "in_port=51, nw_dst=10.0.0.42,ip,ip,actions=pop_vlan,output:6" -O openflow13
ovs-ofctl add-flow br0 "in_port=51, nw_dst=10.0.0.43,ip,ip,actions=pop_vlan,output:7" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, nw_dst=10.0.0.1,ip,ip,actions=pop_vlan,output:1" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, nw_dst=10.0.0.2,ip,ip,actions=pop_vlan,output:2" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, nw_dst=10.0.0.3,ip,ip,actions=pop_vlan,output:3" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, nw_dst=10.0.0.4,ip,ip,actions=pop_vlan,output:4" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, nw_dst=10.0.0.20,ip,ip,actions=pop_vlan,output:5" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, nw_dst=10.0.0.21,ip,ip,actions=pop_vlan,output:6" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, nw_dst=10.0.0.30,ip,ip,actions=pop_vlan,output:1" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, nw_dst=10.0.0.31,ip,ip,actions=pop_vlan,output:2" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, nw_dst=10.0.0.32,ip,ip,actions=pop_vlan,output:3" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, nw_dst=10.0.0.33,ip,ip,actions=pop_vlan,output:8" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, nw_dst=10.0.0.40,ip,ip,actions=pop_vlan,output:4" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, nw_dst=10.0.0.41,ip,ip,actions=pop_vlan,output:5" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, nw_dst=10.0.0.42,ip,ip,actions=pop_vlan,output:6" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, nw_dst=10.0.0.43,ip,ip,actions=pop_vlan,output:7" -O openflow13
ovs-ofctl dump-flows br0 -O openflow13
exit
