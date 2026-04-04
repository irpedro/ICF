
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select id
from "postgres"."public"."gold_granulada_monitorizacao"
where id is null



  
  
      
    ) dbt_internal_test