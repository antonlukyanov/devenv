require "libsys"

__ = sys.exec

home = os.getenv('LWDG_HOME')

__[[gcc -static -o mimetex.exe -DAA -DWINDOWS mimetex.c gifsave.c]]
__[[strip mimetex.exe]]
__("mv mimetex.exe " .. home.."/utils")
