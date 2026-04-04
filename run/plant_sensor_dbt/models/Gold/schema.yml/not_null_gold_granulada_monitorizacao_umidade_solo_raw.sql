
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select umidade_solo_raw
from "postgres"."public"."gold_granulada_monitorizacao"
where umidade_solo_raw is null



  
  
      
    ) dbt_internal_test