-- ============================================================
-- HOSPITAL LOGISTICS DISTRIBUTION — FULL SQL ANALYSIS
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
    SUM(CAST(SLA_Breach AS INT)) AS SLA_Breaches, 
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
    SUM(CAST(Temp_Excursion_Flag AS INT)) AS Excursions,  
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
    SUM(CAST(Rejected_Flag AS INT)) AS Rejected_Transfers,  
    ROUND(SUM(CASE WHEN Rejected_Flag = 1 THEN Unit_Cost_USD * Qty_Shipped + Handling_Cost_USD ELSE 0 END), 2) AS Rejection_Cost_Loss
FROM Logistics_Distribution
GROUP BY Item_Category
ORDER BY Rejection_Cost_Loss DESC;

-- 7. YEAR-OVER-YEAR TREND
SELECT
    YEAR(Transfer_Date) AS Transfer_Year,
    COUNT(*) AS Total_Transfers,
    ROUND(AVG(CAST(SLA_Breach AS FLOAT)) * 100, 1) AS SLA_Breach_Rate,
    SUM(CAST(Rejected_Flag AS INT)) AS Total_Rejections,          
    SUM(CAST(Temp_Excursion_Flag AS INT)) AS Total_Temp_Excursions, 
    ROUND(SUM(Unit_Cost_USD * Qty_Shipped + Handling_Cost_USD), 2) AS Total_Cost
FROM Logistics_Distribution
GROUP BY YEAR(Transfer_Date)
ORDER BY Transfer_Year;

-- 8. QUANTITY MISMATCH BY ORIGIN
SELECT
    Origin,
    COUNT(*) AS Total_Transfers,
    SUM(CAST(Qty_Mismatch_Flag AS INT)) AS Mismatches, 
    ROUND(AVG(CAST(Qty_Mismatch_Flag AS FLOAT)) * 100, 1) AS Mismatch_Rate_Pct
FROM Logistics_Distribution
GROUP BY Origin
ORDER BY Mismatch_Rate_Pct DESC;

-- 9. DOCUMENTATION COMPLIANCE BY DESTINATION
SELECT
    Destination,
    COUNT(*) AS Total_Transfers,
    SUM(CASE WHEN Documentation_Complete = 0 THEN 1 ELSE 0 END) AS Incomplete_Docs,  
    ROUND(SUM(CASE WHEN Documentation_Complete = 0 THEN 1.0 ELSE 0 END) / COUNT(*) * 100, 1) AS Incomplete_Rate_Pct
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
    SUM(CAST(SLA_Breach AS INT)) AS SLA_Breaches,      
    ROUND(AVG(CAST(SLA_Breach AS FLOAT)) * 100, 1) AS Breach_Rate_Pct,
    SUM(CAST(Rejected_Flag AS INT)) AS Rejections_Handled  
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