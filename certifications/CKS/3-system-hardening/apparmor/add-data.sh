#!/bin/bash
data_directory=/home/ubuntu/tmp
mkdir -p ${data_directory}
echo "=> File created at `date`" | tee ${data_directory}/create.log
