/**
 * This example provides a very simple TimoTwo integration using the
 * SPI interface.
 *
 * This example provides bare-minimum implementation which is not
 * sufficient for read-world implementation.
 */

#include "timo_spi.h"
#include <SPI.h>

#define TIMO_SPI_DEVICE_BUSY_IRQ_MASK (1 << 7)

static timo_t timo = {.csn_pin = 5, .irq_pin = 3};

/* SPI communication buffers */
static uint8_t rx_buffer[255];
static uint8_t tx_buffer[255];

/* Default configuration */
static const uint16_t manufacturer_id = 0x4c55;
static const uint16_t product_type = 0x7101;
static char           device_label[32] = {'T', 'e', 's', 't'};
static uint8_t        mode = 0;
static uint16_t       dmx_address = 123;

void irq_pin_handler() {
	timo.irq_pending = 1;
}

bool irq_is_pending() {
	noInterrupts();
	bool pending = timo.irq_pending;
	timo.irq_pending = false;
	interrupts();
	return pending;
}

/**
 * This is the Arduino setup function, it's called when the Arduino starts up
 */
void setup() {
	pinMode(LED_BUILTIN, OUTPUT);

	/* Initiate serial port to 250 kbps */
	Serial.begin(250000);

	/* Initate SPI */
	SPI.begin();

	/* Setup IRQ and CS pins */
	pinMode(timo.irq_pin, INPUT);
	pinMode(timo.csn_pin, OUTPUT);
	digitalWrite(timo.csn_pin, HIGH);
	attachInterrupt(digitalPinToInterrupt(timo.irq_pin), irq_pin_handler, FALLING);

	SPI.beginTransaction(SPISettings(2000000, MSBFIRST, SPI_MODE0));

	delay(1000);

	/* Clear the Serial port from any garbage bytes */
	while (Serial.available() > 0) {
		Serial.read();
	}

	Serial.println("Running");
	Serial.flush();

	/* Wait here until module has booted and IRQ signal is high */
	while (irq_is_pending()) {
		/* Do nothing */
		Serial.println("Waiting for TimoTwo...");
	}

	/* Configure TimoTwo module */
	init_timo();
}

/**
 * This is the Arduino main loop function, it's called repeatedly
 */
void loop() {
	int16_t irq_flags;

	if (!digitalRead(timo.irq_pin)) {
		/* Send NOP command to read the IRQ flags */
		irq_flags = timo_transfer(TIMO_NOP_COMMAND, rx_buffer, tx_buffer, 0);

		/* Wait for IRQ signal to go high again - this indicates our command has been processed */
		while (!irq_is_pending()) {
			/* Do nothing */
		}

		/* If there is a extended IRQ we need to check what to do */
		if (irq_flags & TIMO_IRQ_EXTENDED_FLAG) {
			uint32_t ext_flags;
			uint8_t  response_length;

			bzero(tx_buffer, 5);

			/* Read the extended IRQ flags */
			irq_flags = timo_transfer(TIMO_READ_REG_COMMAND(TIMO_EXT_IRQ_FLAGS_REG), rx_buffer, tx_buffer, 5);
			ext_flags = ((uint32_t)rx_buffer[0] << 24) | ((uint32_t)rx_buffer[1] << 16) | ((uint32_t)rx_buffer[2] << 8) | ((uint32_t)rx_buffer[3]);

			/* Check if we got a RXTX data available */
			if (ext_flags & TIMO_EXTIRQ_SPI_RXTX_DA_FLAG) {
				while (!irq_is_pending()) {
					/* Do nothing */
				}

				/* Read the RXTX data */
				bzero(tx_buffer, sizeof(tx_buffer));
				timo_transfer(TIMO_READ_RXTX_COMMAND, rx_buffer, tx_buffer, sizeof(rx_buffer));
				Serial.println("SPI Command:");
				print_response(irq_flags, rx_buffer, rx_buffer[2] + 2);

				response_length = handle_spi_message((SpiMessage *)rx_buffer);

				/* If response length is > 0 it means we have a response to return */
				if (response_length > 0) {
					delay(1);
					/* Write the response to the radio module */
					timo_transfer(TIMO_WRITE_RXTX_COMMAND, rx_buffer, tx_buffer, response_length + 1);
					Serial.println("SPI response");
				}
			}
		}
	}
}

