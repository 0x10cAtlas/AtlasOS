#!/bin/sh

mono organic.exe --working-directory kernel/ --input-file kernel/core.dasm16 --output-file AtlasOS.bin
java -jar utilities\bin2asmbin\bin2asmbin.jar AtlasOS.bin AtlasOS_D.dasm16 -l