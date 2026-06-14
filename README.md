# NOIS PUC Arbocaster

Dengue forecasting for Brazil at the state level (excluding ES) using statistical and neural time series models. Built for the [3rd Infodengue-Mosqlimate Dengue Challenge (IMDC - 2026)](https://sprint.mosqlimate.org/), with benchmarks based on ETS/ARIMA-family models and neural forecasting with MLP and ESN architectures.

## Team and Contributors

- Eduardo Lucas de Faria Bentolila (PUC Rio)
- Igor Tona Peres (PUC Rio)
- Fernando Luiz Cyrino Oliveira (PUC Rio)

## Repository Structure

### Folders

| Folder | Description |
|--------|-------------|
| `0_databases/` | Raw datasets provided by the challenge and processed intermediate files |
| `1_descriptive_analysis/` | Database creation pipeline and exploratory/descriptive analyses |
| `2_forecast_models/` | Python scripts with all forecasting models |
| `3_results_classical/` | Outputs from classical statistical models (metrics, forecasts, plots) |
| `x_directions/` | Draft notes and references guiding model construction and analysis decisions |

### Scripts

| Script | Description |
|--------|-------------|
| `1_database_creation.py` | Full ETL pipeline: merges all raw sources, performs feature engineering, and exports the final dataset for forecasting |
| `1_classic_models.py` | Classical time series models: ETS, ARIMA/SARIMA, and SARIMAX validation across all four validation windows |

> Additional scripts for neural network models will be added as development progresses.

## Setup

To run the code, update the `BASE_DIR` path in each script to point to your local data directory:

```python
BASE_DIR = Path("your/local/path/here")
```

## Libraries and Dependencies

> `environment.yml` will be provided once all model scripts are finalized. It will cover all dependencies for statistical and neural forecasting components.

## Data and Variables

### Source Datasets

| File | Description |
|------|-------------|
| `dengue.csv` | Weekly time series of probable dengue cases per municipality geocode, provided by the Mosqlimate team |
| `climate.csv` | Weekly climate variables per geocode: mean temperature, precipitation rate, total precipitation, atmospheric pressure, relative humidity, thermal range, and rainy days |
| `ocean_climate_oscillations.csv` | Weekly ENSO (El Niño–Southern Oscillation) index from [NASA JPL](https://sealevel.jpl.nasa.gov/overlay-elnino/) |
| `environ_vars.csv` | Environmental classification per geocode: Köppen climate type and biome |
| `datasus_population_2001_2025.csv` | Annual population estimates per municipality geocode (DATASUS/IBGE) |
| `shape_muni.gpkg` | Municipal geometries (GeoPackage) used to compute city area in km² |

### Final Dataset Variables

The processed dataset (`forecast_database`) is built by merging all sources above at the municipality–week level, then aggregated to the **state (UF)** level for modeling.

| Variable | Type | Description |
|----------|------|-------------|
| `date` | `YYYY-MM-DD` | Epidemiological week start (Sunday) |
| `year` | `int` | Year extracted from `date` |
| `epiweek` | `int` (`YYYYWW`) | Epidemiological week number |
| `casos` | `int` | Weekly probable dengue cases — **target variable** |
| `uf` | `str` | Federative Unit (state) abbreviation |
| `uf_code` | `int` | Two-digit state code required by the Mosqlimate platform |
| `train_1` | `bool` | Training window for Validation Test 1 (EW01/2010 – EW25/2022) |
| `train_2` | `bool` | Training window for Validation Test 2 (EW01/2010 – EW25/2023) |
| `train_3` | `bool` | Training window for Validation Test 3 (EW01/2010 – EW25/2024) |
| `train_4` | `bool` | Training window for Validation Test 4 (EW01/2010 – EW25/2025) |
| `target_1` | `bool` | Forecast target for season 2022–2023 (EW41/2022 – EW40/2023) |
| `target_2` | `bool` | Forecast target for season 2023–2024 (EW41/2023 – EW40/2024) |
| `target_3` | `bool` | Forecast target for season 2024–2025 (EW41/2024 – EW40/2025) |
| `target_4` | `bool` | Forecast target for season 2025–2026 (EW41/2025 – EW40/2026)* |
| `temp_med` | `float (°C)` | Mean weekly temperature |
| `precip_med` | `float (mm/h)` | Mean precipitation rate |
| `pressure_med` | `float (atm)` | Mean atmospheric pressure |
| `thermal_range` | `float (°C)` | Mean daily temperature range (max − min) |
| `rainy_days` | `int` | Days in the week with total precipitation > 0.03 mm |
| `enso` | `float` | ENSO index (positive = El Niño, negative = La Niña) |
| `Af_koppen` … `Cwb_koppen` | `int (0/1)` | One-hot encoded Köppen climate classification |
| `Amazônia_biome` … `Pantanal_biome` | `int (0/1)` | One-hot encoded biome classification |
| `population` | `int` | Municipal/state population estimate |
| `city_area_km2` | `float` | Municipality area in km² derived from geometry |
| `pop_density_km2` | `float` | Population density (population / area) |
| `macroregion_code` | `int` | Macro-region code (1=Norte, 2=Nordeste, 3=Sudeste, 4=Sul, 5=Centro-Oeste) |
| `macroregion_name` | `str` | Macro-region name |
| `regional_geocode` | `int` | Regional health district code |
| `regional_health_name` | `str` | Regional health district name |
| `regional_health_area_km2` | `float` | Health district area in km² |

> \* `target_4` does not yet include data through EW40/2026, as cases have not been fully reported. Forecasts for the complete period are still required by the challenge and will be evaluated retrospectively.

### Feature Selection

A correlation analysis was conducted on all non-target variables to identify and remove redundant features before modeling. Variables with high mutual correlation (|r| ≥ 0.7) were dropped to reduce dimensionality and improve neural model performance. The variables removed based on this analysis were:

- `pop_density_km2` — highly correlated with `population`
- `BSh_koppen` — high collinearity with other Köppen dummies
- `As_koppen` — high collinearity with other Köppen dummies
- `rel_humid_med` — high collinearity with `temp_med` and `precip_med`

---

## Models

All models produce forecasts at the **state (UF) level** for Brazil (26 states, excluding ES). Each model is evaluated across four validation windows using the **Weighted Interval Score (WIS)** as the primary metric, alongside MAE, RMSE, and MAPE.

Each validation window follows the structure:

| Validation | Training period | Forecast target |
|------------|----------------|-----------------|
| Test 1 | EW01/2010 – EW25/2022 | EW41/2022 – EW40/2023 |
| Test 2 | EW01/2010 – EW25/2023 | EW41/2023 – EW40/2024 |
| Test 3 | EW01/2010 – EW25/2024 | EW41/2024 – EW40/2025 |
| Test 4 | EW01/2010 – EW25/2025 | EW41/2025 – EW40/2026 |

All models output:
- **Median** (point forecast)
- **Predictive intervals** at 50%, 80%, 90%, and 95%

### Classical Models

Three classical time series models are implemented, fitted independently per UF:

**ETS (Error, Trend, Seasonality)**
Exponential smoothing model with automatic selection across additive trend, seasonal, and damped configurations. Uses `initialization_method="heuristic"` for robustness on sparse dengue series with many zero counts.

**ARIMA / SARIMA**
Automatic order selection via `auto_arima` with explicit weekly seasonality (m = 52). Search space: p, q, P, Q ≤ 2 with `max_order = 6`. Fourier terms (K = 4 pairs) are included as exogenous regressors to supplement the seasonal component. Predictive intervals are derived from the model's confidence intervals.

**SARIMAX**
Extension of ARIMA incorporating exogenous climate and environmental variables. Uses the best ARIMA order as its base structure, with the remaining non-redundant covariates from the feature selection step added as regressors alongside Fourier terms.

### Neural Models

> 🚧 **Under construction.** This section will be updated as neural model development progresses.

**MLP (Multilayer Perceptron)**
*(Description to be added)*

**ESN (Echo State Network)**
*(Description to be added)*

---

## Model Training

### Classical Models

Each classical model (ETS, ARIMA/SARIMA, SARIMAX) is trained independently per state (UF) following a sequential validation scheme. For each of the four validation windows, the model is fitted exclusively on the corresponding training period and used to generate a forecast covering the gap between training end and the target season, plus the full target horizon.

Model selection for ETS is based on minimum AICc across candidate configurations. For ARIMA/SARIMA, order selection is performed via stepwise search using the AICc criterion. The best ARIMA order is reused as the base structure for SARIMAX.

All classical models are refitted from scratch for each validation window — no transfer of weights or parameters between windows.

### Neural Models

> 🚧 **Under construction.** This section will be updated as neural model development progresses.

---

## Data Usage Restriction

Each validation window imposes a strict cutoff on the data available for training. No information from beyond the training end date is used to fit any model, including exogenous climate variables. For future time steps where observed climate data is unavailable (i.e., within the forecast gap and target horizon), exogenous variables are estimated using the historical weekly mean computed from the training period only:

$$\hat{x}_{w} = \frac{1}{|\mathcal{T}_w|} \sum_{t \in \mathcal{T}_w} x_t$$

where $\mathcal{T}_w$ is the set of all training weeks sharing epidemiological week number $w$.

The specific input windows per validation test are:

| Validation | Data available for training | Forecast horizon |
|------------|----------------------------|-----------------|
| Test 1 | EW01/2010 – EW25/2022 | EW41/2022 – EW40/2023 (52 weeks) |
| Test 2 | EW01/2010 – EW25/2023 | EW41/2023 – EW40/2024 (52 weeks) |
| Test 3 | EW01/2010 – EW25/2024 | EW41/2024 – EW40/2025 (52 weeks) |
| Test 4 | EW01/2010 – EW25/2025 | EW41/2025 – EW40/2026 (52 weeks) |

Note that there is a gap of approximately 16 weeks between the end of each training period and the start of the forecast target. Predictions are generated for this gap as well, but only the target weeks are used for evaluation.

---

## Predictive Uncertainty

### Classical Models

For **ARIMA/SARIMA** and **SARIMAX**, predictive intervals are derived analytically from the model's estimated error variance, using the standard normal approximation at each confidence level.

For **ETS**, predictive intervals are obtained via simulation: 500 future sample paths are drawn from the fitted model using additive error draws, and the intervals at each horizon are computed as empirical quantiles of these paths.

In all cases, four interval levels are produced: **50%, 80%, 90%, and 95%**.

### Neural Models

> 🚧 **Under construction.** This section will be updated as neural model development progresses.

---

## Evaluation

The primary metric for this challenge is the **Weighted Interval Score (WIS)**:

$$\text{WIS} = \frac{1}{K + 0.5} \left[ \frac{1}{2} |y - \hat{m}| + \sum_{k=1}^{K} \frac{\alpha_k}{2} \cdot \text{IS}_{\alpha_k} \right]$$

where $\hat{m}$ is the median forecast, $\alpha_k \in \{0.50, 0.80, 0.90, 0.95\}$ are the interval levels, and $\text{IS}_{\alpha_k}$ penalises both interval width and coverage violations. Lower WIS indicates better performance.

Results are summarised as a **WIS heatmap (model × state)** for each validation window, enabling direct comparison across models and Brazilian states.

---

## References

- Mosqlimate Platform: https://mosqlimate.org/
- 3rd Infodengue-Mosqlimate Dengue Challenge (IMDC 2026): https://sprint.mosqlimate.org/
- InfoDengue: https://info.dengue.mat.br/
- ENSO Index (NASA JPL): https://sealevel.jpl.nasa.gov/overlay-elnino/
- Hyndman, R.J., & Athanasopoulos, G. (2021). *Forecasting: Principles and Practice* (3rd ed.). OTexts. https://otexts.com/fpp3/
- Smith, M.J., Haas, J., et al. (2023). Evaluating probabilistic forecasts with the weighted interval score. *arXiv preprint*.