/**
 * Initialize TimoTwo configuration.
 */
void init_timo() {
	int16_t irq_flags;

	Serial.println("Version:");
	irq_flags = timo_transfer(TIMO_READ_REG_COMMAND(TIMO_VERSION_REG), rx_buffer, tx_buffer, 9);
	print_response(irq_flags, rx_buffer, 8);

	Serial.println("Config:");
	irq_flags = timo_transfer(TIMO_READ_REG_COMMAND(TIMO_CONFIG_REG), rx_buffer, tx_buffer, 2);
	print_response(irq_flags, rx_buffer, 1);

	/* We want to configure TimoTwo mode */
	while (get_timo_mode() != mode) {
		Serial.println("Changing mode");
		set_timo_mode(mode);
		irq_flags = timo_transfer(TIMO_READ_REG_COMMAND(TIMO_CONFIG_REG), rx_buffer, tx_buffer, 2);
		print_response(irq_flags, rx_buffer, 1);
	}

	/* We want to enable TimoTwo radio */
	tx_buffer[0] = rx_buffer[0] | TIMO_CONFIG_RADIO_EN;
	timo_transfer(TIMO_WRITE_REG_COMMAND(TIMO_CONFIG_REG), rx_buffer, tx_buffer, 2);
	irq_flags = timo_transfer(TIMO_READ_REG_COMMAND(TIMO_CONFIG_REG), rx_buffer, tx_buffer, 2);
	print_response(irq_flags, rx_buffer, 1);

	/* We want IRQ when extended interrupts */
	Serial.println("IRQ mask:");
	tx_buffer[0] = TIMO_IRQ_EXTENDED_FLAG;
	irq_flags = timo_transfer(TIMO_WRITE_REG_COMMAND(TIMO_IRQ_MASK_REG), rx_buffer, tx_buffer, 2);
	irq_flags = timo_transfer(TIMO_READ_REG_COMMAND(TIMO_IRQ_MASK_REG), rx_buffer, tx_buffer, 2);
	print_response(irq_flags, rx_buffer, 1);

	/* For extended interrupt we want IRQ for RXTX data available */
	Serial.println("Extended IRQ mask:");
	tx_buffer[0] = 0;
	tx_buffer[1] = 0;
	tx_buffer[2] = 0;
	tx_buffer[3] = TIMO_EXTIRQ_SPI_RXTX_DA_FLAG;
	irq_flags = timo_transfer(TIMO_WRITE_REG_COMMAND(TIMO_EXT_IRQ_MASK_REG), rx_buffer, tx_buffer, 5);
	irq_flags = timo_transfer(TIMO_READ_REG_COMMAND(TIMO_EXT_IRQ_MASK_REG), rx_buffer, tx_buffer, 5);
	print_response(irq_flags, rx_buffer, 4);
}

/**
 * Helper function to obtain current TimoTwo mode.
 *
 * Return value 	0 if RX mode, 1 if TX mode.
 */
uint8_t get_timo_mode() {
	timo_transfer(TIMO_READ_REG_COMMAND(TIMO_CONFIG_REG), rx_buffer, tx_buffer, 2);
	return rx_buffer[0] & TIMO_CONFIG_RADIO_TX_RX_MODE ? 1 : 0;
}

/**
 * Helper function to set TimoTwo mode.
 *
 * @param new_mode  The new desired TimoTwo mode.
 */
void set_timo_mode(uint8_t new_mode) {
	uint16_t irq_flags;
	irq_flags = timo_transfer(TIMO_READ_REG_COMMAND(TIMO_CONFIG_REG), rx_buffer, tx_buffer, 2);
	if (new_mode == 0) {
		tx_buffer[0] = rx_buffer[0] & ~TIMO_CONFIG_RADIO_TX_RX_MODE;
	} else {
		tx_buffer[0] = rx_buffer[0] | TIMO_CONFIG_RADIO_TX_RX_MODE;
	}
	timo_transfer(TIMO_WRITE_REG_COMMAND(TIMO_CONFIG_REG), rx_buffer, tx_buffer, 2);
	delay(3000);
}

/**
 * Helper function to set TimoTwo device label.
 *
 * @param p_new_device_label  Pointer to new device label.
 * @param len                 Number of bytes to transmit.
 */
