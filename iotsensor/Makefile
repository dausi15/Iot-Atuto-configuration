all : say_hello clean compile upload

say_hello:
	@echo "Hello World"

compile: MyFirstSketch/MyFirstSketch.ino
	@echo "compiling.."
	arduino-cli compile --fqbn esp32:esp32:esp32 MyFirstSketch

upload: compile
	@echo "uploading..";
	@if [ -e '/dev/ttyUSB0' ] ; then \
		echo "Device found"; \
		arduino-cli upload -p /dev/ttyUSB0 --fqbn esp32:esp32:esp32 MyFirstSketch; \
	else \
		echo "Device not found"; \
	fi

clean:
	@echo "cleaning.."
