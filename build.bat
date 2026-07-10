@echo off
set makensis="C:\Program Files (x86)\NSIS\makensis.exe"

md out
if exist %makensis% (
    %makensis% /V3 src\updater.nsi
) else (
    makensis /V3 src\updater.nsi
)