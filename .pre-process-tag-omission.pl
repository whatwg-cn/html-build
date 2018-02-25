#!/usr/bin/perl -w
use strict;

my $state = undef;

my $mode = 'bored';
my $current = '';
my %voids = ();
my %insertionPoints = ();
my @lines = ();

sub pushLine {
    my($element, $text) = @_;
    die unless exists $insertionPoints{$element};
    my $line = $insertionPoints{$element};
    if ($$line eq '') {
        $$line .= "   <dt><span data-x=\"concept-element-tag-omission\">text/html 中的标签省略</span>：</dt>\n";
    }
    $text =~ s!<(/?)p>!<${1}dd>!g;
    $text =~ s!may!can!g;
    $$line .= " $text";
}

while (defined($_ = <>)) {
    if ($mode eq 'bored') {
        if ($_ eq "  <h5>Optional tags</h5>\n") {
            $mode = 'optionals';
        } elsif ($_ eq "  <h5 data-x=\"Optional tags\">可选标签</h5>\n") {
            $mode = 'optionals';
        } elsif ($_ eq "   <dt><dfn data-x=\"Void elements\">void 元素</dfn></dt>\n") {
            $mode = 'voids';
        } elsif ($_ eq "   <dt><dfn data-x=\"Void elements\">void elements</dfn></dt>\n") {
            $mode = 'voids';
        } elsif ($_ =~ m!<code>([^<]+)</code></dfn> elements?</h4>!) {
            $current = $1;
            $mode = 'element';
        } elsif ($_ =~ m!<code>([^<]+)</code></dfn> 元素</h4>!) {
            $current = $1;
            $mode = 'element';
        }
    } elsif ($mode eq 'element') {
        if ($_ eq "   <dt><span data-x=\"concept-element-attributes\">Content attributes</span>:</dt>\n") {
            my $line = '';
            push(@lines, \$line);
            $insertionPoints{$current} = \$line;
            $mode = 'bored';
        } elsif ($_ eq "   <dt><span data-x=\"concept-element-attributes\">内容属性</span>：</dt>\n") {
            my $line = '';
            push(@lines, \$line);
            $insertionPoints{$current} = \$line;
            $mode = 'bored';
        } elsif ($_ =~ m!</h!) {
            die "confused $_";
        } else {
            # ignore...
        }
    } elsif ($mode eq 'voids') {
        if ($_ =~ m!</dt!) {
            $mode = 'bored';
        } else {
            while (m!\G.*?<code>([^<]+)</code>!g) {
                $voids{$1} = 1;
            }
        }
    } elsif ($mode eq 'optionals') {
        if ($_ =~ m!<p>An? <code>([^<]+)</code>!) {
            $current = $1;
            pushLine($current, $_);
            $mode = 'optionals-in';
        } elsif ($_ =~ m!<h5!) {
            $mode = 'done';
        } else {
            # ignore...
        }
    } elsif ($mode eq 'optionals-in') {
        if ($_ =~ m!</p>!) {
            $mode = 'optionals';
        }
        pushLine($current, $_);
    } elsif ($mode eq 'done') {
        # ignore...
    } else {
        die 'unknown mode';
    }
    my $line = "$_";
    push(@lines, \$line);
}

foreach (keys %insertionPoints) {
    my $line = $insertionPoints{$_};
    if ($$line eq '') {
        if ($voids{$_}) {
            pushLine($_, "  <p>没有 <span data-x=\"syntax-end-tag\">结束标签</span>。</p>\n");
        } else {
            pushLine($_, "  <p>哪个标签都不能省略。</p>\n");
        }
    }
}

foreach (@lines) {
    print $$_;
}
