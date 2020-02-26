echo on

Echo building postgres package...

mkdir "C:\Temp\deployment_config_1642_postgres_package\deployment_config_1642_postgres"
mkdir "C:\Temp\deployment_config_1642_postgres_package\deployment_config_1642_postgres\emd"

xcopy "deployment_config_1642_postgres_package\deployment_config_1642_postgres\emd\*.xml" "C:\Temp\deployment_config_1642_postgres_package\deployment_config_1642_postgres\emd"
xcopy "deployment_config_1642_postgres_package\*txt" "C:\Temp\deployment_config_1642_postgres_package"

cd "deployment_config_1642_postgres_package\deployment_config_1642_postgres\processes\"
"C:\Program Files\7-Zip\7z.exe" a -tzip "C:\Temp\deployment_config_1642_postgres_package\deployment_config_1642_postgres\processes.zip" "*.xml"

cd "..\process_templates\"
"C:\Program Files\7-Zip\7z.exe" a -tzip "C:\Temp\deployment_config_1642_postgres_package\deployment_config_1642_postgres\process_templates.zip" "*.xml"

"C:\Program Files\7-Zip\7z.exe" a -tzip "..\..\..\deployment_config_1642_postgres_package.zip" "C:\Temp\deployment_config_1642_postgres_package\*"

rmdir /S/Q "C:\Temp\deployment_config_1642_postgres_package"

echo Done!