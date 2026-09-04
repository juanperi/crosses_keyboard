/*
 * Temporary fixed-step scroll processor for the left Crosses trackball.
 * SPDX-License-Identifier: MIT
 */

#define DT_DRV_COMPAT zmk_input_processor_scroll_detent

#include <stdint.h>

#include <zephyr/device.h>
#include <zephyr/input/input.h>
#include <zephyr/kernel.h>

#include <drivers/input_processor.h>

#include <zephyr/logging/log.h>

LOG_MODULE_DECLARE(zmk, CONFIG_ZMK_LOG_LEVEL);

struct scroll_detent_config {
    uint8_t type;
    size_t codes_len;
    const uint16_t *codes;
    uint16_t threshold;
};

struct scroll_detent_data {
    int32_t accumulators[2];
};

static int scroll_detent_handle_event(const struct device *dev, struct input_event *event,
                                      uint32_t param1, uint32_t param2,
                                      struct zmk_input_processor_state *state) {
    const struct scroll_detent_config *config = dev->config;
    struct scroll_detent_data *data = dev->data;

    ARG_UNUSED(param1);
    ARG_UNUSED(param2);
    ARG_UNUSED(state);

    if (event->type != config->type) {
        return ZMK_INPUT_PROC_CONTINUE;
    }

    size_t code_idx = config->codes_len;
    for (size_t i = 0; i < config->codes_len; i++) {
        if (event->code == config->codes[i]) {
            code_idx = i;
            break;
        }
    }

    if (code_idx >= ARRAY_SIZE(data->accumulators)) {
        return ZMK_INPUT_PROC_CONTINUE;
    }

    int32_t *accumulator = &data->accumulators[code_idx];
    *accumulator += event->value;
    event->value = 0;

    if (*accumulator >= config->threshold) {
        event->value = 1;
        *accumulator -= config->threshold;
    } else if (*accumulator <= -config->threshold) {
        event->value = -1;
        *accumulator += config->threshold;
    }

    LOG_DBG("scroll detent code %d accumulator %d, output %d", event->code, *accumulator,
            event->value);
    return ZMK_INPUT_PROC_CONTINUE;
}

static const struct zmk_input_processor_driver_api scroll_detent_driver_api = {
    .handle_event = scroll_detent_handle_event,
};

#define SCROLL_DETENT_INST(n)                                                                       \
    static struct scroll_detent_data scroll_detent_data_##n;                                       \
    static const struct scroll_detent_config scroll_detent_config_##n = {                         \
        .type = DT_INST_PROP_OR(n, type, INPUT_EV_REL),                                           \
        .codes_len = DT_INST_PROP_LEN(n, codes),                                                   \
        .codes = DT_INST_PROP(n, codes),                                                           \
        .threshold = DT_INST_PROP(n, threshold),                                                   \
    };                                                                                             \
    BUILD_ASSERT(DT_INST_PROP_LEN(n, codes) <= 2, "scroll detent supports at most two codes");    \
    BUILD_ASSERT(DT_INST_PROP(n, threshold) > 0, "scroll detent threshold must be positive");     \
    DEVICE_DT_INST_DEFINE(n, NULL, NULL, &scroll_detent_data_##n,                                  \
                          &scroll_detent_config_##n, POST_KERNEL,                                \
                          CONFIG_KERNEL_INIT_PRIORITY_DEFAULT, &scroll_detent_driver_api);

DT_INST_FOREACH_STATUS_OKAY(SCROLL_DETENT_INST)
