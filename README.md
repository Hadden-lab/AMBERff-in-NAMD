# AMBERff-in-NAMD

All-atom molecular dynamics (MD) simulations are an essential structural biology technique with increasing application to multimillion-atom systems, 
including viruses and cellular machinery. Classical MD simulations rely on parameter sets, such as the AMBER family of force fields (AMBERff), to accurately 
describe molecular motion. Here, we present an implementation of AMBERff for use in NAMD that overcomes previous limitations to enable high-performance,
massively-parallel simulations encompassing up to two billion atoms. Single-point potential energy comparisons and case studies on model systems demonstrate
that the implementation produces results that are as accurate as running AMBERff in its native engine. 

Please cite:
Antolínez, S.; Jones, P. E.; Phillips, J. C.; Hadden-Perilla J. A.
AMBERff at scale: Multimillion-atom simulations with AMBER force fields in NAMD. Submitted (2023)
https://doi.org/10.1101/2023.10.10.561755