--cоздание таблицы results
create table results (id int, response text);
--1. максимальное число пассажиров в бронированиях
create table task1 as select count(ticket_no) as maximum_persons_per_booking from tickets 
group by book_ref
order by maximum_persons_per_booking desc limit 1;
insert into results values(1, (select * from task1));
--2. количество бронирований с количеством людей больше среднего значения людей на одно бронирование
create table task2 as select sum(a.count_book_ref) as count_book_ref from (
select book_ref, count(distinct(book_ref)) as count_book_ref, count(ticket_no) as persons_per_booking  from tickets
group by book_ref
having count(ticket_no) > (select avg(a.countps) as average_persons_per_booking from (select count(ticket_no) as countps from tickets group by book_ref) a)
) a;
insert into results values(2, (select * from task2));
--3. количество бронирований, у которых состав пассажиров повторялся два и более раза, среди бронирований с максимальным количеством людей 
create table task3_1 as select *,count(passenger_id)over (partition by book_ref ) as cnt_pass from tickets  
 
create table task3_2 as select * from task3_1 where cnt_pass >= (select maximum_persons_per_booking from task1) 
 
create table task3_3 as select a.*,row_number()over (partition by book_ref order by passenger_id) as rn from task3_2 a 
where 1=1 and exists (select 1 from task3_2 b where b.passenger_id=a.passenger_id and a.book_ref!=b.book_ref) 
 
create table task3_final as select 3 as task_id, count(distinct book_ref) as cnt_5_pass from task3_3 
where rn =5 
  
insert into results select * from task3_final;

-- 4.номера брони и контактную информацию по пассажирам в брони с количеством людей в брони = 3 
create table task4 as select 4 as task_id,concat(book_ref,'|',passenger_id,'|', passenger_name,'|', contact_data) result_task_4 from task3_1  
where cnt_pass=3 
order by 2 
  
insert into results select * from task4;

-- 5. максимальное количество перелётов на бронь
create table task5_1 as select (count(distinct a.flight_id)) cnt_flight, b.book_ref from ticket_flights a 
left join tickets b on b.ticket_no=a.ticket_no  
group by book_ref 
  
create table task5_final as select 5 task_id,max(cnt_flight) result_task_5 from task5_1 
 
insert into results select * from task5_final;

-- 6. максимальное количество перелётов на пассажира в одной брони
create table task6 as select 6 task_id, count(distinct (flight_id)) as max_cnt_flights from ticket_flights a 
join tickets b on b.ticket_no=a.ticket_no 
group by passenger_name , b.book_ref
order by max_cnt_flights desc limit 1

insert into results select * from task6;

--7. максимальное количество перелётов на пассажира
create table task7 as select 7 task_id, count(distinct (flight_id)) as max_cnt_flights from ticket_flights a 
join tickets b on b.ticket_no=a.ticket_no 
group by passenger_id 
order by max_cnt_flights desc limit 1;
insert into results select * from task7;

--8. контактная информация по пассажиру(ам) и общие траты на билеты, для пассажира потратившему минимальное количество денег на перелеты

insert into results

select 8 task_id, concat(passenger_id, '|', passenger_name, '|', contact_data)
from
	(select passenger_id, passenger_name, contact_data, --sum(amount) s,
	rank() over(order by sum(amount)) rank_sum from tickets t1 
	join ticket_flights tf using(ticket_no)
	where amount is not null
	group by ticket_no) t2
where rank_sum = 1
order by passenger_id, passenger_name, contact_data;

--9. контактная информация по пассажиру(ам) и общее время в полётах, для пассажира, который провёл максимальное время в полётах

insert into results
select 9 as task_id, concat(passenger_id, '|', passenger_name, '|', contact_data, '|', sum_duration)
from
	(select passenger_id, passenger_name, contact_data, sum(actual_duration) sum_duration,
	rank() over(order by sum(actual_duration) desc) rank_sum_duration
	from tickets t1 
	join ticket_flights using(ticket_no)
	join flights_v using(flight_id)
	where actual_duration is not null
	group by ticket_no) t2
