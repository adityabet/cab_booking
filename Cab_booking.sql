create database `capstone`;
use `capstone`;

-- customers dataset
create table customers(
customer_id int primary key,
name varchar(30) not null,
phone bigint,
email varchar(40) not null,
reg_date Date
);

load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Customers.csv'
into table customers
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

-- Drivers dataset
create table Drivers(
driver_id int primary key,
name varchar(40) not null,
phone bigint,
licence_number varchar(30) unique,
rating decimal(3,2)
);

load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Drivers.csv'
into table Drivers
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

-- Cabs dataset
create table Cabs(
cab_id int primary key,
driver_id int not null,
car_model varchar(30) not null,
reg_number varchar(40) unique,
cab_type varchar(30) not null,
foreign key (driver_id) references Drivers(driver_id)
);

load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Cabs.csv'
into table Cabs
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

-- Bookings dataset
create table Bookings(
booking_id int primary key,
customer_id int not null,
cab_id int not null,
booking_time datetime not null,
pickup_location varchar(200) not null,
drop_location varchar(200) not null,
status varchar(30),
foreign key (customer_id) references Customers(customer_id),
foreign key (cab_id) references Cabs(cab_id)
);

load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Bookings.csv'
into table Bookings
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

-- TripDetails dataset
create table TripDetails(
trip_id int primary key,
booking_id int not null,
trip_start_time datetime not null,
trip_end_time datetime not null,
distance_km Decimal(5,2),
fare decimal(8,2),
foreign key (booking_id) references Bookings(booking_id)
);

load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\tripdetails.csv'
into table tripdetails
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

-- feedback dataset
create table Feedback(
feedback_id int primary key,
booking_id int not null,
rating int check(rating between 1 and 5), comments Text not null,
foreign key (booking_id) references Bookings(booking_id)
);

load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\Feedback.csv'
into table Feedback
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

-- Customer and Booking Analysis
/* 1. Identify customers who have completed the most bookings. What insights can you
draw about their behavior? */
select c.customer_id, c.name,
sum(Case when b.status = "Completed" then 1 else 0 end) as Completed_Booking
from Bookings as b
Join Customers as c
on c.customer_id = b.customer_id
group by c.customer_id, name 
order by Completed_booking desc
limit 5;

/* 2. Find customers who have canceled more than 30% of their total bookings. What
could be the reason for frequent cancellations? */
select c.customer_id, c.name,
sum(Case when b.status = "Cancelled" then 1 else 0 end) as Cancelled_Booking,
round(sum(case when b.status = "Cancelled" then 1 else 0 end) * 100.0 / Count(b.booking_id),2) as Percentage
from Bookings as b
Join Customers as c
on c.customer_id = b.customer_id
group by c.customer_id, name
having Percentage > 30
order by Percentage desc;

/* 3. Determine the busiest day of the week for bookings. How can the company optimize
cab availability on peak days?*/
select dayname(booking_time) as Day_of_week,
hour(booking_time) as Hours_of_time,
count(*) as total_booking
from Bookings
where status = "Completed"
group by Day_of_week, Hours_of_time
order by total_booking desc;

-- Driver Performance & Efficiency
/* 1. Identify drivers who have received an average rating below 3.0 in the past three
months. What strategies can be implemented to improve their performance?*/
Select d.driver_id, d.name, 
round(avg(d.rating),2) as Average_Rating
from Drivers as d
Join Cabs as c
on d.driver_id = c.driver_id
Join Bookings as b
on b.cab_id = c.cab_id
Join Feedback as f
on b.booking_id = f.booking_id
where b.booking_time >= curtime() - interval 3 month
group by d.driver_id, name
having Average_Rating > 3
order by Average_Rating asc;

/* 2. Find the top 5 drivers who have completed the longest trips in terms of distance. 
What does this say about their working patterns? */
Select d.driver_id, d.name, max(t.distance_km) as Distance_km
from Drivers as d
Join Cabs as c
on d.driver_id = c.driver_id
Join Bookings as b
on c.cab_id = b.cab_id 
Join Tripdetails as t
on b.booking_id = t.booking_id
group by d.driver_id, d.name 
order by Distance_km desc
limit 5;

/* 3. Identify drivers with a high percentage of canceled trips. Could this indicate driver 
unreliability? */
Select d.driver_id, d.name, 
concat(round(sum(Case when status = "Cancelled" then 1 else 0 end) * 100.0 / count(d.driver_id),0), '%')as Percentage
from Drivers as d
Join Cabs as c
on d.driver_id = c.driver_id
Join Bookings as b
on c.cab_id = b.cab_id
group by d.driver_id, d.name 
order by Percentage desc
limit 1;

