
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select temperatura_c
from "postgres"."public"."vw_leituras_silver"
where temperatura_c is null



  
  
      
    ) dbt_internal_test