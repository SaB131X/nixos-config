# modules/network/zapret2/default.nix
{ lib, config, pkgs-unstable, ... }:
# Requires nixpkgs with services.zapret2 (unstable / 26.11+).

{
  imports = [
    "${pkgs-unstable.path}/nixos/modules/services/networking/zapret2.nix"
  ];
  services.zapret2 = {
    enable = true;
    package = pkgs-unstable.zapret2;

    extraOptions = [
      # bundled with zapret2 itself, no need to keep a copy in ./files
      "--blob=quic_google:${pkgs-unstable.zapret2}/share/zapret2/files/fake/quic_initial_www_google_com.bin"
      # runs after the default lua libs (extraOptions comes last)
      "--lua-init=fake_default_tls = tls_mod(fake_default_tls,'rnd,rndsni')"
    ];

    # --new and --name are added automatically by the module between profiles.
    # Priority preserves the --new block order of the original script
    # (profiles are first-match-wins).
    profiles = {
      http.priority = 100;
      tls-discord.priority = 200;
      tls.priority = 300;
      quic-youtube.priority = 400;
      quic.priority = 500;
      discord-stun.priority = 600;
      wireguard.priority = 700;
    };

    profiles.http.parameters = [
      "--filter-tcp=80"
      "--filter-l7=http"
      "--hostlist-exclude=${./files/list-exceptions.txt}"
      "--out-range=-d10"
      "--payload=http_req"
      "--lua-desync=fake:blob=fake_default_http:ip_autottl=-2,3-20:ip6_autottl=-2,3-20:tcp_md5"
      "--lua-desync=fakedsplit:ip_autottl=-2,3-20:ip6_autottl=-2,3-20:tcp_md5"
    ];

    profiles.tls-discord = {
      hosts.autodetect = {
        # Linux replacement for --hostlist-auto: zapret2 appends learned
        # hosts to this file at runtime (persisted in /var/lib/zapret2).
        enable = true;
        file = "/var/lib/zapret2/list-auto.txt";
      };
      parameters = [
        "--filter-tcp=443"
        "--filter-l7=tls"
        "--hostlist=${./files/list-discord.txt}"
        # hosts learned under Windows; new detections go to
        # /var/lib/zapret2/list-auto.txt
        # "--hostlist=${./files/list-auto.txt}"
        "--hostlist-exclude=${./files/list-exceptions.txt}"
        "--out-range=-d10"
        "--payload=tls_client_hello"
        "--lua-desync=multidisorder:pos=2,midsld:seqovl=1"
      ];
    };

    profiles.tls.parameters = [
      "--filter-tcp=443"
      "--filter-l7=tls"
      "--hostlist-exclude=${./files/list-exceptions.txt}"
      "--out-range=-d10"
      "--payload=tls_client_hello"
      "--lua-desync=multidisorder:pos=1,midsld:seqovl=1"
    ];

    profiles.quic-youtube.parameters = [
      "--filter-udp=443"
      "--filter-l7=quic"
      "--hostlist=${./files/list-youtube.txt}"
      "--hostlist-exclude=${./files/list-exceptions.txt}"
      "--payload=quic_initial"
      "--lua-desync=fake:blob=quic_google:repeats=11"
    ];

    profiles.quic.parameters = [
      "--filter-udp=443"
      "--filter-l7=quic"
      "--hostlist-exclude=${./files/list-exceptions.txt}"
      "--payload=quic_initial"
      "--lua-desync=fake:blob=fake_default_quic:repeats=11"
    ];

    profiles.discord-stun.parameters = [
      "--filter-udp=50000-65535"
      "--filter-l7=discord,stun"
      "--payload=discord_ip_discovery,stun"
      "--lua-desync=fake:blob=fake_default_quic:repeats=6"
    ];

    profiles.wireguard.parameters = [
      "--filter-l7=wireguard,stun,discord"
      "--hostlist-exclude=${./files/list-exceptions.txt}"
      "--payload=wireguard_initiation,wireguard_cookie,stun,discord_ip_discovery"
      "--lua-desync=fake:blob=0x00000000000000000000000000000000:repeats=2"
    ];

    firewall = {
      tcpPorts = [ 80 443 ];

      # null = all UDP is routed to zapret2. The Discord media range
      # (50000-65535) can't be expressed via the udpPorts list, and WireGuard
      # initiations target arbitrary server ports, so the profiles'
      # --filter-l7/--payload selectors do the fine-grained matching.
      # Overhead is bounded by maxPackets (default 16 per connection).
      udpPorts = null;
      # interfaces = [ "eth0" ];
    };
  };
}
