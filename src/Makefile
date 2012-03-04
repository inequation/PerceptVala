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
# valac flags
VALACFLAGS = --pkg gdk-2.0 --pkg gee-1.0 -X -lgdk_pixbuf-2.0 -X -lSDL -X -I/usr/include/glib-2.0/
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

all: release

cleandebug: clean

cleanrelease: clean

clean:
	echo Cleaning...
	rm -f perceptvala *.vala.c

# recursively call make with proper flags
release:
	$(MAKE) perceptvala VALACFLAGS="$(VALACFLAGS) --disable-assert -X -03"
	$(MKDIR_P) $(RELEASE_DIST_DIR)
	mv perceptvala $(RELEASE_DIST_DIR)

# recursively call make with proper flags
debug:
	$(MAKE) perceptvala VALACFLAGS="$(VALACFLAGS) -g --save-temps"
	$(MKDIR_P) $(DEBUG_DIST_DIR)
	mv perceptvala $(DEBUG_DIST_DIR)

perceptvala: Main.vala Image.vala ImagePixel.vala Neuron.vala NeuralNetwork.vala
	$(VALAC) $(VALACFLAGS) -o perceptvala$(EXEC_EXT) Main.vala Image.vala ImagePixel.vala Neuron.vala NeuralNetwork.vala
