EXEC [ETL].[sp_order_lines_hist_shaun]
    @startdate = '2024-01-01',
    @enddate = '2025-12-09';



--DROP PROCEDURE [ETL].[sp_order_lines_hist_shaun]


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [ETL].[sp_order_lines_hist_shaun]
(
    @startdate DATE,
    @enddate DATE
)
AS 
BEGIN
    SET NOCOUNT ON;

    DECLARE @current_month_end DATE = @startdate;
    
    -- Get distinct month ends within the date range
    DECLARE @month_ends TABLE (
        MonthEnd DATE,
        RowNumber INT IDENTITY(1,1)
    );

    -- Insert all month-end dates within the range
    INSERT INTO @month_ends (MonthEnd)
    SELECT DISTINCT 
        EOMONTH(d.cal_day) AS MonthEnd
    FROM [mdl].[dim_dates] d
    WHERE d.cal_day <= @enddate
        AND d.cal_day >= @startdate
    ORDER BY MonthEnd;

    -- Get starting row
    DECLARE @current_row INT = 1;
    DECLARE @max_row INT = (SELECT COUNT(*) FROM @month_ends);
    DECLARE @current_month DATE;

    -- Drop temp table if exists
    DROP TABLE IF EXISTS #Temp_Table_Mcd_Order_Lines;

    -- Create temp table with correct column definitions
    CREATE TABLE #Temp_Table_Mcd_Order_Lines(
        [BucketDate] [date] NULL,
        [Snapshot_DTS] [datetime2](7) NOT NULL,
        [Order_Line_Date_ID] [int] NOT NULL,
        [Order_ID] [int] NOT NULL,
        [Order_SID] [nvarchar](50) NOT NULL,
        [Order_Line_ID] [int] NOT NULL,
        [Order_Line_SID] [nvarchar](50) NOT NULL,
        [order_line_number] [nvarchar](50) NULL,
        [order_line_status_id] [int] NOT NULL,
        [order_line_status_code] [nvarchar](255) NULL,
        [customer_id] [int] NOT NULL,
        [u_reuse_billing_account_sid] [nvarchar](50) NULL,
        [u_new_billing_account] [nvarchar](255) NULL,
        [account_sid] [nvarchar](50) NULL,
        [account_number] [nvarchar](50) NULL,
        [account_name] [nvarchar](255) NULL,
        [commitment_term_id] [int] NULL,
        [commitment_term_sid] [nvarchar](50) NULL,
        [consumer_sid] [nvarchar](50) NULL,
        [contact_sid] [nvarchar](50) NULL,
        [periodicity_id] [int] NULL,
        [periodicity_sid] [nvarchar](50) NULL,
        [recurring_periodicity] [nvarchar](255) NULL,
        [previous_product_model_sid] [nvarchar](50) NULL,
        [price_list_sid] [nvarchar](50) NULL,
        [priority_id] [int] NULL,
        [priority_code] [nvarchar](50) NULL,
        [product_id] [int] NULL,
        [product_sid] [nvarchar](50) NULL,
        [product_full_name] [nvarchar](255) NULL,
        [product_offering_id] [int] NULL,
        [product_offering_sid] [nvarchar](50) NULL,
        [product_offering_type] [nvarchar](255) NULL,
        [product_specification_sid] [nvarchar](50) NULL,
        [u_billing_product_sid] [nvarchar](50) NULL,
        [service_specification_sid] [nvarchar](50) NULL,
        [location_sid] [nvarchar](50) NULL,
        [shipping_location_sid] [nvarchar](50) NULL,
        [parent_line_item_sid] [nvarchar](50) NULL,
        [specification_sid] [nvarchar](50) NULL,
        [top_line_item_sid] [nvarchar](50) NULL,
        [u_customer_po_tracker_sid] [nvarchar](50) NULL,
        [u_supplier_contract_sid] [nvarchar](50) NULL,
        [pricing_method] [nvarchar](50) NULL,
        [product_fullname] [nvarchar](255) NULL,
        [sold_product_sid] [nvarchar](50) NULL,
        [u_assigned_to_sid] [nvarchar](50) NULL,
        [u_assignment_group_sid] [nvarchar](50) NULL,
        [u_original_crm_product_id] [nvarchar](255) NULL,
        [u_supplier_sid] [nvarchar](50) NULL,
        [unit_of_measurement_sid] [nvarchar](50) NULL,
        [unit_of_measurement_code] [nvarchar](50) NULL,
        [unit_of_measurement_name] [nvarchar](255) NULL,
        [effective_date] [datetime2](7) NULL,
        [expected_end_date] [datetime2](7) NULL,
        [expected_start_date] [datetime2](7) NULL,
        [expiration_date] [datetime2](7) NULL,
        [contract_start_date] [datetime2](7) NULL,
        [planned_end_date] [datetime2](7) NULL,
        [planned_start_date] [datetime2](7) NULL,
        [u_actual_completion_date] [date] NULL,
        [u_billing_start_date] [date] NULL,
        [u_billing_end_date] [date] NULL,
        [u_committed_date] [date] NULL,
        [u_customer_ordered_date] [date] NULL,
        [u_estimated_completion_date] [date] NULL,
        [u_supplier_ordered_date] [date] NULL,
        [actual_end_date] [datetime2](7) NULL,
        [actual_start_date] [datetime2](7) NULL,
        [committed_due_date] [datetime2](7) NULL,
        [contract_end_date] [datetime2](7) NULL,
        [quantity] [decimal](18, 6) NULL,
        [cumulative_annual_recurring_price] [decimal](18, 6) NULL,
        [cumulative_monthly_recurring_price] [decimal](18, 6) NULL,
        [cumulative_one_time_price] [decimal](18, 6) NULL,
        [list_price] [decimal](18, 6) NULL,
        [mrc] [decimal](18, 6) NULL,
        [nrc] [decimal](18, 6) NULL,
        [total_discount] [decimal](18, 6) NULL,
        [total_one_time_charges] [decimal](18, 6) NULL,
        [total_one_time_price] [decimal](18, 6) NULL,
        [total_price] [decimal](18, 6) NULL,
        [total_recurring_charges] [decimal](18, 6) NULL,
        [total_recurring_price] [decimal](18, 6) NULL,
        [u_previous_unit_cost] [decimal](18, 6) NULL,
        [u_previous_unit_price] [decimal](18, 6) NULL,
        [u_total_contract_value] [decimal](18, 6) NULL,
        [u_total_cost] [decimal](18, 6) NULL,
        [u_total_one_time_cost] [decimal](18, 6) NULL,
        [u_total_recurring_cost] [decimal](18, 6) NULL,
        [u_unit_net_cost] [decimal](18, 6) NULL,
        [unit_price] [decimal](18, 6) NULL,
        [Load_DTS] [datetime2](7) NOT NULL,
        [Created_By] [nvarchar](50) NULL,
        [Create_DTS] [datetime2](7) NOT NULL,
        [Updated_By] [nvarchar](50) NULL,
        [Update_DTS] [datetime2](7) NOT NULL
    );

    -- Loop through each month end
    WHILE @current_row <= @max_row
    BEGIN
        -- Get current month end date
        SELECT @current_month_end = MonthEnd
        FROM @month_ends
        WHERE RowNumber = @current_row;

        -- Populate temp table with current month-end snapshot data
        INSERT INTO #Temp_Table_Mcd_Order_Lines 
        SELECT 
            @current_month_end AS BucketDate,
            olv.Snapshot_DTS,
            olv.Order_Line_Date_ID,
            olv.Order_ID,
            olv.Order_SID,
            olv.Order_Line_ID,
            olv.Order_Line_SID,
            olv.order_line_number,
            olv.order_line_status_id,
            olv.order_line_status_code,
            olv.customer_id,
            olv.u_reuse_billing_account_sid,
            olv.u_new_billing_account,
            olv.account_sid,
            olv.account_number,
            olv.account_name,
            olv.commitment_term_id,
            olv.commitment_term_sid,
            olv.consumer_sid,
            olv.contact_sid,
            olv.periodicity_id,
            olv.periodicity_sid,
            olv.recurring_periodicity,
            olv.previous_product_model_sid,
            olv.price_list_sid,
            olv.priority_id,
            olv.priority_code,
            olv.product_id,
            olv.product_sid,
            olv.product_full_name,
            olv.product_offering_id,
            olv.product_offering_sid,
            olv.product_offering_type,
            olv.product_specification_sid,
            olv.u_billing_product_sid,
            olv.service_specification_sid,
            olv.location_sid,
            olv.shipping_location_sid,
            olv.parent_line_item_sid,
            olv.specification_sid,
            olv.top_line_item_sid,
            olv.u_customer_po_tracker_sid,
            olv.u_supplier_contract_sid,
            olv.pricing_method,
            olv.product_fullname,
            olv.sold_product_sid,
            olv.u_assigned_to_sid,
            olv.u_assignment_group_sid,
            olv.u_original_crm_product_id,
            olv.u_supplier_sid,
            olv.unit_of_measurement_sid,
            olv.unit_of_measurement_code,
            olv.unit_of_measurement_name,
            olv.effective_date,
            olv.expected_end_date,
            olv.expected_start_date,
            olv.expiration_date,
            olv.contract_start_date,
            olv.planned_end_date,
            olv.planned_start_date,
            olv.u_actual_completion_date,
            olv.u_billing_start_date,
            olv.u_billing_end_date,
            olv.u_committed_date,
            olv.u_customer_ordered_date,
            olv.u_estimated_completion_date,
            olv.u_supplier_ordered_date,
            olv.actual_end_date,
            olv.actual_start_date,
            olv.committed_due_date,
            olv.contract_end_date,
            olv.quantity,
            olv.cumulative_annual_recurring_price,
            olv.cumulative_monthly_recurring_price,
            olv.cumulative_one_time_price,
            olv.list_price,
            olv.mrc,
            olv.nrc,
            olv.total_discount,
            olv.total_one_time_charges,
            olv.total_one_time_price,
            olv.total_price,
            olv.total_recurring_charges,
            olv.total_recurring_price,
            olv.u_previous_unit_cost,
            olv.u_previous_unit_price,
            olv.u_total_contract_value,
            olv.u_total_cost,
            olv.u_total_one_time_cost,
            olv.u_total_recurring_cost,
            olv.u_unit_net_cost,
            olv.unit_price,
            olv.Load_DTS,
            olv.Created_By,
            olv.Create_DTS,
            olv.Updated_By,
            olv.Update_DTS
        FROM (
            SELECT 
                olv.*,
                ROW_NUMBER() OVER (
                    PARTITION BY olv.order_line_SID
                    ORDER BY olv.Update_DTS DESC
                ) AS rn
            FROM [mdl].[FACT_Order_Line_Values] olv
            WHERE olv.Update_DTS <= @current_month_end
        ) olv
        WHERE olv.rn = 1;

        -- Move to next month
        SET @current_row = @current_row + 1;
    END;

    -- Return results
    SELECT * 
    FROM #Temp_Table_Mcd_Order_Lines
    ORDER BY BucketDate, order_line_SID;

END;
GO