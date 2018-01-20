[Unit]
Description=Puma HTTP Server
After=network.target

[Service]
Type=simple
User=asomirl
WorkingDirectory=/home/asomirl/reddit
ExecStart=/bin/bash -lc 'DATABASE_URL=${db_address} puma'
Restart=always

[Install]
WantedBy=multi-user.target