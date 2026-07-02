# NOIS PUC Arbocaster

Dengue forecasting for Brazil at the state level (excluding ES) using statistical and neural time series models, combined through a stacking ensemble. Built for the [3rd Infodengue-Mosqlimate Dengue Challenge (IMDC - 2026)](https://sprint.mosqlimate.org/), with benchmarks based on ETS/ARIMA-family models, neural forecasting with MLP and ESN architectures, and a meta-learner that optimally combines all base models.

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
| `2_forecast_models/` | Python scripts and notebooks with all forecasting models |
| `3_results_classical/` | Outputs from the classical models without climate lags (metrics, forecasts, plots) |
| `4_results_mlp/` | Outputs from the MLP model without climate lags (metrics, forecasts, plots) |
| `5_results_classical_v2/` | Outputs from the classical models with lagged climate features |
| `6_results_mlp_v2/` | Outputs from the MLP model with lagged climate features |
| `7_results_esn/` | Outputs from the ESN model (metrics, forecasts, plots) |
| `8_results_stacking/` | Outputs from the stacking ensemble (metrics, forecasts, best-model heatmap) |
| `x_directions/` | Draft notes and references guiding model construction and analysis decisions |

### Scripts

| Script | Description |
|--------|-------------|
| `1_database_creation.py` | Full ETL pipeline: merges all raw sources, performs feature engineering, and exports the final dataset for forecasting |
| `1_classic_models.py` | Classical time series models: ETS, ARIMA/SARIMA, and SARIMAX validation across all four validation windows |
| `2_mlp_model.py` | MLP (Multilayer Perceptron) in a MISO configuration with Monte Carlo Dropout for predictive intervals |
| `3_esn_model.py` | ESN (Echo State Network) with a Seed Ensemble for predictive intervals |
| `4_stacking_ensemble.py` | Stacking meta-learner combining the classical, MLP, and ESN base forecasts |

## Setup

To run the code, update the `BASE_DIR` path in each script to point to your local data directory:

```python
BASE_DIR = Path("your/local/path/here")
```

## Libraries and Dependencies

> More informations about all dependencies for statistical and neural forecasting components are provided by `environment.yml`.

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

### Lagged Climate Features

A cross-correlation function (CCF) analysis was performed between each climate variable and the target (`casos`) to detect temporal lags between a climate event and the resulting change in cases. For each variable, the lag maximizing the absolute correlation was identified per UF, and the global median lag was applied to build the corresponding lagged columns (e.g., `enso_lag12`). The analysis showed that most climate variables exhibit their strongest correlation at **lag 0**, with the **ENSO index being the main exception**, peaking at approximately **12 weeks**. Lagged features were created by shifting each variable within each UF, and the missing values introduced at the start of each series were handled by forward-fill.

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

**MLP (Multilayer Perceptron)**
A feedforward network in a MISO (Multiple-Input, Single-Output) configuration: multiple input features (lagged cases and exogenous variables) map to a single output (cases in the following week). Hyperparameters — window size, hidden-layer architecture, learning rate, and dropout rate — are selected automatically through an internal grid search on a held-out validation split. The series is stabilized with a log transform (decided by the Breusch–Pagan test) and differencing (decided by the KPSS test), and all features are scaled with a Min–Max scaler fitted on the training set only. Training uses the Adam optimizer with early stopping. Predictive uncertainty is obtained through **Monte Carlo Dropout**: dropout is kept active at inference time, and 500 stochastic forward passes generate a predictive distribution whose quantiles form the 50%, 80%, 90%, and 95% intervals.

**ESN (Echo State Network)**
A reservoir computing model in which the input weights and the recurrent reservoir weights are fixed after random initialization, and only the readout layer is trained via Ridge regression. The reservoir spectral radius is scaled below 1 to preserve the echo state property. Hyperparameters — reservoir size, spectral radius, leaking rate, sparsity, ridge penalty, and input scaling — are selected through a random search over the hyperparameter space, which is far more efficient than a full grid search given the cost of the reservoir eigenvalue computation. The same stabilization (log/differencing) and Min–Max scaling used for the MLP are applied. Predictive uncertainty is obtained through a **Seed Ensemble**: since the ESN is sensitive to reservoir initialization, N instances are trained with distinct random seeds, producing N forecast trajectories whose quantiles form the predictive intervals — the conceptual analogue of Monte Carlo Dropout for reservoir models.

### Stacking Ensemble

The three model families above are combined through **stacking** (stacked generalization), where a second-level meta-learner is trained to optimally combine the base-model forecasts rather than selecting a single best model. The base forecasts used as meta-features come from the out-of-sample validation predictions of each model, ensuring the meta-learner is trained on genuinely out-of-sample data — equivalent to the out-of-fold prediction scheme of a `caretList`/`caretStack` framework.

Because the challenge target is probabilistic, a separate meta-learner is trained **for each quantile** (median and the lower/upper bounds of every interval). Each meta-learner is a Gradient Boosting Regressor with quantile (pinball) loss, optimized directly for the corresponding quantile level, which preserves valid interval widths and avoids the interval collapse that occurs when independent point regressors are used per quantile. For each quantile, a small internal grid search (over tree depth and learning rate) selects the configuration that minimizes the pinball loss. Training uses K-fold out-of-fold cross-validation (5 folds) to prevent meta-model overfitting, and quantile monotonicity is enforced as a final safeguard.

> **Numerical sanitation.** The recursive, long-horizon forecasts of the ESN and SARIMAX can become numerically unstable for specific states — collapsing to a constant or diverging exponentially. Before the ensemble is built, base forecasts are sanitized: non-finite, negative, or above-ceiling values (defined relative to each state's historical peak) are replaced by a seasonal climatology fallback. The number of sanitized entries is reported, and developing numerically stable recursive variants is left as future work.

---

## Model Training

### Classical Models

Each classical model (ETS, ARIMA/SARIMA, SARIMAX) is trained independently per state (UF) following a sequential validation scheme. For each of the four validation windows, the model is fitted exclusively on the corresponding training period and used to generate a forecast covering the gap between training end and the target season, plus the full target horizon.

Model selection for ETS is based on minimum AICc across candidate configurations. For ARIMA/SARIMA, order selection is performed via stepwise search using the AICc criterion. The best ARIMA order is reused as the base structure for SARIMAX.

All classical models are refitted from scratch for each validation window — no transfer of weights or parameters between windows.

### Neural Models

Both neural models are trained independently per state (UF) and per validation window, with no transfer of weights between windows. For each window, the data are stabilized and scaled using parameters fitted on the training period only, and hyperparameters are selected through an internal validation split (the last fraction of the training period). The MLP is then refit on the full training period using the selected configuration, and the ESN readout is trained on the full training period for each seed of the ensemble. Forecasts are generated recursively: the prediction at each step feeds back as input for the next, while future exogenous variables are supplied from the training-period seasonal means (see Data Usage Restriction).

### Stacking Ensemble

The stacking meta-learners are trained on the base-model forecasts across all UFs and validation windows. Before training, a lag-comparison step decides, for each base family that has both versions (classical and MLP), whether the lagged-climate or the non-lagged version performs better, compared via the **median** WIS — robust to the explosive outliers produced by unstable recursive forecasts. The ESN enters as its single (lagged) version. The selected base versions are then sanitized, combined into the meta-feature matrix, and used to fit the per-quantile Gradient Boosting meta-learners with out-of-fold cross-validation.

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

For the stacking ensemble, the meta-learner is trained only on base-model forecasts generated under these same per-window restrictions, so no future information leaks into the combination step.

---

## Predictive Uncertainty

### Classical Models

For **ARIMA/SARIMA** and **SARIMAX**, predictive intervals are derived analytically from the model's estimated error variance, using the standard normal approximation at each confidence level.

For **ETS**, predictive intervals are obtained via simulation: 500 future sample paths are drawn from the fitted model using additive error draws, and the intervals at each horizon are computed as empirical quantiles of these paths.

### Neural Models

For the **MLP**, predictive intervals are produced by **Monte Carlo Dropout**: dropout remains active during inference, and 500 stochastic forward passes yield a sample of trajectories whose empirical quantiles define each interval level.

For the **ESN**, predictive intervals are produced by a **Seed Ensemble**: multiple reservoirs are initialized with distinct random seeds, each generating a forecast trajectory, and the empirical quantiles across trajectories define each interval level.

### Stacking Ensemble

For the **stacking ensemble**, intervals are produced directly by the per-quantile Gradient Boosting meta-learners: each interval bound is the output of a meta-learner trained with quantile (pinball) loss at the corresponding level, with monotonicity enforced across quantiles.

In all cases, four interval levels are produced: **50%, 80%, 90%, and 95%**.

---

## Evaluation

The primary metric for this challenge is the **Weighted Interval Score (WIS)**:

$$\text{WIS} = \frac{1}{K + 0.5} \left[ \frac{1}{2} |y - \hat{m}| + \sum_{k=1}^{K} \frac{\alpha_k}{2} \cdot \text{IS}_{\alpha_k} \right]$$

where $\hat{m}$ is the median forecast, $\alpha_k \in \{0.50, 0.80, 0.90, 0.95\}$ are the interval levels, and $\text{IS}_{\alpha_k}$ penalises both interval width and coverage violations. Lower WIS indicates better performance.

Results are summarised as a **WIS heatmap (model × state)** for each validation window, enabling direct comparison across models and Brazilian states. In addition, a **best-model map (UF × validation window)** identifies which base model achieves the lowest WIS in each cell, and the stacking ensemble is compared against every individual base model to quantify the gain from combination.

---

## References

- Mosqlimate Platform. https://mosqlimate.org/
- 3rd Infodengue-Mosqlimate Dengue Challenge (IMDC 2026). https://sprint.mosqlimate.org/
- InfoDengue. https://info.dengue.mat.br/
- ENSO Index (NASA JPL). https://sealevel.jpl.nasa.gov/overlay-elnino/
- Hyndman, R.J., & Athanasopoulos, G. (2021). *Forecasting: Principles and Practice* (3rd ed.). OTexts. https://otexts.com/fpp3/
- Bracher, J., Ray, E.L., Gneiting, T., & Reich, N.G. (2021). Evaluating epidemic forecasts in an interval format. *PLOS Computational Biology*, 17(2), e1008618.
- Peres, I.T., Hamacher, S., Cyrino Oliveira, F.L., Bozza, F.A., & Salluh, J.I.F. (2022). Data-driven methodology to predict the ICU length of stay: A multicentre study of 99,492 admissions in 109 Brazilian units. *Anaesthesia Critical Care & Pain Medicine*, 41(6), 101142.
- Wolpert, D.H. (1992). Stacked generalization. *Neural Networks*, 5(2), 241–259.
- Breiman, L. (1996). Stacked regressions. *Machine Learning*, 24(1), 49–64.
- Srivastava, N., Hinton, G., Krizhevsky, A., Sutskever, I., & Salakhutdinov, R. (2014). Dropout: A simple way to prevent neural networks from overfitting. *Journal of Machine Learning Research*, 15, 1929–1958.
- Gal, Y., & Ghahramani, Z. (2016). Dropout as a Bayesian approximation: Representing model uncertainty in deep learning. *ICML*, 1050–1059.
- Jaeger, H., & Haas, H. (2004). Harnessing nonlinearity: Predicting chaotic systems and saving energy in wireless communication. *Science*, 304(5667), 78–80.
- Lukoševičius, M., & Jaeger, H. (2009). Reservoir computing approaches to recurrent neural network training. *Computer Science Review*, 3(3), 127–149.
