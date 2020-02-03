# noVLAN commands:
ovs-ofctl add-flow br0 "in_port=1, actions=output:49" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, actions=output:1" -O openflow13
ovs-ofctl add-flow br0 "in_port=2, actions=output:50" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, actions=output:2" -O openflow13
ovs-ofctl add-flow br0 "in_port=13, actions=output:51" -O openflow13
ovs-ofctl add-flow br0 "in_port=51, actions=output:13" -O openflow13
ovs-ofctl add-flow br0 "in_port=14, actions=output:52" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, actions=output:14" -O openflow13

# VLAN = 1 commands:
# ovs-ofctl add-flow br0 "in_port=1, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=49, actions=pop_vlan,output:1" -O openflow13
# ovs-ofctl add-flow br0 "in_port=2, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
# ovs-ofctl add-flow br0 "in_port=50, actions=pop_vlan,output:2" -O openflow13

# ovs-ofctl add-flow br0 "in_port=1, actions=push_vlan:0x8100,mod_vlan_vid:1,output:49" -O openflow13
# ovs-ofctl add-flow br0 "in_port=49, actions=pop_vlan,output:1, output:3" -O openflow13
# ovs-ofctl add-flow br0 "in_port=2, actions=push_vlan:0x8100,mod_vlan_vid:1,output:50" -O openflow13
# ovs-ofctl add-flow br0 "in_port=50, actions=pop_vlan,output:2, output:4" -O openflow13

# VLAN = 2 commands:
ovs-ofctl add-flow br0 "in_port=13, actions=push_vlan:0x8100,mod_vlan_vid:2,output:51" -O openflow13
ovs-ofctl add-flow br0 "in_port=51, actions=pop_vlan,output:13" -O openflow13
ovs-ofctl add-flow br0 "in_port=14, actions=push_vlan:0x8100,mod_vlan_vid:2,output:52" -O openflow13
ovs-ofctl add-flow br0 "in_port=52, actions=pop_vlan,output:14" -O openflow13

ovs-ofctl dump-flows br0 -O openflow13
exit
