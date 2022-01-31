from scapy.all import *

TYPE_PROBE = 0x200
MAX_INFRA = 16

class Probe(Packet):
   fields_desc = [ ByteField("hop_cnt", 0)]

class ProbeData(Packet):
   fields_desc = [ BitField("occup", 0, 8),
                   BitField("nnid", 0, 8),
                   BitField("op", 0, 8),
                   BitField("neurondst", 0, MAX_INFRA),
                   BitField("info", 0, 64),
                   BitField("data", 0, 128)]

class ProbeFwd(Packet):
   fields_desc = [ ByteField("egress_spec", 0),
                   ByteField("op",0) ]

bind_layers(Ether, Probe, type=TYPE_PROBE)
bind_layers(Probe, ProbeFwd, hop_cnt=0)
bind_layers(Probe, ProbeData)
bind_layers(ProbeData, ProbeData, bos=0)
bind_layers(ProbeData, ProbeFwd, bos=1)
bind_layers(ProbeFwd, ProbeFwd)
