require "libsys"

__ = sys.exec

home = os.getenv('LWDG_HOME')

__[[gcc -static -o jpeg2ps.exe asc85ec.c getopt.c jpeg2ps.c readjpeg.c]]
__[[strip jpeg2ps.exe]]
__("mv jpeg2ps.exe " .. home.."/utils")
