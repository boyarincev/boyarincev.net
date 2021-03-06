@echo off

setlocal enabledelayedexpansion

SET ARTIFACTS=%~dp0%artifacts

IF NOT DEFINED DEPLOYMENT_SOURCE (
  SET DEPLOYMENT_SOURCE=%~dp0%.
)

IF NOT DEFINED DEPLOYMENT_TARGET (
  SET DEPLOYMENT_TARGET=%ARTIFACTS%\wwwroot
)

echo Start - Building the Snow Site
echo Running Snow.exe config=%DEPLOYMENT_SOURCE%\Snow\

pushd %DEPLOYMENT_SOURCE%
call  .\Snow\_compiler\Snow.exe config=.\Snow\

IF !ERRORLEVEL! NEQ 0 goto error

mkdir %DEPLOYMENT_SOURCE%\Website\feed
copy %DEPLOYMENT_SOURCE%\Website\feed.xml %DEPLOYMENT_SOURCE%\Website\feed\index.xml

mkdir %DEPLOYMENT_SOURCE%\Website\rss
copy %DEPLOYMENT_SOURCE%\Website\rss.xml %DEPLOYMENT_SOURCE%\Website\rss\index.xml

IF NOT DEFINED NEXT_MANIFEST_PATH (
  SET NEXT_MANIFEST_PATH=%ARTIFACTS%\manifest

  IF NOT DEFINED PREVIOUS_MANIFEST_PATH (
    SET PREVIOUS_MANIFEST_PATH=%ARTIFACTS%\manifest
  )
)

echo Setting up Kudu Sync

IF NOT DEFINED KUDU_SYNC_COMMAND (
  :: Install kudu sync
  echo Installing Kudu Sync
  call npm install kudusync -g --silent
  IF !ERRORLEVEL! NEQ 0 goto error

  :: Locally just running "kuduSync" would also work
  SET KUDU_SYNC_COMMAND=node "%appdata%\npm\node_modules\kuduSync\bin\kuduSync"
)


echo Kudu Sync from "%DEPLOYMENT_SOURCE%\Website" to "%DEPLOYMENT_TARGET%"
call %KUDU_SYNC_COMMAND% -q -f "%DEPLOYMENT_SOURCE%\Website" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.deployment;deploy.cmd" 2>nul
IF !ERRORLEVEL! NEQ 0 goto error

goto end

:error
echo An error has occured during web site deployment.
exit /b 1

:end
echo Finished successfully.