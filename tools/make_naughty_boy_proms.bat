
copy /B 15.44 + 16.43 graphx_10.bin
copy /B 13.46 + 14.45 graphx_11.bin
copy /B 11.48 + 12.47 graphx_20.bin
copy /B  9.50 + 10.49 graphx_21.bin
copy /B 1.30 + 2.29 + 3.28 + 4.27 + 5.26 + 6.25 + 7.24 + 8.23 prog.bin


make_vhdl_prom graphx_10.bin prom_graphx_1_bit0.vhd
make_vhdl_prom graphx_11.bin prom_graphx_1_bit1.vhd
make_vhdl_prom graphx_20.bin prom_graphx_2_bit0.vhd
make_vhdl_prom graphx_21.bin prom_graphx_2_bit1.vhd
make_vhdl_prom prog.bin prom_prog.vhd

make_vhdl_prom 6301-1.63 prom_palette_1.vhd
make_vhdl_prom 6301-1.64 prom_palette_2.vhd

