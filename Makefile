
UNAME_S := $(shell uname -s 2>/dev/null || echo unknown)
UNAME_O := $(shell uname -o 2>/dev/null || echo unknown)

ifdef DEBUG
CFLAGS = -O0 -g -Wextra -DMEMDEBUG -DSTRBUF_CHECK
#LDFLAGS = -lefence
LDFLAGS += -g
else
CFLAGS = -O2
endif

ifdef NO_ICONV
CFLAGS += -DNO_ICONV
endif

LIBS = -lz
ZIP_OBJS =
ifdef USE_KUNZIP
	CFLAGS += -DUSE_KUNZIP
	ZIP_OBJS = kunzip/fileio.o kunzip/zipfile.o
else
	LIBS += -lzip
endif

OBJ = odt2txt.o regex.o mem.o strbuf.o $(ZIP_OBJS)
TEST_OBJ = t/test-strbuf.o t/test-regex.o
ALL_OBJ = $(OBJ) $(TEST_OBJ)

INSTALL = install
GROFF   = groff

DESTDIR = /usr/local
PREFIX  =
BINDIR  = $(PREFIX)/bin
MANDIR  = $(PREFIX)/share/man
MAN1DIR = $(MANDIR)/man1

ifeq ($(UNAME_S),FreeBSD)
	CFLAGS += -DICONV_CHAR="const char" -I/usr/local/include
	LDFLAGS += -L/usr/local/lib
	LIBS += -liconv
endif
ifeq ($(UNAME_S),OpenBSD)
	CFLAGS += -DICONV_CHAR="const char" -I/usr/local/include
	LDFLAGS += -L/usr/local/lib
	LIBS += -liconv
endif
ifeq ($(UNAME_S),Darwin)
       CFLAGS += -I/opt/local/include
       LDFLAGS += -L/opt/local/lib
       LIBS += -liconv
endif
ifeq ($(UNAME_S),NetBSD)
	CFLAGS += -DICONV_CHAR="const char"
endif
ifeq ($(UNAME_S),SunOS)
	ifeq ($(CC),cc)
		ifdef DEBUG
			CFLAGS = -v -g -DMEMDEBUG -DSTRBUF_CHECK
		else
			CFLAGS = -xO3
		endif
	endif
	CFLAGS += -DICONV_CHAR="const char"
endif
ifeq ($(UNAME_S),HP-UX)
	CFLAGS += -I$(ZLIB_DIR)
	LIBS = $(ZLIB_DIR)/libz.a
endif
ifeq ($(UNAME_O),Cygwin)
	CFLAGS += -DICONV_CHAR="const char"
	LIBS += -liconv
	EXT = .exe
endif
ifeq ($(UNAME_O),Msys)
	CFLAGS += -I/mingw$(ARCH)/lib/libzip/include
	LIBS += -liconv -llibzip -lzip -lz -L/mingw$(ARCH)/lib
	EXT = .exe
endif
ifneq ($(MINGW32),)
	CFLAGS += -I$(REGEX_DIR) -I$(ZLIB_DIR) -I$(ICONV_DIR)/include/ -I$(LIBZIP_DIR)/lib/
	LIBS = $(REGEX_DIR)/regex.o
	ifdef STATIC
		CFLAGS += -DZIP_STATIC
		LIBS += $(wildcard $(ICONV_DIR)/lib/.libs/*.o)
		LIBS += $(LIBZIP_DIR)/lib/.libs/libzip.a
		LIBS += $(ZLIB_DIR)/libz.a
	else
		LIBS += -liconv
	endif
	EXT = .exe
endif

BIN = odt2txt$(EXT)
MAN = odt2txt.1

$(BIN): $(OBJ)
	$(CC) -o $@ $(LDFLAGS) $(OBJ) $(LIBS)

t/test-strbuf: t/test-strbuf.o strbuf.o mem.o
t/test-regex: t/test-regex.o regex.o strbuf.o mem.o

$(ALL_OBJ): Makefile

all: $(BIN)
	@if [ -n "$(USE_KUNZIP)" ] ; then \
		echo '' ; \
		echo ' Please use libzip (http://www.nih.at/libzip) instead of' ; \
		echo ' kunzip. It is a much more complete zip library and has' ; \
		echo ' much better handling for exotic and/or broken documents.' ; \
		echo '' ; \
	fi

install: $(BIN) $(MAN)
	$(INSTALL) -d -m755 $(DESTDIR)$(BINDIR)
	$(INSTALL) $(BIN) $(DESTDIR)$(BINDIR)
	$(INSTALL) -d -m755 $(DESTDIR)$(MAN1DIR)
	$(INSTALL) $(MAN) $(DESTDIR)$(MAN1DIR)

odt2txt.html: $(MAN)
	$(GROFF) -Thtml -man $(MAN) > $@

odt2txt.ps: $(MAN)
	$(GROFF) -Tps -man $(MAN) > $@

clean:
	rm -fr $(OBJ) $(BIN) odt2txt.ps odt2txt.html

.PHONY: clean