void set_timo_device_label(const char *p_new_device_label, const int8_t len) {
	uint16_t irq_flags;
	irq_flags = timo_transfer(TIMO_READ_REG_COMMAND(TIMO_CONFIG_REG), rx_buffer, tx_buffer, 2);
	memcpy(&tx_buffer, p_new_device_label, len);
	timo_transfer(TIMO_WRITE_REG_COMMAND(TIMO_DEVICE_NAME_REG), rx_buffer, tx_buffer, 32);
}

/*
 * Make a complete SPI transaction with the TimoTwo module
 *
 * Docs: https://docs.lumenrad.io/timotwo/spi-interface/#spi-commands
 *
 * Return value  The content of the IRQ flags reqister, or -1 if there was no response.
 **/
int16_t timo_transfer(uint8_t command, uint8_t *dst, uint8_t *src, uint32_t len) {
	uint8_t irq_flags;

	uint32_t start_time = millis();

	/* Perform the transfer of the command byte */
	digitalWrite(timo.csn_pin, LOW);
	irq_flags = SPI.transfer(command);
	irq_is_pending();
	digitalWrite(timo.csn_pin, HIGH);

	/* If no bytes to transfer, this was a NOP command - just wait for IRQ or timeout */
	if (len == 0) {
		start_time = millis();
		while ((!digitalRead(timo.irq_pin)) && (!irq_is_pending())) {
			if (millis() - start_time > 10) {
				break;
			}
		}
		return irq_flags;
	}

	/* wait for IRQ or timeout */
	while (!irq_is_pending()) {
		if (millis() - start_time > 1000) {
			return -1;
		}
	}

	/* start the payload transfer */
	digitalWrite(timo.csn_pin, LOW);
	irq_flags = SPI.transfer(TIMO_NOP_COMMAND);

	/* If busy flag is set we can't do the transfer now, cancel */
	if (irq_flags & TIMO_SPI_DEVICE_BUSY_IRQ_MASK) {
		digitalWrite(timo.csn_pin, HIGH);
		return irq_flags;
	}

	/* Transfer the data */
	for (uint32_t i = 0; i < len - 1; i++) {
		*dst++ = SPI.transfer(*src++);
	}

	/* End transfer */
	digitalWrite(timo.csn_pin, HIGH);

	/* wait for IRQ or timeout */
	while (!digitalRead(timo.irq_pin)) {
		if (millis() - start_time > 50) {
			break;
		}
	}
	return irq_flags;
}

/**
 * Handles the received SPI message.
 *
 * Return value 	Length in bytes of the response.
 *
 * @param message	Pointer to obained SPI message.
 */
uint8_t handle_spi_message(const SpiMessage *message) {
	uint8_t len = 0;

	switch (message->command) {
	/*
	 * GETTER handlers
	 */
	case TIMO_SPI_CMD_GET_MANUFACTURER_ID:
		Serial.println("MANUFACTURER_ID: GET");
		len = prepare_manufacturer_id_response();
		break;
	case TIMO_SPI_CMD_GET_PRODUCT_TYPE:
		Serial.println("PRODUCT_TYPE: GET");
		len = prepare_product_type_response();
		break;
	case TIMO_SPI_CMD_GET_DEVICE_LABEL:
		Serial.println("DEVICE_LABEL: GET");
		len = prepare_device_label_response();
		break;
	case TIMO_SPI_CMD_GET_MODE:
		Serial.println("MODE: GET");
		len = prepare_timotwo_mode_response();
		break;
	case TIMO_SPI_CMD_GET_DMX_ADDRESS:
		Serial.println("DMX_ADDRESS: GET");
		len = prepare_dmx_address_response();
		break;
	/*
	 * SETTERS handlers
	 */
	case TIMO_SPI_CMD_SET_DEVICE_LABEL:
		Serial.println("DEVICE_LABEL: SET");
		update_device_label(message);
		break;
	case TIMO_SPI_CMD_SET_MODE:
		Serial.println("MODE: SET");
		update_timotwo_mode(message);
		break;
	case TIMO_SPI_CMD_SET_DMX_ADDRESS:
		Serial.println("DMX_ADDRESS: SET");
		update_dmx_address(message);
		break;
	default:
		Serial.println("Got unknown command");
		break;
	}

	return len;
}

