package App::finquotehist;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{finquotehist} = {
    v => 1.1,
    summary => 'Fetch historical stock quotes',
    args => {
        action => {
            schema => 'str*',
            description => <<'_',

Choose what action to perform. The default is 'fetch_quotes'. Other actions include:

* 'fetch_splits' - Fetch splits.
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
            schema => ['array*', of=>'str*'],
            pos => 0,
            greedy => 1,
        },
        engines => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'engine',
            schema => ['array*', of=>'perl::modname*'],
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
            "Finance::QuoteHist::", {list_modules=>1});
        return [200, "OK", [
            grep {!/\A(Generic)\z/}
                map {my $x = $_; $x =~ s/\AFinance::QuoteHist:://; $x}
                sort keys %$mods]];
    } elsif ($action eq 'fetch_quotes') {
    } else {
        return [400, "Unknown action"];
    }
}

1;
# ABSTRACT:

=head1 SYNOPSIS

See L<finquotehist> script.

=cut
