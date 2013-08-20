SYS := $(shell gcc -dumpmachine)
CC = gcc
OPTIMIZATION = -O3

CFLAGS = -lm -ldl -lpthread -lz -lssl -lcrypto $(HARDMODE)
ifeq (, $(findstring linux, $(SYS)))
CFLAGS = -liconv -lm -ldl -lpthread -lz -lssl -lcrypto $(HARDMODE)
endif

DEBUG = -g -ggdb

ifeq ($(LUAJIT),)
ifeq ($(LUA),)
LIBLUA = -llua -L/usr/lib -L/usr/local/lib
else
LIBLUA = -L$(LUA) -llua
endif
else
LIBLUA = -L$(LUAJIT) -lluajit-5.1
endif

ifndef $(PREFIX)
PREFIX = /usr/local/alilua
endif

INCLUDES=-I/usr/local/include -I/usr/local/include/luajit-2.0

all: alilua

alilua : main.o
	$(CC)  objs/*.o -o $@ $(CFLAGS) $(DEBUG) $(LIBLUA)

main.o:
	[ -d objs ] || mkdir objs;
	cd objs && $(CC) -c ../common/*.c $(CFLAGS) $(DEBUG) $(LIBLUA) $(INCLUDES);
	cd objs && $(CC) -c ../se/*.c $(CFLAGS) $(DEBUG) $(LIBLUA) $(INCLUDES);
	cd objs && $(CC) -c ../src/*.c $(CFLAGS) $(DEBUG) $(LIBLUA) $(INCLUDES);
	cd objs && $(CC) -c ../deps/*.c $(CFLAGS) $(DEBUG) $(LIBLUA) $(INCLUDES);
	cd objs && $(CC) -c ../deps/yac/*.c $(CFLAGS) $(DEBUG) $(LIBLUA) $(INCLUDES);
	cd objs && $(CC) -c ../deps/fastlz/*.c $(CFLAGS) $(DEBUG) $(LIBLUA) $(INCLUDES);
	cd objs && $(CC) -c ../coevent/*.c $(CFLAGS) $(DEBUG) $(LIBLUA) $(INCLUDES);

	cd lua-libs/LuaBitOp-1.0.2 && make && cp bit.so ../ && make clean;
	cd lua-libs/lua-cjson-2.1.0 && make && cp cjson.so ../ && make clean;
	cd lua-libs/lzlib && make && cp zlib.so ../ && make clean;


.PHONY : clean zip install noopt hardmode

clean:
	rm -rf objs
	rm -rf alilua
	rm -rf lua-libs/*.so

zip:
	git archive --format zip --prefix alilua/ -o alilua-`git log --date=short --pretty=format:"%ad" -1`.zip HEAD

install:all
	$(MAKE) DEBUG=$(OPTIMIZATION);
	strip alilua;
	[ -d $(PREFIX) ] || mkdir $(PREFIX);
	[ -d $(PREFIX)/lua-libs ] || mkdir $(PREFIX)/lua-libs;
	! [ -f $(PREFIX)/alilua ] || mv $(PREFIX)/alilua $(PREFIX)/alilua.old
	cp alilua $(PREFIX)/
	cp script.lua $(PREFIX)/
	cp alilua-index.lua $(PREFIX)/
	[ -f $(PREFIX)/host-route.lua ] || cp host-route.lua $(PREFIX)/
	cp lua-libs/*.lua $(PREFIX)/lua-libs/
	cp lua-libs/*.so $(PREFIX)/lua-libs/

noopt:
	$(MAKE) OPTIMIZATION=""

hardmode:
	$(MAKE) HARDMODE="-std=c99 -pedantic -Wall"