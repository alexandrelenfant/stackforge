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

http://{$DOMAIN}:{$HTTP_PORT},
{{#if ADMIN_ENABLED}}http://admin.{$DOMAIN}:{$HTTP_PORT},
{{/if}}http://api.{$DOMAIN}:{$HTTP_PORT} {
    redir https://{host}:{$HTTPS_PORT}{uri} 308
}

{$DOMAIN} {
    reverse_proxy front:{$FRONT_INTERNAL_PORT}

    import common_headers

    encode gzip zstd
}

{{#if ADMIN_ENABLED}}
admin.{$DOMAIN} {
    reverse_proxy admin:{$ADMIN_INTERNAL_PORT}

    import common_headers

    encode gzip zstd
}

{{/if}}
api.{$DOMAIN} {
    reverse_proxy api:{$API_INTERNAL_PORT}

    import common_headers
    header {
        Cache-Control "public, max-age=60"

        Cross-Origin-Opener-Policy "same-origin"
        Cross-Origin-Resource-Policy "same-origin"
    }

    encode gzip zstd
}