where rank_sum_duration = 1
order by passenger_id, passenger_name, contact_data;

--10. город(а) с количеством аэропортов больше одного

insert into results

select 10 task_id, city
from airports
group by city
having count(city) > 1
order by city;

--11. город(а), у которого самое меньшее количество городов прямого сообщения

create table task11 as 
	select departure_city, arrival_city,
	count(*) over(partition by departure_city order by departure_city) c
	from routes r
	group by departure_city, arrival_city

insert into results

select 11 task_id, departure_city 
from task11
where c = (select min(c) from task11)
order by departure_city;

--12. пары городов, у которых нет прямых сообщений исключив реверсные дубликаты

create table task12 as
	select distinct departure_city, arrival_city
	from routes

insert into results

select 12 task_id, concat(dc, '|', ac)
from(
	select t1.departure_city dc, t2.arrival_city ac
	from task12 t1, task12 t2
	where t1.departure_city < t2.arrival_city
	except
	select * from task12) t
order by dc, ac;

--13. города, до которых нельзя добраться без пересадок из Москвы

insert into results

select distinct 13 task_id, departure_city
from routes
where departure_city != 'Москва' 
and departure_city not in (
		select arrival_city from routes 
		where departure_city = 'Москва');
		
--14. модель самолета, который выполнил больше всего рейсов

create table task14 as(
	select aircraft_code, count(aircraft_code) c from flights_v
	where actual_departure is not null
	group by aircraft_code)

insert into results
	
select 14 task_id, model 
from aircrafts a 
join task14 using(aircraft_code)
where c = (select max(c) from task14);

--15. модель самолета, который перевез больше всего пассажиров

create table task15 as (
	select aircraft_code, count(aircraft_code) c from flights_v fv 
	join ticket_flights tf using(flight_id)
	where actual_departure is not null
	group by aircraft_code)

insert into results

select 15 task_id, model 
from aircrafts a 
join task15 using(aircraft_code)
where c = (select max(c) from task15);

--16. отклонение в минутах суммы запланированного времени перелета от фактического по всем перелётам
create table task16 (id int, sum int)
insert into task16 
select 16 task_id, extract(EPOCH from sum(scheduled_duration)-sum(actual_duration))/60 diff
from flights_v
where status='Arrived'
order by diff;

insert into results select * from task16

--17. города, в которые осуществлялся перелёт из Санкт-Петербурга 2016-09-13

insert into results

select 17 task_id, arrival_city from flights_v
where departure_city = 'Санкт-Петербург' and actual_departure::date = '2016-09-13'
order by arrival_city;

--18. перелёт(ы) с максимальной стоимостью всех билетов

insert into results

select 18 task_id, flight_id from
	(select flight_id, sum(amount) sum_amount,
	max(sum(amount)) over() max_sum_amount
	from ticket_flights tf
	group by flight_id) t
where sum_amount = max_sum_amount
order by flight_id;

--19. дни в которых было осуществлено минимальное количество перелётов

insert into results

select 19 task_id, date_departure from
	(select actual_departure::date date_departure, count(flight_id) count_flight, min(count(flight_id)) over() min_count_flight from flights f 
	where actual_departure is not null
	group by actual_departure::date) t
where count_flight = min_count_flight
order by date_departure; 

--20. среднее количество вылетов в день из Москвы за 09 месяц 2016 года

insert into results

select 20 task_id, avg(count_flights) avg_departure from 
	(select count(flight_id) count_flights
	from flights 
	where actual_departure is not null and date_trunc('month', actual_departure) = '2016-09-01' 
	group by actual_departure::date) t;

--21. топ 5 городов у которых среднее время перелета до пункта назначения больше 3 часов

with task21_1 as (
	select distinct departure_city,avg(actual_duration) over(partition by departure_city) avg_duration from flights_v
	where status='Arrived'
	order by avg_duration desc limit 5)
	
insert into results
	
select 21 task_id,departure_city from task21_1 where extract(epoch from avg_duration)/3600>3
order by departure_city   limit 5

--таблица results
select * from results r where 1=1 order by 1 asc;	