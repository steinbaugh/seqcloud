#!/usr/bin/env bash

test_array_to_r_vector() {
    assertEquals \
        "$(_koopa_array_to_r_vector "aaa" "bbb")" \
        'c("aaa", "bbb")'
}