/**
 * Prepare Manufacturer ID response.
 *
 * Return value 	Length in bytes of the response.
 */
uint8_t prepare_manufacturer_id_response() {
	uint8_t len;

	len = sizeof(manufacturer_id);
	tx_buffer[0] = manufacturer_id >> 8;
	tx_buffer[1] = manufacturer_id;

	return len;
}

/**
 * Prepare Product Type response.
 *
 * Return value 	Length in bytes of the response.
 */
uint8_t prepare_product_type_response() {
	uint8_t len;

	len = sizeof(product_type);
	tx_buffer[0] = product_type >> 8;
	tx_buffer[1] = product_type;

	return len;
}

/**
 * Prepare Device Label response.
 *
 * Return value 	Length in bytes of the response.
 */
uint8_t prepare_device_label_response() {
	uint8_t len;

	len = sizeof(device_label);
	memcpy(&tx_buffer, &device_label, len);

	return len;
}

/**
 * Prepare DMX Address response.
 *
 * Return value 	Length in bytes of the response.
 */
uint8_t prepare_dmx_address_response() {
	uint8_t len;

	len = sizeof(dmx_address);
	tx_buffer[0] = dmx_address >> 8;
	tx_buffer[1] = dmx_address;

	return len;
}

/**
 * Prepare TimoTwo Mode response.
 *
 * Return value 	Length in bytes of the response.
 */
uint8_t prepare_timotwo_mode_response() {
	uint8_t len;

	len = sizeof(mode);
	tx_buffer[0] = mode;

	return len;
}

/**
 * Handle Device Label update.
 *
 * @param message	Pointer to the SPI message.
 */
void update_device_label(const SpiMessage *message) {
	memcpy(&device_label, message->payload, sizeof(device_label));
	set_timo_device_label((const char *)&device_label, sizeof(device_label));
};

/**
 * Handle DMX Address update.
 *
 * @param message	Pointer to the SPI message.
 */
void update_dmx_address(const SpiMessage *message) {
	uint16_t new_dmx_address;

	new_dmx_address = message->payload[0] << 8 | message->payload[1];

	if ((new_dmx_address > 0) && (new_dmx_address <= 512)) {
		dmx_address = new_dmx_address;
	}
};

/**
 * Handle TimoTwo Mode update.
 *
 * @param message	Pointer to the SPI message.
 */
void update_timotwo_mode(const SpiMessage *message) {
	mode = message->payload[0] == 0 ? 0 : 1;

	if (get_timo_mode() != mode) {
		set_timo_mode(mode);
		init_timo(); /* Mode change may cause TimoTwo to reboot, we want to re-init */
	}
};

/*
 * Helper function for printing out SPI response from TimoTwo.
 *
 * @param irq_flags	Obtained IRQ flags to printout.
 * @param data		Pointer to the data to printout.
 * @param len		Length in bytes to printout.
 */
void print_response(int16_t irq_flags, uint8_t *data, uint32_t len) {
	if (irq_flags < 0) {
		Serial.println("Timeout!");
		return;
	}
	Serial.print("< ");
	print_irq_flags(irq_flags);
	Serial.print(" ");
	Serial.flush();
	for (uint32_t i = 0; i < len; i++) {
		Serial.print(nibble_to_hex(0x0f & (data[i] >> 4)));
		Serial.print(nibble_to_hex(0x0f & data[i]));
		Serial.print(" ");
		Serial.flush();
	}
	Serial.println();
}

/*
 * Helper function for printing out IRQ flags.
 *
 * @param irq_flags		Obtained IRQ flags to printout.
 */
void print_irq_flags(int16_t irq_flags) {
	for (int i = 7; i >= 0; i--) {
		if (irq_flags & (1 << i)) {
			Serial.print('1');
		} else {
			Serial.print('0');
		}
	}
	Serial.flush();
}

/**
 * Helper function for converting nibble to char.
 *
 * @param nibble	Value to convert.
 */
char nibble_to_hex(uint8_t nibble) {
	nibble &= 0x0f;
	if (nibble >= 0 && nibble <= 9) {
		return '0' + nibble;
	} else {
		return 'A' + nibble - 10;
	}
}
