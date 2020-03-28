#!/bin/bash
docker run -p 1775:1775 -p 1775:1775/udp --env SERVER_PORT=1775 --env PASSWORD=x --env METHOD=chacha20 --env PROTOCOL=origin --env OBFS=http_simple --env PROTOCOLPARAM=104114:m9Rz7o -itd breakwa11/shadowsocksr
