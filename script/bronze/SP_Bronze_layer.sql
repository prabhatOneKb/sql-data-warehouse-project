USE [Datawarehouse]
GO
/****** Object:  StoredProcedure [Bronze].[load_bronze]    Script Date: 09-08-2026 14:23:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec bronze.load_bronze
Create or ALTER   procedure [Bronze].[load_bronze] as

BEGIN 
Declare @start_time datetime, @end_time datetime, @batch_start_time datetime, @batch_end_time datetime;
BEGIN TRY
print '======================================================';
print 'loading Bronze Layer';
print '======================================================';

print '------------------------------------------------------';
print 'Loading CRM tables'
print '------------------------------------------------------';
set @batch_start_time=GETDATE();
set @start_time= GETDATE();
print '>> Truncating table: Bronze.crm_cust_info';
Truncate table Bronze.crm_cust_info
print '>> Inserting data into: Bronze.crm_cust_info';
Bulk insert Bronze.crm_cust_info
from'C:\project_DE\Data Engineering\Data_Warehous-project\source_crm\cust_info.csv'
with (
firstrow=2,
fieldterminator=',',
Tablock
);
set @end_time= GETDATE();
print'>> Load Duration for table Bronze.crm_cust_info: '+ cast(datediff(second,@start_time, @end_time)as nvarchar)+'seconds';
print '------------------------------------------------------';
set @start_time= GETDATE();
print '>> Truncating table: Bronze.crm_prd_info';
Truncate table Bronze.crm_prd_info
print '>> Inserting data into: Bronze.crm_prd_info';
Bulk insert Bronze.crm_prd_info
from'C:\project_DE\Data Engineering\Data_Warehous-project\source_crm\prd_info.csv'
with (
firstrow=2,
fieldterminator=',',
Tablock
);
set @end_time= GETDATE();
print'>> Load Duration for table Bronze.crm_prd_info: '+ cast(datediff(second,@start_time, @end_time) as nvarchar)+'seconds';
print '------------------------------------------------------';
set @start_time= GETDATE();
print '>> Truncating table: Bronze.crm_sales_details';
Truncate table Bronze.crm_sales_details
print '>> Inserting data into: Bronze.crm_sales_details';
Bulk insert Bronze.crm_sales_details
from'C:\project_DE\Data Engineering\Data_Warehous-project\source_crm\sales_details.csv'
with (
firstrow=2,
fieldterminator=',',
Tablock
);

set @end_time= GETDATE();
print'>> Load Duration for table Bronze.crm_sales_details: '+ cast(datediff(second,@start_time, @end_time)as nvarchar)+'seconds';

print '------------------------------------------------------';
print 'Loading ERP tables'
print '------------------------------------------------------';

set @start_time= GETDATE();
print '>> Truncating table: Bronze.erp_cust_az12';
Truncate table Bronze.erp_cust_az12
print '>> Inserting data into: Bronze.erp_cust_az12';
Bulk insert Bronze.erp_cust_az12
from'C:\project_DE\Data Engineering\Data_Warehous-project\source_erp\CUST_AZ12.csv'
with (
firstrow=2,
fieldterminator=',',
Tablock
);

set @end_time= GETDATE();
print'>> Load Duration for table Bronze.erp_cust_az12: '+ cast(datediff(second,@start_time, @end_time)as nvarchar)+'seconds';
print '------------------------------------------------------';
set @start_time= GETDATE();
print '>> Truncating table: Bronze.erp_loc_a101';
Truncate table Bronze.erp_loc_a101
print '>> Inserting data into: Bronze.erp_loc_a101';
Bulk insert Bronze.erp_loc_a101
from'C:\project_DE\Data Engineering\Data_Warehous-project\source_erp\LOC_A101.csv'
with (
firstrow=2,
fieldterminator=',',
Tablock
);
set @end_time= GETDATE();
print'>> Load Duration for table Bronze.erp_loc_a101: '+ cast(datediff(second,@start_time, @end_time)as nvarchar)+'seconds';
print '------------------------------------------------------';
set @start_time= GETDATE();
print '>> Truncating table: Bronze.erp_PX_CAT_G1V2';
Truncate table Bronze.erp_PX_CAT_G1V2
print '>> Inserting data into: Bronze.erp_PX_CAT_G1V2';
Bulk insert Bronze.erp_PX_CAT_G1V2
from'C:\project_DE\Data Engineering\Data_Warehous-project\source_erp\PX_CAT_G1V2.csv'
with (
firstrow=2,
fieldterminator=',',
Tablock
);

set @end_time= GETDATE();
print'>> Load Duration for table Bronze.erp_PX_CAT_G1V2: '+ cast(datediff(second,@start_time, @end_time)as nvarchar)+'seconds';
print '------------------------------------------------------';
set @batch_end_time=GETDATE();
print 'Loading Bronze Layer'
print 'Load time for whole process: '+ cast(datediff(second,@batch_start_time,@batch_end_time) as nvarchar)+'seconds';
print '------------------------------------------------------';
END TRY
BEGIN CATCH
print'====================================================='
print'ERROR'
print'====================================================='
Print'ERROR_MESSAGE:'+ ERROR_MESSAGE();
Print'ERROR_MESSAGE:'+ Cast(ERROR_NUMBER() as nvarchar);
Print'ERROR_MESSAGE:'+ Cast(ERROR_STATE() as nvarchar);
print'====================================================='
END CATCH
END
