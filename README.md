# AI for Optimizing Traffic Light Control

**NTCC university project: software prototype and simulation**

> ⚠️ **Academic simulation / prototype.** This software does **not** control real traffic infrastructure, does **not**
> access real government traffic systems, does **not** provide legally certified traffic control and does **not**
> guarantee real-world traffic improvements. All traffic, camera, emergency and signal data are simulated or entered
> by the user.

**For the NTCC report:** [docs/FINAL_RESULTS_SUMMARY.md](docs/FINAL_RESULTS_SUMMARY.md) (all findings with 30-seed
confidence intervals, trade-offs, limitations, future work). **For a live demo:** [docs/DEMO_GUIDE.md](docs/DEMO_GUIDE.md)
(5–7 minute script).

## Project description

The prototype simulates four connected urban intersections and compares two ways of controlling their traffic lights:

* **Fixed-time control (baseline):** each direction gets a predefined green time, whatever the traffic.
* **Adaptive / AI-assisted control:** a transparent, configurable priority score that considers:
  * vehicle categories (A/A1 motorcycles, B cars, C trucks, D buses, emergency)
  * queue length
  * average and maximum waiting time, with starvation prevention
  * pedestrian demand, with a maximum pedestrian wait
  * emergency vehicles, with a green corridor
  * downstream congestion and neighbouring intersections
  * incidents
  * road-safety constraints (minimum/maximum green, yellow, all-red, pedestrian clearance)

An **optional reinforcement-learning** controller (tabular Q-learning) and an **optional computer-vision** detector
(pretrained YOLO) are included. The application works fully without either of them.

The dashboard is a responsive web app (PWA). It runs in Chrome/Edge on Windows and in Safari on iPhone.

### Main features

| Area | What you can do |
|---|---|
| Dashboard | Live network map (signals, queues coloured by vehicle class, moving vehicles, crosswalks, congestion, incidents), per-intersection cards, AI reason, next phase, score breakdown, live charts, decision and event logs |
| Simulation controls | Start, pause, single step, reset, speed 1x/2x/5x/10x, scenario, controller, random seed |
| Operator mode | PIN-protected (demo) manual override: extend green, change to a valid phase, return to AI. Every attempt is logged. Also trigger incidents and dispatch emergency vehicles |
| Experiments | Fixed vs adaptive (and optionally RL) on identical traffic: 17 metrics, % improvement, charts, per-approach fairness, run all scenarios, CSV/JSON export |
| Settings | Arrival rates, vehicle mix, pedestrian and emergency frequency, every algorithm weight and threshold, vehicle class weights, safety timings, fixed-time plan |
| Vision | Simulated camera feed in the detection format, JSON detection injection, optional YOLO image/video detection |
| About | Methodology and limitations, written for the university presentation |

## Architecture

```
Browser (Windows / iPhone)  ──HTTP──►  FastAPI backend  ──►  simulation/  (traffic model, signal safety)
React + TypeScript PWA                 live loop, SQLite       ai/          (classification, fairness, pedestrians,
                                       exports, operator                     emergency, coordination, controllers,
                                                                             optional RL + vision)
```

Controllers only **request** phases. A signal state machine enforces min/max green, yellow, all-red and pedestrian
clearance, and an independent safety monitor checks every simulated second for conflicting greens. See
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for details.

## Technologies

* Python 3.12, FastAPI, Uvicorn, PyYAML, SQLite (standard library), pytest
* React 18, TypeScript, Vite, Recharts, React Router
* Optional: Ultralytics YOLO (pretrained COCO model)

## Directory structure

```
NTCC-Traffic-AI/
├── ai/                     decision layer
│   ├── classification.py   vehicle type → A/B/C/D/EMERGENCY + weights
│   ├── state.py            traffic-state calculation
│   ├── fairness.py         waiting time / starvation prevention
│   ├── pedestrian.py       pedestrian priority and WALK time
│   ├── emergency.py        emergency priority + green corridor
│   ├── coordination.py     neighbour / downstream coordination, rerouting
│   ├── evaluation.py       fixed-vs-adaptive experiments
│   ├── controllers/        fixed_time.py, adaptive.py, rl_controller.py
│   ├── rl/                 optional Q-learning (train.py, models/q_table.json)
│   └── vision/             detection interface, simulated camera, optional YOLO
├── backend/                FastAPI app, live simulation manager, SQLite, exports
├── simulation/             network, signal state machine, safety monitor, demand,
│                           scenarios, incidents, metrics, engine
├── config/traffic_config.yaml   all weights, thresholds and safety timings
├── frontend/               React + TypeScript dashboard (PWA)
├── data/                   SQLite database (created at runtime), sample detections
├── docs/                   architecture and benchmark results
├── scripts/                benchmark.py, make_icons.py
├── tests/                  pytest suite (56 tests)
├── setup.cmd / start.cmd / start-dev.cmd
└── IMPLEMENTATION_PLAN.md
```

