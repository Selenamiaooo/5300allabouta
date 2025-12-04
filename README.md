# 🚇 NYC Subway Ridership SPC Dashboard  
### _Statistical Process Control (SPC) Analysis of Congestion Pricing Impacts Across NYC Boroughs_

![Header](docs/banner.png) <!-- optional: delete if no image -->

---

## 📌 Overview

This repository contains the full Shiny dashboard developed for analyzing **NYC subway ridership changes** surrounding the introduction of **Congestion Pricing**.  
Using **Statistical Process Control (SPC)** methods (X-charts and Moving-Range charts), we evaluate how monthly ridership in **Manhattan, Brooklyn, Queens, and the Bronx** deviates from historical patterns.

The dashboard provides:
- 🗺️ **Interactive station-level map**  
- 📈 **Borough-level SPC control charts (plotly interactive X chart + MR chart)**  
- 📋 **Station classifications: Core / Secondary / Stable**  
- 🧮 **Loss estimation** related to ridership deviations  
- 📄 **Documentation of methodology and project background**

---

## 📂 Repository Structure

NYC-Subway-SPC/
│
├── shinyapp.R # Main Shiny dashboard code
│
├── sixsigma_pre/ # Input data for SPC + mapping
│ ├── stationsmap.csv # Station attributes + loss data + type classification
│ ├── all_region.csv # Borough-level SPC metrics (ridership, MR, UCL, LCL)
│ └── control_tests.png # SPC 8-rule reference figure
│
├── docs/ # Optional: documentation, images, report
│ ├── report.pdf # Project report (if included)
│ └── presentation.pptx # Final slides (if included)
│
└── README.md # Project summary (this file)
