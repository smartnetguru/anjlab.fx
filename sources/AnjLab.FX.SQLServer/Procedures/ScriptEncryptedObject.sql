if exists (select * from sysobjects where id = object_id(N'fx.ScriptEncryptedObject') and xtype in (N'P'))
drop procedure fx.ScriptEncryptedObject
go
/*
<summary>
	Decrypt SQL Server stored procedures, functions, views, and triggers
</summary>

<remarks>
	HEADS UP: In order to run this script you must log in
	to the server in DAC mode: To do so, type
	ADMIN:<SQLInstanceName> as your server name and use the "sa"
	or any other server admin user with the appropriate password.
	
	Remote DAC should be enabled with
	
	sp_configure 'remote admin connections', 1
	reconfigure
                       
	CAUTION! DAC (dedicated admin access) will kick out all other
	server users.
                        
	The script below accepts an object (schema name + object name)
	that were created using the WITH ENCRYPTION option and returns
	the decrypted script that creates the object. This script
	is useful to decrypt stored procedures, views, functions,
	and triggers that were created WITH ENCRYPTION.
                        
	The algorithm used below is the following:
	1. Check that the object exists and that it is encrypted.

	2. In order to decrypt the object, the script ALTER (!!!) it
	and later restores the object to its original one. This is
	required as part of the decryption process: The object
	is altered to contain dummy text (the ALTER uses WITH ENCRYPTION)
	and then compared to the CREATE statement of the same dummy
	content. 
                        
	Note: The object is altered in a transaction, which is rolled
	back immediately after the object is changed to restore
	all previous settings.
                        
	3. A XOR operation between the original binary stream of the
	enrypted object with the binary representation of the dummy
	object and the binary version of the object in clear-text
	is used to decrypt the original object.
</remarks>					 

<author>
	Based on code of
	Omri Bahat

	Copyright � SQL Farms Solutions, http://www.sqlfarms.com. All rights reserved.
	This code can be used only for non-redistributable purposes.
	The code can be used for free as long as this copyright notice is not removed.
</author>

<date>01/01/2007</date>

<param name="Schema">Object's schema name</param>
<param name="Object">Encrypted object name</param>
<param name="PrintResult">Flag to determine should resulted script be printed to output</param>
<param name="Result">DDL statement</param>


<example>
	exec fx.ScriptEncryptedObject N'fx', N'EncryptedExample'
</example>

*/

if exists (select * from sysobjects where id = object_id(N'fx.EncryptedExample') and xtype in (N'P'))
drop procedure fx.EncryptedExample
go

create procedure fx.EncryptedExample with encryption as
begin
	print N'This is a message from decrypted object'
end
go

