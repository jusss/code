#!/bin/bash
docker run -p 22323:51348 -p 22323:51348/udp --env SERVER_PORT=51348 --env PASSWORD=w --env METHOD=chacha20 --env PROTOCOL=origin --env OBFS=http_simple --env PROTOCOLPARAM=104114:m9Rz7o -itd breakwa11/shadowsocksr
