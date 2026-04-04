
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select luz_par_ppfd
from "postgres"."public"."gold_granulada_monitorizacao"
where luz_par_ppfd is null



  
  
      
    ) dbt_internal_test