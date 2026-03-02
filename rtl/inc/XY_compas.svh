`ifndef __XY_COMPASS__
`define __XY_COMPASS__

typedef enum logic [2:0] {
    HOME,
    NORTH,
    EAST,
    SOUTH,
    WEST
} GENERAL_DIRECTIONS;

typedef enum logic [3:0] {
    HOME_REQ,
    HOME_RESP,
    NORTH_REQ,
    NORTH_RESP,
    EAST_REQ,
    EAST_RESP,
    SOUTH_REQ,
    SOUTH_RESP,
    WEST_REQ,
    WEST_RESP
} DOUBLE_CHANNEL_DIRECTIONS;

`endif
