require "libsys"

__ = sys.exec

home = os.getenv('LWDG_HOME')

__[[gcc -o wkill.exe wkill.c]]
__[[gcc -o wps.exe wps.c]]
__[[strip wkill.exe wps.exe]]
__("mv wkill.exe wps.exe " .. home.."/utils")
