
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select temperatura_media_c
from "postgres"."public"."gold_diaria_monitorizacao"
where temperatura_media_c is null



  
  
      
    ) dbt_internal_test