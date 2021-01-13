PRAGMA foreign_keys = ON;
.echo off
.mode col
.headers on
.nullvalue NULL

.w 5 12 12 20 10 10 4 25
select Title, FirstName, LastName, Email, Phone, Birthday, Age,
    Address from Clients; 
