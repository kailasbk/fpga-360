iverilog -g2012 -Y .v -o ./sim.out $@
vvp ./sim.out -lxt2
