#!/bin/bash

while read p; do
  echo $1,$p >> result.csv
done <$1
