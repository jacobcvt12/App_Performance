.headers on
select company, version, rating, date, count(*) as count
from tableau_tbl
group by company, version, rating, date;
