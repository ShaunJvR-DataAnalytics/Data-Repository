select *
from [mdl].[v_Fact_GL_Entries_Snapshotv2_Current]

select *
from [mdl].[DIM_GL_ACCOUNTS]

--Mileage
SELECT 
    d.GL_ACCOUNT_NUMBER,
	d.COMPANY_NAME,
    d.GL_ACCOUNT_DESC,
    SUM(f.AMOUNT) AS Total_Amount 
FROM [mdl].[v_Fact_GL_Entries_Snapshotv2_Current] f 
LEFT JOIN [mdl].[DIM_GL_ACCOUNTS] d    
ON d.GL_ACCOUNT_NUMBER = f.GL_ACCOUNT_NUMBER
WHERE d.GL_ACCOUNT_NUMBER = '60201'  -- Only Mileage
  AND f.POSTED_DATE_ID BETWEEN '20240401' AND '20250228' -- Only April 2024 to feb 2025
  AND d.ETL_CURRENT_FLAG = 'Y'
GROUP BY d.GL_ACCOUNT_NUMBER, d.GL_ACCOUNT_DESC,d.COMPANY_NAME;

--Travel
SELECT 
    d.GL_ACCOUNT_NUMBER,
	d.COMPANY_NAME,
    d.GL_ACCOUNT_DESC,
    SUM(f.AMOUNT) AS Total_Amount 
FROM [mdl].[v_Fact_GL_Entries_Snapshotv2_Current] f 
LEFT JOIN [mdl].[DIM_GL_ACCOUNTS] d    
ON d.GL_ACCOUNT_NUMBER = f.GL_ACCOUNT_NUMBER
WHERE d.GL_ACCOUNT_NUMBER = '60205'  -- Only Mileage
  AND f.POSTED_DATE_ID BETWEEN '20240401' AND '20250228' -- Only April 2024 to feb 2025
  AND d.ETL_CURRENT_FLAG = 'Y'
GROUP BY d.GL_ACCOUNT_NUMBER, d.GL_ACCOUNT_DESC,d.COMPANY_NAME;

--Accomodation and travel
SELECT 
    d.GL_ACCOUNT_NUMBER,
	d.COMPANY_NAME,
    d.GL_ACCOUNT_DESC,
    SUM(f.AMOUNT) AS Total_Amount 
FROM [mdl].[v_Fact_GL_Entries_Snapshotv2_Current] f 
LEFT JOIN [mdl].[DIM_GL_ACCOUNTS] d    
ON d.GL_ACCOUNT_NUMBER = f.GL_ACCOUNT_NUMBER
WHERE d.GL_ACCOUNT_NUMBER = '60200'  -- Only Mileage
  AND f.POSTED_DATE_ID BETWEEN '20240401' AND '20250228' -- Only April 2024 to feb 2025
  AND d.ETL_CURRENT_FLAG = 'Y'
GROUP BY d.GL_ACCOUNT_NUMBER, d.GL_ACCOUNT_DESC,d.COMPANY_NAME;




