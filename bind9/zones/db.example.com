$TTL    604800
@       IN      SOA     example.com. admin.example.com. (
                     2023032201         ; Serial
                     604800         ; Refresh
                     86400         ; Retry
                     2419200         ; Expire
                     604800 )       ; Negative Cache TTL
;
@       IN      NS      ns1.example.com.
@       IN      A       192.0.2.1
ns1     IN      A       192.0.2.1
www     IN      A       192.0.2.1 