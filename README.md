# AI Traffic Signals That See Pedestrians

**MSc Artificial Intelligence Dissertation — University of East London, 2026**  
**Student:** Murtuza Shareef Mohammed | **Supervisor:** Dr. B. N. Ossai

## Overview
This project presents an AI-driven pedestrian signal optimisation system 
integrating YOLOv8 object detection with SUMO traffic simulation via a 
Python TraCI bridge. Evaluated at a simulated Ilford High Road junction, 
Borough of Redbridge, London.

## Key Results
| Metric | Result |
|--------|--------|
| Pedestrian wait time reduction (QB-POL, peak) | **−34.4%** |
| Emission reduction (NOx + CO₂ average) | **−21.1%** |
| Vehicle delay increase | **+1.0s (p = 0.263, not significant)** |
| YOLOv8s mAP@50 (post fine-tuning) | **0.941** |

## System Components
- **YOLOv8s** — Pedestrian detection model (Ultralytics 8.0.196)
- **SUMO 1.18** — Ilford High Road junction traffic simulation
- **Python TraCI** — Adaptive signal controller (T-POL, P-POL, QB-POL)
- **HBEFA3** — Emission modelling (built into SUMO)

## How to Run
See the Execution Guide in this repo or follow the steps below.

### 1. Install dependencies
```bash
pip install ultralytics sumolib traci pandas numpy scipy matplotlib
```

### 2. Run SUMO with GUI
```bash
sumo-gui -c sumo/ilford_junction.sumocfg
```

### 3. Run the adaptive controller
```bash
python traci/run_simulation.py --policy qbpol --scenario peak
```

## Tech Stack
Python 3.10 · Ultralytics YOLOv8 · SUMO 1.18 · CUDA 11.8 · Google Colab (Tesla T4)
