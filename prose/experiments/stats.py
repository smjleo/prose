#!/usr/bin/env python3

import os
import sys
import pandas as pd
import numpy as np
from scipy.stats import sem
from glob import glob

df = pd.read_csv(sys.argv[1])
if 'file' not in df.columns or 'runtime_ms' not in df.columns:
    raise Exception("CSV file must contain 'file' and 'runtime_ms' columns")

stats = df.groupby('file')['runtime_us'].agg(['mean', 'sem']).reset_index()

print(f"{'file':<30} {'mean (ms)':<12} {'sem (ms)':<12}")
print("-" * 60)

for _, row in stats.iterrows():
    print(f"{row['file']:<30} {row['mean']:<12.3f} {row['sem']:<12.3f}")
