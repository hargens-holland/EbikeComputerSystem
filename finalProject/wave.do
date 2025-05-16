onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /eBike_tb2/TORQUE
add wave -noupdate /eBike_tb2/iDUT/iSensorCondition/cadence
add wave -noupdate -format Analog-Step -height 74 -max 70.0 -radix unsigned /eBike_tb2/iDUT/iSensorCondition/target_curr
add wave -noupdate -format Analog-Step -height 74 -max 14.999999999999998 -radix unsigned /eBike_tb2/iDUT/iSensorCondition/avg_curr
add wave -noupdate -format Analog-Step -height 74 -max 70.0 -radix decimal /eBike_tb2/iDUT/iSensorCondition/error
add wave -noupdate /eBike_tb2/iDUT/highGrn
add wave -noupdate /eBike_tb2/iDUT/lowGrn
add wave -noupdate /eBike_tb2/iPHYS/SS_n
add wave -noupdate /eBike_tb2/iPHYS/SCLK
add wave -noupdate /eBike_tb2/iPHYS/MOSI
add wave -noupdate /eBike_tb2/iPHYS/NEMO_setup
add wave -noupdate -format Analog-Step -height 74 -max 41.999999999999559 -min -128031.0 /eBike_tb2/iPHYS/omega
TreeUpdate [SetDefaultTree]
WaveRestoreCursors
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 2
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {47795664 ps}
