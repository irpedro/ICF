
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select status_umidade_solo
from "postgres"."public"."gold_granulada_monitorizacao"
where status_umidade_solo is null



  
  
      
    ) dbt_internal_test