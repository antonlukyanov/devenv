require "libsys"

__ = sys.exec

home = os.getenv('LWDG_HOME')

__[[g++ -o ccalc.exe ccalc.cpp]]
__[[strip ccalc.exe]]
__("mv ccalc.exe " .. home.."/utils")
