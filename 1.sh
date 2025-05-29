#!/bin/bash
# Step 1: Clean the build
echo "Running: make clean"
make clean
# Step 2: Build target g++_final
echo "Running: make g++_final"
make g++_final
# Step 3: Run gem5_public with ARGS=P3
#echo "Running: make gem5_public ARGS=P3"
#make gem5_public ARGS=P3
# Step 3: Run gem5_public with all public cases
# 跑全部 public cases
echo "Running: make gem5_public_all"
make gem5_public_all
echo "All tasks completed."
# Step 4 : Compare to golden output
 echo "Comparing output to golden output"
 make testbench_public
# Step 5: Get Score
 echo "Getting score"
 make score_public