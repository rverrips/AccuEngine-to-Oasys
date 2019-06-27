@echo Off
echo -- Script to update data from AccuEngine to Oasys by Roy Verrips (roy@verrips.org) > sqlite.sql
echo -- Last considerable code update 30 May 2012 by roy@verrips.org >> sqlite.sql
echo.
echo * Requires sqlite3.exe to reside in the same directory, and bcp and sqlcmd to be installed in the path
echo.
echo * AccuEngine-to-Oasys runs a seven step process *
echo * 1 - generates the script to run using echo to sqlite.sql*
echo * 2 - established the date-time variables *
echo * 3 - renames the dataout.txt file to dataout-records.txt *
echo * 4 - Runs bcp.exe SQL script to get the employee card and employee number output to emp_master.txt *
echo * 5 - Runs the sqlite script sqlite.sql and produces output of time cards records into timecards.txt *
echo * 6 - Runs sqlcmd.exe with SQL script from time_cards.sql to update the data *
echo * 7 - Deletes dataout-records.txt, sqlite.sql, emp_master.txt, timecards.txt*
echo.
echo * Checks Dependancies *
If NOT exist sqlite3.exe echo "Please install sqlite3.exe from http://sqlite.org into the path" & pause & exit
If NOT exist "c:\Program Files\Microsoft SQL Server\90\Tools\Binn\bcp.exe" echo "Please install bcp.exe from Microsoft SQL Server" & pause & exit
If NOT exist "c:\Program Files\Microsoft SQL Server\90\Tools\Binn\sqlcmd.exe" echo "Please install sqlcmd.exe from Microsoft SQL Server" & pause & exit
echo.
echo * 1 - Generating the sqlite.sql script *
echo.
echo -- 1.  Create Table (time_records) for the dataout file >> sqlite.sql
echo create table time_records (data_record TEXT); >> sqlite.sql
echo -- 2.  Create Table (emp_master) for Employee Codes (emp_code) and Card Numbers (fin_code) >> sqlite.sql
echo create table emp_master (emp_code TEXT, fin_code TEXT); >> sqlite.sql
echo -- 3.  Create Table (time_cards) for the data to output >> sqlite.sql
echo create table time_cards (emp_code TEXT, tx_date DATE, tx_type TEXT, machine_id TEXT); >> sqlite.sql
echo .bail on >> sqlite.sql
echo .separator "," >> sqlite.sql
echo .import dataout-records.txt time_records >> sqlite.sql
echo .import emp_master.txt emp_master >> sqlite.sql
echo alter table time_records ADD COLUMN fin_code TEXT; >> sqlite.sql
echo alter table time_records ADD COLUMN tx_date TEXT; >> sqlite.sql
echo alter table time_records ADD COLUMN tx_type TEXT; >> sqlite.sql
echo alter table time_records ADD COLUMN machine_id TEXT; >> sqlite.sql
echo delete from time_records where length(data_record) ^< 32; >> sqlite.sql
echo update time_records set fin_code = substr(data_record, 31, 10); >> sqlite.sql
echo update time_records set tx_date = '20'^|^|substr(data_record, 10, 2)^|^|'-'^|^|substr(data_record, 12, 2)^|^|'-'^|^|substr(data_record, 14, 2)^|^|' '^|^|substr(data_record, 16, 2)^|^|':'^|^|substr(data_record, 18, 2); >> sqlite.sql
echo update time_records set tx_type = substr(data_record, 23, 1); >> sqlite.sql
echo update time_records set machine_id = substr(data_record, 23, 1); >> sqlite.sql
echo update time_records set tx_type = "I" where tx_type = 1; >> sqlite.sql
echo update time_records set tx_type = "O" where tx_type = 4; >> sqlite.sql
echo .mode insert time_cards >> sqlite.sql
echo .output timecards.txt >> sqlite.sql
echo select emp_master.emp_code,time_records.tx_date,time_records.tx_type,NULL,NULL,time_records.machine_id from time_records inner join emp_master on emp_master.fin_code=time_records.fin_code; >> sqlite.sql
echo -- End of Sqlite Script >> sqlite.sql
echo.
echo * 2 - Establishing Date / Time Varibles *
For /f "tokens=1-4 delims=/ " %%a in ('date /t') do (set usedate=%%d%%b%%c)
For /f "tokens=1-3 delims=/: " %%a in ('time /t') do (set usetime=%%c%%a%%b)
echo.
echo * 3 - Renaming the datafile *
ren dataout.txt dataout-records.txt
echo.
echo * 3b - Making a backup copy of the datafile *
copy dataout-records.txt processed\dataout_%usedate%%usetime%.txt
echo.
echo * 4 - Running bcp.exe SQL script to get the employee card and employee number output to emp_master.txt *
bcp "Select emp_code, fin_code from Oasys2009_SC.dbo.emp_master where fin_code is Not NULL;" queryout "emp_master.txt" -S S-EU-H7507-BO\Oasys -U vicas -P vicas -T -c -t,
echo.
echo * 5 - Runs the sqlite script sqlite.sql and produces output of time cards records into timecards.txt *
sqlite3 < sqlite.sql
echo.
echo * 6 - Runs sqlcmd.exe with SQL script from time_cards.sql to update the data *
echo.
sqlcmd -S S-EU-H7507-BO\Oasys -U %sqlpassword% -P %sqlusername% -d OASYS2009_SC -itimecards.txt
echo * 7 - Deletes dataout-records.txt, sqlite.sql, emp_master.txt, timecards.txt*
echo.
del dataout-records.txt sqlite.sql emp_master.txt timecards.txt
exit
