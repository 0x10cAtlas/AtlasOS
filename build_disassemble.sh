#!/bin/sh

mono organic.exe --input-file make.dasm16 --output-file AtlasOS.bin
java -jar utilities/bin2asmbin/bin2asmbin.jar AtlasOS.bin AtlasOS_D.dasm16 -l