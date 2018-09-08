package App::finquotehist;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

my $sch_date = [
    'date*', {
        'x.perl.coerce_to' => 'DateTime',
        'x.perl.coerce_rules' => ['str_natural'],
    },
];

$SPEC{finquotehist} = {
    v => 1.1,
    summary => 'Fetch historical stock quotes',
    args => {
        action => {
            schema => 'str*',
            description => <<'_',

Choose what action to perform. The default is 'fetch_quotes'. Other actions include:

* 'fetch_splits' - Fetch splits.
* 'fetch_dividends' - Fetch dividends.
* 'list_engines' - List available engines (backends).

_
            default => 'fetch_quotes',
            cmdline_aliases => {
                l => {is_flag=>1, summary => 'Shortcut for --action list_engines', code => sub { $_[0]{action} = 'list_engines' }},
            },
        },
        symbols => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'symbol',
            schema => ['array*', of=>'str*', min_len=>1],
            pos => 0,
            greedy => 1,
        },
        from => {
            schema => $sch_date,
            tags => ['category:filtering'],
        },
        to => {
            schema => $sch_date,
            tags => ['category:filtering'],
        },
       engines => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'engine',
            schema => ['array*', of=>'perl::modname*'],
            default => ['Yahoo', 'Google'],
            element_completion => sub {
                require Complete::Module;
                my %args = @_;
                my $ans = Complete::Module::complete_module(
                    word => $args{word},
                    ns_prefix => 'Finance::QuoteHist',
                );
                [grep {$_ !~ /\A(Generic)\z/} @$ans];
            },
            cmdline_aliases => {
                e => {},
            },
        },
    },
    examples => [
        {
            summary => 'List available engines (backends)',
            argv => [qw/-l/],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Fetch historical quote (by default 1 year) for a few NASDAQ stocks',
            argv => [qw/AAPL AMZN MSFT/],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Fetch quotes for a few Indonesian stocks, for a certain date range',
            argv => [qw/--from 2018-01-01 --to 2018-09-07 BBCA.JK BBRI.JK TLKM.JK/],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Fetch quotes for a stock, from 3 years ago',
            argv => ['--from', '3 years ago', 'AAPL'],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Fetch splits for a few Indonesian stocks',
            argv => [qw/--action fetch_splits BBCA.JK BBRI.JK TLKM.JK/],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub finquotehist {
    my %args = @_;
    my $action = $args{action} // 'fetch';

    if ($action eq 'list_engines') {
        require PERLANCAR::Module::List;
        my $mods = PERLANCAR::Module::List::list_modules(
            "Finance::QuoteHist::", {list_modules=>1, recurse=>1});
        return [200, "OK", [
            grep {!/\A(Generic)\z/}
                map {my $x = $_; $x =~ s/\AFinance::QuoteHist:://; $x}
                sort keys %$mods]];
    } elsif ($action eq 'fetch_quotes' || $action eq 'fetch_splits' || $action eq 'fetch_dividends') {
        require DateTime;
        require Finance::QuoteHist;

        return [400, "Please specify one or more symbols"]
            unless $args{symbols} && @{ $args{symbols} };

        my $from = $args{from} // DateTime->today->subtract(years=>1);
        my $to   = $args{to}   // DateTime->today;
        my $q = Finance::QuoteHist->new(
            lineup  => [map {"Finance::QuoteHist::$_"} @{ $args{engines} }],
            symbols => $args{symbols},
            start_date => $from->strftime("%m/%d/%Y"),
            end_date   => $to  ->strftime("%m/%d/%Y"),
        );
        my @rows;
        my @rows0;
        if    ($action eq 'fetch_quotes'   ) { @rows0 = $q->quotes }
        elsif ($action eq 'fetch_splits'   ) { @rows0 = $q->splits }
        elsif ($action eq 'fetch_dividends') { @rows0 = $q->dividends }
        my $fields;
        for my $row0 (@rows0) {
            my $row;
            if ($action eq 'fetch_quotes') {
                $fields //= [qw/symbol date open high low close volume adjclose/];
                $row = {
                    symbol   => $row0->[0],
                    date     => $row0->[1],
                    open     => $row0->[2],
                    high     => $row0->[3],
                    low      => $row0->[4],
                    close    => $row0->[5],
                    volume   => $row0->[6],
                    adjclose => $row0->[7],
                };
            } elsif ($action eq 'fetch_splits') {
                $fields //= [qw/symbol date post pre/];
                $row = {
                    symbol   => $row0->[0],
                    date     => $row0->[1],
                    post     => $row0->[2],
                    pre      => $row0->[3],
                };
            } elsif ($action eq 'fetch_dividends') {
                $fields //= [qw/symbol date dividend/];
                $row = {
                    symbol   => $row0->[0],
                    date     => $row0->[1],
                    dividend => $row0->[2],
                };
            }
            push @rows, $row;
        }
        [200, "OK", \@rows, {'table.fields' => $fields}];
    } else {
        return [400, "Unknown action"];
    }
}

1;
# ABSTRACT:

=head1 SYNOPSIS

See L<finquotehist> script.

=cut
