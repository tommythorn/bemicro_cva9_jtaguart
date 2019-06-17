all:
	quartus_map bemicro_cva9_jtaguart
	quartus_fit bemicro_cva9_jtaguart
	quartus_asm bemicro_cva9_jtaguart
	quartus_pgm bemicro_cva9_jtaguart.cdf
	nios2-terminal|dd of=/dev/null status=progress bs=65535
