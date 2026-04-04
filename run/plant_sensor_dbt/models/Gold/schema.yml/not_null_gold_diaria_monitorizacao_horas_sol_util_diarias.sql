
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select horas_sol_util_diarias
from "postgres"."public"."gold_diaria_monitorizacao"
where horas_sol_util_diarias is null



  
  
      
    ) dbt_internal_test