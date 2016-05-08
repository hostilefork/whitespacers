
# 
#      whitespace.pl - A language with no visible syntax.
#      (c) Michael Koelbl 2003 (mrk21@infradead.org)
#      
#      This program is free software; you can redistribute it and/or
#      modify it under the terms of the GNU General Public License
#      as published by the Free Software Foundation; either version 2
#      of the License, or (at your option) any later version.
#     
#      This program is distributed in the hope that it will be useful,
#      but WITHOUT ANY WARRANTY; without even the implied warranty of
#      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#      GNU General Public License for more details.
#      
#      You should have received a copy of the GNU General Public License along
#      with this program; if not, write to the Free Software Foundation, Inc.,
#      59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
# 
# 

use strict;
use Getopt::Std;

my $debug;
my %opt;
getopts('d', \%opt);
$debug = 1 if $opt{'d'};

my $prog_string;
undef $/;
$prog_string = <>;
$/ = "\n";

my $p = new prog ( $prog_string );
my @stack;
my %heap;
my %labels;
my @prog_stack;
my $stdin = '';

# pre_parse to get all the labels
while ( $p->is_cmd )
{
    my @valid_cmds = qw ( AAn ACA ACB ACC ABAn ABCn
			  BAAA BAAB BAAC BABA BABB
			  BBA BBB 
			  CAAl CABl CACl CBAl CBBl CBC CCC
			  BCAA BCAB BCBA BCBB
			  );

    my %cmd_list = qw ( AAn push_number 
			ACA duplicate_last
			ACB swap_last
			ACC pop_number
			ABAn copy
			ABCn slide
			BAAA add
			BAAB subtract
			BAAC multiply
			BABA div
			BABB mod
			BBA store
			BBB retrieve
			CAAl set_label
			CABl call_label
			CACl jump
			CBAl jump_ifzero
			CBBl jump_negative
			CBC ret
			CCC end
			BCAA print_char
			BCAB print_num
			BCBA read_char
			BCBB read_num );

    $p->parse_reset;
    print STDERR "posiiton: ".$p->get_pos. "     " if $debug;
    foreach my $v ( @valid_cmds )
    {
	$p->parsecmd( $v ) or next;
	$v eq "CAAl" and  $labels{ $p->result } = $p->get_pos;
	my $r = $p->result || '';
	print STDERR "command: $v ".$cmd_list{$v}." $r\n" if $debug;
    }
}

$p->restart;

$debug and print STDERR "$_ = ".$labels{$_}."\n" foreach sort { $a cmp $b } keys %labels;


while ( $p->is_cmd )
{
    print STDERR "position=".$p->get_pos."\n" if $debug;
    print STDERR " stack=".join(',',@stack)."\n" if $debug;
    $p->parse_reset;
    $p->parsecmd( "AAn" ) and push @stack, $p->result;
    $p->parsecmd( "ACA" ) and push @stack, $stack[-1];
    $p->parsecmd( "ACB" ) and push @stack, reverse splice @stack, -2, 2;
    $p->parsecmd( "ACC" ) and pop @stack;
    $p->parsecmd( "ABAn" ) and push @stack, $stack[-$p->result - 1];
    $p->parsecmd( "ABCn" ) and splice @stack, -$p->result - 1, $p->result;

    my ( $left, $right );
    $p->parsecmd( "BA") and do
    {
	my ( $left, $right ) = splice @stack, -2, 2;
	$p->parse_reset;
	$p->parsecmd( "AA" ) and push @stack, $left + $right;
	$p->parsecmd( "AB" ) and push @stack, $left - $right;
	$p->parsecmd( "AC" ) and push @stack, $left * $right;
	$p->parsecmd( "BA" ) and push @stack, int( $left / $right );
	$p->parsecmd( "BB" ) and push @stack, $left % $right;
	next;
    };
    
    $p->parsecmd( "BBA" ) and do
    {
	my ( $adr, $value ) = splice @stack, -2, 2;
	$heap{ $adr } = $value;
    };
    $p->parsecmd( "BBB" ) and push @stack, $heap{ pop @stack } || 0;

    $p->parsecmd( "CAAl" );
    $p->parsecmd( "CABl" ) and do {
	push @prog_stack, $p->get_pos;
	$p->set_pos( $labels{ $p->result } );
    };

    $p->parsecmd( "CACl" ) and $p->set_pos( $labels{ $p->result } );
    $p->parsecmd( "CBAl" ) and pop @stack == 0 and $p->set_pos( $labels{ $p->result } );
    $p->parsecmd( "CBBl" ) and pop @stack < 0 and $p->set_pos( $labels{ $p->result } );
    $p->parsecmd( "CBC" ) and $p->set_pos( pop @prog_stack );
    $p->parsecmd( "CCC" ) and exit;

    $p->parsecmd( "BCAA" ) and print chr( pop @stack );
    $p->parsecmd( "BCAB" ) and print ( ( pop @stack ) );
    $p->parsecmd( "BCBA" ) and $heap{ pop @stack } = ord( &get_char );
    $p->parsecmd( "BCBB" ) and $heap{ pop @stack } = &get_num;
}

