/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================

if OBJECT_ID('Gold.dim_customers','V') is not null
Drop view Gold.dim_customers
GO
create view Gold.dim_customers as(
select 
ROW_NUMBER() over(order by cst_id) as 'Customer_key',
ci.cst_id as 'Customer_id',
ci.cst_key as'Customer_number',
ci.cst_firstname as 'First_name',
ci.cst_lastname as 'Last_name',
la.cntry as 'Country',
ci.cst_marital_status as 'Marital_status',
case when ci.cst_gndr !='N/A' then ci.cst_gndr
else coalesce(ca.gen,'N/A')
end as Gender,
ca.bdate as 'Birthdate',
ci.cst_create_date as 'Create_date'

from Silver.crm_cust_info ci 
left join Silver.erp_cust_az12 ca
on        ci.cst_key=ca.cid
left join Silver.erp_loc_a101 la
on        ci.cst_key=la.cid )

GO
--By checking the table as it contains customer info so it is a dimensional table
if OBJECT_ID('Gold.dim_products','V') is not null
Drop view Gold.dim_products
GO
create view  Gold.dim_products as

select 
ROW_NUMBER() over (order by pn.prd_start_dt, pn.prd_key) as 'Product_key',
pn.prd_id as 'Product_id',
pn.prd_key as 'Product_number',
pn.prd_nm as 'Product_name',
pn.cat_id as 'Category_id',
pc.cat as 'Category',
pc.subcat as 'Subcategory',
pc.maintenance,
pn.prd_cost as 'Cost',
pn.prd_line as 'Product_line',
pn.prd_start_dt as'Start_date'
from Silver.crm_prd_info as pn 
Left join Silver.erp_PX_CAT_G1V2 as pc on pn.cat_id=pc.id
where prd_end_dt is NULL --Filter out all historical data
GO

--It is a dimensional table
if OBJECT_ID('Gold.fact_sales','V') is not null
Drop view Gold.fact_sales
GO
create view Gold.fact_sales as 
select 
sd.sls_ord_num as 'order_number',
pr.Product_key,
cu.Customer_key,
sd.sls_order_dt as 'order_date',
sd.sls_ship_dt as 'Shipping_date',
sd.sls_due_dt as 'due_date',
sd.sls_sales as 'sales_amount',
sd.sls_quantity as 'quantity',
sd.sls_price as 'price'
from Silver.crm_sales_details sd
left join Gold.dim_products pr 
on sd.sls_prd_key = pr.Product_number
left join Gold.dim_customers cu
on sd.sls_cust_id=cu.Customer_id
GO
--we can see lot of transactions, events and dates so it is a fact table.
--It is connecting with multiple dimensiona tables.
--use the dimensions surrogate keys instead of IDs to easily connect facts with dimensions.
