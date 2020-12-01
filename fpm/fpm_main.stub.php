<?php

/** @generate-function-entries */

function fastcgi_finish_request(): bool {}

function apache_request_headers(): array {}

/** @alias apache_request_headers */
function getallheaders(): array {}

function fpm_get_status(): array|false {}

/** @param mixed $value */
function redefine(string $constant_name, $value, bool $case_insensitive = false): bool {}

