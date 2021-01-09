genam -IGames1:Utilities/Devpac/Include -L bootblockplot.s to bootblockplot.o
vlink -brawbin1 bootblockplot.o -o bootblockplot.bin
pad bootblockplot.bin 0 1024 64 bootblockpadded.bin
;# delete bootblockplotpadded.bin
;# rename outpadded to bootblockplotpadded.bin


;# genam -L plot.s to plot.o
;# vlink -brawbin1 -Ttext 0x70000 plot.o -o plot.bin
;#pad plot.bin 0 11776 11268
;#delete plotpadded2.bin
;#rename outpadded to plotpadded2.bin

genam -L plotsperimentale.s to plotsperimentale.o
vlink -brawbin1 -Ttext 0x70000 plotsperimentale.o -o plotsperimentale.bin
pad plotsperimentale.bin 0 -1 -1 plotsperimentalepadded.bin
;# rename outpadded to plotsperimentalepadded.bin

join bootblockplotpadded.bin plotsperimentalepadded.bin to final.bin
makeadf final.bin > final.adf
transadf write drive=df0: file=final.adf