create procedure fx.ScriptEncryptedObject 
( 
	@Schema sysname = N'fx', 
	@Object sysname = N'EncryptedExample',
	@PrintResult bit = 1,
	@Result nvarchar(max) = null output
) as
begin

	set nocount on

	declare 
		@i                            int,
		@ObjectDataLength             int,
		@ContentOfDecryptedObject     nvarchar(max),
		@ContentOfFakeObject          nvarchar(max),
		@ContentOfFakeEncryptedObject nvarchar(max),
		@TextToPrint nvarchar(max),
		@ObjectType                   nvarchar(128),
		@ObjectID                     int

	set @ObjectID = object_id('[' + @Schema + '].[' + @Object + ']')

	-- Check that the provided object exists in the database.
	if @ObjectID is null
	begin
		raiserror('Specified object or schema does not exist in the database', 16, 1)
		return -1
	end

	-- Check that the provided object is encrypted.
	if not exists(select top 1 * from syscomments where id = @ObjectID and encrypted = 1)
	begin
		raiserror('Specified object exists however it is not encrypted.', 16, 1)
		return -1
	end

	-- Determine the type of the object
	if object_id('[' + @Schema + '].[' + @Object + ']', 'PROCEDURE') is not null
		set @ObjectType = 'procedure'
	else
		if object_id('[' + @Schema + '].[' + @Object + ']', 'TRIGGER') is not null
			set @ObjectType = 'trigger'
		else
			if object_id('[' + @Schema + '].[' + @Object + ']', 'VIEW') is not null
				set @ObjectType = 'view'
			else
				set @ObjectType = 'function'

	/*
	 Get the binary representation of the object- syscomments no longer holds
	 the content of encrypted object.
	*/
	select top 1 @Result = imageval
	from sys.sysobjvalues
	where objid = object_id('[' + @Schema + '].[' + @Object + ']')
			and valclass = 1 and subobjid = 1

	set @Objectdatalength = datalength(@Result)/2

	/*
	 We need to alter the existing object and make it into a dummy object
	 in order to decrypt its content. This is done in a transaction
	 (which is later rolled back) to ensure that all changes have a minimal
	 impact on the database.
	*/

	set @ContentOfFakeObject = N'alter ' + @ObjectType + N' [' + @Schema + N'].[' + @Object + N'] with encryption as'

	while datalength(@ContentOfFakeObject)/2 < @Objectdatalength
	begin
			if datalength(@ContentOfFakeObject)/2 + 4000 < @Objectdatalength
					set @ContentOfFakeObject = @ContentOfFakeObject + replicate(N'-', 4000)
			else
					set @ContentOfFakeObject = @ContentOfFakeObject + replicate(N'-', @Objectdatalength - (datalength(@ContentOfFakeObject)/2))
	end

	-- Since we need to alter the object in order to decrypt it, this is done in a transaction
	set xact_abort off
	begin tran

	exec(@ContentOfFakeObject)

	if @@error <> 0 rollback tran

	-- Get the encrypted content of the new "fake" object.
	select top 1 @ContentOfFakeEncryptedObject = imageval
	from sys.sysobjvalues
	where objid = object_id('[' + @Schema + '].[' + @Object + ']')
			and valclass = 1 and subobjid = 1

	if @@trancount > 0 rollback tran

	-- Generate a CREATE script for the dummy object text.
	set @ContentOfFakeObject = N'create ' + @ObjectType + N' [' + @Schema + N'].[' + @Object + N'] with encryption as'

	while datalength(@ContentOfFakeObject)/2 < @Objectdatalength
	begin
			if datalength(@ContentOfFakeObject)/2 + 4000 < @Objectdatalength
					set @ContentOfFakeObject = @ContentOfFakeObject + replicate(N'-', 4000)
			else
					set @ContentOfFakeObject = @ContentOfFakeObject + replicate(N'-', @Objectdatalength - (datalength(@ContentOfFakeObject)/2))
	end


	set @i = 1

	--Fill the variable that holds the decrypted data with a filler character
	set @ContentOfDecryptedObject = space(0)

	while datalength(@ContentOfDecryptedObject)/2 < @Objectdatalength
	begin
			if datalength(@ContentOfDecryptedObject)/2 + 4000 < @Objectdatalength
					set @ContentOfDecryptedObject = @ContentOfDecryptedObject + replicate(N'A', 4000)
			else
					set @ContentOfDecryptedObject = @ContentOfDecryptedObject + replicate(N'A', @Objectdatalength - (datalength(@ContentOfDecryptedObject)/2))
	end


	while @i <= @Objectdatalength
	begin
			--xor real & fake & fake encrypted
			set @ContentOfDecryptedObject = stuff(@ContentOfDecryptedObject, @i, 1,
					nchar(
							unicode(substring(@Result, @i, 1)) ^
							(
									unicode(substring(@ContentOfFakeObject, @i, 1)) ^
									unicode(substring(@ContentOfFakeEncryptedObject, @i, 1))
							)))

			set @i = @i + 1
	end

	-- Print the content of the decrypted object
	if @PrintResult = 1 
	begin
		set @TextToPrint = @Result

		while charindex(nchar(10), @TextToPrint) - 1 > 0
		begin
			print substring(@TextToPrint, 1, charindex(nchar(10), @TextToPrint) - 1)
			set @TextToPrint = substring(@TextToPrint, charindex(nchar(10),@TextToPrint) + 1, len(@TextToPrint) - (charindex(nchar(10),@TextToPrint)) )
		end	
		print @TextToPrint
	end

	return 0


end