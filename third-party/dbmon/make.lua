require "libsys"

__ = sys.exec

home = os.getenv('LWDG_HOME')

__[[g++ -static -o DbMon.exe DbMon.cpp]]
__[[strip DbMon.exe]]
__("mv DbMon.exe " .. home.."/utils")