## Installation (Windows)

Requirements:

* **Python 3.10+.** Install it from python.org and tick "Add python.exe to PATH". The `py` launcher is used below.
* **Node.js 18+** (LTS) from nodejs.org.

Open **PowerShell** in the project folder and run:

```powershell
# 1. Python virtual environment + backend packages
py -3 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt

# 2. Frontend packages + production build
cd frontend
npm install
npm run build
cd ..
```

Or double-click / run **`setup.cmd`**, which does the same.

> The commands call `.\.venv\Scripts\python.exe` directly, so you don't need to activate the virtual environment.
> This avoids PowerShell's script-execution policy.

## Starting the application

### Option A: single server (recommended for demonstrations)

```powershell
.\.venv\Scripts\python.exe -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
```

(or run `start.cmd`), then open **http://localhost:8000**.
The backend serves the built dashboard and the API. Interactive API docs are at http://localhost:8000/docs.

### Option B: development mode (hot reload)

Terminal 1, the backend:

```powershell
.\.venv\Scripts\python.exe -m uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload
```

Terminal 2, the frontend:

```powershell
cd frontend
npm run dev
```

Then open **http://localhost:5173** (Vite forwards `/api` to the backend). `start-dev.cmd` starts both.

## Running a simulation

1. On the **Dashboard**, choose a scenario and a controller, then press **Start**. Use 5x or 10x to speed it up.
2. Click an intersection on the map to see its details and the AI score breakdown.
3. On the **Operator** page:
   * Sign in with the demo PIN **1234** (set in `config/traffic_config.yaml`; demo only).
   * Override a signal, trigger an incident or dispatch an ambulance, police car or fire engine.
4. On the **Experiments** page, choose a scenario and press **Run comparison**, or **Run all scenarios**. Export results as
   CSV or JSON for your report.
5. On **Settings**, change demand and algorithm weights, then rerun experiments.

### Scenarios

Normal traffic · Morning rush hour · Evening rush hour · Heavy truck traffic · Pedestrian heavy · Emergency vehicles ·
Accident / blockage · Unbalanced traffic (fairness).

### Vehicles and routes on the map

* **Tap (iPhone) or click (PC) any vehicle**, waiting in a queue or driving on a road. A panel shows its class, PCU, origin,
  destination, where it is now, its next movement, waits, travel time, stops and reroutes. The map highlights its route:
  grey = already driven, dashed blue with arrows = still ahead, ⚑ = the exit it is heading for.
* **Show vehicle routes** (above the map) draws the remaining routes of up to 20 vehicles faintly.
* Vehicles move smoothly between server updates: they leave the queue, turn through the intersection (curved for
  left/right), drive along the road, join the next queue, and fade out at the map edge when they leave.
* Add `?fps=1` to the address (e.g. `http://localhost:8000/?fps=1`) to show a frame-rate counter.
* Routes exist in OD routing mode (the default). In probabilistic mode vehicles have no planned route.

### Routing mode (how vehicles choose where to go)

Set in `config/traffic_config.yaml` under `routing:` (takes effect when the simulation is reset):

| `routing.mode` | Behaviour |
|---|---|
| `od` (default) | Every vehicle gets an origin, a destination (exit gate such as `I4-E`) and a planned route (Dijkstra on the road graph, no U-turns). Turns follow the route. |
| `probabilistic` | The original model: at every intersection a vehicle goes through/left/right with `simulation.turn_probabilities`. It reproduces the original reference results exactly. |

`routing.rerouting` (OD mode) controls incident route guidance: `all` (default, the same for every controller, so a
comparison isolates the signal controller), `adaptive_only` (ablation, like the original prototype) or `off`.
The default OD matrix is derived from the turn probabilities. A scenario can define its own matrix (`Scenario.od`).

### Networks: Demo Grid and Real Map Prototype

