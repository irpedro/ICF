
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select taxa_cobertura_dados_pct
from "postgres"."public"."gold_diaria_monitorizacao"
where taxa_cobertura_dados_pct is null



  
  
      
    ) dbt_internal_test