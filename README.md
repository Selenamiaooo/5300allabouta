哈哈那我懂了 😎
我给你重新做一个**专业 + 漂亮 + 带 emoji 的 GitHub README**，风格更现代、视觉更强，你们交作业、展示项目的时候会更亮眼。

下面这份 **可以直接复制当 README.md 内容**，完全不会乱码。

---

# 🚇 NYC Subway Ridership SPC Dashboard

### 📊 *Statistical Process Control Analysis of Subway Ridership under NYC Congestion Pricing*

---

## ✨ Overview

This repository contains an interactive **R Shiny dashboard** analyzing how **NYC subway ridership** changed around the implementation of **Congestion Pricing**.

Using **SPC (Statistical Process Control)** techniques, including **X-charts** and **Moving Range charts**, we detect whether ridership in **Manhattan, Brooklyn, Queens, and the Bronx** shows significant deviations from historical patterns.

The dashboard includes:

* 🗺️ **Interactive subway station map**
* 📈 **Borough-level SPC charts (hover-enabled Plotly)**
* 🚦 **Station classification: Core / Secondary / Stable**
* 💸 **Ridership loss and financial impact estimations**
* 📚 **Documentation of assumptions and SPC methodology**

---

## 📁 Repository Structure

```
NYC-Subway-SPC/
│
├── shinyapp.R                     # Main Shiny dashboard
│
├── sixsigma_pre/                  # Input data for SPC + station map
│   ├── stationsmap.csv            # Station-level classification + loss values
│   ├── all region.csv             # Borough-level SPC metrics
│   └── control_tests.png          # Reference for 8 SPC rules
│
├── docs/                          # (Optional) Project report, slides, images
│   ├── report.pdf
│   └── presentation.pptx
│
└── README.md                      # Project summary
```

---

## 🚀 How to Run the App Locally

### **1️⃣ Clone the repository**

```bash
git clone https://github.com/YOUR_GROUP_NAME/YOUR_REPO.git
```

### **2️⃣ Install required R packages**

```r
install.packages(c(
  "shiny", "leaflet", "dplyr", "readr",
  "scales", "ggplot2", "plotly"
))
```

### **3️⃣ Run the dashboard**

```r
shiny::runApp("shinyapp.R")
```

---

## 🌐 Dashboard Features

### 🗺️ **1. Station Map (Interactive)**

* Visualizes all NYC subway stations in the selected borough
* Stations are categorized as:

  * 🔴 **Core** (violates both 2σ and 3σ rules)
  * 🟠 **Secondary** (violates 2σ only)
  * ⚪ **Stable** (no violations)
* Hover tooltips show:

  * Station complex
  * Borough
  * Station type
  * Loss estimate

---

### 📈 **2. Borough-Level SPC Charts**

#### **X-Chart – Total Monthly Ridership**

* Interactive hover tooltips
* Flags values:

  * 🔺 Above UCL (Upper Control Limit)
  * 🔻 Below LCL (Lower Control Limit)
  * ⚪ Within limits
* Shows trends and sudden shifts in ridership

#### **MR-Chart – Month-to-Month Variation**

* Detects sudden changes in ridership
* Plots MR against UCL(MR) and mean MR
* Hover tooltips provide MR values per month

---

### 🧾 **3. Station List Viewer**

Filter stations by:

* 🔴 Core
* 🟠 Secondary
* ⚪ Stable

Useful for identifying priority stations and summarizing borough-level behavior.

---

## 📊 Methodology Summary

### 🧮 SPC Components

* **X-chart**:

  * Tracks month-to-month ridership patterns
  * UCL and LCL computed using:

    * Mean ridership
    * Moving Range estimate of process variability

* **MR-chart**:

  * Moving Range defined as
    [
    MR_t = |X_t - X_{t-1}|
    ]

### 🚦 Station Classification Rules

| Type             | Criteria                                  |
| ---------------- | ----------------------------------------- |
| 🔴 **Core**      | Out-of-control under both 2σ and 3σ rules |
| 🟠 **Secondary** | Violates only 2σ rules                    |
| ⚪ **Stable**     | No SPC rule violations                    |

### 💸 Loss Estimation

* Based on deviation from expected ridership within control limits
* Converted to estimated revenue loss using standard fare assumptions

---

## 👩‍💻 Authors

* **Luyao Chang – Cornell Systems Engineering '25**
* **Yueqing Miao – Cornell Systems Engineering '26**
* **Kegan Lin – Cornell Systems Engineering '26**
* **Jack Zhou – Cornell Systems Engineering '26**
* **Laura Liu – Cornell Systems Engineering '25**

---

## 📜 License

This repository is provided for academic and instructional purposes under Cornell University coursework.

---

## 🙌 Acknowledgements

Thanks to:

* NYC MTA for open data
* Cornell Professor Tim!!
* Teammates and reviewers

