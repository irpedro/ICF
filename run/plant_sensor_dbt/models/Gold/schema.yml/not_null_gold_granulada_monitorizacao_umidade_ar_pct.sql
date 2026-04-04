
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select umidade_ar_pct
from "postgres"."public"."gold_granulada_monitorizacao"
where umidade_ar_pct is null



  
  
      
    ) dbt_internal_test