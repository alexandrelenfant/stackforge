{
    http_port {$HTTP_PORT}
    https_port {$HTTPS_PORT}
}

(common_headers) {
    header {
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Frame-Options "DENY"
        X-Content-Type-Options "nosniff"
        Referrer-Policy "strict-origin-when-cross-origin"
        Permissions-Policy "camera=(), microphone=(), geolocation=()"
    }
}

http://test.{$DOMAIN_LCL:localhost}:{$HTTP_PORT},
{{#if ADMIN_ENABLED}}http://test.admin.{$DOMAIN_LCL:localhost}:{$HTTP_PORT},
{{/if}}http://test.api.{$DOMAIN_LCL:localhost}:{$HTTP_PORT} {
    redir https://{host}:{$HTTPS_PORT}{uri} 308
}

test.{$DOMAIN_LCL:localhost} {
    reverse_proxy front:{$FRONT_INTERNAL_PORT}

    import common_headers

    encode gzip zstd
}

{{#if ADMIN_ENABLED}}
test.admin.{$DOMAIN_LCL:localhost} {
    reverse_proxy admin:{$ADMIN_INTERNAL_PORT}

    import common_headers

    encode gzip zstd
}

{{/if}}
test.api.{$DOMAIN_LCL:localhost} {
    reverse_proxy api:{$API_INTERNAL_PORT}

    import common_headers
    header {
        Cache-Control "public, max-age=60"

        Cross-Origin-Opener-Policy "same-origin"
        Cross-Origin-Resource-Policy "same-origin"
    }

    encode gzip zstd
}