The **Network** selector on the Dashboard (or `network.id` in `config/traffic_config.yaml`) switches between the
**Demo Grid** (2×2, default) and the **Real Map Prototype**: 3 signalised junctions on Chapanata Street, Chilonzor, Tashkent
(`chapanata_3`; a 4-junction alternative `chapanata` adds an assumed-signal crossing under the Bunyodkor bridge), built offline
from OpenStreetMap (© OpenStreetMap contributors, ODbL). **Its demand is synthetic**, and signal timings, phasing and one signal
location are assumed; the dashboard panel under the map lists every assumption. The app reads only
`data/networks/*.json` and works offline. Details: [docs/REAL_MAP.md](docs/REAL_MAP.md).

### Traffic input from files

Instead of random arrivals, the simulator can replay counts per approach, vehicle class and 15-minute (or any) interval from
a CSV or JSON file: set `traffic_input.provider: csv` and `traffic_input.file: data/traffic_inputs/example_demo_grid.csv`.
The example files contain example values, not measured traffic. Format: [docs/TRAFFIC_INPUT_FORMAT.md](docs/TRAFFIC_INPUT_FORMAT.md).

### Optional simulators and vision (not required)

* **SUMO** is not needed and not installed. A provider interface and a design document exist
  ([docs/SUMO_INTEGRATION.md](docs/SUMO_INTEGRATION.md)). `simulation.provider: sumo` falls back to the built-in engine.
* **YOLO** stays optional. Standard YOLO does not detect emergency vehicles ([docs/VISION.md](docs/VISION.md)).

### Link travel time

`travel_time.model` in `config/traffic_config.yaml`: `constant` (default, every link 18 s, as before) or `bpr` (per-class
free-flow speed plus a BPR congestion term; illustrative parameters, not calibrated). Routing and route guidance use the same
link times. Results: [docs/results_travel_time.md](docs/results_travel_time.md).

### Command-line benchmark

```powershell
# current default (OD routing)
.\.venv\Scripts\python.exe scripts\benchmark.py --duration 1800 --seed 42
# original reference model
.\.venv\Scripts\python.exe scripts\benchmark.py --duration 1800 --seed 42 --routing probabilistic
# ablation: rerouting only for the adaptive controller, save the summaries to JSON
.\.venv\Scripts\python.exe scripts\benchmark.py --routing od --rerouting adaptive_only --json results.json
```

Reference results:
* original probabilistic model: [docs/baseline_results.md](docs/baseline_results.md) (same numbers as [docs/RESULTS.md](docs/RESULTS.md))
* OD routing: [docs/baseline_results_od.md](docs/baseline_results_od.md), compared in [docs/results_phase1.md](docs/results_phase1.md)

These are single-seed simulation results. In the *Accident* scenario most of the original adaptive advantage came from
rerouting being available only to the adaptive controller (see `docs/results_phase1.md`).

### Multi-seed batch experiments (recommended for results)

A single seed is never proof. On the **Experiments** page, use *Multi-seed batch experiments*: choose scenarios, controllers,
10/20/30 or a custom number of seeds and a duration, then press **Run batch**. It runs in the background (you can leave the
page). You get the mean with a 95 % confidence interval, the paired difference per seed and on how many seeds each controller
was better, as charts and a table, with CSV/JSON export.

Command line (no UI needed):

```powershell
.\.venv\Scripts\python.exe -m scripts.run_batch --scenario all --seeds 30 --workers 4 --out results\my_batch
.\.venv\Scripts\python.exe -m scripts.run_batch --scenario accident,unbalanced --seeds 10 --routing probabilistic
```

The 30-seed reference results are in [docs/results_multiseed.md](docs/results_multiseed.md).

## Running the tests

```powershell
.\.venv\Scripts\python.exe -m pytest
```

The suite covers, among other things:

* conflicting lights never green (all scenarios, both controllers)
* yellow/all-red sequence and minimum green
* a waiting road is eventually served, and the maximum waiting threshold forces service
* the "40 vehicles × 2 min vs 9 vehicles × 8 min" example
* pedestrians are never ignored, and no crossing phase runs when nobody waits
* emergency priority and the green corridor, and the return from emergency mode
* downstream congestion changes upstream decisions, and spillback
* incidents reduce capacity, expire or are cleared, and drivers are rerouted
* manual override is safe, rejects invalid phases, respects limits and is logged
* API endpoints and exports, and RL safety

Frontend type check: `cd frontend; npm run typecheck`.

## Using the app on an iPhone (same Wi-Fi network)

1. Start the backend with `--host 0.0.0.0` (Option A above; `start.cmd` already does this).
2. Find your PC's local IP address:
   ```powershell
   ipconfig
   ```
   Look for **IPv4 Address** under your Wi-Fi adapter, for example `192.168.1.25`.
