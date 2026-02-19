DECLARE @startdate DATE = '2024-05-01';
DECLARE @enddate DATE = CAST(GETDATE() AS DATE);

WITH base AS (
    SELECT *,
        CASE 
            WHEN MONTH(Report_Run_Date) >= 4 THEN YEAR(Report_Run_Date)
            ELSE YEAR(Report_Run_Date) - 1
        END AS fiscal_year,
        CASE 
            WHEN MONTH(Report_Run_Date) BETWEEN 4 AND 6 THEN 1
            WHEN MONTH(Report_Run_Date) BETWEEN 7 AND 9 THEN 2
            WHEN MONTH(Report_Run_Date) BETWEEN 10 AND 12 THEN 3
            ELSE 4
        END AS fiscal_quarter_no,
        ROW_NUMBER() OVER (
            PARTITION BY Report_Run_Date
            ORDER BY Last_Refreshed_Date DESC
        ) AS rn
    FROM mdl.dim_monthly_close_dates
),
Month_Params AS (
    SELECT 
        b.*,
        FORMAT(b.Report_Run_Date, 'MMMM') AS Snapshot_Month,
        b.Report_Run_Date AS Report_Date,

        -- Quarter Start Date Lookup
        (SELECT TOP 1 Report_Run_Date 
         FROM mdl.dim_monthly_close_dates d
         WHERE 
            (
                (b.fiscal_quarter_no = 1 AND MONTH(d.Report_Run_Date) = 4 AND YEAR(d.Report_Run_Date) = b.fiscal_year)
                OR (b.fiscal_quarter_no = 2 AND MONTH(d.Report_Run_Date) = 7 AND YEAR(d.Report_Run_Date) = b.fiscal_year)
                OR (b.fiscal_quarter_no = 3 AND MONTH(d.Report_Run_Date) = 10 AND YEAR(d.Report_Run_Date) = b.fiscal_year)
                OR (b.fiscal_quarter_no = 4 AND MONTH(d.Report_Run_Date) = 1 AND YEAR(d.Report_Run_Date) = b.fiscal_year + 1)
            )
         ORDER BY d.Report_Run_Date
        ) AS Quarter_Start_Date,

        -- Quarter End Date Lookup (start of next quarter)
        (SELECT TOP 1 Report_Run_Date 
         FROM mdl.dim_monthly_close_dates d
         WHERE 
            (
                (b.fiscal_quarter_no = 1 AND MONTH(d.Report_Run_Date) = 7 AND YEAR(d.Report_Run_Date) = b.fiscal_year)
                OR (b.fiscal_quarter_no = 2 AND MONTH(d.Report_Run_Date) = 10 AND YEAR(d.Report_Run_Date) = b.fiscal_year)
                OR (b.fiscal_quarter_no = 3 AND MONTH(d.Report_Run_Date) = 1 AND YEAR(d.Report_Run_Date) = b.fiscal_year + 1)
                OR (b.fiscal_quarter_no = 4 AND MONTH(d.Report_Run_Date) = 4 AND YEAR(d.Report_Run_Date) = b.fiscal_year + 1)
            )
         ORDER BY d.Report_Run_Date
        ) AS Quarter_End_Date

    FROM base b
    WHERE b.rn = 1 
      AND b.Report_Run_Date >= @startdate AND b.Report_Run_Date <= @enddate
),
Latest_ETL AS (
    SELECT 
        o.Opportunity_SID,
        MAX(o.ETL_Effective_DTS) AS Max_ETL_Effective_DTS,
        mp.Snapshot_Month,
        mp.Quarter_Start_Date,
        mp.Quarter_End_Date
    FROM mdl.Dim_Opportunities o
    INNER JOIN Month_Params mp 
        ON o.ETL_Effective_DTS <= mp.Report_Date
    GROUP BY o.Opportunity_SID, mp.Snapshot_Month, mp.Quarter_Start_Date, mp.Quarter_End_Date
),
Filtered_Data AS (
    SELECT 
        o.Opportunity_ID,
        o.LC_MRR AS MRR,
        o.LC_NRR AS NRR,
        o.ETL_Effective_DTS,
        CASE 
            WHEN moh.Providing_Practice = 'Collaborate' THEN 'C&C'
            WHEN moh.Providing_Practice = 'Communications Compliance' THEN 'C&C'
            ELSE moh.Providing_Practice
        END AS Providing_Practice,
        le.Quarter_Start_Date,
        le.Quarter_End_Date
    FROM mdl.v_FACT_Marketing_Opportunities_History moh
    LEFT JOIN mdl.Dim_Opportunities o
        ON o.Opportunity_ID = moh.Opportunity_ID
    INNER JOIN Latest_ETL le
        ON o.Opportunity_SID = le.Opportunity_SID 
       AND o.ETL_Effective_DTS = le.Max_ETL_Effective_DTS
    INNER JOIN Month_Params mp
        ON mp.Snapshot_Month = le.Snapshot_Month
       AND o.Estimated_Close_DT >= mp.Quarter_Start_Date
       AND o.Estimated_Close_DT <= mp.Quarter_End_Date
    WHERE 
        moh.Providing_Practice IN ('Collaborate', 'Communications Compliance', 'Connect', 'Consult', 'Digital', 'Experience', 'Gyrocom', 'Transform')
        AND o.State = 'Open'
        AND o.Opportunity_Type NOT LIKE '%Renewal%'
        AND o.Confidence_Level IN ('75%', '90%')
),
Deduped AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY Opportunity_ID, Quarter_Start_Date
            ORDER BY ETL_Effective_DTS DESC
        ) AS rn
    FROM Filtered_Data
)
SELECT 
    CONVERT(DATE, DATEFROMPARTS(YEAR(CAST(Quarter_Start_Date AS DATE)), MONTH(CAST(Quarter_Start_Date AS DATE)), 1)) AS my_Period,
    CAST(Quarter_Start_Date AS DATE) AS Quarter_Start_Date,
    CAST(Quarter_End_Date   AS DATE) AS Quarter_End_Date,
    Providing_Practice,
    ROUND(SUM(CAST(CASE WHEN Providing_Practice <> 'Digital' THEN MRR ELSE 0 END AS DECIMAL(18,2))), 2) AS Pipeline_MRR,
	ROUND(SUM(CAST(NRR AS DECIMAL(18,2))), 2) AS Pipeline_NRR,
	ROUND(SUM(CAST(CASE WHEN Providing_Practice = 'Digital' THEN MRR ELSE 0 END AS DECIMAL(18,2))), 2) AS Pipeline_ROR
FROM Deduped
WHERE rn = 1
GROUP BY 
    CAST(Quarter_Start_Date AS DATE),
    CAST(Quarter_End_Date   AS DATE),
    Providing_Practice
ORDER BY 
    CAST(Quarter_Start_Date AS DATE),
    Providing_Practice;


