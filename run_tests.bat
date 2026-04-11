@echo off
mkdir reports 2>nul

echo Running Login Test...
call maestro test e2e/logintestcases/login_with_valid_cred.yaml -e Mobile_Number=1617539764 -e Password=Password100@ --format html --output reports/01_login_report.html

echo Running Homescreen Test...
call maestro test e2e/homescreentestcase/homescreen.yaml -e Mobile_Number=1617539764 -e Password=Password100@ --format html --output reports/02_homescreen_report.html

echo Running Notification Test...
call maestro test e2e/notificationtestcase/notification.yaml -e Mobile_Number=1617539764 -e Password=Password100@ --format html --output reports/03_notification_report.html

echo Running Crypto Test...
call maestro test e2e/topuptestcase/cryptotestcase.yaml -e Mobile_Number=1617539764 -e Password=Password100@ --format html --output reports/04_cryptotestcase_report.html

echo Running Crypto Request Test...
call maestro test e2e/topuptestcase/cryptorequest.yaml -e Mobile_Number=1617539764 -e Password=Password100@ --format html --output reports/05_cryptorequest_report.html

echo Running Zigift Card Test...
call maestro test e2e/topuptestcase/zigiftcard.yaml -e Mobile_Number=1617539764 -e Password=Password100@ --format html --output reports/06_zigiftcard_report.html

echo Running Transaction Test...
call maestro test e2e/transactiontestcase/transaction.yaml -e Mobile_Number=1617539764 -e Password=Password100@ --format html --output reports/07_transaction_report.html

echo Running Crypto Cashout Test...
call maestro test e2e/sendcryptocashout/cryptocashout.yaml -e Mobile_Number=1617539764 -e Password=Password100@ --format html --output reports/08_cryptocashout_report.html

echo Running Wallets Send Money Test...
call maestro test e2e/sendcryptocashout/wallets_sendmoney.yaml -e Mobile_Number=1617539764 -e Password=Password100@ --format html --output reports/09_wallets_report.html

echo ✅ All Tests Completed!
pause