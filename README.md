# 🌍 Economic Impact on Neurological Disorders: ADHD vs. Autism

A comprehensive data science project utilizing advanced statistical modeling and geospatial visualization in R to evaluate the relationship between a country's economic power (GDP per capita) and the diagnosed prevalence of neurological disorders.

## Project Overview
The core objective of this analysis is to investigate whether higher national income leads to increased diagnosis rates for different neurological conditions. 

### Key Findings
* **The Wealth-Diagnosis Correlation:** Autism prevalence is heavily correlated with economic capacity. The data shows a distinct upward trend as GDP increases, strongly suggesting that richer nations have the resources (screening tools, specialists) required for widespread diagnosis.
* **The ADHD Anomaly:** Unlike Autism, ADHD shows a global, somewhat economically independent trend, but with a massive, localized diagnostic boom in the Americas.
* **Model Superiority:** Through rigorous Akaike Information Criterion (AIC) testing, the *Interaction Model* (combining GDP, Disease Type, and their interaction) drastically outperformed standard Linear and Quadratic models, proving that the economic impact behaves fundamentally differently depending on the specific disorder.

## Methodology & Statistical Approach
Unlike simple correlation checks, this project utilized a structured econometric approach to validate findings:
* **Data Merging:** Executed robust `left_join` operations aligning ISO3 country codes between World Bank and vector map datasets.
* **Statistical Modeling:** Evaluated multiple functional forms:
  * *Base Linear Model*
  * *Log-Linear Model* (to account for exponential GDP scaling)
  * *Quadratic Model*
  * *Interaction Model* (Selected via AIC as the optimal fit)
* **Reproducibility:** The entire analysis is fully reproducible via the provided R Markdown script.

---

## Technologies Used
* **Language:** `R`
* **Framework:** `R Markdown` (for fully reproducible research and automated HTML reporting)
* **Key Packages:** * `tidyverse` & `dplyr` (for data wrangling)
  * `ggplot2` & `viridis` (for accessible, color-blind friendly data visualization)
  * `leaflet`, `sf`, `rnaturalearth` (for interactive geospatial mapping)

---

## Repository Structure
```text
├── Data/                 # Raw datasets (World Bank GDP & GHDx Prevalence)
├── Output/               # Final generated high-resolution plots (.png)
├── Assignment_Report.Rmd # The core R Markdown script containing all code and logic
├── index.html            # The compiled, interactive HTML report
├── .gitignore            # Excludes R history, cache, and OS hidden files
└── README.md             # Project documentation
```
## Data Sources
* [World Bank Open Data](https://data.worldbank.org/) (GDP & Demographics)
* [Global Health Data Exchange (GHDx)](http://ghdx.healthdata.org/) (Disease Prevalence Rates)

---

## 🌐 Live Interactive Report
You can read the full interactive report, complete with hoverable scatter plots and navigable maps, directly via GitHub Pages:  
**https://cihanerrsilan.github.io/economic-impact-on-neurological-disorders/**

---

## 🎓 Academic Context
This empirical project was conducted as part of the **Master of Science in Data Science** program at the **Lucerne University of Applied Sciences and Arts (HSLU)**, specifically for the *R Bootcamp* module.

* **Authors:** Şilan Cihaner
* **Date:** February 2026
