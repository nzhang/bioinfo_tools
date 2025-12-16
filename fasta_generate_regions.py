#!/usr/bin/env python3
import sys

if len(sys.argv) < 3:
    print("usage: {} <fai file> <region size>".format(sys.argv[0]))
    sys.exit(1)

fai_file = sys.argv[1]
region_size = int(sys.argv[2])

with open(fai_file) as f:
    for line in f:
        fields = line.strip().split("\t")
        chrom_name = fields[0]
        chrom_length = int(fields[1])
        region_start = 0
        while region_start < chrom_length:
            start = region_start
            end = region_start + region_size
            if end > chrom_length:
                end = chrom_length
            print("{}:{}-{}".format(chrom_name, start, end))
            region_start = end
