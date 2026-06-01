@echo off
mkdir reports 2>nul

echo Running All Tests...
call maestro test e2e/logintestcases/ -e Mobile_Number=1617539764 -e Password=Password100@ --format html --output reports/01_login_report.html
call maestro test e2e/homescreentestcase/ -e Mobile_Number=1617539764 -e Password=Password100@ --format html --output reports/02_home_report.html
call maestro test e2e/notificationtestcase/ -e Mobile_Number=1617539764 -e Password=Password100@ --format html --output reports/03_notification_report.html
call maestro test e2e/topuptestcase/ -e Mobile_Number=1617539764 -e Password=Password100@ --format html --output reports/04_topup_report.html
call maestro test e2e/transactiontestcase/ -e Mobile_Number=1617539764 -e Password=Password100@ --format html --output reports/05_transaction_report.html
call maestro test e2e/sendcryptocashout/ -e Mobile_Number=1617539764 -e Password=Password100@ --format html --output reports/06_sendcrypto_report.html

echo All Tests Completed!
pause