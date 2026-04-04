
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select nome_planta
from "postgres"."public"."cadastro_sensores"
where nome_planta is null



  
  
      
    ) dbt_internal_test