3. On the iPhone, open Safari and go to **http://192.168.1.25:8000** (your own IP).
4. If the page does not load, Windows Firewall is probably blocking the port. The first time Python listens on a port,
   Windows usually asks whether to allow it. Choose **Private networks**. Otherwise, allow port 8000 manually in an
   administrator PowerShell (this changes a system setting, so do it yourself only if you are comfortable):
   ```powershell
   New-NetFirewallRule -DisplayName "NTCC Traffic AI 8000" -Direction Inbound -Protocol TCP -LocalPort 8000 -Action Allow -Profile Private
   ```
   Your Wi-Fi must be set to a **Private** network in Windows.
5. Optional: in Safari tap **Share → Add to Home Screen** to install it like an app.
   (Offline caching via the service worker needs HTTPS, so over plain local HTTP the app simply loads from the PC.)

In development mode use port 5173 instead of 8000.

## Optional extras

### Reinforcement learning (Q-learning)

```powershell
.\.venv\Scripts\python.exe -m ai.rl.train --episodes 60 --duration 900     # about 1 minute
.\.venv\Scripts\python.exe scripts\benchmark.py --rl
```

* **State:** phase, green-time bucket, NS/EW weighted queue buckets, pedestrians, red-side wait.
* **Action:** hold or switch.
* **Reward:** minus weighted queue and pedestrians, a penalty above the wait threshold, and a bonus per vehicle served.

The agent runs inside the same safety and fairness shield. After training, restart the backend, and "RL" appears in
the controller list and on the Experiments page. A trained table is included in `ai/rl/models/q_table.json`.

**RL model trained in OD mode (Phase 3c).** `ai/rl/models/q_table_od.json` was trained with a fixed protocol (5 runs,
separate training/validation/test seeds). With the default `rl.model: auto` it is used in OD routing mode, and
the original `q_table.json` in probabilistic mode. Set `rl.model` to a file name to override. Results: [docs/results_rl_od.md](docs/results_rl_od.md). In short, the RL
controller does not beat the transparent adaptive controller in any scenario.

### Computer vision (YOLO)

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements-optional.txt
```

This is a large download (PyTorch). Restart the backend, then upload an image or a short video on the **Vision** page. The
pretrained COCO model counts motorcycles, cars, trucks, buses and people. It **cannot** recognise ambulance, police or
fire vehicles. Without YOLO, the Vision page still shows the simulated camera feed and accepts detection JSON
(`data/sample_detections.json`) through `POST /api/detections`.

## Data logging and export

Everything is stored in `data/traffic.db` (SQLite):

* runs: scenario, controller, seed, timestamp, configuration, summary, time series
* metric snapshots per approach every 10 s
* every signal decision with its reason
* incidents, emergency events and alerts
* manual overrides, including rejected attempts

Exports:

* Experiments page buttons
* `GET /api/experiments/{id}/export?format=csv|json`
* `GET /api/runs/{id}/export?format=csv&table=summary|per_approach|timeseries|snapshots|decisions|events|overrides`
* `GET /api/runs/{id}/export?format=json`

To start with an empty history, stop the server and delete `data/traffic.db`.

## Limitations

The full list is in [docs/LIMITATIONS.md](docs/LIMITATIONS.md). In short:

* Queue-based simulation. There is no lane-changing, car-following or detailed turning-conflict geometry. Left turns are
  permissive within the two vehicle phases, and pedestrians use an exclusive all-red crossing phase.
* Demand is random but stationary within a scenario and not calibrated with real counts. Parameters are illustrative.
* Neighbour coordination reads shared simulation state. A real system would need communication, latency and fault handling.
* Safety rules are generic examples of how legal constraints (e.g. Uzbekistan traffic regulations) could be encoded.
  They are **not legally certified**.
* Operator authentication is a demo PIN, not production security.
* The optional YOLO model does not detect emergency vehicles. Weather, night and occlusion are not modelled.
* The optional RL agent is small and experimental. It does not beat the transparent adaptive controller.

## Future improvements

* Calibrate with real traffic counts and time-of-day demand profiles. Integrate SUMO for microscopic validation.
* Protected left-turn phases and concurrent pedestrian phases. Larger and irregular networks.
* A dedicated emergency-vehicle detector (siren/light-bar model) or V2X priority requests.
* Deep RL (DQN/PPO) with multi-agent coordination, trained on many seeds and validated against the shield.
* Real operator authentication, audit trail signing and role-based access.
* WebSocket streaming instead of polling. Offline-capable HTTPS deployment.