-- Revenue & Business Metrics 
/* 1. Calculate the total revenue generated by completed bookings in the last 6 months. 
How has the revenue trend changed over time? */
Select sum(t.fare) as Total_Revenue
from Bookings as b
Join TripDetails as t
on b.booking_id = t.booking_id
where b.status = "Completed" and t.trip_end_time >= curdate() - interval 6 month;

/* 2. Identify the top 3 most frequently traveled routes based on PickupLocation and 
DropoffLocation. Should the company allocate more cabs to these routes? */
Select pickup_location, drop_location,
count(*) as Total_Trips
from Bookings
group by pickup_location, drop_location
order by Total_Trips desc
limit 3;

/* 3. Determine if higher-rated drivers trend to complete more trips and earn higher fares. 
Is there a direct correlation between driver ratings and earnings? */
Select d.driver_id, d.name,
round(avg(d.rating),2) as Average_Rating,
count(t.trip_id) as Total_Trips,
round(sum(t.fare),2) as Total_Fare
from Drivers as d
Join Cabs as c
on c.driver_id = d.driver_id
Join Bookings as b
on b.cab_id = c.cab_id
Join TripDetails as t
on t.booking_id = b.booking_id
where status = "Completed"
group by d.driver_id, d.name 
order by Average_Rating desc
limit 5;

-- Operational Efficiency & Optimization 
/* 1. Analyze the average waiting time (difference between booking time and trip start 
time) for different pickup locations. How can this be optimized to reduce delays? */
Select b.pickup_location,
concat(round(avg(timestampdiff(minute, booking_time, trip_start_time)),2)," min") as Waiting_Time
from Bookings as b
Join TripDetails as t 
on b.booking_id = t.booking_id
group by b.pickup_location
order by Waiting_time desc;

/* 2. Identify the most common reasons for trip cancellations from customer feedback. 
What actions can be taken to reduce cancellations? */
Select f.comments, count(*) as Total_Comments
from Feedback as f
Join Bookings as b
on f.booking_id = b.booking_id
where b.status = "Cancelled" and f.comments is not null
group by f.comments
order by Total_Comments desc
limit 5;

/* 3. Find out whether shorter trips (low-distance) contribute significantly to revenue. 
Should the company encourage more short-distance rides? */
Select 
Case when t.distance_km < 5 then 'Less Distance_km (<5)'
when t.distance_km between 5 and  15 then 'Medium Distance_km (>5)'
else 'More Distance_km (>5)' end as Trip_Distance,
sum(t.fare) as Total_Fare_Amount,
round(avg(t.fare),2) as Average_Fare_Amount
from TripDetails as t
Join Bookings as b
on t.booking_id = b.booking_id
where b.status = "Completed"
group by Trip_Distance
order by Total_Fare_Amount desc;

-- Comparative & Predictive Analysis 
/* 1. Compare the revenue generated from 'Sedan' and 'SUV' cabs. Should the company 
invest more in a particular vehicle type? */
Select c.cab_type, sum(t.fare) as Revenue
from TripDetails as t
Join Bookings as b
on b.booking_id = t.booking_id
Join Cabs as c
on c.cab_id = b.cab_id
where c.cab_type in ("SUV", "Sedan") and status = "Completed"
group by c.cab_type
order by Revenue desc;

/* 2. Predict which customers are likely to stop using the service based on their last 
booking date and frequency of rides. How can customer retention be improved?  */
Select c.customer_id, c.name,
count(b.booking_id) as Total_Bookings,
max(b.booking_time) as Max_Booking_Time,
Datediff(Curdate(), max(b.booking_time)) as Last_Booking
from Customers as c
Join Bookings as b
on c.customer_id = b.customer_id
group by c.customer_id, c.name
having Last_Booking > 30 
and Total_Bookings < 5
order by Last_Booking desc;

/* 3. Analyze whether weekend bookings differ significantly from weekday bookings. 
Should the company introduce dynamic pricing based on demand? */
Select 
Case when DayOfWeek(b.booking_time) in (1,7) then 'Weekend' else 'Weekday' end as DaysOfWeek,
count(*) as Total_bookings,
sum(t.fare) as Total_Revenue,
round(avg(t.fare),2) Average_Fare_Amount
from Bookings as b
Join TripDetails as t
on b.booking_id = t.booking_id
where status = "Completed"
group by DaysOfWeek
order by Average_Fare_Amount desc;






