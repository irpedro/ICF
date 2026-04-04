
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select data_ref
from "postgres"."public"."gold_diaria_monitorizacao"
where data_ref is null



  
  
      
    ) dbt_internal_test