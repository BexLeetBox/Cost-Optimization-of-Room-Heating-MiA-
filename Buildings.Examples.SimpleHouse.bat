@echo off
SET PATH=C:/Program Files/OpenModelica1.24.4-64bit/bin/;C:/Program Files/OpenModelica1.24.4-64bit/lib//omc;C:/Program Files/OpenModelica1.24.4-64bit/lib/;C:/Users/47973/AppData/Roaming/.openmodelica/binaries/Modelica;C:/Users/47973/AppData/Roaming/.openmodelica/libraries/Modelica 4.0.0+maint.om/Resources/Library/ucrt64;C:/Users/47973/AppData/Roaming/.openmodelica/libraries/Modelica 4.0.0+maint.om/Resources/Library/win64;C:/Users/47973/AppData/Roaming/.openmodelica/libraries/Modelica 4.0.0+maint.om/Resources/Library;C:/Program Files/OpenModelica1.24.4-64bit/bin/;%PATH%;
SET ERRORLEVEL=
CALL "%CD%/Buildings.Examples.SimpleHouse.exe" %*
SET RESULT=%ERRORLEVEL%

EXIT /b %RESULT%
