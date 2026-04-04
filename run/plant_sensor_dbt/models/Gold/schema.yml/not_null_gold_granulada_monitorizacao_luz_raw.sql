
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select luz_raw
from "postgres"."public"."gold_granulada_monitorizacao"
where luz_raw is null



  
  
      
    ) dbt_internal_test