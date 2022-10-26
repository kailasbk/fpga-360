iverilog -g2012 -o sim/sim.out $@ > sim/iverilog.log 2> sim/iverilog.log
cd sim
vvp sim.out
