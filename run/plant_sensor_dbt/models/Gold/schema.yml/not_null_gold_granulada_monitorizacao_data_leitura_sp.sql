
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select data_leitura_sp
from "postgres"."public"."gold_granulada_monitorizacao"
where data_leitura_sp is null



  
  
      
    ) dbt_internal_test