select a,b,c
from tablea
join tableb on ( tablea.a=tableb.a)
join tablec on ( tablec.a=tableb.a)
left outer join tabled on ( tabled.a=tableb.a)
left join tablee on ( tabled.a=tableb.a)
where tablea.x = 1 and tableb.y=1
group by tablea.a, tablec.c
order by tablea.a, tablec.c;


