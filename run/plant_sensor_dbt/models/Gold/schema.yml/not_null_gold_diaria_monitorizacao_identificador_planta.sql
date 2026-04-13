
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select identificador_planta
from "postgres"."public"."gold_diaria_monitorizacao"
where identificador_planta is null



  
  
      
    ) dbt_internal_test