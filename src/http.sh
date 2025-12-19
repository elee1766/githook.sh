# http utilities

githook_download_file() {
    _url="$1"
    _output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$_url" -o "$_output"
    elif command -v wget >/dev/null 2>&1; then
        wget -q "$_url" -O "$_output"
    else
        githook_error "curl or wget required"
    fi
}
