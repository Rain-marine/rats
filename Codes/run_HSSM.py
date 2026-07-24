#!/usr/bin/env python
# coding: utf-8

# In[ ]:


import os
import sys

import numpyro
numpyro.set_host_device_count(4)

import numpy as np
import pandas as pd
import arviz as az
import hssm

condition = sys.argv[1]  # T1 or T3

DATA_DIR = "../data"
OUT_DIR = f"../results/hssm_{condition}"
ONNX_PATH = "onnx/ddm_opn.onnx"

os.makedirs(OUT_DIR, exist_ok=True)

df = pd.read_parquet(f"{DATA_DIR}/after_{condition}.parquet")

tmp_df = df[["RatID", "Trial", "Date", "Correct", "ReactionTime"]].copy()

tmp_df = tmp_df.rename(columns={
    "RatID": "subj_idx",
    "ReactionTime": "rt"
})

tmp_df["response"] = np.where(tmp_df["Correct"].isin([0, 1]), 1, -1)
tmp_df["rt"] = tmp_df["rt"].fillna(-999)
tmp_df["deadline"] = 1.75

model_df = tmp_df[["subj_idx", "rt", "response", "deadline"]].copy()

model_df["rt"] = model_df["rt"].astype("float32")
model_df["deadline"] = model_df["deadline"].astype("float32")
model_df["response"] = model_df["response"].astype("int32")
model_df["subj_idx"] = model_df["subj_idx"].astype("int32")

model_df.to_parquet(f"{OUT_DIR}/{condition}_model_df.parquet")

m = hssm.HSSM(
    data=model_df,
    model="ddm",
    missing_data=True,
    deadline="deadline",
    loglik_kind="approx_differentiable",
    loglik_missing_data=ONNX_PATH
)

draws = 2000
tune = 2000

idata = m.sample(
    sampler="numpyro",
    chains=4,
    cores=4,
    draws=draws,
    tune=tune,
    progressbar=True
)

az.to_netcdf(idata, f"{OUT_DIR}/{condition}_idata.nc")
az.summary(idata).to_csv(f"{OUT_DIR}/{condition}_summary.csv")

print(f"Finished {condition}")


# In[ ]:




