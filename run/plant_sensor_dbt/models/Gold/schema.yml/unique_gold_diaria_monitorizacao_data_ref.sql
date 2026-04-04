
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    data_ref as unique_field,
    count(*) as n_records

from "postgres"."public"."gold_diaria_monitorizacao"
where data_ref is not null
group by data_ref
having count(*) > 1



  
  
      
    ) dbt_internal_test