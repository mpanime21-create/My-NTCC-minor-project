# Implementation Plan — AI for Optimizing Traffic Light Control

> Academic simulation / prototype only. It does not connect to or control real traffic infrastructure.

## 1. Environment found

- Windows 11, PowerShell 5.1
- Python 3.12 via the `py` launcher (the `python` command is only the Microsoft Store stub)
- Node.js 24 / npm 11
- Empty project directory

## 2. Architecture

```
 ┌──────────────────────────── Browser (Windows Chrome/Edge, iPhone Safari) ───────────────────────────┐
 │  React + TypeScript (Vite) PWA: Dashboard · Operator · Experiments · Settings · Vision · About       │
 └───────────────▲─────────────────────────────── HTTP/JSON (polling) ─────────────────────────────────┘
                 │
 ┌───────────────┴─────────── backend/ (FastAPI) ───────────────────────────────────────────────────────┐
 │ live simulation manager (asyncio loop, speed 1x–10x) · REST API · operator auth (demo PIN) · SQLite  │
 └───────────────▲──────────────────────────────────────────────────────────────▲──────────────────────┘
                 │ controller interface (decide)                                  │ results / logs
 ┌───────────────┴─────── ai/ ───────────────────────┐      ┌──────────── simulation/ ────────────────┐
 │ classification · state · fairness · pedestrian    │◄────►│ network · signals (state machine)       │
 │ emergency · coordination                          │      │ safety monitor · demand · scenarios     │
 │ controllers: fixed-time, adaptive, (optional RL)  │      │ incidents · metrics · engine            │
 │ vision (optional YOLO / simulated camera)         │      └─────────────────────────────────────────┘
 └───────────────────────────────────────────────────┘
```

Key design rule: **controllers only *request* phases**. The signal state machine in
`simulation/signals.py` enforces min-green, yellow, all-red and pedestrian clearance, and
`simulation/safety.py` checks every second that no conflicting movements are
released at the same time. Fixed-time, adaptive, RL and manual operator commands all go
through the same safety layer.

## 3. Technology choices

| Layer | Choice | Reason |
|---|---|---|
| Simulation / AI | Pure Python 3.12 (stdlib + PyYAML) | Transparent, testable, and needs no GPU |
| Backend | FastAPI + Uvicorn | Simple async API, automatic docs at `/docs` |
| Database | SQLite (`sqlite3` stdlib) | No server needed, single file |
| Frontend | React 18 + TypeScript + Vite, Recharts | Fast dev server, responsive, charts |
| PWA | Web manifest + service worker | Can be added to the iPhone home screen |
| Tests | pytest | Core-logic and API tests |
| Optional CV | Ultralytics YOLO (not installed by default) | Pretrained model, no training |
| Optional RL | Tabular Q-learning (pure Python) | Lightweight; app never depends on it |

## 4. Simulation model (summary)

- A 2×2 grid of 4 connected intersections (I1–I4), each with N/E/S/W approaches.
  Internal approaches are fed by neighbouring intersections; external approaches by demand generators.
- Point queues at stop lines; discharge at a saturation headway in PCU (passenger-car units).
  Discharge is blocked if the downstream link storage is full (spillback).
- Phases: `NS` (north+south green), `EW` (east+west green), `PED` (exclusive all-pedestrian
  crossing with all vehicles red). Transitions: green → yellow → all-red → next phase.
- Vehicle classes A/A1 (motorcycles), B (cars/light vans), C (trucks), D (buses), EMERGENCY
  (ambulance/police/fire), each with configurable weight and PCU.
- Separate random streams for arrivals, pedestrians and emergencies, so fixed-time and adaptive runs
  see exactly the same traffic for a given seed.

## 5. Modules

| # | Concern | Location |
|---|---|---|
| 1 | Traffic simulation | `simulation/engine.py`, `network.py`, `demand.py`, `scenarios.py` |
| 2 | Vehicle classification | `ai/classification.py` |
| 3 | Traffic-state calculation | `ai/state.py` |
| 4 | Signal-control algorithms | `ai/controllers/` (fixed, adaptive, RL) |
| 5 | Emergency priority | `ai/emergency.py` |
| 6 | Waiting time / fairness | `ai/fairness.py`, `ai/pedestrian.py` |
| 7 | Neighbour coordination | `ai/coordination.py` |
| 8 | API / backend | `backend/` |
| 9 | Dashboard | `frontend/` |
| – | Safety rules | `simulation/signals.py`, `simulation/safety.py` |
| – | Configuration | `config/traffic_config.yaml` |

## 6. Development phases

1. **Minimal working version.** 4-intersection engine, vehicle classes, queues, waiting times, fixed and adaptive controllers, FastAPI live loop, basic dashboard with controls.
2. **Run and fix.** pytest suite, smoke run, API checks.
3. **Realism features.** Pedestrians, emergency green corridor, incidents, neighbour coordination and metering.
4. **Analysis features.** Experiment comparison, charts, SQLite logging, CSV/JSON export, operator manual override.
5. **Optional extras.** Simulated camera feed, detection-injection API, optional YOLO image detection, optional Q-learning controller.
6. **Documentation.** README (Windows setup, iPhone access), methodology page, limitations.
