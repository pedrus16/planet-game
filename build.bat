"C:\Program Files\7-zip\7z.exe" a "build\mario.zip" ".\dist\*"
copy /b "C:\Program Files\LOVE\love.exe"+"build\mario.zip" build\mario.exe
del .\build\mario.zip