sub check_stdin
{
    length($stdin) or do {
	$stdin = <STDIN>;
#	chomp;
    };
}


sub get_char
{
    &check_stdin;
    return substr( $stdin, 0, 1,'' );
}

sub get_num
{
    &check_stdin;
    $stdin =~ s/^\s*(-?\d+)\s*//g and do {
	print STDERR "input=$1\n" if $debug;
	return $1;
    };
    return undef;
}


package prog;

sub new
{
    my ( $cl, $data ) = @_;
    my @data = split //, $data;
    my @out_data;
    foreach ( split //, $data )
    {
	push @out_data, 'A' if $_ eq chr(32);
	push @out_data, 'B' if $_ eq chr(9);
	push @out_data, 'C' if $_ eq chr(10);
    }
    print STDERR "command list: ".join('', @out_data ) . "\n" if $debug;
    my $self = { 'pos' => 0,
		 'data' => \@out_data };
    my $g = ref $cl || $cl;
    return bless $self, $cl;
}

sub next1
{
    my $self = shift;
    return $self->{'data'}[ $self->{'pos'}++ ];
}

sub parse_reset
{
    my $self = shift;
    $self->{'parse_done'} = 0;
}
    
sub parsecmd
{
    my ( $self, $string ) = @_;
    my ( $number, $label ) ;
    $self->{'parse_done'} and return undef;
    $label = 1 if $string =~ s/l$//;
    $number = 1 if $string =~ s/n$//;
    my @s_check = split //, $string;
    my $p = $self->{'pos'};
    foreach ( @s_check )
    {
	$self->{'data'}[$p] eq $_ or return undef;
	$p++;
    }
    $self->{'pos'} = $p;
    $self->{'parse_done'} = 1;
    my $result;
    $result = $self->get_number if $number;
    $result = $self->get_label if $label;
    $self->{'result'} = $result;
    return 1;
}

sub get_number
{
    my $self = shift;
    my $sign = $self->next1 eq "A" ? 1 : -1;
    my $number = 0;
    my $c;
    while (( $c = $self->next1) ne "C" )
    {
	$number *= 2;
	$c eq "B" and $number += 1;
    }
    return $sign * $number;
}

sub set_pos
{
    my ( $self, $l ) = @_;
    $self->{'pos'} = $l;
}

sub result
{
    my $self = shift;
    return $self->{'result'};
}

sub get_label
{
    my $self = shift;
    my $l = '';
    my $p;
    while (( $p = $self->next1 ) ne "C" )
    {
	$l .= $p;
    }
    return $l;
}

sub get_pos
{
    my $self = shift;
    return $self->{'pos'};
}

sub is_cmd
{
    my $self = shift;
    return 1 if $self->{'pos'} < scalar ( @{ $self->{'data'}});
}

sub restart
{
    my $self = shift;
    $self->{'pos'} = 0;
}

1;
