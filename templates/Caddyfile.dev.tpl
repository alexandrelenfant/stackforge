{
    http_port {$HTTP_PORT}
    https_port {$HTTPS_PORT}

    servers {
        protocols h1 h2
    }
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

(local_tls) {
    tls /certs/{$DOMAIN_LCL:localhost}.pem \
        /certs/{$DOMAIN_LCL:localhost}-key.pem
}

http://{$DOMAIN_LCL:localhost}:{$HTTP_PORT},
{{#if ADMIN_ENABLED}}http://admin.{$DOMAIN_LCL:localhost}:{$HTTP_PORT},
{{/if}}http://api.{$DOMAIN_LCL:localhost}:{$HTTP_PORT},
http://mail.{$DOMAIN_LCL:localhost}:{$HTTP_PORT} {
    redir https://{host}:{$HTTPS_PORT}{uri} 308
}

{$DOMAIN_LCL:localhost} {
    reverse_proxy front:{$FRONT_INTERNAL_PORT}

    import local_tls

    import common_headers

    encode gzip zstd
}

{{#if ADMIN_ENABLED}}
admin.{$DOMAIN_LCL:localhost} {
    reverse_proxy admin:{$ADMIN_INTERNAL_PORT}

    import local_tls

    import common_headers

    encode gzip zstd
}

{{/if}}
api.{$DOMAIN_LCL:localhost} {
    reverse_proxy api:{$API_INTERNAL_PORT}

    import local_tls

    import common_headers

    encode gzip zstd
}

mail.{$DOMAIN_LCL:localhost} {
    reverse_proxy mailpit:8025

    import local_tls

    import common_headers

    encode gzip zstd
}