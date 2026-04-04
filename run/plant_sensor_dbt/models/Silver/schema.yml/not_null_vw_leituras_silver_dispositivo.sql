
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select dispositivo
from "postgres"."public"."vw_leituras_silver"
where dispositivo is null



  
  
      
    ) dbt_internal_test