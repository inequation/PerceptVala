# perceptvala makefile
# Written by Leszek Godlewski

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
VALACFLAGS =
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

clean:
	rm -f perceptvala

# recursively call make with proper flags
release:
	$(MAKE) perceptvala VALACFLAGS="$(VALACFLAGS) --disable-assert --Xcc=-03"
	$(MKDIR_P) $(RELEASE_DIST_DIR)
	mv perceptvala $(RELEASE_DIST_DIR)

# recursively call make with proper flags
debug:
	$(MAKE) perceptvala VALACFLAGS="$(VALACFLAGS) -g"
	$(MKDIR_P) $(DEBUG_DIST_DIR)
	mv perceptvala $(DEBUG_DIST_DIR)

perceptvala: Main.vala NeuronInput.vala ImagePixel.vala Neuron.vala
	$(VALAC) $(VALACFLAGS) -o perceptvala$(EXEC_EXT) Main.vala NeuronInput.vala ImagePixel.vala Neuron.vala
