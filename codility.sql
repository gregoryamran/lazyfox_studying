create table players (
      player_id integer not null unique,
      group_id integer not null
  );

  create table matches (
      match_id integer not null unique,
      first_player integer not null,
      second_player integer not null,
      first_score integer not null,
      second_score integer not null
  );

insert into players values(20, 2);
insert into players values(30, 1);
insert into players values(40, 3);
insert into players values(45, 1);
insert into players values(50, 2);
insert into players values(65, 1);
insert into matches values(1, 30, 45, 10, 12);
insert into matches values(2, 20, 50, 5, 5);
insert into matches values(13, 65, 45, 10, 10);
insert into matches values(5, 30, 65, 3, 15);
insert into matches values(42, 45, 65, 8, 4);


 
with grp_plyr_scr as 
(
	select 
		p.group_id,
		p.player_id,
		sum(coalesce( m1.first_score , 0  )) as score 		
	from 
	players p
	left join matches m1 on first_player  = p.player_id
	group by p.group_id  , p.player_id 	
	union all
	select 
		p.group_id,
		p.player_id,		
		sum(coalesce( m2.second_score  , 0  )) as score
	from 
	players p
	left join matches m2 on m2.second_player = p.player_id
	group by p.group_id  , p.player_id 
) 
,
final_cte as (
	select 
	g.group_id ,
	g.player_id, 
	sum(g.score) , 
	row_number() over( partition by group_id order by sum(score) desc , player_id  asc) rnk 
	from grp_plyr_scr g	
	group by g.group_id , g.player_id 
)
select * from final_cte where rnk=1 order by group_id  ;





CREATE TABLE candidates (
    id SERIAL PRIMARY KEY,
    position VARCHAR(50),
    salary DECIMAL(10, 2)
);

INSERT INTO candidates (position, salary)
VALUES
    ('senior', 60000.00),
    ('senior', 55000.00),
    ('senior', 65000.00),
    ('junior', 30000.00),
    ('junior', 35000.00),
    ('senior', 70000.00),
    ('junior', 32000.00),
    ('senior', 60000.00),
    ('junior', 33000.00);


with candidates_partitioned as (
 SELECT
        id,
        position,
        salary,
        sum(salary) over (
          partition by position
            order by salary asc
            rows between unbounded preceding and current row
        ) as running_expenses
    FROM candidates 
),
target_candidates as (
    SELECT
        id,
        position,
        salary
    FROM candidates_partitioned
    WHERE position = 'senior' and running_expenses <= 300000
    UNION ALL 
    SELECT
        id,
        position,
        salary
    FROM candidates_partitioned 
    WHERE position = 'junior' and running_expenses <= (
        SELECT 300000 - COALESCE(MAX(running_expenses), 0) 
        FROM candidates_partitioned
        WHERE running_expenses <= 300000 and position = 'senior'
    )
)
--select * from target_candidates
SELECT 
   coalesce(position, 'total') as position,
   count(id) as employee_count,
   sum(salary) as gross_salary
FROM target_candidates
GROUP BY ROLLUP(position)
ORDER BY position

;


CREATE TABLE cookbook_titles (
    page_number int ,
    title VARCHAR(50) 
);

truncate table cookbook_titles;


INSERT INTO cookbook_titles (page_number, title)
values 
	( 1 , 'Scrambled eggs' ),
	( 2 , 'Fondue' ),
	( 3 , 'Sandwich' ),
	( 4 , 'Tomato soup' ),
	( 6 , 'Liver soup' ),
	( 7 , 'Carrot soup' ),
	( 8 , 'Onion soup' )
	;
 

INSERT INTO cookbook_titles (page_number, title)
values 
	( 9 , 'Fried chicken' )
	;


INSERT INTO cookbook_titles (page_number, title)
values 
	( 12 , 'Fried duck' ),
	( 15 , 'Baked chicken' )
	;

select * from cookbook_titles ;


with cte as (
        select 
        (row_number() over() -1 ),
        2 *(row_number() over()-1) lt,
        2 *(row_number() over()-1)+ 1 rt
        from
        cookbook_titles
        )
select lt as left_page_number, 
       (select title from cookbook_titles where page_number = lt)left_title,
       (select title from cookbook_titles where page_number = rt)right_title
from cte

;

with series as
(	select	generate_series as page_number
	from	generate_series(0, 
                          	(select max(page_number) from cookbook_titles)
                           )
)
--select * from series ;
,
cookbook_titles_v2 as
(
	select
		s.page_number,
		(s.page_number /2 ) ,
		c.title
	from
		series s
	left join cookbook_titles c on
		s.page_number = c.page_number
)
select * from cookbook_titles_v2 ;
 
select
	(row_number() over( order by page_number / 2)-1)* 2 as left_page_number,
	(row_number() over( order by page_number / 2)-1)* 2 +1 as right_page_number,
	string_agg(case when page_number % 2 = 0 then title end, ',') as left_title,
	string_agg(case when page_number % 2 = 1 then title end, ',') as right_title
from
	cookbook_titles_v2
group by
	page_number /2 

	;
	
	
with t as(select
    (row_number() over (order by page_number)-1)*2 as left_page_number
,    (row_number() over (order by page_number)-1)*2+1 as left_page_numbe2
from cookbook_titles)
select left_page_number,
left_page_numbe2,
        t1.title as left_title,
        t2.title as right_title
from t left join cookbook_titles t1 on t.left_page_number=t1.page_number
       left join cookbook_titles t2 on t.left_page_number+1=t2.page_number	

       
       
Create table products(ProductName VARCHAR(100), Price INT, Quantity INT) ;

truncate table products;

Insert into products values ('Pencil',3,20) ;
Insert into products values ('Rubber',4,5)  ; 
Insert into products values ('Scale',15,4)  ; 

Insert into products values ('Notebook', 110 , 3 )  ;
Insert into products values ('Bag', 10 ,4  )  ;

select * from products ;



with computed_total_price as 
( 
	SELECT  p.* , qty2  , sum(price) over( order by price, qty2 ) as total_price 
	FROM   generate_series( 1  , (select sum(Quantity) from products  ) ) qty2
	CROSS JOIN 
	products p
	where 
	p.Quantity >= qty2	
	order by productname, qty2
)
select count(qty2) from computed_total_price
where total_price <= 100 

;


Create table transactions(date date , amount  INT ) ;

INSERT INTO transactions(Amount,Date) VALUES (1000,'2020-01-06');
INSERT INTO transactions(Amount,Date) VALUES (-10,'2020-01-14');
INSERT INTO transactions(Amount,Date) VALUES (-75,'2020-01-20');
INSERT INTO transactions(Amount,Date) VALUES (-5,'2020-01-25');
INSERT INTO transactions(Amount,Date) VALUES (-4,'2020-01-29');
INSERT INTO transactions(Amount,Date) VALUES (2000,'2020-03-10');
INSERT INTO transactions(Amount,Date) VALUES (-75,'2020-03-12');
INSERT INTO transactions(Amount,Date) VALUES (-20,'2020-03-15');
INSERT INTO transactions(Amount,Date) VALUES (40,'2020-03-15');
INSERT INTO transactions(Amount,Date) VALUES (-50,'2020-03-17');
INSERT INTO transactions(Amount,Date) VALUES (200,'2020-10-10');
INSERT INTO transactions(Amount,Date) VALUES (-200,'2020-10-10');

