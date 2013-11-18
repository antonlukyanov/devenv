-- Скрипт отключает автозапуск для всех съемных носителей.
-- Скрипт необходимо запускать с правами администратора.

run = os.execute

run( 
  "reg add HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\policies\\Explorer " ..
  "/v NoDriveTypeAutoRun " ..
  "/t REG_DWORD " ..
  "/d 0x000000ff " ..
  "/f"
)
