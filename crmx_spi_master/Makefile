BUILD_DIR = build
BOARD	  = arduino:sam:arduino_due_x_dbg
SKETCH	  = crmx_spi_master.ino
PORT     ?= /dev/cu.usbmodem1101

.PHONY: all compile upload clean

all: compile upload

compile:
	@echo "Compiling sketch: $(SKETCH) "
	arduino-cli compile --fqbn $(BOARD) --build-path $(BUILD_DIR) $(SKETCH)

upload: compile
	@echo "Uploading sketch: $(SKETCH) "
	arduino-cli upload -p $(PORT) --fqbn $(BOARD) --input-dir $(BUILD_DIR) $(SKETCH)

clean:
	rm -rf $(BUILD_DIR)
