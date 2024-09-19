# ezTrack-processing

This repository contains Python and MATLAB scripts for batch processing and analyzing fiber photometry data, aligned with freezing data from [ezTrack](https://github.com/denisecailab/ezTrack).

## Python

- **EztrackBatch** 

  This Jupyter notebook runs ezTrack on a batch of videos, based on parameters defined in a CSV file. It allows the user to customize parameters by video instead of keeping them constant. Requires FreezeAnalysis_Functions.py to run ezTrack.

## MATLAB

- **PhotometryFreezingAnalysis**

  This live script uses ezTrack freezing data and fiber photometry data to generate plots for analysis of contextual fear conditioning experiments. These include average calcium traces at freezing and moving onset.

- **ProcessOutputFiles**

  This live script crops raw ezTrack output to match parameters for each stage in the contextual fear conditioning paradigm. It also a inserts timestamps column marking onset of each conditioned stimulus. *Must be run before using PhotometryFreezingAnalysis and SignalVideoAnimation.*

- **SignalVideoAnimation**

  This script generates a segment of a behavioral video that is synced to a fiber photometry trace and a label of freezing or moving. It exports the combined animation at a specified frame rate.

## References

Pennington ZT, Dong Z, Feng Y, Vetere LM, Page-Harley L, Shuman T, Cai DJ (2019). ezTrack: An open-source video analysis pipeline for the investigation of animal behavior. Scientific Reports: 9(1): 19979
