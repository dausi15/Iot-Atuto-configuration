all : clean compile upload

compile: iotsketch/iotsensor.ino
	@echo "compiling.."
	arduino-cli compile --fqbn esp32:esp32:esp32 iotsketch

upload: compile
	@echo "uploading..";
	@if [ -e '/dev/ttyUSB0' ] ; then \
		echo "Device found"; \
		arduino-cli upload -p /dev/ttyUSB0 --fqbn esp32:esp32:esp32 iotsketch; \
	else \
		echo "Device not found"; \
	fi

clean:
	@echo "cleaning.."
