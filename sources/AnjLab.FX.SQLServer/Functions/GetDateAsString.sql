if exists (select * from sysobjects where id = object_id(N'fx.GetDateAsString') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
drop function fx.GetDateAsString
GO
/*
<summary>
	Returns date as custom string in Russian.
</summary>

<author>
	Alex Zakharov
	Copyright © AnjLab 2008, http://anjlab.com. All rights reserved.
	The code can be used for free as long as this copyright notice is not removed.
<author>

<date>9\22\2007</date>

<param name="mode">
	0 - full date and time in Russian
	1 - full date in Russian
	2 - month and year in Russian
<mode>

<example>
	print fx.GetDateAsString(getDate(), 1)
</example>

*/

create function fx.GetDateAsString (@Date datetime, @Mode tinyint) returns nvarchar(100) AS

begin

declare @Result nvarchar(100)
declare @Months table (Id tinyint, name nvarchar(20))

if @Mode = 0 /* Полная дата*/ begin

	insert into @Months values(1, N'января')
	insert into @Months values(2, N'февраля')
	insert into @Months values(3, N'марта')
	insert into @Months values(4, N'апреля')
	insert into @Months values(5, N'мая')
	insert into @Months values(6, N'июня')
	insert into @Months values(7, N'июля')
	insert into @Months values(8, N'августа')
	insert into @Months values(9, N'сентября')
	insert into @Months values(10, N'октября')
	insert into @Months values(11, N'ноября')
	insert into @Months values(12, N'декабря')

	select @Result = cast(day(@Date) as nchar(2)) + N'  ' + name + N'  ' + cast(year(@Date) as nchar(4)) + N' г. ' 
		+ cast(datepart(hh, @Date) as nchar(2)) + N':' + cast(datepart(mi, @Date) as nchar(2))
	from @Months where Id = month(@Date)

end

IF @Mode = 1 /* Полная дата без времени*/ begin

	insert into @Months values(1, N'января')
	insert into @Months values(2, N'февраля')
	insert into @Months values(3, N'марта')
	insert into @Months values(4, N'апреля')
	insert into @Months values(5, N'мая')
	insert into @Months values(6, N'июня')
	insert into @Months values(7, N'июля')
	insert into @Months values(8, N'августа')
	insert into @Months values(9, N'сентября')
	insert into @Months values(10, N'октября')
	insert into @Months values(11, N'ноября')
	insert into @Months values(12, N'декабря')

	select @Result = cast(day(@Date) as nchar(2)) + N'  ' + name + N'  ' + cast(year(@Date) as nchar(4)) + N' г. ' 
	from @Months where Id = month(@Date)

end

IF @Mode = 2 /* Месяц в именительном падеже и год */
begin

	insert into @Months values(1, N'Январь')
	insert into @Months values(2, N'Февраль')
	insert into @Months values(3, N'Март')
	insert into @Months values(4, N'Апрель')
	insert into @Months values(5, N'Май')
	insert into @Months values(6, N'Июнь')
	insert into @Months values(7, N'Июль')
	insert into @Months values(8, N'Август')
	insert into @Months values(9, N'Сентябрь')
	insert into @Months values(10, N'Октябрь')
	insert into @Months values(11, N'Ноябрь')
	insert into @Months values(12, N'Декабрь')

	select @Result = name + N' ' + cast(year(@Date) as nchar(4)) from @Months where Id = month(@Date)

end

return @Result

end




