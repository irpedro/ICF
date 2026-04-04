
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select planta_monitorizada
from "postgres"."public"."gold_granulada_monitorizacao"
where planta_monitorizada is null



  
  
      
    ) dbt_internal_test