exec Silver.load_silver
Create or alter procedure Silver.load_silver as
Begin
print'--------------------------------------------------'
print'>>Loading Silver Layer.......'
print'--------------------------------------------------'
print'>>Loading crm Tables'
declare @start_time datetime, @end_time datetime, @batch_start_time datetime, @batch_end_time datetime
set @batch_start_time =getdate();
set @start_time=getdate();
print'>>Truncate data from crm_cust_info Table'
truncate table Silver.crm_cust_info;
print'>>Inserting values into Silver.crm_cust_info'
Insert into Silver.crm_cust_info(
cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_marital_status,
cst_gndr,
cst_create_date
)

select cst_id
      ,cst_key
      ,trim(cst_firstname) as cst_firstname
      ,trim(cst_lastname) as cst_lastname
      ,
	  case when upper(trim(cst_marital_status))='S' then 'Single'
	  when upper(trim(cst_marital_status))='M' then 'Married'
	  else 'N/A'
	  end cst_marital_status
      ,
	  Case 
	  when upper (trim(cst_gndr))='M' then 'Male'
	  when upper(trim(cst_gndr))='F' then 'Female'
	  else 'N/A'
	  End cst_gndr
      ,cst_create_date
	 
from (
select *,row_number() over( partition by cst_id order by cst_create_date desc) as flag_last from Bronze.crm_cust_info where cst_id is not null )t where flag_last =1
print'========================================================================'
set @end_time =getdate();
print'>> Load Duration for table Silver.crm_cust_info: '+cast(datediff(second,@start_time,@end_time)as nvarchar)+'Seconds';
print'========================================================================'
-----------------------------------------------------------------------------------------------------------

--Quick Summary here i have performed cleaning operation 
--1 i have removed extra space from all the values in the column
--2 Handling missing values like null to N/A 
--3 i have removed the duplicate data from the table so that it ensure only one record per entity which makes the every row relevant.
--as we are removing duplicate which means we are doing data filtering
set @start_time=getdate();
print'truncate data from crm_prd_info Table'
truncate table Silver.crm_prd_info;
print'Inserting values into Silver.crm_prd_info'
insert into Silver.crm_prd_info(
        prd_id
	  ,cat_id
      ,prd_key
      ,prd_nm
      ,prd_cost
      ,prd_line
      ,prd_start_dt
      ,prd_end_dt)

SELECT prd_id
	  ,REPLACE (SUBSTRING(prd_key,1,5),'-','_') as cat_id -- here we are extracting category id from prd_key
	  ,SUBSTRING(prd_key,7,Len(prd_key)) as prd_key --by using len() we are assigning value dynamically based on the length.
      ,prd_nm
      ,ISNULL (prd_cost,0) as prd_cost
      ,case
	   when upper(trim(prd_line))='M' then 'Mountain'
	   when upper(trim(prd_line))='R' then 'Road'
	   when upper(trim(prd_line))='S' then 'other sales'
	   when upper(trim(prd_line))='T' then 'Touring'
	   ELSE 'N/A'
	   end as prd_line
	  ,cast(prd_start_dt as date) as prd_start_dt
      ,cast(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt)-1 as date ) as  prd_end_dt
  FROM [Datawarehouse].[Bronze].[crm_prd_info] 

print'========================================================================'
set @end_time =getdate();
print'>> Load Duration for table Silver.crm_prd_info: '+cast(datediff(second,@start_time,@end_time)as nvarchar)+'Seconds';
print'========================================================================'
  --Here i have created a new column from the existing column as it was containing two type of data in one column.
  --I have used Isnull to handle the missing values or null values.
  --I have performed data normalization like removing low cardinality from the column
  --I have changed the data type using cast() function.
  set @start_time=getdate();
print'truncate data from crm_sales_details'
truncate table Silver.crm_sales_details;
print'Inserting values into Silver.crm_sales_details'
  insert into Silver.crm_sales_details(
  sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,sls_order_dt
      ,sls_ship_dt
      ,sls_due_dt
      ,sls_sales
      ,sls_quantity
      ,sls_price
	  )
   SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,case when sls_order_dt=0 or len(sls_order_dt) !=8 then null
	   else cast(cast(sls_order_dt as varchar)as date)
	   end as sls_order_dt
	  
      ,case
	  when sls_ship_dt=0 or len(sls_ship_dt)!=8 then null
	  else cast(cast(sls_ship_dt as varchar) as date)
	  end as sls_ship_dt
      ,case 
	  when sls_due_dt=0 or len(sls_due_dt)!=8  then null
	  else cast(cast(sls_due_dt as varchar) as date)
	  end as sls_due_dt
      ,case 
	  when sls_sales is null or sls_sales<=0 or sls_sales!= sls_quantity* abs(sls_price)
	   then sls_quantity* abs(sls_price)
	  else sls_sales end as sls_sales
      ,sls_quantity
      ,case when sls_price is null or sls_price<=0  
	  then sls_sales/nullif(sls_quantity,0)
	  else sls_price
	  end as sls_price
  FROM [Datawarehouse].[Bronze].[crm_sales_details]

