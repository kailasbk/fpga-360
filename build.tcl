# define target part and create output directory
set partNum xc7a100tcsg324-1
set outputDir obj
set topLevel top_level

set_part $partNum

file mkdir $outputDir
set files [glob -nocomplain "$outputDir/*"]
if {[llength $files] != 0} {
    file delete -force {*}[glob -directory $outputDir *];
}

# import vivado ip
read_ip ./ip/frame_ram.xcix
read_ip ./ip/depth_ram.xcix
read_ip ./ip/clk_wiz.xcix

# read source files
read_verilog -sv [ glob ./src/util/*.sv ./src/fp/*.sv ./src/graphics/*.sv ./src/control/*.sv ./src/ip/*.sv ./src/*.sv ]
read_verilog -v [ glob ./src/ip/*.v ]
read_xdc ./xdc/top_level.xdc

# run synthesis
synth_design -top $topLevel -part $partNum -verbose
write_checkpoint -force $outputDir/post_synth.dcp
report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
report_utilization -file $outputDir/post_synth_util.rpt
report_timing -file $outputDir/post_synth_timing.rpt

# run optimization
opt_design
place_design
report_clock_utilization -file $outputDir/clock_util.rpt

# get timing violations and run optimizations if needed
if {[get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]] < 0} {
    puts "Found setup timing violations => running physical optimization"
    phys_opt_design
}
write_checkpoint -force $outputDir/post_place.dcp
report_utilization -file $outputDir/post_place_util.rpt
report_timing_summary -file $outputDir/post_place_timing_summary.rpt
report_timing -file $outputDir/post_place_timing.rpt

# route design and generate bitstream
route_design -directive Explore
write_checkpoint -force $outputDir/post_route.dcp
report_route_status -file $outputDir/post_route_status.rpt
report_timing_summary -file $outputDir/post_route_timing_summary.rpt
report_timing -file $outputDir/post_route_timing.rpt
report_power -file $outputDir/post_route_power.rpt
report_drc -file $outputDir/post_imp_drc.rpt
write_bitstream -force $outputDir/out.bit
