ovs-ofctl add-flow br0 "in_port=1, actions=output:49" -O openflow13
ovs-ofctl add-flow br0 "in_port=49, actions=output:1" -O openflow13
ovs-ofctl add-flow br0 "in_port=2, actions=output:50" -O openflow13
ovs-ofctl add-flow br0 "in_port=50, actions=output:2" -O openflow13

ovs-ofctl dump-flows br0 -O openflow13
exit
