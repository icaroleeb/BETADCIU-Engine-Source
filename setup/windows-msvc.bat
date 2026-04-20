@REM @echo off
@REM color 0a
@REM cd ..
@REM @echo on
@REM echo Installing Microsoft Visual Studio Community (Dependency)
@REM curl -# -O https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe
@REM vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 -p
@REM del vs_Community.exe
@REM echo Finished.
@REM pause

@echo off
color 0a
cd ..
@echo on
echo Installing Microsoft Visual Studio Community (Dependency)
curl -L -o vs_Community.exe https://aka.ms/vs/17/release/vs_Community.exe

vs_Community.exe ^
 --wait ^
 --nocache ^
 --installPath "%ProgramFiles%\Microsoft Visual Studio\2022\Community" ^
 --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ^
 --add Microsoft.VisualStudio.Component.Windows10SDK.19041
del vs_Community.exe

echo Finished.
pause