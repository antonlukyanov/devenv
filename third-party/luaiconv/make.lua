require "libsys"

__ = sys.exec

home = os.getenv('LWDG_HOME')

__("pexports " .. home .. "/share/libiconv2.dll >libiconv2.def" )
__[[dlltool --def libiconv2.def --dllname libiconv2.dll --output-lib libiconv2.a]]
__("g++ -static --shared -DLUA_BUILD_AS_DLL -I" .. home .. "/include -I../lua-addons/iconv  -L" .. home .. "/lib -o luaiconv.dll luaiconv.c libiconv2.a -llua52")
__[[strip luaiconv.dll]]
__[[rm libiconv2.def libiconv2.a]]
__("mv luaiconv.dll " .. home .. '/share')
