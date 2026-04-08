#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Moo;
use Term::ANSIColor;
use IO::Handle;
use Text::LineFold;
use File::Spec;
use Text::ANSI::Util qw(ta_strip);

STDOUT->autoflush(1);

#### Strip `*\s` from emerge --search #####################################
# /#» string trim --chars='\* '  (emerge --search ansi | grep perl) 	#
# dev-perl/Term-ANSIScreen						#
# virtual/perl-Term-ANSIColor						#
#########################################################################


#------------------------------------------------------------------------------
# Emerge::Formatter
#------------------------------------------------------------------------------
{
    package Emerge::Formatter;
    use Text::ANSI::Util qw(ta_strip);
    use Moo;

    has wrap => (is => 'ro', default => sub { $ENV{COLUMNS} || 166 });
    has indent => (is => 'ro', default => sub { '    ' }); # 4 spaces

    has _wrapper => (
        is => 'lazy',
        builder => sub {
            Text::LineFold->new(ColMax => shift->wrap, ColMin => 20);
        }
    );

    # Context: whether the last line started with >>>
    has _in_section => (is => 'rw', default => sub { 0 });

    # Tracks whether the previous line was a step line
    has _extra_indent => (is => 'rw', default => sub { 0 });

    has _plugins => (
        is => 'ro',
        default => sub {
            [
                \&Emerge::Plugins::Sections::mark_section_headers,
                \&Emerge::Plugins::Bullets::bulletize,
                \&Emerge::Plugins::CurrentStep::track_step,
                \&Emerge::Plugins::EmergingIndent::indent_after_step,
            ];
        }
    );

    sub process_stream ($self, $fh_in, $fh_out = *STDOUT) {
        while (my $line = <$fh_in>) {
            my $formatted = $self->process_line($line);
            print $fh_out $formatted, "\n" if defined $formatted && length $formatted;
        }
    }

    sub process_line ($self, $line) {
        # Cleaned version for pattern matching using Text::ANSI::Util

        my $clean = ta_strip($line);
        $clean =~ s/^\s+//;

        # Update section context
        $self->_in_section(1) if $clean =~ /^>>>/;

        # Apply all plugins
        my $out = $line;

        for my $plugin (@{$self->_plugins}) {
            $out = $plugin->($out, $clean);
        }

        # Detect extra indentation marker from emerging steps
        my $extra_indent = '';
        if ($out =~ /\x{200B}$/) {
            $extra_indent = $self->indent;
            $out =~ s/\x{200B}$//;  # remove marker
#           $out =~ s/^→//;         # remove debug marker if present

        }

        # Apply section + extra indentation
        $out = $self->indent . $extra_indent . $out if $self->_in_section && $clean !~ /^>>>/;


        # Fold line

        $out = $self->_wrapper->fold($out);


        # Apply path coloring after folding
        $out = Emerge::Plugins::Paths::dim_paths($out, $clean);

        return $out;
    }
}

#------------------------------------------------------------------------------
# Plugins
#------------------------------------------------------------------------------

# --- Path dimmer -------------------------------------------------------------
{
    package Emerge::Plugins::Paths;
    use Term::ANSIColor;
    use File::Spec;

    sub _looks_like_path ($token) {
        return 1 if File::Spec->file_name_is_absolute($token);
        return $token =~ m{^(?:\.{1,2}/|~/?)};
    }

    sub dim_paths ($line, $clean) {
        $line =~ s{(\S+)}{
            my $tok = $1;
            _looks_like_path($tok) ? color('faint') . $tok . color('reset') : $tok;
        }gex;
	chomp $line;
        return $line;
    }
}

# --- Section markers ---------------------------------------------------------
{
    package Emerge::Plugins::Sections;
    use Term::ANSIColor;

    sub mark_section_headers ($line, $clean) {
        $line =~ s/^(\s*)(>>>)/$1 . color('bold blue') . $2 . color('reset')/ge;
        return $line;
    }
}

# --- Bullet points -----------------------------------------------------------
{
    package Emerge::Plugins::Bullets;

    sub bulletize ($line, $clean) {
        $line =~ s/^(\s*)\*/$1•/;
        return $line;
    }
}

