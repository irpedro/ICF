
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select nome_cientifico
from "postgres"."public"."gold_granulada_monitorizacao"
where nome_cientifico is null



  
  
      
    ) dbt_internal_test