# 🌍 Economic Impact on Neurological Disorders: ADHD vs. Autism

This repository contains a comprehensive data science project analyzing the relationship between a country's economic power (GDP per capita) and the diagnosed prevalence of neurological disorders, specifically ADHD and Autism Spectrum Disorders. 

**Authors:** Silan Cihaner 

**Date:** February 2026  

## 📊 Project Overview
The core objective of this analysis is to investigate whether higher national income leads to increased diagnosis rates for different neurological conditions. 

Key findings from our statistical modeling (AIC comparisons) and geospatial analysis indicate a significant "Visibility Gap":
* **ADHD** shows a global, somewhat economically independent trend, with a massive diagnostic boom in the Americas.
* **Autism** prevalence is heavily correlated with economic capacity, showing a distinct upward trend as GDP increases, likely due to the higher resources required for diagnosis.

## 🛠️ Tools & Technologies Used
* **Language:** R
* **Data Manipulation:** `tidyverse` (dplyr, tidyr)
* **Visualization:** `ggplot2`, `viridis` (for accessible color palettes)
* **Geospatial Mapping:** `leaflet` (Interactive maps), `sf`, `rnaturalearth`
* **Statistical Modeling:** Linear Regression, Log-Linear, Polynomial (Quadratic), and Complex Interaction Models.

## 📂 Repository Structure
* `/Data`: Contains the raw datasets (Note: If data is publicly sourced, state the source here).
* `Assignment_Report.Rmd`: The core R Markdown script containing all code, analysis, and logical flow.
* `index.html`: The compiled HTML report.

## 🚀 How to View the Project
You can read the full interactive report directly via GitHub Pages here:  
👉 **[Buraya GitHub Pages Linkini Koyacaksın - Örn: https://silan.github.io/gdp-neurological-analysis]**

*(If running locally, simply clone this repository and open `Assignment_Report.Rmd` in RStudio, ensure all packages are installed, and hit "Knit".)*

## 📚 Data Sources
* [World Bank Open Data](https://data.worldbank.org/) (GDP & Demographics)
* [Global Health Data Exchange (GHDx)](http://ghdx.healthdata.org/) (Disease Prevalence Rates)
