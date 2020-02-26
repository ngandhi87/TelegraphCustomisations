echo on

Echo building dual running package...

mkdir "C:\Temp\deployment_config_1642_dual_running_package\deployment_config_1642_dual_running"

xcopy "deployment_config_1642_dual_running_package\deployment_config_1642_dual_running\*_system_settings.*" "C:\Temp\deployment_config_1642_dual_running_package\deployment_config_1642_dual_running"
xcopy "deployment_config_1642_dual_running_package\deployment_config_1642_dual_running\system_settings.*" "C:\Temp\deployment_config_1642_dual_running_package\deployment_config_1642_dual_running"
xcopy "deployment_config_1642_dual_running_package\*txt" "C:\Temp\deployment_config_1642_dual_running_package"

cd "deployment_config_1642_dual_running_package\deployment_config_1642_dual_running\processes"
"C:\Program Files\7-Zip\7z.exe" a -tzip "C:\Temp\deployment_config_1642_dual_running_package\deployment_config_1642_dual_running\processes.zip" "*.xml"

cd "..\process_templates\"
"C:\Program Files\7-Zip\7z.exe" a -tzip "C:\Temp\deployment_config_1642_dual_running_package\deployment_config_1642_dual_running\process_templates.zip" "*.xml"

cd "..\groovy_scripts\"
"C:\Program Files\7-Zip\7z.exe" a -tzip "C:\Temp\deployment_config_1642_dual_running_package\deployment_config_1642_dual_running\groovy_scripts.zip" "*"

cd "..\transformers\"
"C:\Program Files\7-Zip\7z.exe" a -tzip "C:\Temp\deployment_config_1642_dual_running_package\deployment_config_1642_dual_running\transformers.zip" "*"

"C:\Program Files\7-Zip\7z.exe" a -tzip "..\..\..\deployment_config_1642_dual_running_package.zip" "C:\Temp\deployment_config_1642_dual_running_package\*"

rmdir /S/Q "C:\Temp\deployment_config_1642_dual_running_package"

echo Done!