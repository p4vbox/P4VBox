create_pblock pblock_vSwitch0
add_cells_to_pblock [get_pblocks pblock_vSwitch0] [get_cells -quiet [list nf_datapath_0/wrapper_vSwitch0]]
resize_pblock [get_pblocks pblock_vSwitch0] -add {SLICE_X2Y300:SLICE_X103Y499}
resize_pblock [get_pblocks pblock_vSwitch0] -add {DSP48_X0Y120:DSP48_X6Y199}
resize_pblock [get_pblocks pblock_vSwitch0] -add {RAMB18_X0Y120:RAMB18_X6Y199}
resize_pblock [get_pblocks pblock_vSwitch0] -add {RAMB36_X0Y60:RAMB36_X6Y99}
set_property RESET_AFTER_RECONFIG true [get_pblocks pblock_vSwitch0]
set_property SNAPPING_MODE ON [get_pblocks pblock_vSwitch0]
create_pblock pblock_vSwitch1
add_cells_to_pblock [get_pblocks pblock_vSwitch1] [get_cells -quiet [list nf_datapath_0/wrapper_vSwitch1]]
resize_pblock [get_pblocks pblock_vSwitch1] -add {SLICE_X2Y2:SLICE_X103Y199}
resize_pblock [get_pblocks pblock_vSwitch1] -add {DSP48_X0Y2:DSP48_X6Y79}
resize_pblock [get_pblocks pblock_vSwitch1] -add {RAMB18_X0Y2:RAMB18_X6Y79}
resize_pblock [get_pblocks pblock_vSwitch1] -add {RAMB36_X0Y1:RAMB36_X6Y39}
set_property RESET_AFTER_RECONFIG true [get_pblocks pblock_vSwitch1]
set_property SNAPPING_MODE ON [get_pblocks pblock_vSwitch1]
