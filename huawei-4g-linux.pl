#!/usr/bin/env perl
#
# Huawei 4g modem E3276 (and possibly others) connect script 
# by Janhouse (Janis Jansons) - janis.jansons@janhouse.lv
#
# This has been tested with Latvian based operator LMT.
# It should work for many other modems and networks.
#
#
use 5.010;
use warnings;
use strict;
use Getopt::Long;
use POSIX "WNOHANG";
use IO::Select;
STDERR->autoflush(1);

my ($help, $pin, $fh);
my $device="/dev/ttyUSB0";
my $interface="wwan0";
my $apn="internet.lmt.lv";

$SIG{'INT'} = \&close_handler;
$SIG{'TERM'} = \&close_handler;

GetOptions(
    "help" => \$help,
    "interface=s" => \$interface,
    "device=s" => \$device,
    "pin=s" => \$pin,
    "apn=s" => \$apn,
) or exit 1;

err("Huawei 4g modem (E3276 and possibly others) script by Janhouse (Janis Jansons).\n");

show_help() if defined $help;

do{ err("No device found at $device (Try specifying it in --device= argument)");exit 1 } if not -e $device and not -z $device;
do{ err("Device is not readable by the effective user. (Try using root.)"); exit 1 } if not -r $device;
do{ err("Device us not writable by the effective user. (Try using root.)"); exit 1 } if not -w $device;

err("Opening device: $device");
open( $fh, "+>".$device) or do{ err("Can't read serial port : $!"); exit 1 };

do{ err("$device is not a tty."); exit 1 } if not -t $fh;

my $response;

$response=get_command_response($fh, "ATZ", "OK");
err(format_output($response));

$response=get_command_response($fh, "AT+CPIN=$pin", "OK") if defined $pin;
err(format_output($response));

$response=get_command_response($fh, "ATQ0 V1 E1 S0=0", "OK");
err(format_output($response));

$response=get_command_response($fh, "AT^NDISDUP=1,1,\"$apn\"", "^NDISSTAT");
err(format_output($response));
sleep(5);

$response=get_command_response($fh, "AT^DHCP?", "^DHCP:");
err(format_output($response));

if($response=~/DHCP: (.*?)$/ism){

# Run dhcpcd:
system("dhcpcd $interface");

# Or get it from the modem:
    #err("DHCP");
    my @ips=map { join(".", unpack("C4", pack("L", hex))) } split /,/, $1;
    #use Data::Dumper;
    #print Dumper @ips;
    #err($ips);
    #"ifconfig $interface $ips[0] netmask $ips[1] up";
    
=pod
10.40.26.58,
255.255.255.252,
10.40.26.57,
10.40.26.57,
212.93.97.145,
212.93.96.2,
0.0.32.67,
0.0.32.67
=cut

}

err("\nYou can close this script now or you can keep it open to monitor the link quality.\n");

while(1){
    
    err("Link quality:");
    $response=get_command_response($fh, "AT+CSQ", "+CSQ:");
    err(format_output($response));
    $response=get_command_response($fh, "AT+COPS?", "+COPS:");
    err(format_output($response));
    sleep(5);

}

sub format_output {
    my $string=shift;
    $string=~s/(\r\n){2,}/\r\n/mg;
    $string=~s/^/> /mg;
    $string=~s/\s+$//;
    return $string;
}

sub get_command_response {
    my $fh=shift;
    my $command=shift;
    my $ok=shift;
    my $s = IO::Select->new();
    $s->add($fh);
    print $fh $command."\r\n";
    my $string;
    while(1){
        if(my @handles = $s->can_read(5)){
            my $h=shift(@handles);
            my $s;
            my $bytes_read = sysread($h, $s, 1024);
            $string.=$s;
            return $string if defined $ok and $string =~ m/\s.?$ok\s/i;
            next;
        }else{
            return $string;
        }
        return;
    }
}

sub show_help {
    print(<<EOF);
Usage: $0
    -h/--help                          Show this help screen.
    -p/--pin=0000                      PIN code for the SIM card.
    -d/--device=/dev/ttyUSB0           Device to be used.
    -i/--interface=wwan0               Network interface to be used.
    -a/--apn=internet.lmt.lv           Access point name
EOF
    exit 0;
} 

sub err {
    print STDERR shift."\n";
}

sub close_handler {
    print "\nClosing...\n";
    close($fh);
    exit 0;
}

1;
