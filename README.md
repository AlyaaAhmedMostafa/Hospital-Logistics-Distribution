# 🏥 Hospital Logistics & Distribution — Supply Chain Analytics Report

> **Period Covered:** January 2020 – December 2023
> **Analysis Engine:** Microsoft SQL Server (T-SQL) · Python (pandas/numpy) for validation
> **Records Analyzed:** 27,000 transfer transactions · 25 fields

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Dataset Overview](#2-dataset-overview)
3. [SQL Analysis Architecture](#3-sql-analysis-architecture)
4. [Key Performance Indicators](#4-key-performance-indicators)
5. [SLA Compliance Analysis](#5-sla-compliance-analysis)
6. [Quality & Rejection Analysis](#6-quality--rejection-analysis)
7. [Cold Chain & Temperature Excursion Analysis](#7-cold-chain--temperature-excursion-analysis)
8. [Cost & Financial Exposure Analysis](#8-cost--financial-exposure-analysis)
9. [Carrier Performance Benchmarking](#9-carrier-performance-benchmarking)
10. [Transport Mode Efficiency](#10-transport-mode-efficiency)
11. [Origin & Destination Risk Profiling](#11-origin--destination-risk-profiling)
12. [Year-over-Year Trend Analysis](#12-year-over-year-trend-analysis)
13. [Documentation & Compliance Gap](#13-documentation--compliance-gap)
14. [Strategic Recommendations](#14-strategic-recommendations)
15. [SQL Queries Reference](#15-sql-queries-reference)

---

## 1. Executive Summary

This report presents a full supply chain performance analysis of a hospital logistics and distribution network covering **27,000 internal and external item transfers** executed between January 2020 and December 2023. The analysis was conducted using **Microsoft SQL Server T-SQL** and covers SLA compliance, cold chain integrity, item rejection, cost exposure, carrier benchmarking, and documentation compliance.

### 🔴 Critical Findings at a Glance

| Risk Signal | Value | Status |
|---|---|---|
| Overall SLA Breach Rate | **52.7%** | 🔴 Critical |
| Emergency-Priority SLA Compliance | **48.8%** | 🔴 Critical |
| STAT-Priority SLA Compliance | **46.7%** | 🔴 Critical |
| Total Rejection Cost Exposure | **$36.0M (10.2% of supply chain cost)** | 🔴 Critical |
| Temperature Excursion Rate | **5.5%** | 🟡 Elevated |
| Quantity Mismatch Rate | **8.2%** | 🟡 Elevated |
| Documentation Incomplete Rate | **6.9%** | 🟡 Elevated |

> **Bottom Line:** More than half of all transfers breach their SLA targets — including life-critical Emergency and STAT shipments — while a $36 million rejection cost burden signals systemic gaps in cold chain management, carrier accountability, and inventory handling controls.

---

## 2. Dataset Overview

### Schema

```sql
-- Table: Logistics_Distribution
-- Primary Key: Transfer_ID (VARCHAR)
-- 27,000 rows | 25 columns | Date range: 2020-01-01 to 2023-12-31
```

| Field Group | Columns |
|---|---|
| **Identifiers** | Transfer_ID, Transfer_Date, Staff_ID |
| **Routing** | Origin (10 nodes), Destination (15 nodes) |
| **Item** | Item_Category (12 types), Qty_Shipped, Qty_Received |
| **Logistics** | Transport_Mode (6), Storage_Zone (5), Carrier (6) |
| **Time/SLA** | Priority_Level, SLA_Hours, Transit_Hours, SLA_Breach |
| **Temperature** | Temp_Required, Temp_Recorded_C, Temp_Excursion_Flag |
| **Quality** | Qty_Mismatch_Flag, Rejected_Flag, Rejection_Reason, Redelivery_Required |
| **Admin** | Unit_Cost_USD, Handling_Cost_USD, Documentation_Complete |

### Transfer Volume Distribution

| Priority Level | Transfers | Share |
|---|---|---|
| Routine | 14,780 | 54.7% |
| Urgent | 6,717 | 24.9% |
| STAT | 3,579 | 13.3% |
| Emergency | 1,924 | 7.1% |
| **Total** | **27,000** | **100%** |

---

## 3. SQL Analysis Architecture

All queries were executed against a single-table dataset loaded into Microsoft SQL Server. The analytical framework used the following SQL techniques:

```sql
-- Core analytical pattern used throughout this analysis

-- 1. KPI Aggregation
SELECT
    Priority_Level,
    COUNT(*) AS Total_Transfers,
    SUM(SLA_Breach) AS SLA_Breaches,
    CAST(AVG(CAST(SLA_Breach AS FLOAT)) * 100 AS DECIMAL(5,2)) AS SLA_Breach_Rate_Pct,
    SUM(Rejected_Flag) AS Total_Rejections,
    CAST(AVG(CAST(Rejected_Flag AS FLOAT)) * 100 AS DECIMAL(5,2)) AS Rejection_Rate_Pct
FROM Logistics_Distribution
GROUP BY Priority_Level
ORDER BY SLA_Breach_Rate_Pct DESC;

-- 2. Financial Exposure
SELECT
    Item_Category,
    SUM(Unit_Cost_USD * Qty_Shipped + Handling_Cost_USD) AS Total_Supply_Chain_Cost,
    SUM(CASE WHEN Rejected_Flag = 1
             THEN Unit_Cost_USD * Qty_Shipped + Handling_Cost_USD ELSE 0 END) AS Rejection_Cost_Loss
FROM Logistics_Distribution
GROUP BY Item_Category
ORDER BY Rejection_Cost_Loss DESC;

-- 3. Carrier Benchmarking using Window Functions
SELECT
    Carrier,
    AVG(CAST(SLA_Breach AS FLOAT)) AS Breach_Rate,
    AVG(Handling_Cost_USD) AS Avg_Handling_Cost,
    AVG(CAST(Rejected_Flag AS FLOAT)) AS Rejection_Rate,
    RANK() OVER (ORDER BY AVG(CAST(SLA_Breach AS FLOAT)) ASC) AS Carrier_SLA_Rank
FROM Logistics_Distribution
GROUP BY Carrier;
```

---

## 4. Key Performance Indicators

### Supply Chain Volume & Financial Scale

| KPI | Value |
|---|---|
| Total Transfers Processed | 27,000 |
| Total Units Shipped | 2,700,323 |
| Total Gross Item Value | $353,992,633 |
| Total Handling Cost | $525,827 |
| **Total Supply Chain Cost** | **$354,518,461** |
| Annual Average Supply Chain Cost | ~$88.6M |

### Operational Performance

| KPI | Value | Benchmark Target |
|---|---|---|
| SLA On-Time Rate | **47.3%** | ≥ 95% |
| Rejection Rate | **9.4%** | < 2% |
| Temperature Excursion Rate | **5.5%** | < 1% |
| Quantity Mismatch Rate | **8.2%** | < 1% |
| Redelivery Rate | **9.4%** | < 2% |
| Documentation Completeness | **93.1%** | 100% |
| Average Transit Time | **4.34 hours** | — |
| Median Transit Time | **2.36 hours** | — |

---

## 5. SLA Compliance Analysis

### SLA Breach by Priority Level

```sql
SELECT Priority_Level,
       COUNT(*) AS Total,
       SUM(SLA_Breach) AS Breaches,
       ROUND(AVG(CAST(SLA_Breach AS FLOAT)) * 100, 1) AS Breach_Rate_Pct
FROM Logistics_Distribution
GROUP BY Priority_Level
ORDER BY Breach_Rate_Pct DESC;
```

| Priority Level | Total Transfers | SLA Breaches | Breach Rate |
|---|---|---|---|
| STAT (0.5 hr SLA) | 3,579 | 1,909 | **53.3%** 🔴 |
| Urgent (2 hr SLA) | 6,717 | 3,563 | **53.0%** 🔴 |
| Emergency (0.25 hr SLA) | 1,924 | 985 | **51.2%** 🔴 |
| Routine (4 hr SLA) | 14,780 | 7,763 | **52.5%** 🔴 |

**Key Insight:** SLA breach rates are alarmingly consistent across all priority tiers — including Emergency shipments with a 15-minute SLA window. This is not a triage or routing problem; it indicates a **systemic process failure** in transit time management.

### SLA Breach by Destination

| Destination | Breach Rate | Concern Level |
|---|---|---|
| Orthopedics | 53.8% | 🔴 |
| Pediatrics | 53.7% | 🔴 |
| Oncology Ward | 53.6% | 🔴 |
| Neurology | 53.5% | 🔴 |
| General Ward A | 53.2% | 🔴 |
| ICU | 53.0% | 🔴 |
| ER | 52.6% | 🔴 |
| General Ward B | 50.6% | 🟡 |

> All clinical destinations show breach rates exceeding 50%, with specialized high-acuity units (Orthopedics, Pediatrics, Oncology) performing worst.

---

## 6. Quality & Rejection Analysis

### Rejection Volume & Cost

```sql
SELECT
    Rejection_Reason,
    COUNT(*) AS Incidents,
    SUM(Unit_Cost_USD * Qty_Shipped + Handling_Cost_USD) AS Financial_Impact_USD
FROM Logistics_Distribution
WHERE Rejected_Flag = 1
GROUP BY Rejection_Reason
ORDER BY Incidents DESC;
```

| Rejection Reason | Incidents | Share |
|---|---|---|
| Temperature Excursion | 941 | 37.0% |
| Label Error | 558 | 21.9% |
| Quantity Mismatch | 540 | 21.2% |
| Documentation Missing | 131 | 5.2% |
| Wrong Item Delivered | 129 | 5.1% |
| Expired on Arrival | 127 | 5.0% |
| Packaging Damaged | 118 | 4.6% |
| **Total** | **2,544** | **100%** |

**Total Rejection Financial Exposure: $36,047,967 (10.2% of total supply chain cost)**

### Rejection Cost by Item Category

| Item Category | Rejection Cost |
|---|---|
| Chemotherapy Agents | **$17,499,333** |
| Blood Products | $6,246,031 |
| Controlled Drugs | $2,988,250 |
| Parenteral Nutrition | $2,620,160 |
| Diagnostic Reagents | $2,038,749 |
| Imaging Contrast | $1,544,734 |
| Vaccines | $1,298,035 |
| Surgical Instruments | $918,027 |

> Chemotherapy agents alone account for **48.5% of total rejection cost**, driven by high unit costs ($1,029 average) and temperature sensitivity.

### Quantity Mismatch by Origin

| Origin | Mismatch Rate |
|---|---|
| Lab Supply Room | 9.1% |
| Pharmacy Hub | 8.6% |
| Radiology Store | 8.5% |
| Central Warehouse | 8.4% |
| Sterile Processing | 8.1% |

---

## 7. Cold Chain & Temperature Excursion Analysis

### Excursion Rate by Item Category

```sql
SELECT
    Item_Category,
    SUM(Temp_Excursion_Flag) AS Excursions,
    COUNT(*) AS Total,
    ROUND(AVG(CAST(Temp_Excursion_Flag AS FLOAT)) * 100, 2) AS Excursion_Rate_Pct
FROM Logistics_Distribution
GROUP BY Item_Category
ORDER BY Excursion_Rate_Pct DESC;
```

| Item Category | Excursions | Excursion Rate |
|---|---|---|
| Diagnostic Reagents | 267 | **12.5%** 🔴 |
| Blood Products | 402 | **12.5%** 🔴 |
| Vaccines | 291 | **12.2%** 🔴 |
| Chemotherapy Agents | 190 | **12.1%** 🔴 |
| Parenteral Nutrition | 194 | **11.7%** 🔴 |
| Organ Specimens | 153 | **11.5%** 🔴 |
| Controlled Drugs | 0 | ✅ 0.0% |
| IV Fluids | 0 | ✅ 0.0% |
| Medical Gases | 0 | ✅ 0.0% |

**Key Finding:** Temperature excursions are **exclusively concentrated in cold-chain-sensitive biologics** (items requiring 2–8°C storage). Items stored at ambient temperature show zero excursions. This pattern indicates the failure is in refrigerated transport and cold storage handoff protocols, not in environmental monitoring technology.

### Excursion Rate by Carrier

| Carrier | Excursion Rate |
|---|---|
| ColdChain Solutions | Highest |
| BioFreight Inc | Elevated |
| Internal Porter Team | Near average |
| HospitalRun Internal | Lowest |

> Despite its name, **ColdChain Solutions** posts the highest SLA breach rate (61.9%) — a critical finding that warrants immediate contract review.

---

## 8. Cost & Financial Exposure Analysis

### Total Supply Chain Cost by Item Category

| Item Category | Total Cost | Avg Unit Cost | Avg Handling Cost | Transfers |
|---|---|---|---|---|
| Chemotherapy Agents | **$159,046,500** | $1,028.70 | $19.76 | 1,569 |
| Controlled Drugs | $52,569,980 | $240.29 | $20.33 | 2,163 |
| Blood Products | $47,649,810 | $143.67 | $19.04 | 3,226 |
| Parenteral Nutrition | $21,424,970 | $131.13 | $19.76 | 1,662 |
| Imaging Contrast | $20,748,770 | $108.04 | $19.50 | 1,920 |
| Diagnostic Reagents | $15,418,870 | $72.32 | $18.91 | 2,135 |
| Surgical Instruments | $14,803,440 | $54.08 | $19.70 | 2,743 |
| Vaccines | $10,044,680 | $41.92 | $18.56 | 2,392 |

### Annual Cost Trend

| Year | Total Supply Chain Cost | YoY Change |
|---|---|---|
| 2020 | $85,260,177 | — |
| 2021 | $88,550,889 | +3.9% |
| 2022 | $91,148,884 | +2.9% |
| 2023 | $89,558,511 | -1.7% |

> Cost grew 6.8% over the period before a slight contraction in 2023. The $36M rejection loss is a largely preventable cost that represents 40%+ of a full year's cost growth.

---

## 9. Carrier Performance Benchmarking

```sql
SELECT
    Carrier,
    COUNT(*) AS Transfers,
    ROUND(AVG(CAST(SLA_Breach AS FLOAT)) * 100, 1) AS SLA_Breach_Rate,
    ROUND(AVG(Handling_Cost_USD), 2) AS Avg_Handling_Cost,
    ROUND(AVG(CAST(Rejected_Flag AS FLOAT)) * 100, 1) AS Rejection_Rate,
    RANK() OVER (ORDER BY AVG(CAST(SLA_Breach AS FLOAT)) ASC) AS Performance_Rank
FROM Logistics_Distribution
GROUP BY Carrier;
```

| Rank | Carrier | SLA Breach Rate | Rejection Rate | Avg Handling Cost | Volume |
|---|---|---|---|---|---|
| 🥇 1 | HospitalRun Internal | **45.1%** | 9.7% | $19.18 | 2,667 |
| 🥈 2 | Internal Porter Team | **47.0%** | 9.7% | $19.38 | 7,635 |
| 🥉 3 | RapidMed Couriers | 50.2% | 9.5% | $19.70 | 3,623 |
| 4 | MedExpress Logistics | 54.1% | 9.2% | $19.45 | 5,992 |
| 5 | BioFreight Inc | 61.3% | 9.1% | $20.28 | 3,077 |
| 🔴 6 | ColdChain Solutions | **61.9%** | 9.2% | $19.07 | 4,006 |

**Key Insight:** Internal teams (HospitalRun Internal, Internal Porter Team) significantly outperform all third-party carriers on SLA compliance. External carriers — particularly ColdChain Solutions and BioFreight Inc — show breach rates 15–17 percentage points above the best internal performer, while charging comparable or higher handling costs.

---

## 10. Transport Mode Efficiency

| Transport Mode | SLA Breach Rate | Volume | Notes |
|---|---|---|---|
| Electric Trolley | 54.2% | 5,347 | Highest breach rate |
| Dumbwaiter | 53.1% | 2,741 | |
| Refrigerated Van | 52.9% | 4,191 | Cold chain risk |
| Courier Vehicle | 52.6% | 3,503 | External exposure |
| Pneumatic Tube | 52.6% | 3,234 | |
| Manual Cart | **51.4%** | 7,984 | Best performer; highest volume |

**Key Insight:** Manual Cart, despite being the highest-volume mode, shows the lowest breach rate — suggesting that human-paced transport may actually be more reliable than automated or motorized alternatives in this environment.

---

## 11. Origin & Destination Risk Profiling

### Highest-Risk Origins (Quantity Mismatch)

```sql
SELECT Origin,
       SUM(Qty_Mismatch_Flag) AS Mismatches,
       ROUND(AVG(CAST(Qty_Mismatch_Flag AS FLOAT)) * 100, 1) AS Mismatch_Rate
FROM Logistics_Distribution
GROUP BY Origin
ORDER BY Mismatch_Rate DESC;
```

| Origin | Mismatch Rate | Risk |
|---|---|---|
| Lab Supply Room | 9.1% | 🔴 High |
| Pharmacy Hub | 8.6% | 🔴 High |
| Radiology Store | 8.5% | 🔴 High |
| Central Warehouse | 8.4% | 🔴 High |
| Sterile Processing | 8.1% | 🟡 Elevated |

### Highest-Risk Destinations (SLA Breach)

| Destination | Breach Rate |
|---|---|
| Orthopedics | 53.8% |
| Pediatrics | 53.7% |
| Oncology Ward | 53.6% |
| Neurology | 53.5% |
| ICU | 53.0% |
| ER | 52.6% |

---

## 12. Year-over-Year Trend Analysis

```sql
SELECT
    YEAR(Transfer_Date) AS Transfer_Year,
    COUNT(*) AS Total_Transfers,
    SUM(SLA_Breach) AS SLA_Breaches,
    ROUND(AVG(CAST(SLA_Breach AS FLOAT)) * 100, 1) AS Breach_Rate_Pct,
    SUM(Rejected_Flag) AS Rejections,
    SUM(Temp_Excursion_Flag) AS Temp_Excursions
FROM Logistics_Distribution
GROUP BY YEAR(Transfer_Date)
ORDER BY Transfer_Year;
```

| Year | Transfers | SLA Breach Rate | Trend |
|---|---|---|---|
| 2020 | 6,693 | 53.0% | Baseline |
| 2021 | 6,836 | 52.5% | ↓ slight improvement |
| 2022 | 6,821 | 51.7% | ↓ marginal improvement |
| 2023 | 6,650 | 53.4% | ↑ regression |

> Over the four-year period, SLA compliance improved marginally from 2020 to 2022 but **regressed in 2023**, suggesting that any improvement initiatives lacked sustainability or were reversed.

---

## 13. Documentation & Compliance Gap

```sql
SELECT
    Destination,
    SUM(CASE WHEN Documentation_Complete = 'No' THEN 1 ELSE 0 END) AS Incomplete_Docs,
    COUNT(*) AS Total,
    ROUND(SUM(CASE WHEN Documentation_Complete = 'No' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1) AS Incomplete_Rate
FROM Logistics_Distribution
GROUP BY Destination
ORDER BY Incomplete_Rate DESC;
```

| Destination | Incomplete Doc Rate |
|---|---|
| Cardiology | 7.8% |
| Pharmacy Outpost | 7.5% |
| General Ward A | 7.4% |
| Laboratory | 7.3% |
| ICU | 7.0% |
| Surgery Suite | 6.9% |

Overall documentation gap: **6.9% of 27,000 transfers = ~1,863 transfers with incomplete documentation**, creating regulatory compliance and traceability risk especially for controlled drugs and chemotherapy agents.

---

## 14. Strategic Recommendations

### 🔴 Priority 1 — SLA Compliance Overhaul (Immediate)

**Problem:** 52.7% overall SLA breach rate; 51.2% on Emergency transfers.

**Recommendations:**
- Redesign transit routing logic in the Hospital Information System to auto-escalate Emergency and STAT shipments to the fastest available carrier (internal teams preferred)
- Implement real-time transfer tracking with automatic alert triggers at 50% and 80% of SLA time elapsed
- Introduce SLA dashboards per ward and per carrier with weekly review cadence by the logistics manager
- Penalize repeat SLA breaches contractually; embed SLA KPIs into carrier SLAs with financial claw-backs

---

### 🔴 Priority 2 — Carrier Contract Review (Immediate)

**Problem:** ColdChain Solutions (61.9% breach) and BioFreight Inc (61.3% breach) are significantly underperforming internal teams.

**Recommendations:**
- Immediately audit ColdChain Solutions and BioFreight Inc contracts; issue a formal Performance Improvement Notice
- Transition high-priority and biologics shipments to HospitalRun Internal or Internal Porter Team where capacity allows
- Evaluate hybrid insourcing of cold-chain deliveries for Chemotherapy Agents and Blood Products, given their $17.5M and $6.2M rejection cost exposure

---

### 🔴 Priority 3 — Cold Chain Integrity Programme (Urgent)

**Problem:** Temperature excursions affect 12.5% of Blood Products, Vaccines, and Diagnostic Reagents. Chemotherapy rejection losses alone = $17.5M.

**Recommendations:**
- Mandate continuous temperature data loggers on all transfers of biologics, blood products, vaccines, and chemotherapy agents
- Enforce immediate cold chain handoff protocols at every transfer node with digital acknowledgement sign-off
- Investigate why ColdChain Solutions — a specialist cold chain carrier — has the highest SLA breach and elevated excursion rates; review their refrigerated vehicle maintenance records
- Set a maximum 1% temperature excursion KPI for new carrier contracts; current 5.5% rate is unacceptable

---

### 🟡 Priority 4 — Quantity Mismatch & Dispatch Accuracy (Short-term)

**Problem:** 8.2% quantity mismatch rate; Lab Supply Room (9.1%) and Pharmacy Hub (8.6%) are highest-risk dispatch origins.

**Recommendations:**
- Implement barcode/RFID scan-verify-before-dispatch workflow at Lab Supply Room and Pharmacy Hub
- Require dual-staff sign-off for high-value item categories (Chemotherapy, Controlled Drugs, Blood Products)
- Conduct a root cause analysis on the 558 label errors — second-largest rejection reason — to identify whether the issue is printing, affixing, or scanning

---

### 🟡 Priority 5 — Documentation Completeness (Short-term)

**Problem:** 6.9% documentation incomplete rate; Cardiology (7.8%) and Pharmacy Outpost (7.5%) worst.

**Recommendations:**
- Block transfers from proceeding to dispatch if documentation fields are incomplete (system-enforced gate)
- Automate documentation generation for routine transfers via the Hospital Supply Chain Management System
- Audit all 131 "Documentation Missing" rejection cases for regulatory compliance exposure on Controlled Drugs

---

### 🟢 Priority 6 — Internal Capacity Expansion (Medium-term)

**Problem:** Internal carriers outperform external ones significantly; their volume share is constrained.

**Recommendations:**
- Increase Internal Porter Team headcount or shift scheduling to absorb volume from worst-performing external carriers
- Build a business case for expanding HospitalRun Internal from 2,667 to 5,000+ annual transfers, replacing ColdChain Solutions routing

---

## 15. SQL Queries Reference

<details>
<summary><strong>Click to expand all T-SQL queries used in this analysis</strong></summary>

```sql
-- ============================================================
-- HOSPITAL LOGISTICS DISTRIBUTION — FULL T-SQL ANALYSIS
-- Microsoft SQL Server | Database: HospitalSupplyChain
-- ============================================================

-- 0. DATASET OVERVIEW
SELECT
    COUNT(*) AS Total_Transfers,
    MIN(Transfer_Date) AS Date_From,
    MAX(Transfer_Date) AS Date_To,
    COUNT(DISTINCT Origin) AS Unique_Origins,
    COUNT(DISTINCT Destination) AS Unique_Destinations,
    COUNT(DISTINCT Carrier) AS Unique_Carriers,
    COUNT(DISTINCT Item_Category) AS Unique_Item_Categories
FROM Logistics_Distribution;

-- 1. EXECUTIVE KPIs
SELECT
    COUNT(*) AS Total_Transfers,
    SUM(Qty_Shipped) AS Total_Units_Shipped,
    ROUND(SUM(Unit_Cost_USD * Qty_Shipped), 2) AS Gross_Item_Value,
    ROUND(SUM(Handling_Cost_USD), 2) AS Total_Handling_Cost,
    ROUND(SUM(Unit_Cost_USD * Qty_Shipped + Handling_Cost_USD), 2) AS Total_Supply_Chain_Cost,
    ROUND(AVG(CAST(SLA_Breach AS FLOAT)) * 100, 1) AS SLA_Breach_Rate_Pct,
    ROUND(AVG(CAST(Rejected_Flag AS FLOAT)) * 100, 1) AS Rejection_Rate_Pct,
    ROUND(AVG(CAST(Temp_Excursion_Flag AS FLOAT)) * 100, 1) AS Temp_Excursion_Rate_Pct,
    ROUND(AVG(CAST(Qty_Mismatch_Flag AS FLOAT)) * 100, 1) AS Qty_Mismatch_Rate_Pct,
    ROUND(AVG(CAST(Redelivery_Required AS FLOAT)) * 100, 1) AS Redelivery_Rate_Pct,
    ROUND(AVG(Transit_Hours), 2) AS Avg_Transit_Hours
FROM Logistics_Distribution;

-- 2. SLA COMPLIANCE BY PRIORITY
SELECT
    Priority_Level,
    COUNT(*) AS Total_Transfers,
    SUM(SLA_Breach) AS SLA_Breaches,
    ROUND(AVG(CAST(SLA_Breach AS FLOAT)) * 100, 1) AS Breach_Rate_Pct,
    ROUND(AVG(Transit_Hours), 2) AS Avg_Transit_Hours,
    AVG(SLA_Hours) AS Avg_SLA_Hours
FROM Logistics_Distribution
GROUP BY Priority_Level
ORDER BY Breach_Rate_Pct DESC;

-- 3. CARRIER PERFORMANCE SCORECARD
SELECT
    Carrier,
    COUNT(*) AS Transfers,
    ROUND(AVG(CAST(SLA_Breach AS FLOAT)) * 100, 1) AS SLA_Breach_Rate,
    ROUND(AVG(CAST(Rejected_Flag AS FLOAT)) * 100, 1) AS Rejection_Rate,
    ROUND(AVG(CAST(Temp_Excursion_Flag AS FLOAT)) * 100, 1) AS Temp_Excursion_Rate,
    ROUND(AVG(Handling_Cost_USD), 2) AS Avg_Handling_Cost,
    RANK() OVER (ORDER BY AVG(CAST(SLA_Breach AS FLOAT)) ASC) AS SLA_Rank
FROM Logistics_Distribution
GROUP BY Carrier
ORDER BY SLA_Breach_Rate;

-- 4. REJECTION ROOT CAUSE ANALYSIS
SELECT
    Rejection_Reason,
    COUNT(*) AS Incidents,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Logistics_Distribution WHERE Rejected_Flag = 1), 1) AS Pct_of_Rejections,
    ROUND(SUM(Unit_Cost_USD * Qty_Shipped + Handling_Cost_USD), 2) AS Financial_Impact_USD
FROM Logistics_Distribution
WHERE Rejected_Flag = 1
GROUP BY Rejection_Reason
ORDER BY Financial_Impact_USD DESC;

-- 5. TEMPERATURE EXCURSION BY ITEM CATEGORY
SELECT
    Item_Category,
    Temp_Required,
    COUNT(*) AS Total_Transfers,
    SUM(Temp_Excursion_Flag) AS Excursions,
    ROUND(AVG(CAST(Temp_Excursion_Flag AS FLOAT)) * 100, 2) AS Excursion_Rate_Pct,
    ROUND(AVG(Temp_Recorded_C), 2) AS Avg_Temp_Recorded
FROM Logistics_Distribution
GROUP BY Item_Category, Temp_Required
ORDER BY Excursion_Rate_Pct DESC;

-- 6. COST & REJECTION EXPOSURE BY ITEM CATEGORY
SELECT
    Item_Category,
    COUNT(*) AS Transfers,
    ROUND(AVG(Unit_Cost_USD), 2) AS Avg_Unit_Cost,
    ROUND(SUM(Unit_Cost_USD * Qty_Shipped + Handling_Cost_USD), 2) AS Total_Cost,
    SUM(Rejected_Flag) AS Rejected_Transfers,
    ROUND(SUM(CASE WHEN Rejected_Flag = 1 THEN Unit_Cost_USD * Qty_Shipped + Handling_Cost_USD ELSE 0 END), 2) AS Rejection_Cost_Loss
FROM Logistics_Distribution
GROUP BY Item_Category
ORDER BY Rejection_Cost_Loss DESC;

-- 7. YEAR-OVER-YEAR TREND
SELECT
    YEAR(Transfer_Date) AS Transfer_Year,
    COUNT(*) AS Total_Transfers,
    ROUND(AVG(CAST(SLA_Breach AS FLOAT)) * 100, 1) AS SLA_Breach_Rate,
    SUM(Rejected_Flag) AS Total_Rejections,
    SUM(Temp_Excursion_Flag) AS Total_Temp_Excursions,
    ROUND(SUM(Unit_Cost_USD * Qty_Shipped + Handling_Cost_USD), 2) AS Total_Cost
FROM Logistics_Distribution
GROUP BY YEAR(Transfer_Date)
ORDER BY Transfer_Year;

-- 8. QUANTITY MISMATCH BY ORIGIN
SELECT
    Origin,
    COUNT(*) AS Total_Transfers,
    SUM(Qty_Mismatch_Flag) AS Mismatches,
    ROUND(AVG(CAST(Qty_Mismatch_Flag AS FLOAT)) * 100, 1) AS Mismatch_Rate_Pct
FROM Logistics_Distribution
GROUP BY Origin
ORDER BY Mismatch_Rate_Pct DESC;

-- 9. DOCUMENTATION COMPLIANCE BY DESTINATION
SELECT
    Destination,
    COUNT(*) AS Total_Transfers,
    SUM(CASE WHEN Documentation_Complete = 'No' THEN 1 ELSE 0 END) AS Incomplete_Docs,
    ROUND(SUM(CASE WHEN Documentation_Complete = 'No' THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1) AS Incomplete_Rate_Pct
FROM Logistics_Distribution
GROUP BY Destination
ORDER BY Incomplete_Rate_Pct DESC;

-- 10. TRANSPORT MODE EFFICIENCY
SELECT
    Transport_Mode,
    COUNT(*) AS Transfers,
    ROUND(AVG(CAST(SLA_Breach AS FLOAT)) * 100, 1) AS SLA_Breach_Rate,
    ROUND(AVG(Transit_Hours), 2) AS Avg_Transit_Hours,
    ROUND(AVG(Handling_Cost_USD), 2) AS Avg_Handling_Cost
FROM Logistics_Distribution
GROUP BY Transport_Mode
ORDER BY SLA_Breach_Rate;

-- 11. STAFF PERFORMANCE ANALYSIS
SELECT TOP 10
    Staff_ID,
    COUNT(*) AS Transfers_Handled,
    SUM(SLA_Breach) AS SLA_Breaches,
    ROUND(AVG(CAST(SLA_Breach AS FLOAT)) * 100, 1) AS Breach_Rate_Pct,
    SUM(Rejected_Flag) AS Rejections_Handled
FROM Logistics_Distribution
GROUP BY Staff_ID
ORDER BY SLA_Breaches DESC;

-- 12. HIGH-VALUE REJECTED TRANSFERS (TOP 20)
SELECT TOP 20
    Transfer_ID,
    Transfer_Date,
    Item_Category,
    Carrier,
    Rejection_Reason,
    Qty_Shipped,
    Unit_Cost_USD,
    ROUND(Unit_Cost_USD * Qty_Shipped + Handling_Cost_USD, 2) AS Total_Cost_USD
FROM Logistics_Distribution
WHERE Rejected_Flag = 1
ORDER BY Unit_Cost_USD * Qty_Shipped DESC;
```



