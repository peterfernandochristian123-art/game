@echo off
title Push Project Retro Zero ke GitHub
cd /d "%~dp0"
echo ========================================================
echo  MENGUNGGAH SELURUH UPDATE KE GITHUB (origin/main)
echo ========================================================
echo.
echo Akun: peterfernandochristian123-art
echo Repositori: https://github.com/peterfernandochristian123-art/game.git
echo.
echo Menjalankan git push origin main...
echo (Jika muncul jendela browser atau pop-up GitHub, silakan klik Sign In / Authorize)
echo.
git push origin main
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================================
    echo  [SUKSES] SEMUA PERUBAHAN BERHASIL TERSIMPAN KE GITHUB!
    echo ========================================================
) else (
    echo.
    echo ========================================================
    echo  [GAGAL] Terjadi kendala saat push. Pastikan koneksi internet
    echo  dan izin akun GitHub Anda sudah terhubung.
    echo ========================================================
)
echo.
pause
