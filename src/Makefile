# PerceptVala makefile
# Written by Leszek Godlewski <github@inequation.org>

# =============================================================================
# Configuration
# Feel free to change any of these, as long as you know what you're doing.
# =============================================================================

# path to make
MAKE = make
# mkdir command with arguments to create all missing directories in the path
MKDIR_P = mkdir -p
# path to the Vala compiler
VALAC = valac
# path to the valadoc documentation generator
VALADOC = valadoc
# valac/valadoc flags that define the packages to use
VALAPKGFLAGS = --pkg gtk+-3.0 --pkg cairo --pkg pango --pkg gee-1.0
# valac flags
VALACFLAGS = $(VALAPKGFLAGS)
# valadoc flags
VALADOCFLAGS = $(VALAPKGFLAGS) --vapidir=/usr/share/vala-0.18/vapi/ --private --package-name=PerceptVala --package-version="`LC_ALL=en_US date`"
# path to the MinGW gcc cross-compiler (only relevant if cross-compiling from
# Linux to Win32)
MINGW_GCC = i686-w64-mingw32-gcc
# MinGW gcc flags (only relevant if cross-compiling from Linux to Win32)
MINGW_CFLAGS = -O3
# MinGW pkg-config call routine syntax
MINGW_PKG_CONFIG = PKG_CONFIG_PATH=/home/inequation/mingw/lib/pkgconfig/ pkg-config --define-variable=prefix=/home/inequation/mingw
# debug dist directory
DEBUG_DIST_DIR = ../bin/Debug
# release dist directory
RELEASE_DIST_DIR = ../bin/Release
# executable extension (none for *nix)
#EXEC_EXT = .exe
EXEC_EXT =

# =============================================================================
# End of configuration
# =============================================================================

SOURCES=Main.vala MainWindow.vala ImagePixel.vala Neuron.vala NeuralNetwork.vala CharacterRenderer.vala BiasNeuron.vala ErrorPlotRenderer.vala
C_SOURCES=Main.c MainWindow.c ImagePixel.c Neuron.c NeuralNetwork.c CharacterRenderer.c BiasNeuron.c ErrorPlotRenderer.c

MINGW_FLAGS_GLIB=`$(MINGW_PKG_CONFIG) glib-2.0 --cflags --libs`
MINGW_FLAGS_GTK=`$(MINGW_PKG_CONFIG) gtk+-3.0 --cflags --libs`
MINGW_FLAGS_ATK=`$(MINGW_PKG_CONFIG) atk --cflags --libs`
MINGW_FLAGS_GEE=`$(MINGW_PKG_CONFIG) gee-1.0 --cflags --libs`
MINGW_FLAGS_CAIRO=`$(MINGW_PKG_CONFIG) cairo --cflags --libs`
MINGW_CFLAGS_ACTUAL=$(MINGW_CFLAGS) $(MINGW_FLAGS_GLIB) $(MINGW_FLAGS_GTK) $(MINGW_FLAGS_ATK) $(MINGW_FLAGS_GEE) $(MINGW_FLAGS_CAIRO)

all: release

cleandebug: clean

cleanrelease: clean

clean:
	echo Cleaning...
	rm -f perceptvala *.vala.c

cross-win32: $(SOURCES)
	$(MAKE) perceptvala VALACFLAGS="$(VALACFLAGS) --disable-assert -C"
	$(MINGW_GCC) $(C_SOURCES) -o perceptvala.exe $(MINGW_CFLAGS_ACTUAL)
	rm $(C_SOURCES)
	$(MKDIR_P) $(RELEASE_DIST_DIR)/win32
	mv perceptvala.exe $(RELEASE_DIST_DIR)/win32

# recursively call make with proper flags
release: $(SOURCES)
	$(MAKE) perceptvala VALACFLAGS="$(VALACFLAGS) --disable-assert -X -O3"
	$(MKDIR_P) $(RELEASE_DIST_DIR)
	mv perceptvala $(RELEASE_DIST_DIR)

# recursively call make with proper flags
debug: $(SOURCES)
	$(MAKE) perceptvala VALACFLAGS="$(VALACFLAGS) -g --save-temps -D DEBUG"
	$(MKDIR_P) $(DEBUG_DIST_DIR)
	mv perceptvala $(DEBUG_DIST_DIR)

# recursively call make with proper flags
debug-verbose: $(SOURCES)
	$(MAKE) debug VALACFLAGS="$(VALACFLAGS) -D VERBOSE"

perceptvala: $(SOURCES)
	$(VALAC) $(VALACFLAGS) -o perceptvala$(EXEC_EXT) $(SOURCES)

docs: $(SOURCES)
	rm -rf ../doc
	$(VALADOC) $(VALADOCFLAGS) -o ../doc $(SOURCES)