# --- Emerging step indentation -----------------------------------------------
{
    package Emerge::Plugins::EmergingIndent;

    my @step_prefixes = qw(Emerging Installing Merging Completed);

    sub indent_after_step ($line, $clean) {
        if ($clean =~ /^>>>\s*(\w+)/ && grep { $_ eq $1 } @step_prefixes) {
	    say '';
            return $line . "\x{200B}"; # zero-width marker
        }
        return $line;
    }
}

# --- Track current step ------------------------------------------------------
{
    package Emerge::Plugins::CurrentStep;
    use strict;
    use warnings;

    our $CURRENT_STEP = '';

    my @step_prefixes = qw(Emerging Installing Merging Completed);

    sub track_step ($line, $clean) {
        if ($clean =~ /^>>>\s*(\w+)/ && grep { $_ eq $1 } @step_prefixes) {
            $CURRENT_STEP = $line;
        }
        return $line;
    }
}

#------------------------------------------------------------------------------
# Main Script
#------------------------------------------------------------------------------
package main;

my $formatter = Emerge::Formatter->new(
    wrap   => $ENV{COLUMNS} || 166,
    indent => '    ',
);

$formatter->process_stream(*STDIN, *STDOUT);















#
####!/usr/bin/env perl
#
#use v5.36;
#use strict;
#use warnings;
#
#use Moo;
#use Term::ANSIColor;
#use IO::Handle;
#use Text::LineFold;
#use File::Spec;
#
#STDOUT->autoflush(1);
#
#
##------------------------------------------------------------------------------
## Emerge::Formatter
##------------------------------------------------------------------------------
#{
#    package Emerge::Formatter;
#    use Moo;
#
#    has wrap => (is => 'ro', default => sub { $ENV{COLUMNS} || 166 });
#    has indent => (is => 'ro', default => sub { '    ' }); # 4 spaces
#
#    has _wrapper => (
#        is => 'lazy',
#        builder => sub {
#            Text::LineFold->new(ColMax => shift->wrap, ColMin => 20);
#        }
#    );
#
#    # Context: whether the last line started with >>>
#    has _in_section => (is => 'rw', default => sub { 0 });
#
#    # Tracks whether the previous line was a step line
#    has _extra_indent => (is => 'rw', default => sub { 0 });
#
#    has _plugins => (
#        is => 'ro',
#        default => sub {
#            [
#                \&Emerge::Plugins::Sections::mark_section_headers,
#                \&Emerge::Plugins::Bullets::bulletize,
#                \&Emerge::Plugins::CurrentStep::track_step,
#                \&Emerge::Plugins::EmergingIndent::indent_after_step,
#            ];
#        }
#    );
#
#    sub process_stream ($self, $fh_in, $fh_out = *STDOUT) {
#        while (my $line = <$fh_in>) {
#            my $formatted = $self->process_line($line);
#            print $fh_out $formatted, "\n" if defined $formatted && length $formatted;
#        }
#    }
#
#    sub process_line ($self, $line) {
#        # Strip ANSI for matching
#        my $clean = $line;
#        $clean =~ s/\e\[[0-9;]*m//g;
#        $clean =~ s/^\s+//;
#
#        # Update section context
#        $self->_in_section(1) if $clean =~ /^>>>/;
#
#        # Apply plugins
#        my $out = $line;
#        for my $plugin (@{$self->_plugins}) {
#            $out = $plugin->($out, $clean); # pass clean line as second arg
#        }
#
#        # Detect extra indentation marker
#        my $extra_indent = '';
#        if ($out =~ /\x{200B}$/) {
#            $extra_indent = $self->indent;
#            $out =~ s/\x{200B}$//;  # remove marker
#            $out =~ s/^→//;         # remove debug marker if present
#        }
#
#        # Apply indentation if in section
#        $out = $self->indent . $extra_indent . $out if $self->_in_section && $clean !~ /^>>>/;
#
#        # Fold line
#        $out = $self->_wrapper->fold($out);
#
#        # Apply path coloring after folding
#        $out = Emerge::Plugins::Paths::dim_paths($out);
#
#        return $out;
#    }
#}
#
##------------------------------------------------------------------------------
## Plugins
##------------------------------------------------------------------------------
#
## --- Path dimmer -------------------------------------------------------------
#{
#    package Emerge::Plugins::Paths;
#    use Term::ANSIColor;
#    use File::Spec;
#
#    sub _looks_like_path ($token) {
#        return 1 if File::Spec->file_name_is_absolute($token);
#        return $token =~ m{^(?:\.{1,2}/|~/?)};
#    }
#
#    sub dim_paths ($line) {
#        $line =~ s{(\S+)}{
#            my $tok = $1;
#            _looks_like_path($tok) ? color('faint') . $tok . color('reset') : $tok;
#        }gex;
#        return $line;
#    }
#}
#
## --- Section markers ---------------------------------------------------------
#{
#    package Emerge::Plugins::Sections;
#    use Term::ANSIColor;
#
#    sub mark_section_headers ($line) {
#        $line =~ s/^(\s*)(>>>)/$1 . color('bold blue') . $2 . color('reset')/re;
#    }
#}
#
## --- Bullet points -----------------------------------------------------------
#{
#    package Emerge::Plugins::Bullets;
#
#    sub bulletize ($line) {
#        $line =~ s/^(\s*)\*/$1•/;
#        return $line;
#    }
#}
#
## --- Emerging step indentation -----------------------------------------------
#{
#    package Emerge::Plugins::EmergingIndent;
#
#    my @step_prefixes = qw(Emerging Installing Merging Completed);
#
#    sub indent_after_step ($line, $clean) {
#        if ($clean =~ /^>>>\s*(\w+)/ && grep { $_ eq $1 } @step_prefixes) {→
#            return "→" . $line . "\x{200B}";
#        }
#        return $line;
#    }
#}
#
## --- Track current step ------------------------------------------------------
#{
#    package Emerge::Plugins::CurrentStep;
#    use strict;
#    use warnings;
#
#    our $CURRENT_STEP = '';
#
#    my @step_prefixes = qw(Emerging Installing Merging Completed);
#
#    sub track_step ($line, $clean) {
#        if ($clean =~ /^>>>\s*(\w+)/ && grep { $_ eq $1 } @step_prefixes) {
#            $CURRENT_STEP = $line;
#        }
#        return $line;
#    }
#}
#
##------------------------------------------------------------------------------
## Main Script
##------------------------------------------------------------------------------
#package main;
#
#my $formatter = Emerge::Formatter->new(
#    wrap   => $ENV{COLUMNS} || 166,
#    indent => '    ',
#);
#
#$formatter->process_stream(*STDIN, *STDOUT);
#
#
###!/usr/bin/env perl
##use v5.36;
##use strict;
##use warnings;
##
##use Moo;
##use Term::ANSIColor;
##use IO::Handle;
##use Text::LineFold;
##use File::Spec;
##
##STDOUT->autoflush(1);
##
###------------------------------------------------------------------------------
### Emerge::Formatter
###------------------------------------------------------------------------------
##{
##    package Emerge::Formatter;
##    use Moo;
##
##    has wrap => (is => 'ro', default => sub { $ENV{COLUMNS} || 166 });
##    has indent => (is => 'ro', default => sub { '    ' }); # 4 spaces
##
##    has _wrapper => (
##        is => 'lazy',
##        builder => sub {
##            Text::LineFold->new(ColMax => shift->wrap, ColMin => 20);
##        }
##    );
##
##    # Context: whether the last line started with >>>
##    has _in_section => (is => 'rw', default => sub { 0 });
##
##    has _plugins => (
##        is => 'ro',
##        default => sub {
##            [
##                \&Emerge::Plugins::Sections::mark_section_headers,
##                \&Emerge::Plugins::Bullets::bulletize,
##                # Note: Paths coloring applied AFTER folding
##        	\&Emerge::Plugins::EmergingIndent::indent_after_step,
##	        \&Emerge::Plugins::CurrentStep::track_step,
##            ];
##        }
##    );
##
##    sub process_stream ($self, $fh_in, $fh_out = *STDOUT) {
##        while (my $line = <$fh_in>) {
##            chomp $line;
##            my $formatted = $self->process_line($line);
##            print $fh_out $formatted if defined $formatted && length $formatted;
##        }
##    }
##
##    sub process_line ($self, $line) {
##        my $clean = $line;
##        $clean =~ s/\e\[[0-9;]*m//g; # strip ANSI codes
##        $clean =~ s/^\s+//;          # trim start for matching
##
##        # Handle indentation context
##        $self->_in_section(1) if $clean =~ /^>>>/;
##
##        # Apply non-color plugins first
##        my $out = $line;
##        for my $plugin (@{$self->_plugins}) {
##            $out = $plugin->($out);
##        }
##
##        # Apply indentation if in section
##        $out = $self->indent . $out if $self->_in_section && $clean !~ /^>>>/;
##
##        # Fold line without ANSI codes interfering
##        $out = $self->_wrapper->fold($out);
##
##        # Apply color plugin after folding
##        $out = Emerge::Plugins::Paths::dim_paths($out);
##
##	# inside process_line after applying plugins
##	my $extra_indent = '';
##	if ($out =~ /\x{200B}$/) {
##	    $extra_indent = $self->indent;
##	    $out =~ s/\x{200B}$//; # remove marker
##	}
##
##	$out = $self->indent . $extra_indent . $out if $self->_in_section && $clean !~ /^>>>/;
##
##
##        # Update section context
##        $self->_in_section(1) if $clean =~ /^>>>/;
##
##        return $out;
##    }
##}
##
###------------------------------------------------------------------------------
### Plugins
###------------------------------------------------------------------------------
##
### --- Path dimmer -------------------------------------------------------------
##{
##    package Emerge::Plugins::Paths;
##    use Term::ANSIColor;
##    use File::Spec;
##
##    sub _looks_like_path ($token) {
##        return 1 if File::Spec->file_name_is_absolute($token);
##        return $token =~ m{^(?:\.{1,2}/|~/?)};
##    }
##
##    # Apply faint coloring to path tokens
##    sub dim_paths ($line) {
##        $line =~ s{(\S+)}{
##            my $tok = $1;
##            _looks_like_path($tok) ? color('faint') . $tok . color('reset') : $tok;
##        }gex;
##        return $line;
##    }
##}
##
### --- Section markers ---------------------------------------------------------
##{
##    package Emerge::Plugins::Sections;
##    use Term::ANSIColor;
##
##    sub mark_section_headers ($line) {
##        $line =~ s/^(\s*)(>>>)/$1 . color('bold blue') . $2 . color('reset')/re;
##    }
##}
##
### --- Bullet points -----------------------------------------------------------
##{
##    package Emerge::Plugins::Bullets;
##
##    # Convert leading '*' into a bullet '•'
##    sub bulletize ($line) {
##        $line =~ s/^(\s*)\*/$1•/;
##        return $line;
##    }
##}
##
### --- Emerging step indentation ------------------------------------------------
##{
##    package Emerge::Plugins::EmergingIndent;
##    use Moo::Role;
##
##    # Lines that trigger extra indentation
##    my @step_prefixes = qw(Emerging Installing Merging Completed);
##
##    sub indent_after_step ($line) {
##        # Check if line starts with >>> and any of the step keywords
##        if ($line =~ /^>>>\s*(\w+)/ && grep { $_ eq $1 } @step_prefixes) {
##            # Return line unchanged, but set a flag for the formatter to indent subsequent lines
##            # We'll just add indentation to the next lines in process_line
##            # For simplicity, here we'll append a zero-width marker for formatter
##            return "→" . $line . "\x{200B}"; # zero-width space as marker
##        }
##        return "→→" . $line;
##    }
##}
##
### --- Track current emerging step ---------------------------------------------
##{
##    package Emerge::Plugins::CurrentStep;
##    use strict;
##    use warnings;
##
##    # Save the last seen step line in a package variable
##    our $CURRENT_STEP = '';
##
##    my @step_prefixes = qw(Emerging Installing Merging Completed);
##
##    sub track_step ($line) {
##        if ($line =~ /^>>>\s*(\w+)/ && grep { $_ eq $1 } @step_prefixes) {
##            $CURRENT_STEP = $line;
##        }
##        return $line;
##    }
##}
##
##
###------------------------------------------------------------------------------
### Main Script
###------------------------------------------------------------------------------
##package main;
##
##my $formatter = Emerge::Formatter->new(
##    wrap   => $ENV{COLUMNS} || 166,
##    indent => '    ',
##);
##
##$formatter->process_stream(*STDIN, *STDOUT);
