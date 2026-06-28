-- =============================================
-- Predictive Maintenance Analysis
-- Dataset: AI4I 2020 | Author: Raj Shethna
-- =============================================

USE PredictiveMaintenance;

SELECT TOP 5 * 
FROM MachineSensor; --Top 5 rows


-- 1. Overall Failure Rate
SELECT 
    COUNT(*) AS Total_Records,
    SUM(CAST(Machine_failure AS INT)) AS Total_Failures,
    ROUND(100.0 * SUM(CAST(Machine_failure AS INT)) / COUNT(*), 2) AS Failure_Rate_Pct
FROM MachineSensor;
/*10,000 production runs recorded
339 ended in machine failure
3.39% overall failure rate*/


-- 2. Failure Rate by Machine Type
SELECT 
    Type,
    COUNT(*) AS Total,
    SUM(CAST(Machine_failure AS INT)) AS Failures,
    ROUND(100.0 * SUM(CAST(Machine_failure AS INT)) / COUNT(*), 2) AS Failure_Rate_Pct
FROM MachineSensor
GROUP BY Type
ORDER BY Failure_Rate_Pct DESC;
/*Low grade machines (L) fail the most — 3.92% failure rate, and they make up 60% of all production runs
Medium grade (M) — 2.77%
High grade (H) — most reliable at 2.09%, less than half the failure rate of L

Lower quality machines are being used most frequently and failing most often. An IE team would use this to make two decisions — either schedule more preventive 
maintenance on L-type machines, or shift higher-risk jobs to H-type machines.*/


-- 3. Failure by Mode
SELECT
    SUM(CAST(TWF AS INT)) AS Tool_Wear_Failures,
    SUM(CAST(HDF AS INT)) AS Heat_Dissipation_Failures,
    SUM(CAST(PWF AS INT)) AS Power_Failures,
    SUM(CAST(OSF AS INT)) AS Overstrain_Failures,
    SUM(CAST(RNF AS INT)) AS Random_Failures
FROM MachineSensor;
/*Heat dissipation is the dominant failure mode at 34% of all failures — and critically, it's preventable. It's driven by temperature differentials between air and 
process temperature. If the IE team monitors that gap in real time and flags when it narrows below a threshold, they can intervene before the machine fails. That's 
the difference between reactive maintenance and predictive maintenance*/


-- 4. Process Conditions: Failure vs No Failure
SELECT 
    Machine_failure,
    ROUND(AVG(Air_temperature_K), 2) AS Avg_Air_Temp,
    ROUND(AVG(Process_temperature_K), 2) AS Avg_Process_Temp,
    ROUND(AVG(CAST(Rotational_speed_rpm AS FLOAT)), 2) AS Avg_RPM,
    ROUND(AVG(Torque_Nm), 2) AS Avg_Torque,
    ROUND(AVG(CAST(Tool_wear_min AS FLOAT)), 2) AS Avg_Tool_Wear
FROM MachineSensor
GROUP BY Machine_failure;
/*The three signals that predict failure:
1. Torque spikes — machines that fail are running at 27% higher torque on average. High torque means the cutting tool is working harder than it should — either the 
material is tougher, the tool is worn, or the feed rate is wrong.
2. Tool wear accumulation — failed machines had tools running 35% longer than healthy machines. This directly connects to the TWF and OSF failure modes you saw in 
Query 3.
3. RPM drops — failing machines spin slower. This is a classic sign of mechanical resistance building up — the machine is struggling before it fails.*/

/*Four complete query results that tell a coherent story:

- 3.39% failure rate — small but costly at scale
- Low-grade machines fail most — resource allocation opportunity
- Heat dissipation dominates — temperature management gap
- Torque + tool wear + RPM are the predictive signals — actionable thresholds*/


-- 5. High Risk Threshold Alert
SELECT 
    COUNT(*) AS High_Risk_Runs,
    SUM(CAST(Machine_failure AS INT)) AS Actual_Failures,
    ROUND(100.0 * SUM(CAST(Machine_failure AS INT)) / COUNT(*), 2) AS Failure_Rate_Pct
FROM MachineSensor
WHERE Torque_Nm > 47 AND Tool_wear_min > 130;
/*When torque exceeds 47 Nm AND tool wear exceeds 130 minutes:

- 950 production runs met this condition
- 139 of them failed
- 14.63% failure rate — compared to 3.39% overall

That's a 4.3x higher failure rate in identifiable, predictable conditions.*/

/*I analysed 10,000 production records from a manufacturing process dataset. Overall failure rate was 3.39%. But when I isolated runs where torque exceeded 47 Nm 
and tool wear exceeded 130 minutes, the failure rate jumped to 14.63% — 4.3 times higher. That means the team could monitor just two variables in real time and 
flag high-risk machines before they fail, reducing unplanned downtime without any complex machine learning. Just SQL threshold logic connected to a Power BI alert 
dashboard.*/