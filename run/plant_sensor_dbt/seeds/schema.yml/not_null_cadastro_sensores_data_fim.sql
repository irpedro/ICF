
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select data_fim
from "postgres"."public"."cadastro_sensores"
where data_fim is null



  
  
      
    ) dbt_internal_test