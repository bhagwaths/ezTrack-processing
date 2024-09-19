# ezTrack-processing

This repository contains Python and MATLAB scripts for batch processing and analyzing fiber photometry data, aligned with freezing data from [ezTrack](https://github.com/denisecailab/ezTrack).

**EztrackBatch**  (Python)

This Jupyter notebook runs ezTrack on a batch of videos, based on parameters defined in a CSV file. It allows the user to customize parameters by video instead of keeping them constant. Requires FreezeAnalysis_Functions.py to run ezTrack.

**PhotometryFreezingAnalysis** (MATLAB)

This live script uses ezTrack freezing data and fiber photometry data to generate plots for analysis of contextual fear conditioning experiments. These include average calcium traces at freezing and moving onset.

**ProcessOutputFiles** (MATLAB)

This live script crops raw ezTrack output to match parameters for each stage in contextual fear conditioning. It also a inserts timestamps column marking onset of each conditioned stimulus. *Must be run before using PhotometryFreezingAnalysis and SignalVideoAnimation.*

**SignalVideoAnimation** (MATLAB)

This script generates a segment of a behavioral video that is synced to a fiber photometry trace and a label of freezing or moving. It exports the video at a specified frame rate.
