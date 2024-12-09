#ifndef TIMO_SPI_H_
#define TIMO_SPI_H_

#define TIMO_READ_REG_COMMAND(address)  (address)
#define TIMO_WRITE_REG_COMMAND(address) (0x40 | address)
#define TIMO_READ_RXTX_COMMAND          0x84
#define TIMO_WRITE_RXTX_COMMAND         0x93
#define TIMO_NOP_COMMAND                0xFF

#ifndef PACKED
#define PACKED __attribute__((__packed__))
#endif

typedef struct PACKED {
	uint8_t irq_flags;
	uint8_t command;
	uint8_t payload[254];
} SpiMessage;

/* Custom OEM commands */
#define TIMO_SPI_CMD_GET_MANUFACTURER_ID 0x00
#define RESERVED_1                       0x01
#define TIMO_SPI_CMD_GET_PRODUCT_TYPE    0x02
#define RESERVED_2                       0x01
#define TIMO_SPI_CMD_GET_DEVICE_LABEL    0x04
#define TIMO_SPI_CMD_SET_DEVICE_LABEL    0x05
#define TIMO_SPI_CMD_GET_MODE            0x06
#define TIMO_SPI_CMD_SET_MODE            0x07
#define TIMO_SPI_CMD_GET_DMX_ADDRESS     0x08
#define TIMO_SPI_CMD_SET_DMX_ADDRESS     0x09

#define TIMO_CONFIG_REG           0x00
#define TIMO_STATUS_REG           0x01
#define TIMO_IRQ_MASK_REG         0x02
#define TIMO_IRQ_FLAGS_REG        0x03
#define TIMO_DMX_WINDOW_REG       0x04
#define TIMO_ASC_FRAME_REG        0x05
#define TIMO_LINK_QUALITY_REG     0x06
#define TIMO_ANTENNA_REG          0x07
#define TIMO_DMX_SPEC_REG         0x08
#define TIMO_DMX_CONTROL_REG      0x09
#define TIMO_EXT_IRQ_MASK_REG     0x0A
#define TIMO_EXT_IRQ_FLAGS_REG    0x0B
#define TIMO_VERSION_REG          0x10
#define TIMO_RF_POWER_REG         0x11
#define TIMO_BLOCKED_CHANNELS_REG 0x12
#define TIMO_BINDING_UID_REG      0x20
#define TIMO_BLE_STATUS_REG       0x30
#define TIMO_BLE_PIN_REG          0x31
#define TIMO_BATTERY_REG          0x32
#define TIMO_UNIVERSE_COLOR_REG   0x33
#define TIMO_OEM_INFO_REG         0x34
#define TIMO_DEVICE_NAME_REG      0x36

#define TIMO_CONFIG_UART_EN          (1 << 0)
#define TIMO_CONFIG_RADIO_TX_RX_MODE (1 << 1)
#define TIMO_CONFIG_SPI_RDM_EN       (1 << 3)
#define TIMO_CONFIG_RADIO_EN         (1 << 7)

#define TIMO_IRQ_EXTENDED_FLAG    (1 << 6)
#define TIMO_IRQ_RF_LINK_FLAG     (1 << 3)
#define TIMO_IRQ_DMX_CHANGED_FLAG (1 << 2)

#define TIMO_EXTIRQ_SPI_RDM_FLAG        (1 << 0)
#define TIMO_EXTIRQ_SPI_RXTX_DA_FLAG    (1 << 1)
#define TIMO_EXTIRQ_SPI_RXTX_CTS_FLAG   (1 << 2)
#define TIMO_EXTIRQ_SPI_RADIO_DISC_FLAG (1 << 3)

typedef struct
{
	int  csn_pin;
	int  irq_pin;
	bool irq_pending;
} timo_t;

typedef struct
{
	uint8_t     address;
	uint32_t    length;
	uint8_t     read_access;
	uint8_t     write_access;
	char const *name;
} timo_register_info_t;

#define TIMO_REGISTERS {                                                                                                   \
	{.address = TIMO_CONFIG_REG, .length = 1, .read_access = 1, .write_access = 1, .name = "CONFIG"},                      \
	{.address = TIMO_STATUS_REG, .length = 1, .read_access = 1, .write_access = 1, .name = "STATUS"},                      \
	{.address = TIMO_IRQ_MASK_REG, .length = 1, .read_access = 1, .write_access = 1, .name = "IRQ_MASK"},                  \
	{.address = TIMO_IRQ_FLAGS_REG, .length = 1, .read_access = 1, .write_access = 0, .name = "IRQ_FLAGS"},                \
	{.address = TIMO_DMX_WINDOW_REG, .length = 4, .read_access = 1, .write_access = 1, .name = "DMX_WINDOW"},              \
	{.address = TIMO_ASC_FRAME_REG, .length = 3, .read_access = 1, .write_access = 0, .name = "ASC_FRAME"},                \
	{.address = TIMO_LINK_QUALITY_REG, .length = 1, .read_access = 1, .write_access = 0, .name = "LINK_QUALITY"},          \
	{.address = TIMO_ANTENNA_REG, .length = 1, .read_access = 1, .write_access = 1, .name = "ANTENNA"},                    \
	{.address = TIMO_DMX_SPEC_REG, .length = 8, .read_access = 1, .write_access = 1, .name = "DMX_SPEC"},                  \
	{.address = TIMO_DMX_CONTROL_REG, .length = 1, .read_access = 1, .write_access = 1, .name = "DMX_CONTROL"},            \
	{.address = TIMO_VERSION_REG, .length = 8, .read_access = 1, .write_access = 0, .name = "VERSION"},                    \
	{.address = TIMO_RF_POWER_REG, .length = 1, .read_access = 1, .write_access = 1, .name = "RF_POWER"},                  \
	{.address = TIMO_BLOCKED_CHANNELS_REG, .length = 11, .read_access = 1, .write_access = 1, .name = "BLOCKED_CHANNELS"}, \
	{.address = TIMO_BINDING_UID_REG, .length = 6, .read_access = 1, .write_access = 1, .name = "BINDING_UID"},            \
	{.address = TIMO_BLE_STATUS_REG, .length = 1, .read_access = 1, .write_access = 1, .name = "BLE_STATUS"},              \
	{.address = TIMO_BLE_PIN_REG, .length = 6, .read_access = 0, .write_access = 1, .name = "BLE_PIN"},                    \
	{.address = TIMO_BATTERY_REG, .length = 1, .read_access = 0, .write_access = 1, .name = "BATTERY"},                    \
	{.address = TIMO_UNIVERSE_COLOR_REG, .length = 3, .read_access = 1, .write_access = 1, .name = "UNIVERSE_COLOR"},      \
	{.address = TIMO_OEM_INFO_REG, .length = 6, .read_access = 1, .write_access = 1, .name = "OEM_INFO"},                  \
}

#endif
