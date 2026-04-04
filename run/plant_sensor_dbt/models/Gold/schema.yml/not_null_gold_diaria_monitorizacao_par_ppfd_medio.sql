
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select par_ppfd_medio
from "postgres"."public"."gold_diaria_monitorizacao"
where par_ppfd_medio is null



  
  
      
    ) dbt_internal_test