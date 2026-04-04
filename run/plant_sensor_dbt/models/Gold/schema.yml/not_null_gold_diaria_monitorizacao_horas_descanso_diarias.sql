
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select horas_descanso_diarias
from "postgres"."public"."gold_diaria_monitorizacao"
where horas_descanso_diarias is null



  
  
      
    ) dbt_internal_test