print'========================================================================'
set @end_time =getdate();
print'>> Load Duration for table Silver.crm_sales_details: '+cast(datediff(second,@start_time,@end_time)as nvarchar)+'Seconds';
print'========================================================================'
 
  --select distinct sls_sales, sls_quantity, sls_price from Silver.crm_sales_details where sls_sales!= sls_quantity * sls_price or sls_sales is null or sls_price is null
  --or sls_quantity is null or sls_sales<=0 or sls_quantity<=0  or sls_price <=0 order by sls_sales, sls_quantity, sls_price
 

  --Here i have changed the datatype using cast() function 
  --Derived correct value using other columns and replaced null or value 0 with relevant values
print'--------------------------------------------------'
print'>>Loading erp Tables'
  set @start_time=getdate();
  print'truncate data from silver.erp_cust_az12'
truncate table silver.erp_cust_az12;
print'Inserting values into silver.erp_cust_az12'
  insert into silver.erp_cust_az12(cid
      ,bdate
      ,gen)
  select 
	   case when cid like 'NAS%' then SUBSTRING(cid,4,len(cid)) 
	   else cid
	   end as cid
      ,case when bdate > GETDATE() then null
	  else bdate
	  end as bdate
      ,case when upper(trim(gen)) in ('M','Male') then 'Male'

	  when upper(trim(gen)) in ('F','Female') then 'Female'
	  else 'N/A'
	  end as gen
  FROM [Datawarehouse].[Bronze].[erp_cust_az12]


print'========================================================================'
set @end_time =getdate();
print'>> Load Duration for table silver.erp_cust_az12: '+cast(datediff(second,@start_time,@end_time)as nvarchar)+'Seconds';
print'========================================================================'
  --here i have removed some unwanted character from the column cid 
  --also validated date column by checking if the date is greater than current date if is greater then assign null to it.
  -- also i have done data normalization
  set @start_time=getdate();
  print'truncate data from Silver.erp_loc_a101'
truncate table Silver.erp_loc_a101;
print'Inserting values into Silver.erp_loc_a101'
Insert into Silver.erp_loc_a101(
cid,cntry
)
SELECT  replace(cid,'-','')as cid
      ,case when upper(trim(cntry)) in ('US','USA') then 'United States'
	  when upper(trim(cntry))='DE' then 'Germany'
	  when upper(trim(cntry))=''or cntry is null then 'N/A'

	  else trim(cntry)
	  end as cntry
  FROM [Datawarehouse].[Bronze].[erp_loc_a101]

print'========================================================================'
set @end_time =getdate();
print'>> Load Duration for table Silver.erp_loc_a101: '+cast(datediff(second,@start_time,@end_time)as nvarchar)+'Seconds';
print'========================================================================'
  --Here we have removed some unwanted characters 
  --performed data normalization
  set @start_time=getdate();
print'truncate data from silver.erp_PX_CAT_G1V2'
truncate table silver.erp_PX_CAT_G1V2;
print'Inserting values into silver.erp_PX_CAT_G1V2'
 insert into silver.erp_PX_CAT_G1V2(
  id
      ,cat
      ,subcat
      ,maintenance
 )
  SELECT id
      ,cat
      ,subcat
      ,maintenance
  FROM [Datawarehouse].[Bronze].[erp_PX_CAT_G1V2] 
  set @end_time=getdate();
  --Here we have not performed any operation because it is passing all the validation checks.
print'========================================================================'
set @end_time =getdate();
print'>> Load Duration for table  silver.erp_PX_CAT_G1V2: '+cast(datediff(second,@start_time,@end_time)as nvarchar)+'Seconds';
print'========================================================================'
 set @batch_end_time=getdate();
 print'>>Total Batch loading time taken: '+cast(datediff(second, @batch_start_time ,@batch_end_time)as nvarchar)+'Seconds';
 End
