
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select status_saude_luminosa
from "postgres"."public"."gold_diaria_monitorizacao"
where status_saude_luminosa is null



  
  
      
    ) dbt_internal_test