
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select flg_origem_dados_confiavel
from "postgres"."public"."gold_granulada_monitorizacao"
where flg_origem_dados_confiavel is null



  
  
      
    ) dbt_internal_test