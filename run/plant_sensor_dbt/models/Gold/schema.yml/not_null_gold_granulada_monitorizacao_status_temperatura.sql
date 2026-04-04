
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select status_temperatura
from "postgres"."public"."gold_granulada_monitorizacao"
where status_temperatura is null



  
  
      
    ) dbt_internal_test