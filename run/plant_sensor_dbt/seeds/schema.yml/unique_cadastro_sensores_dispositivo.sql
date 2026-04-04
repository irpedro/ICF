
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    dispositivo as unique_field,
    count(*) as n_records

from "postgres"."public"."cadastro_sensores"
where dispositivo is not null
group by dispositivo
having count(*) > 1



  
  
      
    ) dbt_internal_test