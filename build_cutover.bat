echo on

Echo building cutover package...

mkdir "C:\Temp\deployment_config_1642_cutover_package\deployment_config_1642_cutover"
mkdir "C:\Temp\deployment_config_1642_cutover_package\deployment_config_1642_cutover\plugins"

xcopy "deployment_config_1642_cutover_package\deployment_config_1642_cutover\system_settings.*" "C:\Temp\deployment_config_1642_cutover_package\deployment_config_1642_cutover"
xcopy "deployment_config_1642_cutover_package\deployment_config_1642_cutover\plugins\*.zip" "C:\Temp\deployment_config_1642_cutover_package\deployment_config_1642_cutover\plugins"
xcopy "deployment_config_1642_cutover_package\*txt" "C:\Temp\deployment_config_1642_cutover_package"

cd "deployment_config_1642_cutover_package\deployment_config_1642_cutover\processes\"
"C:\Program Files\7-Zip\7z.exe" a -tzip "C:\Temp\deployment_config_1642_cutover_package\deployment_config_1642_cutover\processes.zip" "*.xml"

cd "..\process_templates\"
"C:\Program Files\7-Zip\7z.exe" a -tzip "C:\Temp\deployment_config_1642_cutover_package\deployment_config_1642_cutover\process_templates.zip" "*.xml"

cd "..\groovy_scripts\"
"C:\Program Files\7-Zip\7z.exe" a -tzip "C:\Temp\deployment_config_1642_cutover_package\deployment_config_1642_cutover\groovy_scripts.zip" "*"

cd "..\transformers\"
"C:\Program Files\7-Zip\7z.exe" a -tzip "C:\Temp\deployment_config_1642_cutover_package\deployment_config_1642_cutover\transformers.zip" "*"

"C:\Program Files\7-Zip\7z.exe" a -tzip "..\..\..\deployment_config_1642_cutover_package.zip" "C:\Temp\deployment_config_1642_cutover_package\*"

rmdir /S/Q "C:\Temp\deployment_config_1642_cutover_package"

echo Done!